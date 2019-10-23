//
//  PDR_Application.h
//  Pandora
//
//  Created by Mac Pro on 12-12-22.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "H5CoreOverrideResourceOptions.h"
#import "PDRCoreDefs.h"
#import <UIKit/UIKit.h>
#import "PDRToolSystemEx.h"

typedef NS_ENUM(NSInteger, PDRCoreAppPopGesture) {
    PDRCoreAppPopGestureNone = 0,
    PDRCoreAppPopGestureClose,
    PDRCoreAppPopGestureHide,
    PDRCoreAppPopGestureSkip,
    PDRCoreAppPopGestureAppBack
};

typedef NS_ENUM(NSInteger, PDRCoreAppFrameHistoryBack) {
    PDRCoreAppFrameHistoryBackNone = 0,
    PDRCoreAppFrameHistoryBackPopGesture,
    PDRCoreAppFrameHistoryBackBackButton,
    PDRCoreAppFrameHistoryBackAll
};

@interface PDRCoreAppUserAgentInfo : NSObject
@property(nonatomic, strong)NSString *value;
@property(nonatomic, assign)BOOL concatenate;
@end

@interface PDRCoreAppAuthorInfo : NSObject
@property(nonatomic, strong)NSString *email;
@property(nonatomic, strong)NSString *href;
@property(nonatomic, strong)NSString *content;
@end

@interface PDRCoreAppLicenseInfo : NSObject
@property(nonatomic, strong)NSString *href;
@property(nonatomic, strong)NSString *content;
@end

typedef NS_ENUM(int, PDRCoreWebviewCrashAction) {
    PDRCoreWebviewCrashActionRestart = 1,
    PDRCoreWebviewCrashActionReload,
    PDRCoreWebviewCrashActionNone
};

@interface PDRCoreWebviewKernel : NSObject
@property(nonatomic, strong)NSString *name;
@property(nonatomic, assign)PDRCoreWebviewCrashAction crashAction;
+ (NSString*)getKernelWithName:(NSString*)name;
- (PDRCoreWebviewCrashAction)getCrashActionWithString:(NSString*)action;
@end

typedef NS_ENUM(NSInteger, PDRCoreWebviewMode) {
    PDRCoreWebviewModeChild = 0,//child表示作为launchwebview的子窗口
    PDRCoreWebviewModeFront,    //front表示与launchwebview平级并在其前显示
    PDRCoreWebviewModeBehind,  //behind表示与launchwebview平级并在其后显示
    PDRCoreWebviewModeParent   // parent表示作为launchwebview的父窗口
};

typedef NS_ENUM(NSInteger, H5CoreAppSafeareaValue) {
    H5CoreAppSafeareaValueNone = 1,
    H5CoreAppSafeareaValueAuto
};

@interface H5CoreAppSafearea :NSObject
@property(nonatomic, strong)UIColor *backgroundColor;
@property(nonatomic, assign)H5CoreAppSafeareaValue top;
@property(nonatomic, assign)H5CoreAppSafeareaValue bottom;
@property(nonatomic, assign)H5CoreAppSafeareaValue left;
@property(nonatomic, assign)H5CoreAppSafeareaValue right;
+(instancetype)safeareaWithJson:(NSDictionary*)json;
@end

@interface PDRCoreWebviewConfig : NSObject
@property(nonatomic, strong)NSString *launch_path;
@property(nonatomic, strong)NSString *uid;
@property(nonatomic, assign)PDRCoreWebviewMode mode;
@property(nonatomic, assign)BOOL injection;
@property(nonatomic, strong)NSDictionary *overrideurl;
@property(nonatomic, strong)NSDictionary *additionHeads;
@property(nonatomic, strong)H5CoreOverrideResourceOptions *overrideResource;
@property(nonatomic, strong)NSDictionary* styles;
@end

typedef NS_ENUM(NSInteger, PDRCoreAppSplashscreenTarget) {
    PDRCoreAppSplashscreenTargetDefalut = 0,
    PDRCoreAppSplashscreenTargetSecond,
    PDRCoreAppSplashscreenTargetCustorm
};

typedef NS_ENUM(NSInteger, H5CoreUniappControlMode) {
    H5CoreUniappControlModeWebview = 1,
    H5CoreUniappControlModeWeex
};

typedef NS_ENUM(NSInteger, H5CoreUniappControlRenderer) {
    H5CoreUniappControlRendererAuto = 1,
    H5CoreUniappControlRendererNative
};

typedef NS_ENUM(NSInteger, H5NVueJsframework) {
    H5NVueJsframeworkUniapp = 1,
    H5NVueJsframeworkWeex
};

@interface H5CoreAppUniAppInfo :NSObject
@property(nonatomic, assign)H5CoreUniappControlMode mode;
@property(nonatomic, assign)H5NVueJsframework jsframework;
@property(nonatomic, assign)H5CoreUniappControlRenderer renderer;
@property(nonatomic, strong)NSString *flexDirection;
@property(nonatomic, assign)BOOL forceUniApp;
@end

