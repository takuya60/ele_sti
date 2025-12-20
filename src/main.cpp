/*
 * @Author: takuyasaya 1754944616@qq.com
 * @Date: 2025-12-16 17:01:57
 * @LastEditors: takuyasaya 1754944616@qq.com
 * @LastEditTime: 2025-12-20 18:13:32
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

//#include "hal/RK3568Backend.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));
    QQmlApplicationEngine engine;
    qmlRegisterUncreatableType<TreatmentManager>("ELE_Sti", 1, 0, "TreatmentManager", "Get state from treatmentManager instance");
    // 工作线程和后端初始化
    QThread *workthread =  new QThread();

    //RK3568Backend * backend= new RK3568Backend();


    WinBackend * backend= new WinBackend();
    backend->moveToThread(workthread);
    workthread->start();
    QObject::connect(workthread,&QThread::finished,backend,&QObject::deleteLater);
    // 把初始化放到工作线程里执行
    QMetaObject::invokeMethod(backend,[backend](){
        if (! backend->init("/dev/spidev1.0"))
        {
            qDebug() << "Backend init failed!";
        }
       
    });
    // 服务和管理器初始化
    auto service = new TreatmentService(backend);
    auto manager = new TreatmentManager(service);
    // QML 上下文属性设置
    engine.rootContext()->setContextProperty("treatmentManager", manager);

    // 
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [](){ QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule("ELE_Sti", "Main");
    return app.exec();
}

