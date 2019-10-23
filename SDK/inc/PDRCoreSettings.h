//
//  PDR_Manager_Feature.h
//  Pandora
//
//  Created by Mac Pro_C on 12-12-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PDRExendPluginType) {
    ///全局插件 该插件native实例将采用单例模式
    PDRExendPluginTypeApp = 0,
    PDRExendPluginTypeFrame = 1,
    /// NView插件 该插件可以使用UI接口进行管理
    PDRExendPluginTypeNView = 2
};

@interface PDRExendPluginInfo : NSObject
@property(nonatomic, copy)NSString *name;
@property(nonatomic, copy)NSString *impClassName;
@property(nonatomic, copy)NSString *javaScript;
@property(nonatomic, assign)PDRExendPluginType type;
+(PDRExendPluginInfo*)infoWithName:(NSString*)name
                      impClassName:(NSString*)impClassName
                              type:(PDRExendPluginType)pluginType
                        javaScript:(NSString*)javasrcipt;
@end

typedef NS_ENUM(NSInteger, H5CoreAppSplashType) {
    //自动选择启动界面，如果splash图片已经下载则显示splash图片，否则使用默认加载流应用界面
    H5CoreAppSplashTypeAuto = 0,
    //使用默认加载流应用界面（如在360浏览器环境中在标题栏下显示加载进度条）。 默认值为"auto"
    H5CoreAppSplashTypeDefault = 1
};

@interface DC5PAppStartParams : NSObject
@property(nonatomic, copy)NSString *version; //app version
@property(nonatomic, copy)NSString *appid;   //app id
@property(nonatomic, copy)NSString *documentPath; //配置的应用文档目录
@property(nonatomic, copy)NSString *rootPath; //应用的运行目录
@property(nonatomic, copy)NSString *arguments; //启动参数
@property(nonatomic, copy)NSString *arguments_restore; //恢复时的启动参数
@property(nonatomic, copy)NSString *launcher;
@property(nonatomic, copy)NSString *channel; //应用的市场推广渠道标识
@property(nonatomic, copy)NSString *launch_path; //启动流用是指定首页地址
@property(nonatomic, copy)NSString *launch_path_restore;
@property(nonatomic, copy)NSString *launch_path_id;
@property(nonatomic, copy)NSString *launcher_comfrom; //启动当前应用的appid或是传入的启动类型
@property(nonatomic, copy)NSString *iconPath; //应用图标
@property(nonatomic, copy)NSString *summary; //应用说明
@property(nonatomic, assign)BOOL    needCheckUpdate;
@property(nonatomic, copy)NSString *origin;
@property(nonatomic, copy)NSString *direct_page;
@property(nonatomic, copy)NSString *direct_page_backup;
@property(nonatomic, assign, readonly)BOOL isTestVersion;
@property(nonatomic, assign)BOOL streamApp; //应用说明
@property(nonatomic, assign)BOOL isW2APackage; // 是否w2a打包
@property(nonatomic, assign)BOOL wapApp; //应用说明
@property(nonatomic, assign)BOOL debug;
@property(nonatomic, assign)BOOL isSDKApp;
@property(nonatomic, assign)BOOL isHomePageVisable;
@property(nonatomic, assign)BOOL isHomePageVisable_restore;
@property(nonatomic, assign)H5CoreAppSplashType splashType;
@property(nonatomic, assign)H5CoreAppSplashType splashType_restore;
@property(nonatomic, assign)BOOL isRecovery;
- (void)copySelfTo:(DC5PAppStartParams*)startParams;
- (void)setVersionStatus:(BOOL)isTestVersion;
- (BOOL)isSetupVersionStatus;
- (NSString*)getMaketChannel;
@end

@interface PDRCoreSettings : NSObject
@property(nonatomic, assign)BOOL fullScreen;
#if defined(kAppStoreDebugFirstRun)
@property(nonatomic, assign)BOOL isFirstRun;
@property(nonatomic, assign)BOOL isBaseIpa;
#endif
@property(nonatomic, assign)UIStatusBarStyle statusBarStyle;
@property(nonatomic, assign)BOOL reserveStatusbarOffset;
@property(nonatomic, copy)NSString *version; //manifest.josn info.plist中的版本号
@property(nonatomic, copy)NSString *innerVersion; //runtime版本号
@property(nonatomic, copy)NSString *versionCode; //Info.plist中CFBundleVersion字段值版本号
@property(nonatomic, retain)NSMutableDictionary *uniVersionDic; //uni-appb编译器版本号

@property (nonatomic,assign)BOOL isweexdebugMode;//是否是weexdebugTool模式
@property (nonatomic,assign)BOOL isWXDevToolAlert;//是否是weexdebugTool模式下超时弹框
@property (nonatomic,assign)BOOL isWXDevToolReload;//weexdebugTool模式下是否进行debug服务来的reload命令逻辑
@property(nonatomic, assign)BOOL debug; //是否是debug模式
//  true表示开启真机同步资源调试功能，
//false表示不开启真机同步资源调试功能
@property(nonatomic, assign)BOOL syncDebug;
@property(nonatomic, assign, readonly)BOOL ns; //是否是debug模式
@property(nonatomic, retain)NSArray *apps;   //apps节点
@property(nonatomic, retain)NSString *autoStartdAppid;
@property(nonatomic, retain)NSString *docmentPath;
@property(nonatomic, retain)NSString *downloadPath;
@property(nonatomic, retain)NSString *executableAppsPath;
@property(nonatomic, retain)NSString *workAppsPath;
@property(nonatomic, readonly)NSArray *extendPlugins;
@property(nonatomic, retain)UIColor *statusBarColor;
@property(nonatomic, retain)NSString *extendPluginsJs;
@property(nonatomic, assign)CGFloat navBarHeight;
@property(nonatomic, assign)BOOL showNavbar; //应用说明
@property(nonatomic, assign)NSInteger openAppMax;
@property(nonatomic, assign)NSInteger trimMemoryAppCount;
//加载配置文件
- (void) load;
// info.plist中支持的方向
- (BOOL)configSupportOrientation:(UIInterfaceOrientation)orientation ;
//判断是否支持指定的方向
- (BOOL) supportsOrientation:(UIInterfaceOrientation)orientation;
//判断所有支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations;
//设置支持的方向
- (UIInterfaceOrientationMask)setlockOrientationWithArray:(NSArray*)orientations;
- (void) setlockOrientation:(NSUInteger)orientation;
- (void) unlockOrientation;
- (void)setAppid:(NSString*)appid documentPath:(NSString*)doumnetPath;
- (DC5PAppStartParams*)settingWithAppid:(NSString*)appid;
- (void)setupAutoStartdAppid:(NSString *)autoStartdAppid;
- (PDRExendPluginInfo*)regPluginWithName:(NSString*)pluginName
                            impClassName:(NSString*)impClassName
                                    type:(PDRExendPluginType)pluginType
                              javaScript:(NSString*)javaScript;
@end

extern NSString *kDCCoreSettingPortraitPrimary;
extern NSString *kDCCoreSettingPortraitSecondary;
extern NSString *kDCCoreSettingLandscapePrimary;
extern NSString *kDCCoreSettingLandscapeSecondary;
extern NSString *kDCCoreSettingPortrait;
extern NSString *kDCCoreSettingLandscape;

