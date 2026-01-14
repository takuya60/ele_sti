/*
 * @Author: takuyasaya 1754944616@qq.com
 * @Date: 2025-12-16 17:01:57
 * @LastEditors: takuyasaya 1754944616@qq.com
 * @LastEditTime: 2025-12-22 20:57:32
 * @FilePath: \ele_sti\include\controllers\TreatmentManager.h
 * @Description: ui交互层：qml ui与service交互的中间层，实现参数转换和信号转发
 */
#pragma once

#include <QObject>
#include <QtQml>
#include "core/TreatmentService.h"

class TreatmentManager : public QObject
{
    Q_OBJECT
    // 属性定义
    Q_PROPERTY(Runstate currentState READ currentState NOTIFY stateChanged)
    Q_PROPERTY(int remainingTime READ remainingTime NOTIFY timeUpdated)

public:
    // 枚举类型注册
    enum class Runstate {
        Idle    = (int)TreatmentService::Runstate::Idle,
        Running = (int)TreatmentService::Runstate::Running,
        Paused  = (int)TreatmentService::Runstate::Paused,
        Error   = (int)TreatmentService::Runstate::Error
    };
    Q_ENUM(Runstate) // 在QT注册枚举类型

    explicit TreatmentManager(TreatmentService *service,QObject *parent =nullptr);
     ~TreatmentManager();

    Q_INVOKABLE void startTreatment(int duration, int freq, float posAmp, float negAmp, int posW, int dead, int negW);
    Q_INVOKABLE void stopTreatment();

    Q_INVOKABLE void updateParameters(int freq, float posAmp, float negAmp, int posW, int dead, int negW);
    Q_INVOKABLE void setPIDParameters(float kp, float ki, float kd);

    int remainingTime() const;
    Runstate currentState() const;
private:
    TreatmentService *m_service;
    int m_remainingTime = 0;
signals:
    void stateChanged();
    void timeUpdated();
    void serialTriggerReceived();
    void monitorDataUpdated(float impedance, int battery, int error);
    void waveformReceived(const QList<float> &data);

};
