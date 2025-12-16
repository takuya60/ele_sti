#pragma once 

#include <stdint.h>

// 波形包一次传输的采样点数量
#define WAVEFORM_BATCH_SIZE  50 

// --- 帧头定义 ---
#define HEAD_CONTROL  0xAA  // [下行] 控制包
#define HEAD_PID      0xDD  // [下行] PID配置包
#define HEAD_WAVEFORM 0xBB  // [上行] ADC波形包
#define HEAD_STATUS   0xCC  // [上行] 状态包

// --- 指令类型(用于ControlPacket.cmd) ---
#define CMD_START     0x01  // 开始治疗
#define CMD_STOP      0x02  // 停止治疗
#define CMD_UPDATE    0x03  // 更新参数

// --- 错误码 ---
#define ERR_NONE      0x00  // 正常
#define ERR_ELECTRODE 0x01  // 电极脱落
#define ERR_OVER_CURR 0x02  // 过流保护
#define ERR_TIMEOUT   0x03  // 通信超时

// =============================================================
// 数据结构定义
// 使用 pack(1)  1 字节对齐
// =============================================================
;
#pragma pack(push,1)
/**
 * @brief 1.刺激控制包
 * @note  rk3568->M0
 */
struct ControlPacket {
    uint8_t  head;           // HEAD_CONTROL (0xAA)
    uint8_t  cmd;            // CMD_START / CMD_STOP / CMD_UPDATE
    
    // --- 时间参数 ---
    uint16_t freq;           // 频率 (Hz)
    uint16_t positive_width; // 反向脉宽 (us)
    uint16_t negative_width; // 正向脉宽 (us)
    uint16_t dead_pulse;     // 脉间死区 (us): 正波与负波的间隔
    uint16_t dead_cycle;     // 周期间死区 (us): 两个波形周期之间的间隔
                             // (注: 若由 M4 自动计算，此字段可填 0)
    // --- 幅值参数 ---
    float    amp_pos;        // 正向幅值 (mA)
    float    amp_neg;        // 反向幅值 (mA)
    
    uint8_t  checksum;       // 校验和
};

/**
 * @brief 2. PID 配置包
 * @note  rk3568->M0
 */
struct PIDPacket {
    uint8_t  head;           // HEAD_PID (0xDD)
    uint8_t  reserved;       // 保留字节 对齐用
    
    // --- PID 系数 ---
    float    kp;
    float    ki;
    float    kd;
    
    // --- 积分限幅 ---
    float    integ_limit;    // 防止积分饱和导致过充
    
    uint8_t  checksum;       // 校验和
};

/**
 * @brief 3. 高速波形包
 * @note 批量传输 ADC 数据，用于 Qt Charts 画图和上位机算法分析
 */
struct WaveformPacket {
    uint8_t  head;           // HEAD_WAVEFORM (0xBB)
    
    // --- 批量采样数据  ---
    float    adc_batch[WAVEFORM_BATCH_SIZE]; 
    
    uint8_t  checksum;       // 校验和
};

/**
 * @brief 4. 低速状态包
 * @note 每秒发送一次，用于系统监控
 */
struct StatusPacket {
    uint8_t  head;           // HEAD_STATUS (0xCC)
    uint8_t  battery_pct;
    uint16_t real_freq;      // M0 定时器当前实际频率
    uint8_t  error_code;     // 错误码 (见 ERR_ 宏)
    uint8_t  checksum;       // 校验和
};

#pragma pack(pop) // 恢复默认对齐

// 通用校验算法
/**
 * @brief 计算校验和 (简单累加法)
 * @param data 结构体指针
 * @param len  需要计算的长度 (通常是 sizeof(Struct) - 1)
 */
static inline uint8_t calculateChecksum(const void* data, int len) {
    const uint8_t* p = (const uint8_t*)data;
    uint8_t sum = 0;
    for (int i = 0; i < len; i++) {
        sum += p[i];
    }
    return sum;
}
