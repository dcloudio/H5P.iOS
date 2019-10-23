
//
//  QUCLoginViewController.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-17.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"
#import "QUCSuggestTextFieldView.h"
#import "QUCRegionItem.h"

@class QUCLoginView;
@class QUCUserModel;

@class QUCUnderlineButton;
/**
 *	@brief	用户中心登录VC，dict支持account、password、以及登录后的回调data
 */
@interface QUCLoginViewController: QUCBasicViewController<QUCSuggestTextFieldDataSource,UITextFieldDelegate,UIGestureRecognizerDelegate>
@property (nonatomic, strong) QUCLoginView *loginView;
@property (nonatomic, strong) QUCRegionItem *regionItem;

/**
 *  @brief  用户是否可以点击登录按钮，默认业务方不需要关心，而有些业务当成功回调后，需要处理其他逻辑。例如：弹出弹层提示用户，然后可以让用户重新登录，需要用到此属性
 */
@property (nonatomic, assign) BOOL isCanLogin;

/**
 *	@brief	登录失败时回调，如错误为：显示验证码等需要互动错误，则不会调用此方法
 *
 *	@param 	errCode 	int类型，登录错误码
 *	@param 	errMsg      NSString类型，登录错误描述
 */
-(void) qucLoginFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg;

/**
 *	@brief	登录成功时回调
 *
 *	@param 	user 	QUCUserModel 包含qid、QT及服务器端返回全部信息
 */
-(void) qucLoginSuccessedWithQuser:(QUCUserModel *)user;

/**
 *  清空输入框内容：用户名、密码、验证码、realPassword
 */
-(void) clearTextField;

/**
 *  点击找回密码跳转方法
 */
-(void) findPwdBtnPressed:(id) sender;
@end
