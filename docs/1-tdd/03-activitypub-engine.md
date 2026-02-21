# ActivityPub Engine — Technical Design Document

## 1. Scope

This document describes the technical architecture of the Lightweb ActivityPub Engine. It covers the machinery — how activities enter, are processed, stored, delivered, and emitted as events — without reference to any specific activity or object type. Individual object types are defined in separate implementation specs.

The AP Engine is one of three server processes per Lightweb instance. It owns:

- All federation (Server-to-Server ActivityPub)
- Object persistence (PostgreSQL, one database per user)
- Object caching (Redis, cache-only, rebuildable)
- Real-time delivery (WebSocket)
- Event emission (Redis Streams)

It does **not** implement the ActivityPub Client-to-Server protocol. Client interaction uses a custom REST/WebSocket API.

---

## 2. Design Decisions

These decisions were made during the design phase and are not open for reconsideration without revisiting this document.

| Decision                | Choice                                             | Rationale                                                                                   |
| ----------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Activity processing     | Middleware chain                                   | Predictable, linear, forces consistency                                                     |
| Object storage          | Polymorphic JSONB with GIN indexes                 | Matches AP's polymorphic data model, no migrations per type, queryable without rigid schema |
| JSON-LD handling        | Compact form, hard-coded contexts                  | No library dependency, no network calls, sufficient for compliance                          |
| Feed fan-out            | Fan-out on write to each user's Postgres           | Complete data isolation per user, portable databases                                        |
| Redis cache role        | Cache only, rebuildable from Postgres              | No data loss on Redis failure or flush                                                      |
| Redis event role        | Streams with consumer groups                       | Durable event delivery, catch-up on reconnect, at-least-once semantics                      |
| Redis memory management | LFU eviction, TTL only for remote data correctness | Eviction handles memory pressure; TTL handles staleness of data we can't observe changes to |
| Cache architecture      | Normalized two-layer (object cache + feed indexes) | No duplication across feeds; single object cached once, referenced by ID                    |
| Inbox model             | Both shared and per-actor inboxes                  | Shared inbox reduces inbound federation traffic                                             |
| Scale target            | Hundreds to low thousands of users per instance    | Decentralized by design, not built for mega-instances                                       |

---

## 3. Middleware Pipeline

All activity processing — inbound (federation) and outbound (local dispatch) — flows through ordered middleware chains. Each middleware step receives a context object, performs its work, and calls `next()` or short-circuits with an error.

### 3.1 Inbound Pipeline (Federation → Local)

A remote server POSTs a signed activity to our inbox.

```
receive
  → parseBody          Extract and validate JSON from request body
  → resolveActor       Fetch or cache-lookup the sending actor's public key
  → verifySignature    Verify HTTP Signature (RFC 9421) using actor's public key
  → validateSchema     Ensure the activity has required fields and recognized type
  → resolveAddressing  Determine local recipients from to/cc fields
  → decryptContent     If encrypted, unwrap MLS payload (type manifest lookup)
  → persist            Write to each local recipient's database (fan-out)
  → executeSideEffects Run type-specific handlers (e.g., update follower lists)
  → emitEvents         Append typed events to Redis Streams per recipient
  → respond            Return 202 Accepted
```

If any step fails, the pipeline short-circuits. Signature verification failure returns 401. Schema validation failure returns 400. Errors are logged but never leak internal details to the remote server.

### 3.2 Outbound Pipeline (Local → Federation)

A local action (from the client API or LLM Engine dispatch) produces an activity to be delivered.

```
dispatch
  → validateAction     Verify action is in the allowed vocabulary, params are valid
  → resolveRecipients  Look up recipient actor URIs, determine delivery targets
  → constructActivity  Build the AP activity envelope with proper addressing
  → encryptContent     If required by type manifest + relationship state, apply MLS
  → persist            Write to the sending user's database (outbox)
  → signRequest        Generate HTTP Signature for each delivery target
  → deliver            POST to remote inboxes (async, with retry)
  → emitEvents         Append events to Redis Stream for the sending user
  → respond            Return result to caller
```

