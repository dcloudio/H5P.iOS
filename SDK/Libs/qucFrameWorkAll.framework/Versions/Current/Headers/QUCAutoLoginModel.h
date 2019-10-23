//
//  QUCAutoLoginModel.h
//  qucsdk
//
//  Created by simaopig on 14-7-17.
//  Copyright (c) 2014年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

/**
 *	@brief	自动登录Model，发送通知：QUCAutoLoginNotification
 */
@interface QUCAutoLoginModel : NSObject


/**
 *	@brief	自动登录 ,fields传递为：qid,username,nickname,loginemail,head_pic,expire_alarm 头像为：s errDetailFlag为：1
 *	@param 	Q 	Cookie Q
 *	@param 	T 	Cookie T
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void)autoLoginWithQ:(NSString *)Q
                    T:(NSString *)T
             Progress:(QUCHTTPRequestProcessHandler)progressBlock;


/**
 *	@brief	自动登录
 *	@param 	Q 	Cookie Q
 *	@param 	T 	Cookie T
 *	@param 	fields 	返回的用户字段信息，字符串：qid,username,nickname,loginemail,head_pic,expire_alarm
 *	@param 	headType 头像大小：小写字母a/s/m/b/q(分别代表20x20/48x48/64x64/100x100/150x150)
 *	@param 	errDetailFlag 	当参数为QUCIntf_AUTOLOGIN_QTERRDESC_YES时，自动登录校验失败返回更详细的错误码标识 ，说明真实原因
 *	@param 	resMode 	返回结果类型，默认为json，当指定为QUCINTF_RES_MODE_DES时，返回DES加密的结果，本方法会对返回结果自动解密
 *  @param  vtGuid  业务方可传递随机数给用户中心，用户中心会在header返回同样的值
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
-(void)autoLoginWithQ:(NSString *)Q
                    T:(NSString *)T
               Fields:(NSString *)fields
             HeadType:(NSString *)headType
      ErrorDetailFlag:(QUCIntfAutoLoginQTErrdesc)errDetailFlag
              ResMode:(QUCIntfResMod)resMode
               VtGuid:(NSString *)vtGuid
             Progress:(QUCHTTPRequestProcessHandler)progressBlock;

@end
