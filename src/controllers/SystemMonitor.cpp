// #include "controllers/SystemMonitor.h"
// #include <QFile>
// #include <QTextStream>
// #include <QTimer>
// #include <QDebug>
// #include <QRegularExpression>

// // ==========================================
// // HardwareWorker 实现 (后台线程逻辑)
// // ==========================================

// HardwareWorker::HardwareWorker(QObject *parent) : QObject(parent) {}

// void HardwareWorker::readStats()
// {
//     int cpu = readCpuUsage();
//     int mem = readMemUsage();
//     auto batInfo = readBatteryInfo();
    
//     emit dataReady(cpu, mem, batInfo.first, batInfo.second);
// }

// int HardwareWorker::readCpuUsage()
// {
//     QFile file("/proc/stat");
//     if (!file.open(QIODevice::ReadOnly)) return 0;

//     QString line = file.readLine();
//     // 格式: cpu  user nice system idle ...
//     // 使用 Split 行为 SkipEmptyParts 防止多个空格导致解析错误
//     QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    
//     if (parts.length() < 5) return 0;

//     // 第4项是 idle，其他加起来是 total
//     // 注意：/proc/stat 第一列是 "cpu" 字符串，所以从 parts[1] 开始是数值
//     long idle = parts[4].toLong();
//     long total = 0;
//     for (int i = 1; i < parts.length(); ++i) {
//         total += parts[i].toLong();
//     }

//     long diffTotal = total - m_prevTotal;
//     long diffIdle = idle - m_prevIdle;

//     m_prevTotal = total;
//     m_prevIdle = idle;

//     if (diffTotal == 0) return 0;
    
//     // 使用率 = (总增量 - 空闲增量) / 总增量
//     double usage = (1.0 - (double)diffIdle / diffTotal) * 100.0;
//     return (int)usage;
// }

// int HardwareWorker::readMemUsage()
// {
//     QFile file("/proc/meminfo");
//     if (!file.open(QIODevice::ReadOnly)) return 0;

//     long total = 0;
//     long available = 0;
//     bool foundTotal = false;
//     bool foundAvail = false;

//     // 读取前几行即可找到需要的字段
//     while (!file.atEnd() && (!foundTotal || !foundAvail)) {
//         QString line = file.readLine();
//         QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        
//         if (parts.length() < 2) continue;

//         if (parts[0] == "MemTotal:") {
//             total = parts[1].toLong();
//             foundTotal = true;
//         }
//         else if (parts[0] == "MemAvailable:") {
//             // MemAvailable 是最准确的可用内存指标 (内核 3.14+)
//             available = parts[1].toLong();
//             foundAvail = true;
//         }
//     }

//     if (total == 0) return 0;
//     return (int)((1.0 - (double)available / total) * 100.0);
// }

// std::pair<int, bool> HardwareWorker::readBatteryInfo()
// {
//     // RK3568 常见的电池路径，如果你的板子不同，可以用终端 `ls /sys/class/power_supply/` 确认一下
//     QString batPath = "/sys/class/power_supply/battery";
//     if (!QFile::exists(batPath)) {
//         batPath = "/sys/class/power_supply/BAT0"; // 另一种常见命名
//     }

//     // 如果找不到电池目录，返回默认值
//     if (!QFile::exists(batPath)) {
//         return {85, false}; // 模拟值
//     }

//     int level = 0;
//     bool charging = false;

//     // 读取电量百分比
//     QFile fCap(batPath + "/capacity");
//     if (fCap.open(QIODevice::ReadOnly)) {
//         level = fCap.readAll().trimmed().toInt();
//     }

//     // 读取充电状态
//     QFile fStatus(batPath + "/status");
//     if (fStatus.open(QIODevice::ReadOnly)) {
//         QString status = fStatus.readAll().trimmed();
//         // 状态通常是 "Charging", "Discharging", "Full"
//         charging = (status == "Charging");
//     }

//     return {level, charging};
// }

// // ==========================================
// // SystemMonitor 实现 (主线程管理)
// // ==========================================

// SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent)
// {
//     m_thread = new QThread(this);
//     m_worker = new HardwareWorker(); // 注意：这里不能设置 parent，否则无法 moveToThread

//     // 把工人移到独立线程
//     m_worker->moveToThread(m_thread);

//     // 当线程启动时，在线程内部创建并启动定时器
//     // 技巧：必须在线程内部 new QTimer，否则定时器还是属于主线程的
//     connect(m_thread, &QThread::started, m_worker, [this]() {
//         QTimer *timer = new QTimer();
//         timer->setInterval(1000); // 1秒刷新一次
        
//         // 定时器超时 -> 让工人干活
//         connect(timer, &QTimer::timeout, m_worker, &HardwareWorker::readStats);
        
//         // 线程退出时销毁定时器
//         connect(m_thread, &QThread::finished, timer, &QTimer::deleteLater);
        
//         timer->start();
//     });

//     // 接收数据：跨线程信号槽 (Qt::QueuedConnection 是自动的)
//     connect(m_worker, &HardwareWorker::dataReady, this, &SystemMonitor::onDataReceived);

//     // 线程退出时销毁 Worker
//     connect(m_thread, &QThread::finished, m_worker, &QObject::deleteLater);

//     // 启动线程，设置低优先级 (LowPriority)，不抢占 UI 和 治疗线程 资源
//     m_thread->start(QThread::LowPriority);
// }

// SystemMonitor::~SystemMonitor()
// {
//     // 优雅退出线程
//     m_thread->quit();
//     m_thread->wait();
//     // m_worker 会在 finished 信号中自动 delete
// }

// void SystemMonitor::onDataReceived(int cpu, int mem, int bat, bool charging)
// {
//     // 只有数值变化时才更新，避免无效的 UI 刷新
//     bool changed = false;
    
//     if (m_cpu != cpu) { m_cpu = cpu; changed = true; }
//     if (m_mem != mem) { m_mem = mem; changed = true; }
//     if (m_bat != bat) { m_bat = bat; changed = true; }
//     if (m_charging != charging) { m_charging = charging; changed = true; }

//     if (changed) {
//         emit statsChanged();
//     }
// }
