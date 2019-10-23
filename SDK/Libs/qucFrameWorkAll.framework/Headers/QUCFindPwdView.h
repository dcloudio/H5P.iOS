//
//  QUCFindPwdView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QUCTextField;
@class QUCUnderlineButton;
@class QUCRegionsView;

@interface QUCFindPwdView : UIView

@property (nonatomic, readonly, strong) QUCTextField *mobileField;
@property (nonatomic, readonly, strong) UIButton *nextButton;
@property (nonatomic, strong) QUCUnderlineButton *findPwdUserOtherWayBtn;
@property (nonatomic, strong) QUCRegionsView *regionsView;

- (void) showRegionsView;

@end
