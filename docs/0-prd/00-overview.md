# 00 — Overview

## What Is Lightweb Browser

A federated social and business media/communications platform built on ActivityPub. Multiple users per server. Every interaction flows through a single input bar — the LLM interprets intent, the system executes it.

### Mission Statement

To provide a simple and well-defined structure for communications which is conducive to accessibility mechanisms such as voice control and AR. Such structure not only relieves interface friction, but is inherently more secure and well integrated. To provide an internet safe for kids, safe for everyone.

### Problem Statement

Mainstream social media platforms are centralized, opaque, and buried in buttons, menus, and configuration screens. And no social platform today provides a principled, interoperable model for secure non-technical use of the internet.

_Sending_ data through web browsers and most apps is uncontrolled and insecure.

### Vision

To lock down browser PUT/POST capability, effectively making it read only, by designing a new alternate simple & secure platform.

## Design Principles

**No Buttons.** All user intent is expressed as natural language or gesture through a single persistent input bar. Configuration is the system's problem, never the user's.

**Layout is User-Controlled.** The screen never changes without an explicit user gesture. No auto-rearranging, no popups, no focus-stealing.

**Allowlist, Never Deny.** Nothing is permitted until explicitly granted. Permissions evolve over time through structured relationships.

**Trust is Structured.** Relationships between actors gate capabilities. The same model governs friends, family, colleagues, and communities.

## Architecture

Three server processes per instance. Each module is its own process, serving all users on the server. Per-user state is namespaced at every layer.

```
┌──────────────────────────────────────────────────────────┐
│  Server Instance                                         │
│                                                          │
│  ┌──────────────────────────────────┐                    │
│  │  Client Server (Next.js)         │                    │
│  │  SSR + hydration + proxy         │                    │
│  └───────┬──────────────┬───────────┘                    │
│          │ REST         │ REST/WS                        │
│  ┌───────▼──────────┐   │                                │
│  │  LLM Engine      │   │                                │
│  │  (Fastify)       │   │                                │
│  │  Per-user config │   │                                │
│  │  & tool defs     │   │                                │
│  │  ~/config            │                                │
│  └───────┬──────────┘   │                                │
│          │ Action       │                                │
│          │ dispatch     │                                │
│          └───────┬──────┘                                │
│                  │                                       │
│  ┌───────────────▼──────────────────┐                    │
│  │  ActivityPub Engine (Fastify)    │◄── External        │
│  │  Federation, objects, encryption,│    Federation      │
│  │  transports, WebSocket           │                    │
│  └───────┬──────────────────────────┘                    │
│          │                                               │
│  Redis (key-prefixed per user, ACL-enforced)             │
└──────────┬───────────────────────────────────────────────┘
           │
┌──────────▼───────────────────────────────────┐
│  Shared Infrastructure                       │
│  ├── PostgreSQL (separate DB per user)       │
│  ├── S3/R2 (shared media storage)            │
│  └── External LLM API (Claude, swappable)    │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│  Per-User Home Directories (/home/<user>/)   │
│  ├── config/registry.json                    │
│  └── keys/                                   │
└──────────────────────────────────────────────┘
```

## Tech Stack

| Layer             | Technology                    |
| ----------------- | ----------------------------- |
| Mobile            | React Native (Expo)           |
| Client Server     | Next.js 14+ (App Router)      |
| LLM Engine        | Fastify                       |
| AP Engine         | Fastify                       |
| Shared UI         | Solito + react-native-web     |
| Language          | TypeScript                    |
| LLM Integration   | Vercel AI SDK                 |
| LLM Provider      | Claude (swappable via config) |
| Database          | PostgreSQL (per user)         |
| Cache / Real-time | Redis (local sidecar)         |
| Media Storage     | S3/R2                         |
| Monorepo          | Turborepo                     |
| Deployment        | Docker + Kubernetes           |

## Provider Abstractions

All external dependencies implement pluggable interfaces configured via the Config Registry. Switching providers requires only a config change and restart.

| Provider     | Interface                                                 | Implementations        |
| ------------ | --------------------------------------------------------- | ---------------------- |
| LLM          | Vercel AI SDK `generateText(model, tools, prompt)`        | Claude, OpenAI, Gemini |
| Database     | `query(sql, params)`, `transaction(fn)`                   | PostgreSQL             |
| Cache/Stream | `cache.get/set/mget/invalidate`, `stream.append/read/ack` | Redis                  |

## Multi-User Namespacing

Multiple users share a single server instance. Identity follows standard ActivityPub convention: `@alice@lightweb.cloud`. Isolation is enforced at every layer through namespacing.

### Scale Target

A single server instance is designed to serve hundreds to low thousands of users — not tens of thousands, not millions. Design decisions should be rooted in this level of scale. The goal is true decentralization in numbers: many small servers across many organizations, not a handful of mega-instances implementing a federated protocol in name only.

### Linux Users

Each Lightweb user is a native Linux user. Personal state lives in the user's home directory:

```
/home/alice/
├── config/registry.json    # User config (LLM Engine owned)
├── skills/                 # User skill definitions
└── keys/                   # MLS keypairs, signing keys
```

OS-level file permissions provide isolation — no application-level access control needed for the filesystem layer.

### PostgreSQL

Separate database per user (e.g. `lightweb_alice`, `lightweb_bob`). Connection routing based on authenticated user.

### Redis

Key prefixing per user (`alice:feed:cache`, `alice:session:xyz`). Redis ACLs restrict each user to their own key pattern (`alice:*`). Pub/sub channels are also prefixed (`alice:events`, `alice:presence`). This approach works with Redis Cluster and scales horizontally.

## Protocol Layers

All communication — social posts, RCS chat, and video chat — flows through the same layered architecture:

```
┌─────────────────────────────────┐
│  ActivityPub                    │  Addressing, activities, objects
│  (all messages are AP objects)  │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│  Encryption (MLS)               │  Optional per object type
│  (wraps payload when            │  Based on relationship state
│   relationship state requires)  │  and type manifest
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│  Transport                      │
│  ├── HTTP POST (federation)     │  Async delivery
│  ├── WebSocket (real-time)      │  Chat, presence, typing
│  └── WebRTC (future)            │  Voice/video media streams
└─────────────────────────────────┘
```

This is not three separate systems. It is one AP system with optional E2EE and pluggable transport.
