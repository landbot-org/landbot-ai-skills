# landbot-flows — operating reference

Read this before building or editing. It records what earlier runs learned; the live contract (`GET /openapi.yml`) and catalog (`GET /blocks`) always win when they disagree with this file. Every claim here was observed on production during September 2026 and can go stale; reconcile before relying on it.

## Connection integrity (the one rule that protects the customer's bot)

The bulk `PUT /draft` diagram carries **a keyed connections object**. Do not confuse it with the array the add-blocks operation accepts. Preserve every field you do not understand.

An earlier run sent `PUT` an array by mistake, then a `DELETE` removed all 49 connections while reporting `removed_connections: []`; a publish that followed served a disconnected bot for about a minute.

So, before every `PUT /draft` or `DELETE /draft/blocks/{id}`:
1. Save the complete draft (`GET /bots/{id}/draft`) to a file.
2. After the write, read it back.
3. Compare node ids and connection ids and counts, not just counts.
4. Check the paths you expect are still reachable from the greeting.
5. On any unexplained loss, `PUT` the saved draft back and stop. Do not publish. `removed_connections` and `violations` are not evidence either way.

## Things the API does that the contract may not say

- `POST /bots` returned the uuid as `data.id`. Read the actual response.
- Button payloads needed `$` prefixes; condition outputs were `true` / `false`. Read the variant's `outputs`.
- An add-blocks request needs at least one block; it is not a connections-only call.
- AI-agent input interactions needed `config.variant` (`text`, `number`, `email`) although the schema is loose. Exit ids must be uuids; a non-uuid answers `502` from the agents service, not `422`.
- Do not probe production with deliberately invalid writes to discover enums. Read the schema; if it is silent, ask.
- A trailing slash on a v0-alpha path is a `404` served as HTML by the marketing site.

## What the visitor runtime does on v4 (`3.1.0`)

- `ask_yes_no` never renders ("Thinking..." forever). `code` blocks are skipped silently. Use `buttons` for Yes/No; do not rely on `code`.
  Re-checked 2026-09-22 on one published flow, before and after the channel's switch to `3.1.0`. On `3.0.0` its `code` block ran: the page title changed, a window variable was set, a console line and a network request appeared. On `3.1.0` none of the four happened, and the chat went straight on to the next block. The `ask_yes_no` after it never appeared on `3.1.0` (waited over 20 s); the chat stops there. On `3.0.0` it rendered and answered.
- A `set_a_field` block with value `${chat_uuid}` stores the chat's id (a uuid) on both renderers. Use it when an alert or webhook needs to name the exact chat.
- An AI agent's `instructions` are capped at 9,000 characters (9,001 → `422` "Instructions must be 9000 characters or less"; checked 2026-09-22 on `/ai-agents`).
- `ask_date`: the block accepts only the patterns in `format`, while the calendar writes `pickerFormat`. Mismatched, every answer is rejected in a loop (verified 2026-09-22). Tapping a day does not fill the input; the visitor types the date.
- Five or more `buttons` options render as a boxed list with a search field, not a row of buttons (seen 2026-09-22).
- Enter submits short text inputs. A native Back button exists and returns to an editable earlier input on the paths tested; branch-changing rollback was not tested.
- Test each screen and input type, each branch, validation and the final values. `violations: []` means no API rule fired; it does not mean the visitor experience works.

## What this skill does not do

- It does not style. Presentation is the `landbot-style` skill, which consumes the `LANDBOT_HANDOFF` line this skill prints.
- It does not write channel settings. The Bots API has no channel-style operation, and channel writes can be live immediately.
- It does not enforce the plan. `required_tier` is recorded, not checked. Name the tier when you place `formulas` (professional) or `ai_agent`, `conditions`, `webhook` (starter).
