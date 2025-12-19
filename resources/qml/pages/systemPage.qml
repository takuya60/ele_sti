import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls.Basic
import QtQuick.Effects
import "../components" as Components

Item {
    id: pageRoot
    anchors.fill: parent

    // 外部传入属性
    property int viewportWidth: 1200
    property var theme
    property var toastRef

    // ==========================================
    // 1. 核心数据模型 (模拟)
    // ==========================================
    property date currentTime: new Date()
    property int cpuUsage: 0
    property int memUsage: 0
    property int batteryLevel: 85
    property bool isCharging: false

    // 模拟数据定时器
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            currentTime = new Date()
            // 模拟 CPU/MEM 波动 (0-100)
            cpuUsage = 30 + Math.random() * 20
            memUsage = 45 + Math.random() * 10

            // 模拟电池
            if (isCharging) {
                batteryLevel++; if(batteryLevel > 100) batteryLevel = 100;
            } else {
                batteryLevel--; if(batteryLevel < 20) batteryLevel = 20;
            }
        }
    }

    // 辅助函数：时间格式化
    function pad(v) { return v < 10 ? "0"+v : v }
    function getHour() { return pad(currentTime.getHours()) }
    function getMin() { return pad(currentTime.getMinutes()) }
    function getSec() { return pad(currentTime.getSeconds()) }
    function getDateStr() { return currentTime.toLocaleDateString(Qt.locale(), "yyyy/MM/dd dddd") }

    // ==========================================
    // 2. 主布局
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ================= 左侧：状态监控区 =================
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            Layout.fillWidth: true
            spacing: 20

            // 1. 顶部：时间卡片 (Digital Clock)
            // (时间卡片逻辑比较简单且特定，这里保持内联，也可以封装为 EClockCard)
            Components.EBlurCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                blurSource: bgImage // 假设主窗口有 id: bgImage
                blurAmount: 0.7
                borderRadius: 24
                borderWidth: 1
                borderColor: "#30FFFFFF"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    // 图标装饰
                    Text {
                        text: "\uf017"; font.family: iconFont.name;
                        color: theme.focusColor; font.pixelSize: 50; opacity: 0.8
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: getHour() + ":" + getMin()
                            color: "white"
                            font.pixelSize: 70
                            font.bold: true
                            font.family: "Roboto Mono" // 等宽字体

                            // 秒数小标
                            Text {
                                anchors.left: parent.right
                                anchors.baseline: parent.baseline
                                anchors.leftMargin: 10
                                text: getSec()
                                color: theme.focusColor
                                font.pixelSize: 30
                            }
                        }
                        Text {
                            text: getDateStr()
                            color: "#aaaaaa"
                            font.pixelSize: 16
                            font.letterSpacing: 2
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }

            // 2. 中部：硬件资源监控 (使用新组件 ESystemMonitorCard)
            Components.MSystemMonitor {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 这里的 blurSource 依赖于 ESystemMonitorCard 继承自 EBlurCard
                blurSource: bgImage

                title: "系统状态 (SYSTEM STATUS)"

                // 关闭组件内部模拟，使用页面级的统一模拟数据
                useSimulation: false

                // 数据转换：组件需要 0.0-1.0，页面数据是 0-100
                cpuUsage: pageRoot.cpuUsage / 100.0
                memUsage: pageRoot.memUsage / 100.0
            }
        }

        // ================= 右侧：媒体与电池 =================
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            spacing: 20

            // 1. 沉浸式轮播图 (使用新组件 ECarousel)
            Components.MCarousel {
                Layout.fillWidth: true
                Layout.fillHeight: true

                radius: 24
                shadowEnabled: true

                model: [
                    "../../fonts/pic/ca2.jpg",
                    "../../fonts/pic/ca1.png",
                    "../../fonts/pic/ca3.jpg",
                    "../../fonts/pic/ca4.jpg",
                    "../../fonts/pic/3.jpg"
                ]
            }

            // 2. 电池状态 (Battery Status) - 性能优化版
            // 2. 电池状态 (Battery Status) - 无闪烁版
                        Item {
                            id: batteryCardContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120

                            // === 层级 1: 静态背景 + 特效 ===
                            Rectangle {
                                id: batteryBg
                                anchors.fill: parent
                                radius: 12

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: isCharging ? "#00e676" : (batteryLevel < 20 ? "#ff5252" : "#7c4dff")
                                        Behavior on color { ColorAnimation { duration: 500 } }
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: isCharging ? "#00c853" : (batteryLevel < 20 ? "#c62828" : "#651fff")
                                        Behavior on color { ColorAnimation { duration: 500 } }
                                    }
                                }
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: batteryBg
                                source: batteryBg
                                brightness: 0.1
                            }

                            // === 层级 2: 动态内容 ===
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 20

                                // 电池图标
                                Text {
                                    // 动态图标：充电显示闪电，不充电显示电池格
                                    text: isCharging ? "\uf0e7" : (batteryLevel > 80 ? "\uf240" : (batteryLevel > 50 ? "\uf241" : "\uf243"))
                                    font.family: iconFont.name
                                    color: "white"
                                    font.pixelSize: 48

                                    // 【已删除】OpacityAnimator on opacity ...
                                    // 现在图标会保持常亮，不再闪烁
                                }

                                Column {
                                    Text {
                                        text: batteryLevel + "%"
                                        color: "white"; font.pixelSize: 42; font.bold: true
                                    }
                                    Text {
                                        text: isCharging ? "CHARGING..." : (batteryLevel < 20 ? "LOW BATTERY" : "BATTERY NORMAL")
                                        color: "white"; opacity: 0.8
                                        font.pixelSize: 12; font.bold: true; font.letterSpacing: 1
                                    }
                                }
                            }

                            // 点击切换模拟状态
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { isCharging = !isCharging; if(toastRef) toastRef.show(isCharging ? "连接电源" : "断开电源") }
                            }
                        }
        }
    }
}
