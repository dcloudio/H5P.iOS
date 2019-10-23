//
//  QUCLoginView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-20.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QUCPassField;
@class QUCUnderlineButton;
@class QUCTextField;
@class QUCCaptchaView;
@class QUCSuggestTextFieldView;
@class QUCRegionsView;

@interface QUCLoginView : UIView

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, readonly, strong) QUCSuggestTextFieldView *accountTextField;
@property (nonatomic, strong) QUCPassField *qucPassField;
@property (nonatomic, strong) QUCCaptchaView *qucCaptchaView;
@property (nonatomic, readonly, strong) UIButton *submitButton;
@property (nonatomic, strong) QUCUnderlineButton *regLinkBtn;
@property (nonatomic, strong) QUCUnderlineButton *findpwdLinkBtn;
@property (nonatomic, strong) QUCUnderlineButton *loginOtherBtn;// .hidden默认为YES，可通过设置.hidden = NO来暴露“海外“入口。
@property (nonatomic, assign) BOOL showCaptchaFlag;

@property (nonatomic, strong) QUCRegionsView *regionsView;// regions/countries view

-(void) showCaptcha;
- (void)showRegionsView;// 显示海外区号选择入口

@end
