//
//  QUCFindPwdViewController.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"
@class QUCFindPwdView;

/**
 *	@brief	找回密码VC
 */
@interface QUCFindPwdViewController : QUCBasicViewController<UITextFieldDelegate>

@property (nonatomic,strong) QUCFindPwdView *findPwdView;

@end
