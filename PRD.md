# Product Requirements Document (PRD)

## Lightweb Browser — ActivityPub Platform

**Version:** 0.6 (Draft)
**Status:** 🟡 In Progress
**Last Updated:** 2026-02-17

---

## 1. Overview

A new social & business media platform where content is created and controlled by you.

### 1.1 Mission Statement

To provide a simple and well-defined structure for communications which is conducive to accessibility mechanisms such as voice control and AR. Such structure not only relieves interface friction, but is inherently more secure and well integrated.

### 1.2 Problem Statement

Mainstream social media platforms are centralized, opaque, and buried in buttons, menus, and configuration screens. Existing Fediverse clients remain too technical and too cluttered for general audiences. And no social platform today provides a principled, interoperable model for trust — who can see what, who can act on whose behalf, and how those permissions evolve over time.

### 1.3 Vision

Lightweb Browser is a federated social platform built on ActivityPub, designed around three radical premises:

1. **There are no buttons.** Every interaction flows through a single persistent, context-aware input bar.
2. **Everything is allowlisted.** No action, content view, or configuration change is permitted until explicitly granted. Permissions evolve naturally over time.
3. **Trust is a first-class object.** The platform provides a structured, interoperable model for circles of trust — between family members, colleagues, communities — that is itself built on ActivityPub and extensible by anyone.

### 1.4 Design Philosophy

**"No Buttons"**

- No navigation tabs, no settings screens, no action menus
- All user intent is expressed as natural language or gesture
- The system infers what the user means based on what card is in focus
- When defaults are not enough, AI handles the remainder
- Configuration is never the user's problem — it's the system's problem

**"Allowlist, Never Deny"**

- Nothing is permitted until explicitly granted
- The default state for any unrecognised action is a permission request, not a refusal
- Permissions are granular, scoped, and evolve over time
- The system always tells you what _is_ allowed, never just says no

**"Trust is Structured"**

- Trust relationships are first-class ActivityPub objects, not platform-internal hacks
- They are interoperable, federatable, and extensible
- The same trust model that governs parent/child applies to employer/employee, community/member, etc.

### 1.5 App Name

**Lightweb Browser**

---

## 2. Goals & Success Metrics

| Goal                   | Metric                                                | Target (6 months post-launch) |
| ---------------------- | ----------------------------------------------------- | ----------------------------- |
| Federation reliability | % of ActivityPub interactions completing successfully | > 98%                         |
| AI intent resolution   | % of natural language inputs correctly actioned       | > 90%                         |
| Performance            | Feed load time (p95)                                  | < 1.5s on 4G                  |
| Accessibility          | WCAG 2.1 AA compliance                                | 100% of core flows            |

---

## 3. Target Audience

**Primary:** General public, all ages. No technical knowledge of federation or AI required.

**Key personas:**

- **The Privacy-Conscious User** — migrating from Twitter/X or Meta, wants data ownership without learning a new interface paradigm
- **The Community Builder** — wants to run a topic-based server, configure it naturally via AI without touching config files
- **The Casual Social User** — just wants to post and chat; finds existing social apps over-engineered
- **The Parent** — wants granular, evolving control over what their child can see, follow, and do — without a complex parental controls dashboard
- **The Protected Account** (child) — uses the platform naturally, with the trust system invisible; encounters graceful gates rather than confusing errors
- **The Business User** _(post-v1)_ — employee/employer trust relationships mirror the parent/child model

> ⚠️ **Design implication:** ActivityPub federation, AI/LLM systems, and the Circle of Trust must be completely invisible to end users. Users experience outcomes (content visible / not visible, action permitted / request sent) never mechanisms.

---

## 4. Scope

### 4.1 In Scope (v1.0 Launch)

- ✅ User registration and login (SSO only — Google and Facebook)
- ✅ Single-screen column navigator — 1 column on mobile by default, 2–3 on tablet; always user-configurable per device
- ✅ Feed as unified inbox — all events (messages, replies, follows, trust requests) arrive as cards; no separate notifications
- ✅ One card always in focus; persistent context-aware input bar always visible
- ✅ Left swipe → opens new column to the right (remote feed, chat thread, AI pane)
- ✅ Right swipe → AI mode for focused card
- ✅ **Chat-first messaging** — 1:1 and group chat, WhatsApp-equivalent, E2EE via MLS
- ✅ `ChatMessage` object type — dedicated type, always encrypted, separate from `Note`
- ✅ Group chat with host server model — creator's server is MLS Delivery Service
- ✅ Automatic group host migration — oldest remaining member's server takes over
- ✅ ActivityPub federation (inbox, outbox, followers, following, WebFinger)
- ✅ Native iOS and Android apps
- ✅ Web client (Next.js shell embedding the shared mobile UI component)
- ✅ Server-side LLM processor (Claude by default; swappable via config)
- ✅ In-memory JSON configuration registry (single source of truth for all config)
- ✅ Circle of Trust — account control model (open and controlled accounts)
- ✅ TrustRequest / TrustGrant object types — permission escalation via ActivityPub
- ✅ Allowlist permission model for all actions and config objects
- ✅ LightwebObject base type with typed extension system (internal v1)
- ✅ Encryption defined per extension manifest — `ChatMessage`: required, `Note`: none
- ✅ Review object type — 👍 / 👎 + blurb, applicable per object type
- ✅ MLS (RFC 9420) E2EE for ChatMessage and TrustRequest objects
- ✅ Hybrid key storage — client-side primary, encrypted server backup
- ✅ Managed hosting — Lightweb Cloud, dedicated container per user

### 4.2 Out of Scope (v1.0)

- ❌ Push notifications (replaced by feed cards)
- ❌ Video chat (v2 — same host server model, adds SFU)
- ❌ Video hosting / media
- ❌ Groups / communities (distinct from group chat)
- ❌ Stories / ephemeral content
- ❌ Monetization / creator tools
- ❌ Admin moderation dashboard (manual DB tooling only at launch)
- ❌ Comments (replaced by structured Review objects)
- ❌ Public extension namespace publication — internal v1 only
- ❌ Business / employer trust relationships (post-v1)

---

## 5. Technical Architecture

### 5.1 High-Level Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
│                                                                  │
│  iOS (React Native)   Android (React Native)   Web (Next.js)     │
│        └─────────────── Solito shared UI ──────────┘            │
│                              │                                   │
│         ┌────────────────────┤                                   │
│         │  Embedded Mobile   │  ← Web renders same RN component  │
│         │  UI Component      │    inside a Next.js shell         │
│         └────────────────────┘                                   │
└──────────────────────────────┬───────────────────────────────────┘
                               │ HTTPS / REST + WebSockets
┌──────────────────────────────▼───────────────────────────────────┐
│                      API GATEWAY (Next.js)                        │
│   - Auth (JWT / OAuth2 — Google, Facebook)                        │
│   - REST API for all clients                                      │
│   - React Server Components (web shell)                           │
│   - Rate limiting, input validation                               │
│   - Routes natural language inputs → LLM Service                 │
└──────────┬───────────────────────────────────────┬───────────────┘
           │                                       │