### 3.3 Middleware Contract

```typescript
interface MiddlewareContext {
  activity: Record<string, unknown>; // The raw AP activity
  actor?: Actor; // Resolved sending actor
  recipients?: LocalRecipient[]; // Resolved local recipients
  user?: string; // Authenticated local user (outbound only)
  meta: Record<string, unknown>; // Arbitrary metadata passed between steps
}

type Middleware = (
  ctx: MiddlewareContext,
  next: () => Promise<void>,
) => Promise<void>;
```

### 3.4 Type Handler Registry

The pipeline itself is type-agnostic. Type-specific behavior lives in a handler registry, consulted during the `executeSideEffects` step.

```typescript
interface TypeHandler {
  type: string; // e.g., "Create", "Follow", "Like"
  objectType?: string; // Optional, e.g., "Note", "Article"
  onInbound: (ctx: MiddlewareContext) => Promise<void>; // Side effects for received activities
  onOutbound: (ctx: MiddlewareContext) => Promise<void>; // Side effects for sent activities
}
```

Handlers are registered at startup. If no handler exists for an activity type, the activity is persisted and events are emitted, but no side effects execute. This ensures forward compatibility — unknown activity types from remote servers are stored, not rejected.

---

## 4. Data Model

### 4.1 Per-User PostgreSQL Database

Each Lightweb user has an isolated database (`lightweb_<username>`). All tables below exist in every user's database.

### 4.2 Core Tables

**actors** — Cached representations of known remote and local actors.

| Column             | Type        | Description                                         |
| ------------------ | ----------- | --------------------------------------------------- |
| uri                | TEXT PK     | Actor URI (e.g., `https://remote.social/users/bob`) |
| type               | TEXT        | `Person`, `Service`, `Application`, etc.            |
| preferred_username | TEXT        | Display name handle                                 |
| inbox              | TEXT        | Actor's inbox URL                                   |
| outbox             | TEXT        | Actor's outbox URL                                  |
| shared_inbox       | TEXT        | Server's shared inbox URL (nullable)                |
| public_key_pem     | TEXT        | Actor's public key for signature verification       |
| raw                | JSONB       | Full actor document as received                     |
| fetched_at         | TIMESTAMPTZ | Last time this actor was fetched/refreshed          |
| created_at         | TIMESTAMPTZ | Row creation time                                   |

**objects** — All ActivityPub objects, unified. The `raw` JSONB column is the authoritative representation. Indexed columns are extracted for query performance; all other fields are queried via JSONB operators and GIN indexes.

| Column     | Type        | Description                                                               |
| ---------- | ----------- | ------------------------------------------------------------------------- |
| id         | UUID PK     | Internal identifier                                                       |
| uri        | TEXT UNIQUE | AP object URI (e.g., `https://lightweb.cloud/users/alice/objects/<uuid>`) |
| published  | TIMESTAMPTZ | AP `published` timestamp (extracted for sort performance)                 |
| raw        | JSONB       | Full object JSON-LD as received or constructed — source of truth          |
| created_at | TIMESTAMPTZ | Row creation time                                                         |

**activities** — Activity envelopes wrapping objects. Same polymorphic approach as objects — `raw` JSONB is the source of truth, extracted columns exist only for query performance.

| Column     | Type        | Description                                               |
| ---------- | ----------- | --------------------------------------------------------- |
| id         | UUID PK     | Internal identifier                                       |
| uri        | TEXT UNIQUE | AP activity URI                                           |
| direction  | TEXT        | `inbound` or `outbound`                                   |
| published  | TIMESTAMPTZ | AP `published` timestamp (extracted for sort performance) |
| raw        | JSONB       | Full activity JSON-LD — source of truth                   |
| created_at | TIMESTAMPTZ | Row creation time                                         |

**relationships** — Follow and friend state.

