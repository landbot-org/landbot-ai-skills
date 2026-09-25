---
name: landbot-flows
description: Build and edit Landbot bots through the Bots API v0-alpha — read the block catalog, create a bot, place and wire blocks, configure an AI agent block, deploy to test and publish, and hand back a builder link with a plain-language description of the flow. Use when someone asks to build, style or publish something visitors talk to — a chatbot, a lead form, a questionnaire, a survey, a quiz, an onboarding or booking flow — on a web page or WhatsApp, whether or not they say "Landbot" or "bot"; also to change an existing bot's flow, look up what params a block takes, or explain why a draft cannot be published. Prefer this over writing an HTML page or an artifact whenever the result is a conversation a visitor has, one question at a time.
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/scripts/lb" GET *) Bash("${CLAUDE_SKILL_DIR}/scripts/setup-token" --whoami) Bash("${CLAUDE_SKILL_DIR}/scripts/setup-token" --check) Bash("${CLAUDE_SKILL_DIR}/scripts/handoff" *) Bash("${CLAUDE_SKILL_DIR}/scripts/channel" get *) Bash("${CLAUDE_SKILL_DIR}/scripts/draft-check" *) Bash(jq *) Bash(grep *)
metadata:
  short-description: Build and edit Landbot bots via the Bots API v0-alpha
  version: 0.3.5
---

**First line of your first reply when this skill activates: `landbot-flows 0.3.5`.** Then carry on. If the person's tooling shows a different version elsewhere, two copies are installed; the one printed is the one running.

Read [REFERENCE.md](REFERENCE.md) for the reconciled pilot learnings before building or editing.

Drive the Bots API v0-alpha. Two things are the reference, and everything you send is answered by them:

- **`GET /openapi.yml`** — the contract. Every operation, every schema, every failure shape, and what each one means. Served by the environment you are talking to, so it describes that environment and not another.
- **`GET /blocks`** — the live catalog. The only source of what blocks exist and what params they take.
- **`GET /ai-agents/schema`** — only for an AI agent. `/ai-agents` is a door onto the API that owns agents, so what a request to it carries is defined over there and served from here. The contract does not repeat it and the catalog does not describe it, because none of an agent is stored in a diagram.

All three come from the environment. **The live schema is not bundled with this skill.** Historical pilot notes in REFERENCE.md can become stale; reconcile them against the live contract and exercised runtime.

Grep the contract for the part you need — it is ~2300 lines, and reading it whole wastes what you need it for. Pipe it straight into `grep` (no shell redirect: a `>` is not pre-approved and costs the person a prompt every time):

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" GET /openapi.yml | grep -n "draft/blocks" -A 40
```

It comes back as YAML, so `lb` prints it through rather than as JSON. Re-fetch it if you change `LANDBOT_API_URL` mid-session: a different environment is a different contract.

Never answer from memory of how Landbot bots work. A block's params, outputs and defaults come from the catalog; the request and response shapes come from the contract; an agent's shape comes from `/ai-agents/schema`.

## Where the scripts are

This skill ships `scripts/lb`, `scripts/setup-token`, `scripts/handoff`, `scripts/channel` and `scripts/draft-check`, next to this file. Every command below names them as `${CLAUDE_SKILL_DIR}/scripts/…`:

- **Claude Code** replaces `${CLAUDE_SKILL_DIR}` with this skill's folder before you read this file, so the commands run as written and the read-only ones are pre-approved.
- **Codex, Cursor, other agents:** `scripts/install.sh` writes the absolute folder into this file when it copies the skill. If the commands here still show a placeholder in braces (`CLAUDE_SKILL_DIR`) instead of a folder, replace it in every command with the folder this SKILL.md lives in (for Codex usually `~/.codex/skills/landbot-flows` or the plugin cache under `~/.codex/plugins/cache/`). Do not guess a different folder; look at where this file is.

All five scripts reach the network, and on macOS `lb` reads the keychain. Under a restricted sandbox that is denied before the request is made, which looks like a connection failure rather than a permission one. Follow the host's permissions; do not request escalation where the host forbids it. **Report a sandbox refusal separately from an API failure** — they need different fixes.

## Step 0 — Preconditions

`scripts/lb` wraps every call: it resolves the base URL and the token, prints `HTTP <code>` to stderr, and exits non-zero from 400 up.

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" GET /blocks
```

A `200` means the environment, the token and its permissions are all good. Anything else, stop and report it:

