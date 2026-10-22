# Item descriptions

The selector and final confirmation show a one-line description next to each item, so that unfamiliar names like `aether`, `omacut`, or `hunk` can be judged before removal.

- **Packages** show their pacman `Description` (the package's `pkgdesc`), read at runtime with one `LC_ALL=C pacman -Qi` call. Nothing here needs updating when packages are added or uncommented.
- **Webapps, TUIs, and CLI wrappers** have no local description. `curated_description_for` holds each project's own one-line description, with the sources listed below.

Descriptions are plain text. Control characters are removed before display, and each row is trimmed with `…` to fit the terminal, measured in cells so wide CJK text fits too. Trimming stops at a word boundary, or between CJK characters. Without room, or without a description, a row looks exactly as it did before.

## Rules for curated text

- Use the project's own words, from the first available of:
  1. its package registry entry (mise registry, npm),
  2. its repository's About text or README,
  3. the service's own page title or meta description,
  4. Omarchy's own summary.
- Shorten only by dropping a leading or trailing clause, a leading subject (`Join`, `You can`, `<name> is`), or trailing punctuation. A pronoun may be replaced by what it refers to. Do not reword.
- Keep each line at 100 characters or fewer, with no final period. Tests enforce this, and require an entry for every `DEFAULT_WEBAPPS`, `DEFAULT_TUIS`, and `DEFAULT_NPM_CLIS` item.

## Sources

All sources were retrieved on 2026-10-20.

| Item | Text | Source |
| --- | --- | --- |
| 🌐 HEY | A delightfully fresh take on email + calendar, from 37signals | [hey.com](https://www.hey.com/) page title |
| 🌐 Basecamp | Basecamp puts everything you need to get work done in one place | [basecamp.com](https://basecamp.com/) meta description |
| 🌐 WhatsApp | Simple, reliable, private messaging and calling for free | [whatsapp.com](https://www.whatsapp.com/) tagline |
| 🌐 Google Photos | Edit, Organize, Search, and Backup Your Photos | [Google Photos](https://www.google.com/photos/about/) page title |
| 🌐 Google Contacts | Save names, email addresses, phone numbers, and more | [Contacts Help](https://support.google.com/contacts/answer/1069522) |
| 🌐 Google Messages | A simple, helpful text messaging app | [messages.google.com](https://messages.google.com/) page title |
| 🌐 Google Maps | Google Maps is your ultimate guide to explore and navigate the world | [Google Maps](https://www.google.com/maps/about/) meta description |
| 🌐 YouTube | Enjoy the videos and music you love, upload original content | [youtube.com](https://www.youtube.com/) meta description |
| 🌐 X | From breaking news and entertainment to sports and politics, get the full story | [x.com](https://x.com/) meta description |
| 🌐 Zoom | Zoom's trusted collaboration tools: including video meetings, Zoom Chat, VoIP phone, webinars | [zoom.com](https://www.zoom.com/) meta description |
| 🌐 Discord | Group Chat That’s All Fun & Games | [discord.com](https://discord.com/) page title |
| 🌐 Grok | Grok is an AI assistant | [grok.com](https://grok.com/) meta description |
| 🌐 ChatGPT | ChatGPT helps you get answers, find inspiration, and be more productive | [chatgpt.com](https://chatgpt.com/) `og:description` |
| 🌐 GitHub | The world's most widely adopted, AI-powered developer platform | [github.com](https://github.com/) meta description |
| 🌐 Figma | Figma is the canvas where design, code, and AI come together | [figma.com](https://www.figma.com/) meta description |
| 🌐 Fizzy | A refreshing take on cards, columns, and kanban | [fizzy.do](https://www.fizzy.do/) meta description |
| 🌐 Docker (TUI) | A simple terminal UI for docker and docker-compose | [Arch `lazydocker`](https://archlinux.org/packages/extra/x86_64/lazydocker/) package description |
| 🌐 Disk Usage (TUI) | View disk space usage and delete unwanted data, fast | [Byron/dua-cli](https://github.com/Byron/dua-cli) About |
| ⬢ codex | Codex CLI is a coding agent from OpenAI that runs locally on your computer | [npm `@openai/codex`](https://www.npmjs.com/package/@openai/codex) |
| ⬢ claude | Use Claude, Anthropic's AI assistant, right from your terminal | [npm `@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code) |
| ⬢ crush | The glamourous AI coding agent for your favourite terminal | mise registry (`mise tool --description crush`) |
| ⬢ gemini | An open-source AI agent that brings the power of Gemini directly into your terminal | [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) About |
| ⬢ gh | GitHub’s official command line tool | [cli/cli](https://github.com/cli/cli) About |
| ⬢ copilot | GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal | [npm `@github/copilot`](https://www.npmjs.com/package/@github/copilot) |
| ⬢ opencode | The open source coding agent | [anomalyco/opencode](https://github.com/anomalyco/opencode) About |
| ⬢ playwright, playwright-cli | A high-level API to automate web browsers | [npm `playwright`](https://www.npmjs.com/package/playwright) |
| ⬢ pi | Coding agent CLI with read, bash, edit, write tools and session management | [npm `@earendil-works/pi-coding-agent`](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) |
| ⬢ omp | Coding agent with the IDE wired in | [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi) About |
| ⬢ grok | Bring Grok into your terminal | [npm `@xai-official/grok`](https://www.npmjs.com/package/@xai-official/grok) |
| ⬢ cursor-agent | Cursor CLI — Run Agents in Terminal | [cursor.com/cli](https://cursor.com/cli) page title |
| ⬢ ghui | Terminal UI for GitHub pull requests | [npm `@kitlangton/ghui`](https://www.npmjs.com/package/@kitlangton/ghui) |
| ⬢ hunk | Review-first terminal diff viewer for agentic coders | [modem-dev/hunk](https://github.com/modem-dev/hunk) About |
| ⬢ muse | Muse Code is the coding agent built to run Muse Spark 1.2 | [Meta for Developers](https://dev.meta.ai/resources/blog/build-with-muse-code/) standfirst ("it" resolved) |
| ⬢ hermes | Hermes Agent is the open-source, self-hosted AI agent by Nous Research | [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/) meta description |
| ⬢ agy | Google Antigravity CLI companion | mise registry (`mise tool --description antigravity-cli`) |
| ⬢ hey | HEY CLI and Agent Skills | [basecamp/hey-cli](https://github.com/basecamp/hey-cli) About |
| ⬢ basecamp | The official command-line interface for Basecamp | [basecamp/basecamp-cli](https://github.com/basecamp/basecamp-cli) README |
| ⬢ cf | The agentic CLI for the entire Cloudflare API | [cloudflare/cf](https://github.com/cloudflare/cf) About |
| ⬢ ori | OpenRouter's CLI for working with projects you already have | [OpenRouterLabs/ori-releases](https://github.com/OpenRouterLabs/ori-releases) README |