| Column       | Type        | Description                                    |
| ------------ | ----------- | ---------------------------------------------- |
| id           | UUID PK     | Internal identifier                            |
| actor_uri    | TEXT        | The remote actor                               |
| type         | TEXT        | `follower`, `following`, `friend`              |
| status       | TEXT        | `pending`, `accepted`, `rejected`              |
| activity_uri | TEXT        | The Follow or Offer activity that created this |
| created_at   | TIMESTAMPTZ | Row creation time                              |
| updated_at   | TIMESTAMPTZ | Last state change                              |

**feed** — Chronological feed entries for this user, populated on write.

| Column       | Type        | Description                |
| ------------ | ----------- | -------------------------- |
| id           | UUID PK     | Internal identifier        |
| activity_uri | TEXT        | References the activity    |
| actor_uri    | TEXT        | Who performed the activity |
| published    | TIMESTAMPTZ | Sort key                   |
| created_at   | TIMESTAMPTZ | Row creation time          |

The `feed` table is the user's materialized timeline. It is populated during the `persist` step of the inbound pipeline and during the `persist` step of the outbound pipeline.

**groups** — Named collections of actor URIs. Used for audience scoping (AP `to`/`cc` addressing), content filtering, and any future purpose requiring a named set of actors.

| Column     | Type        | Description                                                                 |
| ---------- | ----------- | --------------------------------------------------------------------------- |
| id         | UUID PK     | Internal identifier                                                         |
| name       | TEXT UNIQUE | Group name (e.g., `close-friends`, `work-colleagues`)                       |
| uri        | TEXT UNIQUE | AP collection URI (e.g., `https://<domain>/users/<username>/groups/<name>`) |
| created_at | TIMESTAMPTZ | Row creation time                                                           |

**group_members** — Membership in groups.

| Column      | Type        | Description               |
| ----------- | ----------- | ------------------------- |
| group_id    | UUID FK     | References `groups.id`    |
| actor_uri   | TEXT        | Member actor URI          |
| added_at    | TIMESTAMPTZ | When the member was added |
| PRIMARY KEY |             | `(group_id, actor_uri)`   |

Groups are resolved during the `resolveRecipients` (outbound) and `resolveAddressing` (inbound) pipeline steps. When a `to` or `cc` field contains a group URI, the pipeline expands it to the member actor URIs for delivery.

### 4.3 Indexes

**B-tree indexes** (extracted columns for sort and lookup performance):

- `objects(uri)` — unique, lookups by AP URI
- `objects(published DESC)` — chronological ordering
- `activities(uri)` — unique, deduplication
- `activities(direction, published DESC)` — inbox/outbox queries
- `feed(published DESC)` — chronological feed reads
- `relationships(actor_uri, type)` — relationship lookups

**GIN indexes** (JSONB path queries):

- `objects(raw->'type')` — type-filtered queries
- `objects(raw->'attributedTo')` — objects by author
- `objects(raw->'inReplyTo')` — thread resolution
- `objects(raw->'lwMetadata'->'tags')` — internal tag queries (collection membership, filtering)
- `activities(raw->'actor')` — activities by actor
- `activities(raw->'object')` — activities referencing an object
- `activities(raw->'to')` — addressing queries
- `activities(raw->'cc')` — addressing queries

### 4.4 Deduplication

Activities are deduplicated by `uri`. If an inbound activity's URI already exists in the user's database, it is silently dropped. This handles the case where a remote server delivers via both shared inbox and per-actor inbox, or retries delivery.

---

## 5. Actor Model

### 5.1 Local Actor Document

Each local user is represented as an AP `Person` actor. The actor document is constructed on-the-fly from the user's configuration and keys.

```
GET /users/:username
Accept: application/activity+json

{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://w3id.org/security/v1",
    "https://lightwebbrowser.org/ns"
  ],
  "id": "https://<domain>/users/<username>",
  "type": "Person",
  "preferredUsername": "<username>",
  "inbox": "https://<domain>/users/<username>/inbox",
  "outbox": "https://<domain>/users/<username>/outbox",
  "followers": "https://<domain>/users/<username>/followers",
  "following": "https://<domain>/users/<username>/following",
  "endpoints": {
    "sharedInbox": "https://<domain>/inbox"
  },
  "publicKey": {
    "id": "https://<domain>/users/<username>#main-key",
    "owner": "https://<domain>/users/<username>",
    "publicKeyPem": "<PEM>"
  }
}
```

