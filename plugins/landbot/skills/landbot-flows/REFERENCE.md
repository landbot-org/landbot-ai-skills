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
- On `3.1.0` the `ask_yes_no` question IS sent: the inbox shows it with its buttons. Only the visitor's page never draws it, so the visitor is stuck while the chat looks normal to an agent reading the inbox.
- A bot open in the builder overwrites API writes on its next save, and `edited_at` does not move (verified 2026-09-22). Opening a bot and leaving it untouched changed nothing in 60 s; no empty `minChars`/`maxChars` were written.
- `https://app.landbot.io/gui/chats_v4/<chat uuid>` opens that exact chat in the inbox (verified 2026-09-22).
- A `set_a_field` block with value `${chat_uuid}` stores the chat's id (a uuid) on both renderers. Use it when an alert or webhook needs to name the exact chat.
- An AI agent's `instructions` are capped at 9,000 characters (9,001 → `422` "Instructions must be 9000 characters or less"; checked 2026-09-22 on `/ai-agents`).
- `ask_date`: the block accepts only the patterns in `format`, while the calendar writes `pickerFormat`. Mismatched, every answer is rejected in a loop (verified 2026-09-22). Tapping a day does not fill the input; the visitor types the date.
- Five or more `buttons` options render as a boxed list with a search field, not a row of buttons (seen 2026-09-22).
- Enter submits short text inputs. A native Back button exists: it re-asks the previous question and the new answer wins; `conditions`, `set_a_field` and `formulas` run again on the way forward, so a branch change after Back works (verified 2026-09-18 and on 16 bots 2026-09-25). Back re-runs every step after the previous answer: a total that is incremented as the visitor goes counts twice, and an `email` or `webhook` between two questions can fire twice — compute totals from stored answers and put deliveries after the last question. Keep it visible (`landbot-style` Step 2b); `channel back on --bot <uuid>` switches it on (`design.back_button_visible`).
- Test each screen and input type, each branch, validation and the final values. `violations: []` means no API rule fired; it does not mean the visitor experience works.
- A question keeps its words twice: `text` for the builder and `richText` (HTML, `<p>line</p>` per line) for the visitor's chat. The v4 web chat shows `richText` (since about 2026-09-21). A write that carries an old `richText` with a new `text` changes the builder and not the chat (found 2026-09-22 on a published bot). Bots written through this API before 2026-09-18 can show "Ask anything" in place of a question: four of our own demo bots did on 2026-09-23. Copying a whole flow with `PUT /draft` carries the old value along; a `PUT /draft` that leaves `richText` out stores it empty, and the chat then shows `text` (verified 2026-09-23).
- URL parameters on the share link reach later messages as fields, but not the greeting; on the first turn a Set-a-field of the same name can lose to the URL value. Copy URL values into fields of your own before using them.

## Formulas (`formulas` block): traps found on production, 2026-09-22

- `IsGreater(@a, @b)` on two fields compares them as **text**. For numbers, `IsLess(ToFloat(@x), 10)`.
- `If(...)` returns floats: wrap with `ToInteger(...)` when an integer is shown. Sums drift: `Round(..., 2)`.
- `RegexTest(pattern, value)` takes the **pattern first**; the other order returns False, silently.
- The function is `Concat`, not `Concatenate` (refused when written).
- An empty `set_a_field` value is refused (`param_non_empty`); `UNSET` takes `variables: [{"value": {"name": "field"}}]`.
- The vocabulary has no signatures in the catalog. Try an unknown function on a throwaway bot, never on the person's.

## Channel writes: live or draft, preview, publish, discard (`scripts/channel`)

SKILL.md Step 5a has the rules the agent follows; this is how the script carries them out.

