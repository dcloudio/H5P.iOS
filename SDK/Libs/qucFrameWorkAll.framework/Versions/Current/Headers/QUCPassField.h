//
//  QUCPassFieldView.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-20.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QUCPassField : UIView
@property (nonatomic, assign) BOOL isShowPassword;
@property (nonatomic, strong) UITextField *passTextField;
@property (nonatomic, strong) UIButton *showPassButton;

- (id)initWithFrame:(CGRect)frame withScene:(NSString *)scene;

- (void) toggleShowPassButton;
@end