┌──────────▼──────────┐  ┌───────────────┐  ┌─────▼──────────────┐
│  ActivityPub Service │  │  LLM Service  │  │   Media Service    │
│  (Fastify / Node.js) │  │  (Fastify)    │  │   (Node.js)        │
│                      │  │               │  │                    │
│  - Inbox / Outbox    │  │  - Receives   │  │  - Image upload    │
│  - Actor management  │  │    input +    │  │  - Resize / CDN    │
│  - WebFinger         │  │    context    │  │  - S3 storage      │
│  - Federation        │  │  - Reads /    │  └────────────────────┘
│  - HTTP Signatures   │  │    writes     │
└──────────┬───────────┘  │    Config     │
           │              │    Registry   │
           │              │  - Calls LLM  │
           │              │    provider   │
           │              │    (Claude)   │
           │              └───────┬───────┘
           │                      │
           │              ┌───────▼────────────┐
           │              │  Config Registry   │
           │              │  (JSON file,       │
           │              │   always in memory)│
           │              └────────────────────┘
           │
┌──────────▼──────────────────────────────────────────────────────┐
│                          DATA LAYER                              │
│                                                                  │
│   PostgreSQL (content only)        Redis (cache + pub/sub)       │
│   - Users, posts, follows          - Feed caching               │
│   - AP objects / activities        - Session store              │
│   - Media metadata                 - Real-time DM delivery      │
│                                                                  │
│   ⚠️  No configuration in PostgreSQL. All config is in the     │
│       JSON Config Registry (see §8).                            │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Technology Choices

| Layer                | Technology                             | Rationale                                             |
| -------------------- | -------------------------------------- | ----------------------------------------------------- |
| Mobile frontend      | **React Native** (via Expo)            | Native components on iOS & Android                    |
| Web frontend         | **Next.js 14+** (App Router)           | Embeds shared RN UI; RSC for web shell                |
| Code sharing         | **Solito**                             | Unified navigation + components across RN and Next.js |
| ActivityPub backend  | **Fastify** (Node.js)                  | High-performance; built-in schema validation          |
| LLM service          | **Fastify** (Node.js)                  | Isolated service; clean provider swap interface       |
| Language             | **TypeScript** throughout              | Monorepo type safety end to end                       |
| Database             | **PostgreSQL**                         | Content only; JSONB for ActivityPub objects           |
| Cache / realtime     | **Redis**                              | Feed caching, pub/sub for DMs                         |
| Object storage       | **S3-compatible** (e.g. Cloudflare R2) | Media hosting                                         |
| Monorepo tooling     | **Turborepo**                          | Shared packages, incremental builds                   |
| Initial LLM provider | **Claude (Anthropic)**                 | Default; swappable via config registry                |

### 5.3 Web Client Strategy

The web client is a **Next.js application** with two roles:

1. **Shell:** Next.js handles routing, auth, SSR metadata, and the outer browser chrome
2. **Embedded UI:** The exact same React Native UI component used on mobile is embedded inside the shell via `react-native-web`

This means the mobile UI and web UI share **identical code.** The web shell adds browser-native affordances (URL routing, tab title, keyboard shortcut hints). The core feed, input bar, and swipe interactions are the same on all platforms.

> 📌 The web experience intentionally looks and feels like a mobile app running in a browser — this is by design, not a limitation.

---

## 6. ActivityPub Implementation

### 6.1 Required Endpoints

| Endpoint                     | Method | Purpose                      |
| ---------------------------- | ------ | ---------------------------- |
| `/.well-known/webfinger`     | GET    | Actor discovery              |
| `/.well-known/nodeinfo`      | GET    | Server metadata              |
| `/users/:username`           | GET    | Actor object                 |
| `/users/:username/inbox`     | POST   | Receive federated activities |
| `/users/:username/outbox`    | GET    | Published activities         |
| `/users/:username/followers` | GET    | Followers collection         |
| `/users/:username/following` | GET    | Following collection         |

### 6.2 Activity Types (v1.0)

- `Create` (Note) — posts and DMs
- `Follow` / `Accept` / `Reject`
- `Like`
- `Announce` — boosts / reposts
- `Delete`
- `Undo` — un-follow, un-like, un-boost

### 6.3 Security Requirements

- HTTP Signatures on all outgoing federated requests (RFC 9421 / draft-cavage)
- Signature verification on all incoming inbox POST requests
- Domain blocklist / allowlist support (configured via Config Registry)

---

## 7. Feature Requirements

### 7.1 Feed UI — Column Navigator Model

The entire UI is built on a single primitive: the **column navigator**. There is one screen. It contains one or more columns. Every navigation action adds a column to the right and optionally compresses or removes columns to the left. There are no pages, no modals, no navigation stack in the traditional sense.

#### Column Count — Device Defaults & User Configuration

| Device         | Default columns | Minimum | Maximum |
| -------------- | --------------- | ------- | ------- |
| Mobile phone   | 1               | 1       | 2       |
| Tablet (small) | 2               | 1       | 3       |
| Tablet (large) | 3               | 1       | 4       |
| Web (desktop)  | 2               | 1       | 4       |

Column count is **user-configurable per device** via the Config Registry (via LLM: _"show me two columns on my phone"_). The device default is applied on first use only.

#### What a Column Is

Every column is a **vertical scrolling feed** of cards, with the persistent input bar anchored at the bottom. The leftmost column is always the home feed. Additional columns open to the right on left-swipe, each representing a different context (remote feed, chat thread, AI conversation, etc.).

```
1 COLUMN (mobile default)        2 COLUMNS (tablet / after swipe)
┌──────────────────────┐         ┌───────────┬──────────────────┐
│  HOME FEED           │         │ HOME FEED │ CHAT / REMOTE    │
│                      │         │           │                  │
│  [Card A]            │         │ [Card A]  │ [Message 1]      │
│ ╔════════════╗       │         │╔═════════╗│ [Message 2]      │
│ ║ [Card B]   ║ focus │  swipe  │║[Card B] ║│ [Message 3]      │
│ ╚════════════╝       │ ──────▶ │╚═════════╝│                  │
│  [Card C]            │  left   │ [Card C]  │                  │
│                      │         │           │                  │
├──────────────────────┤         ├───────────┼──────────────────┤
│  [Reply to @alice…]  │         │[Reply…  ] │ [Type a message] │
└──────────────────────┘         └───────────┴──────────────────┘
```

On a 1-column device, left-swipe replaces the current column entirely (the home feed slides off-screen left). Swiping right on the new column restores the home feed. Same physics, column count determines whether "replace" or "add" occurs.

#### One Card Always In Focus

Across all columns, exactly **one card is in focus** at any time — the last card tapped or scrolled to. The input bar at the bottom of each column reflects the focused card in that column. When focus moves to a card in a different column, that column's input bar becomes active.

---

### 7.2 The Persistent Input Bar

The input bar is the **only** interactive control in the entire UI. It is permanently anchored to the bottom of the screen, above the system keyboard.

**There are no buttons anywhere in the app.**

#### Context-Dependent Behaviour

The bar's mode, placeholder text, and submit action are determined entirely by the **focused card** and **current pane.**

