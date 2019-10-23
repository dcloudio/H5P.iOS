//
//  QUCSetPwdViewController.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"

@class QUCSetPwdView;
@class QUCUserModel;

/**
 *	@brief	找回密码第三步：设置新密码vc
 */
@interface QUCSetPwdViewController : QUCBasicViewController<UITextFieldDelegate>


@property (nonatomic,strong) QUCSetPwdView *setpwdView;
/**
 *  @brief  用户是否可以点击保存密码按钮，默认业务方不需要关心，而有些业务当成功回调后，需要处理其他逻辑。例如：弹出弹层提示用户，然后可以让用户重新注册，需要用到此属性
 */
@property (nonatomic, assign) BOOL isCanSavePwd;
/**
 *	@brief  找回密码后可自动登录，登录失败时回调
 *
 *	@param 	errCode int 错误码
 *	@param 	errMsg  NSString 错误消息
 */
-(void) qucLoginFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg;

/**
 *	@brief	找回密码后可自动登录，登录成功时回调
 *
 *	@param 	user    QUCUserModel 包含qid、QT及服务器端返回全部信息
 */
-(void) qucLoginSuccessedWithQuser:(QUCUserModel *)user;

/**
 *  清空输入框内容：密码、realPassword
 */
-(void) clearTextField;


@end
