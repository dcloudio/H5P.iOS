//
//  QUCRegisterViewController.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-17.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"
#import "QUCRegByMobileView.h"

@class QUCUserModel;
@class QUCRegByMobileView;

/**
 *	@brief	用户中心使用手机号注册VC
 */
@interface QUCRegByMobileViewController: QUCBasicViewController<UITextFieldDelegate>

@property (nonatomic, strong) QUCRegByMobileView *regByMobileView;

/**
 *  @brief  用户是否可以点击注册按钮，默认业务方不需要关心，而有些业务当成功回调后，需要处理其他逻辑。例如：弹出弹层提示用户，然后可以让用户重新注册，需要用到此属性
 */
@property (nonatomic, assign) BOOL isCanRegister;
/**
 *	@brief	注册时检测到帐号已存在且密码正确时，自动登录，登录成功时回调
 *
 *	@param 	user 	QUCUserModel 含qid及QT及服务器端返回所有信息
 */
-(void) qucLoginSuccessedWithQuser:(QUCUserModel *)user;

/**
 *  清空输入框内容：Mobile、密码、realPassword
 */
-(void) clearTextField;
@end
