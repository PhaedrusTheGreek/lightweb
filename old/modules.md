# Lightweb Browser — Module Map

## Modules

| Module | Doc | Owns |
|--------|-----|------|
| Overview | [00-overview.md](docs/00-overview.md) | Architecture, philosophy, tech stack |
| Client UI | [01-client-ui.md](docs/01-client-ui.md) | Feed, cards, input bar, panes |
| ActivityPub | [02-activitypub.md](docs/02-activitypub.md) | Federation, object model, encryption, transports |
| LLM Engine | [03-llm-engine.md](docs/03-llm-engine.md) | Intent resolution, config, trust, skills |

## How They Connect

```
                          External
                         Federation
                             │
┌──────────┐  REST/WS   ┌───▼───────────────────────────┐
│          │◄───────────►│  ActivityPub Engine            │
│  Client  │             │  - Object model & types        │
│  UI      │             │  - Federation (inbox/outbox)   │
│          │  REST       │  - Encryption layer (MLS)      │
│          │◄───────────►│  - Transport layer (HTTP/WS)   │
└──────────┘             └───▲───────────────────────────┘
      │                      │
      │ REST                 │ Action dispatch
      │                      │
      ▼                      │
┌────────────────────────────▼──┐
│  LLM Engine                   │
│  - Intent resolution          │
│  - Config registry            │
│  - Trust & permissions        │
│  - Action API (skills)        │
└───────────────────────────────┘
```

## Key Interfaces

- **Client → LLM Engine**: User input + context → interpreted intent + response
- **LLM Engine → AP Engine**: Named action dispatch (Follow, CreateNote, SendMessage, etc.)
- **AP Engine → External**: Federation protocol (HTTP Signatures, inbox POST)
- **AP Engine → Client**: Feed data, real-time delivery (WebSocket)
- **Encryption layer**: MLS wraps AP objects optionally, based on relationship state
- **Transport layer**: HTTP (async federation), WebSocket (real-time), WebRTC (future media)
