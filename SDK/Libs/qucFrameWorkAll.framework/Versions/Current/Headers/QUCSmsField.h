//
//  QUCSmsField.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-23.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QUCTextField.h"

@interface QUCSmsField : UIView<QUCTextFieldDelegate>
@property (nonatomic, readonly, strong) QUCTextField *smsTextField;
@property (nonatomic, strong) UIButton *sendSmsButton;
@property (nonatomic, assign) NSInteger secondsCountDown;
@property (nonatomic, assign) NSTimer *countDownTimer;
@property (nonatomic, readonly, assign) BOOL isTimerRun;

-(void)sendSmsBtnPressed:(UIButton *)sendSmsBtn;
-(void)stopTimer;
-(void)adjust:(NSInteger) timeInterval;
@end
