//
//  QUCRegisterView.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-18.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QUCCheckBoxButton;
@class QUCUnderlineButton;
@class QUCPassField;
@class QUCTextField;
@class QUCRegionsView;

@interface QUCRegByMobileView : UIView

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, readonly, strong) QUCTextField *mobileField;
@property (nonatomic, strong) QUCPassField *qucPassField;
@property (nonatomic, readonly, strong) UIButton *submitButton;
@property (nonatomic, readonly, strong) QUCCheckBoxButton *serviceChkBoxBtn;
@property (nonatomic, readonly, strong) UIButton *serviceLinkBtn;
@property (nonatomic, strong) QUCUnderlineButton *regModeSwitchBtn;
@property (nonatomic, strong) QUCRegionsView *regionsView;// regions/countries view

- (void)showRegionsView;

@end
