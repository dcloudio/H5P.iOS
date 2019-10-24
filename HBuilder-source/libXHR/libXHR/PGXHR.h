/*
 *------------------------------------------------------------------
 *  pandora/feature/PGXHR.h
 *  Description:
 *      XmlHttpRequest头文件定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-29 创建文件
 *------------------------------------------------------------------
 */

#import "PGPlugin.h"
#import "PGMethod.h"
#import "PDRNetTask.h"

typedef NS_ENUM(NSInteger, PGXHRTextEncoding) {
    PGXHRTextEncodingGBK = 0,
    PGXHRTextEncodingUTF_8
};

@class PGXHRConnection;
@protocol PGXHRConnectionDelegate <NSObject>
- (void) connectionEnd:(PGXHRConnection*)connection;
@end

@interface PGXHRConnection : PTNetConnection<PTNetConnectionDelegate> {
    @private
    NSMutableData *_data;
}

@property (nonatomic, assign) PGPlugin *bridge;
@property (nonatomic, retain) NSString *UUID;
@property (nonatomic, retain) NSString *mCallbackid;
@property (nonatomic, assign) PGXHRTextEncoding textEncoding;
@property (nonatomic, retain) NSString *responseText;
@property (nonatomic, retain) NSString *overrideMimeType;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) long long contentLength;
- (void) open;
- (void) send;
- (void) abort;

@end

@interface PGXHR :PGPlugin
{
    @private
    NSMutableDictionary *_XHRConnections;
}

- (void) open:(PGMethod*)command;
- (void) send:(PGMethod*)command;
- (void) abort:(PGMethod*)command;

- (void) connectionEnd:(PGXHRConnection*)connection;

@end