import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "." as Components

Components.EBlurCard {
    id: root

    // 默认尺寸 (放在布局里时会被忽略，但独立显示时有用)
    implicitWidth: 320
    implicitHeight: 180

    // =========================
    // 1. 公共属性
    // =========================
    property string title: "SYSTEM STATUS"

    // 数据输入 (0.0 - 1.0)
    property real cpuUsage: 0.0
    property real memUsage: 0.0

    property string cpuText: Math.round(cpuUsage * 100) + "%"
    property string memText: Math.round(memUsage * 100) + "%"

    // 样式配置
    blurAmount: 0.6
    borderRadius: 24
    borderWidth: 1
    borderColor: "#30FFFFFF"

    property bool useSimulation: true

    // 配色 (调亮了底轨 trackColor，确保在深色背景可见)
    readonly property color cpuColor: "#2979ff"
    readonly property color memColor: "#00e676"
    readonly property color trackColor: "#20ffffff" // 【修复】半透明白色，比纯黑更明显

    // =========================
    // 2. 模拟器
    // =========================
    Timer {
        running: root.useSimulation
        repeat: true
        interval: 1000
        triggeredOnStart: true
        onTriggered: {
            root.cpuUsage = 0.3 + Math.random() * 0.4
            root.memUsage = 0.4 + Math.random() * 0.2
        }
    }

    // =========================
    // 3. 内容布局
    // =========================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        // 顶部标题栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\uf2db" // FontAwesome: microchip
                font.family: iconFont.name // 确保外部已加载字体
                color: theme.focusColor
                font.pixelSize: 16
                opacity: 0.9
            }

            Text {
                text: root.title
                font.pixelSize: 18
                font.bold: true
                color: "#cccccc"
                font.letterSpacing: 1
                Layout.fillWidth: true
            }
        }

        // 仪表盘区域 (使用 Item 包裹 RowLayout 以处理居中)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 20

                // --- CPU 仪表盘 ---
                NeonGauge {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    name: "CPU LOAD"
                    value: root.cpuUsage
                    displayString: root.cpuText
                    accentColor: root.cpuColor
                    trackColor: root.trackColor
                }

                // 竖向分割线
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    color: "#40ffffff"
                }

                // --- 内存 仪表盘 ---
                NeonGauge {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    name: "MEM USAGE"
                    value: root.memUsage
                    displayString: root.memText
                    accentColor: root.memColor
                    trackColor: root.trackColor
                }
            }
        }
    }

    // =========================
    // 4. 内部组件：霓虹仪表盘 (重写版)
    // =========================
    component NeonGauge : Item {
        id: gaugeRoot
        property string name: ""
        property real value: 0.0
        property string displayString: ""
        property color accentColor: "#00e676"
        property color trackColor: "#333333"

        // 【核心修复】动态计算尺寸：取宽高的较小值，并在 resize 时更新
        // 减去一点 padding 防止光晕被切掉
        readonly property real size: Math.min(width, height) - 10

        // 【核心修复】动态线宽：尺寸越大，线条越粗 (比如尺寸的 8%)
        readonly property real strokeWidth: Math.max(6, size * 0.08)

        // 数值动画
        Behavior on value { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            // 1. 圆环容器
            Item {
                Layout.alignment: Qt.AlignHCenter
                // 强制设置宽高，确保 Canvas 有绘制区域
                width: gaugeRoot.size
                height: gaugeRoot.size

                // A. 底轨 (Track) - 单独一层
                Canvas {
                    id: trackCanvas
                    anchors.fill: parent
                    antialiasing: true

                    // 监听尺寸变化重绘
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset();
                        var cx = width/2, cy = height/2;
                        var r = (width/2) - (gaugeRoot.strokeWidth / 2);

                        ctx.lineWidth = gaugeRoot.strokeWidth;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = gaugeRoot.trackColor; // 使用传入的浅色
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
                        ctx.stroke();
                    }
                }

                // B. 进度条 (Progress) - 独立一层以应用特效
                Canvas {
                    id: progressCanvas
                    anchors.fill: parent
                    antialiasing: true

                    // 绑定属性以触发重绘
                    property real drawVal: gaugeRoot.value
                    onDrawValChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset();
                        var cx = width/2, cy = height/2;
                        var r = (width/2) - (gaugeRoot.strokeWidth / 2);
                        var start = -Math.PI / 2;
                        var end = start + (Math.PI * 2 * drawVal);

                        ctx.lineWidth = gaugeRoot.strokeWidth;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = gaugeRoot.accentColor;

                        // 只有值大于极小值才绘制，避免绘制 artifacts
                        if (drawVal > 0.001) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, start, end, false);
                            ctx.stroke();
                        }
                    }

                    // 【光晕特效】
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 10
                        blur: 0.8        // 适度模糊，产生发光感
                        brightness: 0.2  // 稍微提亮
                        saturation: 0.2  // 保持色彩饱和
                    }
                }

                // C. 中间文字
                Text {
                    anchors.centerIn: parent
                    text: gaugeRoot.displayString
                    // 【自适应字体】字体大小随圆环大小缩放 (约占 22%)
                    font.pixelSize: Math.max(12, gaugeRoot.size * 0.22)
                    font.bold: true
                    color: "white"
                    style: Text.Outline // 加一点描边增加对比度
                    styleColor: "#80000000"
                }
            }

            // 2. 底部标签
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: gaugeRoot.name
                font.pixelSize: 18
                font.bold: true
                color: "#aaaaaa" // 稍微亮一点的灰色
                font.letterSpacing: 1
            }
        }
    }
}
