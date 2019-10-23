//
//  QUCRegByEmailViewController.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-20.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"
#import "QUCSuggestTextFieldView.h"

@class QUCRegByEmailView;
@class QUCUserModel;

typedef enum{
    unKnow, // 没有赋值
    regNeedActive, //注册需要激活
    regUnNeedActive, //注册不需要激活
}isRegNeedActive;

/**
 *	@brief	用户中心使用邮箱注册VC
 */
@interface QUCRegByEmailViewController : QUCBasicViewController<QUCSuggestTextFieldDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) QUCRegByEmailView *regByEmailView;
@property (nonatomic, assign) isRegNeedActive isRegNeedAcive;//for demo
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
 *	@brief	注册参数不需激活情况下，在注册成功后回调
 *
 *	@param 	user    QUCUserModel 含qid及QT及服务器端返回所有信息
 */
-(void) qucRegSuccessedWithQuser:(QUCUserModel *)user;

/**
 *	@brief	注册失败时回调，如错误为：显示验证码等需要互动错误，则不会调用此方法
 *
 *	@param 	errCode 	int类型，登录错误码
 *	@param 	errMsg      NSString类型，登录错误描述
 */
-(void) qucRegFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg;


/**
 *  清空输入框内容：Email、密码、验证码、realPassword
 */
-(void) clearTextField;
@end
