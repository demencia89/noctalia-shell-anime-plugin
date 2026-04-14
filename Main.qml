import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    readonly property string scriptPath:
        (pluginApi?.pluginDir ?? "") + "/allanime.py"
    readonly property string luaPath:
        (pluginApi?.pluginDir ?? "") + "/progress.lua"
    readonly property string progressDir:
        (pluginApi?.pluginDir ?? "") + "/progress"

    // ── Settings ──────────────────────────────────────────────────────────────
    property string currentMode:
        pluginApi?.pluginSettings?.mode ||
        pluginApi?.manifest?.metadata?.defaultSettings?.mode ||
        "sub"

    property string panelSize:  pluginApi?.pluginSettings?.panelSize  || "medium"
    property string posterSize: pluginApi?.pluginSettings?.posterSize || "medium"

    function setSetting(key, val) {
        if (key === "mode") currentMode = val
        if (key === "panelSize") panelSize = val
        if (key === "posterSize") posterSize = val
        
        if (pluginApi) {
            pluginApi.pluginSettings[key] = val
            pluginApi.saveSettings()
        }
    }

    function setMode(mode) {
        if (mode !== "sub" && mode !== "dub") return
        if (currentMode === mode) return

        setSetting("mode", mode)

        if (currentAnime)
            fetchAnimeDetail(currentAnime)

        if (currentView === "search" && currentSearchQuery.length > 0)
            searchAnime(currentSearchQuery, true)
        else
            fetchPopular(true)
    }

    // ── Browse state ──────────────────────────────────────────────────────────
    property var    animeList:       []
    property bool   isFetchingAnime: false
    property string animeError:      ""
    property string currentView:     "popular"
    property string currentCountry:  "ALL"
    property string currentSearchQuery: ""
    property string currentGenre:    ""
    property var    genresList:      []
    property int    _page:           1
    property bool   _hasMore:        true

    // ── Detail state ──────────────────────────────────────────────────────────
    property var  currentAnime:     null
    property bool isFetchingDetail: false

    // ── Stream state ──────────────────────────────────────────────────────────
    property var    selectedLink:    null
    property bool   isFetchingLinks: false
    property string linksError:      ""
    property string currentEpisode:  ""

    // ── Currently playing ─────────────────────────────────────────────────────
    property string _playingShowId: ""
    property string _playingEpNum:  ""
    property string _pendingEpisodeId: ""
    property string _pendingProgressFile: ""
    property string _activeShowId: ""
    property string _activeEpNum: ""
    property string _activeProgressFile: ""
    property string _queuedUrl: ""
    property string _queuedRef: ""
    property string _queuedTitle: ""
    property string _queuedShowId: ""
    property string _queuedEpNum: ""
    property string _queuedProgressFile: ""
    property real _queuedStartPos: 0
    property bool _launchQueued: false

    // ── Library ───────────────────────────────────────────────────────────────
    property bool libraryLoaded: false
    property var  libraryList:   []

    // Counter that bumps whenever libraryList changes — views bind to this
    // so watched/in-library checks re-evaluate reactively
    property int libraryVersion: 0

    Component.onCompleted: {
        _loadLibrary()
        _ensureProgressDir()
        fetchGenres()
        fetchPopular(true)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _ensureProgressDir() {
        mkdirProc.command = ["mkdir", "-p", progressDir]
        mkdirProc.running = true
    }

    function _saveLibrary() {
        if (!pluginApi) return
        pluginApi.pluginSettings.library = libraryList
        pluginApi.saveSettings()
        libraryVersion++  // trigger reactive re-evaluation in views
    }

    function _loadLibrary() {
        if (!pluginApi) return
        var raw = pluginApi.pluginSettings?.library
        libraryList = (raw && Array.isArray(raw)) ? raw : []
        libraryLoaded = true
        libraryVersion++
    }

    // ── Library API ───────────────────────────────────────────────────────────
    function isInLibrary(id) {
        var _ = libraryVersion  // reactive dependency
        return libraryList.some(function(e) { return e.id === id })
    }

    function getLibraryEntry(id) {
        var _ = libraryVersion  // reactive dependency
        return libraryList.find(function(e) { return e.id === id }) || null
    }

    function isEpisodeWatched(showId, epNum) {
        var _ = libraryVersion  // reactive dependency
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return false
        return (entry.watchedEpisodes || []).indexOf(String(epNum)) !== -1
    }

    function hasEpisodeProgress(showId, epNum) {
        var _ = libraryVersion
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return false
        var prog = entry.episodeProgress || {}
        return (prog[String(epNum)] || 0) > 0
    }

    function _makeEntry(show, lastEpId, lastEpNum) {
        return {
            id: show.id, name: show.name || "",
            englishName: show.englishName || "",
            nativeName: show.nativeName || "",
            thumbnail: show.thumbnail || "",
            score: show.score || null,
            type: show.type || "",
            episodeCount: show.episodeCount || "",
            availableEpisodes: show.availableEpisodes || {sub:0,dub:0,raw:0},
            season: show.season || null,
            lastWatchedEpId:  lastEpId  ? String(lastEpId)  : "",
            lastWatchedEpNum: lastEpNum ? String(lastEpNum) : "",
            watchedEpisodes:  [],
            episodeProgress:  {}
        }
    }

    function addToLibrary(show) {
        if (isInLibrary(show.id)) return
        var updated = libraryList.slice()
        updated.push(_makeEntry(show, "", ""))
        libraryList = updated
        _saveLibrary()
    }

    function addToLibraryWithEpisode(show, epId, epNum) {
        if (isInLibrary(show.id)) {
            updateLastWatched(show.id, epId, epNum)
            return
        }
        var updated = libraryList.slice()
        updated.push(_makeEntry(show, epId, epNum))
        libraryList = updated
        _saveLibrary()
    }

    function removeFromLibrary(id) {
        libraryList = libraryList.filter(function(e) { return e.id !== id })
        _saveLibrary()
    }

    function updateLastWatched(showId, epId, epNum) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId:  String(epId),
                lastWatchedEpNum: String(epNum),
                watchedEpisodes:  e.watchedEpisodes  || [],
                episodeProgress:  e.episodeProgress  || {}
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function markEpisodeWatched(showId, epNum) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            var watched = (e.watchedEpisodes || []).slice()
            if (watched.indexOf(String(epNum)) === -1) watched.push(String(epNum))
            // Clear progress since it's fully watched
            var prog = Object.assign({}, e.episodeProgress || {})
            delete prog[String(epNum)]
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId:  e.lastWatchedEpId,
                lastWatchedEpNum: e.lastWatchedEpNum,
                watchedEpisodes:  watched,
                episodeProgress:  prog
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function saveEpisodeProgress(showId, epNum, position) {
        var updated = libraryList.map(function(e) {
            if (e.id !== showId) return e
            var prog = Object.assign({}, e.episodeProgress || {})
            prog[String(epNum)] = position
            return {
                id: e.id, name: e.name, englishName: e.englishName,
                nativeName: e.nativeName, thumbnail: e.thumbnail,
                score: e.score, type: e.type, episodeCount: e.episodeCount,
                availableEpisodes: e.availableEpisodes, season: e.season,
                lastWatchedEpId:  e.lastWatchedEpId,
                lastWatchedEpNum: e.lastWatchedEpNum,
                watchedEpisodes:  e.watchedEpisodes || [],
                episodeProgress:  prog
            }
        })
        libraryList = updated
        _saveLibrary()
    }

    function getEpisodeProgress(showId, epNum) {
        var entry = libraryList.find(function(e) { return e.id === showId })
        if (!entry) return 0
        return (entry.episodeProgress || {})[String(epNum)] || 0
    }

    function commitPendingEpisodeSelection() {
        if (!currentAnime || !_playingShowId || !_playingEpNum) return
        if (isInLibrary(_playingShowId))
            updateLastWatched(_playingShowId, _pendingEpisodeId, _playingEpNum)
        else
            addToLibraryWithEpisode(currentAnime, _pendingEpisodeId, _playingEpNum)
    }

    // ── MPV launch & progress tracking ───────────────────────────────────────
    property string _pendingUrl:   ""
    property string _pendingRef:   ""
    property string _pendingTitle: ""

    // Step 1: called from DetailView Connections
    function playWithMpv(url, referer, title) {
        if (!url || url.length === 0) return
        _pendingUrl   = url
        _pendingRef   = referer
        _pendingTitle = title
        _pendingProgressFile = progressDir + "/" + _playingShowId + "-ep" + _playingEpNum + ".txt"

        // Read existing progress file if it exists (for resume)
        preReadProc.command = [
            "sh", "-c",
            "test -f \"$1\" && cat \"$1\" || printf 'position=0\n'",
            "sh",
            _pendingProgressFile
        ]
        preReadProc._buf = ""
        if (preReadProc.running) preReadProc.running = false
        Qt.callLater(function() { preReadProc.running = true })
    }

    Process {
        id: preReadProc
        property string _buf: ""

        onRunningChanged: {
            if (running) return
            var startPos = 0
            var lines = _buf.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith("position=")) {
                    startPos = parseFloat(line.substring(9)) || 0
                }
            }
            _buf = ""
            _doLaunchMpv(startPos)
        }

        stdout: SplitParser {
            onRead: function(data) { preReadProc._buf += data + "\n" }  // SplitParser strips newlines
        }
    }

    function _startMpvSession(showId, epNum, progressFile, startPos, url, referer, title) {
        _activeShowId = showId
        _activeEpNum = epNum
        _activeProgressFile = progressFile
        var args = [
            "mpv", "--fs", "--force-window=yes",
            "--title=" + (title || "Anime"),
            "--script=" + luaPath,
            "--script-opts=progress_file=" + progressFile,
        ]
        if (startPos > 5)
            args.push("--start=" + Math.floor(startPos))
        if (referer && referer.length > 0)
            args.push("--referrer=" + referer)
        args.push(url)

        mpvProcess.command = args
        mpvProcess.running = true
    }

    function _doLaunchMpv(startPos) {
        var showId = _playingShowId
        var epNum = _playingEpNum
        var progressFile = _pendingProgressFile
        var url = _pendingUrl
        var referer = _pendingRef
        var title = _pendingTitle

        if (mpvProcess.running) {
            _queuedShowId = showId
            _queuedEpNum = epNum
            _queuedProgressFile = progressFile
            _queuedUrl = url
            _queuedRef = referer
            _queuedTitle = title
            _queuedStartPos = startPos
            _launchQueued = true
            mpvProcess.running = false
            return
        }

        _startMpvSession(showId, epNum, progressFile, startPos, url, referer, title)
    }

    Process {
        id: mpvProcess

        onRunningChanged: {
            if (running || !root._activeProgressFile) return
            // mpv exited — read the progress file
            postReadProc.command = [
                "sh", "-c",
                "test -f \"$1\" && cat \"$1\" || printf 'duration=0\nposition=0\n'",
                "sh",
                root._activeProgressFile
            ]
            postReadProc._buf    = ""
            postReadProc._showId = root._activeShowId
            postReadProc._epNum  = root._activeEpNum
            postReadProc._pfile  = root._activeProgressFile
            if (postReadProc.running) postReadProc.running = false
            Qt.callLater(function() { postReadProc.running = true })
        }
    }

    Process {
        id: postReadProc
        property string _buf:    ""
        property string _showId: ""
        property string _epNum:  ""
        property string _pfile:  ""

        onRunningChanged: {
            if (running) return
            var dur = 0, pos = 0
            var lines = _buf.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith("duration=")) dur = parseFloat(line.substring(9)) || 0
                if (line.startsWith("position=")) pos = parseFloat(line.substring(9)) || 0
            }
            _buf = ""

            if (dur > 0 && pos > 0) {
                if (pos / dur >= 0.85) {
                    // Fully watched
                    root.markEpisodeWatched(_showId, _epNum)
                    // Delete the progress file
                    rmProc.command = ["rm", "-f", _pfile]
                    rmProc.running = true
                } else {
                    // Partially watched — save position
                    root.saveEpisodeProgress(_showId, _epNum, pos)
                }
            }

            root._activeShowId = ""
            root._activeEpNum = ""
            root._activeProgressFile = ""

            if (root._launchQueued) {
                var nextShowId = root._queuedShowId
                var nextEpNum = root._queuedEpNum
                var nextProgressFile = root._queuedProgressFile
                var nextStartPos = root._queuedStartPos
                var nextUrl = root._queuedUrl
                var nextRef = root._queuedRef
                var nextTitle = root._queuedTitle

                root._launchQueued = false
                root._queuedShowId = ""
                root._queuedEpNum = ""
                root._queuedProgressFile = ""
                root._queuedStartPos = 0
                root._queuedUrl = ""
                root._queuedRef = ""
                root._queuedTitle = ""

                root._startMpvSession(
                    nextShowId,
                    nextEpNum,
                    nextProgressFile,
                    nextStartPos,
                    nextUrl,
                    nextRef,
                    nextTitle
                )
            }
        }

        stdout: SplitParser {
            onRead: function(data) { postReadProc._buf += data + "\n" }
        }
    }

    // ── Utility processes ────────────────────────────────────────────────────
    Process { id: mkdirProc }
    Process { id: rmProc }

    // ── Browse processes ──────────────────────────────────────────────────────
    Process {
        id: genreProc
        property string _buf: ""
        onRunningChanged: {
            if (running) return
            if (_buf.length === 0) return
            try {
                root.genresList = JSON.parse(_buf)
            } catch(e) { Logger.w("Anime", "genres parse error:", e) }
            _buf = ""
        }
        stdout: SplitParser {
            onRead: function(data) { genreProc._buf += data }
        }
    }

    Process {
        id: browseProc
        property string _buf:   ""
        property bool   _reset: true

        onRunningChanged: {
            if (running) return
            root.isFetchingAnime = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) { root.animeError = d.error; _buf = ""; return }
                var results = d.results || []
                root.animeList = _reset ? results : root.animeList.concat(results)
                root._hasMore  = d.hasNextPage || false
                root._page++
            } catch(e) { root.animeError = "Parse error: " + e }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { browseProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "browse:", data)
            }
        }
    }

    Process {
        id: detailProc
        property string _buf:  ""
        property var    _show: null

        onRunningChanged: {
            if (running) return
            root.isFetchingDetail = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) { _buf = ""; return }
                if (_show) {
                    var enriched = Object.assign({}, _show)
                    enriched.episodes = (d.episodes || []).map(function(ep) {
                        return {id: ep.id, number: ep.number}
                    })
                    if (d.description) enriched.description = d.description
                    if (d.thumbnail)   enriched.thumbnail   = d.thumbnail
                    root.currentAnime = enriched
                }
            } catch(e) { Logger.w("Anime", "detail error:", e) }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { detailProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "detail:", data)
            }
        }
    }

    Process {
        id: streamProc
        property string _buf: ""

        onRunningChanged: {
            if (running) return
            root.isFetchingLinks = false
            if (_buf.length === 0) return
            try {
                var d = JSON.parse(_buf)
                if (d.error) { root.linksError = d.error; _buf = ""; return }
                root.selectedLink = d
            } catch(e) { root.linksError = "Parse error: " + e }
            _buf = ""
        }

        stdout: SplitParser {
            onRead: function(data) { streamProc._buf += data }
        }
        stderr: SplitParser {
            onRead: function(data) {
                if (data.trim().length > 0) Logger.w("Anime", "stream:", data)
            }
        }
    }

    // ── Internal browse helper ────────────────────────────────────────────────
    function _runBrowse(args, reset) {
        browseProc._buf   = ""
        browseProc._reset = reset
        browseProc.command = ["python3", scriptPath].concat(args)
        isFetchingAnime = true
        animeError = ""
        if (browseProc.running) {
            browseProc.running = false
            Qt.callLater(function() { browseProc.running = true })
        } else {
            browseProc.running = true
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────
    function fetchGenres() {
        genreProc._buf = ""
        genreProc.command = ["python3", scriptPath, "genres"]
        genreProc.running = true
    }

    function setGenre(genre) {
        if (currentGenre === genre) return
        currentGenre = genre
        if (currentView === "search" && currentSearchQuery.length > 0)
            searchAnime(currentSearchQuery, true)
        else
            fetchPopular(true)
    }

    function fetchPopular(reset) {
        if (reset) { _page = 1; _hasMore = true }
        if (!_hasMore || isFetchingAnime) return
        currentView = "popular"
        currentSearchQuery = ""
        var args = ["popular", String(_page), currentMode]
        if (currentGenre) args.push(currentGenre)
        _runBrowse(args, reset || _page === 1)
    }

    function fetchNextPage() {
        if (currentView === "search")
            searchAnime(currentSearchQuery, false)
        else
            fetchPopular(false)
    }

    function searchAnime(query, reset) {
        if (reset) { _page = 1; _hasMore = true }
        if (isFetchingAnime) return
        currentView = "search"
        currentSearchQuery = query
        var args = ["search", query, currentMode, String(_page)]
        if (currentGenre) args.push(currentGenre)
        _runBrowse(args, reset || _page === 1)
    }

    function fetchAnimeDetail(show) {
        currentAnime = show
        detailProc._buf  = ""
        detailProc._show = show
        detailProc.command = ["python3", scriptPath, "episodes", show.id, currentMode]
        isFetchingDetail = true
        if (detailProc.running) {
            detailProc.running = false
            Qt.callLater(function() { detailProc.running = true })
        } else {
            detailProc.running = true
        }
    }

    function clearDetail() {
        currentAnime = null
        if (detailProc.running) detailProc.running = false
    }

    function fetchStreamLinks(showId, epId, epNum, _quality) {
        if (!currentAnime) return
        _playingShowId  = showId
        _playingEpNum   = String(epNum)
        _pendingEpisodeId = String(epId || "")
        currentEpisode  = String(epNum)
        linksError      = ""
        selectedLink    = null
        isFetchingLinks = true
        streamProc._buf  = ""
        streamProc.command = ["python3", scriptPath, "stream",
                              showId, String(epNum), currentMode]
        if (streamProc.running) {
            streamProc.running = false
            Qt.callLater(function() { streamProc.running = true })
        } else {
            streamProc.running = true
        }
    }

    function clearStreamLinks() {
        selectedLink   = null
        linksError     = ""
        currentEpisode = ""
        _pendingEpisodeId = ""
    }
}
