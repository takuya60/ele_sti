// /*
//  * @Author: takuyasaya 1754944616@qq.com
//  * @Date: 2025-12-22 20:57:09
//  * @LastEditors: takuyasaya 1754944616@qq.com
//  * @LastEditTime: 2025-12-22 21:04:09
//  * @FilePath: \ele_sti\include\controllers\SystemMonitor.h
//  * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
//  */
// #pragma once

// #include <QObject>
// #include <QThread>

// // ==========================================
// // Worker 类：负责在后台线程干脏活累活
// // ==========================================
// class HardwareWorker : public QObject {
//     Q_OBJECT
// public:
//     explicit HardwareWorker(QObject *parent = nullptr);

// public slots:
//     // 执行一次读取任务 (被定时器触发)
//     void readStats();

// signals:
//     // 数据准备好后，发送给主线程
//     void dataReady(int cpu, int mem, int bat, bool charging);

// private:
//     // 上一次的 CPU 计数 (用于计算瞬间使用率)
//     long m_prevTotal = 0;
//     long m_prevIdle = 0;

//     // 具体的读取逻辑
//     int readCpuUsage();
//     int readMemUsage();
//     std::pair<int, bool> readBatteryInfo();
// };

// // ==========================================
// // Controller 类：负责对接 QML UI
// // ==========================================
// class SystemMonitor : public QObject {
//     Q_OBJECT
//     // 暴露给 QML 的属性
//     Q_PROPERTY(int cpuUsage READ cpuUsage NOTIFY statsChanged)
//     Q_PROPERTY(int memUsage READ memUsage NOTIFY statsChanged)
//     Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY statsChanged)
//     Q_PROPERTY(bool isCharging READ isCharging NOTIFY statsChanged)

// public:
//     explicit SystemMonitor(QObject *parent = nullptr);
//     ~SystemMonitor();

//     // Getters
//     int cpuUsage() const { return m_cpu; }
//     int memUsage() const { return m_mem; }
//     int batteryLevel() const { return m_bat; }
//     bool isCharging() const { return m_charging; }

// signals:
//     void statsChanged();

// private slots:
//     // 接收 Worker 传来的数据
//     void onDataReceived(int cpu, int mem, int bat, bool charging);

// private:
//     QThread *m_thread;
//     HardwareWorker *m_worker;
    
//     // 缓存的数据
//     int m_cpu = 0;
//     int m_mem = 0;
//     int m_bat = 80; // 默认值
//     bool m_charging = false;
// };
