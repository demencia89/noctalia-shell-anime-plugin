#!/usr/bin/env python3
"""
allanime.py — AllAnime API helper for the Noctalia anime plugin.
No third-party dependencies; uses only stdlib.

Usage:
  python3 allanime.py search <query> [sub|dub] [page]
  python3 allanime.py popular [page] [sub|dub]
  python3 allanime.py latest [page] [sub|dub] [country]
  python3 allanime.py episodes <show_id> [sub|dub]
  python3 allanime.py stream <show_id> <episode_number> [sub|dub]

All output is JSON on stdout. Errors are {"error": "..."} with exit code 1.
"""

import json
import sys
import urllib.request
import urllib.error
import re

# ── Constants ─────────────────────────────────────────────────────────────────
API     = "https://api.allanime.day/api"
REFERER = "https://allmanga.to"
AGENT   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
BASE    = "allanime.day"

# ── GQL queries (single-line — multiline breaks the API) ──────────────────────
_Q_SHOWS = "query($search:SearchInput $limit:Int $page:Int $translationType:VaildTranslationTypeEnumType $countryOrigin:VaildCountryOriginEnumType){shows(search:$search limit:$limit page:$page translationType:$translationType countryOrigin:$countryOrigin){edges{_id name englishName nativeName thumbnail score type season availableEpisodes}}}"

_Q_EPISODES = "query($showId:String!){show(_id:$showId){_id description thumbnail availableEpisodesDetail}}"

_Q_STREAM = "query($showId:String! $translationType:VaildTranslationTypeEnumType! $episodeString:String!){episode(showId:$showId translationType:$translationType episodeString:$episodeString){episodeString sourceUrls}}"

_GENRES = [
    "Action", "Adventure", "Comedy", "Drama", "Ecchi", "Fantasy", "Horror", 
    "Mahou Shoujo", "Mecha", "Music", "Mystery", "Psychological", "Romance", 
    "Sci-Fi", "Slice of Life", "Sports", "Supernatural", "Thriller"
]

_PROVIDER_PRIORITY = {
    "auto": ["Default", "S-mp4", "Luf-Mp4", "Yt-mp4"],
    "default": ["Default", "S-mp4", "Luf-Mp4", "Yt-mp4"],
    "sharepoint": ["S-mp4", "Default", "Luf-Mp4", "Yt-mp4"],
    "hianime": ["Luf-Mp4", "Default", "S-mp4", "Yt-mp4"],
    "youtube": ["Yt-mp4", "Default", "S-mp4", "Luf-Mp4"],
}

# ── Hex-decode table (from ani-cli provider_init) ─────────────────────────────
_HEX = {
    "79":"A","7a":"B","7b":"C","7c":"D","7d":"E","7e":"F","7f":"G","70":"H",
    "71":"I","72":"J","73":"K","74":"L","75":"M","76":"N","77":"O","68":"P",
    "69":"Q","6a":"R","6b":"S","6c":"T","6d":"U","6e":"V","6f":"W","60":"X",
    "61":"Y","62":"Z","59":"a","5a":"b","5b":"c","5c":"d","5d":"e","5e":"f",
    "5f":"g","50":"h","51":"i","52":"j","53":"k","54":"l","55":"m","56":"n",
    "57":"o","48":"p","49":"q","4a":"r","4b":"s","4c":"t","4d":"u","4e":"v",
    "4f":"w","40":"x","41":"y","42":"z","08":"0","09":"1","0a":"2","0b":"3",
    "0c":"4","0d":"5","0e":"6","0f":"7","00":"8","01":"9","15":"-","16":".",
    "67":"_","46":"~","02":":","17":"/","07":"?","1b":"#","63":"[","65":"]",
    "78":"@","19":"!","1c":"$","1e":"&","10":"(","11":")","12":"*","13":"+",
    "14":",","03":";","05":"=","1d":"%",
}

def _decode_url(encoded):
    pairs = [encoded[i:i+2] for i in range(0, len(encoded), 2)]
    return "".join(_HEX.get(p, p) for p in pairs).replace("/clock", "/clock.json")

