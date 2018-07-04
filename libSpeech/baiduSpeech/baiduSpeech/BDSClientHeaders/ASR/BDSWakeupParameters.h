//
//  BDSWakeupParameters.h
//  BDSpeechClient
//
//  Created by baidu on 16/6/6.
//  Copyright © 2016年 baidu. All rights reserved.
//

#ifndef BDSWakeupParameters_h
#define BDSWakeupParameters_h

#import <Foundation/Foundation.h>

/*
 * BDS_WAKEUP_WORDS_FILE_PATH
 * Value explanation:   唤醒词文件路径
 * Value type:          NSString
 * Default value:       -
 */
extern NSString* BDS_WAKEUP_WORDS_FILE_PATH;

/*
 * BDS_WAKEUP_DAT_FILE_PATH
 * Value explanation:   唤醒引擎模型文件路径
 * Value type:          NSString
 * Default value:       -
 */
extern NSString* BDS_WAKEUP_DAT_FILE_PATH;

/*
 * BDS_WAKEUP_APP_CODE
 * Value explanation:   离线授权所需APPCODE
 * Value type:          NSString
 * Default value:       -
 */
extern NSString* BDS_WAKEUP_APP_CODE;

/*
 * BDS_WAKEUP_LICENSE_FILE_PATH
 * Value explanation:   离线授权文件路径
 * Value type:          NSString
 * Default value:       -
 */
extern NSString* BDS_WAKEUP_LICENSE_FILE_PATH;

#pragma mark - 音频文件路径（文件识别）

/*
 * BDS_WAKEUP_ENABLE_DNN_WAKEUP
 * Value explanation:   使用DNN唤醒，功耗低
 * Value type:          @(BOOL)
 * Default value:       NO
 */
extern NSString* BDS_WAKEUP_ENABLE_DNN_WAKEUP;

/*
 * BDS_WAKEUP_AUDIO_FILE_PATH
 * Value explanation:   设置音频文件路径（数据源）
 * Value type:          NSString
 * Default value:       nil
 */
extern NSString* BDS_WAKEUP_AUDIO_FILE_PATH;

/*
 * BDS_WAKEUP_AUDIO_INPUT_STREAM
 * Value explanation:   设置音频输入流（数据源）
 * Value type:          NSInputStream
 * Default value:       nil
 */
extern NSString* BDS_WAKEUP_AUDIO_INPUT_STREAM;

/*
 * BDS_ASR_DISABLE_AUDIO_OPERATION
 * Value explanation:   Disable sdk audio operation (Set audio session disactive).
 * Value type:          BOOL
 * Default value:       @(NO)
 */
extern NSString* BDS_WAKEUP_DISABLE_AUDIO_OPERATION;

#pragma mark - SDK 工作队列

/*
 * BDS_WAKEUP_WORK_QUEUE
 * Value explanation:   指定SDK工作队列
 * Value type:          dispatch_queue_t
 * Default value:       main queue (dispatch_get_main_queue())
 * Example: dispatch_queue_create("queueLabel", DISPATCH_QUEUE_SERIAL)
 */
extern NSString* BDS_WAKEUP_WORK_QUEUE;

/*
 * BDS_WAKEUP_WORDS
 * Value explanation:   唤醒词列表
 * Value type:          NSArray
 * Default value:       -
 */
extern NSString* BDS_WAKEUP_WORDS;

#endif /* BDSWakeupParameters_h */
