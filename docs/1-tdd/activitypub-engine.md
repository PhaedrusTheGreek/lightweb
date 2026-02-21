# ActivityPub Engine — Technical Design Document

## 1. Scope

This document describes the technical architecture of the Lightweb ActivityPub Engine. It covers the machinery — how activities enter, are processed, stored, delivered, and emitted as events — without reference to any specific activity or object type. Individual object types are defined in separate implementation specs.

The AP Engine is one of three server processes per Lightweb instance. It owns:

- All federation (Server-to-Server ActivityPub)
- Object persistence (PostgreSQL, one database per user)
- Feed caching (Redis, cache-only, rebuildable)
- Real-time delivery (WebSocket)
- Event emission (Redis pub/sub)

It does **not** implement the ActivityPub Client-to-Server protocol. Client interaction uses a custom REST/WebSocket API.

---

## 2. Design Decisions

These decisions were made during the design phase and are not open for reconsideration without revisiting this document.

| Decision | Choice | Rationale |
|---|---|---|
| Activity processing | Middleware chain | Predictable, linear, forces consistency |
| Object storage | Unified `objects` table with type discriminator | Matches AP's polymorphic data model, no migrations per type |
| JSON-LD handling | Compact form, hard-coded contexts | No library dependency, no network calls, sufficient for compliance |
| Feed fan-out | Fan-out on write to each user's Postgres | Complete data isolation per user, portable databases |
| Redis role | Cache only, rebuildable from Postgres | No data loss on Redis failure or flush |
| Inbox model | Both shared and per-actor inboxes | Shared inbox reduces inbound federation traffic |
| Scale target | Hundreds to low thousands of users per instance | Decentralized by design, not built for mega-instances |

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
  → emitEvents         Publish typed events to Redis pub/sub per recipient
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
  → emitEvents         Publish events to Redis pub/sub for the sending user
  → respond            Return result to caller
```

### 3.3 Middleware Contract

```typescript
interface MiddlewareContext {
  activity: Record<string, unknown>;  // The raw AP activity
  actor?: Actor;                       // Resolved sending actor
  recipients?: LocalRecipient[];       // Resolved local recipients
  user?: string;                       // Authenticated local user (outbound only)
  meta: Record<string, unknown>;       // Arbitrary metadata passed between steps
}

