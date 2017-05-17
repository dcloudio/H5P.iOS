/*
 *------------------------------------------------------------------
 *  pandora/feature/PGShare
 *  Description:
 *    上传插件实现定义
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
#import "PGSinaAuthView.h"
#import "WBHttpRequest.h"

@implementation PGSINAAuthorizeView

@synthesize authorizeViewDeleagte;
@synthesize requestURLString;
@synthesize returnCode;
@synthesize appKey;
@synthesize appSecret;
@synthesize redirectURI;

- (id)initWithFrame:(CGRect)frame {
    if ( self = [super initWithFrame:frame] ) {
        _SWBAuthorizeView = [[UIWebView alloc] initWithFrame:frame];
        _SWBAuthorizeView.delegate = self;
        _SWBAuthorizeView.scalesPageToFit = YES;
        [self addSubview:_SWBAuthorizeView];
    }
    return self;
}

- (void)layoutSubviews {
    _SWBAuthorizeView.frame = self.bounds;
}

- (void)loadAuthPage {
    NSURLRequest *authRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURLString]
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:60.0];
    [_SWBAuthorizeView loadRequest:authRequest];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self postOnloadedEvt];
    });
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error{
    [self postOnErrorEvt:error];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType{
    
    NSString *urlString = [[NSString alloc] initWithString:request.URL.absoluteString];
    NSRange range = [urlString rangeOfString:@"code="];
    
    if (range.location != NSNotFound /*&& self.post == 0*/){
     //   self.post = 1;
        NSRange scope = [urlString rangeOfString:@"="];
        NSString *code = [urlString substringFromIndex:scope.location + scope.length];
        [self performSelector:@selector(getAccessToken) withObject:nil afterDelay:0.01f];
        self.returnCode = code;
    }
    
    [urlString release];
    return YES;
}

- (void)getAccessToken {
    NSDictionary *params = [[NSDictionary alloc]initWithObjectsAndKeys:appKey,@"client_id",
                            appSecret, @"client_secret",
                            redirectURI, @"redirect_uri",
                            @"authorization_code",@"grant_type",
                            self.returnCode,@"code",
                            nil];
    
    [WBHttpRequest requestWithURL:@"https://api.weibo.com/oauth2/access_token"
                       httpMethod:@"POST"
                           params:params
                            queue:nil
            withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
                if ( error ) {
                    if ( [authorizeViewDeleagte respondsToSelector:@selector(authorizeView:didFailuredWithError:)] ) {
                        [authorizeViewDeleagte performSelector:@selector(authorizeView:didFailuredWithError:) withObject:self withObject:error];
                    }
                    [self postOnErrorEvt:error];
                } else {
                    if ( [authorizeViewDeleagte respondsToSelector:@selector(authorizeView:didSucceedWithAccessToken:)] ) {
                        [authorizeViewDeleagte performSelector:@selector(authorizeView:didSucceedWithAccessToken:) withObject:self withObject:result];
                    }
                    [self postOnauthenticatedEvt];
                }
            }];
    return;
}

- (void)dealloc {
    self.appKey = nil;
    self.appSecret = nil;
    self.redirectURI = nil;
    self.returnCode = nil;
    self.requestURLString = nil;
    [_SWBAuthorizeView removeFromSuperview];
    [_SWBAuthorizeView release];
    [super dealloc];
}

@end
