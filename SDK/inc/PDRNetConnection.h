/*
 *------------------------------------------------------------------
 *  pandora/tools/PDRNetConnection.h
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
#import <Foundation/Foundation.h>
#import "PDRToolSystemEx.h"

typedef NS_ENUM(NSInteger, PTNetTaskState) {
    PTNetTaskStateInit = 0,
    PTNetTaskStateConnectioning = 1,
    PTNetTaskStateConnectionEstablishment = 2,
    PTNetTaskStateReceiveResponse = PTNetTaskStateConnectionEstablishment,
    PTNetTaskStateReceiveData = 3,
    PTNetTaskStateUploaderData = PTNetTaskStateReceiveData,
    PTNetTaskStateSucess = 4,
    PTNetTaskStateError = 4,
    PTNetTaskStateAbort = 5
};

/*
 *@网络接口代理
 */
@class PTNetConnection;
@protocol PTNetConnectionDelegate <NSObject>
@optional
//网络连接开始
- (void)netConnectionStart:(PTNetConnection *)connection;
//数据发送中
- (void)netConnection:(PTNetConnection *)connection written:(NSInteger)totalBytesWritten
     totalBytes:(NSInteger)totalBytes;
//接受到响应
- (void)netConnection:(PTNetConnection *)connection didReceiveResponse:(id)response;
//连接过程中出现错误
- (void)netConnection:(PTNetConnection *)connection didFailWithError:(NSError*)error;
//数据接收中
- (void)netConnection:(PTNetConnection *)connection didReceiveData:(NSData *)data;
//数据接收完成
- (void)netConnectionFinished:(PTNetConnection *)connection;
@end

/*
 *@网络接口封装
 *@该接口应该能自动处理各种协议
 *@目前只支持HTTP
 *@已有现在对使用并没有抽象各接口还未
 *@做到协议的通用
 */
@interface PTNetConnection : NSObject<NSURLConnectionDelegate> {
    @private
    NSMutableDictionary *_httpHeaderDict;
    NSURLConnection *_connection;
}

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) id request;

@property (nonatomic, retain) NSString *reqMethod;
@property (nonatomic, retain) NSString *reqUrl;
@property (nonatomic, retain) NSData *reqBody;
@property (nonatomic, retain) NSDictionary *responseHeaders;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) PDRCoreAppSSLActive eSslActive;

@property (assign, nonatomic) id<PTNetConnectionDelegate> delegate;
- (void)start;
- (void)cancel;
- (void)reset;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setAllHTTPHeaderFields:(NSDictionary*)dict;

@end

@interface NSString(PTNet)
+(NSRange)contentRange:(NSString*)contentRange;
@end
