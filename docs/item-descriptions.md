# Item descriptions

Confirmation shows a short functional description for each item. Packages use pacman metadata; webapps, terminal launchers, and CLI tools use `curated_description_for`. Descriptions do not affect name search, ownership checks, or removal targets.

Package descriptions are queried once for the complete plan using `LC_ALL=C` without wrapping. Control characters are removed; gum wraps complete confirmation rows to the terminal width.

## Editing and sources

Use concise paraphrases of what each tool does, keep a relevant source below, and cover catalogue entries in the description test. References were checked on 20 October 2026 and extended for 4.5 on 6 November 2026. Node.js and uv appear only inside the default-tools group.

| Item | Description | Source |
| --- | --- | --- |
| 🌐 HEY | Email and calendar | [hey.com](https://www.hey.com/) |
| 🌐 Basecamp | Project management and team collaboration | [basecamp.com](https://basecamp.com/) |
| 🌐 WhatsApp | Messaging and voice/video calls | [whatsapp.com](https://www.whatsapp.com/) |
| 🌐 Google Photos | Photo storage, search and editing | [Google Photos](https://www.google.com/photos/about/) |
| 🌐 Google Contacts | Address book | [Contacts Help](https://support.google.com/contacts/answer/1069522) |
| 🌐 Google Messages | Text messaging | [messages.google.com](https://messages.google.com/) |
| 🌐 Google Maps | Maps and directions | [Google Maps](https://www.google.com/maps/about/) |
| 🌐 YouTube | Video sharing and streaming | [youtube.com](https://www.youtube.com/) |
| 🌐 X | Social network and news | [x.com](https://x.com/) |
| 🌐 Zoom | Video meetings and team chat | [zoom.com](https://www.zoom.com/) |
| 🌐 Discord | Community text, voice and video chat | [discord.com](https://discord.com/) |
| 🌐 Grok | AI chat assistant | [grok.com](https://grok.com/) |
| 🌐 ChatGPT | AI chat assistant | [chatgpt.com](https://chatgpt.com/) |
| 🌐 GitHub | Code hosting and collaboration | [github.com](https://github.com/) |
| 🌐 Figma | Interface design and collaboration | [figma.com](https://www.figma.com/) |
| 🌐 Fizzy | Kanban boards | [fizzy.do](https://www.fizzy.do/) |
| 🌐 Docker (TUI) | Docker container management in a terminal | [Arch `lazydocker`](https://archlinux.org/packages/extra/x86_64/lazydocker/) |
| 🌐 Disk Usage (TUI) | Disk usage viewer | [Byron/dua-cli](https://github.com/Byron/dua-cli) |
| ⬢ codex | OpenAI coding agent | [npm `@openai/codex`](https://www.npmjs.com/package/@openai/codex) |
| ⬢ claude | Anthropic coding agent | [npm `@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code) |
| ⬢ crush | Terminal coding agent | [mise registry](https://github.com/jdx/mise/blob/v2026.11.1/registry/crush.toml) |
| ⬢ gemini | Google coding agent | [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) |
| ⬢ gh | GitHub command-line interface | [cli/cli](https://github.com/cli/cli) |
| ⬢ copilot | GitHub coding agent | [npm `@github/copilot`](https://www.npmjs.com/package/@github/copilot) |
| ⬢ opencode | Open-source coding agent | [anomalyco/opencode](https://github.com/anomalyco/opencode) |
| ⬢ playwright, playwright-cli | Browser automation | [npm `playwright`](https://www.npmjs.com/package/playwright) |
| ⬢ pi | Terminal coding agent | [npm `@earendil-works/pi-coding-agent`](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) |
| ⬢ omp | Coding agent with IDE tools | [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi) |
| ⬢ grok | Grok terminal assistant | [npm `@xai-official/grok`](https://www.npmjs.com/package/@xai-official/grok) |
| ⬢ cursor-agent | Cursor coding agent | [cursor.com/cli](https://cursor.com/cli) |
| ⬢ ghui | GitHub pull requests in a terminal | [npm `@kitlangton/ghui`](https://www.npmjs.com/package/@kitlangton/ghui) |
| ⬢ hunk | Terminal diff viewer | [modem-dev/hunk](https://github.com/modem-dev/hunk) |
| ⬢ muse | Meta coding agent | [Meta for Developers](https://dev.meta.ai/resources/blog/build-with-muse-code/) |
| ⬢ hermes | Self-hosted AI agent | [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/) |
| ⬢ agy | Google Antigravity terminal companion | [mise registry](https://github.com/jdx/mise/blob/v2026.11.1/registry/antigravity-cli.toml) |
| ⬢ hey | HEY command-line interface | [basecamp/hey-cli](https://github.com/basecamp/hey-cli) |
| ⬢ basecamp | Basecamp command-line interface | [basecamp/basecamp-cli](https://github.com/basecamp/basecamp-cli) |
| ⬢ cf | Cloudflare API command-line interface | [cloudflare/cf](https://github.com/cloudflare/cf) |
| ⬢ ori | OpenRouter command-line interface | [OpenRouterLabs/ori-releases](https://github.com/OpenRouterLabs/ori-releases) |
| ⬢ kimi | Kimi coding agent | [MoonshotAI/kimi-code](https://github.com/MoonshotAI/kimi-code) (`@moonshot-ai/kimi-code` package metadata) |
| ⬢ amp | Terminal coding agent | [mise amp registry](https://github.com/jdx/mise/blob/v2026.11.1/registry/amp.toml) |
| ⬢ devin | Devin coding agent | [Devin CLI](https://devin.ai/cli) |
| ⬢ kiro-cli | Kiro terminal coding agent | [Kiro CLI](https://kiro.dev/docs/cli/) |
| ⬢ dsh | DeepSeek agent profiles and plugins | [npm metadata](https://registry.npmjs.org/@deepseek-ai/dsh/latest) |
| ⬢ kilo | Terminal coding agent | [npm metadata](https://registry.npmjs.org/@kilocode/cli/latest) |
| ⬢ mcode | MiniMax coding agent | [npm metadata](https://registry.npmjs.org/@minimax-ai/code/latest) |
| ⬢ commandcode | Terminal coding agent | [npm metadata](https://registry.npmjs.org/command-code/latest) |
| ⬢ freebuff | Terminal coding agent | [npm metadata](https://registry.npmjs.org/freebuff/latest) |
| ⬢ qwen | Qwen coding agent | [mise qwen registry](https://github.com/jdx/mise/blob/v2026.11.1/registry/qwen.toml) |
| node (group only) | JavaScript runtime | [Node.js](https://nodejs.org/) |
| uv (group only) | Python package and project manager | [astral-sh/uv](https://github.com/astral-sh/uv) |
| ⬢ Omarchy default CLI tools (all) | Opt out of all default mise tools, including Node.js and uv | [Omarchy opt-out contract](https://github.com/omacom/omarchy/blob/v4.5.0/bin/omarchy-mise-default-tools) |
