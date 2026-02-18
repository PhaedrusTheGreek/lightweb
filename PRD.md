# Product Requirements Document (PRD)

## Lightweb Browser — ActivityPub Platform

**Version:** 0.10 (Draft)
**Status:** 🟡 In Progress
**Last Updated:** 2026-02-18

---

## 1. Overview

A new social & business media platform where content is created and controlled by you.

### 1.1 Mission Statement

To provide a simple and well-defined structure for communications which is conducive to accessibility mechanisms such as voice control and AR. Such structure not only relieves interface friction, but is inherently more secure and well integrated. To provide an internet safe for kids, safe for everyone.

### 1.2 Problem Statement

Mainstream social media platforms are centralized, opaque, and buried in buttons, menus, and configuration screens. And no social platform today provides a principled, interoperable model for secure non-technical use of the internet.

_Sending_ data through web browsers and most apps is uncontrolled and insecure.

### 1.3 Vision

To lock down browser PUT/POST capability, effectively making it read only, by designing a new alternate simple & secure social & business media / communciations browser interface.

Lightweb Browser is a federated social platform built on ActivityPub, designed around three radical premises:

1. **There are no unnecessary UI input components such as buttons and choosers and boxes.** Every interaction flows through a single persistent, context-aware input bar which at any time could be replaced with a voice input or sign language or future "keyboard".
2. **Security is Deny by Default** Internet actions or UI changes must be explicitly allowed. Permissions evolve naturally over time.
3. **Trust is structured.** The platform provides a structured model for circles of trust — between family members, colleagues, communities — built as Lightweb extension types that federate over ActivityPub transport. Further, quality of business objects are reputable over time based on reviews expressed via native ActivityStreams objects (`Like`, `Dislike`, `Note`). Positive reviews inside circle of trust carry more weight.

### 1.4 Design Philosophy

**"No Buttons"**

- No navigation tabs, no settings screens, no action menus
- All user intent is expressed as natural language or gesture
- The system infers what the user means based on what card is in focus
- When defaults are not enough, AI handles the remainder
- Configuration is never the user's problem — it's the system's problem

**"Layout is User-Controlled"**

- The screen layout never changes without an explicit user gesture (swipe, scroll)
- The LLM cannot rearrange columns or shift focus
- Receiving a new message does not move or resize existing columns
- Creating a new card does not auto-open a compose column
- Only the user's physical gesture — swipe, tap, scroll — changes what they see

**"Allowlist, Never Deny"**

- Nothing is permitted until explicitly granted
- The default state for any unrecognised action is a permission request, not a refusal
- Permissions are granular, scoped, and evolve over time
- The system always tells you what _is_ allowed, never just says no

**"Trust is Structured"**

- Trust relationships are structured Lightweb extension types that federate over ActivityPub transport
- They are extensible and travel via standard AP inbox/outbox delivery
- The same trust model that governs parent/child applies to employer/employee, community/member, etc.

### 1.5 App Name

**Lightweb Browser**

---

## 2. Goals & Success Metrics

| Goal                 | Metric                                                | Target (6 months post-launch) |
| -------------------- | ----------------------------------------------------- | ----------------------------- |
| Interoperability.    | Level of interoperability with non-LW implementations | Basic Functionality           |
| AI intent resolution | % of natural language inputs correctly actioned       | > 99.9%                       |
| Accessibility        | WCAG 2.1 AA compliance                                | 100% of core flows            |

---

## 3. Target Audience

**Primary:** General public, all ages. No technical knowledge of federation or AI required.

**Key personas:**

- **The Privacy-Conscious User** — migrating from Twitter/X or Meta, wants data ownership without learning a new interface paradigm
- **The Community Builder** — wants to run a topic-based server, configure it naturally via AI without touching config files
- **The Casual Social User** — just wants to post and chat; finds existing social apps over-engineered
- **The Parent** — wants granular, evolving control over what their child can see, follow, and do — without a complex parental controls dashboard
- **The Protected Account** (child) — uses the platform naturally, with the trust system invisible; encounters graceful gates rather than confusing errors
- **The Business User** _(post-v1)_ — Internet presence for standardized and secure ecommerce interactions

> ⚠️ **Design implication:** ActivityPub federation, AI/LLM systems, and the Circle of Trust must be completely invisible to end users. Users experience outcomes (content visible / not visible, action permitted / request sent) never mechanisms.

---

## 4. Scope

### 4.1 In Scope (v1.0 Launch)

- ✅ User registration and login (SSO only — Google and Apple)
- ✅ Single-screen column navigator — 1 column on mobile by default, 2–3 on tablet; always user-configurable per device
- ✅ Feed as unified inbox — all events (messages, replies, follows, trust requests) arrive as cards; no separate notifications
- ✅ One card always in focus (default to latest); persistent context-aware input bar always visible
- ✅ Symmetric swipe — swipe any card left or right to open its detail view (remote feed, chat thread, etc.) as a new column in the direction of the swipe
- ✅ AI-default input — input bar routes through LLM by default; switches to direct keyboard for chat threads and content creation
- ✅ Content creation flow — LLM creates unsent draft cards in the feed; user composes via swipe-to-column or inline LLM dictation
- ✅ **Chat-first messaging** — 1:1 and group chat, WhatsApp-equivalent, E2EE via MLS
- ✅ **Federated DMs** — cross-implementation direct messaging via standard AP private `Note` objects; default-deny, configurable per account
- ✅ **Conversation upgrade** — federated DMs automatically upgrade to encrypted `ChatMessage` + RCS when both parties have mutual `Relationship` objects satisfying the `encrypted_chat` permission rule; unified chat thread UI with per-message encryption and RCS indicators
- ✅ `ChatMessage` object type — dedicated type, always encrypted, separate from `Note`
- ✅ Group chat with host server model — creator's server is MLS Delivery Service
- ✅ Automatic group host migration — oldest remaining member's server takes over
- ✅ ActivityPub federation (inbox, outbox, followers, following, WebFinger)
- ✅ Native iOS and Android apps
- ✅ Meta Quest client (voice-first VR/AR — single controller, no visible text input by default)
- ✅ Web client (Next.js shell embedding the shared mobile UI component)
- ✅ Server-side LLM processor (Claude by default; swappable via config)
- ✅ In-memory JSON configuration registry (single source of truth for all config)
- ✅ Circle of Trust — account control model (open and controlled accounts)
- ✅ TrustRequest / TrustGrant object types — permission escalation via ActivityPub
- ✅ Allowlist permission model for all actions and config objects
- ✅ Native AS `Relationship` objects (`lw:following`, `lw:friendOf`, `lw:closeFriendOf`) stored in SQL with boolean permission rules (`any`/`all`)
- ✅ Contact registry — relationships in SQL, aliases/metadata in Config Registry for LLM resolution
- ✅ Friend request flow via TrustRequest (`Create Relationship`); delegated permissions for controlled accounts
- ✅ LightwebObject base type with typed extension system
- ✅ Encryption defined per extension manifest — `ChatMessage`: required, `Note`/`Article`: none
- ✅ Reviews via native ActivityStreams objects — `Like` (👍), `Dislike` (👎), `Note` (blurb), applicable per object type
- ✅ Streams — topic-specific feeds published via the native AP `streams` property on the Actor object; each stream is an `OrderedCollection`
- ✅ MLS (RFC 9420) E2EE for ChatMessage and TrustRequest objects
- ✅ Hybrid key storage — client-side primary, encrypted server backup
- ✅ Managed hosting — Lightweb Cloud, single-user-per-server (dedicated container per user, domain = identity)

### 4.2 Out of Scope (v1.0)

- ❌ Push notifications (replaced by feed cards)
- ❌ Video chat (v2 — same host server model, adds SFU)
- ❌ Video hosting / media
- ❌ Groups / communities (distinct from group chat)
- ❌ Stories / ephemeral content
- ❌ Monetization / creator tools
- ❌ Admin moderation dashboard (manual DB tooling only at launch)
- ❌ Comments (replaced by native `Like`/`Dislike`/`Note` review mechanism)
- ❌ ECommerce tooling

---

## 5. Technical Architecture

### 5.1 High-Level Overview

```
                    ┌─ PER-USER CONTAINER ──────────────────────────────┐
                    │                                                   │
┌────────────────┐  │  ┌────────────────────────────────────────────┐   │
│  CLIENT LAYER  │  │  │         NEXT.JS  (single process)          │   │
│                │  │  │                                            │   │
│ iOS (RN/Expo) ─┼──┼─▶│  API Routes                                │   │
│ Android (RN)  ─┼──┼─▶│  - REST API for all clients                │   │
│ Web (browser) ─┼──┼─▶│  - Auth (JWT / OAuth2 — Google, Apple)     │   │
│                │  │  │  - Rate limiting, input validation         │   │
│ ── Solito ──   │  │  │                                            │   │
│ shared UI +    │  │  │  ActivityPub Engine                        │   │
│ react-native-  │  │  │  - Inbox / Outbox                          │   │
│ web            │  │  │  - Actor management & WebFinger            │   │
│                │  │  │  - HTTP Signatures                         │   │
└────────────────┘  │  │  - Federation send/receive                 │   │
                    │  │                                            │   │
  HTTPS / REST +    │  │  LLM Client                                │   │
  WebSockets        │  │  - Calls external LLM API (Claude)         │   │
                    │  │  - Reads / writes Config Registry          │   │
                    │  │  - Dispatches AP actions                   │   │
                    │  │                                            │   │
                    │  │  Web Shell (SSR)                           │   │
                    │  │  - React Server Components                 │   │
                    │  │  - Embeds shared RN UI via react-native-web│   │
                    │  │  - Minimal client JS (swipe, WS, focus)    │   │
                    │  └─────────────┬──────────────────────────────┘   │
                    │                │                                  │
                    │  ┌─────────────▼──────────┐                       │
                    │  │  Redis (local sidecar) │  ~5 MB idle           │
                    │  │  - Feed caching        │                       │
                    │  │  - Session store       │                       │
                    │  │  - Real-time pub/sub   │                       │
                    │  └────────────────────────┘                       │
                    │                                                   │
                    │  Config Registry (JSON file, always in memory)    │
                    └──────────────────────────┬────────────────────────┘
                                               │
                    ┌─ SHARED INFRASTRUCTURE ───┼───────────────────────┐
                    │                           │                       │
                    │  ┌────────────────────────▼───────────────────┐   │
                    │  │  Managed PostgreSQL (separate DB per user) │   │
                    │  │  - Users, posts, follows                   │   │
                    │  │  - AP objects / activities                 │   │
                    │  │  - Media metadata                          │   │
                    │  │  - Connection pooling by provider          │   │
                    │  │                                            │   │
                    │  │  ⚠️  No configuration in PostgreSQL.       │   │
                    │  │      All config is in the                  │   │
                    │  │      JSON Config Registry (see §8).        │   │
                    │  └────────────────────────────────────────────┘   │
                    │                                                   │
                    │  ┌────────────────────┐  ┌─────────────────────┐  │
                    │  │  S3/R2 Storage     │  │  External LLM API   │  │
                    │  │  - Media uploads   │  │  - Claude (default) │  │
                    │  │  - CDN delivery    │  │  - Swappable via    │  │
                    │  └────────────────────┘  │    config registry  │  │
                    │                          └─────────────────────┘  │
                    └───────────────────────────────────────────────────┘
```

### 5.2 Technology Choices

