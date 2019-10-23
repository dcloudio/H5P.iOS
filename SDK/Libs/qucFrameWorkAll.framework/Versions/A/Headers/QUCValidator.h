//
//  QUCValidator.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-23.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum
{
    NoError,         //没有错误
    PasswordInValid, //密码长度不合法
    PasswordRepeat,  //密码全为重复字符
    PasswordOrderd,  //密码为连续字符
    PasswordWeak,    //密码为弱密码
}PasswordError;

#define PassWordMinLen  6 //用户中心要求密码最短为6位
#define PassWordMaxLen  20//用户中心要求密码最长为20位

/**
 *	@brief	校验用户信息类
 */
@interface QUCValidator : NSObject
/**
 *	@brief	校验手机号是否合法
 *
 *	@param 	phoneNum 	手机号
 *
 *	@return	nil or errMsg
 */
+ (NSString *)validPhoneNum:(NSString *)phoneNum;

/**
 *	@brief	校验密码，登陆场景不检查弱密码
 *
 *	@param 	password 	密码
 *	@param 	flag 	是否需要校验弱密码
 *
 *	@return	nil or errMsg
 */
+ (NSString *)validPassword:(NSString *)password checkWeakPassword:(BOOL)flag;

/**
 *	@brief	校验帐号是否合法：仅校验了是否为空，防止服务器端逻辑调整
 *
 *	@param 	account 	帐号信息
 *
 *	@return	nil or errMsg
 */
+ (NSString *)validLoginAccount:(NSString *)account;
/**
 *	@brief	校验短信验证码是否合法：仅校验了是否为空，防止服务器端逻辑调整
 *
 *	@param 	smsCode 	短信验证码
 *
 *	@return	nil or errMsg
 */
+ (NSString *)validSmsCode:(NSString *)smsCode;

/**
 *	@brief	校验邮箱是否合法：校验了不能为空、是否符合邮箱正则
 *
 *	@param 	email 	邮箱
 *
 *	@return	nil or errMsg
 */
+ (NSString *)validEmail:(NSString *)email;

/**
 *	@brief	校验验证码是否合法：校验了验证码长度
 *
 *	@param 	captcha 	校验码
 *
 *	@return	nil or errMsg
 */
+ (NSString *)validCaptcha:(NSString *)captcha;

/**
 *	@brief	校验手机号是否合法
 *
 *	@param 	phoneNum 	手机号
 *
 *	@return	YES or NO
 */
+ (BOOL)isValidPhoneNum:(NSString *)phoneNum;

/**
 *	@brief	校验是否含有中文字符（密码中不能含有中文字符）
 *
 *	@param 	str 	字符串
 *
 *	@return	YES or NO
 */
+ (BOOL)hasChineseChar:(NSString *)str;

/**
 *	@brief	校验是否含有Ascii字符
 *
 *	@param 	str 	字符串
 *
 *	@return	YES or NO
 */
+ (BOOL)isAsciiString:(NSString *)str;

/**
 *  用特定的正则表达式，进行匹配，返回特定的结果
 *
 *  @param mobile  手机号
 *  @param regex   正则表达式
 *  @param message 需要返回的message
 *
 *  @return message
 */
+ (NSString *)validMobile:(NSString *)mobile regex:(NSString *)regex message:(NSString *)message;

@end