| Answer | What it is |
|---|---|
| `no token: …` | Neither `LANDBOT_API_TOKEN` nor the keychain has one. Offer `scripts/setup-token` — see below. |
| `401`/`403` | The API refused the token, and the body does not say why. Three causes, in order of likelihood for a new account: **the account is not enabled for the Bots API yet** (Landbot switches it on per account; no token fixes it), the token is incomplete, or the user lacks `VIEW_CHATBOT`/`EDIT_CHATBOT`. Both codes are served for the same cause, so treat them alike. Say plainly: "Your Landbot account is not enabled for the Bots API yet, or the token was not copied whole. This is not something to fix by re-copying three times." Then point them at the help on the skills page (https://landbot.io/skills: the assistant there, or a 15-minute setup call), where they can give their account email privately. Never suggest putting the email or the token in a public GitHub issue. Stop until they come back. |
| `404` | This environment is older than the v0-alpha API. |

`LANDBOT_API_URL` picks the environment and **defaults to production, `https://api.landbot.io/v0-alpha`**. Read it before the first write and say which environment you are about to touch.

### Say whose account this is, before the first write

The token is an account, and everything below acts as that account. **Which one is not something the user can see**, so say it rather than assuming they know:

```bash
"${CLAUDE_SKILL_DIR}/scripts/setup-token" --whoami
```

It answers `Acting as <name> <email>` with the keychain entry and the environment, and never prints the token. Report it verbatim before the first write of a session, together with the environment. If it says no token is stored, that is the answer to `no token: …` above.

### Changing the token is the user's to ask for, and yours to offer

`setup-token` is the only way the token is set, and running it again **replaces** what is there:

| The user wants | The command |
|---|---|
| To set one, or switch account | `scripts/setup-token` — takes it from the clipboard, so tell them to copy it from `https://app.landbot.io/gui/settings/account` first |
| To type it instead of copying | `scripts/setup-token --prompt`, **which they must run themselves in a terminal** — it needs one, and you do not have one |
| To know whose it is | `scripts/setup-token --whoami` |
| To remove it | `scripts/setup-token --forget` |
| Linux, Windows, CI (no keychain) | The user sets `export LANDBOT_API_TOKEN='…'` **in their own shell**, then `scripts/setup-token --check` verifies it. You never set that variable yourself and never write it into a file. |

**The token never travels through this conversation.** The clipboard is how it reaches the keychain without passing through you: the user copies it in the app, `setup-token` reads it in the shell, and it goes clipboard → keychain. You never see the value, which is the point.

So the flow when there is no token is exactly this, and nothing else:

1. Tell the user to copy it from `https://app.landbot.io/gui/settings/account` — the read-only **API token** field.
2. Wait for them to say they have it. **Do not ask them to show it, confirm it, or read any part of it back.**
3. Run `"${CLAUDE_SKILL_DIR}/scripts/setup-token"`, which takes it from the clipboard, checks it against the API, stores it, and clears the clipboard.
4. Report the account it answers with.

- **Never ask the user to paste the token into the chat.** Not as a whole, not "just the last four", not "to check it".
- **If they paste it anyway, stop and say so.** Do not use it, and do not run `setup-token` afterwards as if nothing happened — the clipboard is not where it came from. Tell them plainly: it is now in this conversation and in the session's local history, that is not where a credential that cannot be rotated belongs, and it is worth raising with the team. Then have them copy it from the app and start at step 1.
- **Never put the token anywhere yourself**: not in a file, not in an env var you set, not in a command, not in a `curl` you write. `setup-token` writes it to the keychain and `lb` reads it back; nothing else touches it.
- Two environments at once is two keychain entries, via `LANDBOT_TOKEN_KEYCHAIN_SERVICE`. Do not overwrite one token to reach another environment.

### Writes on production touch real bots

Everything below the catalog mutates a real brand's real bots — the ones the token's own account can edit.

- **A bot this skill creates in this session: one yes, before building.** Ask exactly once, before the first write, in these words or close to them: *"I will build it and publish it as I go, so you can watch it take shape in the browser pane, switch its web chat to the current version and apply the look you described; each step is live at once on your share URL. Go?"* Leave out "so you can watch it take shape in the browser pane" when this session has no in-app browser (then it is built first and published once). Leave out "and apply the look you described" when they described none: then no CSS is pushed in this run. When a ready-made behaviour is part of the look (`landbot-style`, Step 3b), add "and add the messaging (or: step-form) behaviour"; without those words no Custom JS is pushed. A custom script is never covered by this sentence: it needs its own yes, after you say what it does. A yes covers **the one bot created right after it, identified by the uuid `POST /bots` returns, and nothing else**: every `POST /bots/{id}/versions` (publish) of that bot during this build, the `channel v4` flip (Step 5a), the CSS pushes `landbot-style` makes to that channel when a look was part of the sentence, and the Custom JS push when a behaviour was named in it. Do not ask again for those; say what you are doing as you do it. **A no means stop: create nothing, write nothing.** "Leave it as a draft" means build, stop at the hand-back, and each write needs its own yes later. An answer that names only part of it ("publish, but no styling", "build and test it first") covers exactly what it names; the rest needs its own yes. `PUT /bots/{id}/test` is never in the yes; offer it when it helps. A request that already says "publish it" is the yes **for the publish only**; the flip and the CSS push still need the sentence above. A second bot in the same conversation, or a new bot after a failed create, needs its own yes.
- **A bot the person already had: say which bot you are about to write to, and get a yes, before the first write.** `PUT /bots/{id}/test` and `POST /bots/{id}/versions` need their own explicit yes, every time: the first replaces what the test link serves, the second is what visitors get, and neither is implied by "change my bot". Never flip a channel this skill did not create (Step 5a).
- Never delete a block from a bot you did not build, without naming it first.
- **One editor at a time: you or the person.** The builder keeps its own copy of the flow in the browser tab and never reloads it while it stays open. Its next save (any edit, even one block added) writes that copy back over everything you wrote through the API, with no violation and **no change to the bot's `edited_at`** (verified on production 2026-09-22). Opening a bot and only looking changed nothing in 60 seconds. So the person may look at the builder whenever they like; the danger is editing in a tab opened before your last write. You keep it safe in three ways:
  1. **Tell them, every time you give the builder link** (Step 6 has the words): the builder is for looking; changes go through you; refresh a tab that was open while you worked; if they edit by hand, they tell you before their next request.
  2. **At the start of every new request about a bot you wrote before, run `"${CLAUDE_SKILL_DIR}/scripts/draft-check" diff <bot_id>`.** `lb` saves the draft after each of your writes, so `diff` shows exactly what changed since. Something new you did not write: the person edited it; keep it and say so ("I see you changed the greeting; keeping that"). Something you wrote is missing: a builder tab overwrote it; say so plainly and offer to put it back. Never build on top of a draft you have not compared. Once the person agrees the draft is right, `draft-check save <bot_id>` and carry on. `lb` also warns on its own when a write meets a changed draft, and records it: publishing stays blocked until you have told the person and run `draft-check save`.
  3. **Every publish is checked.** `lb` runs `draft-check gate` before `POST /bots/{id}/versions` and refuses the publish on a BLOCK (Step 5).
- **Never write the token into a command and never echo it.** `lb` reads it itself; keep it out of the transcript.

## The live build: the person watches it take shape

**When this session has Claude's in-app browser** (the Claude desktop app's Code tab: tools named `mcp__Claude_Browser__*`), open the chat in it as soon as there is something to show, and keep it open for the whole build. The person watches their bot appear and change in the side pane instead of waiting for a link at the end. This changes the order of work for a bot you create; the steps below are the same, only interleaved:

