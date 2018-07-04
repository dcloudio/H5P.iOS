//
//  BDSUploaderDefines.h
//  BDSpeechClient
//
//  Created by baidu on 16/6/6.
//  Copyright © 2016年 baidu. All rights reserved.
//

#ifndef BDSUploaderDefines_h
#define BDSUploaderDefines_h

#import <Foundation/Foundation.h>

#pragma mark - Uploader Delegate
@protocol BDSClientUploaderDelegate<NSObject>
- (void)UploadCompleteWithError:(NSError *)error;
@end

#pragma mark - Uploader Command
extern NSString* BDS_UP_CMD_START;
extern NSString* BDS_UP_CMD_CANCEL;

#pragma mark - 数据上传错误类别
typedef enum TVoiceRecognitionUploaderErrorDomain
{
    EVRUploaderErrorDomain = 100,
} TVoiceRecognitionUploaderErrorDomain;

#pragma mark - 数据上传错误状态
typedef enum TVoiceRecognitionDataUploaderErrorCode
{
    EVRDataUploaderSucceed = (EVRUploaderErrorDomain << 16) | (0x0000FFFF & 0),                     // 上传成功
    EVRDataUploaderParamError = (EVRUploaderErrorDomain << 16) | (0x0000FFFF & 1),                  // 参数错误
    EVRDataUploaderRequestError = (EVRUploaderErrorDomain << 16) | (0x0000FFFF & 2),                // 网络请求发生错误
    EVRDataUploaderResponseParseError = (EVRUploaderErrorDomain << 16) | (0x0000FFFF & 3),          // 服务器数据解析错误
    EDataUploaderNetworkUnAvailableError = (EVRUploaderErrorDomain << 16) | (0x0000FFFF & 4),       // 网络不可用
} TVoiceRecognitionDataUploaderErrorCode;

#endif /* BDSUploaderDefines_h */