| Pane state              | Focused card            | Placeholder                                   | Submit action     |
| ----------------------- | ----------------------- | --------------------------------------------- | ----------------- |
| Home feed               | Post from followed user | `Reply to @alice…`                            | ActivityPub reply |
| Home feed               | DM thread               | `Reply…`                                      | DM reply          |
| Home feed               | Own post or empty       | `What's on your mind?`                        | New post          |
| Remote feed (left pane) | Remote post             | `Reply to @bob@remote.social…`                | Federated reply   |
| AI pane (right pane)    | Any card                | `Ask about this, or say what you want to do…` | Sent to LLM       |

#### Ambiguous Input Routing

If a user's input in the home feed doesn't match a default action pattern, it is silently routed to the LLM service for interpretation. From the user's perspective, the system simply understood them.

#### Mode Switching

Modes change **only** via gesture (swipe) or focus change. There is no button, icon, or control to change the input mode. The user never thinks about modes — they only think about what card they're looking at.

---

### 7.3 Swipe Interactions — The Column Navigator in Action

All navigation is expressed as horizontal swipes on cards. Left swipe opens a new column to the right. Right swipe closes the rightmost column and returns focus left. There are no other navigation gestures.

#### Left Swipe → Opens New Column (Context-Dependent)

The content of the new column depends on the **type of the swiped card:**

| Swiped card type                    | New column content                                         |
| ----------------------------------- | ---------------------------------------------------------- |
| `Note` from remote server           | Origin server's public feed, card in chronological context |
| `ChatMessage` (incoming message)    | Full E2EE chat thread with that contact or group           |
| `TrustRequest`                      | Trust context for that request                             |
| Follow / activity notification card | That actor's feed                                          |

On a 1-column device (mobile default), the new content **replaces** the current column — the home feed slides fully off-screen left and the new content is full screen. Swipe right to return. On a 2+ column device, the new content opens as a new right column; existing columns compress left.

#### Right Swipe → AI Mode Column

Right swipe on any focused card opens the AI pane as a new column to the right. The full ActivityPub object of the swiped card is injected into the LLM context. Input bar becomes the AI chat interface.

**Example AI interactions:**

- `"Unfollow"` → LLM dispatches `Undo Follow` activity
- `"Block this server"` → LLM updates Config Registry domain blocklist
- `"Translate this"` → LLM returns translated text inline
- `"What can I do here?"` → LLM describes available actions in plain language
- `"Mute words like this"` → LLM updates muted keywords in Config Registry
- `"Change my bio to…"` → LLM updates user profile via API

#### The Home Feed as Unified Inbox

The home feed is the **single inbox for all events** — messages, posts, follow notifications, trust requests, reviews. There are no separate notification screens, badge counts, or inbox/feed distinctions.

```
HOME FEED — unified inbox (newest at bottom)
┌─────────────────────────────────────┐
│  📣 @bob posted: "Check this out"   │  ← Note  — swipe left → remote feed
│                                     │
│  🔔 @carol followed you             │  ← Follow — swipe left → @carol's feed
│                                     │
│  🔒 Trust request from @child       │  ← TrustRequest — swipe left → trust view
│                                     │
│ ╔═════════════════════════════════╗ │
│ ║ 💬 @alice: hey are you free?   ║ │  ← ChatMessage card — focused
│ ╚═════════════════════════════════╝ │    swipe left → opens full chat thread
├─────────────────────────────────────┤
│  Reply to @alice…           [Send]  │  ← Input bar reflects focused card
└─────────────────────────────────────┘
```

#### Swipe Mechanics

- Commit threshold: `ui.swipe_commit_threshold` in Config Registry (default: 0.4 = 40% screen width)
- Commit velocity: `ui.swipe_velocity_threshold` (default: 800px/s)
- Below both thresholds: card springs back, no navigation
- Animation: ~300ms ease-in-out; card motion physically continuous throughout
- Must not conflict with vertical scroll or horizontal scroll within cards

---

### 7.4 LLM Service

The LLM Service is **server-side only.** The client never calls an LLM provider directly.

#### Request Flow

```
Client sends: { userInput, focusedCardId, paneState, conversationHistory }
       │
       ▼
API Gateway validates + enriches with full card ActivityPub object
       │
       ▼
LLM Service:
  1. Load Config Registry (already in memory)
  2. Build system prompt: server config + card context + available actions
  3. Call LLM provider (Claude by default)
  4. Parse response → { replyText, actions[] }
  5. Execute actions[] via ActivityPub Service or Config Registry writer
  6. Return replyText to client
```

#### Provider Abstraction

```typescript
interface LLMProvider {
  complete(systemPrompt: string, messages: Message[]): Promise<LLMResponse>;
}
// Registered providers: ClaudeProvider | OpenAIProvider | GeminiProvider
// Active provider determined by config.llm.provider at startup
```

Switching LLM providers requires only a change to `config/registry.json` and a server restart. No code changes.

#### LLM Permissions

| The LLM **can**                                                     | The LLM **cannot**                    |
| ------------------------------------------------------------------- | ------------------------------------- |
| Read entire Config Registry                                         | Read or write PostgreSQL directly     |
| Write scoped Config Registry keys                                   | Access another user's data            |
| Dispatch ActivityPub activities on behalf of the authenticated user | Make arbitrary outbound network calls |
| Return natural language responses                                   | Modify server infrastructure          |
| Describe available actions for any card context                     |                                       |

---

### 7.5 Chat — 1:1 and Group Messaging

Chat is a **first-class, primary feature** of Lightweb Browser v1 — equivalent in importance to the social feed. All chat messages use the `ChatMessage` object type (not `Note`) and are always end-to-end encrypted via MLS.

#### The ChatMessage Object Type

`ChatMessage` is a dedicated `LightwebObject` type with `encryption: "required"` in its extension manifest. It is structurally separate from `Note` (social post) — they are never conflated.

```jsonc
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://lightwebbrowser.org/ns",
  ],
  "type": "ChatMessage",
  "id": "https://alice.lightweb.cloud/messages/abc123",
  "actor": "https://alice.lightweb.cloud/users/alice",
  "to": ["https://bob.lightweb.cloud/users/bob"], // 1:1
  // or for group:
  // "to": ["https://alice.lightweb.cloud/groups/friendgroup"],
  "lwMetadata": {
    "mlsGroupId": "mls-group-uuid", // identifies the MLS group
    "mlsEpoch": 42, // MLS epoch at time of send
    "replyTo": "message-id-optional", // threaded reply reference
  },
  "content": "<mls-ciphertext>", // always ciphertext, never plaintext
  "published": "2026-02-17T12:00:00Z",
}
```

#### Conversation Model

A conversation is an ActivityPub `Collection` — a persistent ordered set of `ChatMessage` objects between a fixed set of actors. It maps 1:1 to an MLS group.

```
Conversation (Collection)
  ├── id: https://alice.lightweb.cloud/conversations/xyz
  ├── type: "Conversation"          // LightwebObject extension
  ├── members: [alice, bob]         // or [alice, bob, carol, ...]
  ├── hostServer: alice.lightweb.cloud   // MLS Delivery Service
  └── messages: [ChatMessage, ...]  // ordered, oldest first
```

#### Arriving in the Feed

