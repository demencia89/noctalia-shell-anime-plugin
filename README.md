# Anime Plugin for Noctalia

Browse and track anime directly from your Noctalia bar. Streams episodes via `mpv` using AllAnime as the backend source.

## Features

- **Browse tab** — Popular anime, search, sub/dub toggle, infinite scroll, and quick hover actions to add or remove shows from your library
- **Library tab** — Saved shows with last-watched progress and direct remove controls on each card
- **Detail view** — Full episode list with one-click mpv playback
- **Progress tracking** — Resume partial episodes and automatically mark watched episodes
- **Adaptive styling** — Uses Noctalia theme roles so the plugin follows the active dynamic colorscheme
- **Persistent state** — Library, layout preferences, mode, and progress saved in Noctalia plugin settings

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

| Key          | Default   | Description                                |
|--------------|-----------|--------------------------------------------|
| `mode`       | `sub`     | Default audio mode (`sub` or `dub`)        |
| `panelSize`  | `medium`  | Drawer width preset (`small/medium/large`) |
| `posterSize` | `medium`  | Grid density preset (`small/medium/large`) |

## Notes

- The plugin shells out to `python3` for API requests and to `mpv` for playback.
- Stream URLs are resolved on demand; they are ephemeral and not stored in settings.
- Library data is stored in `~/.config/noctalia/plugins/anime/settings.json`.
- Resume data is stored as per-episode text files under `~/.config/noctalia/plugins/anime/progress/`.
- Browse and library cards use separate library action buttons, so adding or removing a show does not require opening its detail view.
