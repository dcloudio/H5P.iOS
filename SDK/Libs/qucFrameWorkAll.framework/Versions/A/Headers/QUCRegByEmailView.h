//
//  QUCRegByEmailView.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-20.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QUCCheckBoxButton;
@class QUCUnderlineButton;
@class QUCPassField;
@class QUCTextField;
@class QUCCaptchaView;
@class QUCSuggestTextFieldView;

@interface QUCRegByEmailView : UIView
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, readonly, strong) QUCSuggestTextFieldView *emailField;
@property (nonatomic, strong) QUCPassField *qucPassField;
@property (nonatomic, strong) QUCCaptchaView *qucCaptchaView;
@property (nonatomic, readonly, strong) UIButton *submitButton;
@property (nonatomic, readonly, strong) QUCCheckBoxButton *serviceChkBoxBtn;
@property (nonatomic, readonly, strong) UIButton *serviceLinkBtn;
@property (nonatomic, strong) QUCUnderlineButton *regModeSwitchBtn;
@property (nonatomic, assign) BOOL showCaptchaFlag;

-(void) showCaptcha;

@end
