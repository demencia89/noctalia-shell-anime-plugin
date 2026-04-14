# Anime Plugin for Noctalia

Browse and track anime directly from your Noctalia bar. Streams episodes via `mpv` using AllAnime as the backend source.

## Features

- **Browse tab** — Popular and recent-release feeds, search, sub/dub toggle, infinite scroll, genre filters, and quick hover actions to add or remove shows from your library
- **Library tab** — Saved shows with direct remove controls, progress bars, and remembered scroll position when returning from detail view
- **Continue Watching rail** — In-progress anime are surfaced at the top of the library for quick resuming
- **Detail view** — Full episode list with one-click mpv playback, per-episode watched/unwatched controls, and progress indicators
- **Progress tracking** — Resume partial episodes, automatically mark watched episodes, and keep richer playback progress with position and duration
- **Playback preferences** — Choose preferred stream quality and provider fallback order from the settings panel
- **Navigation quality-of-life** — Browse and library grids restore your scroll position after opening and closing a show
- **Adaptive styling** — Uses Noctalia theme roles so the plugin follows the active dynamic colorscheme
- **Persistent state** — Library, layout preferences, browse preferences, playback preferences, and progress saved in Noctalia plugin settings

## Requirements

- `mpv` in `$PATH`
- `python3` in `$PATH`
- Network access to `api.allanime.day` and the resolved stream providers

## Installation

Drop the `anime/` folder into your Noctalia plugins directory, then enable it in the Plugins tab.

```
~/.config/noctalia/plugins/anime/
├── manifest.json
├── Main.qml
├── BarWidget.qml
├── Panel.qml
├── progress.lua
└── components/
    ├── BrowseView.qml
    ├── DetailView.qml
    ├── LibraryView.qml
    ├── PlayerView.qml
    └── SettingsView.qml
```

## Settings

| Key                 | Default   | Description                                                |
|---------------------|-----------|------------------------------------------------------------|
| `mode`              | `sub`     | Default audio mode (`sub` or `dub`)                        |
| `panelSize`         | `medium`  | Drawer width preset (`small/medium/large`)                 |
| `posterSize`        | `medium`  | Grid density preset (`small/medium/large`)                 |
| `preferredQuality`  | `best`    | Preferred playback quality (`best/1080/720/480`)           |
| `preferredProvider` | `auto`    | Preferred provider order (`auto/default/sharepoint/...`)   |

## Notes

- The plugin shells out to `python3` for API requests and to `mpv` for playback.
- Stream URLs are resolved on demand; they are ephemeral and not stored in settings.
- Library data is stored in `~/.config/noctalia/plugins/anime/settings.json`.
- Resume data is stored as per-episode text files under `~/.config/noctalia/plugins/anime/progress/`.
- Browse and library cards use separate library action buttons, so adding or removing a show does not require opening its detail view.
- Existing saved progress entries remain compatible; newer sessions store both playback position and duration so the UI can render actual progress bars.
- Provider preference is best-effort. If the preferred source fails, the plugin falls back to the remaining known providers automatically.