Incoming chat messages arrive as **`ChatMessage` cards in the home feed**, alongside posts and other events. They are visually distinct (e.g. chat bubble icon, sender avatar, message preview). There is no separate inbox.

Tapping or focusing a chat card and swiping left opens the **full chat thread** as a new column. On mobile (1-column), this is full screen. On tablet/web, it opens as the right column.

#### Chat Thread Column

```
CHAT THREAD COLUMN (full screen on mobile)
┌─────────────────────────────────────┐
│  ← @alice                           │  ← swipe right anywhere = back to feed
│                                     │
│  Hey are you free tonight?          │  alice (oldest)
│                          Yeah! Why? │  you
│  Want to grab dinner?               │  alice
│                    Sure, where?     │  you
│  That new place on Main St 🍜       │  alice (newest, at bottom)
│                                     │
├─────────────────────────────────────┤
│  Reply to @alice…           [Send]  │
└─────────────────────────────────────┘
```

- Newest messages at the bottom — same chronological convention as the feed
- Real-time delivery via WebSockets; fallback polling every 5s
- Read receipts: delivered / read states tracked per message per member
- Message states visible to sender only (no read receipt broadcasting by default — configurable)

#### Group Chat

Group conversations work identically to 1:1, with the following additions:

- Group has a name, optional avatar, and a member list
- The **creator's server** is the MLS Delivery Service (host server) for the group
- Host server maintains MLS group state (membership epochs, encrypted key packages) — it never holds decryption keys
- All messages route through the host server, which fans out to member servers via ActivityPub
- Member servers deliver to their users' clients

**Host migration (automatic):**
If the host server goes offline, the **oldest remaining member's server** automatically assumes the Delivery Service role. MLS handles the key rotation via a commit. No user action required. Migration completes within one reconnection cycle.

**Group membership changes:**

- Adding a member: any existing member can add (subject to their Circle of Trust allowlist)
- Removing a member: any member can remove themselves; group admin can remove others
- Every membership change triggers an MLS commit and key rotation — past messages remain inaccessible to removed members (forward secrecy)

#### Initiating a New Chat

No buttons. The user focuses any card from another user and types a message in the input bar. The LLM infers intent and creates a new conversation if one doesn't exist, or routes to the existing thread if it does. The user never thinks about "creating a conversation."

---

### 7.6 User Profiles & Auth

- Username format: `@user@yourdomain.com`
- Profile fields: display name, bio, avatar, header image, up to 4 custom fields
- **Auth: SSO only — Google and Facebook OAuth2. Zero password management.**
  - Account auto-provisioned from SSO identity on first login
  - No email/password fallback; no password reset flows
  - Store only the OAuth2 subject ID + provider, never credentials
- JWT sessions with refresh token rotation (expiry configurable via Config Registry)

---

## 8. Circle of Trust

### 8.1 Philosophy

> **Allowlist, never deny. Nothing is permitted until explicitly granted. Permissions evolve.**

The Circle of Trust is the platform's answer to the question: _who is allowed to do what, and who decides?_ It is not a parental controls feature bolted on after the fact — it is a core architectural primitive that applies equally to families, businesses, communities, and any other trust relationship.

### 8.2 Account Types

Every account is exactly one of two types:

**Open Account**
Full autonomy. The account holder controls all their own actions and all their own configuration objects. No external approval required for any action.

**Controlled Account**
All actions and all configuration object writes are gated by one or more controlling accounts. The controlled account cannot act outside its allowlist without generating a `TrustRequest`. The controlling account's LLM can read and write the controlled account's configuration, but **cannot execute actions on the controlled account's behalf.**

```
Open Account                    Controlled Account
┌─────────────────┐             ┌─────────────────────────────────┐
│  Full autonomy  │             │  Controller: @parent@server.com │
│  Own config     │             │                                  │
│  Own actions    │             │  Allowed actions: [Reply, Like]  │
└─────────────────┘             │  Locked config: [purchases,      │
                                │    follow-list, content-filters] │
                                │  Editable config: [layout, theme]│
                                └─────────────────────────────────┘
```

### 8.3 The TrustRequest Object

When a controlled account attempts an action not on their allowlist, the system does not show an error. Instead it creates a `TrustRequest` — a native ActivityPub object that travels to the controller's feed as a card.

```jsonc
// LightwWeb extension: TrustRequest
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://lightwebbrowser.org/ns", // internal v1; published post-v1
  ],
  "type": "TrustRequest",
  "id": "https://server.com/trust-requests/abc123",
  "actor": "https://server.com/users/child", // requesting account
  "controller": "https://server.com/users/parent", // approving account
  "requestedAction": {
    "type": "Follow",
    "object": "https://remote.social/users/creator",
  },
  "scope": "persistent", // "once" | "persistent" | "content-only"
  "context": {
    // the card that triggered the request
    "type": "Note",
    "id": "https://remote.social/notes/xyz",
  },
  "message": "My friend shared something from @creator — can I follow them?",
  "status": "pending", // "pending" | "approved" | "denied"
}
```

**TrustRequest scopes:**

| Scope          | Meaning                                                                 | Config change             |
| -------------- | ----------------------------------------------------------------------- | ------------------------- |
| `once`         | Approve viewing this specific post only                                 | None                      |
| `content-only` | Allow future content from this account visible in feed (without follow) | Adds to content allowlist |
| `persistent`   | Full follow permission granted                                          | Adds to follow allowlist  |

The LLM resolves the child's natural language request (_"ask my dad if I can see this"_) to the most conservative applicable scope, unless context suggests otherwise.

### 8.4 Approval Flow on the Controller's Feed

The `TrustRequest` arrives as a card in the controller's (parent's) feed. The card is in focus. The input bar default action is **Approve** — so the controller just hits send. Denial requires entering AI mode (right swipe) and providing a reason, which is delivered back to the child's feed as a message.

```
Controller's feed:
┌────────────────────────────────────────────┐
│  🔔 Trust Request from @child              │
│  "@creator posted something my friend      │
│   shared. Can I follow them?"              │
│                                            │
│  Requested: Follow @creator@remote.social  │
│  Scope: persistent                         │
└────────────────────────────────────────────┘
├────────────────────────────────────────────┤
│  Approve                           [Send]  │  ← Default action: Approve
└────────────────────────────────────────────┘

To deny: right swipe → AI mode → explain why
```

### 8.5 Configuration Object Permissions

The Config Registry is divided into named configuration objects. Each object is independently permissioned per controlled account.

| Config object     | Example contents                 | Default for child account |
| ----------------- | -------------------------------- | ------------------------- |
| `layout`          | Card size, feed density          | ✅ Editable by account    |
| `theme`           | Colours, font size               | ✅ Editable by account    |
| `follow-list`     | Who account follows              | 🔒 Controller only        |
| `content-filters` | Muted keywords, blocked domains  | 🔒 Controller only        |
| `purchases`       | Payment methods, spending limits | 🔒 Controller only        |
| `account-profile` | Display name, bio, avatar        | 🟡 Configurable           |
| `trust-settings`  | Controller relationships         | 🔒 Controller only        |

**Controller LLM access to controlled account config:**

- The controller's LLM can read and write any locked config object on the controlled account
- The controller's LLM **cannot** execute actions (Follow, Purchase, Post, etc.) on behalf of the controlled account
- All controller config writes are logged as ActivityPub activities on both accounts

