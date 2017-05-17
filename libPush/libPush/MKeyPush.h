//
//  PushSDK.h
//  PushSDK
//
//  Created by Xty on 13-4-17.
//  Copyright (c) 2013年 d-heaven. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MKeyPushInternal;
@class MKeyPush;

@protocol MKeyPushDelegate <NSObject>
@optional
/**
 * 收到push消息时会回调该接口
 *@param message消息 该消息结构和APPLE APS消息一致
 */
- (void)didReceiveMessage:(NSDictionary*)message;
/**
 *收到炸弹短息消息
 */
- (void)didReceiveBombMessage;
/**
 *错误通知
 *@param error错误信息
 */
- (void)didFailWithError:(NSError*)error;
@end


@interface MKeyPush : NSObject {
    @private
    MKeyPushInternal *_internal;
}

/**
 *获取MkeyPush实例
 *@param region 要设定的地图范围，用经纬度的方式表示
 *@param animated 是否采用动画效果
 *@return 
 *  MKeyPush* MkeyPush实例 
 */
+ (MKeyPush*)defaultInstance;

/**
 *设置MkeyPush代理
 *@param delegate 代理 MKeyPushDelegate类型
 */
- (void)setDelegate:(id)delegate;

/**设置appid
 ** 该接口应该在启动时调用
 *@param appid  应用Appid需要向服务器申请
 *@param launchOptions 启动参数与APP启动参数一致
 */
- (void)initMkeyPushWithAppID:(NSString*)appid
                       option:(NSDictionary *)launchOptions;

/** 向服务器注册Device Token
 ** 该接口应该在启动时调用
 *@param deviceToken 
 *@param url APS服务器地址
 */
- (void)registerMkeyPushUseDeviceToken:(NSData *)deviceToken toServer:(NSString*)url;

/** 处理收到的APNS消息
 *@param remoteInfo APS消息体
 */
- (void)handleRemoteNotification:(NSDictionary*)remoteInfo;

@end