| Layer                   | Technology                              | Rationale                                                         |
| ----------------------- | --------------------------------------- | ----------------------------------------------------------------- |
| Mobile frontend         | **React Native** (via Expo)             | Native components on iOS & Android                                |
| Quest frontend          | **React Native** + OpenXR bridge        | Voice-first VR/AR client; shares `packages/ui`; single controller |
| Unified server          | **Next.js 14+** (App Router)            | Single process: API routes, AP engine, LLM client, SSR web shell  |
| Code sharing            | **Solito** + **react-native-web**       | Shared UI components + navigation across RN and Next.js           |
| Language                | **TypeScript** throughout               | Monorepo type safety end to end                                   |
| Database                | **Managed PostgreSQL** (e.g. Supabase)  | Separate DB per user; connection pooling by provider              |
| Cache / realtime        | **Redis** (local sidecar per container) | Feed caching, sessions, pub/sub for real-time chat                |
| Object storage          | **S3-compatible** (e.g. Cloudflare R2)  | Shared media hosting across all users                             |
| Monorepo tooling        | **Turborepo**                           | Shared packages, incremental builds                               |
| Initial LLM provider    | **Claude (Anthropic)**                  | External API calls; swappable via config registry                 |
| Container orchestration | **Kubernetes** (GKE / GCP)              | One container per user; cluster-level scaling                     |

### 5.3 Web Client Strategy

The web client is a **Next.js application** that serves two roles in one process:

1. **Shell:** Next.js handles routing, auth, SSR metadata, and the outer browser chrome via React Server Components
2. **Embedded UI:** The exact same React Native UI component used on mobile is embedded inside the shell via `react-native-web` and Solito

This means the mobile UI and web UI share **identical code.** The web shell adds browser-native affordances (URL routing, tab title, keyboard shortcut hints). The core feed, input bar, and swipe interactions are the same on all platforms.

**Minimal client-side JavaScript.** The web shell is primarily server-side rendered. Client-side JS is limited to interactive features that require it:

- Swipe gesture handling (touch/pointer events)
- WebSocket connection for real-time chat delivery
- Card focus tracking and input bar state
- Animation transitions (~300ms ease-in-out)

This is a thin interactive layer, not a full client-side application. The same React Native components render on web — the client JS hydrates interactivity, not the entire UI.

> 📌 The web experience intentionally looks and feels like a mobile app running in a browser — this is by design, not a limitation.

### 5.4 Meta Quest Client — Voice-First VR/AR

The Meta Quest client is a **voice-first** adaptation of the Lightweb column navigator. It reuses the shared UI component layer but replaces the persistent text input bar with voice input as the primary interaction mode. Only one Quest controller is needed.

#### Controller Mapping

| Controller input   | Action         | Notes                                                                                                                                      |
| ------------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Joystick**       | Swipe & scroll | Up/down scrolls the feed vertically; left/right performs symmetric swipe navigation — direction determines column placement (same as §7.3) |
| **Trigger (hold)** | Voice input    | Press and hold to speak; release to submit. Equivalent to typing in the input bar — LLM or direct depending on active column type          |

#### Key Differences from Mobile/Web

- **No visible text input bar by default.** The input bar is hidden; all user intent is expressed via voice while holding the trigger. The input bar can be summoned via voice command (_"show keyboard"_) or via LLM for cases requiring precise text entry (URLs, passwords), at which point a virtual keyboard appears
- **Single controller only.** The entire interaction model — scrolling, swiping, and speaking — is operable with one hand on one controller
- **Focus follows gaze + joystick.** Card focus is determined by a combination of head gaze and joystick position, replacing tap-to-focus
- **Voice is contextual.** The same context-dependent behaviour from §7.2 applies — what the voice input does depends on the focused card and active column type. Holding the trigger on a chat thread and saying "sounds good" sends a direct reply; holding the trigger on the home feed with a card focused and saying "unfollow" routes through the LLM to dispatch the action

#### Voice Input Flow

```
User holds trigger
       │
       ▼
Audio captured → streamed to server (WebSocket)
       │
       ▼
Server-side speech-to-text (provider-abstracted)
       │
       ▼
Transcribed text processed identically to typed input bar submission
  - Same focused card context
  - Same active column type routing (LLM vs direct, per §7.2)
       │
       ▼
Response rendered as card / chat bubble + optional TTS playback
```

#### Speech Provider Abstraction

Speech-to-text follows the same provider pattern as §5.8 (Provider Abstractions):

```typescript
// Speech — voice input transcription
interface SpeechProvider {
  transcribe(audioStream: ReadableStream): Promise<string>;
}
// Registered: WhisperProvider | DeepgramProvider | QuestNativeProvider
// Active: config.speech.provider
```

#### Platform Integration

- Built with **React Native** via the Quest fork / react-native-openxr bridge, sharing the `packages/ui` component layer
- Column navigator renders as a curved panel in 3D space — same column model, spatially arranged
- Swipe animations map to joystick-driven panel transitions
- Audio capture uses the Quest's built-in microphone array

> 📌 The Quest client proves the core design thesis: because all interaction flows through one input mechanism (the input bar), swapping text for voice requires no architectural changes — only an input adapter.

---

### 5.5 Single-User-Per-Server Model

Every Lightweb user gets a **dedicated container** — one user, one server, one domain. The user's domain _is_ their identity (e.g. `@alice@alice.lightweb.cloud`).

**Why single-user-per-server:**

- **Security isolation.** A compromise of one container cannot access another user's data, keys, or configuration
- **Resource isolation.** One user's traffic spike doesn't affect another user
- **Simplicity.** No multi-tenancy complexity — the Config Registry, Redis, and process state all belong to exactly one user
- **Identity model.** Domain = identity aligns naturally with ActivityPub's actor model and WebFinger discovery

**WebFinger** (RFC 7033) is still required for federation interop — other AP servers expect to resolve `@user@domain` via `/.well-known/webfinger`. In a single-user-per-server model this is trivially implemented (always returns the one user) but must exist for other servers to discover and follow this actor.

### 5.6 Consolidated Single-Process Architecture

All server-side functionality runs in a **single Next.js process** per container. There are no separate microservices.

| Concern            | Implementation                                                  |
| ------------------ | --------------------------------------------------------------- |
| API gateway        | Next.js API routes (`/api/*`)                                   |
| ActivityPub engine | Next.js API routes (`/users/*/inbox`, `/users/*/outbox`, etc.)  |
| WebFinger          | Next.js API route (`/.well-known/webfinger`)                    |
| LLM client         | HTTP client calls to external Claude/OpenAI API from API routes |
| Web shell (SSR)    | React Server Components + hydrated interactive layer            |
| WebSocket server   | Attached to Next.js HTTP server for real-time chat delivery     |
| Config Registry    | JSON file loaded into process memory at startup                 |

**Why not microservices:** With one user per container, there is no concurrency benefit from splitting services. A single process eliminates inter-process communication overhead, simplifies deployment, and reduces memory footprint (~100–150 MB total per container vs ~300+ MB for three separate Node.js processes).

### 5.7 Infrastructure Split — Per-Container vs Shared

Each user container runs locally:

- **Next.js process** — single Node.js process (~100–150 MB)
- **Redis sidecar** — local instance (~5 MB idle, grows with cached feed size)
- **Config Registry** — JSON file on local disk, held in process memory

Shared infrastructure (managed, external to containers):

- **Managed SQL** — separate database per user, hosted on a cloud provider (e.g. Supabase). Connection pooling handled by the provider. Each container connects to its own database via connection string
- **S3/R2 object storage** — shared media storage across all users. Media uploads go through the user's container, stored in a shared bucket with user-prefixed keys
- **External LLM API** — Claude (default) or other provider. HTTP calls from within Next.js API routes. No local LLM process

**Container capacity estimate:** On a 3-node GCP cluster (e2-medium, 4 GB RAM each, ~$75/month total), approximately 65–80 idle containers fit comfortably. Active containers with traffic consume more, so real-world capacity depends on usage patterns.

### 5.8 Provider Abstractions

All infrastructure dependencies are accessed through provider interfaces, configured via the Config Registry. Active providers are resolved at startup. Switching any provider requires only a config change and restart — no code changes.

```typescript
// LLM — external AI service
interface LLMProvider {
  complete(systemPrompt: string, messages: Message[]): Promise<LLMResponse>;
}
// Registered: ClaudeProvider | OpenAIProvider | GeminiProvider
// Active: config.llm.provider

// Database — content storage
interface DatabaseProvider {
  query<T>(sql: string, params: unknown[]): Promise<T[]>;
  transaction<T>(fn: (tx: Transaction) => Promise<T>): Promise<T>;
}
// Registered: PostgresProvider | SQLiteProvider (dev/test)
// Active: config.database.provider

// Queue / Cache — real-time + caching
interface QueueProvider {
  publish(channel: string, message: unknown): Promise<void>;
  subscribe(
    channel: string,
    handler: (message: unknown) => void,
  ): Promise<void>;
  cache: {
    get<T>(key: string): Promise<T | null>;
    set(key: string, value: unknown, ttlMs?: number): Promise<void>;
  };
}
// Registered: RedisProvider | InMemoryProvider (dev/test)
// Active: config.queue.provider
```

---

## 6. ActivityPub Implementation

### 6.1 Required Endpoints

| Endpoint                       | Method | Purpose                      |
| ------------------------------ | ------ | ---------------------------- |
| `/.well-known/webfinger`       | GET    | Actor discovery              |
| `/.well-known/nodeinfo`        | GET    | Server metadata              |
| `/users/:username`             | GET    | Actor object                 |
| `/users/:username/inbox`       | POST   | Receive federated activities |
| `/users/:username/outbox`      | GET    | Published activities         |
| `/users/:username/followers`   | GET    | Followers collection         |
| `/users/:username/following`   | GET    | Following collection         |
| `/users/:username/streams`     | GET    | List of topic streams        |
| `/users/:username/streams/:id` | GET    | Individual stream collection |

### 6.2 Activity Types (v1.0)

- `Create` (Note) — status updates and federated DMs (private `Note` with restricted addressing)
- `Create` (Article) — long-form posts (plain text only, no HTML)
- `Create` (ChatMessage) — E2EE chat messages (Lightweb-to-Lightweb, mutual `Relationship` objects required)
- `Create` (TrustRequest) — permission escalation and friend requests (always E2EE via MLS)
- `Create` (TrustGrant) — permission approval and friend acceptance (always E2EE via MLS)
- `Follow` / `Accept` / `Reject`
- `Like`
- `Announce` — boosts / reposts
- `Delete`
- `Dislike` — 👎 negative rating (review mechanism)
- `Undo` — un-follow, un-like, un-dislike, un-boost
- `Add` / `Remove` — manage stream membership (add/remove objects to/from a stream `OrderedCollection`)

### 6.3 Security Requirements

- HTTP Signatures on all outgoing federated requests (RFC 9421 / draft-cavage)
- Signature verification on all incoming inbox POST requests
- Domain blocklist / allowlist support (configured via Config Registry)

---

## 7. Feature Requirements

### 7.1 Feed UI — Column Navigator Model

The entire UI is built on a single primitive: the **column navigator**. There is one screen. It contains one or more columns. Swiping a card opens its detail view as a new column **in the direction of the swipe** — swipe right and the column opens to the right; swipe left and it opens to the left. Both directions perform the same action (drill into the card); the direction only determines column placement. There are no pages, no modals, no navigation stack in the traditional sense.

#### Column Count — Device Defaults & User Configuration

| Device         | Default columns | Minimum | Maximum |
| -------------- | --------------- | ------- | ------- |
| Mobile phone   | 1               | 1       | 1       |
| Tablet (small) | 2               | 1       | 3       |
| Tablet (large) | 3               | 1       | 4       |
| Web (desktop)  | 2               | 1       | \*      |

