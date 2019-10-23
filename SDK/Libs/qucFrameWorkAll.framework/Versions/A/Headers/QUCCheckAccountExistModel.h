//
//  QUCCheckAccountExistModel.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-6-27.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

/**
 *	@brief	用户中心检测帐号是否已存在接口，发送通知：QUCCheckAccountExistNotification
 */
@interface QUCCheckAccountExistModel : NSObject


/**
 *	@brief	检测帐号存在性
 *
 *	@param 	account 	帐号
 *	@param 	type 	帐号类型
 */
- (void)checkAccountExistWithAccount:(NSString *)account
                                Type:(NSString *)type;


/**
 *	@brief	检测帐号存在性
 *
 *	@param 	account 	帐号
 *	@param 	type 	帐号类型
 *	@param 	res_mode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vt_guid  业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
- (void)checkAccountExistWithAccount:(NSString *)account
                                Type:(NSString *)type
                             ResMode:(QUCIntfResMod)resMode
                              VtGuid:(NSString *)vtGuid
                            Progress:(QUCHTTPRequestProcessHandler)progressBlock;


@end