### 8.6 Multiple Controllers

A controlled account may have multiple controllers (e.g. two parents). **Any single controller acting alone is sufficient** to approve a `TrustRequest` or modify the controlled account's configuration. There is no consensus requirement and no per-action-type differentiation — first controller to respond wins.

This keeps the model simple and avoids deadlock (a child waiting indefinitely for both parents to agree). The tradeoff — that one parent can approve something the other might not — is an intentional social/family policy decision, not a platform concern.

### 8.7 Future Extension: Business Use Case

The identical model applies to business relationships post-v1:

```
Parent    → Child        becomes    Manager   → Employee
Controller → Controlled             Controller → Controlled

TrustRequest("Purchase", vendor)    TrustRequest("Follow", competitor_account)
```

No new primitives required. Only new extension manifests defining business-relevant object types and action vocabularies.

---

## 9. Object Model & Extension Architecture

### 9.1 Design Philosophy

Lightweb Browser uses a **minimal, curated set of core object types.** Every type is formally defined, internally maintained, and openly published as a spec so other ActivityPub implementors may adopt them. No third-party plugins exist — all types are first-party. Richness comes not from proliferating types but from **hierarchy and metadata tags.**

> The pudding is in the organisation, not the type count.

### 9.2 Core Object Types (v1)

```typescript
interface LightwebObject extends ASObject {
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://lightwebbrowser.org/ns",
  ];
  type: LightwebObjectType;
  lwMetadata?: Record<string, unknown>; // type-specific structured descriptors
  lwTags?: string[]; // arbitrary filterable/sortable tags
  lwTrustScope?: TrustScope;
  lwEncrypted?: boolean; // true = MLS-encrypted payload
}

type LightwebObjectType =
  | "Note" // social post
  | "ChatMessage" // E2EE chat message (always encrypted)
  | "TrustRequest" // permission escalation (always encrypted)
  | "TrustGrant" // permission approval (always encrypted)
  | "Review" // 👍/👎 + blurb
  | "Product" // any purchasable thing — physical, digital, or service
  | "MediaItem" // any media — episode, movie, track, video
  | "LWCollection"; // groups any objects at arbitrary depth (extends AP OrderedCollection)
```

**That's it.** Eight types. Everything else — menus, TV shows, podcasts, storefronts, playlists — is expressed as `LWCollection` hierarchies of `Product` and `MediaItem` objects with appropriate `lwTags` and `lwMetadata`.

### 9.3 The LWCollection — Universal Container

`LWCollection` extends ActivityPub's `OrderedCollection` with Lightweb metadata. It can contain any `LightwebObject` including other `LWCollection`s, enabling **arbitrary-depth hierarchies** with no schema changes.

```jsonc
// A restaurant menu
{
  "@context": ["https://www.w3.org/ns/activitystreams", "https://lightwebbrowser.org/ns"],
  "type": "LWCollection",
  "id": "https://restaurant.lightweb.cloud/objects/menu-2026",
  "name": "Spring Menu",
  "lwMetadata": { "displayHint": "menu", "currency": "USD" },
  "lwTags": ["restaurant", "italian"],
  "orderedItems": [
    {
      "type": "LWCollection",           // category
      "name": "Starters",
      "lwTags": ["starters"],
      "orderedItems": [
        {
          "type": "Product",
          "name": "Bruschetta",
          "lwMetadata": { "price": 9.00, "description": "Toasted bread, tomato, basil" },
          "lwTags": ["vegan", "gluten-free-option"]
        }
        // ... more products
      ]
    }
    // ... more categories
  ]
}

// A TV show — identical structure, different tags
{
  "type": "LWCollection",
  "name": "The Last of Us",
  "lwMetadata": { "displayHint": "tvshow", "studio": "HBO" },
  "lwTags": ["drama", "sci-fi", "mature"],
  "orderedItems": [
    {
      "type": "LWCollection",           // season
      "name": "Season 1",
      "lwTags": ["season"],
      "orderedItems": [
        {
          "type": "MediaItem",
          "name": "S1E1 — When You're Lost in the Darkness",
          "lwMetadata": { "duration": 4920, "format": "4K", "episodeNumber": 1 },
          "lwTags": ["episode"]
        }
        // ... more episodes
      ]
    }
  ]
}
```

The `lwMetadata.displayHint` field tells the client **how to render** the collection card — as a menu, a storefront, a show, a playlist, etc. The data structure is identical; only the presentation hint differs.

### 9.4 The Product Type

`Product` covers any purchasable thing — physical goods, digital downloads, and services. Services are not a separate type; they are `Product` objects with `lwTags: ["service"]`.

```jsonc
{
  "type": "Product",
  "id": "https://shop.lightweb.cloud/objects/product-abc",
  "name": "Handmade Ceramic Mug",
  "lwMetadata": {
    "price": 28.0,
    "currency": "USD",
    "description": "Hand-thrown, food-safe glaze",
    "inventory": 12,
    "variants": [
      { "name": "Colour", "options": ["White", "Slate", "Terracotta"] },
    ],
  },
  "lwTags": ["handmade", "ceramic", "kitchenware"],
  "attachment": [{ "type": "Image", "url": "..." }],
}
```

**Available actions:** Purchase, Save, Share, Review, React

### 9.5 The MediaItem Type

`MediaItem` covers any media — a podcast episode, TV episode, movie, music track, or short video. The distinction between a "podcast" and a "TV show" is expressed via `lwTags` and parent `LWCollection`, not by type.

```jsonc
{
  "type": "MediaItem",
  "id": "https://media.lightweb.cloud/objects/ep-001",
  "name": "Episode 1 — The Beginning",
  "lwMetadata": {
    "duration": 2700, // seconds
    "format": "audio", // "audio" | "video" | "4K" | "HD" | "SD"
    "streamUrl": "...", // resolved server-side, never exposed to untrusted clients
    "episodeNumber": 1,
  },
  "lwTags": ["podcast", "technology", "interview"],
}
```

**Available actions:** Play, Save, Share, Review, React

### 9.6 Type → Action Vocabulary

| Object type    | Available actions                    | Reviewable                | Encrypted |
| -------------- | ------------------------------------ | ------------------------- | --------- |
| `Note`         | Reply, Like, Boost, Delete           | ✅ Yes                    | ❌ No     |
| `ChatMessage`  | Reply, Delete                        | ❌ No                     | ✅ Always |
| `TrustRequest` | Approve, Escalate                    | ❌ No                     | ✅ Always |
| `TrustGrant`   | Revoke                               | ❌ No                     | ✅ Always |
| `Review`       | Like, Boost, Delete                  | ❌ No                     | ❌ No     |
| `Product`      | Purchase, Save, Share, Review, React | ✅ Yes                    | ❌ No     |
| `MediaItem`    | Play, Save, Share, Review, React     | ✅ Yes                    | ❌ No     |
| `LWCollection` | Browse, Save, Share, React           | 🟡 Inherits from children | ❌ No     |

### 9.7 Tags — Filtering and Discovery

`lwTags` are arbitrary string tags on any object or collection. They drive filtering, sorting, and discovery. Examples:

