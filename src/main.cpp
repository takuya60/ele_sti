/*
 * @Author: takuyasaya 1754944616@qq.com
 * @Date: 2025-12-16 17:01:57
 * @LastEditors: takuyasaya 1754944616@qq.com
 * @LastEditTime: 2026-01-01 19:00:23
 * @FilePath: \ele_sti\src\main.cpp
 * @Description: 应用程序入口
 */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QThread>
#include "controllers/TreatmentManager.h"
#include <QQmlContext>
#include "core/TreatmentService.h"
#include "controllers/TreatmentManager.h"

#include "hal/WinBackend.h"

#include "hal/ButtonBackend.h"

//#include "hal/RK3568Backend.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));
    QQmlApplicationEngine engine;
    qmlRegisterUncreatableType<TreatmentManager>("ELE_Sti", 1, 0, "TreatmentManager", "Get state from treatmentManager instance");
    // 工作线程和后端初始化
    QThread *workthread =  new QThread();
    QThread *serialthread =  new QThread();

    //RK3568Backend * backend= new RK3568Backend();
    WinBackend * backend= new WinBackend();
    ButtonBackend *btnBackend = new ButtonBackend();

    // 把backend放到各自的线程中
    backend->moveToThread(workthread);
    btnBackend->moveToThread(serialthread);
    workthread->start();
    serialthread->start();
    QObject::connect(workthread,&QThread::finished,backend,&QObject::deleteLater);
    QObject::connect(serialthread, &QThread::finished, btnBackend, &QObject::deleteLater);


    // 把初始化放到工作线程里执行
    QMetaObject::invokeMethod(backend,[backend](){
        if (! backend->init("/dev/spidev1.0"))
        {
            qDebug() << "Backend init failed!";
        }
       
    });
    QMetaObject::invokeMethod(btnBackend, [btnBackend](){
        // 注意：这里的端口号 "/dev/ttyUSB0" 根据你的实际情况修改
        if (!btnBackend->openSerial("/dev/ttyUSB0")) {
            qDebug() << "ButtonSerial init failed!";
        }
    });
    // 服务和管理器初始化
    auto service = new TreatmentService(backend);
    auto manager = new TreatmentManager(service);
    // QML 上下文属性设置
    engine.rootContext()->setContextProperty("treatmentManager", manager);
    QObject::connect(btnBackend, &ButtonBackend::startFromSerial,
                     manager, &TreatmentManager::serialTriggerReceived);
    // 
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [](){ QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule("ELE_Sti", "Main");
    return app.exec();
}