Column count is **user-configurable per device** via the Config Registry (via LLM: _"show me two columns on my phone"_). The device default is applied on first use only.

#### What a Column Is

Every column is a **vertical scrolling feed** of cards, with the persistent input bar anchored at the bottom. The leftmost column is always the home feed by default. Additional columns open in the direction of the swipe, each representing a different context (remote feed, chat thread, etc.).

```
1 COLUMN (mobile default)        2 COLUMNS (after right-swipe on Card B)
┌──────────────────────┐         ┌───────────┬──────────────────┐
│  HOME FEED           │         │ HOME FEED │ CHAT / REMOTE    │
│                      │         │           │                  │
│  [Card A]            │         │ [Card A]  │ [Message 1]      │
│ ╔════════════╗       │         │╔═════════╗│ [Message 2]      │
│ ║[Card B]    ║ focus │  swipe  │║[Card B] ║│ [Message 3]      │
│ ╚════════════╝       │ ──────▶ │╚═════════╝│                  │
│  [Card C]            │  right  │ [Card C]  │                  │
│                      │         │           │                  │
├──────────────────────┤         ├───────────┼──────────────────┤
│  [Ask anything…    ] │         │[Ask…    ] │ [Type a message] │
└──────────────────────┘         └───────────┴──────────────────┘
```

On a 1-column device, swiping replaces the current column entirely — the home feed slides off-screen in the opposite direction of the swipe, and the detail view takes over full screen. Swiping back in the opposite direction restores the home feed. On multi-column devices, the new column is added in the swipe direction; existing columns compress to make room.

**Accessibility First**

It is critical that the input bar be anchored at the bottom for all interaction because pointing by finger is a nightmare for precision, especially while you're old and can't see.

#### One Card Always In Focus

Across all columns, exactly **one card is in focus** at any time — the last card tapped or scrolled to. The input bar at the bottom of each column reflects the focused card in that column. When focus moves to a card in a different column, that column's input bar becomes active.

---

### 7.2 The Persistent Input Bar

The input bar is ostensibly the **only** interactive control in the entire UI. It is permanently anchored to the bottom of the screen, above the system keyboard.

**There are no buttons or other inputs anywhere in the app (ostensibly).**

#### Input Mode — Determined by Object Type

The input bar operates in one of two modes: **LLM** (input is sent to the server-side LLM for interpretation) or **Direct** (input is sent as-is, like a keyboard). The mode is determined by the **type of content in the active column**, not by a user-toggled setting or swipe direction.

| Active column content                           | Input mode | Placeholder            | Behaviour                                                     |
| ----------------------------------------------- | ---------- | ---------------------- | ------------------------------------------------------------- |
| Home feed — card in focus                       | **LLM**    | `Ask anything…`        | LLM receives input + focused card context; dispatches actions |
| Home feed — no card in focus                    | **LLM**    | `Ask anything…`        | LLM receives input as general request (e.g. "text steve")     |
| Chat thread (`OrderedCollection<ChatMessage>`)  | **Direct** | `Type a message…`      | Keystrokes sent as chat message (encrypted or federated)      |
| Draft card in compose column                    | **Direct** | `Write your post…`     | Keystrokes compose the draft content directly                 |
| Remote feed (`OrderedCollection<Note/Article>`) | **LLM**    | `Ask about this feed…` | LLM receives input + feed/card context; dispatches actions    |
| Trust context view                              | **LLM**    | `Ask anything…`        | LLM receives input + trust request context                    |

**The rule is simple:** if the active view is a chat thread or a content draft, you're typing directly. Everything else routes through the LLM.

#### Mode Switching

Modes change **only** via gesture (swipe) or focus change. There is no button, icon, or control to change the input mode. The user never thinks about modes — they only think about what card they're looking at and what column they're in.

---

### 7.3 Swipe Interactions — The Column Navigator in Action

All navigation is expressed as horizontal swipes on cards. **Both left and right swipes perform the same action** — drill into the swiped card's detail view — but the new column opens **in the direction of the swipe.** Swipe right and the detail column appears to the right; swipe left and it appears to the left. There are no other navigation gestures (except for vertical scroll).

#### Swipe (Either Direction) → Opens Detail Column (Context-Dependent)

The content of the new column depends on the **type of the swiped card:**

| Swiped card type                      | New column content                                         |
| ------------------------------------- | ---------------------------------------------------------- |
| `Note` / `Article` from remote server | Origin server's public feed, card in chronological context |
| `ChatMessage` (incoming message)      | Full E2EE chat thread with that contact or group           |
| `TrustRequest`                        | Trust context for that request                             |
| Follow / activity notification card   | That actor's feed                                          |
| Stream card                           | That stream's topic feed                                   |
| Draft card (unsent)                   | Compose view for that draft                                |

On a 1-column device (mobile default), the new content **replaces** the current column — the home feed slides off-screen in the opposite direction and the detail view takes over full screen. Swiping back in the opposite direction restores the home feed. On a 2+ column device, the new column is added in the swipe direction; existing columns compress to make room.

**Why symmetric swipe?** Users can arrange their workspace however they prefer. Swipe a chat right to open it beside the feed, or swipe it left to open it on the other side. On multi-column devices this gives spatial flexibility — the user controls the layout, not the system.

#### AI Without a Mode — LLM as Default Input

There is no dedicated "AI mode" or "AI pane." The LLM is the **default input handler** on the home feed and any non-chat detail column. Users interact with the LLM simply by typing (or speaking) while a card is in focus.

**Example LLM interactions from the home feed:**

- `"Unfollow"` (card focused) → LLM dispatches `Undo Follow` activity
- `"Block this server"` (card focused) → LLM updates Config Registry domain blocklist
- `"Translate this"` (card focused) → LLM returns translated text inline
- `"What can I do here?"` (card focused) → LLM describes available actions in plain language
- `"Mute words like this"` (card focused) → LLM updates muted keywords in Config Registry
- `"Change my bio to…"` (no card focused) → LLM updates user profile via API
- `"Text steve"` (no card focused) → LLM resolves contact, opens chat
- `"Create a stream called Photography"` (no card focused) → LLM creates `OrderedCollection`, adds to actor's `streams`
- `"Post this to my photography stream"` (card focused) → LLM adds object to stream via `Add` activity

#### The Home Feed as Unified Inbox

The home feed is the **single inbox for all events** — messages, status updates, articles, follow notifications, trust requests, likes, dislikes. There are no separate notification screens, badge counts, or inbox/feed distinctions. Users can also create **streams** — topic-specific feeds that curate a subset of their content (see §9.13). Streams appear as swipeable cards in the home feed and as entries in the actor's `streams` property for federated discovery.

```
HOME FEED — unified inbox (newest at bottom)
┌─────────────────────────────────────┐
│  📣 @bob: "Check this out"           │  ← Note  — swipe → remote feed
│                                     │
│  🔔 @carol followed you             │  ← Follow — swipe → @carol's feed
│                                     │
│  🔒 Trust request from @child       │  ← TrustRequest — swipe → trust view
│                                     │
│ ╔═════════════════════════════════╗ │
│ ║ 💬 @alice: hey are you free?    ║ │  ← ChatMessage card — focused
│ ╚═════════════════════════════════╝ │    swipe → opens full chat thread
├─────────────────────────────────────┤
│  Ask anything…              [Send]  │  ← Input bar: LLM mode (card in focus)
└─────────────────────────────────────┘
```

The input bar never moves. Its mode (LLM or direct) changes based on the object type of the active column (see §7.2).

#### Swipe Mechanics

- Commit threshold: `ui.swipe_commit_threshold` in Config Registry (default: 0.4 = 40% screen width)
- Commit velocity: `ui.swipe_velocity_threshold` (default: 800px/s)
- Below both thresholds: card springs back, no navigation
- Animation: ~300ms ease-in-out; card motion physically continuous throughout
- Must not conflict with vertical scroll or horizontal scroll within cards

---

### 7.4 Content Creation Flow

Content creation is initiated through the LLM and completed either inline or in a dedicated compose column. The system never auto-opens a compose view — the user controls when and whether to expand the draft (see "Layout is User-Controlled" in §1.4).

#### Creation Sequence

```
Home feed, LLM mode, user types: "tweet"
       │
       ▼
LLM creates a new DRAFT card at the bottom of the feed
  - Type: Note (or Article, depending on LLM interpretation)
  - Status: unsent, unedited
  - Card is automatically in focus
  - Layout does NOT change — still on home feed
       │
       ▼
User has two paths:
       │
       ├──▶ SWIPE the draft card → opens compose column
       │      Input bar switches to DIRECT mode
       │      User types content with keyboard
       │      "Send" / "Post" submits the draft
       │
       └──▶ STAY on home feed → continue talking to LLM
              "Make it about the weather" → LLM fills in content
              "Add a photo" → LLM attaches media
              "Post it" → LLM publishes the draft
```

#### Draft Card States

| State       | Visual indicator            | Input bar (if swiped to column) | Input bar (if on home feed) |
| ----------- | --------------------------- | ------------------------------- | --------------------------- |
| **Empty**   | Blank card, cursor blinking | `Write your post…` (Direct)     | `Ask anything…` (LLM)       |
| **Drafted** | Content preview visible     | Direct editing                  | LLM can revise on request   |
| **Sent**    | Normal card appearance      | N/A (no longer a draft)         | N/A                         |

Draft cards are **local-only** until explicitly published. They are not federated, not visible to anyone else, and can be discarded at any time ("delete that draft" via LLM, or swipe-to-dismiss TBD).

---

### 7.5 LLM Client

The LLM client is **server-side only** — an HTTP client within the Next.js process that calls an external LLM API. The client never calls an LLM provider directly.

#### Request Flow

```
Client sends: { userInput, focusedCardId, activeColumnType, conversationHistory }
       │
       ▼
Next.js API route validates + enriches with full card ActivityPub object
       │
       ▼
LLM Client:
  1. Read Config Registry (already in process memory)
  2. Build system prompt: server config + card context + available actions
  3. Call external LLM API (Claude by default)
  4. Parse response → { replyText, actions[] }
  5. Execute actions[] via AP engine or Config Registry writer
  6. Return replyText to client
```

#### LLM Permissions

| The LLM client **can**                                              | The LLM client **cannot**         |
| ------------------------------------------------------------------- | --------------------------------- |
| Read entire Config Registry (in process memory)                     | Read or write PostgreSQL directly |
| Write scoped Config Registry keys                                   | Access another user's data        |
| Dispatch ActivityPub activities on behalf of the authenticated user | Make outbound network calls       |
| Return natural language responses                                   | Modify server infrastructure      |
| Describe available actions for any card context                     |                                   |

---

### 7.6 Chat — 1:1 and Group Messaging

Chat is a **first-class, primary feature** of Lightweb Browser v1 — equivalent in importance to the social feed. Lightweb supports two distinct wire formats for direct messaging — **federated DMs** (standard ActivityPub private `Note` objects) and **encrypted chat** (`ChatMessage` objects over MLS) — presented in a **single unified chat thread** in the UI.

#### Two Wire Types, One Thread

|                   | Federated DM                                                                             | Encrypted Chat                                                                     |
| ----------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Wire type**     | `Note` (private addressing)                                                              | `ChatMessage` (Lightweb custom)                                                    |
| **AP compatible** | All implementations                                                                      | Lightweb (+ future MLS-capable servers)                                            |
| **Encryption**    | None (standard AP transport)                                                             | Always E2EE (MLS)                                                                  |
| **RCS features**  | None (typing, read receipts, presence unavailable)                                       | Full (typing indicators, read receipts, presence)                                  |
| **Delivery**      | AP inbox (polling)                                                                       | WebSocket real-time + 5s fallback                                                  |
| **Requires**      | `messaging.allow_insecure_dm` or sender matches `insecure_dm` permission rule (see §8.8) | Mutual `Relationship` objects matching `encrypted_chat` permission rule (see §8.8) |