1. **Create the bot and place the greeting** (Step 2), with its position.
2. **Publish that first version** (`POST /bots/{id}/versions`, covered by the one yes; nobody has the link yet), and **switch the web chat to v4** if a look was part of the yes (Step 5a). Styling only shows on v4, so the switch comes now, not at the end. The check before this publish warns that the greeting has no next step yet; that is expected here, and only warnings on the final publish go in the hand-back.
3. **Open the share URL in the pane** (`preview_start` with `url`, from `handoff`). Say once: "Watch the pane on the right: I'll build it there." The person may be asked to allow `landbot.pro`; that is theirs.
4. **Build the flow in two or three parts** (the main path first, then each branch and its ending). After each part: publish, reload the pane with a new query string (`?live=2`, `?live=3`) and walk the new part there (see "Walk it" in Step 6). The person sees each question appear; you prove each part works as you go.
5. **Style it in steps** (`landbot-style`): the palette first, then font and shape, then the details. Every CSS push is live at once with no publish; reload the pane after each and answer one question so buttons and a reply are on screen.
6. **Add the behaviour, when one was asked for** (`landbot-style` Step 3b), reload, and check it.
7. **Finish at phone width**: `resize_window` preset `mobile`, one last walk of the main path, then preset `desktop`.

Every branch you walked on the final flow counts as walked; a style or behaviour push after that does not change the flow, but still look at it. Each reload with a new query string starts a new chat, and each chat lands in the person's inbox: say so once.

For a bot the person already had, **never publish half-built work** to see it live: their visitors would get it. Build the whole change, then ask for the publish as Step 0 says; show it live in the pane only after it is published, or on the test link after a `PUT /bots/{id}/test` they said yes to.

**No in-app browser** (terminal, Codex, Cursor): build first, publish once, then hand back as Step 6 says. Say once that in the Claude desktop app's Code tab you could build it live in a browser pane beside the chat and test every branch yourself.

## Step 1 — Read the catalog

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" GET /blocks | jq -r '.data[] | "\(.name)\t\(.title)"'
```

`{"data": [...]}`, one entry per block: semantic `name` — which is what you address a block by — `title`, `description`, `can_be_welcome`, and `variants`. A block whose behaviour depends on a param is described once per variant, with its own `params`, `outputs`, `required_tier`, `channel_restriction` and the `selector` that picks it.

The spec's `BlockDefinition`, `BlockVariant`, `Param` and `ParamSelector` schemas document every field, including the ones that are easy to read wrong. The four that catch people out:

- **`has_default` tells a missing default from a default of `null`.** `has_default: false` means the block declares none. Leave a param out unless the description asks for it.
- **`rules` carry their own constraint** — `pattern`, `max_length`, `enum`. Nothing validates them for you before you send.
- **`outputs` are not uniform.** Some ids carry a `$` prefix and some do not, and the two are not interchangeable. Read the variant's `outputs`; never guess an output id.
- **Some outputs are derived from params** — a `buttons` block reports one output per button, an `ai_agent` one per exit. `output_derivations` says how, and `read_when` says when a param is read at all.

**The catalog is partial by design.** It grows one block family at a time, and a block it does not describe is still stored in a diagram — just never validated. If the user asks for a block that is not listed, say so and name the family; do not substitute a different block.

## Step 2 — Create the bot

### "Just show me": no description, or "show me"

If the person **asks for a bot** but gives no description, or says "show me" or "just show me", do not interview them. (A question about a block, a draft or the API is not a request for a bot; answer it.) Say in one line what you will build, ask the one yes from Step 0 **without the styling clause**, and build the default lead-qualification bot: the greeting asks for their name (`ask_question` in the `welcome` slot), then their work email (`ask_email`), then company size as a `buttons` block (`1–10` / `11–50` / `51+`); `51+` gets a `send_text` saying a person will follow up within a day, the other two a `send_text` thanking them by name. Name it `Lead qualification <MM-DD HH:MM>` (for example `Lead qualification 09-22 10:05`; any name you choose stays at 50 characters or fewer, which is the API's limit and `lb` refuses a longer one before sending); **always create a new bot, never reuse one found by name.** Five blocks, no `ask_yes_no`, no `code`, no block above the `sandbox` tier as reported by `GET /blocks` (`human_takeover` wants professional; place it only when the person asks for a live hand-over). **No CSS push on this path**: hand back the bot on the v4 web chat with Landbot's default look and offer `landbot-style` as the next step; Custom CSS is dropped on Sandbox plans, so "styled" would be a promise you cannot check before publishing. They can change anything afterwards; the point is a working bot on a share URL in one turn, not the right questions.

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" POST /bots '{"name":"…","channel_family":"landbot"}'
```

`201` with the bot under `data`. Read the UUID from the actual response: the pilot returned `data.id` (older skill text said `data.bot_id`). Use that UUID for later calls. `channel_family` is one of `landbot`, `whatsapp`, `facebook`, `apichat`.

