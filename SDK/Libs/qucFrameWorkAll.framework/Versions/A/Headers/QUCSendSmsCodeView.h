//
//  QUCSendSmsCodeView.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-20.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
@class QUCSmsField;

@interface QUCSendSmsCodeView : UIView{
    
}
@property (nonatomic, readonly, strong) UILabel *headLabel;
@property (nonatomic, strong) UILabel *mpNumLabel;
@property (nonatomic, strong) QUCSmsField *qucSmsField;
@property (nonatomic, strong) UIButton *submitButton;
@end