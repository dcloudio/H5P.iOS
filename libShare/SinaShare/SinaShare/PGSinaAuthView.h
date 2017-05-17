/*
 *------------------------------------------------------------------
 *  pandora/PGShare.h
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
#import "PGShare.h"

@class PGSINAAuthorizeView;
@protocol PGSINAAuthorizeViewDelegate <NSObject>
- (void)authorizeView:(PGSINAAuthorizeView *)webView didSucceedWithAccessToken:(NSDictionary *)token;
- (void)authorizeView:(PGSINAAuthorizeView *)authorize didFailuredWithError:(NSError *)error;
@end

@interface PGSINAAuthorizeView : PGAuthorizeView<UIWebViewDelegate> {
    UIWebView *_SWBAuthorizeView;
}

@property(nonatomic, copy)NSString *appKey;
@property(nonatomic, copy)NSString *appSecret;
@property(nonatomic, copy)NSString *redirectURI;
@property (nonatomic, retain) NSString *returnCode;
@property (nonatomic, retain) NSString *requestURLString;
@property(nonatomic, assign)id<PGSINAAuthorizeViewDelegate> authorizeViewDeleagte;
- (void) loadAuthPage;
@end