# nxm-memory

**nxm-memory** is a local memory and search engine for AI assistants. Although it works great for coding projects, it is not limited to code — it can index and search any collection of files: documentation, notes, research, contracts, knowledge bases, and more. It indexes an entire workspace on your own machine and makes it queryable in natural language, without sending anything to the cloud. It reads the documents in your workspace and gives you fast, relevant answers about them. It exposes its tools through the **Model Context Protocol (MCP)**, so it plugs into agents like Claude Code, Opencode, Pi, and others.

> [!IMPORTANT]
> **It is configured exactly like any other MCP server.** **Everything runs locally: fast, private, always available.**

---

## 1. Local installation

One command. It auto-detects your system (macOS Apple Silicon or Linux x86_64), downloads the binary, and installs it to `~/.local/bin`:

```sh
curl -fsSL https://raw.githubusercontent.com/dangranaz/nxm-memory/main/install.sh | sh
```

On **first run**, the program automatically downloads the embedding model (~200 MB) and the required ONNX Runtime library. There is nothing else to download by hand.

If `~/.local/bin` is not on your `PATH`, add it:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Supported platforms: **macOS arm64** (Apple Silicon) and **Linux x86_64**.

### Configure it in your agents, harnesses, and any MCP-compatible tool

nxm-memory is a standard MCP server, so you can configure it in your agents, your harnesses, and any tool that supports the MCP standard. Here is an example for **OpenCode** — add it to your `opencode.json` (global) or `opencode.jsonc` under the `mcp` key. Point `--w` at the project you want indexed:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "nxm-memory": {
      "type": "local",
      "command": ["nxm-mcp-server", "--w", "/path/to/your/project", "--transport", "stdio"],
      "enabled": true
    }
  }
}
```

The configuration follows the same pattern in other agents (Claude Code, Pi, Cursor, Kiro…): a local MCP server whose command is `nxm-mcp-server` with `--transport stdio`.

---

## 2. Getting it running

Start the server pointing it at your project folder (the workspace). On startup it scans the folder and builds its index:

```sh
nxm-mcp-server --w /path/to/your/project --port 7169
```

The server stays running and keeps the index up to date automatically as files change. To stop it:

```sh
nxm-mcp-server --stop
```

### Excluding folders from the index with `.nxmignore`

Create a **`.nxmignore`** file at the root of your project to tell nxm-memory which folders and files **not** to index. The syntax is the same as `.gitignore`. This matters: without exclusions, huge and useless folders (dependencies, build output, artifacts) would end up in the index, slowing everything down and polluting search results.

Recommended `.nxmignore` example:

```gitignore
# Dependencies and packages
node_modules/
vendor/
.venv/
venv/

# Build output and artifacts
target/
dist/
build/
out/
*.min.js
*.min.css

# Version control and caches
.git/
.cache/
__pycache__/

# Lock files and logs
*.lock
*.log
```

Useful rules:
- one pattern per line; `#` starts a comment;
- a trailing `/` (e.g. `build/`) matches directories only;
- `!pattern` re-includes something excluded earlier;
- the data folder `.nxm/` is **always** excluded automatically (the index never ingests its own state).

### Connecting it to an AI agent

To use it inside an agent (Claude Code, Cursor, Kiro…), use the `stdio` transport, with the agent managing the process lifecycle:

```sh
nxm-mcp-server --w /path/to/your/project --transport stdio
```

---

## 3. The technology and the memory model (in plain terms)

Think of nxm-memory as **long-term memory for your AI assistant**, dedicated to a project.

When you give it a folder, it reads everything and breaks it into small pieces ("chunks"). For each piece it stores two things: the **exact words** it contains and its **meaning**. Meaning is captured with an embedding model (a neural network that turns text into numbers, so that texts meaning similar things end up "close" together). This way you can search either for a precise word or for a concept expressed with words different from those in the code.

Search combines three approaches — exact match, keyword search, and meaning-based search — and blends their results to surface the most relevant answers at the top.

Memory is organized into **four types**, much like human memory:

- **Semantic** — stable facts, rules, and preferences (e.g. "this project uses Rust", "I prefer tests before code").
- **Episodic** — events and sessions: what happened and when.
- **Procedural** — skills and procedures: how a given thing is done in this project.
- **Prospective** — tasks to do and future reminders.

Everything lives on your computer, in a `.nxm/` folder inside the project. Nothing leaves your machine.

---

## 4. Purpose, what it indexes, and the tools

### Purpose

nxm-memory gives an AI assistant **persistent memory and instant search** over a project: it retrieves the right function, the relevant document, or the decision made weeks ago, without having to re-read everything each time. It builds and maintains **the index** of the project and answers the agent's queries.

### What it indexes

On startup (and whenever files change) it **builds the index** of the workspace. Indexing is incremental: only files that actually changed are reprocessed.

- **Code**: Rust, Python, JavaScript/TypeScript (`.rs`, `.py`, `.js`, `.jsx`, `.ts`, `.tsx`), plus `.sh`, `.sql`, `.proto`, `.graphql`, `.html`, `.css`.
- **Documents**: Markdown (`.md`, `.mdx`), PDF, plain text (`.txt`, `.rst`, `.adoc`).
- **Configuration**: `.toml`, `.yaml`/`.yml`, `.json`, `.ini`, `.cfg`.

Folders listed in `.nxmignore` are skipped (see section 2).

### The tools (MCP tools)

The server exposes these tools to the AI agent:

| Tool | What it does |
|------|--------------|
| `index_workspace` | Index or re-index a workspace (automatic full/incremental). |
| `index_search` | Hybrid search (meaning + keywords + fusion) across everything indexed. |
| `search_code` | Search code files only, with language and path filters. |
| `search_docs` | Search documents only (PDF, Markdown, TXT). |
| `search_exact` | Exact substring search, very fast, no embedding needed. |
| `search_regex` | Search with regular expressions. |
| `get_chunk` | Retrieve the full content of a chunk by ID (on-demand loading). |
| `find_symbol` | Find the definition of a symbol (function, struct, class…). |
| `outline` | List the top-level symbols of a file. |
| `find_references` | Find all uses of a symbol across a project. |
| `memory_remember` | Store a fact, event, skill, or task in memory. |
| `memory_recall` | Search memory for relevant facts, events, and skills. |
| `context_compress` | Compress text (file content, shell output, chat history) to save tokens. |
| `context_budget` | Compute the optimal context allocation for a given window. |
| `workspace_list` / `workspace_create` | List / create configured workspaces. |
| `stats` | Index statistics (files indexed, chunks, storage). |
| `watcher_status` | Status of the automatic file watcher. |

---

_The source code is maintained privately. This repository distributes the binaries and the installer; the embedding model is distributed separately and downloaded automatically on first run._
