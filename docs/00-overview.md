# 00 — Overview

## What Is Lightweb Browser

A federated social and business media/communications platform built on ActivityPub. One user per server. Every interaction flows through a single input bar — the LLM interprets intent, the system executes it.

### Mission Statement

To provide a simple and well-defined structure for communications which is conducive to accessibility mechanisms such as voice control and AR. Such structure not only relieves interface friction, but is inherently more secure and well integrated. To provide an internet safe for kids, safe for everyone.

### Problem Statement

Mainstream social media platforms are centralized, opaque, and buried in buttons, menus, and configuration screens. And no social platform today provides a principled, interoperable model for secure non-technical use of the internet.

_Sending_ data through web browsers and most apps is uncontrolled and insecure.

### Vision

To lock down browser PUT/POST capability, effectively making it read only, by designing a new alternate simple & secure social & business media / communciations browser interface.

## Design Principles

**No Buttons.** All user intent is expressed as natural language or gesture through a single persistent input bar. Configuration is the system's problem, never the user's.

**Layout is User-Controlled.** The screen never changes without an explicit user gesture. No auto-rearranging, no popups, no focus-stealing.

**Allowlist, Never Deny.** Nothing is permitted until explicitly granted. Permissions evolve over time through structured relationships.

**Trust is Structured.** Relationships between actors gate capabilities. The same model governs friends, family, colleagues, and communities.

## Architecture

Three servers per user container. Each module is its own process.

```
┌──────────────────────────────────────────────────────────┐
│  Per-User Container                                      │
│                                                          │
│  ┌──────────────────────────────────┐                    │
│  │  Client Server (Next.js)         │                    │
│  │  SSR + hydration + proxy         │                    │
│  └───────┬──────────────┬───────────┘                    │
│          │ REST         │ REST/WS                        │
│  ┌───────▼──────────┐   │                                │
│  │  LLM Engine      │   │                                │
│  │  (Fastify)       │   │                                │
│  │  Config Registry │   │                                │
│  │  Skills          │   │                                │
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
│  Redis (local sidecar for cache, state)                  │
└──────────┬───────────────────────────────────────────────┘
           │
┌──────────▼───────────────────────────────────┐
│  Shared Infrastructure                       │
│  ├── PostgreSQL (separate DB per user)       │
│  ├── S3/R2 (shared media storage)            │
│  └── External LLM API (Claude, swappable)    │
└──────────────────────────────────────────────┘
```

## Tech Stack

| Layer             | Technology                    |
| ----------------- | ----------------------------- |
| Mobile            | React Native (Expo)           |
| Web + Server      | Next.js 14+ (App Router)      |
| Shared UI         | Solito + react-native-web     |
| Language          | TypeScript                    |
| Database          | PostgreSQL (per user)         |
| Cache / Real-time | Redis (local sidecar)         |
| Media Storage     | S3/R2                         |
| LLM               | Claude (swappable via config) |
| Monorepo          | Turborepo                     |
| Container         | Docker + Kubernetes           |

## Provider Abstractions

All external dependencies implement pluggable interfaces configured via the Config Registry. Switching providers requires only a config change and restart.

| Provider    | Interface                               | Implementations          |
| ----------- | --------------------------------------- | ------------------------ |
| LLM         | `complete(systemPrompt, messages)`      | Claude, OpenAI, Gemini   |
| Database    | `query(sql, params)`, `transaction(fn)` | PostgreSQL, SQLite (dev) |
| Queue/Cache | `publish`, `subscribe`, `cache.get/set` | Redis, in-memory (dev)   |

## Single-User-Per-Server

Every user gets a dedicated container with their own domain. Domain = identity (`@alice@alice.lightweb.cloud`). This gives security isolation, resource isolation, and eliminates multi-tenancy complexity.

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
