//
//  QUCSendSmsCodeForFindpwdViewController.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"
@class QUCSendSmsCodeView;

/**
 *	@brief	用户中心找回密码第二步：发送短信验证码vc
 */
@interface QUCSendSmsCodeForFindpwdViewController : QUCBasicViewController<UITextFieldDelegate>

@property (nonatomic,strong) QUCSendSmsCodeView *sendSmsCodeView;
@end