- **Live or draft.** `lb` records every bot it creates (`$LANDBOT_STATE_DIR/created/<uuid>`). For a bot recorded on this machine in the last 6 hours, a channel write is **live**: the channels API regenerates the published config itself, with no publish step. For any other bot (one the person already had, one made on another computer, or one of ours past those 6 hours, whose visitors may be real by then) the write goes to the channel's **draft**, with `"autosave": true`, what the builder itself sends. No bot is refused for its age.
- **A live write is read back.** `channel` fetches the published config after it: `served` is the proof; exit 5 means it does not carry the change (Custom CSS is dropped on Sandbox plans), exit 4 that it could not be checked.
- **`channel preview --bot`** reads only. It writes a local page: the published chat with the draft's look (Custom CSS and JS, design, version, channel texts). The flow in it is the published one, so flow changes are not in it. Serve its folder on `127.0.0.1` and open it in the browser pane (the pane does not run local files, and a `file://` page stalls at the loader: verified 2026-09-26). The page talks to the live bot: an answer in it starts a real chat in the inbox, so look, do not walk.
- **`channel publish --bot`** is a live write, never covered by the yes for the draft write. It publishes only a draft this plugin wrote in the last 6 hours that nobody changed since: the settings the plugin wrote come from the draft, every other channel field is sent as the live channel holds it, and a draft that also differs anywhere else (even in a setting the builder Preview does not show, such as the page head) is the person's work, so it refuses (exit 75). It saves the live channel first and prints the undo. Exit 0: the live channel equals the draft and the published config carries it. Exit 3: the Custom JS is not served on this plan. Exit 1, 4 or 5: published but not verified.
- **`channel discard --bot`** is `PATCH /v1/channels/<id>/discard/` with an empty body. The server copies the live channel's settings over the channel's draft (Landbot monorepo `channels/api.py`, 2026-09-25) and nothing else. Run on production 2026-09-26 and 2026-09-28 on probe channel 3517949: the draft Custom CSS was gone, the channel reported no unpublished changes, and the live channel was unchanged. On 2026-09-28 a flow edit (a block moved) was pending in the same bot's draft; after the discard the flow draft still had it and still reported unpublished changes, so a discard does not touch the flow. It refuses (exit 75) when the draft holds changes the plugin did not make, or when it can no longer prove the draft is ours (the live channel changed since, or 6 hours passed).
- **Someone's unpublished changes.** When the channel holds changes nobody published (`pending: YES` in `channel get`), every write refuses (exit 75): a live write would erase them, and a draft write would mix with them. The same exit comes when the channel changed while the write was being prepared.
- **The builder.** Its Preview shows the channel draft too (verified 2026-09-25). A builder tab opened before a draft write publishes the copy it loaded, so the person reloads it before pressing Publish there.

## What this skill does not do

- It does not style. Presentation is the `landbot-style` skill, which consumes the `LANDBOT_HANDOFF` line this skill prints.
- It writes four channel settings, and only through `scripts/channel`: the web chat version (v4), Custom CSS, Custom JS and the visitor's Back button (`channel back on|off`, which sends the whole `design` back with only `back_button_visible` changed). A write is live at once for a bot this plugin created on this machine a few hours ago, and goes to the builder's draft for any other bot (see `scripts/channel`). `channel publish` makes the plugin's own draft live from chat: the builder's Publish is the same v1 `PATCH /v1/channels/<id>/` without `autosave` (Landbot monorepo, 2026-09-25), so it sends every channel field read from `GET /v1/channels/<id>/copy/`, false and empty values included, because a field left out is refilled from the live channel when that value is truthy (verified on production 2026-09-26, probe channel 3517949: all 28 fields sent, live channel and published index.json carried the draft, `merged` true). `channel preview` writes a local page that boots `Landbot.Native` like the share page, with the published index.json and the draft's channel settings over it; a draft has no public URL of its own (the test channel's index.json answers 404, 2026-09-26). Other channel settings (typing indicator, hidden fields, header text, system messages, page head) are not written by this plugin.
- It does not enforce the plan. `required_tier` is recorded, not checked. Name the tier when you place `formulas` (professional) or `ai_agent`, `conditions`, `webhook` (starter).
