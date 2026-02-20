# 03 — ActivityPub Engine

## Purpose

All content and communication. Federation with the outside world. The object model. The encryption layer. The transport layer. This is the core of the platform.

## Responsibilities

- ActivityPub protocol (inbox, outbox, actors, WebFinger)
- Object model (all Lightweb types)
- HTTP Signature signing and verification
- MLS encryption (optional, per object type and relationship state)
- Transport selection (HTTP, WebSocket, future WebRTC)
- Content persistence (PostgreSQL)
- Feed caching (Redis)
- Real-time delivery (WebSocket server)

## Data Ownership

| Store      | What                                                                     |
| ---------- | ------------------------------------------------------------------------ |
| PostgreSQL | Activities, objects, conversations, followers, following, media metadata |
| Redis      | Feed cache, session tokens, pub/sub channels, presence                   |
| Filesystem | Nothing (config is owned by LLM Engine)                                  |

---

## Object Model

### LightwebObject

All content extends a common base with Lightweb namespace properties:

```typescript
interface LightwebObject extends ASObject {
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://lightwebbrowser.org/ns",
  ];
  type: LightwebObjectType;
  lwMetadata?: Record<string, unknown>;
  lwTags?: string[];
}
```

### Core Types (v1)

| Type        | AP Basis          | Encryption     | Description                     |
| ----------- | ----------------- | -------------- | ------------------------------- |
| Note        | Native (extended) | None           | Short-form posts, federated DMs |
| Article     | Native (extended) | None           | Long-form posts                 |
| ChatMessage | Proprietary       | Required (MLS) | E2EE chat messages              |
| Audio       | Native (extended) | None           | Podcast episodes, music         |
| Video       | Native (extended) | None           | Video content                   |
| Product     | Proprietary       | None           | Purchasable items               |

### Collections

Collections use AP's native `OrderedCollection`, extended with `lwMetadata.displayHint` for rendering. Menus, playlists, TV shows, storefronts, streams — all the same type, different display hint.

### Activity Types (v1)

| Activity                              | Usage                                          |
| ------------------------------------- | ---------------------------------------------- |
| Create                                | Create any object (Note, Article, ChatMessage) |
| Follow / Accept / Reject              | Follow lifecycle                               |
| Offer(Relationship) / Accept / Reject | Friend request lifecycle                       |
| Like / Dislike                        | Reviews and reactions                          |
| Announce                              | Boost / repost                                 |
| Delete                                | Remove owned objects                           |
| Undo                                  | Un-follow, un-like, un-boost                   |
| Add / Remove                          | Stream membership                              |
| Update                                | Modify owned objects                           |

### Tags

`lwTags` are free-form strings on any object. They drive filtering, sorting, and discovery. Not a controlled vocabulary.

### Reviews

Expressed via native AP objects — `Like` (positive), `Dislike` (negative), `Note` as `inReplyTo` (review blurb). No proprietary review type.

---

## Protocol Layers

### Layer 1: ActivityPub (Addressing & Activities)

All communication is AP activities between actors. The inbox is the universal destination.

**Federation endpoints:**

| Endpoint                       | Method | Purpose              |
| ------------------------------ | ------ | -------------------- |
| `/.well-known/webfinger`       | GET    | Actor discovery      |
| `/.well-known/nodeinfo`        | GET    | Server metadata      |
| `/users/:username`             | GET    | Actor object         |
| `/users/:username/inbox`       | POST   | Receive activities   |
| `/users/:username/outbox`      | GET    | Published activities |
| `/users/:username/followers`   | GET    | Followers collection |
| `/users/:username/following`   | GET    | Following collection |
| `/users/:username/streams`     | GET    | Topic streams        |
| `/users/:username/streams/:id` | GET    | Individual stream    |

**Security:** HTTP Signatures (RFC 9421) on all outbound requests. Signature verification on all inbox POSTs. Domain blocklist/allowlist via Config Registry.

### Layer 2: Encryption (MLS — Optional)

MLS (RFC 9420) wraps AP object payloads in E2EE. Whether encryption is applied depends on:

1. **Object type manifest** — `ChatMessage` requires encryption, `Note` does not
2. **Relationship state** — mutual relationships satisfying the `encrypted_chat` permission rule trigger MLS group creation

The encryption layer is transparent to the AP layer above it. An encrypted `ChatMessage` and an unencrypted `Note` both travel as AP `Create` activities. The encryption wraps the `content` field; the AP envelope (addressing, signatures) remains in cleartext for routing.

**MLS group model:**

| Scenario           | MLS Group                      |
| ------------------ | ------------------------------ |
| 1:1 encrypted chat | [alice, bob]                   |
| Group chat         | [alice, bob, carol, ...]       |
| Future: video call | Same group = same participants |

**Key management:**

- Keypairs generated client-side (Ed25519 for signing, X25519 for encryption)
- Encrypted server backup for account recovery
- MLS epoch advancement on membership changes (forward secrecy)

**Host server:** The creator's server acts as MLS Delivery Service — routes ciphertext, manages group state, never holds decryption keys. If host goes offline, oldest remaining member's server takes over.

### Layer 3: Transport (Delivery)

Transport is selected based on delivery requirements, not content type:

