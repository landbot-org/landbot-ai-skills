# landbot-flows — operating reference

What earlier builds learned on production Landbot. The Landbot MCP server's tools and the live catalog always win when they disagree with this file. Every claim here says when it was observed and can go stale; reconcile before relying on it.

## Things the server may not say

- **The share host belongs to the brand** (2026-10-03, production). Landbot serves a brand's web chats on one of `landbot.pro`, `landbot.online` or `landbot.site`; of the web channels created in September 2026, 87% were on `.online`, 9% on `.pro`, 4% on `.site`. A share URL on another host answers 404, so take it from `get_web_chat`, never build it.
- Button outputs carry a `$` prefix and condition outputs are `true` / `false` (September 2026). Read the variant's `outputs`; never guess one.
- AI-agent input interactions needed `config.variant` (`text`, `number`, `email`) although the schema is loose (September 2026).
- Do not probe production with deliberately invalid writes to discover enums. Read the schema; if it is silent, ask.

## What the visitor runtime does on v4 (`3.1.0`)

- `ask_yes_no` never renders ("Thinking..." forever). `code` blocks are skipped silently. Use `buttons` for Yes/No; do not rely on `code`.
  Checked 2026-09-22 on one published flow, before and after the channel's switch to `3.1.0`. On `3.0.0` its `code` block ran: the page title changed, a window variable was set, a console line and a network request appeared. On `3.1.0` none of the four happened, and the chat went straight on to the next block. The `ask_yes_no` after it never appeared on `3.1.0` (waited over 20 s).
- On `3.1.0` the `ask_yes_no` question IS sent: the inbox shows it with its buttons. Only the visitor's page never draws it, so the visitor is stuck while the chat looks normal to an agent reading the inbox.
- A bot open in the builder overwrites writes made elsewhere on its next save, and `edited_at` does not move (2026-09-22). Opening a bot and leaving it untouched changed nothing in 60 s.
- `https://app.landbot.io/gui/chats_v4/<chat uuid>` opens that exact chat in the inbox (2026-09-22).
- A `set_a_field` block with value `${chat_uuid}` stores the chat's id (a uuid) on both renderers. Use it when an alert or webhook needs to name the exact chat.
- An AI agent's `instructions` are capped at 9,000 characters: 9,001 is refused with "Instructions must be 9000 characters or less" (2026-09-22).
- `ask_date`: the block accepts only the patterns in `format`, while the calendar writes `pickerFormat`. Mismatched, every answer is rejected in a loop (2026-09-22). Tapping a day does not fill the input; the visitor types the date.
- Five or more `buttons` options render as a boxed list with a search field, not a row of buttons (2026-09-22).
- Enter submits short text inputs. A native Back button re-asks the previous question and the new answer wins; `conditions`, `set_a_field` and `formulas` run again on the way forward, so a branch change after Back works (2026-09-18, and on 16 bots 2026-09-25). Back re-runs every step after the previous answer: a total incremented as the visitor goes counts twice, and an `email` or `webhook` between two questions can fire twice. Compute totals from stored answers and put deliveries after the last question. Keep Back visible (`landbot-style` Step 2b).
- A question keeps its words twice: `text` for the builder and `richText` (HTML) for the visitor's chat. A write that carries an old `richText` with a new `text` changes the builder and not the chat (2026-09-22). Bots written before 2026-09-18 can show "Ask anything" in place of a question (2026-09-23).
- URL parameters on the share link reach later messages as fields, but not the greeting; on the first turn a Set-a-field of the same name can lose to the URL value. Copy URL values into fields of your own before using them.
- Test each screen and input type, each branch, validation and the final values. `violations: []` means no rule fired; it does not mean the visitor's experience works.

## Formulas (`formulas` block): traps found on production, 2026-09-22

- `IsGreater(@a, @b)` on two fields compares them as **text**. For numbers, `IsLess(ToFloat(@x), 10)`.
- `If(...)` returns floats: wrap with `ToInteger(...)` when an integer is shown. Sums drift: `Round(..., 2)`.
- `RegexTest(pattern, value)` takes the **pattern first**; the other order returns False, silently.
- The function is `Concat`, not `Concatenate` (refused when written).
- An empty `set_a_field` value is refused (`param_non_empty`); `UNSET` takes `variables: [{"value": {"name": "field"}}]`.
- The vocabulary has no signatures in the catalog. Try an unknown function on a throwaway bot, never on the person's.

## The web chat's look

- `update_web_chat` writes live only while the bot has never been published and its chat has no unpublished changes; otherwise it writes the chat's draft, which the person publishes from the builder (2026-10). The builder's Preview shows that draft, Custom CSS included (2026-09-25). A builder tab opened before a draft write publishes the copy it loaded, so the person reloads it before pressing Publish there.
- It writes three settings: the v4 web chat, Custom CSS and the visitor's Back button. Custom JS, the `design` colours, the header text, hidden fields and the page head are set in the builder.

## What this skill does not do

- It does not style. Presentation is the `landbot-style` skill.
- It does not enforce the plan. `required_tier` is recorded, not checked. Name the tier when you place `formulas` (professional) or `ai_agent`, `conditions`, `webhook` (starter).