```
Product tags:    "vegan", "gluten-free", "handmade", "service", "digital"
MediaItem tags:  "podcast", "episode", "movie", "4K", "mature", "documentary"
Collection tags: "restaurant", "menu", "tvshow", "season", "playlist", "storefront"
Note tags:       (user-defined, used for search and muting)
```

Tags are not a controlled vocabulary — they are free strings. The LLM can suggest tags when an object is created and can filter feeds by tag on user request (_"show me only vegan items"_, _"hide mature content"_).

### 9.8 Action Parameters & Registry Defaults

Every action has parameters with registry-stored defaults, adjustable via LLM.

```jsonc
// Extension manifest: MediaItem
{
  "extension": "lightwebbrowser.org/ns/media",
  "objectType": "MediaItem",
  "encryption": "none",
  "reviewable": true,
  "actions": [
    {
      "verb": "Play",
      "parameters": [
        {
          "name": "device",
          "type": "enum",
          "options": ["TV", "Phone", "Tablet", "Desktop"],
          "registryDefault": "user.preferences.playback.device",
        },
        {
          "name": "quality",
          "type": "enum",
          "options": ["SD", "HD", "4K"],
          "registryDefault": "user.preferences.playback.quality",
        },
      ],
    },
    {
      "verb": "Purchase",
      "parameters": [
        {
          "name": "paymentMethod",
          "type": "ref",
          "registryDefault": "user.preferences.payment.defaultMethod",
        },
      ],
    },
  ],
  "llmContext": {
    "intentExamples": [
      "watch this",
      "play it",
      "put it on the TV",
      "listen to this",
    ],
    "parameterPrompts": {
      "device": "which device?",
      "quality": "what quality?",
    },
  },
  "registryDefaults": {
    "user.preferences.playback.device": "TV",
    "user.preferences.playback.quality": "HD",
  },
  "trustRequirements": {
    "Play": "content-only",
    "Purchase": "persistent",
  },
}
```

**The LLM does not need retraining for object types.** Each extension manifest is injected into the LLM system prompt at request time — new types teach the LLM new nouns and verbs via natural language description.

### 9.9 JSON-LD Namespace & Publishing

Extensions are published as JSON-LD context documents at `https://lightwebbrowser.org/ns`. Other ActivityPub servers may implement these types as they wish. Lightweb does not control or gate third-party implementations — the spec is open, the implementation is curated.

**Publishing roadmap:**

- **v1:** Internal — namespace not publicly resolvable; spec documented internally
- **v2:** Publish `TrustRequest`, `TrustGrant`, `LWCollection` — highest interoperability value
- **v3+:** Publish `Product`, `MediaItem`, full ecommerce vocabulary

### 9.10 The Review Object

```jsonc
{
  "type": "Review",
  "id": "https://server.com/reviews/abc123",
  "actor": "https://server.com/users/alice",
  "object": "https://remote.com/objects/product-xyz",
  "lwMetadata": {
    "rating": "positive", // "positive" | "negative"  (👍 | 👎)
    "blurb": "Loved the quality, arrived quickly.",
  },
  "published": "2026-02-17T12:00:00Z",
}
```

**Review rules:**

- One review per actor per object — subsequent reviews replace the previous
- Blurb optional but encouraged — LLM prompts for one if omitted
- Reviews are not themselves reviewable
- `Note` and `ChatMessage` are not reviewable — use Like/Boost for posts
- Reviewable types at v1: `Note` (posts), `Product`, `MediaItem`
- Aggregate counts (👍 total, 👎 total) computed server-side and cached

---

## 10. Security Architecture

### 10.1 Philosophy

Security is structural, not bolted on. Every object that carries private or sensitive information is encrypted at the object level before leaving the originating client. The server routes ciphertext. The server cannot read encrypted content even if compelled to — this is a guarantee, not a policy.

### 10.2 Encryption Standard — MLS (RFC 9420)

Lightweb Browser uses **Messaging Layer Security (MLS)**, ratified as IETF RFC 9420 in 2023, as its end-to-end encryption protocol. MLS was chosen over alternatives (Signal Protocol, OpenPGP) because:

- It handles **group key agreement natively** — a Circle of Trust is an MLS group
- Group membership changes (adding a controller, granting a permission) are first-class protocol operations with automatic key rotation
- It is an open IETF standard with a clear path to interoperability
- It scales cleanly from 2-party DMs to multi-party trust circles without a separate protocol

### 10.3 MLS Groups → Lightweb Concepts

```
MLS Group members                    Lightweb concept
──────────────────────────────────────────────────────────
[alice, bob]                       → 1:1 ChatMessage thread
[alice, bob, carol, ...]           → Group chat Conversation
[child, parent1, parent2]          → Circle of Trust
[user, server_delivery_actor]      → Private object delivery
```

Every `ChatMessage` and `TrustRequest` is delivered inside an MLS group. Group membership = read access. The host server (MLS Delivery Service) routes ciphertext only — it never holds keys that can decrypt content.

#### MLS Delivery Service Role

Every Lightweb server acts as an MLS Delivery Service for groups it hosts. Responsibilities:

- Maintain MLS group state: membership roster, current epoch, encrypted key packages per member
- Fan out incoming `ChatMessage` objects to all member servers via ActivityPub
- Process MLS commits (membership changes, key rotations)
- Never decrypt message content — purely a routing and state coordination role

### 10.4 Keypair Architecture

Every actor is provisioned with two keypairs at account creation:

| Keypair                | Algorithm     | Purpose                                                         |
| ---------------------- | ------------- | --------------------------------------------------------------- |
| **Signing keypair**    | Ed25519       | HTTP Signatures for ActivityPub federation; object authenticity |
| **Encryption keypair** | X25519 (ECDH) | MLS key agreement; deriving shared secrets                      |

Both public keys are published in the actor's ActivityPub `Actor` object, extending the existing `publicKey` field:

```jsonc
{
  "type": "Person",
  "id": "https://server.com/users/alice",
  "publicKey": {
    "id": "https://server.com/users/alice#main-key",
    "type": "Ed25519VerificationKey2020",
    "publicKeyMultibase": "z6Mk...", // signing key
  },
  "lwEncryptionKey": {
    "id": "https://server.com/users/alice#enc-key",
    "type": "X25519KeyAgreementKey2020",
    "publicKeyMultibase": "z6LS...", // encryption key
  },
}
```

### 10.5 Hybrid Key Storage

Private keys are generated client-side and never transmitted in plaintext. A server-side encrypted backup enables account recovery on new devices.

```
FIRST LOGIN (Device A)
──────────────────────────────────────────────────────
1. Generate Ed25519 + X25519 keypairs locally on device
2. Register both public keys with server (Actor object)
3. Derive backup encryption key:
     backupKey = HKDF(SSO_token || userId || serverSalt)
4. Encrypt private keys:
     encryptedBlob = AES-256-GCM(privateKeys, backupKey)
5. Upload encryptedBlob to server
6. Server stores: { userId, encryptedBlob, publicKeys }
   Server cannot decrypt encryptedBlob ✓

NEW DEVICE / ACCOUNT RECOVERY (Device B)
──────────────────────────────────────────────────────
1. Authenticate via SSO → receive SSO token
2. Download encryptedBlob from server
3. Re-derive backupKey using same HKDF inputs
4. Decrypt private keys locally
5. MLS state re-established from key material ✓
```