| Transport          | Used For                                       | Delivery           |
| ------------------ | ---------------------------------------------- | ------------------ |
| HTTP POST to inbox | Federation, async activities                   | Store-and-forward  |
| WebSocket          | Chat messages, typing, presence, read receipts | Real-time push     |
| WebRTC (future)    | Voice/video media streams                      | Peer-to-peer media |

A single conversation may use multiple transports over its lifetime:

- Starts as federated DM → HTTP POST
- Upgrades to encrypted chat → WebSocket for real-time, HTTP for federation fan-out
- Future: adds video → WebRTC for media, WebSocket for signaling

---

## Conversation Lifecycle

Every conversation follows a state machine driven by mutual relationship state:

```
FEDERATED DM                          ENCRYPTED CHAT
(Note, HTTP, no encryption)           (ChatMessage, WebSocket, MLS)

┌──────────────────────┐              ┌──────────────────────┐
│  Wire: Note          │   mutual     │  Wire: ChatMessage   │
│  Transport: HTTP     │  relationship│  Transport: WebSocket │
│  Encryption: none    │──────────►   │  Encryption: MLS     │
│  RCS: none           │  satisfies   │  RCS: full           │
│  Works with: any AP  │  encrypted_  │  Lightweb-only       │
│  server              │  chat rule   │                      │
└──────────────────────┘              └──────────────────────┘
                                       (irreversible)
```

Both types render in the same chat thread UI. The upgrade is per-relationship, automatic, and irreversible.

---

## Interfaces

"Direct" interface used in Direct input mode (chat threads, new posts, replies, comments). Same `ActionDispatch` shape the LLM Engine uses — the AP Engine handles it identically regardless of caller.

### Client → AP Engine (Direct GET)

```
GET /api/stream
  → Activity[]

GET /api/activity/:activityId
  → ActivityDetail (full object, chat thread, remote feed, etc.)
```

### Client → AP Engine (Direct POST)

```
POST /api/activity
{
  action: string
  params: Record<string, unknown>
}
```

### AP Engine → Client (Realtime)

```
WebSocket /ws
  → incoming ChatMessage, typing indicators, presence, read receipts
```

### Internal: LLM Engine → AP Engine (Action Dispatch)

The LLM Engine dispatches named actions. The AP Engine validates and executes them.

```typescript
interface ActionDispatch {
  action: string; // "Follow", "CreateNote", "SendMessage", etc.
  params: Record<string, unknown>;
}

interface ActionResult {
  success: boolean;
  activityId?: string; // AP activity ID if federation occurred
  error?: string;
}
```

**Fixed action vocabulary** (not extensible — security boundary):

| Action              | Params                            | Produces                            |
| ------------------- | --------------------------------- | ----------------------------------- |
| Follow              | { actorUri }                      | Follow activity                     |
| Unfollow            | { actorUri }                      | Undo(Follow)                        |
| SendFriendRequest   | { actorUri, relationshipType }    | Offer(Relationship)                 |
| AcceptFriendRequest | { offerId }                       | Accept(Offer)                       |
| RejectFriendRequest | { offerId }                       | Reject(Offer)                       |
| RemoveRelationship  | { actorUri, relationshipType }    | Local removal                       |
| CreateNote          | { content, tags?, streamTarget? } | Create(Note)                        |
| CreateArticle       | { title, content, tags? }         | Create(Article)                     |
| SendMessage         | { recipientUri, content }         | Create(Note) or Create(ChatMessage) |
| Reply               | { objectId, content }             | Create(Note) with inReplyTo         |
| Like                | { objectId }                      | Like                                |
| Unlike              | { objectId }                      | Undo(Like)                          |
| Dislike             | { objectId }                      | Dislike                             |
| UndoDislike         | { objectId }                      | Undo(Dislike)                       |
| Boost               | { objectId }                      | Announce                            |
| Unboost             | { objectId }                      | Undo(Announce)                      |
| DeleteObject        | { objectId }                      | Delete                              |
| CreateStream        | { name, tags? }                   | OrderedCollection + Actor update    |
| AddToStream         | { objectId, streamId }            | Add                                 |
| RemoveFromStream    | { objectId, streamId }            | Remove                              |

### External: Federation

Outbound: HTTP POST signed activities to remote inboxes.
Inbound: Receive and verify signed activities at local inbox.

### AP Engine → LLM Engine (Events)

When inbound activities arrive that warrant user-level handling, the AP Engine publishes a `SystemEvent` to a Redis pub/sub channel consumed by the LLM Engine. See [02-llm-engine.md](02-llm-engine.md) for the event type table and `SystemEvent` interface.

### Client-Facing: Feed, Real-Time & Direct Dispatch

```
GET  /api/feed              → Card[]
GET  /api/feed/:id          → CardDetail
POST /api/activity          → ActionDispatch (Direct mode — same shape as LLM Engine dispatch)
WS   /ws                    → real-time events (messages, typing, presence)
```

## Dependencies

- **LLM Engine**: receives action dispatches, reads permission state for encryption decisions, consumes events
- **PostgreSQL**: content persistence
- **Redis**: feed cache, pub/sub for real-time delivery, event emission to LLM Engine
- **External LLM API**: none (AP engine does not call the LLM)
