/*
 * @Author: takuyasaya 1754944616@qq.com
 * @Date: 2025-12-16 17:01:57
 * @LastEditors: takuyasaya 1754944616@qq.com
 * @LastEditTime: 2025-12-22 13:01:21
 * @FilePath: \ele_sti\src\controllers\TreatmentManager.cpp
 * @Description: ui交互层：qml ui与service交互的中间层，实现参数转换和信号转发
 */

#include "controllers/TreatmentManager.h"
#include "core/TreatmentService.h"

TreatmentManager::TreatmentManager(TreatmentService *service, QObject *parent)
    :m_service(service),QObject(parent)
{
    // 1. 连接状态变化
    // Service 发出的是 Service::Runstate，需要转发为 Manager::Runstate
    // 为了安全，这里用 Lambda 表达式进行转发
    connect(m_service, &TreatmentService::stateChanged,
            this, [this](TreatmentService::Runstate){
            emit stateChanged();
        });

    // 2. 连接时间更新 (都是 int，直接连)
    connect(m_service, &TreatmentService::timeUpdated,
        this, [this](int t){
            m_remainingTime = t;
            emit timeUpdated();
        });
            
    // 3. 连接波形数据 (Chart显示用)
    connect(m_service, &TreatmentService::waveformReceived,
            this, &TreatmentManager::waveformReceived);
            
    // 4. 连接监测数据 (阻抗/电量等)
    connect(m_service, &TreatmentService::monitoringDataReady,
            this, &TreatmentManager::stateChanged);
}
TreatmentManager::~TreatmentManager()
{
}

void TreatmentManager::startTreatment(int duration,  int freq, float posAmp, float negAmp, int posW, int dead, int negW)
{
    if (!m_service) return;
    // 确保参数是界面上看到的最新值
    updateParameters(freq, posAmp, negAmp, posW, dead, negW);
    // 带着新参数启动
    m_service->startTreatment(duration);
}

void TreatmentManager::stopTreatment()
{
    if (!m_service) return;
    m_service->stopTreatment();
}

void TreatmentManager::updateParameters(int freq, float posAmp, float negAmp,
                                        int posW, int dead, int negW)
{
    if (!m_service) return;
    StimulationParam param;
    param.freq = freq;
    param.posW = posW;
    param.negW = negW;
    param.posAmp = posAmp;
    param.negAmp = negAmp;
    param.dead = dead;
    m_service->updateParameters(param);
}

void TreatmentManager::setPIDParameters(float kp, float ki, float kd)
{
    if (!m_service) return;
    PIDParam pid;
    pid.kp = kp;
    pid.ki = ki;
    pid.kd = kd;
    m_service->setPIDParameters(pid);
}

int TreatmentManager::remainingTime() const // 只读
{
    return m_remainingTime;
}
TreatmentManager::Runstate TreatmentManager::currentState() const
{
    if (!m_service) return Runstate::Idle;
    return static_cast<Runstate>(m_service->currentState()); // 把service的state类型转换到manager的runstate枚举
}