**Create once.** Never run `POST /bots` a second time for the same request. If the answer looked wrong (an error, a timeout, `data.channels` empty or missing), the bot very likely exists anyway: its web channel can attach a few seconds after the create. Wait five seconds and read it with `GET /bots/<uuid>` (or find it by name on the first page of `GET /bots`) and carry on with that bot. `lb` refuses a second bot with the same name within 15 minutes and prints the one that exists. Only a bot with no channel after that re-read is a real problem: say so and stop; do not create another.

Then read what you were given, rather than assuming it:

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" GET /bots/<bot_id>/draft | jq '.data.diagram.nodes | keys'
```

**A new bot is very nearly empty: one node, `hidden`, at `top: 0, left: 0`, and no connections.** No greeting, nothing wired. Read the draft rather than assuming — but expect to build everything, greeting included.

### The greeting is yours to create, and the bot is not publishable without it

The greeting is **a role a node plays, decided by its id** — not a block type and not something the API places for you:

| | |
|---|---|
| **The node id** | `welcome` on `landbot`, `bot_start` on `facebook` and `apichat`. WhatsApp does not restrict the slot at all, since there the bot only ever answers a message the contact sent first. |
| **Which blocks may take it** | Only these seven: `ask_date`, `ask_number`, `ask_phone`, `ask_question`, `ask_url`, `ask_yes_no`, `buttons`. The greeting has to ask something and wait, so **`send_text` cannot be the greeting** — nor can `ask_email`, which waits just the same and is still not allowed. `can_be_welcome` in the catalog is the answer per block. |
| **`params.version: 3`, on `landbot`** | Required, and **no param in the catalog declares it** — the slot wants it, not the block. Without it the builder reads the node as the welcome template it used to be and offers to delete it rather than replace it. |

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" POST /bots/<bot_id>/draft/blocks '{
  "blocks": [{"id": "welcome", "type": "ask_question", "name": "Greeting",
              "params": {"text": "Hi! What is your name?", "destination": "name", "version": 3}}]
}'
```

**Filling the slot changes where the bot starts.** The head is the greeting when the slot is filled and the start point when it is not, so a bot with no greeting heads from `hidden` — which runs, and is not publishable.

**And nothing warns you.** The rule reads as *"if there is a greeting, is it allowed?"*, so a diagram with no greeting at all reports **no violation**: the draft comes back `IS_PRESAVED` with `violations: []` and cannot be published. Do not read a clean draft as a publishable one — see Known gaps.

