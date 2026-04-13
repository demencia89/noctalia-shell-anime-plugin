import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

Item {
    id: detailView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null

    signal backRequested()

    readonly property bool _inLibrary:
        anime && anime.currentAnime ? anime.isInLibrary(anime.currentAnime.id) : false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: Color.mSurfaceVariant
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 10 }
                spacing: 2

                // Back button
                Item {
                    width: 44; height: 44

                    Rectangle {
                        anchors.centerIn: parent; width: 34; height: 34; radius: 17
                        color: backArea.containsMouse ? Color.mSurface : "transparent"
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "←"; font.pixelSize: 18; color: Color.mOnSurfaceVariant
                    }
                    MouseArea {
                        id: backArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: detailView.backRequested()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: anime?.currentAnime
                        ? (anime.currentAnime.englishName || anime.currentAnime.name || "")
                        : ""
                    font.pixelSize: 13; color: Color.mOnSurface; elide: Text.ElideRight
                }

                // Library button
                Item {
                    visible: anime?.currentAnime != null
                    width: libBtnLabel.implicitWidth + 28; height: 32

                    Rectangle {
                        anchors.fill: parent; radius: height / 2
                        color: detailView._inLibrary ? Color.mPrimaryContainer : Color.mSurface
                        border.color: detailView._inLibrary ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    Row {
                        anchors.centerIn: parent; spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailView._inLibrary ? "✓" : "+"
                            font.pixelSize: 11; font.bold: true
                            color: detailView._inLibrary ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                        }
                        Text {
                            id: libBtnLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Library"
                            font.pixelSize: 11; font.letterSpacing: 0.3
                            color: detailView._inLibrary ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!anime?.currentAnime) return
                            if (detailView._inLibrary)
                                anime.removeFromLibrary(anime.currentAnime.id)
                            else
                                anime.addToLibrary(anime.currentAnime)
                        }
                    }
                }
            }
        }

        // ── Episode count / last watched sub-bar ──────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 34
            color: Color.mSurface
            visible: anime?.currentAnime != null

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }

                Text {
                    text: {
                        var eps = anime?.currentAnime?.episodes
                        return eps ? (eps.length + " episodes") : ""
                    }
                    font.pixelSize: 11; font.letterSpacing: 1
                    color: Color.mOnSurfaceVariant; opacity: 0.75
                }

                Item { Layout.fillWidth: true }

                // Last-watched badge
                Rectangle {
                    readonly property var _entry: anime?.currentAnime
                        ? anime.getLibraryEntry(anime.currentAnime.id) : null
                    visible: _entry !== null && _entry !== undefined
                        && (_entry.lastWatchedEpNum || "") !== ""
                    height: 20; width: lastWatchedText.implicitWidth + 18; radius: 10
                    color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)
                    border.color: Color.mPrimary; border.width: 1

                    Text {
                        id: lastWatchedText; anchors.centerIn: parent
                        text: {
                            var e = anime?.currentAnime
                                ? anime.getLibraryEntry(anime.currentAnime.id) : null
                            return e ? "Last: Ep. " + e.lastWatchedEpNum : ""
                        }
                        font.pixelSize: 9; font.letterSpacing: 0.8; color: Color.mPrimary
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.3
            }
        }

        // ── Hero: thumbnail + description ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 160
            color: Color.mSurface
            clip: true
            visible: anime?.currentAnime != null

            // Blurred background from thumbnail
            Image {
                anchors.fill: parent
                source: anime?.currentAnime?.thumbnail ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: 0.15
                layer.enabled: true
                layer.effect: null
            }

            // Dark gradient overlay
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.0) }
                    GradientStop { position: 0.5; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.38) }
                    GradientStop { position: 1.0; color: Color.mSurface }
                }
            }

            Row {
                anchors { fill: parent; margins: 12 }
                spacing: 12

                // Thumbnail
                Rectangle {
                    width: 100; height: 136
                    radius: 8; clip: true
                    color: Color.mSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: anime?.currentAnime?.thumbnail ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // Description
                Item {
                    width: parent.width - 124
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors { fill: parent; topMargin: 4 }
                        text: anime?.currentAnime?.description ?? ""
                        color: Color.mOnSurface
                        font.pixelSize: 11
                        lineHeight: 1.4
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 8
                        opacity: 0.85
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.3
            }
        }

        // ── Episode list ──────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            // Fetching detail spinner
            Rectangle {
                anchors.fill: parent; color: "transparent"
                visible: anime?.isFetchingDetail ?? false; z: 5

                Column {
                    anchors.centerIn: parent; spacing: 14

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"; border.color: Color.mPrimary; border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching episodes"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11; font.letterSpacing: 2; opacity: 0.7
                    }
                }
            }

            // Fetching stream spinner
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.68)
                visible: anime?.isFetchingLinks ?? false; z: 6

                Column {
                    anchors.centerIn: parent; spacing: 14

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"; border.color: Color.mPrimary; border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching stream"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11; font.letterSpacing: 2; opacity: 0.7
                    }
                }
            }

            // Error toast
            Rectangle {
                anchors {
                    bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                    bottomMargin: 12
                }
                height: 36; radius: 18
                width: linksErrText.implicitWidth + 28
                color: Color.mErrorContainer
                visible: (anime?.linksError?.length ?? 0) > 0 && !(anime?.isFetchingLinks ?? false)
                z: 7

                Text {
                    id: linksErrText; anchors.centerIn: parent
                    text: anime?.linksError ?? ""
                    font.pixelSize: 11; color: Color.mOnErrorContainer; elide: Text.ElideRight
                }
            }

            ListView {
                id: epList
                anchors.fill: parent; clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: anime?.currentAnime?.episodes ?? []

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3; color: Color.mPrimary; opacity: 0.45; radius: 2
                    }
                }

                delegate: Rectangle {
                    width: epList.width; height: 52

                    readonly property var _libEntry: {
                        var _ = anime?.libraryVersion ?? 0  // reactive trigger
                        return anime?.currentAnime
                            ? anime.getLibraryEntry(anime.currentAnime.id) : null
                    }
                    readonly property bool isLastWatched:
                        _libEntry !== null && _libEntry !== undefined
                        && _libEntry.lastWatchedEpNum === String(modelData.number)
                    readonly property bool isWatched:
                        (anime?.libraryVersion ?? 0) >= 0 &&
                        (anime?.isEpisodeWatched(anime?.currentAnime?.id ?? "", modelData.number) ?? false)
                    readonly property bool hasProgress:
                        !isWatched &&
                        (anime?.libraryVersion ?? 0) >= 0 &&
                        (anime?.hasEpisodeProgress(anime?.currentAnime?.id ?? "", modelData.number) ?? false)

                    color: isLastWatched
                        ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.07)
                        : (epRowArea.pressed
                            ? Color.mSurfaceVariant
                            : (epRowArea.containsMouse ? Color.mSurface : "transparent"))
                    opacity: isWatched && !isLastWatched ? 0.5 : 1.0
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left; right: parent.right
                            leftMargin: 64; rightMargin: 16
                        }
                        height: 1; color: Color.mOutlineVariant; opacity: 0.22
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 14

                        Rectangle {
                            width: epPillText.implicitWidth + 16; height: 26; radius: 13
                            color: (isLastWatched || isWatched) ? Color.mPrimary : Color.mPrimaryContainer

                            Text {
                                id: epPillText; anchors.centerIn: parent
                                text: "Ep." + (modelData.number || "?")
                                font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.5
                                color: (isLastWatched || isWatched) ? Color.mOnPrimary : Color.mOnPrimaryContainer
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Episode " + (modelData.number || "")
                            font.pixelSize: 12; color: Color.mOnSurface; elide: Text.ElideRight
                        }

                        // In-progress dot
                        Rectangle {
                            visible: hasProgress
                            width: 6; height: 6; radius: 3
                            color: Color.mTertiary
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: 0.9
                        }

                        Text {
                            text: isWatched ? "✓" : "▶"
                            font.pixelSize: isWatched ? 14 : 13
                            font.bold: isWatched
                            color: isWatched
                                ? Color.mPrimary
                                : hasProgress
                                    ? Color.mTertiary
                                    : (epRowArea.containsMouse ? Color.mPrimary : Color.mOutline)
                            opacity: isWatched ? 0.8
                                : hasProgress ? 0.9
                                : (epRowArea.containsMouse ? 0.9 : 0.35)
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on color   { ColorAnimation  { duration: 120 } }
                        }
                    }

                    MouseArea {
                        id: epRowArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (!anime?.currentAnime) return
                            if (!anime.isInLibrary(anime.currentAnime.id)) {
                                // Not in library yet — add and record episode atomically
                                anime.addToLibraryWithEpisode(
                                    anime.currentAnime,
                                    modelData.id,
                                    modelData.number
                                )
                            } else {
                                // Already in library — just update the episode
                                anime.updateLastWatched(
                                    anime.currentAnime.id,
                                    modelData.id,
                                    modelData.number
                                )
                            }
                            anime.fetchStreamLinks(
                                anime.currentAnime.id,
                                modelData.number,
                                "best"
                            )
                        }
                    }
                }
            }
        }
    }

    // ── React to selectedLink ─────────────────────────────────────────────────
    Connections {
        target: anime
        enabled: anime !== null

        function onSelectedLinkChanged() {
            if (!anime?.selectedLink) return
            var lnk = anime.selectedLink
            if (!lnk.url || lnk.url.length === 0) {
                anime.clearStreamLinks()
                return
            }
            var title = anime.currentAnime
                ? (anime.currentAnime.englishName || anime.currentAnime.name)
                  + " — Ep." + anime.currentEpisode
                : ""
            if (anime) anime.playWithMpv(lnk.url, lnk.referer, title)
            anime.clearStreamLinks()
        }
    }
}
