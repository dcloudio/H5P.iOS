//
//  QUCActiveModel.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-1.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

typedef enum{
    QUCINTF_ACTIVE_ACCOUNTTYPE_EMAIL = 1,//邮箱
    QUCINTF_ACITVE_ACCOUNTTYPE_NAME  = 4,//用户名
}QUCINTF_ACITVE_ACCOUNTTYPE;

/**
 *	@brief	发送激活邮件Model，发送通知：QUCActiveNotification
 */
@interface QUCActiveModel : NSObject

/**
 *	@brief	发送激活邮件
 *
 *	@param 	account 	帐号
 *	@param 	type 	帐号类型，仅支持邮箱和用户名
 *	@param 	destUrl 	邮箱中回调的destUrl
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */

-(void) sendActiveEmailWithAccount:(NSString *)account
                              Type:(QUCINTF_ACITVE_ACCOUNTTYPE)type
                           DestUrl:(NSString *)destUrl
                          Progress:(QUCHTTPRequestProcessHandler)progressBlock;


/**
 *	@brief	发送激活邮件
 *
 *	@param 	account 	帐号
 *	@param 	type        帐号类型，仅支持邮箱和用户名
 *	@param 	destUrl 	邮箱中回调的destUrl
 *	@param 	resMode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vtGuid      业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void) sendActiveEmailWithAccount:(NSString *)account
                              Type:(QUCINTF_ACITVE_ACCOUNTTYPE)type
                           DestUrl:(NSString *)destUrl
                           ResMode:(QUCIntfResMod)resMode
                            VtGuid:(NSString *)vtGuid
                          Progress:(QUCHTTPRequestProcessHandler)progressBlock;

@end
