//
//  QUCCaptchaModel.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-26.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCInterface.h"

/**
 *	@brief	获取验证码Model，发送通知：QUCCaptchaNotification
 */
@interface QUCCaptchaModel : NSObject

/**
 *	@brief	获取验证码
 *
 *	@param 	progressBlock 	请求过程中回调^(float progress){}
 */
- (void)getCaptchaWithProgress:(QUCHTTPRequestProcessHandler)progressBlock;


@end
