//
//  QUCfindAccountPwdModel.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QUCConstants.h"
#import "QUCInterface.h"

/**
 *	@brief	找回密码Model，发送通知：QUCFindPwdNotification
 */
@interface QUCFindAccountPwdModel : NSObject



/**
 *	@brief	找回密码，默认传递：自动登录autoLogin QUCINTF_AUTOLOGIN_YES、返回帐号激活状态secType bool、Fields:@"qid, username,nickname,loginemail,head_pic" headType:@"s"
 *
 *	@param 	account 	帐号
 *	@param 	smsCode 	短信校验码
 *	@param 	newPwd 	新密码
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void)findAccountPwdWithAccount:(NSString *)account
                         SmsCode:(NSString *)smsCode
                          NewPwd:(NSString *)newPwd
                        Progress:(QUCHTTPRequestProcessHandler)progressBlock;


/**
 *	@brief	找回密码
 *
 *	@param 	account 	帐号
 *	@param 	smsCode 	短信校验码
 *	@param 	newPwd 	新密码
 *	@param 	autoLogin 	是否自动登录
 *	@param 	secType 	返回用户密保信息(密保邮箱， 登陆邮箱，密保手机等)的 方式：bool/data
 *	@param 	fields 	返回的用户字段信息，字符串：qid,username,nickname,loginemail,head_pic,expire_alarm
 *	@param 	headType 头像大小：小写字母a/s/m/b/q(分别代表20x20/48x48/64x64/100x100/150x150)
 *	@param 	resMode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vtGuid  业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void)findAccountPwdWithAccount:(NSString *)account
                         SmsCode:(NSString *)smsCode
                          NewPwd:(NSString *)newPwd
                       AutoLogin:(QUCINTF_AUTOLOGIN_TYPE)autoLogin
                         SecType:(NSString *)secType
                        Fields:(NSString *)fields
                        HeadType:(NSString *)headType
                         ResMode:(QUCIntfResMod)resMode
                          VtGuid:(NSString *)vtGuid
                        Progress:(QUCHTTPRequestProcessHandler)progressBlock;


@end