## Step 3 — Place and wire the blocks

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" POST /bots/<bot_id>/draft/blocks '{
  "blocks": [{"type": "send_text", "params": {…}, "id": "greet", "name": "Greeting"}],
  "connections": [{"sourcePath": "greet", "targetPath": "n0", "type": "$success"}]
}'
```

This **merges** into the diagram rather than replacing it. Grep the spec for `/draft/blocks` for the full contract; what to hold on to:

- **`type` is the semantic name from the catalog** (`send_text`, `ask_question`, `buttons`), not a template.
- **`id` is optional.** Left out, the API assigns `n0`, `n1`, … Give one when you need to wire it in a later request, or when the id is meaningful.
- **A connection's `type` is an output id exactly as the catalog reports it**, `$` and all. Its `id` is optional and defaults to `source.output--target`.
- Connections may reference blocks in the same request or blocks already in the diagram.
- Everything must be reachable from the block the bot heads from. A node nothing arrives at is stored and never runs.
- **On a web channel born v4 (`version 3.1.0`, which is what every skills-journey brand gets) never place `ask_yes_no` or `code`.** Both are in the catalog and both fail silently at runtime on v4: `ask_yes_no` shows "Thinking..." forever, `code` is skipped without a log. Build Yes/No as a `buttons` block. Catalog presence is not evidence of renderer support.
- **On `ask_date`, `format` and `pickerFormat` must agree, and the defaults do not.** `format` is the list of patterns the block *accepts* (strftime, default `["%Y/%m/%d"]`); `pickerFormat` is how the calendar *writes* the date (`dd/MM/yyyy` and so on). Set `pickerFormat` alone and every date the visitor sends is refused with the error text, forever — the bot looks broken and nothing in the API says so (`violations: []`, publish `201`). Set both: `dd/MM/yyyy` → `["%d/%m/%Y"]`, `MM/dd/yyyy` → `["%m/%d/%Y"]`, `yyyy/MM/dd` → `["%Y/%m/%d"]`. Verified on production 2026-09-22, by walking the chat.
- **The visitor types the date; tapping a day in the calendar does not fill the field** (v4, `showDatePicker: true`, observed 2026-09-22 with and without Custom CSS). So the date question must say the format in its own text ("dd/mm/yyyy"), and a walk of that block means typing.
- **Five or more buttons stop looking like buttons.** From five options, v4 draws a boxed list with a search field instead of a row of buttons. Nothing is broken, but say so when you place them, because the person is picturing buttons.
- **A question's words are stored twice: `text` (what the builder shows) and `richText` (what the visitor's chat shows).** The same goes for `errorText` and `richErrorText`. Write the plain one and **leave the rich one out**: add-blocks and `PATCH` derive it from the plain one, and after a `PUT /draft` it is stored empty and the chat shows the plain one (both verified 2026-09-23). A rich copy a caller sends is kept as it came. So a `richText` carried over from an earlier read keeps showing the old words to visitors while the builder shows the new ones: `200`, `violations: []`, a clean publish, and nothing changes for the visitor. Never copy `richText`, `rawText`, `richErrorText` or `rawErrorText` from a read into a write. Bots written through this API before 2026-09-18 can still show Landbot's placeholder "Ask anything" in place of a question; `draft-check gate` blocks a publish while one does.
- **Output ids differ by block**, and a wrong one answers `422`: `send_text` `$success`, `ask_question` `$success`, `set_a_field` `success`, `conditions` `true`/`false`, `formulas` `$success`/`$failed`, a `buttons` block one per button. Read each variant's `outputs`; these are examples, not a list to trust.
- **Rewiring after the first build is `PATCH /bots/{bot_id}/draft`**, one request with `blocks: {add, update, delete}` and `connections: {add, delete}` (check its `x-implemented` and the `DraftPatch` schema in the contract first). `connections.delete` takes `{"source_path": …, "type": …}` and removes every connection leaving that output; `connections.add` takes `sourcePath`, `targetPath`, `type`. `POST /draft/blocks` needs at least one block and cannot carry connections alone (`400`).
- **Before any `PUT /draft` or `DELETE`, snapshot the whole diagram; after it, read it back and compare node and connection counts and identities.** A pilot lost all 49 connections on a `DELETE` that reported `removed_connections: []`. If anything unexplained is missing, restore the snapshot with `PUT /draft` and do not publish.

### Three different failures, and only two of them are a refusal

- **`200` does not mean the diagram is valid.** Broken rules are *stored with the draft* so no work is lost, and reported in `save_state` and `violations` — each with its `code`, `param` and `block_id`. **Always read `violations` after a write; never trust the status alone.** A draft with violations cannot be published or deployed to test.
- **`422` with `violations` means the request was wrong and nothing was written.** An unknown `type`, an `id` already taken, a connection leaving an output the source does not declare, a derived param that will not compile. All or nothing, and the reason is under `error.violations` rather than at the top level. Fixing the payload fixes it.
- **`422` with no `violations` means the bot is not one this API writes** — a previous builder built it. Nothing is wrong with the request, so changing it achieves nothing. See Known gaps.

**The two `422`s are told apart by whether `violations` is there**, not by the status. Read for it before deciding what to say, because the advice is opposite: one means fix the payload, the other means this bot cannot be written at all.

Report `save_state` verbatim, and each violation's `code`.

## Step 4 — Edit what is there

Grep the spec for the operation before using it; the descriptions carry the traps.

| Change | Operation | The thing to know |
|---|---|---|
| One block's params or label | `PATCH /draft/blocks/{block_id}` | **`params` is replaced whole** — a param you omit comes back as its default. So read the block, change what you mean to change, and send all of its params back, **except `richText`, `rawText`, `richErrorText` and `rawErrorText` when the wording changed** (Step 3: the API derives them). Params the catalog does not declare are kept. The block is not retyped. |
| Remove a block | `DELETE /draft/blocks/{block_id}` | Intended to drop incident connections. A pilot lost all connections despite an empty `removed_connections`; read back and compare the complete graph before any publish. |
| Replace the greeting | `DELETE` it, then `POST` a block with the same id | Only a block whose catalog entry says `can_be_welcome: true` may take the slot. Between the two calls the draft breaks `start_connection`. |
| The whole diagram at once | `PUT /draft` | Body is `{"diagram": {…}}`, **not the diagram bare**. It replaces everything and derives nothing: a `richText` left out is stored empty, and the chat then shows `text`. |
| An `ai_agent` block's agent | Not here — `PUT /ai-agents/{agent_id}` | The agent is not in the diagram. See below. |

Several blocks changed together, or an edit that has to drop a connection with it, is `PATCH /bots/{bot_id}/draft` — check its `x-implemented` first.

### An `ai_agent` block takes two requests, to two different resources

The block holds only what running an agent takes — which agent, and the exits the flow may leave by. Everything the agent *is* lives in the agents API, reached through `/ai-agents`, a door this API opens onto it. **That door did not move with the API**: the rest of the API is served under `/v0-alpha`, `/ai-agents` under `/v3` alone. You do not have to care — `lb` sends any `/ai-agents` path to the `/v3` beside `LANDBOT_API_URL` on its own, so write it like every other path below. So a working AI Agent is two requests, in whichever order suits you:

```bash
# 1. The agent. What this body takes is not described in this API's contract and not in the
#    catalog either — that API writes its own account of itself, so read it first:
"${CLAUDE_SKILL_DIR}/scripts/lb" GET /ai-agents/schema

"${CLAUDE_SKILL_DIR}/scripts/lb" POST /ai-agents '{…}'   # → the agent, and its id

