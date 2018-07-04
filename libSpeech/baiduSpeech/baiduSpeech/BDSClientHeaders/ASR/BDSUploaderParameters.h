//
//  BDSUploaderParameters.h
//  BDSpeechClient
//
//  Created by baidu on 16/6/6.
//  Copyright © 2016年 baidu. All rights reserved.
//

#ifndef BDSUploaderParameters_h
#define BDSUploaderParameters_h

#import <Foundation/Foundation.h>

/*
 * BDS_UPLOADER_SLOT_NAME
 * Value explanation:   上传词条名
 * Value type:          NSString
 * Default value:       -
 */
extern NSString* BDS_UPLOADER_SLOT_NAME;

/*
 * BDS_UPLOADER_SLOT_WORDS
 * Value explanation:   上传词条列表
 * Value type:          NSArray
 * Default value:       -
 */
extern NSString* BDS_UPLOADER_SLOT_WORDS;

#pragma mark - SDK 工作队列

/*
 * BDS_UPLOADER_WORK_QUEUE
 * Value explanation:   指定SDK工作队列
 * Value type:          dispatch_queue_t
 * Default value:       main queue (dispatch_get_main_queue())
 * Example: dispatch_queue_create("queueLabel", DISPATCH_QUEUE_SERIAL)
 */
extern NSString* BDS_UPLOADER_WORK_QUEUE;

#endif /* BDSUploaderParameters_h */
