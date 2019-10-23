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
#import "TCWBAuthorizeView.h"
#import "PGShareControl.h"
#import "PDRToolSystemEx.h"

@class PGQQAuthorizeView;
@protocol PGQQAuthorizeViewDelegate <NSObject>
- (void)authorizeView:(PGQQAuthorizeView *)webView didSucceedWithAccessToken:(NSString *)token;
- (void)authorizeView:(PGQQAuthorizeView *)authorize didFailuredWithError:(NSError *)error;
@end

@interface PGQQAuthorizeView : PGAuthorizeView<TCWBAuthorizeViewDelegate> {
    TCWBAuthorizeView *_AuthViewImp;
}
@property(nonatomic, retain)NSString *appKey;
@property(nonatomic, retain)NSString *appSecret;
@property(nonatomic, retain)NSString *redirectURI;
@property(nonatomic, readonly)TCWBAuthorizeView *authImp;
@property(nonatomic, assign)id<PGAuthorizeViewDeleagte> authorizeViewDeleagte;
- (void) loadAuthPage;
- (NSString*)getAuthorizeURL;
@end