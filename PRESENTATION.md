# nxm-memory

### Persistent memory and instant retrieval for local AI agents — private, offline, cross-platform.

> Give any local AI agent a memory that lasts and a search that understands —
> fully offline, multilingual, and fast enough to index tens of gigabytes of code
> and documents. Runs on macOS (Apple Silicon) and Linux, with nothing leaving
> your machine.

---

## The problem

Large language models forget everything the moment a conversation ends, and they
can only reason over what fits in their context window. For agents working on real
codebases and document sets, that is the wall: no lasting memory, and no way to
pull the *right* few thousand tokens out of millions.

The usual answer — ship your data to a cloud vector service — trades away privacy,
adds latency, and stops working the moment you go offline.

**nxm-memory removes that trade-off.** It gives a local agent durable memory and
high-quality semantic search, entirely on-device, with no network, no API keys,
and no data leaving the machine.

---

## What it does

- **Remembers.** Persistent, structured memory across sessions — facts, past
  events, learned procedures, and future tasks — inspired by how cognitive agents
  organize knowledge.
- **Understands.** Semantic search over code and documents that finds meaning, not
  just keywords — and works *across languages*: ask in Italian, find the answer in
  English.
- **Scales.** Indexes entire codebases and document libraries — tested on
  workspaces of tens of gigabytes, hundreds of thousands of files — and keeps them
  current automatically as files change.
- **Connects.** Speaks the Model Context Protocol, so it plugs into a wide range
  of AI agents, harnesses, and any MCP-compatible tool — several of them at once.
- **Saves tokens.** A built-in context-compression engine shrinks file contents,
  shell output, and chat history before they reach the model — cutting token usage
  (and cost) while preserving errors and the important parts. One of its most
  valuable features for keeping long agent sessions inside the context window.

---

## The technology, at a glance

nxm-memory is a single, self-contained engine that runs entirely on your machine —
no external services, no cloud dependencies.

| Layer | What powers it |
|-------|----------------|
| **Understanding** | A state-of-the-art multilingual embedding model (100+ languages, code + prose) running locally via **ONNX Runtime** — portable across platforms |
| **Search** | Hybrid retrieval: exact match, keyword (BM25), and semantic vector search, fused for relevance — fully on-device |
| **Memory** | A multi-type long-term memory model that separates facts, episodes, skills, and goals |
| **Integration** | A Model Context Protocol server that any compatible agent, harness, or tool can talk to |
| **Storage** | An embedded vector database kept continuously up to date in the background |
| **Footprint** | Pure on-device, no cloud — the model and runtime are downloaded automatically on first run |

The design principle is **lexical-first**: a fast keyword + trigram index makes a
workspace searchable within minutes, while neural (semantic) embedding runs in the
background — so you never wait on a full-corpus embed before search is useful.

> On macOS with Apple Silicon, an optional build can additionally offload query
> embedding to the **Apple Neural Engine** for lower latency. This is opt-in; the
> default build is platform-agnostic and identical on macOS arm64 and Linux x86_64.

---

## Why it matters — the advantages

- **Private by design.** Nothing leaves your machine. No cloud, no API keys, no
  telemetry. Ideal for proprietary code and confidential documents.
- **Cross-platform.** One agnostic build for **macOS arm64** and **Linux x86_64**,
  with identical behavior.
- **Truly multilingual.** One shared understanding space across 100+ languages —
  a question in one language retrieves knowledge written in another.
- **Fast where it counts.** Keyword and exact search return in milliseconds;
  semantic search runs against a continuously maintained vector index.
- **Always current.** nxm-memory stays running in the background and updates the
  index automatically as your files change — every added or modified file is
  picked up and re-indexed.
- **Open to your tools.** A shared server lets multiple AI agents query the same
  memory simultaneously.

---

## Install

One command — auto-detects your platform, installs the binary, and the model is
downloaded automatically on first run:

```sh
curl -fsSL https://raw.githubusercontent.com/dangranaz/nxm-memory/main/install.sh | sh
```

Supported platforms: **macOS arm64** (Apple Silicon) and **Linux x86_64**.

---

## Built for AI agents

nxm-memory exposes its capabilities through the Model Context Protocol, the
emerging standard for connecting AI assistants to external tools. It is configured
exactly like any other MCP server. A single shared server can serve **many agents
at once**, each able to search code, search documents, recall memory, and store
new knowledge — all against the same always-current index.

---

## The bottom line

nxm-memory is a serious, private, high-quality retrieval and memory system for
local AI — fast, multilingual, offline, and cross-platform. It runs on the
hardware you already have, and your data never leaves it.

*Private memory for local AI.*
