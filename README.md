# nxm-memory

**nxm-memory** è un motore di memoria e ricerca locale per assistenti AI (agenti di coding). Indicizza un intero progetto sul tuo computer e lo rende interrogabile in linguaggio naturale, per codice e documenti, senza mandare nulla nel cloud. Espone i suoi strumenti tramite il protocollo **MCP (Model Context Protocol)**, quindi si collega ad agenti come Claude Code, Cursor, Kiro e simili. Tutto gira in locale: veloce, privato, sempre disponibile.

---

## 1. Installazione locale

Un solo comando. Rileva automaticamente il tuo sistema (macOS Apple Silicon o Linux x86_64), scarica il binario e lo installa in `~/.local/bin`:

```sh
curl -fsSL https://raw.githubusercontent.com/dangranaz/nxm-memory/main/install.sh | sh
```

Al **primo avvio**, il programma scarica automaticamente il modello di embedding (~200 MB) e la libreria ONNX Runtime necessaria. Non devi scaricare nient'altro manualmente.

Se `~/.local/bin` non è nel tuo `PATH`, aggiungilo:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Piattaforme supportate: **macOS arm64** (Apple Silicon) e **Linux x86_64**.

---

## 2. Come farlo funzionare

Avvia il server puntandolo alla cartella del tuo progetto (workspace). Alla partenza scansiona la cartella e ne costruisce l'indice:

```sh
nxm-mcp-server --w /percorso/del/tuo/progetto --port 7169
```

Il server resta in ascolto e tiene l'indice aggiornato automaticamente quando i file cambiano. Per fermarlo:

```sh
nxm-mcp-server --stop
```

### Escludere cartelle dall'indice con `.nxmignore`

Crea un file **`.nxmignore`** nella radice del progetto per dire a nxm-memory quali cartelle e file **non** indicizzare. La sintassi è quella di `.gitignore`. Questo è importante: senza esclusioni finirebbero nell'indice cartelle enormi e inutili (dipendenze, build, artefatti), rallentando tutto e sporcando i risultati di ricerca.

Esempio di `.nxmignore` consigliato:

```gitignore
# Dipendenze e pacchetti
node_modules/
vendor/
.venv/
venv/

# Output di build e artefatti
target/
dist/
build/
out/
*.min.js
*.min.css

# Version control e cache
.git/
.cache/
__pycache__/

# File di lock e binari
*.lock
*.log
```

Regole utili:
- una riga per pattern; `#` inizia un commento;
- una `/` finale (es. `build/`) esclude solo le cartelle;
- `!pattern` ri-include qualcosa escluso prima;
- la cartella dati `.nxm/` è **sempre** esclusa in automatico (l'indice non ingerisce mai il proprio stato).

### Collegarlo a un agente AI

Per usarlo dentro un agente (Claude Code, Cursor, Kiro…), si usa il trasporto `stdio`, con l'agente che gestisce il ciclo di vita del processo:

```sh
nxm-mcp-server --w /percorso/del/tuo/progetto --transport stdio
```

---

## 3. La tecnologia e la struttura della memoria (in parole semplici)

Immagina nxm-memory come **una memoria a lungo termine per il tuo assistente AI**, dedicata a un progetto.

Quando gli dai una cartella, la legge tutta e la scompone in piccoli pezzi ("chunk"). Di ogni pezzo conserva due cose: le **parole esatte** che contiene e il suo **significato**. Il significato viene catturato con un modello di embedding (una rete neurale che trasforma il testo in numeri, così che testi che vogliono dire cose simili risultino "vicini"). In questo modo puoi cercare sia una parola precisa, sia un concetto espresso con parole diverse da quelle nel codice.

La ricerca combina tre approcci — corrispondenza esatta, ricerca per parole chiave e ricerca per significato — e ne fonde i risultati per darti le risposte più pertinenti in cima.

La memoria è organizzata in **quattro tipi**, come funziona quella umana:

- **Semantica** — fatti, regole e preferenze stabili (es. "questo progetto usa Rust", "preferisco i test prima del codice").
- **Episodica** — eventi e sessioni: cosa è successo e quando.
- **Procedurale** — competenze e procedure: come si fa una certa cosa in questo progetto.
- **Prospettica** — attività da fare e promemoria futuri.

Tutto vive sul tuo computer, in una cartella `.nxm/` dentro il progetto. Niente lascia la tua macchina.

---

## 4. A cosa serve, cosa indicizza, e gli strumenti

### Scopo

nxm-memory dà a un assistente AI **memoria persistente e ricerca istantanea** su un progetto: ritrova la funzione giusta, il documento pertinente o la decisione presa settimane fa, senza dover ri-leggere tutto ogni volta. Crea e mantiene **l'indice** del progetto e risponde alle interrogazioni dell'agente.

### Cosa indicizza

Alla partenza (e a ogni modifica dei file) **crea l'indice** del workspace. L'indicizzazione è incrementale: rielabora solo i file effettivamente cambiati.

- **Codice**: Rust, Python, JavaScript/TypeScript (`.rs`, `.py`, `.js`, `.jsx`, `.ts`, `.tsx`), più `.sh`, `.sql`, `.proto`, `.graphql`, `.html`, `.css`.
- **Documenti**: Markdown (`.md`, `.mdx`), PDF, testo (`.txt`, `.rst`, `.adoc`).
- **Configurazioni**: `.toml`, `.yaml`/`.yml`, `.json`, `.ini`, `.cfg`.

Le cartelle elencate in `.nxmignore` vengono saltate (vedi sezione 2).

### Gli strumenti (tool MCP)

Il server espone questi strumenti all'agente AI:

| Strumento | A cosa serve |
|-----------|--------------|
| `index_workspace` | Indicizza o re-indicizza un workspace (full o incrementale automatico). |
| `index_search` | Ricerca ibrida (significato + parole chiave + fusione) su tutto l'indicizzato. |
| `search_code` | Cerca solo nei file di codice, con filtri per linguaggio e percorso. |
| `search_docs` | Cerca solo nei documenti (PDF, Markdown, TXT). |
| `search_exact` | Ricerca di sottostringa esatta, velocissima, senza embedding. |
| `search_regex` | Ricerca con espressioni regolari. |
| `get_chunk` | Recupera il contenuto completo di un pezzo tramite ID (caricamento on-demand). |
| `find_symbol` | Trova la definizione di un simbolo (funzione, struct, classe…). |
| `outline` | Elenca i simboli principali di un file. |
| `find_references` | Trova tutti gli utilizzi di un simbolo in un progetto. |
| `memory_remember` | Salva un fatto, un evento, una competenza o un'attività in memoria. |
| `memory_recall` | Cerca in memoria fatti, eventi e competenze pertinenti. |
| `context_compress` | Comprime testo (file, output shell, cronologia chat) per risparmiare token. |
| `context_budget` | Calcola l'allocazione ottimale del contesto per una data finestra. |
| `workspace_list` / `workspace_create` | Elenca / crea i workspace configurati. |
| `stats` | Statistiche dell'indice (file indicizzati, chunk, storage). |
| `watcher_status` | Stato del watcher automatico dei file. |

---

_Il codice sorgente è mantenuto privatamente. Questo repository distribuisce i binari e l'installer; il modello di embedding è distribuito separatamente e scaricato automaticamente al primo avvio._
