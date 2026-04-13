# Anime Plugin for Noctalia

Browse and track anime directly from your Noctalia bar. Streams episodes via `mpv` using AllAnime as the backend source.

## Features

- **Browse tab** — Popular anime, search, sub/dub toggle, infinite scroll
- **Library tab** — Save shows, track last-watched episode per show
- **Detail view** — Full episode list with one-click mpv playback
- **Progress tracking** — Resume partial episodes and automatically mark watched episodes
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
└── components/
    ├── BrowseView.qml
    ├── DetailView.qml
    └── LibraryView.qml
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
