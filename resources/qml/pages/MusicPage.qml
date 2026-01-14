import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../components" as Components

Item {
    id: musicPageRoot

    // === 接收依赖 ===
    property var theme
    property var toastRef
    property real viewportWidth

    // === 内部状态 ===
    property bool isPlaying: false
    property int currentSongIndex: 0
    property real progressValue: 0

    // === Tailwind 调色板 ===
    QtObject {
        id: tw
        property color bgFrom: "#1e1b4b"
        property color bgVia: "#581c87"
        property color bgTo: "#701a75"
        property color pink500: "#ec4899"
        property color purple500: "#a855f7"
        property color pink400: "#f472b6"
        property color purple400: "#c084fc"
        property color textPink: "#fbcfe8"
    }

    // 模拟数据
    ListModel {
        id: songModel
        ListElement { title: "Cyberpunk City"; artist: "Synthwave Boy"; cover: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=600"; duration: "3:45" }
        ListElement { title: "Midnight Rain"; artist: "Lo-Fi Beats"; cover: "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=600"; duration: "2:30" }
        ListElement { title: "Ocean Drive"; artist: "Summer Vibes"; cover: "https://images.unsplash.com/photo-1459749411177-0473ef4884f3?q=80&w=600"; duration: "4:12" }
    }

    // ============================================================
    // 主播放器卡片
    // ============================================================
    Components.EBlurCard {
        id: playerCard

        // 填满父容器
        anchors.fill: parent

        // 设为透明，移除边框颜色

        borderRadius: 24
        borderColor: "transparent"
        borderWidth: 0

        // 外部投影
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 20
            shadowVerticalOffset: 10
        }

        // ============================================================
        // 内容容器
        // ============================================================
        content: Item {
            anchors.fill: parent

            // 1. 背景层
            Rectangle {
                anchors.fill: parent
                radius: playerCard.borderRadius
                color: "transparent"
            }

            // 2. 播放器 UI 布局
            GridLayout {
                // 【核心修复】：使用 anchors.fill 替代 width: parent.width
                // 这样 margins 才会生效，向内收缩，防止溢出
                anchors.fill: parent
                anchors.margins: 40 // 增加边距，让内容离屏幕边缘远一点

                columns: width < 768 ? 1 : 2
                columnSpacing: 48
                rowSpacing: 24

                // --- 左侧：黑胶唱片 ---
                // --- 左侧：黑胶唱片 ---
                                Item {
                                    // 【核心修复】：必须给一个首选宽高，防止在 Grid 中被压缩为 0
                                    Layout.preferredWidth: 320
                                    Layout.preferredHeight: 320

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                    Rectangle {
                                        // 唱片大小逻辑：在父容器允许的范围内，最大 320
                                        property real size: Math.min(parent.width, parent.height, 320)

                                        width: size
                                        height: size
                                        radius: size / 2
                                        color: "#0f172a"
                                        border.width: 6
                                        border.color: "#1AFFFFFF"
                                        anchors.centerIn: parent

                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowBlur: 30
                                            shadowColor: "#80000000"
                                            shadowVerticalOffset: 15
                                        }

                                        // 遮罩源
                                        Item {
                                            id: discMask
                                            anchors.fill: parent
                                            visible: false
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: parent.width - 12; height: parent.height - 12
                                                radius: width / 2
                                                color: "black"
                                            }
                                        }

                                        Image {
                                            id: coverImage
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            source: songModel.get(currentSongIndex).cover
                                            fillMode: Image.PreserveAspectCrop

                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                maskEnabled: true
                                                maskSource: discMask
                                            }

                                            RotationAnimator on rotation {
                                                from: 0; to: 360; duration: 10000; loops: Animation.Infinite
                                                running: musicPageRoot.isPlaying
                                            }
                                        }

                                        // 中心孔
                                        Rectangle {
                                            width: parent.width * 0.25; height: width
                                            radius: width / 2
                                            color: "#000000"
                                            border.color: "#1AFFFFFF"
                                            border.width: 1
                                            anchors.centerIn: parent

                                            Rectangle {
                                                width: parent.width * 0.25; height: width
                                                radius: width / 2
                                                color: "#000000"
                                                border.color: "#333"
                                                border.width: 1
                                                anchors.centerIn: parent
                                            }
                                        }
                                    }
                                }

                // --- 右侧：信息与控制 ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    // 确保右侧区域能自适应，但也有限制
                    Layout.maximumWidth: 800
                    Layout.minimumWidth: 300
                    spacing: 32

                    // 文本信息
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: songModel.get(currentSongIndex).title
                            color: "white"
                            font.pixelSize: Math.min(42, musicPageRoot.width * 0.05 + 16)
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            horizontalAlignment: musicPageRoot.width < 768 ? Text.AlignHCenter : Text.AlignLeft
                        }
                        Text {
                            text: songModel.get(currentSongIndex).artist
                            color: tw.textPink
                            font.pixelSize: Math.min(20, musicPageRoot.width * 0.03 + 12)
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            horizontalAlignment: musicPageRoot.width < 768 ? Text.AlignHCenter : Text.AlignLeft
                        }
                    }

                    // 进度条区域
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // 【修复】：Slider 所在的容器已经通过 Layout.fillWidth 限制在了 Grid 内
                        // Grid 又通过 anchors.margins 限制在了屏幕内
                        Slider {
                            id: progressSlider
                            from: 0; to: 100
                            value: musicPageRoot.progressValue
                            Layout.fillWidth: true

                            background: Rectangle {
                                x: progressSlider.leftPadding
                                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                                width: progressSlider.availableWidth
                                height: 6
                                radius: 3
                                color: "#1AFFFFFF"

                                Rectangle {
                                    width: progressSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: tw.pink400 }
                                        GradientStop { position: 1.0; color: tw.purple400 }
                                    }

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: tw.pink500
                                        shadowBlur: 10
                                    }
                                }
                            }

                            handle: Rectangle {
                                x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                                width: 16; height: 16; radius: 8
                                color: "white"
                                scale: progressSlider.pressed ? 1.3 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 5; shadowColor: "black" }
                            }
                            onMoved: musicPageRoot.progressValue = value
                        }

                        // 时间显示
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "0:00"; color: "#80FFFFFF"; font.pixelSize: 12; font.family: "Monospace" }
                            Item { Layout.fillWidth: true }
                            // 确保最右侧时间不会被挤出去
                            Text {
                                text: songModel.get(currentSongIndex).duration;
                                color: "#80FFFFFF";
                                font.pixelSize: 12;
                                font.family: "Monospace"
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // 按钮组
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 30

                        Components.EButton {
                            text: ""; iconCharacter: "\uf074"
                            buttonColor: "transparent"
                            iconColor: "#99FFFFFF"
                            shadowEnabled: false
                            width: 40; height: 40
                        }

                        Components.EButton {
                            text: ""; iconCharacter: "\uf048"
                            width: 48; height: 48
                            buttonColor: "transparent"
                            iconColor: "white"
                            shadowEnabled: false
                            onClicked: currentSongIndex = (currentSongIndex - 1 + songModel.count) % songModel.count
                        }

                        Components.EButton {
                            width: 72; height: 72
                            Layout.preferredWidth: 72; Layout.preferredHeight: 72
                            radius: 36
                            text: ""
                            iconCharacter: musicPageRoot.isPlaying ? "\uf04c" : "\uf04b"
                            buttonColor: "#FFFFFF"
                            iconColor: "#581c87"
                            shadowEnabled: true
                            shadowColor: "#66FFFFFF"
                            onClicked: musicPageRoot.isPlaying = !musicPageRoot.isPlaying
                        }

                        Components.EButton {
                            text: ""; iconCharacter: "\uf051"
                            width: 48; height: 48
                            buttonColor: "transparent"
                            iconColor: "white"
                            shadowEnabled: false
                            onClicked: currentSongIndex = (currentSongIndex + 1) % songModel.count
                        }

                        Components.EButton {
                            text: ""; iconCharacter: "\uf0ca"
                            width: 40; height: 40
                            buttonColor: "transparent"
                            iconColor: "white"
                            shadowEnabled: false
                            onClicked: playlistDrawer.open()
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // 侧边栏
    // ============================================================
    Components.EDrawer {
        id: playlistDrawer
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        panelWidth: 300
        drawerColor: "transparent"


        Rectangle {
            anchors.fill: parent
            color: "#4D000000"
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                source: playerCard
                blurEnabled: true
                blurMax: 32
                blur: 1.0
            }
            Rectangle {
                width: 1; height: parent.height
                color: "#1AFFFFFF"
                anchors.left: parent.left
            }
        }

        content: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                Text { text: "\uf51f"; font.family: "Font Awesome 6 Free"; color: "white"; font.pixelSize: 20 }
                Item {
                    Layout.fillWidth: true; height: 30
                    Text { id: textSource; text: "MY MUSIC"; font.bold: true; font.pixelSize: 18; font.letterSpacing: 2; visible: false }
                    Rectangle {
                        anchors.fill: textSource
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: tw.pink400 }
                            GradientStop { position: 1.0; color: tw.purple400 }
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: textSource }
                    }
                }
                Item { Layout.fillWidth: true }
                Components.EButton { text: ""; iconCharacter: "\uf00d"; width: 32; height: 32; buttonColor: "transparent"; shadowEnabled: false; onClicked: playlistDrawer.close() }
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: songModel; spacing: 8
                delegate: Rectangle {
                    width: parent.width; height: 64; radius: 12
                    color: (index === currentSongIndex) ? "#33FFFFFF" : "transparent"
                    Rectangle { width: 4; height: parent.height; anchors.left: parent.left; radius: 2; color: (index === currentSongIndex) ? tw.pink400 : "transparent" }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: if(index !== currentSongIndex) parent.color = "#1AFFFFFF"
                        onExited: if(index !== currentSongIndex) parent.color = "transparent"
                        onClicked: { currentSongIndex = index; musicPageRoot.isPlaying = true }
                    }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; anchors.leftMargin: 16; spacing: 12
                        Item {
                            Layout.preferredWidth: 40; Layout.preferredHeight: 40
                            Rectangle { id: thumbMask; anchors.fill: parent; radius: 6; visible: false; color: "black" }
                            Image { anchors.fill: parent; source: model.cover; fillMode: Image.PreserveAspectCrop; layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: thumbMask } }
                            Row {
                                anchors.centerIn: parent; visible: index === currentSongIndex && musicPageRoot.isPlaying; spacing: 2
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 3; height: 10; color: tw.pink400; radius: 1
                                        SequentialAnimation on height {
                                            loops: Animation.Infinite; running: visible
                                            NumberAnimation { from: 5; to: 15; duration: 300 + index*100; easing.type: Easing.InOutQuad }
                                            NumberAnimation { from: 15; to: 5; duration: 300 + index*100; easing.type: Easing.InOutQuad }
                                        }
                                    }
                                }
                            }
                        }
                        Column {
                            Layout.fillWidth: true
                            Text { text: model.title; color: index === currentSongIndex ? "white" : "#CCFFFFFF"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; width: parent.width }
                            Text { text: model.artist; color: "#99FFFFFF"; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                        }
                    }
                }
            }
        }
    }
}
