//
//  TCWBAuthorizeViewController.h
//  TCWeiBoSDKDemo
//
//  Created by wang ying on 12-9-7.
//  Copyright (c) 2012年 bysft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCWBGlobalUtil.h"

@class TCWBAuthorizeView;
@protocol TCWBAuthorizeViewDelegate <NSObject>
@optional
- (void)authorizeViewDidStartLoad:(TCWBAuthorizeView *)webView;
- (void)authorizeViewDidFinishLoad:(TCWBAuthorizeView *)webView;
- (void)authorizeView:(TCWBAuthorizeView *)webView didSucceedWithAccessToken:(NSString *)token;
- (void)authorizeView:(TCWBAuthorizeView *)authorize didFailuredWithError:(NSError *)error;
@end

@interface TCWBAuthorizeView : UIWebView<UIWebViewDelegate> {
}
@property (nonatomic, assign) BOOL onlyFirstPage;
@property (nonatomic, retain) NSString *returnCode;
@property (nonatomic, retain) NSString *requestURLString;
@property (nonatomic, assign) id<TCWBAuthorizeViewDelegate> authorizeDeleagete;
- (void)loadAuthPage;
@end