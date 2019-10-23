//
//  MiPushSDK.h
//  MiPushSDK
//
//  Created by shen yang on 14-3-6.
//  Copyright (c) 2014年 Xiaomi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MiPushSDKDelegate <NSObject>

@optional

/**
 * MiPushSDK 请求结果回调
 *
 * MiPushSDK的所有请求的为异步操作, 用户需监听此方法.
 *
 * @param
 *     selector: 请求的方法
 *     data: 返回结果字典
 */
- (void)miPushRequestSuccWithSelector:(NSString *)selector data:(NSDictionary *)data;
- (void)miPushRequestErrWithSelector:(NSString *)selector error:(int)error data:(NSDictionary *)data;


/**
 * 启用长连接后, 当收到消息是就会回调此方法
 *
 * @param
 *     type: 消息类型
 *     data: 返回结果字典, 跟apns的消息格式一样
 */
- (void)miPushReceiveNotification:(NSDictionary*)data;

@end

@interface MiPushSDK : NSObject

/**
 * 客户端注册设备
 * @param 
 *      delegate: 回调函数
 *      type: apns推送类型. (Badge, Alert, Sound)
 *      connect: 是否启动长连接, 它跟APNSs是不同的通道(不管是否启动系统推送, app在前台都可以收到在线或离线消息)
 */
+ (void)registerMiPush:(id<MiPushSDKDelegate>)delegate;
+ (void)registerMiPush:(id<MiPushSDKDelegate>)delegate type:(UIRemoteNotificationType)type;
+ (void)registerMiPush:(id<MiPushSDKDelegate>)delegate type:(UIRemoteNotificationType)type connect:(BOOL)connect;

/**
 * 客户端设备注销
 */
+ (void)unregisterMiPush;


/**
 * 绑定 PushDeviceToken
 *
 * NOTE: 有时Apple会重新分配token, 所以为保证消息可达,
 * 必须在系统application:didRegisterForRemoteNotificationsWithDeviceToken:回调中,
 * 重复调用此方法. SDK内部会处理是否重新上传服务器.
 *
 * @param 
 *     deviceToken: AppDelegate中,PUSH注册成功后,
 *                  系统回调didRegisterForRemoteNotificationsWithDeviceToken
 */
+ (void)bindDeviceToken:(NSData *)deviceToken;

/**
 * 当同时启动APNs与内部长连接时, 把两处收到的消息合并. 通过miPushReceiveNotification返回
 */
+ (void)handleReceiveRemoteNotification:(NSDictionary*)userInfo;

/**
 * 客户端设置别名
 *
 * @param
 *     alias: 别名 (length:128)
 */
+ (void)setAlias:(NSString *)alias;

/**
 * 客户端取消别名
 *
 * @param
 *     alias: 别名 (length:128)
 */
+ (void)unsetAlias:(NSString *)alias;


/**
 * 客户端设置帐号
 * 多设备设置同一个帐号, 发送消息时多设备可以同时收到
 *
 * @param
 *     account: 帐号 (length:128)
 */
+ (void)setAccount:(NSString *)account;

/**
 * 客户端取消帐号
 *
 * @param
 *     account: 帐号 (length:128)
 */
+ (void)unsetAccount:(NSString *)account;


/**
 * 客户端设置主题
 * 支持同时设置多个topic, 中间使用","分隔
 *
 * @param
 *     subscribe: 主题类型描述
 */
+ (void)subscribe:(NSString *)topics;

/**
 * 客户端取消主题
 * 支持同时设置多个topic, 中间使用","分隔
 *
 * @param
 *     subscribe: 主题类型描述
 */
+ (void)unsubscribe:(NSString *)topics;


/**
 * 统计客户端 通过push开启app行为
 * 如果, 你想使用服务器帮你统计你app的点击率请自行调用此方法
 * 方法放到:application:didReceiveRemoteNotification:回调中.
 * @param 
 *      messageId:Payload里面对应的miid参数
 */
+ (void)openAppNotify:(NSString *)messageId;


/**
 * NOTE 废弃. 请使用getAllAliasAsync替换
 * 获取客户端所有设置的别名
 */
+ (NSArray*)getAllAlias __deprecated;

/**
 * 获取客户端所有设置的别名
 */
+ (void)getAllAliasAsync;

/**
 * NOTE 废弃. 请使用getAllTopicAsync替换
 * 获取客户端所有订阅的主题
 */
+ (NSArray*)getAllTopic __deprecated;

/**
 * 获取客户端所有订阅的主题
 */
+ (void)getAllTopicAsync;

+ (void)getAllAccountAsync;


/**
 * 获取SDK版本号
 */
+ (NSString*)getSDKVersion;

/**
 * 获取RegId
 * 如果没有RegId返回nil
 */
+ (NSString*)getRegId;
@end