# ── HTTP ──────────────────────────────────────────────────────────────────────
def _gql(variables, query):
    body = json.dumps({"variables": variables, "query": query},
                      separators=(",", ":")).encode()
    req = urllib.request.Request(API, data=body, headers={
        "Content-Type": "application/json",
        "Referer":      REFERER,
        "User-Agent":   AGENT,
    })
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read().decode())

def _fetch(url):
    req = urllib.request.Request(url, headers={
        "Referer":    REFERER,
        "User-Agent": AGENT,
    })
    with urllib.request.urlopen(req, timeout=15) as r:
        return r.read().decode(errors="replace")

# ── Normalise ─────────────────────────────────────────────────────────────────
def _normalise(edge):
    thumb = edge.get("thumbnail") or ""

    avail = edge.get("availableEpisodes") or {}
    return {
        "id":          edge.get("_id", ""),
        "name":        edge.get("name", ""),
        "englishName": edge.get("englishName") or edge.get("name", ""),
        "nativeName":  edge.get("nativeName", ""),
        "thumbnail":   thumb,
        "score":       edge.get("score"),
        "type":        edge.get("type", ""),
        "availableEpisodes": {
            "sub": avail.get("sub", 0),
            "dub": avail.get("dub", 0),
            "raw": avail.get("raw", 0),
        },
        "season": edge.get("season"),
    }

def _shows(search_obj, page, mode, country="ALL"):
    data = _gql({
        "search":          search_obj,
        "limit":           40,
        "page":            page,
        "translationType": mode,
        "countryOrigin":   country,
    }, _Q_SHOWS)
    edges = (data.get("data") or {}).get("shows", {}).get("edges") or []
    results = [_normalise(e) for e in edges]
    print(json.dumps({"results": results, "hasNextPage": len(results) == 40}))

# ── Commands ──────────────────────────────────────────────────────────────────
def cmd_popular(page=1, mode="sub", genre=None):
    search = {"allowAdult": False, "allowUnknown": False}
    if genre:
        search["genres"] = [genre]
    _shows(search, page, mode)

def cmd_latest(page=1, mode="sub", country="ALL"):
    _shows({"allowAdult": False, "allowUnknown": False, "sortBy": "latest"}, page, mode, country)

def cmd_search(query, mode="sub", page=1, genre=None):
    search = {"allowAdult": False, "allowUnknown": False, "query": query}
    if genre:
        search["genres"] = [genre]
    _shows(search, page, mode)

def cmd_genres():
    print(json.dumps(_GENRES))

def cmd_episodes(show_id, mode="sub"):
    data = _gql({"showId": show_id}, _Q_EPISODES)
    show = (data.get("data") or {}).get("show") or {}
    detail = show.get("availableEpisodesDetail") or {}
    eps = detail.get(mode) or []
    episodes = [{"id": f"{show_id}-episode-{ep}", "number": ep} for ep in eps]
    # Clean HTML entities from description
    import html
    desc = html.unescape(show.get("description") or "")
    # Strip remaining HTML tags
    import re
    desc = re.sub(r"<[^>]+>", " ", desc).strip()
    desc = re.sub(r" {2,}", " ", desc)
    print(json.dumps({
        "episodes": episodes,
        "episodeDetail": detail,
        "description": desc,
        "thumbnail": show.get("thumbnail") or "",
    }))

def _pick_quality(links, quality_pref):
    def _res(pair):
        try:
            return int(pair[1].rstrip("p"))
        except Exception:
            return 0

    links = sorted(links, key=_res, reverse=True)
    if quality_pref == "best":
        return links[0]

    try:
        target = int(str(quality_pref).rstrip("p"))
    except Exception:
        return links[0]

    at_or_below = [pair for pair in links if _res(pair) <= target]
    if at_or_below:
        return at_or_below[0]
    return links[-1]

