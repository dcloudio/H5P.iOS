//
//  CustomFindPwdViewController.m
//  qucsdkFramework
//
//  Created by 富龙 于 on 14-7-13.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "DCFindPwdViewController.h"

@implementation DCFindPwdViewController

@end

@implementation DCActivateEmailViewController

@end

@implementation DCRegionsViewController

@end

@implementation DCSendSmsCodeForFindpwdViewController

@end


@implementation DCIframeViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //可以考虑设置导航的右侧按钮代理
    DCNavigationController *nav = (DCNavigationController *)self.navigationController;
    [nav setCustomQucNavDelegate:self];
    [nav setShowRightBtnAnimated:YES Title:NSLocalizedString(@"Close", @"关闭")];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //解除代理
    DCNavigationController *nav = (DCNavigationController *)self.navigationController;
    [nav setCustomQucNavDelegate:nil];
    [nav setHideRightBtnAnimated:NO];
}

#pragma mark --webview delegate，重写
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //调用父类方法，显示加载状态
    [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //调用父类方法，去掉加载状态
    [super webViewDidFinishLoad:webView];
    
    //这里可以考虑在导航右侧增加“关闭“按钮
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //调用父类方法，去掉加载状态
    [super webView:webView didFailLoadWithError:error];
    
    //这里可以考虑增加”重试“按钮
}

#pragma mark --点击右侧按钮
- (void)rightNavBtnClick:(id)sender
{
    //隐藏右侧按钮，弹出当前页面
    DCNavigationController *nav = (DCNavigationController *)self.navigationController;
    [nav setHideRightBtnAnimated:NO];
    [nav goBack:sender];
}



@end