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
#import <UIKit/UIKit.h>
#import "PGPlugin.h"
@class PGShare;

@protocol PGAuthorizeViewDeleagte <NSObject>
@optional
- (void)onloaded;
- (void)onauthenticated;
- (void)onerror:(NSError*)error;
@end

@interface PGAuthorizeView : UIView
- (void)loadAuthPage;
- (void)postOnloadedEvt;
- (void)postOnauthenticatedEvt;
- (void)postOnErrorEvt:(NSError*)error;
@property(nonatomic, assign)id<PGAuthorizeViewDeleagte> authViewDeleagte;
@end

@interface PGShareControl : UIView<PGAuthorizeViewDeleagte> {
    PGAuthorizeView *_authView;
}

@property (nonatomic, assign) PDRCoreAppFrame* JSFrameContext;
@property (nonatomic, assign) PDRCoreApp* appContext;
@property (nonatomic, assign) PGShare* bridge;
@property (nonatomic, copy)NSString *authUrl;
@property (nonatomic, copy)NSString *callBackID;
@property (nonatomic, copy)NSString *engineType;
- (void)setAuthorizeView:(PGAuthorizeView*)authView;
@end