def cmd_stream(show_id, ep_num, mode="sub", provider_pref="auto", quality_pref="best"):
    data = _gql({
        "showId": show_id,
        "translationType": mode,
        "episodeString": ep_num,
    }, _Q_STREAM)

    ep = ((data.get("data") or {}).get("episode")) or {}
    source_urls = ep.get("sourceUrls") or []

    # Build name->encoded_url map
    sources = {}
    for s in source_urls:
        name = s.get("sourceName", "")
        url  = s.get("sourceUrl",  "")
        if name and url:
            sources[name] = url

    for provider in _PROVIDER_PRIORITY.get(provider_pref, _PROVIDER_PRIORITY["auto"]):
        raw = sources.get(provider)
        if not raw or not raw.startswith("--"):
            continue
        decoded = _decode_url(raw[2:])
        if not decoded:
            continue
        provider_url = f"https://{BASE}{decoded}"

        try:
            resp = _fetch(provider_url)
        except Exception:
            continue

        # Get metadata for the UI
        show_data = _gql({"showId": show_id}, _Q_EPISODES)
        show = (show_data.get("data") or {}).get("show") or {}
        title = show.get("englishName") or show.get("name") or "Unknown"

        metadata = {
            "title": title,
            "episode": ep_num,
            "showId": show_id
        }
        headers = {
            "User-Agent": AGENT,
            "Referer": REFERER
        }

        # mp4 links with resolution
        links = re.findall(r'"link":"([^"]+)"[^}]*"resolutionStr":"([^"]+)"', resp)
        if links:
            url, res = _pick_quality(links, quality_pref)
            if "repackager.wixmp.com" in url:
                url = re.sub(r"repackager\.wixmp\.com/", "", url)
                url = re.sub(r"\.urlset.*", "", url)
            print(json.dumps({
                "url": url, "referer": REFERER, "type": "mp4",
                "quality": res, "provider": provider,
                "http_headers": headers, "metadata": metadata
            }))
            return

        # HLS fallback
        hls = re.search(r'"url":"(https?://[^"]+master\.m3u8[^"]*)"', resp)
        if hls:
            refm = re.search(r'"Referer":"([^"]+)"', resp)
            final_referer = refm.group(1) if refm else REFERER
            headers["Referer"] = final_referer
            print(json.dumps({
                "url": hls.group(1),
                "referer": final_referer,
                "type": "hls", "provider": provider,
                "http_headers": headers, "metadata": metadata
            }))
            return

    print(json.dumps({"error": "No working stream source found"}))
    sys.exit(1)

# ── Entry point ───────────────────────────────────────────────────────────────
def main():
    args = sys.argv[1:]
    if not args:
        print(json.dumps({"error": "No command given"}))
        sys.exit(1)
    cmd = args[0]
    try:
        if cmd == "search":
            cmd_search(
                args[1] if len(args) > 1 else "",
                args[2] if len(args) > 2 else "sub",
                int(args[3]) if len(args) > 3 else 1,
                args[4] if len(args) > 4 else None
            )
        elif cmd == "popular":
            cmd_popular(
                int(args[1]) if len(args) > 1 else 1,
                args[2] if len(args) > 2 else "sub",
                args[3] if len(args) > 3 else None
            )
        elif cmd == "latest":
            cmd_latest(
                int(args[1]) if len(args) > 1 else 1,
                args[2] if len(args) > 2 else "sub",
                args[3] if len(args) > 3 else "ALL",
            )
        elif cmd == "genres":
            cmd_genres()
        elif cmd == "episodes":
            cmd_episodes(
                args[1],
                args[2] if len(args) > 2 else "sub",
            )
        elif cmd == "stream":
            cmd_stream(
                args[1],
                args[2],
                args[3] if len(args) > 3 else "sub",
                args[4] if len(args) > 4 else "auto",
                args[5] if len(args) > 5 else "best",
            )
        else:
            print(json.dumps({"error": f"Unknown command: {cmd}"}))
            sys.exit(1)
    except IndexError:
        print(json.dumps({"error": f"Missing argument for: {cmd}"}))
        sys.exit(1)
    except urllib.error.HTTPError as e:
        print(json.dumps({"error": f"HTTP Error {e.code}: {e.reason}"}))
        sys.exit(1)
    except urllib.error.URLError as e:
        print(json.dumps({"error": f"Network error: {e}"}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
