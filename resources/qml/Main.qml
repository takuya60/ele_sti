import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ELE_Sti 1.0
import "components" as Components

ApplicationWindow {
    id: root

    // 【关键修改 1】这里必须填你屏幕的“物理分辨率”（竖屏）
    // 假设你的屏幕是 800x1280，如果不对请根据 fbset 命令结果修改
    //width: 800
    //height: 1280
    width: 1280
    height: 800
    visible: true
    title: "Sidebar Demo"
    color: "#222" // 窗口背景色，旋转时边缘显示的颜色

    flags: Qt.Window | Qt.FramelessWindowHint

    // --- 核心状态管理 ---
    property int activeTabIndex: 0
    property bool anyAnimatedWindowOpen: theme.anyAnimatedWindowOpen
    readonly property int resizeMargin: 6

    FontLoader {
        id: iconFont
        source: "../fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }

    ETheme {
        id: theme
        // ... (保持不变)
        property color primaryColor: "#600076ff"
        property color secondaryColor: "#33FFFFFF"
        property color textColor: "white"
        property color shadowColor: "#80000000"
        property int shadowBlur: 10
        property int shadowXOffset: 0
        property int shadowYOffset: 5
        property color blurOverlayColor: "#20000000"
    }
    //Item {
        //id: landscapeContainer

        // 这里的宽高是你原本想要的“设计分辨率”（横屏）
       // width: 1280
       // height: 800
        //rotation: 90
        // 居中定位
        //anchors.centerIn: parent
        // === 原来的界面内容全部放在这里面 ===
        Item {
            id: contentWrapper
            anchors.fill: parent // 填满这个横向容器

            Image {
                id: bgImage
                anchors.fill: parent
                source: "../fonts/pic/3.jpg"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: root.width  // 修正引用
                sourceSize.height: root.height // 修正引用
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

                // 【性能警告】如果在 RK3568 上觉得卡，尝试把 layer.enabled 改为 false 测试
                layer.enabled: true

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
                            onClicked: console.log("Avatar Clicked") // 暂时替换未定义的 animationWrapper1
                        }
                    }

                    // 按钮组
                    Components.EButton2 {
                        Layout.fillWidth: true; height: 52
                        iconSize: 32; fontSize: 12; spacing: 10
                        text: "参数设置"
                        iconCharacter: "\uf1de"
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

                // 【性能警告】同上，如果卡顿，先关掉这个 blur
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

                    Loader {
                        id: paramSetLoader
                        anchors.fill: parent
                        source: "pages/paramSetPage.qml"
                        active: true
                        visible: root.activeTabIndex === 0
                        opacity: root.activeTabIndex === 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.InOutQuad } }

                        onLoaded: {
                            if (item) {
                                if (!item.theme) item.theme = theme
                                if (item.viewportWidth !== undefined) item.viewportWidth = pagesContainer.width
                                if (item.toastRef === undefined) item.toastRef = toast
                            }
                        }
                    }
                    Loader {
                        id: monitorPage
                        anchors.fill: parent
                        source: "pages/monitorPage.qml"
                        active: true
                        visible: root.activeTabIndex === 1
                        opacity: root.activeTabIndex === 1 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.InOutQuad } }

                        onLoaded: {
                            if (item) {
                                if (!item.theme) item.theme = theme
                                if (item.viewportWidth !== undefined) item.viewportWidth = pagesContainer.width
                                if (item.toastRef === undefined) item.toastRef = toast
                            }
                        }
                    }
                    Loader {
                        id: systemPage
                        anchors.fill: parent
                        source: "pages/systemPage.qml"
                        active: true
                        visible: root.activeTabIndex === 2
                        opacity: root.activeTabIndex === 2 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.InOutQuad } }

                        onLoaded: {
                            if (item) {
                                if (!item.theme) item.theme = theme
                                if (item.viewportWidth !== undefined) item.viewportWidth = pagesContainer.width
                                if (item.toastRef === undefined) item.toastRef = toast
                            }
                        }
                    }
                    // 其他页面的 Loader 可以在这里继续添加...
                }
            }

            Components.EToast {
                id: toast
                anchors.top: contentWrapper.top
                anchors.horizontalCenter: contentWrapper.horizontalCenter
                anchors.topMargin: 32 + (toast.yOffset || 0) // 加上 safe check
            }
        }
    }
   // }


