# Skill Definition — Abstract Specification

This document defines the abstract skill format. All concrete skills extend this specification. The LLM Engine reads this document and all applicable concrete skill files at request time to understand what actions are available and how to execute them.

Concrete skill files must implement each section as follows:

---

## 1. Purpose

Plain-language description of what this skill does. One to three sentences. The LLM uses this to match user intent to the correct skill.

## 2. Type

One of:

| Type       | Meaning                                            |
| ---------- | -------------------------------------------------- |
| `internal` | Config mutation — reads/writes the Config Registry |
| `external` | AP dispatch — produces an ActivityPub activity     |

## 3. Config ACL

Applicable to `internal` skills only. An explicit list of config paths this skill is allowed to read and write. The config write layer enforces this boundary in code — the LLM cannot override it.

```
- write: ['messaging.rcs.read_receipts']
- read:  ['messaging.rcs']
```

## 4. Parameters

Declared inputs to the skill. Every parameter specifies a name, type, and whether it is required or optional.

### Parameter declaration format

```
- <name>: <type> (<required|optional>) — <description>
    resolve: <resolver>
    default: <value>
    enum: [<value>, ...]
    min: <value>
    max: <value>
```

Only `name`, `type`, and `required|optional` are mandatory. All other fields are constraints that apply when relevant to the type.

### Type system

A closed set of parameter types. The LLM must resolve natural language input into one of these types at intent time.

| Type       | Format                          | Example                                  |
| ---------- | ------------------------------- | ---------------------------------------- |
| `string`   | UTF-8 text                      | `"Alice Chen"`                           |
| `number`   | Numeric value                   | `20`, `3.50`                             |
| `boolean`  | `true` or `false`               | `true`                                   |
| `enum`     | One of a declared set of values | `"chime"` from `[chime, alert, silent]`  |
| `actorUri` | Full ActivityPub actor URI      | `"https://bob.lightweb.cloud/users/bob"` |
| `objectId` | Full ActivityPub object ID      | `"https://alice.example/objects/abc123"` |

Additional types may be added as the system evolves. All types are primitives — no nested objects or arrays. If a skill needs multiple values of the same type, declare multiple parameters.

### Resolvers

Some types require the LLM to resolve a natural language reference into a canonical value. The `resolve` field tells the LLM which registry or lookup to use.

| Resolver  | Resolves from            | Produces   |
| --------- | ------------------------ | ---------- |
| `contact` | Contact registry aliases | `actorUri` |

The LLM must perform resolution at intent time and present the resolved value to the user for confirmation before dispatch.

### Example

```
- recipient: actorUri (required) — the contact to send money to
    resolve: contact
- amount: number (required) — dollar amount to transfer
    min: 0.01
    max: 100
- memo: string (optional) — message to include with the transfer
```

## 5. Behaviour

Step-by-step instructions the LLM follows when executing this skill. Written in plain language as a numbered list. Behaviour steps may reference parameters by name.

---

# Intent Resolution

When the user expresses intent (natural language input), the LLM:

1. **Matches** the input to a concrete skill by reading the Purpose of all available skills
2. **Extracts** parameter values from the input, resolving natural language references to their canonical typed values using declared resolvers
3. **Validates** that all required parameters are present and all values conform to their declared type and constraints
4. **Confirms** the resolved parameters with the user before proceeding unless the skill is being executed programatically.

The LLM will know that it is being called programatically when it is asked to execute this skill specifically by Skill ID (the filename) AND required parameters are provided in a json object string that when parsed, contains at least the required parameters.