# 2. The block naming it, with the exits it routes. Each exit's id is a uuid you generate,
#    written the same in both requests.
"${CLAUDE_SKILL_DIR}/scripts/lb" POST /bots/<bot_id>/draft/blocks '{
  "blocks": [{"type": "ai_agent", "id": "agent", "params": {
    "assistantId": "<the agent id>",
    "outputs": [{"id": "3f2b9c40-7a1e-4d52-9b8c-0e6f1a2d3c45", "name": "Escalate"}]
  }}],
  "connections": [{"sourcePath": "agent", "targetPath": "handoff",
                   "type": "$3f2b9c40-7a1e-4d52-9b8c-0e6f1a2d3c45"}]
}'
```

- **Never invent the agent payload.** `GET /ai-agents/schema` is that API's own OpenAPI document, generated over there. Its paths are its own — the agent it names under `ai-agents` is the one this door carries. If a field is not in it, it does not exist.
- **`assistantId` and `outputs` are both required.** A block placed before there is an agent to name is stored with `param_required` against each — which is a state this API holds on purpose, not a failure. It cannot be published until both are written.
- **Each exit's `id` is a uuid, and you generate it** — the same one in both requests, which is why nothing has to be read back: the block reports one output per exit as `$<id>`, so a connection leaving it travels in the same request that places it. Only the exit's `name` is yours to word. **The agent's own schema declares that id a plain string and it is wrong**: `GET /ai-agents/schema` gives `ExitCondition.id` no `format: uuid` although `Flow.id` beside it has one, and a non-uuid is answered with a `502` from inside the agents service rather than a `422`. The block takes whatever id it is given and never checks, so the two halves of an exit disagree and only one of them says so.
- **An agent's `instructions` stop at 9,000 characters.** The schema declares no limit, but 9,001 is answered `422` with code `internal_error` and the message "Instructions must be 9000 characters or less". Count before you send; if it is over, shorten it. Do not retry the same body.
- **`PUT /ai-agents/{agent_id}` replaces an agent whole.** What the body leaves out goes back to that API's default — knowledge and interactive components a person set up in the editor included. Never use it to tweak one field of an agent someone else configured; read it, or leave it alone.
- **The block reports the exits it was last written with.** An exit renamed or removed straight through the agents API is not reflected in the diagram. Rewrite the block's `outputs` when you change them there.
- `assistantId` is not resolved when it is written. An id from another brand is accepted and answered as `assistant_not_found` when the bot is compiled.
- **A `502` is not proof the agents service is down.** It is also how that service answers a body it fails to validate before it crashes on it — an `exit_conditions` id that is not a uuid is one. Retry **once**. If it repeats, stop retrying and bisect instead: send the minimum the schema requires, then add one field per call until it breaks. Three retries of a whole payload tell you nothing; three calls that grow by one field name the culprit. `429` is the per-brand rate on making agents.

## Step 5 — Test and publish only within the authorized scope

**If the person gave the one yes before building (Step 0), do not ask again for what it covers:** publish (`POST /bots/{id}/versions`); run Step 5a **only if a look was part of that yes** (a flip nobody asked for is forbidden by Step 5a); then Step 5b and Step 6, saying what you did. Otherwise, **ask.** A bot nobody can talk to is half a deliverable, and the user cannot ask for a step they do not know exists — so offer both when you hand the bot back, saying plainly what each one does:

> The bot is built but not live. I can **deploy it to test**, which makes the test link serve this version so you can try it yourself, or **publish it**, which is what real visitors get. Or leave it as a draft. Which?

Offering is not permission. Use explicit authorization already given for the named action and target; do not ask twice for the same authorized work. If publication or test deployment is not authorized, finish the reviewable draft and ask at that boundary. If the user said never to publish, do not offer it again.

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" PUT  /bots/<bot_id>/test       # what the test link serves
"${CLAUDE_SKILL_DIR}/scripts/lb" POST /bots/<bot_id>/versions   # what visitors get
```

Publishing answers `201`. Say what happened in the user's terms — that the test link now serves it, or that visitors now get it — and give the link again.

### Every publish is checked first, by `lb` itself

Publishing makes live whatever the draft holds, and Landbot checks it only for rule violations, not for whether it is what you meant to build. An empty draft breaks no rule. So before every `POST /bots/{id}/versions`, `lb` runs `draft-check gate` and **refuses the publish, sending nothing**, when:

- the draft reports violations, has no blocks, or a web bot has no greeting;
- a connection points at a block that does not exist;
- a question still shows Landbot's placeholder "Ask anything" instead of its wording;
- **the draft changed since your last write** (an edit in the builder, or a builder tab saving an old copy over yours), including a connection pointed somewhere else, or `lb` saw such a change before one of your writes;
- there is **no snapshot of this bot on this machine** (you never wrote it here): nothing shows the draft is the one you meant.

It prints each reason. Fix what is yours to fix. For a changed draft, run `draft-check diff`, tell the person what changed, and only when they agree the draft is right, run `draft-check save <bot_id>` and publish again. For a bot with no snapshot, go through the draft with the person the same way before `draft-check save`. Landbot's API has no "changed since I read it" lock, so a change landing between the check and the publish cannot be ruled out; the walk after the publish is what catches it. It also **warns** (and publishes) about blocks nothing reaches and questions with no next step: say each warning in the hand-back. A write that answered 400 or more wrote nothing: fix it before anything else, and never publish past it.

### When one is refused, say which of these it is

Both validate before they write, so a refusal means **nothing was published**. The draft is untouched and the previous published version keeps running. Five different things can come back, and the answers are not interchangeable:

| What comes back | What it means | What to do |
|---|---|---|
| `422` with `violations` | The draft breaks rules. Each violation carries `code`, `param` and `block_id`, and the violations are **saved to the draft** as a side effect of the attempt. | Name the block and the param for each one, in plain language, and offer to fix them. These are yours to fix. |
| `422` with no `violations` | A previous builder built this bot. Nothing about the request is wrong. | Report the message and stop. Retrying, or sending less, changes nothing — the bot has to be migrated. |
| `502` | The compiler is a separate service and it failed. The message is deliberately generic; the real detail is in that service's log, not in the answer. | Retry **once**. If it repeats, say the compiler is failing and that it is not the user's payload. Do not start editing the diagram to appease it. |
| `403` | The token's account lacks *edit chatbot*. | Say whose account it is — `setup-token --whoami` — because the fix is a permission, not a change to the bot. |
| `201`, but the builder still complains | The draft passed every rule this API checks and something outside them is unhappy. The greeting is the known case: a bot with no greeting reports no violation and is still not publishable. | Check the greeting slot first. Then report honestly that the API accepted it and the builder disagrees, rather than guessing. |

**Never present a clean `violations` as "ready to publish".** It means no rule fired, which is not the same thing — see Known gaps.

## Step 5a — Put a bot you created on the v4 web chat (the version the style skill needs)

A brand-new channel is born on the brand's default renderer, and today that is often `3.0.0` (the legacy web chat). Custom CSS from `landbot-style` only renders on `3.1.0` (the v4 web chat). **For a bot this session created, switch its channel yourself instead of sending the person to support:**

