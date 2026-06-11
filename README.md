<div align="center">

# WhisperQuill

**A native macOS AI chat app powered by [OpenRouter](https://openrouter.ai)**

*A personal hobby project built to explore agentic coding and have fun.*

![macOS](https://img.shields.io/badge/macOS-26%2B-black?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?logo=swift&logoColor=white)
![Architecture](https://img.shields.io/badge/arch-arm64-lightgrey)
![Status](https://img.shields.io/badge/status-active%20development-brightgreen)

</div>

---

## What is WhisperQuill?

WhisperQuill is a lightweight, native macOS chat client that connects to [OpenRouter](https://openrouter.ai) — giving you access to dozens of AI models through a single, clean interface built entirely in SwiftUI.

This is a **solo hobby project** — primarily a playground for learning agentic AI-assisted coding workflows and experimenting with macOS native UI. It is not a polished commercial product, but it is a fully functional app used daily.

---

## Features

- **Multi-model chat** — Switch between any model available on OpenRouter mid-conversation
- **Real-time streaming** — Responses stream token-by-token with smooth animated delivery
- **Per-chat parameters** — Override temperature, top-p, max tokens, and more per conversation
- **Usage & cost tracking** — Live token counts and USD cost estimates per message and per chat
- **Auto-titling** — Chats are automatically titled by a lightweight model after the first exchange
- **JSON inspector** — Inspect the raw API response for any assistant message
- **Secure API key storage** — Your OpenRouter key lives in the macOS Keychain, never on disk
- **Native Liquid Glass UI** — macOS Sequoia system materials, SF Symbols, sidebar/detail layout

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 26 (Sequoia) or later |
| Xcode | 26.3 or later |
| Architecture | Apple Silicon (arm64) only |
| OpenRouter API Key | [Get one free at openrouter.ai](https://openrouter.ai/keys) |

> **Note:** Intel Macs and iOS/iPadOS are not supported targets.

---

## Architecture

WhisperQuill follows a clean separation of concerns with protocol-backed layers:

```
UI Layer          NavigationSplitView → SidebarView + ConversationPane
State             ConversationStore (ObservableObject, owns all chat state)
Persistence       ChatRepositoryProtocol → SwiftDataChatRepository (SwiftData)
Engine            ChatEngineProtocol → OpenRouterChatEngine
Networking        OpenRouterService (URLSession, SSE streaming)
Design System     AppPalette color tokens · native .glassEffect() · SF Symbols
```

**Key design decisions:**
- API key lives in Keychain only (`com.josh.jchat` / `openrouter-api-key`)
- Token counts and costs are **monotonically increasing** — no refunds on delete/regenerate
- Streaming uses Server-Sent Events (SSE); authoritative cost is settled via `GET /generation` after each stream

---

## Project Structure

```
JChat/
├── Core/
│   └── Conversation/       # ConversationStore, ChatEngine, ChatRepository
├── Models/                 # AppSettings, CachedModel, Character
├── Services/               # OpenRouterService (networking + SSE)
├── UI/
│   ├── Design/             # AppPalette, AppDesign tokens
│   ├── ShellViews.swift    # ConversationPane, SidebarView, MessageRow
│   └── ParameterInspector.swift
├── Views/
│   ├── ContentView.swift
│   ├── SettingsView.swift
│   └── Components/         # InlineModelPicker, etc.
└── Chat.swift              # Core data model
Docs/
├── PROJECT_GUIDE.md        # Architecture, build environment, conventions
├── CHANGELOG_INTERNAL.md   # Session-by-session history
└── KNOWN_ISSUES.md         # Resolved issue log
```

---

## Roadmap

Active backlog is tracked on [GitHub Issues](https://github.com/joshellis625/JChat/issues).

Current priorities:
1. Freeze prevention and transcript stability in long chats
2. UI polish toward a clean, minimal chat experience
3. OpenRouter streaming reliability and consistency
4. Feature re-expansion after stability is locked

---

## Contributing

This is a personal project and is not actively seeking contributions. Feel free to fork and experiment — that's the spirit of it.

---

## License

MIT License

Copyright (c) 2026 ailthrim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

<div align="center">

Built with SwiftUI · Powered by [OpenRouter](https://openrouter.ai) · Made for fun

</div>
