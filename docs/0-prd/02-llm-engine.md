# 02 — LLM Engine

## Purpose

Interpret natural language intent and match it to a curated set of skills and actions. Own all configuration, permissions, and trust logic. The LLM Engine is the brain — it decides what the user means and dispatches the matching skill or action. If no skill or action matches, the LLM must decline — it is never allowed to make arbitrary or freeform changes.

Importantly, the LLM / any skill does not have internet access. While arbitrary skills are unquestionably accessible in today's internet, allowing this would defeat the other primary point of this software's model, which is precisely to curate internet communication for security reasons.

## Responsibilities

This module has a single primary responsibility — natural language intent resolution to curated SDK tool definitions.

The LLM Engine uses the **Vercel AI SDK** to register tools with JSON Schema parameters and TypeScript handler functions. The model decides which tool to call and with what arguments; the handler executes it. Provider-portable across Claude, OpenAI, and Gemini with no changes to tool definitions.

Out of the box tools allow users to:

1. **Change Config** — Make config changes like 'Alias this contact as "dad"'
2. **Dispatch Actions** — Dispatch external actions like 'Follow dad'

These potentially hundreds of tools replace all UI config and settings. Event-based rules (see Event Rules below) provide user-customizable triggering of actions based on events.

---

## Config Registry

This config is application level only - does not include server config like provider security keys

The LLM Engine owns all registry state.

**Storage:** Per-user JSON file at `~/config/registry.json` (i.e. `/home/<username>/config/registry.json`), loaded into memory on request, atomic writes on mutation (temp file → rename). The LLM Engine resolves the config path from the authenticated user's Linux home directory.

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

## Tool API

All user-initiated actions flow through the Tool API. The Tool API is an exhaustive whitelist — if an intent does not match a registered tool, the LLM must refuse the request. No freeform execution is permitted. Two domains:

### A) Internal Tools (Config Mutations)

SDK tool definitions with JSON Schema parameters and TypeScript handler functions. Each tool declares its description (used by the model for intent matching), typed parameters, and a handler that reads/writes the Config Registry.

Config ACL is enforced in the handler — each tool may only write to its declared config paths. This is a code-level boundary, not a prompt-level one.

**Example tools:** set-display-name, set-read-receipts, block-domain, set-follow-policy, etc.

```typescript
const setReadReceipts = tool({
  description: 'Enable or disable read receipts for RCS messaging',
  parameters: z.object({
    enabled: z.boolean().describe('whether read receipts are on'),
  }),
  execute: async ({ enabled }) => {
    // enforces ACL: only messaging.rcs.read_receipts is writable
    await configRegistry.write('messaging.rcs.read_receipts', enabled);
    return { success: true };
  },
});
```

Internal tools are not user-extensible — they are authored, tested, and shipped as code. This ensures the natural language interface remains predictable and reliable.

### B) External Tools (AP Dispatch)

SDK tool definitions that produce AP activities. The handler dispatches to the AP Engine's action API. Not user-extensible — this is a security boundary.

See [03-activitypub.md](03-activitypub.md) for the full action vocabulary and dispatch interface.

### Event Rules

The AP Engine is the primary event producer — it is the first to know when a follow arrives, a DM lands, a friend request is received, etc. When something happens, the AP Engine emits a typed event to the LLM Engine over Redis Streams.

The LLM Engine consumes these events and matches them against **event rules** — user-configurable condition→action pairs stored in `config.events`. Unlike tools, event rules are user-extensible: users create them via natural language ("when someone follows me, auto-follow back") and they are persisted as structured config, not code.

**Event rule structure (stored in `config.events`):**

```json
{
  "rules": [
    {
      "id": "auto-follow-back",
      "trigger": "follow.received",
      "conditions": {},
      "actions": [{ "tool": "follow", "params": { "actorUri": "$event.actorUri" } }]
    },
    {
      "id": "keyword-alert",
      "trigger": "dm.received",
      "conditions": { "contentContains": "urgent" },
      "actions": [{ "tool": "notify", "params": { "priority": "high" } }]
    }
  ]
}
```

Event rules can trigger any registered tool (internal or external). The `$event.*` syntax references fields from the event payload. Conditions are evaluated in code — the LLM is not involved at event-processing time.

**Example rules:** auto-follow-back, auto-accept-friend-request, keyword-alert, notify-on-mention, etc.

Tools for managing event rules (create-event-rule, delete-event-rule, list-event-rules) are themselves internal tools — so users create and manage rules via natural language, but the rules execute deterministically without LLM involvement.

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

- **Vercel AI SDK**: Provider-portable tool use — registers tools with JSON Schema params, handles model calls across Claude, OpenAI, Gemini
- **External LLM API**: Claude (default), swappable via config
- **AP Engine**: action dispatch target, permission query source
- **Config Registry**: owned state (per-user JSON file in `~/config/registry.json`)
