//
//  PGPush.h
//  Pandora
//
//  Created by Pro_C Mac on 13-3-12.
//
//

#import "PGPlugin.h"
#import "PGMethod.h"
#import "PDRCoreDefs.h"
#import <UserNotifications/UserNotifications.h>
#import "H5MultiDelegate.h"

@protocol PGPushServer <UNUserNotificationCenterDelegate>

@end

@interface PGPushServer : H5Server<UNUserNotificationCenterDelegate> {
    H5MultiDelegate *_multiDelegate;
}
@property (readonly, nonatomic) H5MultiDelegate *multiDelegate;
@end

@interface PGPush : PGPlugin
@property (assign, nonatomic) BOOL handleOfflineMsg;
- (void)clear:(PGMethod*)pMethod;
- (void)addEventListener:(PGMethod*)pMethod;
- (void)createMessage:(PGMethod*)pMethod;
- ( NSData* )getClientInfo:(PGMethod*)pMethod;
- (NSMutableDictionary*)getClientInfoJSObjcet;
- (void) onRevRemoteNotification:(NSDictionary *)userInfo isReceive:(BOOL)isReceive;

//override -- option
/// @brief 该方法会保存launchOptions钟remote和locaiton消息
///并开启remote通知监听5+Core APS事件
///PDRCoreRevDeviceToken-PDRCoreRegRemoteNotificationsError
///-PDRCoreAppDidRevLocalNotificationKey-PDRCoreAppDidRevApnsKey
- (void) onCreate;
/// @brief APS注册失败缺少权限或包配置错误
- (void) onRegRemoteNotificationsError:(NSError *)error;
/// @brief DeviceToken获取成功
- (void) onRevDeviceToken:(NSString *)deviceToken;
/**
 @brief 收到APS推送 <br/>
 调用[PDRCore handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:userInfo];<br/>
 会按照5+规范触发rev和click消息,如果自己触发消息可以复写调用dispatchEvent事件
 @param userInfo APS消息(与PDRCoreSysEventRevRemoteNotification事件传递过来的userinfo一致)
 @return 无
 */
- (void) onRevRemoteNotification:(NSDictionary *)userInfo;
/**
 @brief触发JS click receive事件
       JS可以 plus.push.addEventListener监听事件
 @param isRev YES触发receive事件 NO触发click事件
 @param payload 
 @return 无
 */
- (void) dispatchEvent:(BOOL)isRev withPayload:(NSDictionary *)payload;
///@brief该方法在触发事件的同时会按照5+规范进行处理payload
- (void) dispatchEvent:(BOOL)isRev standardPayload:(NSDictionary *)payload;
/// @brief 收到APS推送
//调用[PDRCore handleSysEvent:PDRCoreSysEventRevLocalNotification withObject:userInfo];
//会触发onRevRemoteNotification方法
- (void) onRevLocationNotification:(UILocalNotification *)userInfo;
- (void) onAppEnterBackground;
- (void) onAppEnterForeground;
@end