Both types are rendered in the **same chat thread column** — the user sees one conversation, not two. Per-message indicators show encryption and RCS status.

#### Conversation Lifecycle — The Upgrade Path

Every 1:1 conversation follows a state machine driven by the mutual `Relationship` state of the two parties:

```
CONVERSATION STATES (per contact pair)
═══════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────┐
  │  State 1: FEDERATED DM                              │
  │  Wire type: Note (private addressing)               │
  │  Encryption: ❌ None (standard AP)                  │
  │  RCS: ❌ Not available                              │
  │  Requires: config allows insecure DMs, OR           │
  │            sender matches insecure_dm permission    │
  │            rule (see §8.8)                          │
  │  Works with: any AP server (Mastodon, Pleroma, etc) │
  └──────────────────────┬──────────────────────────────┘
                         │
                  both parties have mutual
                  Relationship objects such
                  that encrypted_chat permission
                  rule evaluates to true
                  (e.g. mutual lw:friendOf)
                         │
                         ▼
  ┌─────────────────────────────────────────────────────┐
  │  State 2: ENCRYPTED CHAT                            │
  │  Wire type: ChatMessage (MLS group)                 │
  │  Encryption: ✅ Always (MLS)                        │
  │  RCS: ✅ Active (typing, read receipts, presence)   │
  │  Requires: both parties on Lightweb (or MLS-capable)│
  │  MLS group created on mutual encrypted_chat match   │
  └─────────────────────────────────────────────────────┘
```

The upgrade is **per-relationship, not per-message.** Once both sides have `Relationship` objects that satisfy the `encrypted_chat` permission rule (e.g. mutual `lw:friendOf`), the MLS group is established and all future messages use `ChatMessage`. Historical federated DM `Note` objects remain visible in the thread but are permanently marked as unencrypted.

**Upgrade trigger:** When the second party accepts a friend request (creating mutual `Relationship` objects that satisfy the `encrypted_chat` permission rule):

1. Initiating server creates an MLS group `[alice, bob]`
2. Sends MLS Welcome message to the other party's server
3. Conversation `mode` flips from `"federated"` to `"encrypted"`
4. System message inserted in thread: _"Messages are now encrypted"_ and _"Real-time chat active"_
5. WebSocket channel established — RCS features activate
6. All future messages in this thread are `ChatMessage`

The upgrade is **irreversible** — removing the `Relationship` object that enabled encryption ends the conversation, it does not downgrade it back to federated DM.

**Federated DM acceptance rules:**

| `messaging.allow_insecure_dm` | Sender matches `insecure_dm` rule? | Mutual `encrypted_chat` match? | Result                              |
| ----------------------------- | ---------------------------------- | ------------------------------ | ----------------------------------- |
| `false`                       | No                                 | No                             | DM silently rejected (default-deny) |
| `false`                       | Yes                                | No                             | DM accepted as federated `Note`     |
| `true`                        | No                                 | No                             | DM accepted as federated `Note`     |
| `true`                        | Yes                                | No                             | DM accepted as federated `Note`     |
| either                        | either                             | Yes                            | Upgrade to `ChatMessage` + MLS      |

#### The ChatMessage Object Type

`ChatMessage` is a dedicated `LightwebObject` type with `encryption: "required"` in its extension manifest. It is structurally separate from `Note` — they are never conflated at the wire level.

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

A conversation is an ActivityPub `OrderedCollection` with a `mode` that tracks the current lifecycle state. Before upgrade, it contains `Note` objects; after upgrade, `ChatMessage` objects. Both coexist in the same ordered timeline.

```
Conversation (OrderedCollection)
  ├── id: https://alice.lightweb.cloud/conversations/xyz
  ├── type: "OrderedCollection"
  ├── members: [alice, bob]              // or [alice, bob, carol, ...]
  ├── lwMetadata:
  │     ├── mode: "federated" | "encrypted"   // current lifecycle state
  │     ├── mlsGroupId?: "mls-group-uuid"     // set on upgrade to encrypted
  │     ├── mlsEpoch?: 42
  │     ├── upgradedAt?: "2026-02-17T14:00:00Z"
  │     └── hostServer?: alice.lightweb.cloud  // MLS Delivery Service (encrypted only)
  └── messages: [(Note | ChatMessage), ...]   // mixed timeline, ordered oldest first
```

#### AP Inbox Handling — Federated DMs

When a private `Note` arrives at the AP inbox (a `Note` addressed to only this actor with no public/followers audience):

```
Incoming private Note
        │
        ▼
  ┌──────────────────────────────┐
  │ Is insecure DM allowed       │
  │ for this sender?             │──── No ───▶ Silently reject
  │ (config flag OR sender       │
  │  matches insecure_dm rule)   │
  └──────── Yes ─────────────────┘
        │
        ▼
  ┌─────────────────────────┐
  │ Find or create          │
  │ Conversation            │
  │ (mode: "federated")     │
  └─────────────────────────┘
        │
        ▼
  ┌──────────────────────────────┐
  │ Do both parties have mutual  │
  │ tags matching encrypted_chat │
  │ permission rule?             │──── Yes ───▶ Create MLS group, upgrade
  └──────── No ──────────────────┘              conversation, notify both
        │
        ▼
  Store Note in Conversation
```

**Outgoing message routing** is determined by conversation mode:

- `mode: "federated"` → send as `Note` with private addressing (standard AP)
- `mode: "encrypted"` → send as `ChatMessage` with MLS encryption

#### Arriving in the Feed

Incoming messages — both federated DMs (`Note`) and encrypted chat (`ChatMessage`) — arrive as **chat cards in the home feed**, alongside posts and other events. They are visually distinct (chat bubble icon, sender avatar, message preview). There is no separate inbox.

Chat cards display a small indicator: 🔓 for unencrypted federated DMs, 🔒 for E2EE messages.

Tapping or focusing a chat card and swiping it (in either direction) opens the **full chat thread** as a new column in the direction of the swipe. On mobile (1-column), this replaces the feed full screen. On tablet/web, it opens as an adjacent column.

#### Chat Thread Column — Unified View with Indicators

```
CHAT THREAD — @bob@mastodon.social
┌─────────────────────────────────────────┐
│  ← @bob@mastodon.social                 │
│                                         │
│  Hey, saw your post about MLS     🔓    │  ← Note (federated DM)
│                          Thanks!  🔓    │  ← Note (federated DM)
│                                         │
│  ── @bob added you as a friend ──       │  ← system: mutual friend tag
│  ── 🔒 Messages are now encrypted ──   │
│  ── 📡 Real-time chat active ──        │
│                                         │
│  So about that MLS paper...       🔒📡 │  ← ChatMessage (E2EE + RCS)
│                     Reading it now 🔒📡 │  ← ChatMessage (E2EE + RCS)
│                          ✓✓ read        │  ← read receipt (RCS)
│                                         │
│  bob is typing…                         │  ← typing indicator (RCS)
├─────────────────────────────────────────┤
│  Reply to @bob…                  [Send] │
└─────────────────────────────────────────┘
```

**Per-message indicators:**

| Indicator | Meaning                                                           |
| --------- | ----------------------------------------------------------------- |
| 🔓        | Unencrypted (federated DM via standard AP)                        |
| 🔒        | End-to-end encrypted (ChatMessage via MLS)                        |
| 📡        | RCS active (real-time delivery, typing indicators, read receipts) |

**Indicator combinations in practice:**

| Conversation mode | E2EE | RCS | Notes                                                       |
| ----------------- | ---- | --- | ----------------------------------------------------------- |
| Federated         | ❌   | ❌  | Standard AP DM — any implementation                         |
| Encrypted         | ✅   | ✅  | Mutual `Relationship` objects — ChatMessage always has both |

RCS requires `ChatMessage`, and `ChatMessage` is always E2EE, so RCS is always encrypted. The indicators are shown independently to communicate _why_ — users understand real-time chat requires mutual trust.

- Newest messages at the bottom — same chronological convention as the feed
- Real-time delivery via WebSockets when in encrypted mode; AP inbox polling when federated
- Read receipts and typing indicators: only available in encrypted mode (RCS)
- Message states visible to sender only (no read receipt broadcasting by default — configurable)

#### Group Chat

Group conversations work identically to 1:1 encrypted chat, with the following additions. Group chat is **always encrypted** — there is no federated DM mode for groups (groups require `ChatMessage` + MLS from creation).

- Group has a name, optional avatar, and a member list
- The **creator's server** is the MLS Delivery Service (host server) for the group
- Host server maintains MLS group state (membership epochs, encrypted key packages) — it never holds decryption keys
- All messages route through the host server, which fans out to member servers via ActivityPub
- Member servers deliver to their users' clients

**Host migration (automatic):**
If the host server goes offline, the **oldest remaining member's server** automatically assumes the Delivery Service role. MLS handles the key rotation via a commit. No user action required. Migration completes within one reconnection cycle.

**Group membership changes:**

- Adding a member: any existing member can add (subject to their Circle of Trust `Relationship` objects)
- Removing a member: any member can remove themselves; group admin can remove others
- Every membership change triggers an MLS commit and key rotation — past messages remain inaccessible to removed members (forward secrecy)

#### Initiating a New Chat

No buttons. The user focuses any card from another user and types a message in the input bar. The LLM infers intent and creates a new conversation if one doesn't exist, or routes to the existing thread if it does. The user never thinks about "creating a conversation."

If the recipient is on a remote non-Lightweb server, the message is sent as a federated DM (`Note` with private addressing). If the recipient is on Lightweb and mutual `Relationship` objects satisfy the `encrypted_chat` permission rule, it goes as `ChatMessage`. The user doesn't choose — the system selects the best available transport.

---

### 7.7 User Profiles & Auth

- Username format: `@user@yourdomain.com`
- Profile fields: display name, bio, avatar, header image, up to 4 custom fields
- **Auth: SSO only — Google and Apple OAuth2. Zero password management.**
  - Account auto-provisioned from SSO identity on first login
  - No email/password fallback; no password reset flows
  - Store only the OAuth2 subject ID + provider, never credentials
  - SSO provider selection is the cloud provider's responsibility — additional providers (e.g. Facebook) may be offered by the hosting platform but are not part of the Lightweb app spec
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

When a controlled account attempts an action not on their allowlist, the system does not show an error. Instead it creates a `TrustRequest` — a native ActivityPub object that travels to the controller's feed as a card. TrustRequests are also used for **friend requests** between any accounts (open or controlled) — see §8.8 for the full friend request flow.

