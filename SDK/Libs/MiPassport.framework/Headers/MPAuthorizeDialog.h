//
//  MPAuthorizeDialog.h
//  MiPassportDemo
//
//  Created by 李 业 on 13-7-12.
//  Copyright (c) 2013年 李 业. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPRequest.h"

@protocol MPAuthorizeDialogDelegate;

@interface MPAuthorizeDialog : UIView <UIWebViewDelegate>
{
    UIWebView *webView;
    UIButton *closeButton;
    UIView *modalBackgroundView;
    UIActivityIndicatorView *indicatorView;
}

@property (nonatomic, assign) id<MPAuthorizeDialogDelegate> delegate;

- (id)initWithURL:(NSString*) loginURL
       authParams:(NSDictionary *)params
         delegate:(id<MPAuthorizeDialogDelegate>)delegate;

- (void)show;
- (void)hide;

@end

@protocol MPAuthorizeDialogDelegate <NSObject>

- (void)authorizeDialog:(MPAuthorizeDialog *)authDialog didRecieveAuthorizationInfo:(NSDictionary *)authorizeInfo;
- (void)authorizeDialog:(MPAuthorizeDialog *)authDialog didFailWithError:(NSError *)error;
- (void)authorizeDialogDidCancel:(MPAuthorizeDialog *)authDialog;

@end