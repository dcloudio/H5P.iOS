//
//  QUCTextFieldView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-20.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

//可选协议，供View层判断输入框是否支持快捷菜单
@protocol QUCTextFieldDelegate <NSObject>
@optional
-(BOOL)isCanPerformAction:(SEL)action withSender:(id)sender;
@end

@interface QUCTextField : UITextField
@property (nonatomic, weak) id<QUCTextFieldDelegate> qucTextFieldDelegate;
@end
