import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: libraryView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null

    signal animeSelected(var show)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: Color.mSurfaceVariant
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 10 }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 19
                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                    border.width: 1
                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        spacing: 0

                        Text {
                            text: "A"
                            font.pixelSize: 20
                            font.letterSpacing: 1
                            color: Color.mPrimary
                        }
                        Text {
                            text: "nime Library"
                            font.pixelSize: 20
                            font.letterSpacing: 1
                            color: Color.mOnSurface
                            opacity: 0.85
                        }
                    }
                }

                Rectangle {
                    visible: (anime?.libraryList?.length ?? 0) > 0
                    height: 30
                    width: libCountText.implicitWidth + 20
                    radius: 15
                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.92)
                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.42)
                    border.width: 1

                    Text {
                        id: libCountText; anchors.centerIn: parent
                        text: (anime?.libraryList?.length ?? 0) + " saved"
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                        color: Color.mOnSurfaceVariant
                    }
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: (anime?.libraryList?.length ?? 0) === 0 && (anime?.libraryLoaded ?? false)

            Rectangle {
                width: Math.min(parent.width - 28, 340)
                anchors.centerIn: parent
                radius: 20
                color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.86)
                border.width: 1
                border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.4)
                implicitHeight: emptyColumn.implicitHeight + 34

                Column {
                    id: emptyColumn
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 42
                        height: 42
                        radius: 21
                        color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "⊡"
                            font.pixelSize: 19
                            color: Color.mPrimary
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Your library is empty"
                        font.pixelSize: 15
                        font.bold: true
                        color: Color.mOnSurface
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        lineHeight: 1.35
                        text: "Open an anime from Browse and tap + Library to keep track of what you are watching."
                        font.pixelSize: 11
                        color: Color.mOnSurfaceVariant
                        opacity: 0.74
                        font.letterSpacing: 0.2
                    }
                }
            }
        }

        // ── Loading ───────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: !(anime?.libraryLoaded ?? true)

            Rectangle {
                width: 28; height: 28; radius: 14
                anchors.centerIn: parent
                color: "transparent"; border.color: Color.mPrimary; border.width: 2
                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite; running: parent.visible
                    easing.type: Easing.Linear
                }
            }
        }

        // ── Library grid ──────────────────────────────────────────────────────
        GridView {
            id: libGrid
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: (anime?.libraryList?.length ?? 0) > 0
            topMargin: 10; leftMargin: 8; rightMargin: 8; bottomMargin: 10
            
            readonly property var columnsMap: ({ "small": 8, "medium": 5, "large": 3 })
            readonly property int columns: columnsMap[anime?.posterSize || "medium"]
            
            cellWidth: Math.floor((width - leftMargin - rightMargin) / columns)
            cellHeight: cellWidth * 1.78
            clip: true; boundsBehavior: Flickable.StopAtBounds
            model: {
                var _ = anime?.libraryVersion ?? 0  // reactive trigger
                return anime?.libraryList ?? []
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3; color: Color.mPrimary; opacity: 0.45; radius: 2
                }
            }

            delegate: Item {
                width: libGrid.cellWidth
                height: libGrid.cellHeight

                readonly property var entry: modelData

                Rectangle {
                    id: libCard
                    anchors { fill: parent; margins: 5 }
                    radius: 10; color: Color.mSurfaceVariant; clip: true

                    // Cover
                    Image {
                        id: libCover
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: parent.height - libTitleBar.height - libEpBar.height
                        source: entry.thumbnail || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        Rectangle {
                            anchors.fill: parent; color: Color.mSurfaceVariant
                            visible: libCover.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent; text: "◫"
                                font.pixelSize: 28; color: Color.mOutline; opacity: 0.25
                            }
                        }

                        // Score badge
                        Rectangle {
                            visible: entry.score != null
                            anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                            height: 18; radius: 9; width: libScoreText.implicitWidth + 10
                            color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                            border.width: 1
                            border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.38)

                            Text {
                                id: libScoreText; anchors.centerIn: parent
                                text: entry.score ? "★ " + (entry.score).toFixed(1) : ""
                                font.pixelSize: 8; font.bold: true
                                color: Color.mPrimary
                            }
                        }

                        // Gradient
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Color.mSurfaceVariant }
                            }
                        }
                    }

                    // Title bar
                    Rectangle {
                        id: libTitleBar
                        anchors { bottom: libEpBar.top; left: parent.left; right: parent.right }
                        height: libTitleText.implicitHeight + 10
                        color: Color.mSurfaceVariant

                        Text {
                            id: libTitleText
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8; rightMargin: 8
                            }
                            text: entry.englishName || entry.name || ""
                            font.pixelSize: 10; font.letterSpacing: 0.2
                            color: Color.mOnSurface
                            wrapMode: Text.Wrap; maximumLineCount: 2
                            elide: Text.ElideRight; lineHeight: 1.3
                        }
                    }

                    // Last-watched bar
                    Rectangle {
                        id: libEpBar
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 28; color: Color.mSurface; radius: 10

                        // Square off top corners
                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.radius; color: parent.color
                        }

                        Row {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left; leftMargin: 8
                            }
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▶"; font.pixelSize: 7
                                color: entry.lastWatchedEpNum ? Color.mPrimary : Color.mOutline
                                opacity: entry.lastWatchedEpNum ? 1 : 0.4
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.lastWatchedEpNum
                                    ? "Ep. " + entry.lastWatchedEpNum
                                    : "Not started"
                                font.pixelSize: 10; font.letterSpacing: 0.4
                                color: entry.lastWatchedEpNum
                                    ? Color.mOnSurface : Color.mOnSurfaceVariant
                                opacity: entry.lastWatchedEpNum ? 0.85 : 0.45
                            }

                            Rectangle {
                                visible: (entry.watchedEpisodes || []).length > 0
                                anchors.verticalCenter: parent.verticalCenter
                                height: 14; radius: 7
                                width: watchedCountText.implicitWidth + 8
                                color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.18)

                                Text {
                                    id: watchedCountText
                                    anchors.centerIn: parent
                                    text: "✓ " + (entry.watchedEpisodes || []).length
                                    font.pixelSize: 8; font.bold: true
                                    color: Color.mPrimary
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: libraryAction
                        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                        width: 32
                        height: 32
                        radius: 16
                        color: libraryActionArea.containsMouse
                            ? Qt.rgba(Color.mErrorContainer.r, Color.mErrorContainer.g, Color.mErrorContainer.b, 0.96)
                            : Color.mPrimary
                        border.width: 1
                        border.color: libraryActionArea.containsMouse
                            ? Color.mError
                            : Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.6)
                        z: 3

                        Behavior on color { ColorAnimation { duration: 140 } }
                        ToolTip.visible: libraryActionArea.containsMouse
                        ToolTip.text: "Remove from library"

                        NIcon {
                            anchors.centerIn: parent
                            icon: "bookmark"
                            pointSize: 14
                            color: Color.mOnPrimary
                            opacity: libraryActionArea.containsMouse ? 0 : 1
                            scale: libraryActionArea.containsMouse ? 0.7 : 1
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            font.pixelSize: 18
                            font.bold: true
                            color: Color.mOnErrorContainer
                            opacity: libraryActionArea.containsMouse ? 1 : 0
                            scale: libraryActionArea.containsMouse ? 1 : 0.7
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: libraryActionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: if (anime) anime.removeFromLibrary(entry.id)
                        }
                    }

                    // Hover/press overlay
                    Rectangle {
                        anchors.fill: parent; radius: 10; color: Color.mPrimary
                        opacity: libCardArea.pressed ? 0.16 : (libCardArea.containsMouse ? 0.07 : 0)
                        Behavior on opacity { NumberAnimation { duration: 130 } }
                    }

                    transform: Scale {
                        origin.x: libCard.width / 2; origin.y: libCard.height / 2
                        xScale: libCardArea.pressed ? 0.97 : 1.0
                        yScale: libCardArea.pressed ? 0.97 : 1.0
                        Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: libCardArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            libraryView.animeSelected({
                                id:               entry.id,
                                name:             entry.name,
                                englishName:      entry.englishName,
                                nativeName:       entry.nativeName  || "",
                                thumbnail:        entry.thumbnail,
                                score:            entry.score,
                                type:             entry.type        || "",
                                episodeCount:     entry.episodeCount || "",
                                availableEpisodes: entry.availableEpisodes || { sub: 0, dub: 0, raw: 0 },
                                season:           entry.season      || null
                            })
                        }
                    }
                }
            }
        }
    }
}