**Known limitation:** If the SSO provider revokes the user's token (account banned, Google account deleted, etc.), the HKDF derivation breaks and the encrypted backup cannot be recovered. Users should be informed of this dependency clearly. A secondary recovery mechanism (e.g. a one-time recovery code generated at account creation) is a post-v1 consideration.

### 10.6 What Is and Is Not Encrypted

Encryption is defined **per object type in the extension manifest**, not as a blanket system policy. The `encryption` field in each manifest is one of `"required"`, `"optional"`, or `"none"`.

| Object type                      | Encryption               | Defined in manifest      |
| -------------------------------- | ------------------------ | ------------------------ |
| `ChatMessage`                    | ✅ Required (MLS)        | `encryption: "required"` |
| `TrustRequest` / `TrustGrant`    | ✅ Required (MLS)        | `encryption: "required"` |
| `Note` (public post)             | ❌ None                  | `encryption: "none"`     |
| `Review`                         | ❌ None                  | `encryption: "none"`     |
| `Movie` / `MenuItem` / `Product` | ❌ None (public objects) | `encryption: "none"`     |
| HTTP Signatures (all federation) | ✅ Ed25519 signing       | Transport layer          |
| Config Registry                  | ❌ Server-side only      | Never on client          |

### 10.7 Objects That Require Encryption by Default

Any `LightwebObject` with a `lwTrustScope` that restricts visibility to fewer recipients than "public" **must** be MLS-encrypted before leaving the originating client. The server enforces this at the API gateway — it will reject sensitive objects submitted without encryption.

---

## 11. Configuration Registry

### 11.1 Philosophy

> **All configuration lives in the Config Registry. All content lives in PostgreSQL. Never mix them.**

The Config Registry is the single source of truth for all system behaviour. It is loaded entirely into memory at server startup and held there for the lifetime of the process. It is never stored in PostgreSQL. Users interact with it only through the LLM — they never see or edit JSON.

### 11.2 Storage & Format

- Single JSON file (`config/registry.json`) on disk
- Loaded fully into memory on startup; served from memory on every read
- Written back to disk atomically on mutation (write to temp file → rename)
- Hierarchical where natural; flat key/value where not
- Human-readable and hand-editable for emergency operator use

### 11.3 Initial Structure

```jsonc
{
  "server": {
    "name": "Lightweb Browser",
    "domain": "lightweb.example.com",
    "registrations_open": true,
    "federation": {
      "enabled": true,
      "blocked_domains": [],
      "allowed_domains": [], // empty = allow all
    },
  },

  "llm": {
    "provider": "claude", // "claude" | "openai" | "gemini"
    "model": "claude-sonnet-4-5-20250929",
    "api_key_env": "LLM_API_KEY", // actual key loaded from env var
    "max_tokens": 1024,
    "temperature": 0.7,
  },

  "auth": {
    "sso_providers": ["google", "facebook"],
    "jwt_expiry_seconds": 3600,
    "refresh_token_expiry_days": 30,
  },

  "ui": {
    "swipe_commit_threshold": 0.4,
    "swipe_velocity_threshold": 800,
    "animation_duration_ms": 300,
    "columns": {
      "mobile_default": 1,
      "tablet_default": 2,
      "web_default": 2,
      "user_override": null, // set per device by user via LLM
    },
    "polling": {
      "background_feed_interval_ms": 60000, // home feed background refresh (default 60s)
      "remote_feed_interval_ms": 5000, // active remote feed when connected via WebSocket
      "websocket_reconnect_delay_ms": 3000,
    },
    "read_receipts": {
      "enabled": true, // on by default
      "posts_require_swipe": true, // post read receipt only on left-swipe connect
    },
  },

  "content": {
    "max_post_characters": 500,
    "max_images_per_post": 4,
  },

  "moderation": {
    "muted_keywords": [],
    "blocked_users": [],
  },
}
```

### 11.4 Access Rules

| Actor                    | Read               | Write                                                 |
| ------------------------ | ------------------ | ----------------------------------------------------- |
| LLM Service              | ✅ Full            | ✅ Scoped (user-affecting keys only, not server-wide) |
| API Gateway              | ✅ Full            | ❌                                                    |
| ActivityPub Service      | ✅ Federation keys | ❌                                                    |
| Client apps              | ❌ Never           | ❌ Never                                              |
| Server operator (manual) | ✅ Full            | ✅ Full (file edit + restart)                         |

---

## 12. Non-Functional Requirements

| Requirement             | Target                                        |
| ----------------------- | --------------------------------------------- |
| Availability            | 99.5% uptime                                  |
| Feed load time (p95)    | < 1.5s on 4G                                  |
| LLM response time (p95) | < 3s                                          |
| Federation delivery     | < 30s to federated servers                    |
| Config Registry write   | < 50ms (atomic file write)                    |
| GDPR / data export      | User data in ActivityPub JSON format          |
| Account deletion        | Within 30 days; federated `Delete` actor sent |
| Accessibility           | WCAG 2.1 AA on all core flows                 |

---

## 13. Monorepo Structure

```
/
├── apps/
│   ├── mobile/           # Expo React Native (iOS + Android)
│   ├── web/              # Next.js web shell (embeds shared mobile UI)
│   ├── api/              # Next.js API gateway
│   ├── federation/       # Fastify ActivityPub service
│   └── llm/              # Fastify LLM service
├── packages/
│   ├── ui/               # Shared React Native + web UI components
│   │   ├── Feed/
│   │   ├── Card/
│   │   ├── InputBar/
│   │   └── SwipePanes/
│   ├── types/            # Shared TypeScript types
│   ├── ap-core/          # ActivityPub builders & validators
│   ├── lw-objects/       # LightwebObject base type + extension manifest loader
│   │   ├── base/         # LightwebObject, TrustRequest, TrustGrant, Review
│   │   └── extensions/   # Internal extension manifests (Movie, MenuItem, etc.)
│   ├── trust/            # Circle of Trust — account model, permission checks
│   ├── crypto/           # MLS client, Ed25519/X25519 keypair mgmt, key backup
│   ├── config-registry/  # Registry loader, reader, writer, TypeScript types
│   └── tsconfig/         # Shared TS config
├── config/
│   └── registry.json     # THE config registry (secrets via env vars only)
├── turbo.json
├── package.json
└── PRD.md
```

---

## 14. Open Questions

