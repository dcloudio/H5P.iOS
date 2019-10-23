//
//  PDR_Application.h
//  Pandora
//
//  Created by Mac Pro on 12-12-22.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "PDRCoreDefs.h"
#import "PDRCoreSettings.h"
#import "PDRCoreAppWindow.h"
#import "H5UniversalApp.h"

@class PDRAppFeatureList;
extern NSString *const PDRCoreAppDidStartedKey;
extern NSString *const PDRCoreAppDidStartedFailedKey;
extern NSString *const PDRCoreAppDidUpdataKey;
extern NSString *const PDRCoreAppDidStopedKey;

@class PDRCoreAppInfo;
@class PDRCoreAppWindow;
@class PDRCoreAppFrame;

/// H5+应用
@interface PDRCoreApp : H5UniversalApp<H5UniversalApp>

/// 应用运行目录
@property (nonatomic, copy)NSString *workRootPath;
/// 安装包位置目录
@property (nonatomic, copy)NSString *executableRootPath;
/// 应用信息
@property (nonatomic, readonly)PDRCoreAppInfo *appInfo;
/// 应用根窗口
@property (nonatomic, readonly)PDRCoreAppWindow *appWindow;
/// 应用首页面
@property (nonatomic, readonly)PDRCoreAppFrame *mainFrame;
/// 创建App使用的参数
@property (nonatomic, retain)NSString *arguments;
@property (nonatomic, readonly) BOOL isStreamApp;
@property(nonatomic, readonly)PDRAppFeatureList *featureList;
@end