@interface PDRCoreAppCongfigParse : NSObject {
@private
    // 应用权限目录
    NSMutableDictionary *_permission;
}
@property(nonatomic, strong)NSDictionary *permission;
// 应用的主页面
@property(nonatomic, strong)NSString *appID;
@property(nonatomic, strong)NSString *appIDInMainifesh;
@property(nonatomic, assign)BOOL copyToReadWriteDir;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *version;
@property(nonatomic, assign)BOOL fullScreen;
@property(nonatomic, assign)BOOL allowsInlineMediaPlayback;
@property(nonatomic, assign)BOOL showSplashscreen;
@property(nonatomic, assign)BOOL autoClose;
@property(nonatomic, assign)BOOL autoclose_w2a;
@property(nonatomic, assign)BOOL splashShowWaiting;
@property(nonatomic, assign)PDRCoreAppSplashscreenTarget splashTarget;
@property(nonatomic, strong)NSString *splashWebviewTarget;
@property(nonatomic, assign)NSUInteger delay;
@property(nonatomic, assign)NSUInteger delay_w2a;
@property(nonatomic, copy)NSString *contentSrc;
@property(nonatomic, copy)NSString *description;
@property(nonatomic, strong)PDRCoreAppAuthorInfo *author;
@property(nonatomic, strong)PDRCoreAppLicenseInfo *license;
@property(nonatomic, strong)NSArray *adsInfo;
@property(nonatomic, strong)NSString* paid;
@property(nonatomic, strong)PDRCoreAppUserAgentInfo *userAgent;
@property(nonatomic, strong)NSString *adaptationSrc;
@property(nonatomic, copy)NSString *errorHtmlPath;
@property(nonatomic, assign)BOOL showErrorPage;
@property(nonatomic, assign)PDRCoreAppPopGesture popGesture;
@property(nonatomic, assign)BOOL isStreamCompetent;
@property(nonatomic, strong)NSDictionary *authorityValue;
@property(nonatomic, assign)BOOL isPostException;
@property(nonatomic, assign)BOOL isShowInputAssistBar;
@property(nonatomic, assign)BOOL bW2AShowLaunchError;
@property(nonatomic, assign)BOOL isPostJSException;
@property(nonatomic, assign)BOOL isEncrypt;
@property(nonatomic, assign)PDRCoreAppSSLActive defSSLActive;
@property(nonatomic, strong)NSArray* appWhitelist;
@property(nonatomic, strong)NSArray* schemeWhitelist;
@property(nonatomic, strong)PDRCoreWebviewKernel *kernel;
@property(nonatomic, strong)NSString *launch_path_w2a;
@property(nonatomic, strong)PDRCoreWebviewConfig *secondWebviewConfig;
@property(nonatomic, strong)PDRCoreWebviewConfig *launchwebviewWebviewConfig;
@property(nonatomic, copy)NSString *configPath;   //配置文件全路径
@property(nonatomic, strong)H5CoreAppSafearea *safearea;
@property(nonatomic, strong)NSDictionary *splashAds;
@property(nonatomic, strong)NSString* arguments;
@property(nonatomic, strong)NSArray *orientation;

@property(nonatomic, assign)UIStatusBarStyle statusBarStyle;
@property(nonatomic, strong)UIColor *statusBarColor;
@property(nonatomic, assign)PDRCoreStatusBarMode statusBarMode;
@property(nonatomic, strong)H5CoreAppUniAppInfo *uniInfo;
@property(nonatomic, strong)NSDictionary *tabBarStyle;
- (int) load;
- (int) loadWithConfig:(NSString*)fullPath;
- (BOOL)lessThanPermission:(NSDictionary*)permission moreModes:(NSArray**)output;
- (BOOL)wap2appManefestIsChange:(PDRCoreAppCongfigParse*)oldManifest;
@end

@interface PDRCoreAppInfo : PDRCoreAppCongfigParse {
    @private
}
@property(nonatomic, strong)NSString *indexPage;
@property(nonatomic, strong)NSString *wwwPath;
@property(nonatomic, strong)NSString *documentPath;
@property(nonatomic, strong)NSString *tmpPath;
@property(nonatomic, strong)NSString *logPath;
@property(nonatomic, strong)NSString *dataPath;
@property(nonatomic, strong)NSString *adaptationJS;

- (void)changeExecutableRootPath:(NSString *)executableRootPath;
- (void)setPathsWithExecutableRootPath:(NSString *)executableRootPath
                              workPath:(NSString *)wwwRootPath
                              workPath:(NSString *)workRootPath
                              docuPath:(NSString *)documentPath
                          constantPath:(NSString *)constantPath;
- (void)loadAdaptationJS;
- (void)webviewDefaultSetting;

- (void)registerForKVO;
- (void)unregisterFromKVO;
@end