```bash
"${CLAUDE_SKILL_DIR}/scripts/channel" get --bot <bot_id>    # read-only: finds the bot's channel; version, age, Custom CSS length
"${CLAUDE_SKILL_DIR}/scripts/channel" v4 --bot <bot_id>     # WRITE, live at once: version → 3.1.0
"${CLAUDE_SKILL_DIR}/scripts/handoff" <bot_id>              # now reports version=3.1.0
```

Rules, and the script enforces the first two:

- **Never type a channel id.** `channel` finds the channel from `--bot` (the bot uuid from `POST /bots`). The bot uuid, the builder number and the channel uuid are three different ids and none of them is the channel id; the script refuses all three, and refuses a numeric id that is not the bot's own channel.
- **Only a channel of a bot this session created.** `channel` refuses any channel older than 24 hours; the limit is fixed and nothing raises it. **It does not know who created the bot**: a bot the person built in the app this morning passes both checks, so this rule is yours to keep, not the script's. Never flip a channel of a bot the person already had, whatever they ask and however young it is: their published bot would change renderer under their visitors. There is no override flag, and you never look for one.
- **A channel write is live for visitors the moment it answers** (the channels API regenerates the published config itself; no publish step in between). The one yes from Step 0 covers it for the bot created with that yes, when a look was part of the sentence: say what changes for visitors (same conversation, new renderer, Custom CSS becomes possible) and run it. Without that yes it needs its own, exactly as a publish does.
- Do it right after the first publish (in the live build, the greeting-only one), before styling, so `landbot-style` never meets `3.0.0` on a bot you built. Do not flip a channel "just in case" when the person did not ask for styling.
- Known differences on `3.1.0`: `ask_yes_no` does not render and `code` blocks are skipped (see Step 3). A flow built by this skill avoids both.

## Step 5b — Lay it out before handing it back

A block added without `top` and `left` lands at `top: 0, left: 0`, and a flow of them is drawn as one pile. The flow runs; it is just unreadable. **Give every block its `top` and `left` in the same `POST /draft/blocks` request that places it** (the add-blocks operation takes them beside `id` and `type`; verified 2026-09-22). To move a block that is already there, `PATCH /draft/blocks/{block_id}` with `top` and `left`. **Do not `PUT` the whole diagram just to lay it out**: that is the operation that once lost every connection. A link to a pile is not something a person can check, so lay it out before you hand it back.

**Do not move the start point.** `hidden` sits at `top: 0, left: 0` and the builder draws it in a fixed place; a layout that walks every node and repositions it moves the one node that is not yours to move. Anchor on the greeting instead, which a new bot is given at `top: 200, left: 500`, and go right from there. Leave `hidden` exactly as the draft reports it.

Place the rest on the builder's own grid — it puts a greeting at `top: 200, left: 500` and the block after it at `top: 200, left: 850`:

- **Left is how far along the conversation is.** Start at `500` and add `350` per step. A block goes to the right of *every* block that points at it, so when two paths meet, the block they meet at goes past the furthest of them.
- **Top is which branch you are on.** Start at `200`. A block's **first exit keeps its parent's `top`**, so the main path is one straight horizontal line; the other exits go below it, `250` apart. A block with many exits is tall, so leave `250 + 30` per exit below it.
- **Never give two blocks the same `top` and `left`.** Check it, because overlapping blocks are invisible in the builder:

```bash
"${CLAUDE_SKILL_DIR}/scripts/lb" GET /bots/<bot_id>/draft \
  | jq '[.data.diagram.nodes[] | "\(.top),\(.left)"] | group_by(.) | map(select(length > 1))'
```

`[]` means no two blocks share a cell. Anything else, move them with `PATCH /draft/blocks/{block_id}` (`top`, `left`), never a `PUT` of the whole diagram.

- A loop back to an earlier block does not move anything — the edge just runs backwards, which is what a loop looks like.
- Anything the start cannot reach goes in a column of its own, past everything else. It is also a bug worth reporting: a block nothing arrives at never runs.

Use the branch names to decide what goes below what: an error or fallback path reads better under the path it recovers from, and the order the user described the flow in usually is the order to stack it.

## Step 6 — Hand it back

**Every bot you create or change ends with a link and a description of it.** Never finish with only an id: a uuid is not something a person can open, and a list of block types is not something they can check. Both are always part of the answer.

### The link, and the handoff line

The builder routes by the legacy numeric id, not the uuid, and v0-alpha does not report it. The style skill needs the numeric **channel** id and the channel version, which v0-alpha does not report either. One script reads all of it, from three APIs, and prints one line:

```bash
"${CLAUDE_SKILL_DIR}/scripts/handoff" <bot_id>
# LANDBOT_HANDOFF bot=<uuid> builder=<numeric id> share=https://landbot.pro/v3/H-<channel>-<code>/index.html channel=<numeric id> version=3.1.0
```

**End every hand-back with that line, verbatim, as the last line of your answer.** It is the contract the style skill consumes. If the script exits `2`, a field is `?` and it says so: report the line as printed, say which field is missing, and never fill it in by hand.

The builder link is `${LANDBOT_APP_URL:-https://app.landbot.io}/gui/bot/<builder>/builder`. If the bot has an `ai_agent` block, give that one too: `…/builder/ai_agent/<block_id>` opens the agent's own editor.

**Every time you give the builder link, give this with it**, in these words or close to them:

> The builder link is for looking at the flow. If you'd like a change, ask me: I'll make it and keep everything in sync. If you had the builder open while I was working, refresh it first: a tab opened before my change still shows the old flow and would save it back over mine. If you prefer to edit something by hand, go ahead, and tell me before your next request so I pick up your changes.

**`version=3.0.0` on a bot you created this session** means the channel is still on the legacy renderer: run Step 5a (`channel v4`; covered by the one yes from Step 0 if a look was part of it, otherwise ask) before handing off to the style skill. On a bot you did not create, say that Custom CSS needs the v4 web chat and that the switch is something Landbot does per account; do not flip it.

