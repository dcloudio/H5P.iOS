//
//  QUCRegisterModel.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-27.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

/**
 *	@brief	帐号注册Model，发送通知：
 */
@interface QUCRegisterModel : NSObject


/**
 *	@brief	注册帐号
 *
 *	@param 	account 	帐号
 *	@param 	type 	帐号类型
 *	@param 	password 	密码
 *	@param 	isKeepAlive 	是否保持登录
 *	@param 	smsCode 	短信校验码
 *	@param 	sc 	验证码的头sc
 *	@param 	uc 	用户输入的验证码
 *	@param 	destUrl 	邮箱注册需要激活时，destUrl
 *	@param 	isNeedActive 	是否需要激活
 */
- (void)regWithAccount:(NSString *)account
                  Type:(NSString *)type
              Password:(NSString *)password
           IsKeepAlive:(NSString *)isKeepAlive
               SmsCode:(NSString *)smsCode
                    Sc:(NSString *)sc
                    Uc:(NSString *)uc
               DestUrl:(NSString *)destUrl
          IsNeedActive:(int)isNeedActive;


/**
 *	@brief	注册帐号
 *
 *	@param 	account 	帐号
 *	@param 	type 	帐号类型
 *	@param 	password 	密码
 *	@param 	fields 	返回的用户字段信息，字符串：qid,username,nickname,loginemail,head_pic,expire_alarm
 *	@param 	headType 头像大小：小写字母a/s/m/b/q(分别代表20x20/48x48/64x64/100x100/150x150)
 *	@param 	isKeepAlive 	是否保持登录
 *	@param 	userName 	用户名
 *	@param 	smsCode 	短信校验码
 *	@param 	sc 	验证码的头sc
 *	@param 	uc 	用户输入的验证码
 *	@param 	destUrl 	邮箱注册需要激活时，destUrl
 *	@param 	isNeedActive 	是否需要激活
 *	@param 	resMode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vtGuid  业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
- (void)regWithAccount:(NSString *)account
                  Type:(NSString *)type
              Password:(NSString *)password
                Fields:(NSString *)fields
              HeadType:(NSString *)headType
           IsKeepAlive:(NSString *)isKeepAlive
              UserName:(NSString *)userName
               SmsCode:(NSString *)smsCode
                    Sc:(NSString *)sc
                    Uc:(NSString *)uc
               DestUrl:(NSString *)destUrl
          IsNeedActive:(int)isNeedActive
               ResMode:(QUCIntfResMod)resMode
                VtGuid:(NSString *)vtGuid
              Progress:(QUCHTTPRequestProcessHandler)progressBlock;


@end