```jsonc
// LightwWeb extension: TrustRequest — permission escalation (controlled account)
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

```jsonc
// LightwWeb extension: TrustRequest — friend request (any account)
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://lightwebbrowser.org/ns",
  ],
  "type": "TrustRequest",
  "id": "https://alice.lightweb.cloud/trust-requests/def456",
  "actor": "https://alice.lightweb.cloud/users/alice", // requesting account
  "target": "https://bob.lightweb.cloud/users/bob", // recipient (not a controller)
  "requestedAction": {
    "type": "Create",
    "object": {
      "type": "Relationship",
      "relationship": "https://lightwebbrowser.org/ns/friendOf",
    },
  },
  "scope": "persistent",
  "message": "I'd like to add you as a friend",
  "status": "pending",
}
```

**TrustRequest scopes:**

| Scope          | Meaning                                                                 | Config change                                    |
| -------------- | ----------------------------------------------------------------------- | ------------------------------------------------ |
| `once`         | Approve viewing this specific post only                                 | None                                             |
| `content-only` | Allow future content from this account visible in feed (without follow) | Adds to content filter allowlist                 |
| `persistent`   | Full permission granted (follow, friendship, etc.)                      | Adds/updates contact in `social.contacts` config |

The LLM resolves the child's natural language request (_"ask my dad if I can see this"_) to the most conservative applicable scope, unless context suggests otherwise. Note that "my dad" indicates the destination, and also importantly, "my dad" must exist in the config registry as an alias in `social.contacts` mapped to a specific actor URI.

### 8.4 Approval Flow on the Controller's Feed

The `TrustRequest` arrives as a card in the controller's (parent's) feed. The card is in focus. The input bar default action is **Approve** — so the controller just hits send. Denial is handled via the LLM: with the trust request card in focus, the controller types a reason (e.g. "no, they post inappropriate content") and the LLM dispatches the denial with that reason, delivered back to the child's feed as a message.

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

To deny: type a reason → LLM dispatches denial with explanation
```

### 8.5 Configuration Object Permissions

The Config Registry is divided into named configuration objects. Each object is independently permissioned per controlled account.

| Config object                 | Example contents                          | Default for child account                                |
| ----------------------------- | ----------------------------------------- | -------------------------------------------------------- |
| `layout`                      | Card size, feed density                   | ✅ Editable by account                                   |
| `theme`                       | Colours, font size                        | ✅ Editable by account                                   |
| `social.contacts`             | Who you follow/friend and their tags      | 🔒 Controller only (unless delegated per tag — see §8.9) |
| `social.permissions`          | What each tag/combination unlocks         | 🔒 Controller only                                       |
| `content-filters`             | Muted keywords, blocked domains           | 🔒 Controller only                                       |
| `purchases`                   | Payment methods, spending limits          | 🔒 Controller only                                       |
| `account-profile`             | Display name, bio, avatar                 | 🟡 Configurable                                          |
| `trust-settings`              | Controller relationships                  | 🔒 Controller only                                       |
| `trust.delegated_permissions` | Which tags child can manage independently | 🔒 Controller only                                       |

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

### 8.8 Social Relationships & Contact Registry

Relationships between users are modelled as native ActivityStreams `Relationship` objects stored in the SQL database. Each relationship is an independent, non-hierarchical link between two actors — they do not imply each other. A `lw:friendOf` relationship does not automatically create `lw:following`; a `lw:closeFriendOf` does not automatically create `lw:friendOf`. Each relationship is created or removed as a separate action.

#### Relationship Types (v1)

| Relationship Type  | Meaning                                   | AP Activity                |
| ------------------ | ----------------------------------------- | -------------------------- |
| `lw:following`     | You follow their public content           | Standard AP `Follow`       |
| `lw:friendOf`      | Explicit trust relationship               | `TrustRequest` (see below) |
| `lw:closeFriendOf` | Highest trust — reserved for inner circle | `TrustRequest` (see below) |

Relationship types are URIs under the Lightweb namespace (`https://lightwebbrowser.org/ns/`). The v1 set is `["lw:following", "lw:friendOf", "lw:closeFriendOf"]`, but the system is extensible — post-v1 types (e.g. `lw:colleagueOf`, `lw:familyOf`) require no code changes, only config.

#### Relationship Storage (SQL)

Relationships are stored in the SQL database as addressable AP objects:

```sql
-- relationships table
id            TEXT PRIMARY KEY,   -- AP object URI (e.g. https://alice.lightweb.cloud/relationships/abc123)
subject       TEXT NOT NULL,      -- local actor URI
object        TEXT NOT NULL,      -- remote actor URI
relationship  TEXT NOT NULL,      -- relationship type URI (e.g. lw:friendOf)
created_at    TIMESTAMP NOT NULL,

-- fast permission lookups
CREATE INDEX idx_rel_subject_object ON relationships (subject, object);
CREATE INDEX idx_rel_subject_type ON relationships (subject, relationship);
```

Each row serializes to a native AS `Relationship` object on federation or API requests:

```jsonc
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://lightwebbrowser.org/ns",
  ],
  "type": "Relationship",
  "id": "https://alice.lightweb.cloud/relationships/abc123",
  "subject": "https://alice.lightweb.cloud/users/alice",
  "object": "https://bob.lightweb.cloud/users/bob",
  "relationship": "https://lightwebbrowser.org/ns/friendOf",
}
```

#### Contact Registry (Config)

Contact metadata that is not federated — aliases and display preferences — remains in the Config Registry under `social.contacts`, keyed by actor URI:

```jsonc
{
  "social": {
    "contacts": {
      "https://bob.lightweb.cloud/users/bob": {
        "aliases": ["bob", "Bob Smith"],
        "addedAt": "2026-02-17T12:00:00Z",
      },
      "https://carol.example.com/users/carol": {
        "aliases": ["carol"],
        "addedAt": "2026-02-18T10:00:00Z",
      },
    },
  },
}
```

- `aliases` — natural language names for LLM resolution (e.g. _"my dad"_, _"Bob"_). The LLM matches user references like _"message Bob"_ or _"ask my dad"_ against these aliases
- `addedAt` — ISO timestamp of when the contact was first added

Relationship state (which types exist between two actors) is always queried from the `relationships` table, never duplicated in config.

#### Relationship-Gated Permissions (Boolean Logic)

Permissions are gated on relationship types using boolean operators. Each permission rule uses `any` (OR) or `all` (AND) to define which relationship type combinations grant it:

```jsonc
{
  "social": {
    "permissions": {
      "encrypted_chat": { "any": ["lw:friendOf", "lw:closeFriendOf"] },
      "insecure_dm": {
        "any": ["lw:following", "lw:friendOf", "lw:closeFriendOf"],
      },
      "see_presence": { "all": ["lw:following", "lw:friendOf"] },
      "see_read_receipts": { "any": ["lw:closeFriendOf"] },
    },
  },
}
```

| Operator | Logic | Meaning                                                           |
| -------- | ----- | ----------------------------------------------------------------- |
| `any`    | OR    | At least one listed relationship type must exist for this contact |
| `all`    | AND   | All listed relationship types must exist for this contact         |

v1 supports one operator per permission rule. Combining `any` and `all` in a single rule (e.g. `{ "all": ["lw:following"], "any": ["lw:friendOf", "lw:closeFriendOf"] }`) is a post-v1 consideration.

**Permission evaluation:** When the system needs to check whether a contact is allowed a capability (e.g. encrypted chat), it queries the `relationships` table for all relationship types between the local actor and the contact, then evaluates them against the corresponding permission rule in `social.permissions`. If the rule evaluates to `true`, the capability is granted.

```sql
-- Example: "any" (OR) check for encrypted_chat
SELECT EXISTS (
  SELECT 1 FROM relationships
  WHERE subject = :local_actor AND object = :contact_actor
  AND relationship IN ('lw:friendOf', 'lw:closeFriendOf')
);
```

#### Follow Policy

For open accounts, incoming AP `Follow` requests are handled according to `social.follow_policy`:

| Policy              | Behaviour                                                               |
| ------------------- | ----------------------------------------------------------------------- |
| `auto_accept`       | Incoming follows are automatically accepted (default for open accounts) |
| `approval_required` | Incoming follows generate a card in the feed; user must approve         |

For controlled accounts, incoming follows are always subject to the controller's approval (unless `lw:following` is in delegated permissions — see §8.9).

#### Friend Request Flow (TrustRequest-Based)

Creating a `lw:friendOf` or `lw:closeFriendOf` relationship is a trust-sensitive action that requires the other party's consent. The flow uses the existing `TrustRequest` mechanism:

```
FRIEND REQUEST FLOW
═══════════════════════════════════════════════════════════════

  Alice says "friend Bob"
        │
        ▼
  ┌─────────────────────────────┐
  │ Is Alice a controlled       │
  │ account? And is "friendOf"  │──── Yes ───▶ TrustRequest to
  │ NOT in delegated perms?     │              Alice's controller
  └──────── No (or delegated) ──┘              (must approve first)
        │
        ▼
  System generates TrustRequest
  with requestedAction.type:
  "Create" and
  requestedAction.object.type:
  "Relationship" (lw:friendOf)
        │
        ▼
  TrustRequest sent to Bob
  via AP inbox (encrypted, MLS)
        │
        ▼
  Bob receives card in feed
  (if Bob is controlled →
   his controller must approve)
        │
        ▼
  ┌─────────────────────────────┐
  │ Bob accepts                 │
  │ → Relationship(lw:friendOf) │
  │   created in Bob's DB       │
  │ → TrustGrant sent to Alice  │
  │ → Relationship(lw:friendOf) │
  │   created in Alice's DB     │
  └─────────────────────────────┘
        │
        ▼
  ┌─────────────────────────────┐
  │ Mutual lw:friendOf          │
  │ exists? AND encrypted_chat  │──── Yes ───▶ Create MLS group,
  │ permission matches?         │              upgrade conversation
  └──────── No ─────────────────┘
        │
        ▼
  Done (one-way relationship only)
```

**Relationship promotion:** The same flow applies when adding a new relationship type to an existing contact (e.g. creating `lw:closeFriendOf` for someone who already has `lw:friendOf`). The TrustRequest specifies the relationship type being created.

**Relationship removal:** Removing a relationship is **unilateral** — no TrustRequest is needed. The local `Relationship` row is deleted. If you remove `lw:friendOf` from a contact, that ends the mutual friendship. Removing a relationship type that gates `encrypted_chat` ends the encrypted conversation (irreversible — it does not downgrade to federated DM).

#### The `lw:following` Relationship

The `lw:following` relationship type is special — it corresponds to the standard AP `Follow` activity. When a user says _"follow @bob"_:

1. System sends a standard AP `Follow` activity to Bob's server
2. Bob's server responds with `Accept` or `Reject` (per Bob's `follow_policy`)
3. On `Accept`, a `Relationship` row is inserted: `subject=Alice, object=Bob, relationship=lw:following`

This ensures interoperability — `lw:following` maps 1:1 to AP Follow, so it works with any AP server (Mastodon, Pleroma, etc.), not just Lightweb.

### 8.9 Delegated Permissions for Controlled Accounts

By default, all relationship changes on a controlled account require controller approval (generating a `TrustRequest`). However, the controller can **delegate** specific relationship type changes to the controlled account, allowing them to act autonomously for those types.

Delegated permissions are stored in the Config Registry under `trust.delegated_permissions`:

```jsonc
{
  "trust": {
    "account_type": "controlled",
    "controllers": ["https://parent.lightweb.cloud/users/parent"],
    "delegated_permissions": {
      "lw:following": true, // child can follow/unfollow without approval
      "lw:friendOf": false, // creating friendOf relationship requires controller approval
      "lw:closeFriendOf": false, // creating closeFriendOf relationship requires controller approval
    },
  },
}
```

