cmake_minimum_required(VERSION 3.16)
project(ele_sti VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia Network Charts Core SerialPort)
qt_standard_project_setup(REQUIRES 6.7)

file(GLOB_RECURSE CPP_SOURCES "src/*.cpp")
file(GLOB_RECURSE H_HEADERS "include/*.h")

qt_add_executable(ele_sti
    ${CPP_SOURCES}
    ${H_HEADERS}
)

target_include_directories(ele_sti PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

qt_add_qml_module(ele_sti
    URI ELE_Sti
    VERSION 1.0
    RESOURCE_PREFIX "/"
    QML_FILES
        resources/qml/Main.qml
        # page
        resources/qml/pages/paramSetPage.qml
        resources/qml/pages/monitorPage.qml
        resources/qml/pages/systemPage.qml
        # resources/qml/pages/MusicPage.qml
        # 组件
        resources/qml/components/EButton.qml
        resources/qml/components/EButton2.qml
        resources/qml/components/ECard.qml
        resources/qml/components/EBlurCard.qml
        resources/qml/components/EMenuButton.qml
        resources/qml/components/EAvatar.qml
        resources/qml/components/EToast.qml
        resources/qml/components/ETheme.qml
        resources/qml/components/EAnimatedWindow.qml
        resources/qml/components/MCarousel.qml
        resources/qml/components/ELoader.qml
        resources/qml/components/Disk.qml
        # resources/qml/components/EDrawer.qml
        resources/qml/components/MSystemMonitor.qml
        resources/qml/components/EClockCard.qml
        resources/qml/components/EDropdown.qml
        resources/qml/components/ParamSlider.qml
    RESOURCES
        # 字体文件
        resources/fonts/icon.ico
        "resources/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf" # 有空格要加引号
        resources/fonts/loader.gif

        # 图片文件
        resources/fonts/pic/01.jpg
        resources/fonts/pic/02.jpg
        resources/fonts/pic/1.jpg
        resources/fonts/pic/2.jpg
        resources/fonts/pic/3.jpg
        resources/fonts/pic/ava.png
        resources/fonts/pic/4.png
        resources/fonts/pic/5.png
        resources/fonts/pic/6.png
        resources/fonts/pic/7.png
        resources/fonts/pic/ca1.png
        resources/fonts/pic/ca2.jpg
        resources/fonts/pic/ca3.jpg
        resources/fonts/pic/ca4.jpg
            )


target_link_libraries(ele_sti PRIVATE
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Network
    Qt6::Charts
    Qt6::Core
    Qt6::SerialPort
)

# 设置 Windows 下不弹黑框 (Linux 下这句不起作用，无副作用)
set_target_properties(ele_sti PROPERTIES WIN32_EXECUTABLE TRUE)
