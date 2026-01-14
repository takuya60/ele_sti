// components/VinylDisk.qml
import QtQuick
import QtQuick.Effects

Item {
    id: root

    // === 公开属性 ===
    property string coverSource: ""
    property bool isPlaying: false
    // 允许外部控制圆盘大小，默认 320
    property real diskSize: 320

    // 设置组件的首选大小，方便 Layout 识别
    implicitWidth: diskSize
    implicitHeight: diskSize

    // === 内部实现 ===
    Rectangle {
        id: diskBody
        // 响应式大小：取组件宽高和设定的 diskSize 中的最小值
        width: Math.min(root.width, root.height, root.diskSize)
        height: width
        radius: width / 2
        anchors.centerIn: parent

        // 黑胶底色
        color: "#0f172a"
        border.width: 6
        border.color: "#1AFFFFFF"

        // 阴影效果
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 30
            shadowColor: "#80000000"
            shadowVerticalOffset: 15
        }

        // 旋转动画容器
        Item {
            id: contentContainer
            anchors.fill: parent

            // 旋转逻辑：绑定外部 isPlaying
            RotationAnimator on rotation {
                from: 0; to: 360
                duration: 10000
                loops: Animation.Infinite
                running: root.isPlaying
            }

            // 1. 遮罩源 (定义圆形的可见区域)
            Item {
                id: discMask
                anchors.fill: parent
                visible: false
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: parent.height - 12
                    radius: width / 2
                    color: "black"
                }
            }

            // 2. 封面图
            Image {
                id: coverImage
                anchors.fill: parent
                anchors.margins: 6
                source: root.coverSource
                fillMode: Image.PreserveAspectCrop

                // 应用圆形遮罩
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: discMask
                }
            }

            // 3. 黑胶中心孔
            Rectangle {
                width: parent.width * 0.25
                height: width
                radius: width / 2
                color: "#000000"
                border.color: "#1AFFFFFF"
                border.width: 1
                anchors.centerIn: parent

                // 内圈装饰
                Rectangle {
                    width: parent.width * 0.25
                    height: width
                    radius: width / 2
                    color: "#000000"
                    border.color: "#333"
                    border.width: 1
                    anchors.centerIn: parent
                }
            }
        }
    }
}
