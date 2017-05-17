/*
 *------------------------------------------------------------------
 *  pandora/PGWXPay.h
 *  Description:
 *      上传插件头文件定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-22 创建文件
 *------------------------------------------------------------------
 */

#import "PGPay.h"
#import "WXApi.h"

enum {
    PGWXPayAppidNotSame = PGPluginErrorNext
};

@interface  PGWXPay : PGPlatby <WXApiDelegate>{
}
@property(nonatomic, copy)NSString *callBackID;
@property(nonatomic, assign)BOOL isRevOpenUrl;
@property(nonatomic, copy)NSString *urlScheme;
- (void)request:(PGMethod*)command;
@end
