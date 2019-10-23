//
//  QUCSendSmsCode.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-27.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

/**
 *	@brief	发短信Model，发送通知：QUCSendSmsCodeNotification
 */
@interface QUCSendSmsCodeModel : NSObject


/**
 *	@brief	发送短信校验码
 *
 *	@param 	account 	帐号
 *	@param 	condition 	发送场景
 */
- (void)sendSmsCodeWithAccount:(NSString *)account
                     Condition:(NSString *)condition;


/**
 *	@brief	发送短信校验码
 *
 *	@param 	account 	帐号
 *	@param 	condition 	发送场景
 *	@param 	resMode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vtGuid  业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
- (void)sendSmsCodeWithAccount:(NSString *)account
                     Condition:(NSString *)condition
                       ResMode:(QUCIntfResMod)resMode
                        VtGuid:(NSString *)vtGuid
                      Progress:(QUCHTTPRequestProcessHandler)progressBlock;


@end
