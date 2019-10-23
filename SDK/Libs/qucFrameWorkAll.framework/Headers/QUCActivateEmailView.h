//
//  QUCActivateEmailView.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-25.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QUCActivateEmailView : UIView
/**
 *	@brief	激活页面的header头，现为“激活邮件已发送至您的邮箱”
 */
@property (nonatomic, readonly, strong) UILabel *headLabel;

/**
 *	@brief	激活页面显示的用户邮箱
 */
@property (nonatomic, strong) UILabel *emailLabel;

/**
 *	@brief	激活页面显示的提醒信息，现为”请在48小时内..."
 */
@property (nonatomic, readonly, strong) UILabel *remindLabel;

/**
 *	@brief	去邮箱收信的button
 */
@property (nonatomic, readonly, strong) UIButton *goMailboxButton;

@end
