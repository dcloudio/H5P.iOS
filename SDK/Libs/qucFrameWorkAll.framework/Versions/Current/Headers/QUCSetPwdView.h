//
//  QUCSetPwdView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
@class QUCPassField;

@interface QUCSetPwdView : UIView
@property (nonatomic, strong) QUCPassField *qucPassField;
@property (nonatomic, readonly, strong) UIButton *savePwdBtn;
@end
