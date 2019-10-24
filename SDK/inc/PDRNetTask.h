/*
 *------------------------------------------------------------------
 *  pandora/tools/PDRNetTask.h
 *  Description:
 *     网络功能能头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-05 创建文件
 *------------------------------------------------------------------
 */

#import "PTOperation.h"
#import "PDRNetConnection.h"
/*
 *@网络任务封装
 */
@interface PTNetTask : PTOperation<PTNetConnectionDelegate>
{
@private
    PTNetConnection *_connection;
    NSTimer *_retryTimer;
}
@property(nonatomic, assign)int64_t totalContentSize;   //总数据量的大小
@property(nonatomic, assign)int64_t receiveContentSize; //已经接收文件大小

@property (nonatomic, readonly) PTNetConnection *netConnect;
@property (nonatomic, assign) NSUInteger statusCode;
@property (nonatomic, assign) PTNetTaskState state;      //网络状态
@property (nonatomic, assign) int retryCount;
@property (nonatomic, assign) int retryMax;
@property (nonatomic, assign) int retryInterval;
@property(nonatomic, assign, setter=setSSLActType:)PDRCoreAppSSLActive SSLActType;

//@property (nonatomic, assign) int timeout;
//
//@property (nonatomic, retain) id mRequest;
//@property (nonatomic, retain) NSString *url;

- (void)sendRequest;
- (void)cancelRequest;

//net progress overrides call [super ...]
- (void)netTaskStart;
- (void)netTaskWritten:(NSInteger)totalBytesWritten
           totalBytes:(NSInteger)totalBytes;
- (void)netTaskDidReceiveResponse:(id)response;
- (void)netTaskDidReceiveData:(NSData *)data;
- (void)netTaskFinished;
//重试之后失败认为任务彻底失败
- (void)netTaskFail:(NSError*)error;
@end
