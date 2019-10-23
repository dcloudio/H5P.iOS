//
//  QUCCaptchaView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-27.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
@class QUCTextField;

@interface QUCCaptchaView : UIView
@property (nonatomic, readonly, strong) QUCTextField *captchaTextField;
@property (nonatomic, strong) UIImageView *captchaImageView;
@property (nonatomic, strong) NSString *captchaSc;
@end