| #   | Question                        | Owner              | Status                                                                                                                   |
| --- | ------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| 1   | App name                        | Product            | 🟢 **Lightweb Browser**                                                                                                  |
| 2   | SSO providers                   | Product            | 🟢 Google + Facebook (+ Apple likely required for App Store)                                                             |
| 3   | Notifications                   | Product            | 🟢 Replaced by feed cards — no separate notification system                                                              |
| 4   | Account model                   | Product            | 🟢 Open or Controlled; no intermediate types                                                                             |
| 5   | Controller LLM scope            | Product            | 🟢 Config-write only; cannot execute actions on controlled account                                                       |
| 6   | Allowlist philosophy            | Product            | 🟢 Confirmed — allowlist always, never deny                                                                              |
| 7   | LLM write scope                 | Product + Security | 🟢 User LLM: own config objects only. Server-wide: operator only                                                         |
| 8   | TrustRequest scopes             | Product            | 🟢 Three scopes: `once`, `content-only`, `persistent`                                                                    |
| 9   | Multiple controllers            | Product            | 🟢 Any one controller sufficient; first to respond wins                                                                  |
| 10  | Hosting model                   | Product            | 🟢 Lightweb Cloud — dedicated container per user                                                                         |
| 11  | Content moderation              | Product            | 🟢 None at v1. No comments. Review objects (👍/👎 + blurb) replace them                                                  |
| 12  | E2EE                            | Engineering        | 🟢 MLS (RFC 9420). Hybrid key storage                                                                                    |
| 13  | Rating format                   | Product            | 🟢 👍 / 👎 + optional blurb                                                                                              |
| 14  | Extension namespace             | Product            | 🟢 v1 internal; v2 publish TrustRequest/TrustGrant; v3+ domain types                                                     |
| 15  | Chat thread layout              | Product            | 🟢 Full screen on 1-col mobile; right column on 2+ col tablet/web                                                        |
| 16  | Group host migration            | Engineering        | 🟢 Automatic — oldest remaining member's server via MLS commit                                                           |
| 17  | Column counts                   | Product            | 🟢 Mobile default 1, tablet 2–3; always user-configurable per device                                                     |
| 18  | Encryption per type             | Engineering        | 🟢 Defined in extension manifest (`encryption: "required"/"optional"/"none"`)                                            |
| 19  | App store strategy              | Product            | 🟢 Single app — "Lightweb Browser" on iOS and Android. Server personalisation happens at first launch, not in the binary |
| 20  | AI chat history                 | Product            | 🟢 Not stored — ephemeral per session                                                                                    |
| 21  | LLM API key                     | Engineering        | 🟢 Operator only at v1; user-owned LLM is post-v1                                                                        |
| 22  | Remote feed connection          | Engineering        | 🟢 Background polling (default 60s, configurable) + on-demand WebSocket on left-swipe                                    |
| 23  | Config registry tracking        | Engineering        | 🟢 Git-tracked — secrets via env vars only                                                                               |
| 24  | Key revocation                  | Engineering        | 🟢 MLS epoch advancement — any group member triggers commit; old-epoch messages inaccessible after rotation              |
| 25  | Reviewable types at v1          | Product            | 🟢 Note, Product, MediaItem                                                                                              |
| 26  | Container orchestration         | Engineering        | 🟢 Kubernetes                                                                                                            |
| 27  | Read receipts                   | Product            | 🟢 On by default. Post read receipt only on left-swipe connect. Chat on delivery/view                                    |
| 29  | Object types                    | Product            | 🟢 8 core types: Note, ChatMessage, TrustRequest, TrustGrant, Review, Product, MediaItem, LWCollection                   |
| 30  | Collection implementation       | Engineering        | 🟢 Extends AP `OrderedCollection` with `lwMetadata` and `lwTags`                                                         |
| 31  | Background polling default      | Product            | 🟢 60s, user-configurable in registry                                                                                    |
| 32  | Services as type                | Product            | 🟢 Services are Products with `lwTags: ["service"]` — no separate type                                                   |
| 33  | Apple Sign In                   | Legal + Eng        | 🟡 Likely required for App Store compliance — confirm before submission                                                  |
| 34  | Hosting model detail            | Engineering        | 🟢 Kubernetes on Lightweb Cloud; dedicated container per user                                                            |
| 35  | Extension namespace publication | Product            | 🟢 v1 internal spec; v2 publish TrustRequest/TrustGrant/LWCollection; v3+ Product/MediaItem                              |

---

## 15. Roadmap

| Phase                                      | Timeline    | Deliverables                                                                           |
| ------------------------------------------ | ----------- | -------------------------------------------------------------------------------------- |
| **Phase 0 — Foundation**                   | Weeks 1–3   | Monorepo, DB schema, Config Registry, WebFinger + Actor endpoints                      |
| **Phase 1 — Core Federation**              | Weeks 4–8   | Inbox/outbox, Follow/Accept, HTTP Signatures, `Note` and `ChatMessage` types           |
| **Phase 2 — Column Navigator + Input Bar** | Weeks 6–12  | Column UI, focused card, input bar, SSO auth, 1-col mobile + 2-col tablet              |
| **Phase 3 — Chat (1:1 + Group)**           | Weeks 8–14  | ChatMessage object, MLS encryption, group host model, host migration, feed cards       |
| **Phase 4 — Swipe + AI Pane**              | Weeks 10–15 | Left swipe (context-dependent column), right swipe (AI pane), animations               |
| **Phase 5 — LLM Service**                  | Weeks 12–16 | LLM service, Claude integration, config read/write, action dispatch                    |
| **Phase 6 — Circle of Trust**              | Weeks 14–18 | Controlled accounts, TrustRequest/TrustGrant, approval flow, config object permissions |
| **Phase 7 — Object Model + Reviews**       | Weeks 16–19 | LightwebObject base, extension manifest loader, Review object                          |
| **Phase 8 — Web Client**                   | Weeks 17–20 | Next.js web shell embedding shared mobile UI                                           |
| **Phase 9 — Lightweb Cloud**               | Weeks 18–21 | Container provisioning, per-user isolation, billing hooks                              |
| **Phase 10 — Polish & Launch**             | Weeks 21–26 | Performance, a11y, beta testing, app store submission                                  |
| **Post-v1**                                | TBD         | Video chat (SFU on host server), TrustRequest open standard, business trust, Apple SSO |

---

## 16. References

- [ActivityPub W3C Spec](https://www.w3.org/TR/activitypub/)
- [ActivityStreams 2.0](https://www.w3.org/TR/activitystreams-core/)
- [ActivityStreams Vocabulary](https://www.w3.org/TR/activitystreams-vocabulary/)
- [JSON-LD 1.1](https://www.w3.org/TR/json-ld11/)
- [WebFinger RFC 7033](https://www.rfc-editor.org/rfc/rfc7033)
- [HTTP Signatures](https://datatracker.ietf.org/doc/html/draft-cavage-http-signatures)
- [MLS RFC 9420](https://www.rfc-editor.org/rfc/rfc9420) _(Messaging Layer Security)_
- [MIMI Working Group](https://datatracker.ietf.org/wg/mimi/about/) _(MLS deployment guidance)_
- [Ed25519 / X25519 — RFC 8032 / RFC 7748](https://www.rfc-editor.org/rfc/rfc8032)
- [Mastodon extensions namespace](https://joinmastodon.org/ns) _(reference for JSON-LD extension publishing)_
- [Solito — React Native + Next.js](https://solito.dev)
- [Mastodon API docs](https://docs.joinmastodon.org/) _(reference AP implementation)_
- [Anthropic Messages API](https://docs.anthropic.com/en/api/messages)
- [W3C Social Web Working Group](https://www.w3.org/Social/WG) _(process for standardising extensions)_

---

_This document is a living spec. Update it as decisions are made and requirements evolve._
