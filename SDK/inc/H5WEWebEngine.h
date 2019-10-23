//
//  H5WebviewProtolca.h
//  libPDRCore
//
//  Created by DCloud on 16/4/6.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIkit.h>
#import "PDRToolSystemEx.h"
#import "PDRCoreAppResource.h"

typedef void (^WebScriptExtextensionHandle)( id _Nullable argus,NSError* _Nullable  error);

NS_ASSUME_NONNULL_BEGIN
@protocol H5WEWebEngineDelegate;

@protocol H5WEWebEngine <NSObject>
@optional
@property(nullable, nonatomic, retain)NSString* name;
@property(nullable, nonatomic, retain)NSString* UUID;
@property(nonatomic) CGRect frame;
@property(nullable, nonatomic,copy) UIColor *backgroundColor;

@property(nonatomic, readonly, assign)NSString* pageurl;
@property(nonatomic, readonly)UIView* webview;
@property (nonatomic, readonly, strong) UIScrollView *scrollView;

@property (nullable, nonatomic, assign) id <H5WEWebEngineDelegate> delegate;

@property (nullable, nonatomic, readonly, strong) NSURLRequest *request;
@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic) BOOL scalesPageToFit;
@property (nonatomic) BOOL allowsInlineMediaPlayback;
@property (nonatomic) BOOL injection;
@property(nonatomic) UIDataDetectorTypes dataDetectorTypes;
@property (nullable, nonatomic, readonly, copy) NSString *title;
@property (nonatomic) BOOL allowsBackForwardNavigationGestures;

- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame withParams:(nullable NSDictionary*)dict;
- (id)loadRequest:(NSURLRequest*)request;
- (void)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL;
- (id)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(nullable NSURL *)readAccessURL;
- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL;
- (void)reCreateWebviewWithOptions:(NSDictionary*)op;
- (void)stopLoading;
- (void)reload;
- (void)close;

-(void)setDefalutFontSize:(CGFloat)fontsize;

- (void)goBack;
- (void)goForward;

- (void)clearPerloadJavaScript;
- (void)clearHookJavaScript;
- (void)enableJavascript;
- (void)disableJavascript;

- (BOOL)isSupportSyncEvalJs;

- (void)setJsFramework:(PDRCoreAppResourceLoader*)loader;
- (void)setJsFrameworkWithJavascript:(NSString*)str;
- (void)injectionJavaScript:(NSString*)javaScriptString;
- (void)setHookJavaScript:(NSString*)javaScriptString;
- (void)setCssJavaScript:(NSString *)perloadCssJS;
- (void)setPerloadJavaScript:(NSString*) javaScriptStr;
- (void)evaluateJavaScript:(NSString*)javaScriptString completionHandler:(nullable void (^)(id, NSError*))completionHandler;
- (void)ScriptFunctionExtextension:(NSString*)extCommand externHandler:(nullable WebScriptExtextensionHandle)externHandler;
- (void)stopScriptFunctionExtextension;
- (void)setCustomUA:(NSString*)userAgent;
- (void)setKeyboardDisplayRequiresUserAction:(BOOL)userAction;

- (void)setScrollViewBackgroundColor:(UIColor*)color;
- (BOOL)getInputAccessoryViewVisable;
- (void)setInputAccessoryViewVisable:(BOOL)visable;
- (void)dispatchDocumentEvent:(NSString *)evtName;
- (void)dispatchDocumentEvent:(NSString *)evtName withData:(NSDictionary*)data;

- (void)handleViewDidAppear;
- (void)handleViewDidDisappear;
//JSContext
- (NSString*)plusObject;

- (id)handleSysEvent:(PDRCoreSysEvent)evt withObject:(id)object ;
@end

@interface H5WEWebEngine : NSObject  <H5WEWebEngine>

@property(nullable, nonatomic, copy)WebScriptExtextensionHandle externScriptComplateHandle;
@property(nullable, nonatomic, retain)NSString *H5PlusJS;
@property(nullable, nonatomic, retain)NSString *hookJS;
@property(nullable, nonatomic, retain)NSString *perloadJS;
@property(nullable, nonatomic, retain)NSString *perloadCssJS;
@property(nonatomic, assign)PDRCoreAppSSLActive eSSLActive;
@property(nonatomic, assign)BOOL bSetbounceBackground;
@property(nonatomic, assign)BOOL transparentEvent;
@property(nullable, nonatomic, retain)NSString* UUID;
@property( nonatomic, readonly)CGFloat fontSize;
@property( nonatomic, retain,nullable)NSString *docPath;
@property( nonatomic, assign)id context;
@end

@protocol H5WEWebEngineDelegate <NSObject>
@optional
- (BOOL)webViewEnginde:(H5WEWebEngine*)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)webViewEnginde:(H5WEWebEngine*)webviewEngine didReceiveScriptMessage:(id)message;
- (NSData*)webViewEnginde:(H5WEWebEngine*)webviewEngine didReceiveSyncScriptMessage:(id)message;
- (void)webViewEnginde:(H5WEWebEngine*)webviewEngine titleUpdate:(NSString*)title;
- (void)webViewEnginde:(H5WEWebEngine *)webviewEngine rendering:(nullable id)message;
- (void)webViewEnginde:(H5WEWebEngine *)webviewEngine rendered:(nullable id)message;
- (void)webViewEnginde:(H5WEWebEngine *)webviewEngine progressChange:(id)message;
- (void)webViewEngindeDidStartLoad:(H5WEWebEngine*)webView;
- (void)webViewEngindeDidFinishLoad:(H5WEWebEngine*)webView;
- (void)webViewEngindeDidDomContentLoaded:(H5WEWebEngine*)webView;
- (void)webViewEnginde:(H5WEWebEngine*)webView didFailLoadWithError:(nullable NSError *)error;
- (void)webviewEnginde:(H5WEWebEngine*)webview didTerminate:(nullable id)extra;
- (NSDictionary*)webViewEnginde:(H5WEWebEngine*)webviewEngine getParams:(nullable id)message;
- (void)webViewEnginde:(H5WEWebEngine*)webView viewResize:(CGSize)newRect;
@end

NS_ASSUME_NONNULL_END