### 5.2 WebFinger

Discovery follows the standard WebFinger flow. A query for `@alice@lightweb.cloud` hits:

```
GET https://lightweb.cloud/.well-known/webfinger?resource=acct:alice@lightweb.cloud

{
  "subject": "acct:alice@lightweb.cloud",
  "links": [
    {
      "rel": "self",
      "type": "application/activity+json",
      "href": "https://lightweb.cloud/users/alice"
    }
  ]
}
```

### 5.3 Remote Actor Resolution

When the pipeline encounters a remote actor URI (in signatures, in activity fields), it:

1. Checks the local `actors` cache table
2. If missing or stale (`fetched_at` older than configurable TTL), fetches the actor document via signed HTTP GET
3. Extracts and stores the public key for signature verification
4. Caches the full document in `actors.raw`

Actor fetch failures are retried with exponential backoff. If an actor cannot be resolved, inbound activities from that actor are rejected.

---

## 6. HTTP Signatures

### 6.1 Outbound Signing

All outbound HTTP requests (activity delivery, actor fetches) are signed per RFC 9421 (HTTP Message Signatures). The signing key is the local user's Ed25519 private key, stored in `/home/<username>/keys/`.

Signed headers include at minimum: `(request-target)`, `host`, `date`, `digest` (for POST bodies).

### 6.2 Inbound Verification

All inbox POSTs are verified before any processing:

1. Extract the `keyId` from the `Signature` header
2. Resolve the actor document at the `keyId` URL (or use cached version)
3. Extract the public key
4. Verify the signature against the request headers and body
5. Verify the `actor` field in the activity matches the signing actor

Failure at any step returns 401 and the activity is rejected.

---

## 7. Collections

ActivityPub defines several standard collections per actor. All are implemented as `OrderedCollection` with cursor-based pagination.

### 7.1 Endpoints

| Endpoint                     | Source                                                           | Visibility                          |
| ---------------------------- | ---------------------------------------------------------------- | ----------------------------------- |
| `/users/:username/inbox`     | `activities WHERE direction = 'inbound'`                         | Owner only (authenticated)          |
| `/users/:username/outbox`    | `activities WHERE direction = 'outbound'`                        | Public (filtered by addressing)     |
| `/users/:username/followers` | `relationships WHERE type = 'follower' AND status = 'accepted'`  | Public or owner-only (configurable) |
| `/users/:username/following` | `relationships WHERE type = 'following' AND status = 'accepted'` | Public or owner-only (configurable) |

### 7.2 Shared Inbox

```
POST /inbox
```

The shared inbox accepts activities addressed to any local actor. The `resolveAddressing` middleware step inspects `to` and `cc` fields to determine which local users should receive the activity, then fans out to each recipient's database.

### 7.3 Pagination

Collections use AP's `OrderedCollectionPage` with cursor-based pagination:

```json
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "type": "OrderedCollectionPage",
  "partOf": "https://lightweb.cloud/users/alice/outbox",
  "next": "https://lightweb.cloud/users/alice/outbox?cursor=<opaque>",
  "orderedItems": [...]
}
```

Cursors are opaque, timestamp-based. Page size is configurable (default: 20).

---

## 8. Federation Delivery

### 8.1 Recipient Resolution

When an outbound activity specifies recipients, the delivery system resolves them:

- **Direct addressing** (`to: ["https://remote.social/users/bob"]`): deliver to that actor's inbox
- **Follower addressing** (`to: ["https://lightweb.cloud/users/alice/followers"]`): expand to all follower actor URIs, deduplicate by shared inbox
- **Public addressing** (`to: ["https://www.w3.org/ns/activitystreams#Public"]`): no delivery (public activities are available via the outbox; followers receive via follower addressing in `cc`)