### The description

Describe **what a person talking to the bot goes through**, in order, in plain language. Not the block types — the conversation. Someone who never asked for a `send_text` should be able to read it and tell you whether it is the bot they wanted:

> Greets the visitor, asks for their name, then asks for their email — and if the email is not valid it asks again. Then it thanks them by name and ends. The AI agent takes over if they ask something the flow does not cover, and hands back to a human when it cannot answer.

Where the flow branches, say what sends it each way. Where it can end, say so.

### Then the rest

- the bot name, and **which environment it is in**
- the uuid (v0-alpha) and the numeric id (builder)
- `save_state` and any violations left, verbatim
- **every choice you made that the request did not specify** — a wording you invented, a validation you added, a default you accepted. This is the part the person is most likely to want changed, and the part they cannot see from the link.

Say plainly whether it is published. A bot you built and did not deploy is not serving anyone yet; do not let a builder link imply otherwise.

### Walk it in the in-app browser, when there is one

A published bot is only proven by talking to it. **If this session has Claude's in-app browser** (the Claude desktop app's Code tab: tools named `mcp__Claude_Browser__*`, such as `preview_start`, `navigate`, `find`, `computer`, `get_page_text`, `resize_window`, `read_console_messages`), walk the conversation there yourself. In the live build (above) the walks happen part by part as you publish; otherwise walk it after the publish and after the style push. The person watches the bot run in the side pane while you do it:

1. Open the share URL: `preview_start` with `url` set to it, or `navigate` when the pane is already open. The person may be asked once to allow `landbot.pro`; that is theirs to answer.
2. Answer every question with obviously fake data (`Test Visitor`, `test@example.com`); each walk creates a real chat in their inbox, so say so once. Find buttons by their text with `find` and click the ref. For a text answer: **click the input first** (focus is lost after every answer), type, then press the key named `Enter` — `Return` types nothing and the text piles up in the field. On a date question, type the date in the block's `pickerFormat`; tapping the calendar does not fill the field.
3. **Take every branch to its ending.** For the next branch, load the share URL again with a new query string (`?walk=2`, `?walk=3`) to start a fresh chat.
4. Read what the bot said with `get_page_text`, not from screenshots. If no new bot message arrives within 15 seconds of an answer, that is a dead end: name the block it stopped after and report it; do not publish a fix without the person's yes. When the channel has Custom JS, also read `read_console_messages` (errors only) after the walk: an error from the script is a failure even when the chat looked fine. Keep the pane visible while walking: a hidden pane slows the page's timers and the chat looks stuck when it is not.
5. In the hand-back, say exactly what was walked: "walked by me in the in-app browser: <branch> → <ending>, …". Never merge it with what the person walked.

Never sign in anywhere in that browser, never open `app.landbot.io` for the person, and never type real personal data into the chat.

**No in-app browser** (terminal, Codex, Cursor): give the share URL, list the branches, and ask the person to walk each one to its ending. Until they say they have, say "published", never "works". Say once that in the Claude desktop app's Code tab you could walk every branch yourself in a browser pane beside the chat.

## Known gaps

**The contract is written by hand, not derived from the code.** Serving it does not make it true — it makes it the same everywhere, which a copy taken by hand does not. A contract test beside it is what keeps it honest. So if the API answers something the contract does not describe, **the API is still right**: report the difference rather than working around it, because it means the document has drifted from the code it describes.

**A bot a previous builder built cannot be written at all.** Every write refuses it with `422`, and **that refusal carries no `violations`** — the bot itself is the reason, so there is no rule to attribute. Reading it and reading its draft still work. The message says to migrate the bot, and that is the whole answer: there is nothing to fix in the request, and retrying, sending fewer blocks or rebuilding the payload changes nothing.

This is the failure most likely to meet a real brand, because most bots in one predate this API. Recognise it by a `422` whose `error` has no `violations`, report the message as it comes, and offer to build a new bot instead — never read it as "the draft broke a rule".

**Different environments are at different versions.** The catalog grows one block family at a time, and a block reaches an environment only once it is deployed there — so a block production lists may be missing on a staging environment, and the reverse. `GET /blocks` is the only answer for the environment you are talking to. Never carry over what a catalog said somewhere else.

**No violation means no rule fired — not that the bot is publishable.** The clearest case is the greeting: the rule asks whether an existing greeting is *allowed*, so a diagram with none at all reports nothing, and the draft comes back `IS_PRESAVED` with `violations: []` while the product refuses to publish it. So `violations: []` is the absence of a complaint, not a verdict. Never tell the user a bot is ready on the strength of it; say the draft broke no rule this API checks, which is a smaller claim and a true one.

**This API records the tier a diagram needs. It does not enforce the plan.** `required_tier` is per variant, the publish *calculates* it and stores it on the bot, and nothing in this API compares it with the brand's subscription — the catalog does not report the plan either, and there is no operation that answers it. So do not promise that a block above the plan will be refused here, and do not promise it will work: whether something downstream refuses it is outside this API and not yours to assert. What is worth doing is naming the tier when you place a block that needs one above `sandbox` — `formulas` wants professional; `ai_agent`, `conditions` and `webhook` want starter — so the user knows before, not after.

**A v0-alpha path never takes a trailing slash.** `GET /blocks/` is a `404` served by the marketing site as a page of HTML, not a JSON error — so there is no `error` to read and `lb` prints the page. If a call comes back as HTML, check the path before anything else.

**Not every operation in the spec is served.** Each one carries `x-implemented`; a `false` one is agreed and not built, and its description says what a request to it answers today. Check it before building a plan around an operation.
