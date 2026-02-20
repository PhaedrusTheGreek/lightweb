# 01 — Client UI

## Purpose

Render the feed, cards, and content panes. Capture user input. The client has no business logic — it sends input to the server and renders what the server returns.

## Responsibilities

- Two-pane layout (feed + content)
- Card rendering by activity/object type
- Persistent input bar with context-aware mode switching
- WebSocket connection for real-time delivery
- Focus tracking (which card is active)
- Animations and transitions

## What It Does NOT Do

- No LLM calls (server-side only)
- No config access (never sees the registry)
- No AP federation (no direct inbox/outbox access)
- No encryption/decryption (handled before delivery)

## Layout

```
MOBILE (single pane)             TABLET / WEB (side-by-side)

┌──────────────────────┐         ┌───────────┬──────────────────┐
│  HOME FEED           │         │ HOME FEED │ CONTENT          │
│                      │         │           │                  │
│  [Card A]            │         │ [Card A]  │ (detail view of  │
│ ╔════════════╗       │         │╔═════════╗│  tapped card)    │
│ ║[Card B]    ║ focus │  tap    │║[Card B] ║│                  │
│ ╚════════════╝       │ ──────▶ │╚═════════╝│ [Message 1]      │
│  [Card C]            │         │ [Card C]  │ [Message 2]      │
│                      │         │           │ [Message 3]      │
├──────────────────────┤         ├───────────┼──────────────────┤
│  [Ask anything…    ] │         │[Ask…    ] │ [Type a message] │
└──────────────────────┘         └───────────┴──────────────────┘
```

On mobile, tapping a card replaces the feed full-screen with the content view. A back gesture (swipe-back or system back button) returns to the feed. On tablet/web, the content pane updates in place — the feed remains visible and scrollable alongside it.

## Input Bar Modes

The input bar mode is determined by what's in the active pane:

| Active pane         | Mode   | Behaviour                               |
| ------------------- | ------ | --------------------------------------- |
| Feed (card focused) | LLM    | Input + card context sent to LLM engine |
| Feed (no focus)     | LLM    | Input sent as general request           |
| Chat thread         | Direct | Keystrokes sent as message              |
| Draft / compose     | Direct | Keystrokes compose content              |

Mode changes only when pane content or focus changes. No toggle, no button.

## Interfaces

### LLM Engine

See [LLM Engine Interface](02-llm-engine.md#interfaces)

### Direct to AP Engine

"Direct" mode used in some contexts (chat threads, new posts, replies, comments). Same `ActionDispatch` shape the LLM Engine uses — the AP Engine handles it identically regardless of caller.

See [AP Engine Interface](03-activitypub.md#interfaces)

## Card Model

Every feed item is a card in the UI. The card type determines how it renders and what tapping it opens:

| Card source            | Tap opens            |
| ---------------------- | -------------------- |
| Note / Article         | Full content         |
| ChatMessage            | Chat thread          |
| Follow notification    | Actor's feed         |
| Friend request (Offer) | Relationship context |
| Stream                 | Topic feed           |

## Dependencies

- **AP Engine**: feed data, real-time delivery, message send
- **LLM Engine**: input interpretation, action results
