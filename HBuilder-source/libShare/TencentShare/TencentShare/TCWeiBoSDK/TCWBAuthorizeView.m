//
//  TCWBAuthorizeViewController.m
//  TCWeiBoSDKDemo
//
//  Created by wang ying on 12-9-7.
//  Copyright (c) 2012年 bysft. All rights reserved.
//

#import "TCWBAuthorizeView.h"

@implementation TCWBAuthorizeView

@synthesize requestURLString;
@synthesize authorizeDeleagete;
@synthesize returnCode;

- (id)initWithFrame:(CGRect)frame {
    if ( self = [super initWithFrame:frame] ) {
        self.delegate = self;
        self.onlyFirstPage = false;
    }
    return self;
}

- (void)loadAuthPage {
    NSURLRequest *authRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURLString]
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:60.0];
    [self loadRequest:authRequest];
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView{
    if ( self.onlyFirstPage && [self canGoBack]) {
        return;
    }
	if ( [authorizeDeleagete respondsToSelector:@selector(authorizeViewDidStartLoad:)] ) {
        [authorizeDeleagete performSelector:@selector(authorizeViewDidStartLoad:) withObject:self];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView{
    if ( self.onlyFirstPage && [self canGoBack] ) {
        return;
    }
    if ( [authorizeDeleagete respondsToSelector:@selector(authorizeViewDidFinishLoad:)] ) {
        [authorizeDeleagete performSelector:@selector(authorizeViewDidFinishLoad:) withObject:self];
    }
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error{
    if ( [authorizeDeleagete respondsToSelector:@selector(authorizeView:didFailuredWithError:)] ) {
        [authorizeDeleagete performSelector:@selector(authorizeView:didFailuredWithError:) withObject:self withObject:error];
    }
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType{
    
    NSString *urlString = [[[NSString alloc] initWithString:request.URL.absoluteString] autorelease];
    NSRange range = [urlString rangeOfString:@"access_token="];
    
    if (range.location != NSNotFound){
        NSRange scope = [urlString rangeOfString:@"#"];
        NSString *code = [urlString substringFromIndex:scope.location + scope.length];
        self.returnCode = code;
        if ( [authorizeDeleagete respondsToSelector:@selector(authorizeView:didSucceedWithAccessToken:)] ) {
            [authorizeDeleagete performSelector:@selector(authorizeView:didSucceedWithAccessToken:) withObject:self withObject:self.returnCode];
        }
        return NO;
    }
    return YES;
}

- (void)getAccessToken {
    
}

- (void)dealloc {
    self.delegate = nil;
    [requestURLString release];
    [returnCode release];
    [super dealloc];
}

@end
