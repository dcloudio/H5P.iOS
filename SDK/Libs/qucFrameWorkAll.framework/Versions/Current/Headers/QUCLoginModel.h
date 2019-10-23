//
//  QUCLoginModel.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-27.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

/**
 *	@brief	用户登录Model，发送通知：QUCLoginNotification
 */
@interface QUCLoginModel : NSObject



/**
 *	@brief	帐号登录，默认：sec_type——@"bool"
 *
 *	@param 	account 	帐号
 *	@param 	password 	密码
 *	@param 	sc 	验证码的头sc
 *	@param 	uc 	用户输入的验证码
 *	@param 	isKeepAlive 	是否保持登录
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void) loginWithAccount:(NSString *)account
                Password:(NSString *)password
                      Sc:(NSString *)sc
                      Uc:(NSString *)uc
             IsKeepAlive:(NSString *)isKeepAlive
                Progress:(QUCHTTPRequestProcessHandler)progressBlock;


/**
 *	@brief	帐号登录
 *
 *	@param 	account 	帐号
 *	@param 	password 	密码
 *	@param 	sc 	验证码的头sc
 *	@param 	uc 	用户输入的验证码
 *	@param 	isKeepAlive 	是否保持登录
 *	@param 	fields 	返回的用户字段信息，字符串：qid,username,nickname,loginemail,head_pic,expire_alarm
 *	@param 	headType 头像大小：小写字母a/s/m/b/q(分别代表20x20/48x48/64x64/100x100/150x150)
 *	@param 	secType 	返回用户密保信息(密保邮箱， 登陆邮箱，密保手机等)的 方式：bool/data
 *	@param 	resMode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vtGuid  业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void) loginWithAccount:(NSString *)account
                Password:(NSString *)password
                      Sc:(NSString *)sc
                      Uc:(NSString *)uc
             IsKeepAlive:(NSString *)isKeepAlive
                  Fields:(NSString *)fields
                HeadType:(NSString *)headType
                 SecType:(NSString *)secType
                 ResMode:(QUCIntfResMod)resMode
                  VtGuid:(NSString *)vtGuid
                Progress:(QUCHTTPRequestProcessHandler)progressBlock;

@end