type Middleware = (ctx: MiddlewareContext, next: () => Promise<void>) => Promise<void>;
```

### 3.4 Type Handler Registry

The pipeline itself is type-agnostic. Type-specific behavior lives in a handler registry, consulted during the `executeSideEffects` step.

```typescript
interface TypeHandler {
  type: string;                                          // e.g., "Create", "Follow", "Like"
  objectType?: string;                                   // Optional, e.g., "Note", "Article"
  onInbound: (ctx: MiddlewareContext) => Promise<void>;  // Side effects for received activities
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

| Column | Type | Description |
|---|---|---|
| uri | TEXT PK | Actor URI (e.g., `https://remote.social/users/bob`) |
| type | TEXT | `Person`, `Service`, `Application`, etc. |
| preferred_username | TEXT | Display name handle |
| inbox | TEXT | Actor's inbox URL |
| outbox | TEXT | Actor's outbox URL |
| shared_inbox | TEXT | Server's shared inbox URL (nullable) |
| public_key_pem | TEXT | Actor's public key for signature verification |
| raw | JSONB | Full actor document as received |
| fetched_at | TIMESTAMPTZ | Last time this actor was fetched/refreshed |
| created_at | TIMESTAMPTZ | Row creation time |

**objects** — All ActivityPub objects, unified.

| Column | Type | Description |
|---|---|---|
| id | UUID PK | Internal identifier |
| uri | TEXT UNIQUE | AP object URI (e.g., `https://lightweb.cloud/users/alice/objects/<uuid>`) |
| type | TEXT | Object type discriminator (`Note`, `Article`, etc.) |
| attributed_to | TEXT | Actor URI of the author |
| in_reply_to | TEXT | URI of parent object (nullable) |
| content | JSONB | Full object payload (plaintext or ciphertext) |
| encrypted | BOOLEAN | Whether content is MLS-encrypted |
| published | TIMESTAMPTZ | AP `published` timestamp |
| raw | JSONB | Original JSON-LD as received (federation) or as constructed (local) |
| created_at | TIMESTAMPTZ | Row creation time |

**activities** — Activity envelopes wrapping objects.

| Column | Type | Description |
|---|---|---|
| id | UUID PK | Internal identifier |
| uri | TEXT UNIQUE | AP activity URI |
| type | TEXT | Activity type (`Create`, `Follow`, `Like`, `Announce`, etc.) |
| actor | TEXT | Actor URI who performed the activity |
| object_uri | TEXT | URI of the target object (references `objects.uri` or remote URI) |
| target_uri | TEXT | URI of the target (for `Add`/`Remove` to collections, nullable) |
| addressing | JSONB | `{ to: [...], cc: [...] }` |
| raw | JSONB | Full activity JSON-LD |
| published | TIMESTAMPTZ | AP `published` timestamp |
| created_at | TIMESTAMPTZ | Row creation time |
| direction | TEXT | `inbound` or `outbound` |

**relationships** — Follow and friend state.

| Column | Type | Description |
|---|---|---|
| id | UUID PK | Internal identifier |
| actor_uri | TEXT | The remote actor |
| type | TEXT | `follower`, `following`, `friend` |
| status | TEXT | `pending`, `accepted`, `rejected` |
| activity_uri | TEXT | The Follow or Offer activity that created this |
| created_at | TIMESTAMPTZ | Row creation time |
| updated_at | TIMESTAMPTZ | Last state change |

**feed** — Chronological feed entries for this user, populated on write.

| Column | Type | Description |
|---|---|---|
| id | UUID PK | Internal identifier |
| activity_uri | TEXT | References the activity |
| actor_uri | TEXT | Who performed the activity |
| published | TIMESTAMPTZ | Sort key |
| created_at | TIMESTAMPTZ | Row creation time |

The `feed` table is the user's materialized timeline. It is populated during the `persist` step of the inbound pipeline and during the `persist` step of the outbound pipeline. Redis caches recent feed entries for fast reads; on cache miss, the cache is rebuilt from this table.

### 4.3 Indexes

At minimum:

- `objects(uri)` — unique, used for lookups by AP URI
- `objects(attributed_to, published)` — actor's objects by time
- `objects(in_reply_to)` — thread resolution
- `objects(type)` — type-filtered queries
- `activities(uri)` — unique, used for deduplication
- `activities(actor, published)` — actor's activity history
- `activities(object_uri)` — find activities referencing an object
- `feed(published DESC)` — chronological feed reads
- `relationships(actor_uri, type)` — relationship lookups

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

| Endpoint | Source | Visibility |
|---|---|---|
| `/users/:username/inbox` | `activities WHERE direction = 'inbound'` | Owner only (authenticated) |
| `/users/:username/outbox` | `activities WHERE direction = 'outbound'` | Public (filtered by addressing) |
| `/users/:username/followers` | `relationships WHERE type = 'follower' AND status = 'accepted'` | Public or owner-only (configurable) |
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

### 9.1 Redis Pub/Sub

After an activity is processed (inbound or outbound), the AP Engine emits a typed event to the user's Redis pub/sub channel.

```
Channel: <username>:events

{
  "type": "activity.received",    // or "activity.sent", "follow.received", etc.
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

The LLM Engine subscribes to the relevant user's channel and matches event handlers defined in user configuration.

### 9.2 Event Types

Event types are derived from the activity type and direction. The naming convention is:

- `<activity-type>.<direction>` — e.g., `create.received`, `follow.sent`
- Type-specific aliases may be registered by type handlers — e.g., a handler for `Create(Note)` might also emit `dm.received`

The event schema is fixed:

```typescript
interface SystemEvent {
  type: string;
  source: "ap";
  payload: Record<string, unknown>;
  timestamp: string;  // ISO 8601
}
```

---

## 10. Client API

The AP Engine exposes a REST and WebSocket API for the client and LLM Engine. This is **not** ActivityPub C2S — it is a custom internal API.

### 10.1 REST Endpoints

```
GET  /api/feed              → Paginated feed (from Redis cache, fallback to Postgres)
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

Authenticated per user. Pushes real-time events: incoming activities, typing indicators, presence, read receipts. Subscriptions are scoped to the authenticated user's data. The WebSocket server reads from the same Redis pub/sub channels used for event emission.

---

## 11. Federation Endpoints

These are the public-facing endpoints that remote servers interact with.

| Endpoint | Method | Content-Type | Purpose |
|---|---|---|---|
| `/.well-known/webfinger` | GET | `application/jrd+json` | Actor discovery |
| `/.well-known/nodeinfo` | GET | `application/json` | Server metadata |
| `/users/:username` | GET | `application/activity+json` | Actor document |
| `/users/:username/inbox` | POST | `application/activity+json` | Receive activities |
| `/users/:username/outbox` | GET | `application/activity+json` | Published activities |
| `/users/:username/followers` | GET | `application/activity+json` | Followers collection |
| `/users/:username/following` | GET | `application/activity+json` | Following collection |
| `/inbox` | POST | `application/activity+json` | Shared inbox |

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

### 12.5 Rate Limiting

Per-domain and per-actor rate limits on the inbox endpoints. Configurable thresholds. Exceeded limits return 429.

---

## 13. Encryption Integration Point

The encryption layer (MLS) is integrated into the middleware pipeline as two steps:

- **Inbound**: `decryptContent` — checks the object type manifest; if the object type requires encryption, unwraps the MLS ciphertext from the `content` field before persistence
- **Outbound**: `encryptContent` — checks the type manifest and relationship state; if encryption is required, wraps the `content` field in MLS ciphertext before delivery

The encryption steps are no-ops for unencrypted object types. The pipeline doesn't need to know about encryption details — it delegates to the encryption subsystem and passes the result along.

Key management, MLS group lifecycle, and the type manifest are defined in a separate TDD.

---

## 14. Redis Cache Strategy

Redis is used exclusively as a rebuildable cache. No data lives only in Redis.

### 14.1 Feed Cache

- Key: `<username>:feed:page:<cursor>`
- Value: Serialized page of feed entries
- TTL: Configurable (default: 5 minutes)
- Invalidation: On new activity (inbound or outbound), delete the user's feed cache keys
- Rebuild: On cache miss, query the user's `feed` table, populate cache, return

### 14.2 Actor Cache

- Key: `<username>:actor:<uri>`
- Value: Serialized actor document
- TTL: Matches the `fetched_at` TTL from the Postgres `actors` table
- Rebuild: On miss, query Postgres; if stale, fetch from remote

### 14.3 Session and Presence

- Key: `<username>:session:<token>` and `<username>:presence`
- These are ephemeral by nature — loss on Redis restart is acceptable
- Sessions fall back to re-authentication; presence resets to offline

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
