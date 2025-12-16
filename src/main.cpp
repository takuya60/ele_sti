#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include "controllers/TreatmentManager.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));
    QQmlApplicationEngine engine;
    qmlRegisterUncreatableType<TreatmentManager>("ELE_Sti", 1, 0, "TreatmentManager", "Controller is created in C++");
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [](){ QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule("EvolveUI", "Main");
    return app.exec();
}

