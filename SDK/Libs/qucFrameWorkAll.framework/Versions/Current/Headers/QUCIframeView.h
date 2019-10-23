//
//  QUCIframeView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-2.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QUCIframeView : UIView
@property (nonatomic,strong) UIWebView *webView;

-(void)loadUrl:(NSURL *)url;

//访问用户中心相关WAP页，可以带QT（登录状态）访问
-(void)loadUrl:(NSURL *)url WithQ:(NSString *)Q T:(NSString *)T;
@end
