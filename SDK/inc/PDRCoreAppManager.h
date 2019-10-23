//
//  PDR_Application.h
//  Pandora
//
//  Created by Mac Pro on 12-12-22.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "PDRCoreApp.h"

@class PDRCoreAppCongfigParse;
@protocol PDRCoreAppWindowDelegate;
@protocol H5UniversalApp;

NS_ASSUME_NONNULL_BEGIN
///APP启动成功
extern NSString *const PDRCoreAppDidLoadNotificationKey;
///APP启动失败
extern NSString *const PDRCoreAppDidStartedFailedKey;
extern NSString *const PDRCoreAppDidSplashCloseKey;
/// 应用管理模块
@interface PDRCoreAppManager : NSObject

/// 当前激活的应用
@property (nonatomic, readonly)H5UniversalApp *activeApp;

- (int)startApp:(NSString*)appid
    withOptions:(DC5PAppStartParams*__nullable)startParams;
///查询应用
- (H5UniversalApp*__nullable)getAppByID:(NSString*)appid;
- (H5UniversalApp*)getMainApp;
- (NSUInteger)appCount;
///重启指定应用
- (void)restart:(H5UniversalApp*)coreApp;
- (void)restartWithAppid:(NSString*)appId;
- (BOOL)activeWithAppId:(NSString*)appId;
/// 关闭指定的应用
- (void)endTopApp;
- (void)endAllApp;
- (void)end:(H5UniversalApp*)coreApp;
- (void)end:(H5UniversalApp*)coreApp animated:(BOOL)animated;
/// 关闭指定的应用
- (void)endWithAppid:(NSString*)appId;
- (void)endWithAppid:(NSString*)appId animated:(BOOL)animated;
- (NSArray<H5UniversalApp*>*)getAllApps;

/**
 创建App
 
 @param appId appId
 @param args 传入启动参数，可以在页面中通过 plus.runtime.arguments 参数获取
 @param delegate 代理
 @return PDRCoreApp实例对象
 */
- (PDRCoreApp*)openAppWithAppid:(NSString*)appId
                       withArgs:(NSString*__nullable)args
                   withDelegate:(id<PDRCoreAppWindowDelegate>__nullable)delegate;

- (PDRCoreAppInfo*)getMainAppInfo;
//打开完整的5+App应用
- (PDRCoreApp*)openAppAtLocation:(NSString*)location
                   withAppId:(NSString*__nullable)appid
                        withArgs:(NSString*__nullable)args
                    withDelegate:(id<PDRCoreAppWindowDelegate>__nullable)delegate __attribute__((deprecated("deprecated, Use -openAppWithAppid:withArgs:withDelegate:")));

- (PDRCoreApp*)openAppAtLocation:(NSString*)location
                   withIndexPath:(NSString*)indexPath
                        withArgs:(NSString*__nullable)args
                    withDelegate:(id<PDRCoreAppWindowDelegate>__nullable)delegate __attribute__((deprecated("deprecated, Use -openAppWithAppid:withArgs:withDelegate:")));

- (void)registerAppHandle:(Class)universalAppImp withScheme:(NSString*)scheme;
@end
NS_ASSUME_NONNULL_END
