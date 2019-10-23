//
//  PDR_Manager_Feature.h
//  Pandora
//
//  Created by Mac Pro_C on 12-12-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PDRCore.h"
#import "PDRNView.h"
#import "H5WEWebEngine.h"
@class PDRCoreAppFrame;
@class PDRCoreApp;
@class PDRCoreAppWindow;
@class PGMethod;
@class PDRCoreAppFrameFeature;

NS_ASSUME_NONNULL_BEGIN
///页面加载完成通知
extern NSString *const PDRCoreAppFrameDidLoadNotificationKey;
///页面关闭通知
extern NSString *const PDRCoreAppFrameDidCloseNotificationKey;
///页面将要加载通知
extern NSString *const PDRCoreAppFrameWillLoadNotificationKey;
///页面开始加载通知
extern NSString *const PDRCoreAppFrameStartLoadNotificationKey;
///页面加载失败通知
extern NSString *const PDRCoreAppFrameLoadFailedNotificationKey;
///页面标题变化通知
extern NSString *const PDRCoreAppFrameTitleUpdaedNotificationKey;


/// H5+应用页面
@interface PDRCoreAppFrame : PDRNView

/// 创建runtime页面（使用 WKWebview 渲染）
/// @param aFrameID 页面标识
/// @param pagePath 页面地址 支持http://  file:// 本地地址
/// @param basePath 加载本地页面时指定页面可访问资源路径（通常设置为页面所在目录以 file:// 开头）
/// @param frame 页面位置
- (PDRCoreAppFrame*)initWithName:(NSString *)aFrameID
                         loadURL:(NSString *)pagePath
                         baseURL:(NSString *)basePath
                           frame:(CGRect)frame;

/// 已废弃，请使用 -initWithName:loadURL:baseURL:frame:
/// @param aFrameID 页面标识
/// @param pagePath 页面地址 支持http://  file:// 本地地址
/// @param frame 页面位置
/// @param engineName 渲染引擎，可选值 UIWebview 或 WKWebview （UIWebview即将废弃，不建议使用，上面的方法默认使用 WKWebview 渲染页面）
- (PDRCoreAppFrame*)initWithName:(NSString*)aFrameID
                         loadURL:(NSString*)pagePath
                           frame:(CGRect)frame
                  withEngineName:(NSString*__nullable)engineName __attribute__((deprecated("deprecated, Use -initWithName:loadURL:baseURL:frame:")));


/// 已废弃，请使用 -initWithName:loadURL:baseURL:frame:
- (PDRCoreAppFrame*)initWithName:(NSString*)viewName
                         loadURL:(NSString*)pagePath
                           frame:(CGRect)frame __attribute__((deprecated("deprecated, Use -initWithName:loadURL:baseURL:frame:")));

/// 页面名字用作plus.webview.findViewById()中的id
//@property(nonatomic, copy)NSString *frameName; @see//@property(nonatomic, copy)NSString *viewName;
/// HTML CSS渲染View
@property(nonatomic, readonly, nullable)H5WEWebEngine *webEngine;
/// 页面地址
@property(nonatomic, copy, nullable)NSString* currenLocationHref;
@property(nonatomic, copy, nullable)NSString* baseURL;
/**
 @brief 在当前页面同步执行Javascript
 @param js javasrcipt 脚本
 @return NSString* 执行结果
 */
- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString*)js;
- (void)evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^__nullable)(id, NSError* ))completionHandler;
/// @brief 关闭页面中的键盘
- (void)dismissKeyboard;
/// @brief 触发document事件 document.addEventListener(evtName,function(e){})
- (void)dispatchDocumentEvent:(NSString*)evtName;
- (void)dispatchForgroundEvent:(NSString*)actType;
- (void)dispatchDocumentEvent:(NSString *)evtName withData:(NSDictionary*__nullable)data;

@property(nonatomic, copy, nullable)NSString *frameID;
@end
NS_ASSUME_NONNULL_END
