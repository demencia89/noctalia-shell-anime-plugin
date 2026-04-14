import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Commons
import qs.Widgets

Item {
    id: browseView

    property var pluginApi: null
    readonly property var anime: pluginApi?.mainInstance || null

    signal animeSelected(var show)
    signal settingsRequested()

    // ── Background ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "transparent"
            z: 2

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1; color: Color.mOutlineVariant; opacity: 0.5
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 10 }
                spacing: 8

                // Wordmark (hidden when search is open)
                Rectangle {
                    visible: !searchBar.visible
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
                            font.pixelSize: 22; font.letterSpacing: 1
                            color: Color.mPrimary
                        }
                        Text {
                            text: "nime"
                            font.pixelSize: 22; font.letterSpacing: 1
                            color: Color.mOnSurface; opacity: 0.85
                        }
                    }
                }

                // Search bar
                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    height: 36; radius: 18
                    color: Color.mSurface
                    visible: false
                    border.color: searchField.activeFocus ? Color.mPrimary : Color.mOutlineVariant
                    border.width: searchField.activeFocus ? 1.5 : 1

                    TextInput {
                        id: searchField
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left; right: clearBtn.left
                            leftMargin: 14; rightMargin: 6
                        }
                        color: Color.mOnSurface
                        font.pixelSize: 13
                        clip: true
                        onTextChanged: searchDebounce.restart()
                        Keys.onEscapePressed: {
                            searchBar.visible = false
                            text = ""
                            if (anime) anime.fetchPopular(true)
                        }
                    }

                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
                        text: "Search anime…"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 13
                        visible: searchField.text.length === 0
                        opacity: 0.6
                    }

                    Item {
                        id: clearBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
                        width: 22; height: 22
                        visible: searchField.text.length > 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18; height: 18; radius: 9
                            color: Color.mSurfaceVariant
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Color.mOnSurfaceVariant
                            font.pixelSize: 9; font.bold: true
                        }
                        MouseArea { anchors.fill: parent; onClicked: searchField.text = "" }
                    }
                }

                Timer {
                    id: searchDebounce
                    interval: 350
                    onTriggered: {
                        if (!anime) return
                        if (searchField.text.trim().length > 0)
                            anime.searchAnime(searchField.text.trim(), true)
                        else
                            anime.fetchPopular(true)
                    }
                }

                // Search toggle
                Item {
                    width: 38; height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32; height: 32; radius: 16
                        color: searchBar.visible ? Color.mPrimaryContainer : "transparent"
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "⌕"; font.pixelSize: 18
                        color: searchBar.visible ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchBar.visible = !searchBar.visible
                            if (searchBar.visible) searchField.forceActiveFocus()
                            else {
                                searchField.text = ""
                                if (anime) anime.fetchPopular(true)
                            }
                        }
                    }
                }

                // Sub / Dub toggle
                Rectangle {
                    height: 28
                    width: modeRow.implicitWidth + 16
                    radius: 14
                    color: Color.mSurface
                    border.color: Color.mOutlineVariant; border.width: 1

                    Row {
                        id: modeRow
                        anchors.centerIn: parent
                        spacing: 0

                        Repeater {
                            model: ["sub", "dub"]

                            delegate: Item {
                                width: modeLabel.implicitWidth + 16
                                height: 28
                                readonly property bool active: anime?.currentMode === modelData

                                Rectangle {
                                    anchors { fill: parent; margins: 3 }
                                    radius: 11
                                    color: active ? Color.mPrimary : "transparent"
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                }
                                Text {
                                    id: modeLabel
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    font.pixelSize: 10; font.letterSpacing: 1; font.bold: true
                                    color: active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (anime) anime.setMode(modelData)
                                }
                            }
                        }
                    }
                }

                Item {
                    width: 38; height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32; height: 32; radius: 16
                        color: settingsArea.containsMouse
                            ? Color.mPrimaryContainer
                            : "transparent"
                        border.width: settingsArea.containsMouse ? 1 : 0
                        border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.25)
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 15
                        color: settingsArea.containsMouse
                            ? Color.mOnPrimaryContainer
                            : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: browseView.settingsRequested()
                    }
                }
            }
        }

        // ── Genre selector ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: (anime?.genresList?.length ?? 0) > 0 ? 56 : 0
            color: "transparent"
            visible: height > 0
            clip: true

            ListView {
                id: genreList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 8
                leftMargin: 18; rightMargin: 18
                model: ["All"].concat(anime?.genresList || [])
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                delegate: Item {
                    width: genreLabel.implicitWidth + 28
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property bool active: (modelData === "All" && (anime?.currentGenre ?? "") === "") ||
                                                   (anime?.currentGenre === modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: active ? Color.mPrimary : Color.mSurfaceVariant
                        border.color: active ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Text {
                        id: genreLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 11; font.bold: active
                        color: active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (anime) {
                                anime.setGenre(modelData === "All" ? "" : modelData)
                            }
                        }
                    }
                }

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        genreList.flick(wheel.angleDelta.y * 5, 0)
                    }
                }
            }
            
            // Subtle gradient on right to indicate more items
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 32
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Color.mSurface }
                }
                opacity: genreList.atEnd ? 0 : 0.8
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        // ── Content area ──────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading
            Rectangle {
                anchors.fill: parent; color: "transparent"
                visible: (anime?.isFetchingAnime ?? false) && (anime?.animeList?.length ?? 0) === 0
                z: 10

                Column {
                    anchors.centerIn: parent; spacing: 14

                    Rectangle {
                        width: 34; height: 34; radius: 17
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"
                        border.color: Color.mPrimary; border.width: 2.5
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "loading"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11; font.letterSpacing: 2.5; opacity: 0.7
                    }
                }
            }

            // Error
            Rectangle {
                anchors.fill: parent; color: "transparent"
                visible: (anime?.animeError?.length ?? 0) > 0 && !(anime?.isFetchingAnime ?? false)
                z: 9

                Column {
                    anchors.centerIn: parent; spacing: 10

                    Text {
                        text: "⚠"; font.pixelSize: 30; color: Color.mError
                        anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.8
                    }
                    Text {
                        text: anime?.animeError ?? ""
                        color: Color.mOnSurfaceVariant; font.pixelSize: 12
                        wrapMode: Text.Wrap; width: 280
                        horizontalAlignment: Text.AlignHCenter; lineHeight: 1.4
                    }
                }
            }

            // Grid
            GridView {
                id: animeGrid
                anchors.fill: parent; anchors.margins: 10
                
                readonly property var columnsMap: ({ "small": 8, "medium": 5, "large": 3 })
                readonly property int columns: columnsMap[anime?.posterSize || "medium"]
                
                cellWidth: (width - 10) / columns
                cellHeight: cellWidth * 1.58
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: anime?.animeList ?? []

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3; color: Color.mPrimary; opacity: 0.45; radius: 2
                    }
                }

                onContentYChanged: {
                    if (contentY + height > contentHeight - cellHeight * 2)
                        if (anime) anime.fetchNextPage()
                }

                delegate: Item {
                    width: animeGrid.cellWidth
                    height: animeGrid.cellHeight

                    readonly property bool inLibrary: {
                        var _ = anime?.libraryVersion ?? 0
                        return anime?.isInLibrary(modelData.id) ?? false
                    }
                    readonly property bool cardHovered: cardArea.containsMouse || libraryActionArea.containsMouse
                    readonly property bool showLibraryAction: inLibrary || cardHovered
                    readonly property bool actionIsRemove: inLibrary && cardHovered

                    Rectangle {
                        id: card
                        anchors { fill: parent; margins: 5 }
                        radius: 10; color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.45)
                        clip: true

                        // Title bar (defined before wrapper so it can be referenced if needed)
                        Rectangle {
                            id: titleBar
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: titleText.implicitHeight + 14
                            color: Color.mSurfaceVariant; radius: 10

                            Text {
                                id: titleText
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8; rightMargin: 8
                                }
                                text: modelData.englishName || modelData.name || ""
                                font.pixelSize: 10; font.letterSpacing: 0.2
                                color: Color.mOnSurface
                                wrapMode: Text.Wrap; maximumLineCount: 2
                                elide: Text.ElideRight; lineHeight: 1.3
                            }
                        }

                        // Poster Wrapper
                        Rectangle {
                            id: posterWrapper
                            anchors { top: parent.top; left: parent.left; right: parent.right; bottom: titleBar.top }
                            radius: 10; clip: true; color: "transparent"
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: posterWrapper.width
                                    height: posterWrapper.height
                                    radius: posterWrapper.radius
                                }
                            }

                            Image {
                                id: coverImg
                                anchors.fill: parent
                                source: modelData.thumbnail || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true; cache: true
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                Rectangle {
                                    anchors.fill: parent; color: Color.mSurfaceVariant
                                    visible: coverImg.status !== Image.Ready
                                    Text {
                                        anchors.centerIn: parent; text: "◫"
                                        font.pixelSize: 28; color: Color.mOutline; opacity: 0.25
                                    }
                                }

                                // Score badge
                                Rectangle {
                                    visible: modelData.score != null
                                    anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                                    height: 18; radius: 9
                                    width: scoreText.implicitWidth + 10
                                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                                    border.width: 1
                                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.38)

                                    Text {
                                        id: scoreText; anchors.centerIn: parent
                                        text: modelData.score != null ? "★ " + (modelData.score || 0).toFixed(1) : ""
                                        font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.5
                                        color: Color.mPrimary
                                    }
                                }

                                // Type badge
                                Rectangle {
                                    visible: (modelData.type || "").length > 0
                                    anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                                    height: 18; radius: 9
                                    width: typeText.implicitWidth + 10
                                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.86)
                                    border.width: 1
                                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.36)

                                    Text {
                                        id: typeText; anchors.centerIn: parent
                                        text: (modelData.type || "").toUpperCase()
                                        font.pixelSize: 8; font.letterSpacing: 1; font.bold: true
                                        color: Color.mPrimary
                                    }
                                }

                                // Episode count badge
                                Rectangle {
                                    visible: modelData.availableEpisodes &&
                                        ((modelData.availableEpisodes.sub > 0) ||
                                         (modelData.availableEpisodes.dub > 0))
                                    anchors {
                                        bottom: parent.bottom; right: parent.right
                                        bottomMargin: 6; rightMargin: 6
                                    }
                                    height: 18; radius: 9
                                    width: epText.implicitWidth + 10
                                    color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.88)
                                    border.width: 1
                                    border.color: Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.38)

                                    Text {
                                        id: epText; anchors.centerIn: parent
                                        text: {
                                            var avail = modelData.availableEpisodes
                                            var n = (anime?.currentMode === "dub") ? avail.dub : avail.sub
                                            return n + " ep"
                                        }
                                        font.pixelSize: 8; font.letterSpacing: 0.5
                                        color: Color.mOnSurface
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
                        }

                        // Library action
                        Rectangle {
                            id: libraryAction
                            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                            width: 32
                            height: 32
                            radius: 16
                            opacity: showLibraryAction ? 1 : 0
                            scale: showLibraryAction ? 1 : 0.82
                            visible: opacity > 0
                            color: inLibrary
                                ? (actionIsRemove
                                    ? Qt.rgba(Color.mErrorContainer.r, Color.mErrorContainer.g, Color.mErrorContainer.b, 0.96)
                                    : Color.mPrimary)
                                : Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.92)
                            border.width: 1
                            border.color: inLibrary
                                ? (actionIsRemove ? Color.mError : Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.6))
                                : Qt.rgba(Color.mOutlineVariant.r, Color.mOutlineVariant.g, Color.mOutlineVariant.b, 0.42)
                            z: 3

                            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            ToolTip.visible: libraryActionArea.containsMouse
                            ToolTip.text: inLibrary ? "Remove from library" : "Add to library"

                            NIcon {
                                id: bookmarkIcon
                                anchors.centerIn: parent
                                icon: "bookmark"
                                pointSize: 14
                                color: Color.mOnPrimary
                                opacity: inLibrary && !actionIsRemove ? 1 : 0
                                scale: inLibrary && !actionIsRemove ? 1 : 0.7
                                Behavior on opacity { NumberAnimation { duration: 110 } }
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                            }

                            Text {
                                id: addIcon
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 18
                                font.bold: true
                                color: Color.mPrimary
                                opacity: !inLibrary && cardHovered ? 1 : 0
                                scale: !inLibrary && cardHovered ? 1 : 0.7
                                Behavior on opacity { NumberAnimation { duration: 110 } }
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                            }

                            Text {
                                id: removeIcon
                                anchors.centerIn: parent
                                text: "−"
                                font.pixelSize: 18
                                font.bold: true
                                color: Color.mOnErrorContainer
                                opacity: actionIsRemove ? 1 : 0
                                scale: actionIsRemove ? 1 : 0.7
                                Behavior on opacity { NumberAnimation { duration: 110 } }
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: libraryActionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (!anime) return
                                    if (inLibrary)
                                        anime.removeFromLibrary(modelData.id)
                                    else
                                        anime.addToLibrary(modelData)
                                }
                            }
                        }

                        // Hover/press overlay
                        Rectangle {
                            anchors.fill: parent; radius: 10; color: Color.mPrimary
                            opacity: cardArea.pressed ? 0.16 : (cardArea.containsMouse ? 0.07 : 0)
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }

                        transform: Scale {
                            origin.x: card.width / 2; origin.y: card.height / 2
                            xScale: cardArea.pressed ? 0.97 : 1.0
                            yScale: cardArea.pressed ? 0.97 : 1.0
                            Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: browseView.animeSelected(modelData)
                        }
                    }
                }
            }
        }
    }
}
