//
//  CustomFindPwdViewController.h
//  qucsdkFramework
//
//  Created by 富龙 于 on 14-7-13.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <qucFrameWorkAll/QUCFindPwdViewController.h>
#import <qucFrameWorkAll/QUCActivateEmailViewController.h>
#import <qucFrameWorkAll/QUCIframeViewController.h>
#import <qucFrameWorkAll/QUCRegionsViewController.h>
#import "DCNavigationController.h"

@interface DCFindPwdViewController : QUCFindPwdViewController

@end

@interface DCActivateEmailViewController : QUCActivateEmailViewController

@end

@interface DCIframeViewController : QUCIframeViewController<DCNavigationControllerDelegate>

@end

@interface DCRegionsViewController : QUCRegionsViewController

@end

@interface DCSendSmsCodeForFindpwdViewController : QUCSendSmsCodeForFindpwdViewController

@end