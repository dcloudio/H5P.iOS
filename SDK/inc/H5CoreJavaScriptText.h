//
//  H5CoreJavaScriptText.h
//  libPDRCore
//
//  Created by DCloud on 16/5/19.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import "PDRCoreApp.h"

@interface H5CoreJavaScriptText : NSObject
+ (NSString*)plusObject;
+ (NSString*)genToJsParamerWithDebug:(BOOL)isDebugMode
                     withPostJSError:(BOOL)postJSError withAppIsRecovery:(BOOL)isAppRecovery withWebviewRecovery:(BOOL)isWebviewRecovery;

+ (NSString*)genRuntimePropertyJsWithLaunchLoadedTime:(NSTimeInterval)launchLoadedTime
                                   withAppStartupTime:(NSTimeInterval)startupTime;
+ (NSString*)genRuntimePropertyJsWithAppid:(NSString*)appId
                          withInnerVersion:(NSString*)innerVersion
                               withVersion:(NSString*)version
                            withUniVersion:(NSString*)uniVersion;
+ (NSString*)genRuntimePropertyJSWithLauncher:(NSString*)launcher
                                withArguments:(id)arguments
                                   withOrigin:(NSString*)origin
                                  withChannel:(NSString*)channel;
+ (NSString*)genRuntimePropertyJSWithPlusObject:(NSString*)plusObject
                                   withLauncher:(NSString*)launcher
                                  withArguments:(id)arguments
                                     withOrigin:(NSString*)origin
                                    withChannel:(NSString*)channel;

+ (NSString*)genDeviceScreenAnDispalyInfoWithPlusObject:(NSString*)plusObject;
+ (NSString*)genDeviceScreenAnDispalyInfo;

+ (NSString*)genDeviceNetworkInfo:(NSInteger)type withPlusObject:(NSString*)plusObject;
+ (NSString*)genDeviceNetworkInfo:(NSInteger)type;
+ (NSString*)genDeviceNetworkInfo;
+ (NSString*)genHtmlId:(NSString*)htmlId withWebViewId:(NSString*)webViewId;

+ (NSString*)genEventDispatchJs:(NSString*)eventName ;
+ (NSString*)genAsyncJs:(NSString*)js;
+ (NSString*)genTryCatchJs:(NSString*)js;
+ (NSString*)waqInAnonymousFunction:(NSString*)js;
+ (NSString*)getWeexExposedModuleJs;
+ (NSString*)replaceGeolocationText;

+ (NSString *)getPushChannelJs;
+ (BOOL)isUniPush;
@end
