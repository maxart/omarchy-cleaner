# Item descriptions

The final confirmation shows a short description beside each selected item. The fuzzy selector searches names and category/shortcut labels only, so descriptive text cannot change name ranking.

- **Packages** use pacman's `Description`, queried once for the full planned removal set with `LC_ALL=C` and wrapping disabled.
- **Webapps, TUIs, and CLI wrappers** use short functional summaries in `curated_description_for`.

Control characters are removed before display. Gum wraps complete confirmation rows to the terminal width, including Unicode text; names and descriptions are not truncated.

## Editing descriptions

Describe what a tool does in plain language. Prefer a short functional phrase over promotional wording or version-specific details. Paraphrasing is welcome. Keep a relevant upstream reference below, and cover each catalogue entry in the description test. Descriptions never determine ownership or removal targets.

## Sources

The original PR recorded the references below on 2026-10-20. The displayed text is now a concise summary, not a verbatim quotation.

| Item | Text | Source |
| --- | --- | --- |
| 🌐 HEY | Email and calendar | [hey.com](https://www.hey.com/) page title |
| 🌐 Basecamp | Project management and team collaboration | [basecamp.com](https://basecamp.com/) meta description |
| 🌐 WhatsApp | Messaging and voice/video calls | [whatsapp.com](https://www.whatsapp.com/) tagline |
| 🌐 Google Photos | Photo storage, search and editing | [Google Photos](https://www.google.com/photos/about/) page title |
| 🌐 Google Contacts | Address book | [Contacts Help](https://support.google.com/contacts/answer/1069522) |
| 🌐 Google Messages | Text messaging | [messages.google.com](https://messages.google.com/) page title |
| 🌐 Google Maps | Maps and directions | [Google Maps](https://www.google.com/maps/about/) meta description |
| 🌐 YouTube | Video sharing and streaming | [youtube.com](https://www.youtube.com/) meta description |
| 🌐 X | Social network and news | [x.com](https://x.com/) meta description |
| 🌐 Zoom | Video meetings and team chat | [zoom.com](https://www.zoom.com/) meta description |
| 🌐 Discord | Community text, voice and video chat | [discord.com](https://discord.com/) page title |
| 🌐 Grok | AI chat assistant | [grok.com](https://grok.com/) meta description |
| 🌐 ChatGPT | AI chat assistant | [chatgpt.com](https://chatgpt.com/) `og:description` |
| 🌐 GitHub | Code hosting and collaboration | [github.com](https://github.com/) meta description |
| 🌐 Figma | Interface design and collaboration | [figma.com](https://www.figma.com/) meta description |
| 🌐 Fizzy | Kanban boards | [fizzy.do](https://www.fizzy.do/) meta description |
| 🌐 Docker (TUI) | Docker container management in a terminal | [Arch `lazydocker`](https://archlinux.org/packages/extra/x86_64/lazydocker/) package description |
| 🌐 Disk Usage (TUI) | Disk usage viewer | [Byron/dua-cli](https://github.com/Byron/dua-cli) About |
| ⬢ codex | OpenAI coding agent | [npm `@openai/codex`](https://www.npmjs.com/package/@openai/codex) |
| ⬢ claude | Anthropic coding agent | [npm `@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code) |
| ⬢ crush | Terminal coding agent | mise registry (`mise tool --description crush`) |
| ⬢ gemini | Google coding agent | [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) About |
| ⬢ gh | GitHub command-line interface | [cli/cli](https://github.com/cli/cli) About |
| ⬢ copilot | GitHub coding agent | [npm `@github/copilot`](https://www.npmjs.com/package/@github/copilot) |
| ⬢ opencode | Open-source coding agent | [anomalyco/opencode](https://github.com/anomalyco/opencode) About |
| ⬢ playwright, playwright-cli | Browser automation | [npm `playwright`](https://www.npmjs.com/package/playwright) |
| ⬢ pi | Terminal coding agent | [npm `@earendil-works/pi-coding-agent`](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) |
| ⬢ omp | Coding agent with IDE tools | [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi) About |
| ⬢ grok | Grok terminal assistant | [npm `@xai-official/grok`](https://www.npmjs.com/package/@xai-official/grok) |
| ⬢ cursor-agent | Cursor coding agent | [cursor.com/cli](https://cursor.com/cli) page title |
| ⬢ ghui | GitHub pull requests in a terminal | [npm `@kitlangton/ghui`](https://www.npmjs.com/package/@kitlangton/ghui) |
| ⬢ hunk | Terminal diff viewer | [modem-dev/hunk](https://github.com/modem-dev/hunk) About |
| ⬢ muse | Meta coding agent | [Meta for Developers](https://dev.meta.ai/resources/blog/build-with-muse-code/) standfirst ("it" resolved) |
| ⬢ hermes | Self-hosted AI agent | [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/) meta description |
| ⬢ agy | Google Antigravity terminal companion | mise registry (`mise tool --description antigravity-cli`) |
| ⬢ hey | HEY command-line interface | [basecamp/hey-cli](https://github.com/basecamp/hey-cli) About |
| ⬢ basecamp | Basecamp command-line interface | [basecamp/basecamp-cli](https://github.com/basecamp/basecamp-cli) README |
| ⬢ cf | Cloudflare API command-line interface | [cloudflare/cf](https://github.com/cloudflare/cf) About |
| ⬢ ori | OpenRouter command-line interface | [OpenRouterLabs/ori-releases](https://github.com/OpenRouterLabs/ori-releases) README |
