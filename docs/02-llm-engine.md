# 02 — LLM Engine

## Purpose

Interpret natural language intent and match it to a curated set of skills and actions. Own all configuration, permissions, and trust logic. The LLM Engine is the brain — it decides what the user means and dispatches the matching skill or action. If no skill or action matches, the LLM must decline — it is never allowed to make arbitrary or freeform changes.

Importantly, the LLM / any skill does not have internet access. While arbitrary skills are unquestionably accessible in today's internet, allowing this would defeat the other primary point of this software's model, which is precisely to curate internet communication for security reasons.

## Responsibilities

This module has a single primary responsiblity - natural language intent resolution to specific curated [skill].md

Out of the box skills will allow user to:

1. Change Config - Make config changes like 'Alias this contact as "dad"'
2. Dispatch Actions - Dispatch external actions like 'Follow dad'

These potentially hundreds of skills will replace all UI config & settings. Interestingly, there will also be very customizable event-based config that allowed custom triggering of actions based on events.

---

## Config Registry

This config is application level only - does not include server config like provider security keys

The LLM Engine owns all registry state.

**Storage:** Single JSON file (`config/registry.json`), loaded into memory at startup, atomic writes on mutation (temp file → rename).

**Version Control:** Must be programatically version controlled. (Git)

**Synchronization:** All modules must be notified of changes & reload. (Redis)

**Structure (top-level keys):**

| Key          | What                                                     |
| ------------ | -------------------------------------------------------- |
| `server`     | Domain, federation settings                              |
| `llm`        | Provider, model, API key env var                         |
| `ui`         | Animation, polling intervals                             |
| `messaging`  | DM policy, RCS settings (typing, receipts, presence)     |
| `social`     | Relationship types, contacts, permissions, follow policy |
| `trust`      | Account type                                             |
| `content`    | Post length limits                                       |
| `moderation` | Muted keywords, blocked users                            |
| `events`     | User-defined event workflows                             |
| `user`       | Profile (display name, bio, avatar), preferences         |

## Trust & Permissions

### Relationship Types

User-defined labels that describe who a contact is to you. Stored in `config.social.relationshipTypes` and fully customizable — the user can add, rename, or remove types via natural language ("add a relationship type called coworker").

**Defaults:**

| Type           | Meaning           |
| -------------- | ----------------- |
| `friend`       | Mutual friendship |
| `close friend` | Inner circle      |

Created via AP `Offer(Relationship)` / `Accept`. The type name is carried in the offer so both sides agree on the label.

**Following is not a relationship type.** Following is a content subscription managed by the AP Engine (AP Follow / Undo Follow). It is orthogonal — you can follow a stranger, or have a close friend you don't follow.

### Contact Registry

Stored in `config.social.contacts`, keyed by actor URI:

```json
{
  "https://bob.lightweb.cloud/users/bob": {
    "relationships": ["friend"],
    "aliases": ["bob", "Bob Smith"]
  }
}
```

Aliases enable LLM resolution — "message Bob" matches against these.

### Permission Rules

Boolean logic on relationship types and following state:

```json
{
  "encrypted_chat": { "any": ["friend", "close friend"] },
  "insecure_dm": { "any": ["following", "friend", "close friend"] },
  "see_presence": { "any": ["friend", "close friend"] },
  "see_read_receipts": { "any": ["close friend"] }
}
```

- `any` = OR (at least one relationship must exist)
- `all` = AND (all listed relationships must exist)

---

## Action API

All user-initiated actions flow through the Action API. The Action API is an exhaustive whitelist — if an intent does not match a registered skill or named action, the LLM must refuse the request. No freeform execution is permitted. Two domains:

### A) Internal Skills (Config Mutations)

Text-based skill definitions. Each skill declares its purpose, sandbox (allowed config paths), parameters, and behaviour. The LLM reads applicable skills at request time.

The LLM cannot write to config paths outside a skill's declared sandbox.

**Example skills:** set-display-name, set-read-receipts, block-domain, set-follow-policy, register-event, etc.

Highly user-extensible by design. Whether or not skills should be extensible by means natural language from client UIs is a topic of debate and would depend on quality - because having well defined and well tested skills are what will make the natural interface predictable.

### B) External Skills (AP Dispatch)

Skills definitions that produce AP activities. Dispatched to the AP Engine. Not user extensible - pluggable only — this is a security boundary.

See [03-activitypub.md](03-activitypub.md) for the full action vocabulary and dispatch interface.

### Event Skills

The AP Engine is the primary event producer — it is the first to know when a follow arrives, a DM lands, a friend request is received, etc. When something happens, the AP Engine emits a typed event to the LLM Engine over Redis pub/sub.

The LLM Engine consumes these events and matches them against **event skills** — skills that are triggered by events rather than user input. Event skills follow the same skill format (purpose, sandbox, parameters, behaviour) but declare a trigger instead of being invoked by the user.

**Example event skills:** notify-on-follow, auto-accept-friend-request, keyword-alert, etc.

Event skills can trigger any combination of internal config mutations or external AP actions, just like user-invoked skills.

**Event types (v1):**

| Event              | Source    | Payload                          |
| ------------------ | --------- | -------------------------------- |
| `follow.received`  | AP Engine | `{ actorUri }`                   |
| `dm.received`      | AP Engine | `{ actorUri, objectId }`         |
| `friend.requested` | AP Engine | `{ actorUri, relationshipType }` |
| `friend.accepted`  | AP Engine | `{ actorUri, relationshipType }` |
| `mention.received` | AP Engine | `{ actorUri, objectId }`         |
| `like.received`    | AP Engine | `{ actorUri, objectId }`         |
| `boost.received`   | AP Engine | `{ actorUri, objectId }`         |

Non-AP event sources (timers, schedules, client events) may be added later — the LLM Engine consumes from an event bus, and the AP Engine is the primary publisher.

---

## Interfaces

### Client → LLM Engine (Natural Language)

```
POST /api/natural_input
{
  userInput: string
  focusedActivityId?: string
  activePaneType: "feed" | "chat" | "draft" | "remote-feed"
  conversationHistory: Message[]
}
```

**Returns:**

```
{
  replyText: string
  actions: ActionResult[]
}
```

### LLM Engine → AP Engine (Activity Dispatch)

```
POST /api/dispatch
{
  action: string
  params: { ... }
}
```

### LLM Engine → Event Subsystem

The LLM Engine will have a scheduled event task that injects custom
events into the event queue, but it's out of scope for v1. For now, all events are generated from the AP engine.

## Dependencies

- **External LLM API**: Claude (default), swappable via config
- **AP Engine**: action dispatch target, permission query source
- **Config Registry**: owned state (JSON file)
