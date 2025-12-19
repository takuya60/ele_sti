import QtQuick
import QtQuick.Controls

Item {
    id: animationWrapper
    z: 999
    visible: false
    state: "iconState"

    // 填满父级以拦截点击
    anchors.fill: parent
    focus: visible && state === "fullscreenState"

    // ================= 配置区域 =================
    property real popupWidth: 600
    property real popupHeight: 400
    property real popupRadius: 20

    // 居中坐标计算
    readonly property real _targetX: (width - popupWidth) / 2
    readonly property real _targetY: (height - popupHeight) / 2

    property var theme
    property int animDuration: 400

    // 弹窗展开后的背景色
    property color fullscreenColor: theme ? theme.secondaryColor : "#222222"

    // 点击背景是否关闭
    property bool dismissOnOverlay: true

    default property alias contentData: contentArea.data
    property bool _lastOpenState: false

    // ================= 内部逻辑 =================
    property bool isAnimating: false
    property var startState: ({
        x: 0, y: 0, width: 100, height: 100, radius: 55,
        color: "#651fff", // 给一个默认紫色，防止读取失败变白
        sourceItem: null
    })

    function _updateThemeOpenCount() {
        if (!theme) return
        var nowOpen = (state === "fullscreenState")
        if (nowOpen === _lastOpenState) return
        _lastOpenState = nowOpen
        if (nowOpen) theme.openAnimatedWindowCount += 1
        else theme.openAnimatedWindowCount -= 1
    }

    function open(source) {
        if (isAnimating || state === "fullscreenState") return;
        isAnimating = true;
        startState.sourceItem = source;

        // 1. 坐标与尺寸捕捉
        var map = startState.sourceItem.mapToItem(animationWrapper, 0, 0);
        startState.x = map.x;
        startState.y = map.y;
        startState.width = startState.sourceItem.width;
        startState.height = startState.sourceItem.height;
        startState.radius = (startState.sourceItem.radius !== undefined) ? startState.sourceItem.radius : startState.height / 2;

        // 2. 颜色捕捉 (修复闪烁变白的核心逻辑)
        function findColor(item) {
            if (!item || !item.visible || item.opacity < 0.01) return null;

            // A. 优先检查渐变色 (Gradient)
            // 如果按钮是渐变的，我们取它的结束颜色作为动画起始色，过渡会更自然
            if (item.gradient && item.gradient.stops && item.gradient.stops.length > 0) {
                var stops = item.gradient.stops;
                return stops[stops.length - 1].color;
            }

            // B. 检查普通填充色
            if (item.fill && isColorValid(item.fill)) return item.fill;
            if (item.color && isColorValid(item.color)) return item.color;

            // C. 递归查找子项（有些按钮的背景是子Rectangle）
            for (var i = 0; i < item.children.length; ++i) {
                var c = findColor(item.children[i]);
                if (c) return c;
            }
            return null;
        }

        function isColorValid(c) {
            return c && c !== Qt.transparent && (c.a === undefined || c.a > 0.01);
        }

        var c = findColor(startState.sourceItem);
        // 如果没找到颜色，就用 sourceItem 自身的 color，如果还是没有，就用默认紫色
        // 这样可以彻底杜绝白色闪烁
        startState.color = c ? c : (startState.sourceItem.color || "#651fff");

        // 3. 初始化位置
        appContainer.x = startState.x;
        appContainer.y = startState.y;
        appContainer.width = startState.width;
        appContainer.height = startState.height;
        appContainer.radius = startState.radius;
        appContainer.color = startState.color;

        if (startState.sourceItem) startState.sourceItem.opacity = 0;

        visible = true;
        state = "fullscreenState";
        _updateThemeOpenCount();
    }

    Connections {
        target: theme
        enabled: !!theme
        ignoreUnknownSignals: true
        function onIsDarkChanged() {}
    }

    // ================= UI 结构 =================

    // 背景遮罩
    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        color: "transparent"
        z: -1

        MouseArea {
            anchors.fill: parent
            enabled: animationWrapper.dismissOnOverlay
            onClicked: {
                if (!animationWrapper.isAnimating && animationWrapper.state === "fullscreenState") {
                    animationWrapper.state = "iconState"
                }
            }
        }
    }

    // 变形容器
    Rectangle {
        id: appContainer
        // 【关键修改】去掉了 clip: true，解决了圆角处的方形边框问题
        // clip: true

        // 拦截内容区域的点击
        MouseArea { anchors.fill: parent; onClicked: {} }

        // 内容容器
        Item {
            id: windowContent
            anchors.fill: parent
            opacity: 0

            // 【建议】如果你的内容溢出了圆角，可以开启 layer 并使用 OpacityMask
            // 但通常去掉 clip 就足够解决边框问题了。
            // 只有当内部列表滚动超出圆角时才需要特殊处理。

            z: 1
            Item { id: contentArea; anchors.fill: parent }
        }
    }

    // ================= 状态 =================
    states: [
        State {
            name: "iconState"
            PropertyChanges { target: appContainer; x: startState.x; y: startState.y; width: startState.width; height: startState.height }
            PropertyChanges { target: appContainer; radius: startState.radius; color: startState.color }
            PropertyChanges { target: windowContent; opacity: 0 }
        },
        State {
            name: "fullscreenState"
            PropertyChanges { target: appContainer; x: _targetX; y: _targetY; width: popupWidth; height: popupHeight }
            PropertyChanges { target: appContainer; radius: popupRadius; color: fullscreenColor }
            PropertyChanges { target: windowContent; opacity: 1 }
        }
    ]

    // ================= 动画过渡 =================
    transitions: [
        Transition {
            from: "iconState"; to: "fullscreenState"
            onRunningChanged: if (!running) animationWrapper.isAnimating = false

            ParallelAnimation {
                // 1. 几何形变：全程平滑插值 (InOutQuart)
                NumberAnimation {
                    targets: [appContainer];
                    properties: "x,y,width,height,radius";
                    duration: animDuration;
                    easing.type: Easing.InOutQuart
                }

                // 2. 颜色过渡
                ColorAnimation { target: appContainer; property: "color"; to: fullscreenColor; duration: animDuration }

                // 3. 内容淡入
                SequentialAnimation {
                // 等盒子撑开一点后再开始显示内容，视觉更整洁
                PauseAnimation { duration: animDuration * 0.5 }

                NumberAnimation {
                    target: windowContent;
                    property: "opacity";
                    to: 1;
                    duration: animDuration * 0.7; // 约 280ms，肉眼清晰可见
                    easing.type: Easing.OutQuad
                }
            }
            }
        },

        Transition {
            from: "fullscreenState"; to: "iconState"
            onRunningChanged: {
                if (!running) {
                    animationWrapper.isAnimating = false;
                    animationWrapper.visible = false;
                    if (startState.sourceItem) {
                        startState.sourceItem.opacity = 1;
                        startState.sourceItem = null;
                    }
                    _updateThemeOpenCount();
                }
            }

            ParallelAnimation {
                // 返回动画
                NumberAnimation {
                    targets: [appContainer];
                    properties: "x,y,width,height,radius";
                    duration: animDuration;
                    easing.type: Easing.InOutQuart
                }

                ColorAnimation { target: appContainer; property: "color"; to: startState.color; duration: animDuration }

                // 内容快速淡出
                NumberAnimation { target: windowContent; property: "opacity"; to: 0; duration: animDuration * 0.3 }
            }
        }
    ]

    onStateChanged: _updateThemeOpenCount()
    Component.onCompleted: _updateThemeOpenCount()
    Component.onDestruction: { if (_lastOpenState && theme) theme.openAnimatedWindowCount -= 1 }
}
