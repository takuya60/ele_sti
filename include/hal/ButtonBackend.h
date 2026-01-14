/*
 * @Author: takuyasaya 1754944616@qq.com
 * @Date: 2026-01-01 18:55:23
 * @LastEditors: takuyasaya 1754944616@qq.com
 * @LastEditTime: 2026-01-01 18:55:27
 * @FilePath: \ele_sti\include\hal\ButtonBackend.h
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
#pragma once

#include <QObject>
#include <QSerialPort>
#include <QTimer>
#include <QByteArray>
#include "common/protocol_data.h"

class ButtonBackend : public QObject
{
    Q_OBJECT
public:
    explicit ButtonBackend(QObject *parent = nullptr);
    ~ButtonBackend();

    /**
     * @brief 初始化串口
     * @param portName 串口设备名，如 "/dev/ttyS3"
     * @return 成功返回 true
     */
    bool openSerial(const QString &portName);

signals:
    void startFromSerial();

    /**
     * @brief 信号：旋钮被单击（停止/暂停，如有需要）
     * 对应屏幕配置：Encoder Mode 4 -> Single Click
     */
    void sigSingleClickStop();


private slots:
    void onReadyRead(); // 接收串口数据

private:
    QSerialPort *serial;
    QByteArray buffer;
    uint16_t m_lastKnobVal;   // 记录上一次读到的旋钮值
};