### 8.2 Shared Inbox Optimization

Before delivering, the system groups recipients by their server's shared inbox. If a remote server has a `sharedInbox` endpoint and multiple recipients are on that server, a single POST is sent to the shared inbox instead of individual POSTs to each actor's inbox.

### 8.3 Delivery Queue

Outbound deliveries are processed asynchronously. Failed deliveries are retried with exponential backoff:

- Retry intervals: 1m, 5m, 30m, 2h, 12h, 24h
- After final retry, the delivery is marked as failed and logged
- Dead servers (repeated failures over 7 days) are marked inactive; delivery is paused and resumed on next successful contact

The delivery queue is persisted in PostgreSQL (in the sending user's database) to survive process restarts.

---

## 9. Event Emission

### 9.1 Redis Streams

After an activity is processed (inbound or outbound), the AP Engine appends a typed event to the user's Redis Stream.

```
Stream: <username>:events

XADD <username>:events * type "activity.received" source "ap" payload "{...}" timestamp "2026-02-21T12:00:00Z"
```

```json
{
  "type": "activity.received",
  "source": "ap",
  "payload": {
    "activityUri": "...",
    "activityType": "Create",
    "actorUri": "...",
    "objectUri": "..."
  },
  "timestamp": "2026-02-21T12:00:00Z"
}
```

Unlike pub/sub, Streams retain events. Consumers that disconnect (process restart, network blip) catch up by reading from their last-seen ID. No events are lost during subscriber downtime.

### 9.2 Consumer Model

The LLM Engine and WebSocket server each register as consumer groups on the user's event stream:

- **LLM Engine**: consumer group `llm`, reads events to trigger user-configured event handlers
- **WebSocket server**: consumer group `ws`, reads events to push real-time updates to connected clients

Each consumer group tracks its own read position independently. Events are acknowledged (`XACK`) after successful processing. Unacknowledged events (consumer crashed mid-processing) are reclaimed and redelivered automatically.

Stream retention is capped by `MAXLEN` (configurable, default: 10,000 entries) to bound memory. Old entries are trimmed as new ones arrive. This is not TTL-based — it's a rolling window of recent events.

### 9.3 Event Types

Event types are derived from the activity type and direction. The naming convention is:

- `<activity-type>.<direction>` — e.g., `create.received`, `follow.sent`
- Type-specific aliases may be registered by type handlers — e.g., a handler for `Create(Note)` might also emit `dm.received`

The event schema is fixed:

```typescript
interface SystemEvent {
  type: string;
  source: "ap";
  payload: Record<string, unknown>;
  timestamp: string; // ISO 8601
}
```

---

## 10. Client API

The AP Engine exposes a REST and WebSocket API for the client and LLM Engine. This is **not** ActivityPub C2S — it is a custom internal API.

### 10.1 REST Endpoints

```
GET  /api/feed              → Paginated feed (from Postgres, with object data resolved via Redis cache)
GET  /api/feed/:id          → Single activity detail
POST /api/activity          → Dispatch an action (ActionDispatch shape)
```

### 10.2 Action Dispatch

Both the client (in Direct input mode) and the LLM Engine use the same dispatch shape:

```typescript
interface ActionDispatch {
  action: string;
  params: Record<string, unknown>;
}

interface ActionResult {
  success: boolean;
  activityId?: string;
  error?: string;
}
```

The action vocabulary is fixed and defined in the implementation specs for each object type. The `validateAction` middleware step rejects unknown actions.

### 10.3 WebSocket

```
WS /ws
```

Authenticated per user. Pushes real-time events: incoming activities, typing indicators, presence, read receipts. Subscriptions are scoped to the authenticated user's data. The WebSocket server consumes from the user's Redis Stream (as its own consumer group) to push events to connected clients.

---

## 11. Federation Endpoints

These are the public-facing endpoints that remote servers interact with.

| Endpoint                     | Method | Content-Type                | Purpose              |
| ---------------------------- | ------ | --------------------------- | -------------------- |
| `/.well-known/webfinger`     | GET    | `application/jrd+json`      | Actor discovery      |
| `/.well-known/nodeinfo`      | GET    | `application/json`          | Server metadata      |
| `/users/:username`           | GET    | `application/activity+json` | Actor document       |
| `/users/:username/inbox`     | POST   | `application/activity+json` | Receive activities   |
| `/users/:username/outbox`    | GET    | `application/activity+json` | Published activities |
| `/users/:username/followers` | GET    | `application/activity+json` | Followers collection |
| `/users/:username/following` | GET    | `application/activity+json` | Following collection |
| `/inbox`                     | POST   | `application/activity+json` | Shared inbox         |

Content negotiation: these endpoints return `application/activity+json` when requested. The `Accept` header is checked; requests without the proper accept header for actor/collection endpoints return 406.

---

## 12. Security

### 12.1 Signature Enforcement

No unsigned activity is ever processed. No unsigned outbound request is ever sent.

### 12.2 Action Vocabulary

The set of actions accepted via `POST /api/activity` is fixed and enumerated. Unknown actions are rejected. This is a security boundary — the LLM Engine cannot invent new actions.

### 12.3 Domain Blocklist/Allowlist

Configurable per server via the Config Registry. Blocked domains have their inbound activities rejected at the `verifySignature` step (after parsing the actor's domain). Outbound delivery to blocked domains is skipped.

### 12.4 Input Validation

All inbound activities are validated for:

- Required fields (`type`, `actor`, `object` where applicable)
- URI format validity
- Reasonable size limits on content fields
- `actor` field matches the HTTP Signature signer

### 12.5 Redis Key Scoping

All Redis operations are scoped to the authenticated user via a key-prefix wrapper. The AP Engine never issues a raw Redis command — all access goes through a scoped client that prepends `<username>:` to every key. This prevents cross-user data leakage through application bugs. Redis ACLs provide a secondary enforcement layer, restricting each user's key pattern (`<username>:*`).

### 12.6 Rate Limiting

Per-domain and per-actor rate limits on the inbox endpoints. Configurable thresholds. Exceeded limits return 429.

---

## 13. Encryption Integration Point

The encryption layer (MLS) is integrated into the middleware pipeline as two steps:

- **Inbound**: `decryptContent` — checks the object type manifest; if the object type requires encryption, unwraps the MLS ciphertext from the `content` field before persistence
- **Outbound**: `encryptContent` — checks the type manifest and relationship state; if encryption is required, wraps the `content` field in MLS ciphertext before delivery

The encryption steps are no-ops for unencrypted object types. The pipeline doesn't need to know about encryption details — it delegates to the encryption subsystem and passes the result along.

Key management, MLS group lifecycle, and the type manifest are defined in a separate TDD.

---

## 14. Redis Strategy

Redis serves two distinct roles: **caching** (rebuildable from Postgres) and **event delivery** (Streams, covered in section 9). This section covers caching. No cached data lives only in Redis — full Redis loss is recoverable.

### 14.1 Memory Management

Redis is configured with a fixed memory limit (`maxmemory`) and the `allkeys-lfu` eviction policy. When memory is full, Redis automatically evicts the least frequently used keys to make room for new ones. This means the cache is self-optimizing — hot data stays, cold data gets evicted based on actual access patterns.

TTL is **not** used for memory management. TTL is used only for **correctness** — specifically, for remote data (actor documents) where we have no way to observe changes and must force a periodic re-fetch. Local data cached from Postgres does not need TTL because the pipeline always invalidates on change.

### 14.2 Normalized Cache Architecture

The cache uses a two-layer normalized design to avoid data duplication across feeds.

**Layer 1: Object Cache** — Each object is cached once by URI.

- Key: `<username>:obj:<uri>`
- Value: Serialized object (full JSON)
- Invalidation: Deleted when the pipeline processes an `Update` or `Delete` activity targeting this object
- Rebuild: On miss, query the user's `objects` table by URI

**Layer 2: Feed Indexes** — Feed pages store only lists of object URIs, not full objects.

- Key: `<username>:feed:<feed_id>:page:<cursor>`
- Value: Ordered array of object URIs (lightweight — ~50 bytes per entry)
- Invalidation: Deleted when a new activity arrives that affects this feed
- Rebuild: On miss, query Postgres with the feed's criteria (tags, addressing, time range), populate the index

Cache pages are large (configurable, default: 500 entries). Client-specified page sizes are handled at the application layer by slicing into the cached page. This means fewer cache keys, fewer invalidations, and the client's pagination is decoupled from the cache's pagination.

**Read flow:**

1. Fetch the feed index page → array of object URIs
2. Slice to the client's requested page size and offset
3. `MGET` the object URIs from the object cache → full objects in a single round trip
4. Any cache misses are fetched from Postgres, cached, and returned

This is always exactly 2 Redis round trips regardless of page size.

### 14.3 Feed Index Scoping

Feed indexes are built from Postgres queries that respect the user's configuration. Different feeds are different query criteria cached under different `feed_id` keys:

- `<username>:feed:main:page:0` — the user's primary timeline
- `<username>:feed:close-friends:page:0` — scoped to a group's actors
- `<username>:feed:knitting:page:0` — scoped to objects tagged via `lwMetadata.tags`

The same object appearing in multiple feeds is stored once in the object cache and referenced by URI in each feed index. No duplication.

### 14.4 Federation Collection Cache

Federation-facing collection endpoints (`/users/:username/outbox`, `/followers`, `/following`) use the same two-layer cache. Remote servers paginating through collections hit the feed index cache; the objects they reference are resolved from the object cache. This is where the paged cache provides the most value — remote servers make predictable, repeatable requests that benefit from caching.

### 14.5 Remote Actor Cache

Remote actor documents are cached with a TTL (configurable, default: 24 hours) because changes to remote actors (profile updates, key rotations) cannot be observed through the pipeline. TTL forces periodic re-fetch to ensure correctness.

- Key: `<username>:actor:<uri>`
- Value: Serialized actor document
- TTL: Configurable (default: 24 hours)
- Rebuild: On miss, check Postgres `actors` table; if stale (`fetched_at` older than TTL), re-fetch from remote

This is the only cache type that uses TTL. All other cache types rely on pipeline-driven invalidation and LFU eviction.

### 14.6 Session and Presence

- Key: `<username>:session:<token>` and `<username>:presence`
- These are ephemeral by nature — loss on Redis restart is acceptable
- Sessions fall back to re-authentication; presence resets to offline
- No Postgres backing, no TTL-based correctness concern — these are transient state

### 14.7 Invalidation, Eviction, and TTL

Three distinct mechanisms, three distinct purposes:

| Mechanism          | Purpose                                         | When it applies                                              |
| ------------------ | ----------------------------------------------- | ------------------------------------------------------------ |
| **Invalidation**   | The pipeline _knows_ data changed               | Object updated/deleted, new feed entry, side effect executed |
| **Eviction** (LFU) | Redis needs memory                              | Automatic — least frequently used keys are evicted first     |
| **TTL**            | Data _may have_ changed and we can't observe it | Remote actor documents only                                  |

---

## 15. Process Architecture

The AP Engine runs as a single Fastify process per server instance. It serves all users, routing requests to the appropriate user's database based on authentication (client API) or addressing (federation).

### 15.1 Database Connection Management

A connection pool manager maintains separate pools per user database. Pools are created lazily on first request to a user's database and reaped after inactivity.

### 15.2 Startup

On startup, the AP Engine:

1. Connects to Redis
2. Registers the middleware pipeline
3. Registers type handlers from the handler registry
4. Starts the Fastify HTTP server (federation + client API)
5. Starts the WebSocket server
6. Begins processing the delivery retry queue

### 15.3 Graceful Shutdown

On shutdown signal:

1. Stop accepting new connections
2. Drain in-flight requests (configurable timeout)
3. Flush pending delivery queue entries to Postgres
4. Close database connection pools
5. Disconnect from Redis
