//
//  SynthesizerLogLevel.h
//  BDSSpeechSynthesizer
//
//  Created by lappi on 4/14/15.
//  Copyright (c) 2015 百度. All rights reserved.
//

#ifndef BDSSynthesizerLogLevel_h
#define BDSSynthesizerLogLevel_h

/**
 * @brief 日志级别枚举类型
 */
typedef enum BDSLogLevel {
    BDS_PUBLIC_LOG_OFF = 0,
    BDS_PUBLIC_LOG_ERROR = 1,
    BDS_PUBLIC_LOG_WARN = 2,
    BDS_PUBLIC_LOG_INFO = 3,
    BDS_PUBLIC_LOG_DEBUG = 4,
    BDS_PUBLIC_LOG_VERBOSE = 5,
} BDSLogLevel;

#endif
