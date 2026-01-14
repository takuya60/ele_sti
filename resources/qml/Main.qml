import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ELE_Sti 1.0
import "components" as Components

ApplicationWindow {
    id: root

    // 【关键修改 1】屏幕分辨率
    width: 1280
    height: 800
    visible: true
    title: "Sidebar Demo"
    color: "#222"

    flags: Qt.Window | Qt.FramelessWindowHint

    // --- 核心状态管理 ---
    property int activeTabIndex: 0
    property bool anyAnimatedWindowOpen: theme.anyAnimatedWindowOpen
    readonly property int resizeMargin: 6

    // 全局字体加载器
    FontLoader {
        id: iconFont
        // 请确保路径正确
        source: "../fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    ETheme {
        id: theme
        // ... (保持您的原始配置)
        property color primaryColor: "#600076ff"
        property color secondaryColor: "#33FFFFFF"
        property color textColor: "white"
        property color shadowColor: "#80000000"
        property int shadowBlur: 10
        property int shadowXOffset: 0
        property int shadowYOffset: 5
        property color blurOverlayColor: "#20000000"
    }

    Item {
        id: contentWrapper
        anchors.fill: parent

        Image {
            id: bgImage
            anchors.fill: parent
            source: "../fonts/pic/3.jpg"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: root.width
            sourceSize.height: root.height
            transformOrigin: Item.Center
            scale: root.anyAnimatedWindowOpen ? 1.2 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuad  } }
        }

        // === 2. 侧边栏 ===
        Components.EBlurCard {
            id: sidebarCard
            width: 120
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 16

            layer.enabled: true // 根据性能调整
            blurSource: bgImage
            blurAmount: 1.0
            borderRadius: 24
            borderWidth: 1
            borderColor: "#30FFFFFF"

            content: ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // 头像
                Components.EAvatar {
                    id: avatar
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    avatarSource: "../../fonts/pic/ava.png"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: console.log("Avatar Clicked")
                    }
                }

                // --- 按钮组 ---
                Components.EButton2 {
                    Layout.fillWidth: true; height: 52
                    iconSize: 32; fontSize: 12; spacing: 10
                    text: "参数设置"
                    iconCharacter: "\uf1de"
                    // 只有 index 为 0 时高亮
                    buttonColor: root.activeTabIndex === 0 ? theme.primaryColor : "transparent"
                    textColor: root.activeTabIndex === 0 ? "white" : "#CCFFFFFF"
                    shadowEnabled: root.activeTabIndex === 0
                    onClicked: root.activeTabIndex = 0
                }

                Components.EButton2 {
                    Layout.fillWidth: true; height: 52
                    iconSize: 32; fontSize: 12; spacing: 10
                    text: "实时监测"
                    iconCharacter: "\uf1fe"
                    buttonColor: root.activeTabIndex === 1 ? theme.primaryColor : "transparent"
                    textColor: root.activeTabIndex === 1 ? "white" : "#CCFFFFFF"
                    shadowEnabled: root.activeTabIndex === 1
                    onClicked: root.activeTabIndex = 1
                }

                Components.EButton2 {
                    Layout.fillWidth: true; height: 52
                    iconSize: 32; fontSize: 12; spacing: 10
                    text: "设备状态"
                    iconCharacter: "\uf013"
                    buttonColor: root.activeTabIndex === 2 ? theme.primaryColor : "transparent"
                    textColor: root.activeTabIndex === 2 ? "white" : "#CCFFFFFF"
                    shadowEnabled: root.activeTabIndex === 2
                    onClicked: root.activeTabIndex = 2
                }

                //  音乐页面按钮 (Index = 3)
                // Components.EButton2 {
                //     Layout.fillWidth: true; height: 52
                //     iconSize: 32; fontSize: 12; spacing: 10
                //     text: "音乐娱乐"
                //     iconCharacter: "\uf001" // fa-music
                //     buttonColor: root.activeTabIndex === 3 ? theme.primaryColor : "transparent"
                //     textColor: root.activeTabIndex === 3 ? "white" : "#CCFFFFFF"
                //     shadowEnabled: root.activeTabIndex === 3
                //     onClicked: root.activeTabIndex = 3
                // }

                Item { Layout.fillHeight: true }

                Components.EButton {
                    Layout.fillWidth: true
                    text: "退出"
                    iconCharacter: "\uf2f5"
                    buttonColor: "#20FF0000"
                    textColor: "#FF5555"
                    shadowEnabled: false
                    onClicked: Qt.quit()
                }
            }
        }

        // === 3. 右侧内容 ===
        Components.EBlurCard {
            id: pageCard
            anchors.left: sidebarCard.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 16

            layer.enabled: true
            blurSource: bgImage
            blurAmount: 0.2
            borderRadius: 24
            borderWidth: 1
            borderColor: "#30FFFFFF"

            clip: true

            Item {
                id: pagesContainer
                anchors.fill: parent
                anchors.margins: 20

                property real switchAnimOffset: 0

                Connections {
                    target: root
                    function onActiveTabIndexChanged() {
                        pagesContainer.switchAnimOffset = 30
                        pageEnterAnim.restart()
                    }
                }

                PropertyAnimation {
                    id: pageEnterAnim
                    target: pagesContainer
                    property: "switchAnimOffset"
                    from: 30; to: 0; duration: 360; easing.type: Easing.OutCubic
                }

                y: switchAnimOffset
                opacity: 1.0 - (switchAnimOffset / 30.0)

                // --- 页面 1：参数设置 ---
                Loader {
                    id: paramSetLoader
                    anchors.fill: parent
                    source: "pages/paramSetPage.qml"
                    active: true
                    visible: root.activeTabIndex === 0
                    opacity: root.activeTabIndex === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 360 } }
                    onLoaded: {
                        if (item) {
                            if (!item.theme) item.theme = theme
                            if (item.viewportWidth !== undefined) item.viewportWidth = pagesContainer.width
                            if (item.toastRef === undefined) item.toastRef = toast
                        }
                    }
                }

                // --- 页面 2：实时监测 ---
                Loader {
                    id: monitorPage
                    anchors.fill: parent
                    source: "pages/monitorPage.qml"
                    active: false
                    onVisibleChanged: if (visible) active = true
                    visible: root.activeTabIndex === 1
                    opacity: root.activeTabIndex === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 360 } }
                    onLoaded: {
                        if (item) {
                            if (!item.theme) item.theme = theme
                            if (item.viewportWidth !== undefined) item.viewportWidth = pagesContainer.width
                            if (item.toastRef === undefined) item.toastRef = toast
                        }
                    }
                }

                // --- 页面 3：设备状态 ---
                Loader {
                    id: systemPage
                    anchors.fill: parent
                    source: "pages/systemPage.qml"
                    active: true // 建议改为懒加载
                    onVisibleChanged: if (visible) active = true
                    visible: root.activeTabIndex === 2
                    opacity: root.activeTabIndex === 2 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 360 } }
                    onLoaded: {
                        if (item) {
                            if (!item.theme) item.theme = theme
                        }
                    }
                }

                // --- 页面 4：音乐娱乐 (Index 3) ---
                // Loader {
                //     id: musicLoader
                //     anchors.fill: parent
                //     source: "pages/MusicPage.qml" // 确保文件名对应

                //     active: false // 懒加载：第一次点击时才加载
                //     onVisibleChanged: if (visible) active = true

                //     visible: root.activeTabIndex === 3
                //     opacity: root.activeTabIndex === 3 ? 1 : 0
                //     Behavior on opacity { NumberAnimation { duration: 360 } }

                //     onLoaded: {
                //         if (item) {
                //             // 注入依赖
                //             if (!item.theme) item.theme = theme
                //             if (item.viewportWidth !== undefined) item.viewportWidth = pagesContainer.width
                //             if (item.toastRef === undefined) item.toastRef = toast
                //         }
                //     }
                // }
            }
        }
        Components.EToast {
            id: toast
            anchors.top: contentWrapper.top
            anchors.horizontalCenter: contentWrapper.horizontalCenter
            anchors.topMargin: 32 + (toast.yOffset || 0)
        }
    }
}