When a relationship type change matches a delegated permission set to `true`, no `TrustRequest` is generated to the controller — the controlled account proceeds autonomously. The controller can adjust delegated permissions at any time via their own LLM (writing to the controlled account's config).

**Example:** A parent might delegate `lw:following` permission to their child so the child can follow accounts freely, while still requiring approval for `lw:friendOf` requests (which unlock encrypted chat and other trust-gated features).

---

## 9. Object Model & Extension Architecture

### 9.1 Design Philosophy

Lightweb Browser uses a **minimal, curated set of core object types.** Every type is formally defined, internally maintained, and openly published as a spec so other ActivityPub implementors may adopt them. No third-party plugins exist — all types are first-party. Richness comes not from proliferating types but from **hierarchy and metadata tags.**

> The pudding is in the organisation, not the type count.

**Plain text only — no HTML.** All text content (`Note`, `Article`, `ChatMessage`) is plain text. Lightweb never renders user-supplied HTML. Uncontrolled layouts are treated as both a security risk (XSS, phishing, UI redressing) and an accessibility failure (screen readers, variable viewports, theme consistency). Incoming federated objects that contain HTML in `content` are stripped to plain text on ingestion. The `mediaType` field on all outgoing objects is always `text/plain`.

### 9.2 ActivityPub / ActivityStreams Conformance

The table below maps every AP/AS standard type to Lightweb's implementation status. **Implementation levels:**

- **Native** — used as-is per the AP/AS spec, no modifications
- **Extended** — standard AP/AS type with Lightweb namespace properties added (`lwMetadata`, `lwTags`, etc.)
- **Proprietary** — Lightweb-only type with no direct AP/AS equivalent; published under `lightwebbrowser.org/ns`
- **—** — not implemented in v1

#### Activities

| AP/AS Activity         | v1  | Implementation | Lightweb Usage                                              |
| ---------------------- | --- | -------------- | ----------------------------------------------------------- |
| `Accept`               | ✅  | Native         | Accept Follow, accept TrustRequest                          |
| `TentativeAccept`      | —   |                |                                                             |
| `Add`                  | ✅  | Native         | Add object to OrderedCollection                             |
| `Announce`             | ✅  | Native         | Boost / repost a Note or Article                            |
| `Block`                | —   |                | Not implemented — allowlist-only model                      |
| `Create`               | ✅  | Native         | Create any object (Note, Product, etc.)                     |
| `Delete`               | ✅  | Native         | Delete any owned object                                     |
| `Dislike`              | ✅  | Native         | Dislike (👎) — used as part of the review mechanism         |
| `Flag`                 | —   |                | No moderation at v1                                         |
| `Follow`               | ✅  | Native         | Follow an actor                                             |
| `Ignore`               | —   |                |                                                             |
| `Invite`               | —   |                |                                                             |
| `Join`                 | —   |                |                                                             |
| `Leave`                | —   |                |                                                             |
| `Like`                 | ✅  | Native         | Like (👍) a Note, Article, Product, Audio, Video            |
| `Listen`               | —   |                | Playback tracked via Audio/Video actions, not activities    |
| `Move`                 | —   |                |                                                             |
| `Offer`                | —   |                |                                                             |
| `Read`                 | —   |                | Read receipts handled at transport layer, not as activities |
| `Reject`               | ✅  | Native         | Reject Follow, reject TrustRequest                          |
| `TentativeReject`      | —   |                |                                                             |
| `Remove`               | ✅  | Native         | Remove object from OrderedCollection                        |
| `Undo`                 | ✅  | Native         | Undo Follow, Undo Like, Undo Dislike, Undo Announce         |
| `Update`               | ✅  | Native         | Update any owned object                                     |
| `IntransitiveActivity` | —   |                |                                                             |
| `Arrive`               | —   |                |                                                             |
| `Travel`               | —   |                |                                                             |
| `Question`             | —   |                |                                                             |

#### Objects

| AP/AS Object        | v1  | Implementation | Lightweb Usage                                                                                                          |
| ------------------- | --- | -------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `Note`              | ✅  | Extended       | Status updates, fedi-DMs — short-form plain text, extended with `lwTags`, `lwMetadata`                                  |
| `Article`           | ✅  | Extended       | Long-form posts — plain text (no HTML), extended with `lwTags`, `lwMetadata`                                            |
| `Audio`             | ✅  | Extended       | Podcast episodes, music tracks — extended with `lwMetadata`, `lwTags`                                                   |
| `Document`          | —   |                |                                                                                                                         |
| `Event`             | —   |                |                                                                                                                         |
| `Image`             | ✅  | Native         | Used as attachment on Notes, Products, etc.                                                                             |
| `Page`              | —   |                |                                                                                                                         |
| `Place`             | —   |                |                                                                                                                         |
| `Profile`           | —   |                | Actor profile data stored on the Actor object directly                                                                  |
| `Relationship`      | ✅  | Native         | Native AS Relationship objects stored in SQL; permission rules gate on relationship types via boolean `any`/`all` logic |
| `Tombstone`         | ✅  | Native         | Marks deleted objects for federation consistency                                                                        |
| `Video`             | ✅  | Extended       | TV episodes, movies, short videos — extended with `lwMetadata`, `lwTags`                                                |
| `Link`              | ✅  | Native         | Standard AP link references                                                                                             |
| `Mention`           | ✅  | Native         | @-mentions in Notes and Articles                                                                                        |
| `OrderedCollection` | ✅  | Extended       | Menus, playlists, TV shows, storefronts, **streams** — extended with `lwMetadata.displayHint`, `lwTags`                 |
| `Collection`        | ✅  | Native         | Standard AP collections (followers, following, outbox)                                                                  |
| `CollectionPage`    | ✅  | Native         | Pagination for large collections                                                                                        |

#### Actors

| AP/AS Actor    | v1  | Implementation | Lightweb Usage                                                                                    |
| -------------- | --- | -------------- | ------------------------------------------------------------------------------------------------- |
| `Person`       | ✅  | Extended       | Primary user actor — extended with Lightweb trust/config properties and `streams` for topic feeds |
| `Application`  | —   | Future         |                                                                                                   |
| `Group`        | —   | Future         |                                                                                                   |
| `Organization` | —   | Future         |                                                                                                   |
| `Service`      | —   | Future         |                                                                                                   |

#### Lightweb Proprietary Types (no AP/AS equivalent)

| Lightweb Type  | v1  | AP/AS Basis | Notes                                                                     |
| -------------- | --- | ----------- | ------------------------------------------------------------------------- |
| `ChatMessage`  | ✅  | Proprietary | MLS-encrypted chat message — no standard AP equivalent for E2EE messaging |
| `TrustRequest` | ✅  | Proprietary | Permission escalation request — always encrypted.                         |
| `TrustGrant`   | ✅  | Proprietary | Permission approval — always encrypted.                                   |
| `Product`      | ✅  | Proprietary | Purchasable item (physical, digital, or service). out of scope for v1     |

**Summary:** Lightweb implements 13 of 27 AP/AS activity types and 13 of 17 AP/AS object/actor types natively or with extensions. The 4 proprietary types fill gaps where AP/AS has no equivalent (E2EE messaging, trust delegation, commerce). Reviews are expressed via native `Like`, `Dislike`, and `Note` objects — no proprietary type needed. All proprietary types are published as open specs on a phased roadmap (§9.11). All text content is plain text — no HTML is ever rendered (§9.1).

### 9.3 Core Object Types (v1)

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
  | "Note" // status update, fedi-DM (AP native, extended)
  | "Article" // long-form post (AP native, extended)
  | "Audio" // podcast episode, music track (AP native, extended)
  | "Video" // TV episode, movie, short video (AP native, extended)
  | "ChatMessage" // E2EE chat message (always encrypted)
  | "TrustRequest" // permission escalation (always encrypted)
  | "TrustGrant" // permission approval (always encrypted)
  | "Product"; // any purchasable thing — physical, digital, or service
```

**That's it.** Eight types — four of which (`Note`, `Article`, `Audio`, `Video`) are native AP/AS types extended with Lightweb namespace properties. Reviews are expressed via native `Like`, `Dislike`, and `Note` objects — no proprietary type needed (see §9.12). All text content is **plain text only** — no HTML is ever accepted or rendered (see §9.1). Everything else — menus, TV shows, podcasts, storefronts, playlists — is expressed as native ActivityPub `OrderedCollection` hierarchies of `Product`, `Audio`, and `Video` objects with Lightweb namespace properties (`lwTags`, `lwMetadata`). Collections are not a custom type — they use AP's built-in `OrderedCollection`, which any AP server already understands. Lightweb-specific rendering is driven by `lwMetadata.displayHint`.

### 9.4 Collections — Native AP OrderedCollection with Lightweb Properties

Collections use ActivityPub's native `OrderedCollection` type directly, extended with Lightweb namespace properties (`lwMetadata`, `lwTags`). This means any AP server recognizes them as valid collections — Lightweb-specific rendering is layered on top via `lwMetadata.displayHint`. Collections can nest arbitrarily (collections of collections), enabling menus, TV show seasons, playlists, etc. with no custom types.

```jsonc
// A restaurant menu — native AP OrderedCollection
{
  "@context": ["https://www.w3.org/ns/activitystreams", "https://lightwebbrowser.org/ns"],
  "type": "OrderedCollection",
  "id": "https://restaurant.lightweb.cloud/objects/menu-2026",
  "name": "Spring Menu",
  "lwMetadata": { "displayHint": "menu", "currency": "USD" },
  "lwTags": ["restaurant", "italian"],
  "orderedItems": [
    {
      "type": "OrderedCollection",       // nested collection = category
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
  "type": "OrderedCollection",
  "name": "The Last of Us",
  "lwMetadata": { "displayHint": "tvshow", "studio": "HBO" },
  "lwTags": ["drama", "sci-fi", "mature"],
  "orderedItems": [
    {
      "type": "OrderedCollection",       // season
      "name": "Season 1",
      "lwTags": ["season"],
      "orderedItems": [
        {
          "type": "Video",
          "name": "S1E1 — When You're Lost in the Darkness",
          "lwMetadata": { "duration": 4920, "quality": "4K", "episodeNumber": 1 },
          "lwTags": ["episode"]
        }
        // ... more episodes
      ]
    }
  ]
}
```

The `lwMetadata.displayHint` field tells the client **how to render** the collection card — as a menu, a storefront, a show, a playlist, etc. The data structure is identical; only the presentation hint differs. Non-Lightweb servers see valid `OrderedCollection` objects and can display them as plain lists.

### 9.5 Note & Article — Status Updates and Long-Form Posts

`Note` is a short-form status update — the equivalent of a tweet, toot, or fedi-DM. `Article` is a long-form post — a blog entry, essay, or announcement. Both are native AP/AS types extended with Lightweb namespace properties. **All content is plain text — no HTML is accepted or rendered** (see §9.1).

```jsonc
// A status update — native AP Note, extended
{
  "type": "Note",
  "id": "https://alice.lightweb.cloud/objects/note-001",
  "attributedTo": "https://alice.lightweb.cloud/users/alice",
  "content": "Just tried the new Italian place on 5th. Incredible bruschetta.",
  "mediaType": "text/plain",
  "published": "2026-02-18T12:00:00Z",
  "lwTags": ["food", "restaurant"],
}

// A long-form post — native AP Article, extended
{
  "type": "Article",
  "id": "https://alice.lightweb.cloud/objects/article-001",
  "attributedTo": "https://alice.lightweb.cloud/users/alice",
  "name": "Why I Left Instagram",
  "content": "After ten years of algorithmic feeds and sponsored content, I decided to try something different. Here's what I learned about owning my own social presence...",
  "mediaType": "text/plain",
  "published": "2026-02-18T14:30:00Z",
  "lwTags": ["essay", "social-media", "personal"],
  "lwMetadata": { "wordCount": 1200 },
}
```

**Note available actions:** Reply, Like, Boost, Delete
**Article available actions:** Reply, Like, Boost, Delete

The distinction matters for federation: other AP servers (Mastodon, Pleroma, etc.) render `Note` and `Article` differently — `Note` as a short status, `Article` with a title and full body. By using the correct native types, Lightweb content displays properly across the fediverse without any special handling.

### 9.6 The Product Type

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

**Available actions:** Purchase, Save, Share, Like, Dislike, React

### 9.7 Media Types — Audio & Video

Lightweb uses the native AP/AS `Audio` and `Video` types directly, extended with Lightweb namespace properties. The distinction between a "podcast" and a "TV show" is expressed via `lwTags` and parent `OrderedCollection`, not by type. Any AP server already understands `Audio` and `Video` — Lightweb adds structured metadata on top.

```jsonc
// A podcast episode — native AP Audio, extended
{
  "type": "Audio",
  "id": "https://media.lightweb.cloud/objects/ep-001",
  "name": "Episode 1 — The Beginning",
  "url": "https://media.lightweb.cloud/stream/ep-001", // standard AP property
  "duration": "PT45M", // ISO 8601 duration (standard AP property)
  "lwMetadata": {
    "streamUrl": "...", // resolved server-side, never exposed to untrusted clients
    "episodeNumber": 1,
  },
  "lwTags": ["podcast", "technology", "interview"],
}

// A TV episode — native AP Video, extended
{
  "type": "Video",
  "id": "https://media.lightweb.cloud/objects/ep-s1e1",
  "name": "S1E1 — When You're Lost in the Darkness",
  "url": "https://media.lightweb.cloud/stream/ep-s1e1",
  "duration": "PT1H22M",
  "lwMetadata": {
    "quality": "4K", // "SD" | "HD" | "4K"
    "streamUrl": "...",
    "episodeNumber": 1,
  },
  "lwTags": ["episode", "drama"],
}
```

**Available actions:** Play, Save, Share, Like, Dislike, React

### 9.8 Type → Action Vocabulary

| Object type         | Available actions                           | Reviewable (Like/Dislike/Note) | Encrypted           |
| ------------------- | ------------------------------------------- | ------------------------------ | ------------------- |
| `Note` (status)     | Reply, Like, Boost, Delete                  | ❌ No                          | ❌ No               |
| `Note` (private DM) | Reply, Delete                               | ❌ No                          | ❌ No (standard AP) |
| `Article`           | Reply, Like, Dislike, Boost, Delete         | ✅ Yes                         | ❌ No               |
| `ChatMessage`       | Reply, Delete                               | ❌ No                          | ✅ Always (MLS)     |
| `TrustRequest`      | Approve, Escalate                           | ❌ No                          | ✅ Always           |
| `TrustGrant`        | Revoke                                      | ❌ No                          | ✅ Always           |
| `Product`           | Purchase, Save, Share, Like, Dislike, React | ✅ Yes                         | ❌ No               |
| `Audio`             | Play, Save, Share, Like, Dislike, React     | ✅ Yes                         | ❌ No               |
| `Video`             | Play, Save, Share, Like, Dislike, React     | ✅ Yes                         | ❌ No               |
| `OrderedCollection` | Browse, Save, Share, React                  | 🟡 Inherits from children      | ❌ No               |
| Stream (`OC`)       | Browse, Add, Remove, Delete, Share          | 🟡 Inherits from children      | ❌ No               |

### 9.9 Tags — Filtering and Discovery

`lwTags` are arbitrary string tags on any object or collection. They drive filtering, sorting, and discovery. Examples:

```
Product tags:    "vegan", "gluten-free", "handmade", "service", "digital"
Audio tags:      "podcast", "music", "interview", "audiobook"
Video tags:      "episode", "movie", "4K", "mature", "documentary", "short"
OrderedCollection tags: "restaurant", "menu", "tvshow", "season", "playlist", "storefront"
Stream tags:    (topic tags matching stream content — "photography", "cooking", "tech")
Note tags:       (user-defined, used for search and muting)
Article tags:    "blog", "essay", "tutorial", "announcement"
```

Tags are not a controlled vocabulary — they are free strings. The LLM can suggest tags when an object is created and can filter feeds by tag on user request (_"show me only vegan items"_, _"hide mature content"_).

### 9.10 Action Parameters & Registry Defaults

Every action has parameters with registry-stored defaults, adjustable via LLM.

```jsonc
// Extension manifest: Audio & Video (shared media actions)
{
  "extension": "lightwebbrowser.org/ns/media",
  "objectTypes": ["Audio", "Video"],
  "encryption": "none",
  "reviewable": true, // supports Like/Dislike/Note review mechanism (§9.12)
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

### 9.11 JSON-LD Namespace & Publishing

Extensions are published as JSON-LD context documents at `https://lightwebbrowser.org/ns`. Other ActivityPub servers may implement these types as they wish. Lightweb does not control or gate third-party implementations — the spec is open, the implementation is curated.

**Publishing roadmap:**

- **v1:** Internal — namespace not publicly resolvable; spec documented internally
- **v2:** Publish `TrustRequest`, `TrustGrant` specs — highest interoperability value
- **v3+:** Publish `Product`, full ecommerce vocabulary, and `lwMetadata` extensions for `Audio`/`Video`

### 9.12 Reviews — Native Like, Dislike & Note

Reviews are expressed using three native ActivityStreams objects — no proprietary type required:

1. **`Like`** — 👍 positive rating (native AP activity)
2. **`Dislike`** — 👎 negative rating (native AP activity)
3. **`Note`** — optional review blurb attached as `inReplyTo` the reviewed object

```jsonc
// 👍 Like a product — native AP Like activity
{
  "type": "Like",
  "actor": "https://server.com/users/alice",
  "object": "https://remote.com/objects/product-xyz",
  "published": "2026-02-17T12:00:00Z"
}

// Optional review blurb — native AP Note, linked to the reviewed object
{
  "type": "Note",
  "id": "https://server.com/notes/review-abc123",
  "attributedTo": "https://server.com/users/alice",
  "inReplyTo": "https://remote.com/objects/product-xyz",
  "content": "Loved the quality, arrived quickly.",
  "mediaType": "text/plain",
  "published": "2026-02-17T12:00:01Z"
}
```

**Review rules:**

- One Like or Dislike per actor per object — subsequent actions replace the previous (via `Undo` + re-issue)
- Blurb (`Note` as `inReplyTo`) optional but encouraged — LLM prompts for one if omitted
- `Note` (status) and `ChatMessage` are not reviewable — use Like/Boost for status updates
- Reviewable types at v1: `Article`, `Product`, `Audio`, `Video`
- Aggregate counts (👍 total, 👎 total) computed server-side and cached
- **Future:** blockchain or central authority for fraud-resistant Like/Dislike counts is a post-v1 consideration

### 9.13 Streams — Topic-Specific Feeds

A **stream** is a topic-specific feed that an actor publishes alongside their main outbox. Each stream is a native AP `OrderedCollection` listed in the actor's `streams` property — a standard AP property designed for exactly this purpose.

**Streams vs. outbox:** The `outbox` contains _all_ activities produced by the actor. A stream is a curated subset — a filtered view on a specific topic. When an actor creates a `Note` or `Article` and assigns it to a stream, it appears in both the outbox (for followers who want everything) and the stream collection (for followers who want only that topic).

```jsonc
// Actor object with streams
{
  "@context": ["https://www.w3.org/ns/activitystreams", "https://lightwebbrowser.org/ns"],
  "type": "Person",
  "id": "https://alice.lightweb.cloud/users/alice",
  "outbox": "https://alice.lightweb.cloud/users/alice/outbox",
  "streams": [
    {
      "type": "OrderedCollection",
      "id": "https://alice.lightweb.cloud/users/alice/streams/photography",
      "name": "Photography",
      "lwMetadata": { "displayHint": "feed" },
      "lwTags": ["photography", "art"],
      "totalItems": 42
    },
    {
      "type": "OrderedCollection",
      "id": "https://alice.lightweb.cloud/users/alice/streams/cooking",
      "name": "Cooking",
      "lwMetadata": { "displayHint": "feed" },
      "lwTags": ["cooking", "recipes"],
      "totalItems": 17
    }
  ]
}

// A Note published to a stream
{
  "type": "Create",
  "actor": "https://alice.lightweb.cloud/users/alice",
  "object": {
    "type": "Note",
    "id": "https://alice.lightweb.cloud/objects/note-789",
    "content": "Golden hour at the pier today.",
    "mediaType": "text/plain",
    "attachment": [{ "type": "Image", "url": "..." }],
    "lwTags": ["photography", "sunset"]
  },
  "target": "https://alice.lightweb.cloud/users/alice/streams/photography"
}
```

**Stream rules:**

- Streams are `OrderedCollection` objects with `lwMetadata.displayHint: "feed"` — any AP server sees a valid collection
- An actor can have zero or more streams — there is no required default stream
- The actor's `outbox` remains the canonical complete feed; streams are curated subsets
- Objects can belong to multiple streams (e.g. a recipe photo in both "Photography" and "Cooking")
- Stream membership is managed via native AP `Add` / `Remove` activities targeting the stream collection
- Creating a stream: LLM creates an `OrderedCollection` and adds it to the actor's `streams` — _"create a stream called Photography"_
- Deleting a stream: LLM removes the `OrderedCollection` from `streams` — objects themselves are not deleted
- Publishing to a stream: LLM includes the `target` field pointing to the stream — _"post this to my photography stream"_
- Followers can follow the actor (gets everything via outbox) or discover and follow individual streams for topic-specific content
- Streams federate normally — remote actors can fetch any public stream via its `id` URL
- On the home feed, own streams appear as swipeable cards; swiping opens the stream as a topic feed column

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

| Object type                      | Encryption                      | Defined in manifest                                                             |
| -------------------------------- | ------------------------------- | ------------------------------------------------------------------------------- |
| `ChatMessage`                    | ✅ Required (MLS)               | `encryption: "required"`                                                        |
| `TrustRequest` / `TrustGrant`    | ✅ Required (MLS)               | `encryption: "required"`                                                        |
| `Note` (public status)           | ❌ None                         | `encryption: "none"`                                                            |
| `Note` (private DM)              | ❌ None (standard AP transport) | N/A — standard AP `Note` with private addressing; not a Lightweb extension type |
| `Article`                        | ❌ None                         | `encryption: "none"`                                                            |
| `Product` / `Audio` / `Video`    | ❌ None (public objects)        | `encryption: "none"`                                                            |
| HTTP Signatures (all federation) | ✅ Ed25519 signing              | Transport layer                                                                 |
| Config Registry                  | ❌ Server-side only             | Never on client                                                                 |

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

  "database": {
    "provider": "postgres", // "postgres" | "sqlite"
    "connection_string_env": "DATABASE_URL", // actual URL loaded from env var
  },

  "queue": {
    "provider": "redis", // "redis" | "in-memory"
    "host": "127.0.0.1", // local sidecar
    "port": 6379,
  },

  "auth": {
    "sso_providers": ["google", "apple"],
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
      "posts_require_swipe": true, // post read receipt only on swipe-to-connect
    },
  },

  "messaging": {
    "allow_insecure_dm": false, // default: reject federated DMs from unknown senders
    "rcs": {
      "typing_indicators": true, // send typing events (encrypted mode only)
      "read_receipts": true, // send read receipts (encrypted mode only)
      "presence": true, // online/offline/last seen (encrypted mode only)
    },
  },

  "social": {
    "follow_policy": "auto_accept", // "auto_accept" | "approval_required"
    "relationship_types": ["lw:following", "lw:friendOf", "lw:closeFriendOf"], // extensible
    "contacts": {
      // keyed by actor URI — aliases/metadata only; relationships live in SQL
    },
    "permissions": {
      // each rule uses "any" (OR) or "all" (AND) boolean logic on relationship types
      "encrypted_chat": { "any": ["lw:friendOf", "lw:closeFriendOf"] },
      "insecure_dm": {
        "any": ["lw:following", "lw:friendOf", "lw:closeFriendOf"],
      },
      "see_presence": { "any": ["lw:friendOf", "lw:closeFriendOf"] },
      "see_read_receipts": { "any": ["lw:closeFriendOf"] },
    },
  },

  "trust": {
    "account_type": "open", // "open" | "controlled"
    "controllers": [], // actor URIs of controlling accounts
    "delegated_permissions": {
      // only relevant for controlled accounts; keyed by relationship type
      "lw:following": true, // can follow/unfollow without approval
      "lw:friendOf": false, // creating friendOf relationship requires controller approval
      "lw:closeFriendOf": false, // creating closeFriendOf relationship requires controller approval
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
| LLM client (in-process)  | ✅ Full            | ✅ Scoped (user-affecting keys only, not server-wide) |
| API routes (in-process)  | ✅ Full            | ❌                                                    |
| AP engine (in-process)   | ✅ Federation keys | ❌                                                    |
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
│   ├── quest/            # Meta Quest client (React Native / OpenXR — voice-first VR/AR)
│   └── server/           # Next.js — unified server (API, AP engine, LLM client, web shell)
│       ├── app/           # Next.js App Router (pages, layouts, RSC)
│       ├── api/           # API routes (REST, AP inbox/outbox, WebFinger)
│       └── ws/            # WebSocket server attachment for real-time chat
├── packages/
│   ├── ui/               # Shared React Native + web UI components (via Solito)
│   │   ├── Feed/
│   │   ├── Card/
│   │   ├── InputBar/
│   │   ├── SwipeNavigator/
│   │   └── DraftCard/
│   ├── types/            # Shared TypeScript types
│   ├── ap-core/          # ActivityPub builders & validators
│   ├── lw-objects/       # LightwebObject base type + extension manifest loader
│   │   ├── base/         # LightwebObject, TrustRequest, TrustGrant
│   │   └── extensions/   # Internal extension manifests (Product, Audio/Video media, etc.)
│   ├── llm-client/       # LLM provider abstraction (Claude, OpenAI, Gemini)
│   ├── db-client/        # Database provider abstraction (Postgres, SQLite)
│   ├── queue-client/     # Queue/cache provider abstraction (Redis, in-memory)
│   ├── trust/            # Circle of Trust — account model, permission checks
│   ├── crypto/           # MLS client, Ed25519/X25519 keypair mgmt, key backup
│   ├── config-registry/  # Registry loader, reader, writer, TypeScript types
│   └── tsconfig/         # Shared TS config
├── config/
│   └── registry.json     # THE config registry (secrets via env vars only)
├── Dockerfile            # Single container: Next.js + Redis sidecar
├── turbo.json
├── package.json
└── PRD.md
```

---

## 14. Open Questions

| #   | Question                         | Owner              | Status                                                                                                                                                                                                                  |
| --- | -------------------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | App name                         | Product            | 🟢 **Lightweb Browser**                                                                                                                                                                                                 |
| 2   | SSO providers                    | Product            | 🟢 Google + Apple. Additional providers (e.g. Facebook) are the cloud provider's responsibility, not the app spec                                                                                                       |
| 3   | Notifications                    | Product            | 🟢 Replaced by feed cards — no separate notification system                                                                                                                                                             |
| 4   | Account model                    | Product            | 🟢 Open or Controlled; no intermediate types                                                                                                                                                                            |
| 5   | Controller LLM scope             | Product            | 🟢 Config-write only; cannot execute actions on controlled account                                                                                                                                                      |
| 6   | Allowlist philosophy             | Product            | 🟢 Confirmed — allowlist always, never deny                                                                                                                                                                             |
| 7   | LLM write scope                  | Product + Security | 🟢 User LLM: own config objects only. Server-wide: operator only                                                                                                                                                        |
| 8   | TrustRequest scopes              | Product            | 🟢 Three scopes: `once`, `content-only`, `persistent`                                                                                                                                                                   |
| 9   | Multiple controllers             | Product            | 🟢 Any one controller sufficient; first to respond wins                                                                                                                                                                 |
| 10  | Hosting model                    | Product            | 🟢 Single-user-per-server — dedicated container per user, domain = identity                                                                                                                                             |
| 11  | Content moderation               | Product            | 🟢 None at v1. No comments. Reviews via native `Like`/`Dislike`/`Note` replace them                                                                                                                                     |
| 12  | E2EE                             | Engineering        | 🟢 MLS (RFC 9420). Hybrid key storage                                                                                                                                                                                   |
| 13  | Rating format                    | Product            | 🟢 👍 / 👎 via native Like/Dislike + optional Note blurb                                                                                                                                                                |
| 14  | Extension namespace              | Product            | 🟢 v1 internal; v2 publish TrustRequest/TrustGrant; v3+ domain types                                                                                                                                                    |
| 15  | Chat thread layout               | Product            | 🟢 Full screen on 1-col mobile; right column on 2+ col tablet/web                                                                                                                                                       |
| 16  | Group host migration             | Engineering        | 🟢 Automatic — oldest remaining member's server via MLS commit                                                                                                                                                          |
| 17  | Column counts                    | Product            | 🟢 Mobile default 1, tablet 2–3; always user-configurable per device                                                                                                                                                    |
| 18  | Encryption per type              | Engineering        | 🟢 Defined in extension manifest (`encryption: "required"/"optional"/"none"`)                                                                                                                                           |
| 19  | App store strategy               | Product            | 🟢 Single app — "Lightweb Browser" on iOS and Android. Server personalisation happens at first launch, not in the binary                                                                                                |
| 20  | AI chat history                  | Product            | 🟢 Not stored — ephemeral per session                                                                                                                                                                                   |
| 21  | LLM API key                      | Engineering        | 🟢 Operator only at v1; user-owned LLM is post-v1                                                                                                                                                                       |
| 22  | Remote feed connection           | Engineering        | 🟢 Background polling (default 60s, configurable) + on-demand WebSocket on swipe-to-connect                                                                                                                             |
| 23  | Config registry tracking         | Engineering        | 🟢 Git-tracked — secrets via env vars only                                                                                                                                                                              |
| 24  | Key revocation                   | Engineering        | 🟢 MLS epoch advancement — any group member triggers commit; old-epoch messages inaccessible after rotation                                                                                                             |
| 25  | Reviewable types at v1           | Product            | 🟢 Article, Product, Audio, Video (reviewed via native Like/Dislike/Note)                                                                                                                                               |
| 26  | Container orchestration          | Engineering        | 🟢 Kubernetes                                                                                                                                                                                                           |
| 27  | Read receipts                    | Product            | 🟢 On by default. Post read receipt only on swipe-to-connect. Chat on delivery/view                                                                                                                                     |
| 29  | Object types                     | Product            | 🟢 8 core types: Note, Article, Audio, Video, ChatMessage, TrustRequest, TrustGrant, Product. Reviews via native Like/Dislike/Note. Collections use native AP `OrderedCollection`                                       |
| 30  | Collection implementation        | Engineering        | 🟢 Native AP `OrderedCollection` with Lightweb namespace properties (`lwMetadata`, `lwTags`)                                                                                                                            |
| 31  | Background polling default       | Product            | 🟢 60s, user-configurable in registry                                                                                                                                                                                   |
| 32  | Services as type                 | Product            | 🟢 Services are Products with `lwTags: ["service"]` — no separate type                                                                                                                                                  |
| 33  | Apple Sign In                    | Legal + Eng        | 🟢 Included — Google + Apple are the two app-level SSO providers. Additional providers are the cloud provider's responsibility                                                                                          |
| 34  | Hosting model detail             | Engineering        | 🟢 Single Next.js process + local Redis sidecar per container; managed PG (separate DB per user); shared S3/R2 and external LLM API                                                                                     |
| 35  | Extension namespace publication  | Product            | 🟢 v1 internal spec; v2 publish TrustRequest/TrustGrant; v3+ Product, Audio/Video lwMetadata extensions                                                                                                                 |
| 36  | Server architecture              | Engineering        | 🟢 Consolidated single Next.js process — no separate microservices. AP engine, LLM client, API, and web shell in one process                                                                                            |
| 37  | Database hosting                 | Engineering        | 🟢 Managed PostgreSQL (e.g. Supabase) — separate database per user, connection pooling by provider                                                                                                                      |
| 38  | UI code sharing                  | Engineering        | 🟢 Solito + react-native-web — single shared UI across iOS, Android, and web. Minimal client JS for interactivity                                                                                                       |
| 39  | Relationship model               | Product            | 🟢 Native AS `Relationship` objects stored in SQL. Types: `lw:following`, `lw:friendOf`, `lw:closeFriendOf`. Independent — `lw:friendOf` does not imply `lw:following`. Permissions gated via boolean `any`/`all` rules |
| 40  | Follow policy (open accounts)    | Product            | 🟢 Auto-accept by default; configurable to `approval_required` via LLM                                                                                                                                                  |
| 41  | Controlled account relationships | Product            | 🟢 All relationship changes require controller approval by default; delegable per type via `trust.delegated_permissions`                                                                                                |
| 42  | Friend request mechanism         | Product            | 🟢 Uses `TrustRequest` with `requestedAction.type: "Create"` and `object.type: "Relationship"`. Consent required from target. Mutual relationship triggers chat upgrade                                                 |
| 43  | Streams (topic feeds)            | Product            | 🟢 Native AP `streams` property on Actor. Each stream is an `OrderedCollection` with `lwMetadata.displayHint: "feed"`. Managed via `Add`/`Remove` activities                                                            |

---

## 15. Roadmap

| Phase                                      | Timeline    | Deliverables                                                                                                          |
| ------------------------------------------ | ----------- | --------------------------------------------------------------------------------------------------------------------- |
| **Phase 0 — Foundation**                   | Weeks 1–3   | Monorepo, Next.js server scaffold, DB schema, Config Registry, WebFinger + Actor endpoints, Redis sidecar, Dockerfile |
| **Phase 1 — Core Federation**              | Weeks 4–8   | AP engine (inbox/outbox), Follow/Accept, HTTP Signatures, `Note`, `Article`, and `ChatMessage` types                  |
| **Phase 2 — Column Navigator + Input Bar** | Weeks 6–12  | Shared Solito UI, column navigator, focused card, input bar, SSO auth, 1-col mobile + 2-col tablet                    |
| **Phase 3 — Chat (1:1 + Group)**           | Weeks 8–14  | ChatMessage object, MLS encryption, WebSocket server, group host model, host migration, feed cards                    |
| **Phase 4 — Swipe + Content Creation**     | Weeks 10–15 | Symmetric swipe (context-dependent columns), content creation flow, draft cards, animations, minimal client JS        |
| **Phase 5 — LLM Client**                   | Weeks 12–16 | LLM client module, Claude integration, config read/write, action dispatch                                             |
| **Phase 6 — Circle of Trust**              | Weeks 14–18 | Controlled accounts, TrustRequest/TrustGrant, approval flow, config object permissions                                |
| **Phase 7 — Object Model + Reviews**       | Weeks 16–19 | LightwebObject base, extension manifest loader, native Like/Dislike/Note review mechanism                             |
| **Phase 8 — Lightweb Cloud**               | Weeks 17–21 | K8s deployment, container provisioning, per-user DB creation, managed PG setup, billing hooks                         |
| **Phase 9 — Polish & Launch**              | Weeks 21–26 | Performance, a11y, beta testing, app store submission                                                                 |
| **Post-v1**                                | TBD         | Video chat (SFU on host server), TrustRequest open standard, business trust                                           |

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
