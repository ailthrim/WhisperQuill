# WhisperQuill — Codex Project Context

WhisperQuill is a native SwiftUI chat app for macOS that connects to OpenRouter. This is a solo hobby project.

## Canonical Docs

Read `Docs/PROJECT_GUIDE.md` first. It is the source of truth for architecture, build workflow, validation, regression checks, git workflow, and reference links.

| Doc | Contents |
| --- | --- |
| `Docs/PROJECT_GUIDE.md` | Architecture, build environment, Codex workflow, validation, regression checklist, git workflow, reference links |
| `Docs/KNOWN_ISSUES.md` | Resolved issue log and older backlog notes. Current open work belongs in GitHub Issues |
| `Docs/CHANGELOG_INTERNAL.md` | Session-by-session history of changes and decisions |

## Codex Workflow

- Treat `Docs/` as the project memory layer.
- Keep durable project facts in `Docs/PROJECT_GUIDE.md`.
- Keep session history and meaningful recovery notes in `Docs/CHANGELOG_INTERNAL.md`.
- Update docs at natural checkpoints after code, build, workflow, or architecture changes.
- Do not recreate stale pre-rename artifacts. The canonical project is `WhisperQuill.xcodeproj`.

## Build Rules

- Clean the build folder before every build.
- Use the current macOS target only: `WhisperQuill.xcodeproj`, scheme `WhisperQuill`, arm64.
- XcodeBuildMCP should be available, but it is most useful for iOS simulator workflows. For this macOS-only app, explicit `xcodebuild` commands against `WhisperQuill.xcodeproj` are acceptable and often simpler.
- Do not build or restore `JChat.xcodeproj`; it is an obsolete pre-rename project artifact.

## Reference Docs Policy

Before writing SwiftUI, UI layout, or HIG-related code, consult the Apple HIG and SwiftUI links in `Docs/PROJECT_GUIDE.md`.

Before writing OpenRouter API code, consult the OpenRouter API reference links in `Docs/PROJECT_GUIDE.md`.

Do not guess at API shapes or UI conventions when the source docs are available.

## Tool Boundaries

Each AI tool owns its own local config directory. Do not cross-pollinate configs.

| Directory | Owner |
| --- | --- |
| `.codex/` | Codex config only |
| `.gemini/` | Gemini config only |
| `Docs/` | Shared human-readable project memory and history |

If two docs conflict, update the canonical source first, then update references.

## End-of-Session Changelog

At the end of every session that involves code, build workflow, repo recovery, or doc changes, update `Docs/CHANGELOG_INTERNAL.md` using Keep a Changelog style:

```markdown
## [YYYY-MM-DD] - Session Title

### Added
### Changed
### Fixed
### Removed
### Notes
```

Omit empty sections. Keep entries short and scannable.
