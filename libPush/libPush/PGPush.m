//
//  PGPush.m
//  Pandora
//
//  Created by Pro_C Mac on 13-3-12.
//
//

#import "PGPush.h"
#import "PDRCoreWindowManager.h"
#import "PDRCore.h"
#import "PDRCoreAppPrivate.h"
//#import "PDRCoreAppPrivate.h"
#import "DC_JSON.h"
#import  "PDRCommonString.h"
#import "PDRCorePrivate.h"
#import "PDRCoreAppWindow.h"
#import "PDRCoreAppFrame.h"
#import "PDRCoreAppFramePrivate.h"
#import "PDRToolSystemEx.h"

@implementation PGPushServer
@synthesize multiDelegate = _multiDelegate;

- (id)init{
    if ( self = [super init] ) {
        
    }
    return self;
}

-(void)onCreate {
    _multiDelegate = [[H5MultiDelegate alloc] init];
    [self registerForRemoteNotificationTypes];
    [self enableRevAps];
}

-(void)onDestroy {
    [self disableRevAps];
    [_multiDelegate release];
    _multiDelegate = nil;
}

- (void) registerForRemoteNotificationTypes {
   // static dispatch_once_t onceToken;
    //dispatch_once(&onceToken, ^{
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (!error) {
            }
        }];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series ) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge);
        // if ( apn_type != [sharedApplication enabledRemoteNotificationTypes] ) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
        // }
    }
   // });
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    [_multiDelegate enumerateDelegateUsingBlock:^(id<UNUserNotificationCenterDelegate> obj, NSUInteger idx, BOOL *stop) {
        if ( [obj respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)] ) {
            [obj userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
        }
    }];
}
/**/
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    [_multiDelegate enumerateDelegateUsingBlock:^(id<UNUserNotificationCenterDelegate> obj, NSUInteger idx, BOOL *stop) {
        if ( [obj respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)] ) {
            [obj userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        }
    }];
}

- (void) handleRegRemoteNotificationsError:(NSNotification *)userInfo {
    if ( [self respondsToSelector:@selector(onRegRemoteNotificationsError:)] ) {
        [self performSelector:@selector(onRegRemoteNotificationsError:) withObject:userInfo.object];
    }
}

- (void) handleRevDeviceToken:(NSNotification *)userInfo {
    if ( [self respondsToSelector:@selector(onRevDeviceToken:)] ) {
        [self performSelector:@selector(onRevDeviceToken:) withObject:userInfo.object];
    }
}/*
  */

- (void) enableRevAps {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRevDeviceToken:) name:PDRCoreRevDeviceToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRegRemoteNotificationsError:) name:PDRCoreRegRemoteNotificationsError object:nil];
    
}

- (void) disableRevAps {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRCoreRegRemoteNotificationsError object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRCoreRevDeviceToken object:nil];
   
}

- (void)dealloc {
    [super dealloc];
}

@end

@interface PGPush() {
    NSMutableArray *m_pApsListenerList;
    NSMutableDictionary *_apsCache;
    NSMutableDictionary *_localNotiCache;
}
@end

BOOL bIsDeactivate = NO;

@implementation PGPush
@synthesize handleOfflineMsg;

- (void)onCreate {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRevLocationNotification:) name:PDRCoreAppDidRevLocalNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRevRemoteNotification:) name:PDRCoreAppDidRevApnsKey object:nil];
    NSDictionary* options = [PDRCore Instance].launchOptions;
    self.handleOfflineMsg = YES;
    NSDictionary* userInfo  = [options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if ( userInfo ) {
        self.handleOfflineMsg = NO;
        [self saveRemoteMessage:userInfo isReceive:NO];
    }
    UILocalNotification *localNotif = [options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if ( localNotif ) {
        [self saveLocalMessage:localNotif isReceive:NO];
    }
}

//- (void) registerForRemoteNotificationTypes {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series ) {
//            [[UIApplication sharedApplication] registerForRemoteNotifications];
//            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound) categories:nil];
//            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
//        } else {
//            UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge);
//            // if ( apn_type != [sharedApplication enabledRemoteNotificationTypes] ) {
//            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
//            // }
//        }
//    });
//}
- (void) onRegRemoteNotificationsError:(NSError *)error {}
/// @brief DeviceToken获取成功
- (void) onRevDeviceToken:(NSString *)deviceToken {}
- (void)onDidBecomeActive:(NSNotification *)notification
{
    bIsDeactivate = NO;
}

- (void)onWillResignActive:(NSNotification *)notification
{
    self.handleOfflineMsg = YES;
    bIsDeactivate = YES;
}

//- (void) onAppStarted:(NSDictionary*)options {
//    NSDictionary* options = [PDRCore Instance].launchOptions;
//    self.handleOfflineMsg = YES;
//    NSDictionary* userInfo  = [options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//    if ( userInfo ) {
//        self.handleOfflineMsg = NO;
//        [self saveRemoteMessage:userInfo isReceive:NO];
//    }
//    UILocalNotification *localNotif = [options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
//    if ( localNotif ) {
//        [self saveLocalMessage:localNotif isReceive:NO];
//    }
//   // [self enableRevAps];
//   // [self registerForRemoteNotificationTypes];
//}
- (void) dispatchEvent:(BOOL)isRev withPayload:(NSDictionary *)userInfo {
    if ( [userInfo isKindOfClass:[NSDictionary class]] ) {
        NSMutableDictionary *payload = [NSMutableDictionary dictionary];
        [payload addEntriesFromDictionary:userInfo];
        [payload setObject:isRev? g_pdr_string_receive:g_pdr_string_click forKey:g_pdr_string_type];
        if ( [self doRevApnsWithDict:payload] ) {
        } else {
            [self saveRemoteMessage:userInfo isReceive:isRev];
        }
    }
}

- (void) dispatchEvent:(BOOL)isRev standardPayload:(NSDictionary *)payload {
    [self onRevRemoteNotification:payload isReceive:isRev];
}
#pragma mark -
- (NSString*)formatObject:(id)object {
    if ( [object isKindOfClass:[NSString class]] ) {
        return object;
    } else if ( [object isKindOfClass:[NSDictionary class]] ){
        return [object toJSONString];
    }
    return @"";
}

- (void) onRevRemoteNotification:(NSNotification *)userInfo {
    self.handleOfflineMsg = NO;
    [self onRevRemoteNotification:userInfo.object isReceive:!bIsDeactivate];
//    NSDictionary *package = [self packageApsMessage2JSPushMessage:userInfo.object type:!bIsDeactivate ? g_pdr_string_receive :g_pdr_string_click];
//    if ( [self doRevApnsWithDict:package] ) {
//    } else {
//        [self saveRemoteMessage:userInfo.object isReceive:!bIsDeactivate];
//    }
}

- (void) onRevRemoteNotification:(NSDictionary *)userInfo isReceive:(BOOL)isReceive{
    BOOL isRemote = NO;
    NSDictionary *apsPayload = nil;
    NSMutableDictionary *package = [self packageApsMessage2JSPushMessage:userInfo
                                                             type:isReceive?g_pdr_string_receive :g_pdr_string_click
                                                 remoteNofication:&isRemote
                                                    remotePayload:&apsPayload];
//    if ( isRemote && [apsPayload isKindOfClass:[NSDictionary class]] ) {
//        UILocalNotification* pLocalNot = [[[UILocalNotification alloc] init] autorelease];
//        if (pLocalNot)
//        {
//            pLocalNot.fireDate = [[[NSDate alloc] initWithTimeIntervalSinceNow:0] autorelease];
//            pLocalNot.alertTitle = [self formatObject:[apsPayload objectForKey:g_pdr_string_title]];
//            pLocalNot.alertBody = [self formatObject:[apsPayload objectForKey:g_pdr_string_content]];
//            pLocalNot.userInfo = apsPayload;
//            // pLocalNot.alertAction = pPayload;
//            //pLocalNot.hasAction = YES;
//            [[UIApplication sharedApplication] scheduleLocalNotification:pLocalNot];
//        }
//        
//    }else
    {
        isReceive = isRemote?YES:isReceive;
        [package setObject:isReceive?g_pdr_string_receive :g_pdr_string_click forKey:g_pdr_string_type];
        if ( [self doRevApnsWithDict:package] ) {
        } else {
            [self saveRemoteMessage:userInfo isReceive:isReceive];
        }
    }
}

- (void) onRevLocationNotification:(NSObject *)userInfo isReceive:(BOOL)isReceive {
    if ( [self processLocalMessage:userInfo type:isReceive ? g_pdr_string_receive :g_pdr_string_click] ) {
    } else {
        [self saveLocalMessage:userInfo isReceive:isReceive];
    }
}

- (void) onRevLocationNotification:(NSNotification *)userInfo {
    if ( [self processLocalMessage:userInfo.object type:!bIsDeactivate ? g_pdr_string_receive :g_pdr_string_click] ) {
    } else {
        [self saveLocalMessage:userInfo.object isReceive:!bIsDeactivate];
    }
}

- (void) onAppEnterBackground {

}

- (void) onAppEnterForeground {
    
}
#pragma mark - 插件接口
- ( NSData* )getClientInfo:(PGMethod*)pMethod
{
    NSMutableDictionary *clientInfo = [self getClientInfoJSObjcet];
    return [self resultWithJSON:clientInfo];
}

- (NSMutableDictionary*)getClientInfoJSObjcet {
    NSMutableDictionary *clientInfo = [NSMutableDictionary dictionary];
    NSString* pToken = [PDRCore Instance].deviceToken;
    if ( pToken )  {
        [clientInfo setObject:pToken forKey:g_pdr_string_token];
    } else {
        [clientInfo setObject:g_pdr_string_empty forKey:g_pdr_string_token];
    }
    return clientInfo;
}

- (void)addEventListener:(PGMethod*)pMethod
{
    NSString* pCallBackID = nil;
    NSString* pListenType = g_pdr_string_receive;
    NSString* pComeFromFrameId = nil;
    
    pComeFromFrameId = [pMethod.arguments objectAtIndex:0];
    pCallBackID = [pMethod.arguments objectAtIndex:1];
    NSString *tempListenType = [pMethod.arguments objectAtIndex:2];
    if ( [tempListenType isKindOfClass:[NSString class]] ) {
        if ( [g_pdr_string_receive isEqualToString:tempListenType]
            || [g_pdr_string_click isEqualToString:tempListenType] ) {
                pListenType = [tempListenType lowercaseString];
        }
    }
    
    if ( [pCallBackID isKindOfClass:[NSString class]]) {
        NSMutableDictionary* pClickEventListent = [NSMutableDictionary dictionary];
        if (pClickEventListent) {
            [pClickEventListent setObject:pCallBackID forKey:@"CBID"];
            [pClickEventListent setObject:pListenType forKey:g_pdr_string_type];
            [pClickEventListent setObject:pComeFromFrameId forKey:g_pdr_string_id];
        }
        if ( !m_pApsListenerList ) {
            m_pApsListenerList = [[NSMutableArray alloc] initWithCapacity:10];
        }
        [m_pApsListenerList addObject:pClickEventListent];
        
        //检查是否有消息有的话立刻通知
        NSArray *messageList = [self getRemoteMessageWithType:pListenType];
        if ( messageList ) {
            BOOL bProcess = NO;
            for ( NSDictionary *userInfo in messageList ) {
                NSDictionary *package = [self packageApsMessage2JSPushMessage:userInfo type:pListenType remoteNofication:nil remotePayload:nil];
                bProcess = bProcess || [self doRevApnsWithDict:package];
            }
            if ( bProcess ) {
                [self clearRemoteMessageWithType:pListenType];
            }
        }
        //检查是否有消息有的话立刻通知
        NSArray *LocalMessages = [self getLocalMessageWithType:pListenType];
        if ( LocalMessages ) {
            BOOL bProcess = NO;
            for ( UILocalNotification *localNotif in LocalMessages ) {
                bProcess = bProcess || [self processLocalMessage:localNotif type:pListenType];
            }
            if ( bProcess ) {
                [self clearLocalMessageWithType:pListenType];
            }
        }
    }
}

- (void)clear:(PGMethod*)pMethod
{
    UIApplication* application = [UIApplication sharedApplication];
    NSArray* scheduledNotifications = [NSArray arrayWithArray:application.scheduledLocalNotifications];
    application.scheduledLocalNotifications = scheduledNotifications;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)createMessage:(PGMethod*)pMethod
{
    CGFloat fDelay = 0.0f;
    NSString* pMessage = nil;
    NSString* pPayload = nil;
    NSString* sound = nil;
    
    pMessage = [PGPluginParamHelper getStringValue:[pMethod getArgumentAtIndex:0]];
    pPayload = [PGPluginParamHelper getStringValue:[pMethod getArgumentAtIndex:1]];
    NSDictionary *options = [pMethod getArgumentAtIndex:2];
    fDelay = [PGPluginParamHelper getFloatValueInDict:options forKey:g_pdr_string_delay defalut:0.0f];
    sound = [PGPluginParamHelper getStringValueInDict:options forKey:@"sound" defalut:g_pdr_string_system];

    UILocalNotification* pLocalNot = [[[UILocalNotification alloc] init] autorelease];
    if (pLocalNot)
    {
        pLocalNot.fireDate = [[[NSDate alloc] initWithTimeIntervalSinceNow:fDelay] autorelease];
        pLocalNot.alertBody = pMessage;
        if ( [pPayload isKindOfClass:[NSString class]]
            || [pPayload isKindOfClass:[NSDictionary class]]) {
            pLocalNot.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pPayload ? pPayload:@"",@"payload", nil];
        }
        if ( !(sound && NSOrderedSame == [sound caseInsensitiveCompare:g_pdr_string_none]) ) {
            pLocalNot.soundName = UILocalNotificationDefaultSoundName;
        }
       // pLocalNot.alertAction = pPayload;
        //pLocalNot.hasAction = YES;
        [[UIApplication sharedApplication] scheduleLocalNotification:pLocalNot];
    }
}

#pragma mark - 消息保存接口
- (void)saveLocalMessage:(UILocalNotification*)localMessage isReceive:(BOOL)receive {
    if ( nil == _localNotiCache ) {
        _localNotiCache = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    if ( !receive ) {
        [_localNotiCache setObject:[NSArray arrayWithObject:localMessage] forKey:g_pdr_string_click];
    } else {
        NSMutableArray *localMessages = [_apsCache objectForKey:g_pdr_string_receive];
        if ( !localMessages ) {
            localMessages = [NSMutableArray array];
            [_localNotiCache setObject:localMessages forKey:g_pdr_string_receive];
        }
        [localMessages addObject:localMessage];
        //[_localNotiCache setObject:localMessage forKey:g_pdr_string_receive];
    }
}

- (void)clearLocalMessageWithType:(NSString*)type{
    if ( _localNotiCache ) {
        [_localNotiCache removeObjectForKey:type];
    }
}

- (void)clearLocalMessage{
    if ( _localNotiCache ) {
        [_localNotiCache removeAllObjects];
        [_localNotiCache release];
        _localNotiCache = nil;
    }
}

- (NSArray*)getLocalMessageWithType:(NSString*)type {
    if ( _localNotiCache ) {
        return [_localNotiCache objectForKey:type];
    }
    return nil;
}

- (void)saveRemoteMessage:(NSDictionary*)remoteMessage isReceive:(BOOL)receive{
    if ( remoteMessage ) {
        if ( nil == _apsCache ) {
            _apsCache = [[NSMutableDictionary alloc] initWithCapacity:2];
        }
        if ( !receive ) {
            [_apsCache setObject:[NSArray arrayWithObject:remoteMessage]  forKey:g_pdr_string_click];
        } else {
            NSMutableArray *remoteMessagelist = [_apsCache objectForKey:g_pdr_string_receive];
            if ( !remoteMessagelist ) {
                remoteMessagelist = [NSMutableArray array];
                [_apsCache setObject:remoteMessagelist forKey:g_pdr_string_receive];
            }
            [remoteMessagelist addObject:remoteMessage];
        }
    }
}

- (void)clearRemoteMessageWithType:(NSString*)type{
    if ( _apsCache ) {
        [_apsCache removeObjectForKey:type];
    }
}

- (void)clearRemoteMessage{
    if ( _apsCache ) {
        [_apsCache removeAllObjects];
        [_apsCache release];
        _apsCache = nil;
    }
}

- (NSArray*)getRemoteMessageWithType:(NSString*)type {
    if ( _apsCache ) {
        return [_apsCache objectForKey:type];
    }
    return nil;
}
#pragma mark - UNUserNotificationCenter delegate iOS 10
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if ( [notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]] ) {
        [self onRevRemoteNotification:notification.request.content.userInfo isReceive:YES];
        
        //[PDRCore handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:notification.request.content.userInfo];
        completionHandler(UNNotificationPresentationOptionNone);
    } else {
        [self onRevLocationNotification:notification.request.content isReceive:YES];
        //[PDRCore handleSysEvent:PDRCoreSysEventRevLocalNotification withObject:notification.request.content];
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    }
}
/**/
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    if ( [response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]] ) {
        [self onRevRemoteNotification:response.notification.request.content.userInfo isReceive:NO];
        //[PDRCore handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:response.notification.request.content.userInfo];
    } else {
        [self onRevLocationNotification:response.notification.request.content isReceive:NO];
       // [PDRCore handleSysEvent:PDRCoreSysEventRevLocalNotification withObject:response.notification.request.content];
    }
    completionHandler();
}
#pragma mark - 消息监听处理
- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    NSMutableArray *removeItems = [NSMutableArray array];
    for ( NSDictionary *dict in m_pApsListenerList) {
        NSString *frameId = [dict objectForKey:g_pdr_string_id];
        if ( frameId && NSOrderedSame == [frameId caseInsensitiveCompare:theAppframe.frameID] ) {
            [removeItems addObject:dict];
        }
    }
    [m_pApsListenerList removeObjectsInArray:removeItems];
    [super onAppFrameWillClose:theAppframe];
}

- (BOOL)processLocalMessage:(UILocalNotification *)pUserInfo type:(NSString*)pType {
    BOOL bProcess = false;
    BOOL isNotificationContent = NO;
    if ( [pUserInfo isKindOfClass:[UNNotificationContent class]] ) {
        isNotificationContent = YES;
    }
    
    NSString *title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString* pMessage = isNotificationContent? ((UNNotificationContent*)pUserInfo).body : pUserInfo.alertBody;
   // NSString* pPayload = pUserInfo.alertAction;
    id pPayload = [pUserInfo.userInfo objectForKey:@"payload"];
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setObject:title forKey:g_pdr_string_title];
    [message setObject:pMessage forKey:g_pdr_string_content];
    [message setObject:pPayload?pPayload:[NSNull null] forKey:g_pdr_string_payload];
    [message setObject:[NSNull null] forKey:g_pdr_string_aps];

    for (NSMutableDictionary* pDic in m_pApsListenerList)
    {
        NSString* pCBID   = [pDic objectForKey:@"CBID"];
        NSString* pListenType = [pDic objectForKey:g_pdr_string_type];
        NSString* frameId = [pDic objectForKey:g_pdr_string_id];
        if ( [pListenType isEqualToString:pType] ) {
            bProcess = [self tiggerJSInFrameId:frameId withCallBack:pCBID withType:pListenType withMessage:message] || bProcess;
        }
    }
    return bProcess;
}

- (BOOL)doRevApnsWithDict:(NSDictionary *)pUserInfo
{
    NSString* pType = [pUserInfo objectForKey: g_pdr_string_type];
    BOOL bProcess = false;
    
    for ( NSMutableDictionary* listener in m_pApsListenerList ) {
        NSString* pCBID   = [listener objectForKey:@"CBID"];
        NSString* pListenType = [listener objectForKey:g_pdr_string_type];
        NSString* frameId = [listener objectForKey:g_pdr_string_id];
        if ( [pListenType isEqualToString:pType] ) {
            bProcess = [self tiggerJSInFrameId:frameId withCallBack:pCBID withType:pListenType withMessage:pUserInfo] || bProcess;
        }
    }
    return bProcess;
}

- (BOOL)tiggerJSInFrameId:(NSString*)frameId
             withCallBack:(NSString*)callBackId
                 withType:(NSString*)listenType
              withMessage:(NSDictionary*)message {
    NSString *pStringFun = [NSString
                            stringWithFormat:@"window.setTimeout(function(){window.__Mkey__Push__.execCallback_Push('%@','%@', %@ )},0);",
                            callBackId, listenType, [message JSONFragment]];
    if ( pStringFun ) {
        PDRCoreAppFrame *targetFrame = [self.appContext.appWindow getFrameByID:frameId];
        [targetFrame evaluatingJavaScriptAndFetchCommand: pStringFun];
        return TRUE;
    }
    return FALSE;
}
- (PGPluginAuthorizeStatus)authorizeStatus {
    return PGPluginAuthorizeStatusAuthorized;
}

#pragma mark - message package and unpackage

- (NSString *)stringWithFormat:(NSString *)format args:(NSArray *)args
{
	NSMutableData *data = [NSMutableData dataWithLength:(sizeof(id) * args.count)];
	[args getObjects:(__unsafe_unretained id *)data.mutableBytes range:NSMakeRange(0, args.count)];
	NSString *so = [[NSString alloc] initWithFormat:format arguments:data.mutableBytes];
	return so;
}

- (NSMutableDictionary*)packageApsMessage2JSPushMessage:(id)packagePayload
                                                   type:(NSString*)revType
                                       remoteNofication:(BOOL*)remote
                                          remotePayload:(NSDictionary**)remotePayload {
    BOOL retRemote = NO;
    //aps格式消息
    // { title : '应用程序名字', content : 'alert', payload : 出aps外所有节点 , aps: aps  }
    
    //第三方通道
    // 判断符合格式吗 title content payload 三者必须都存在
    // 合适 匹配 不合适 title 应用名字 content 完整内容 payload 可以JSON化JSON 不可以 完整内容
    NSMutableDictionary* javascriptPushMessage = [NSMutableDictionary dictionary];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
  //  id packagePayload = [package objectForKey:g_pdr_string_payload];
    //NSString *revType = [package objectForKey:g_pdr_string_type];
    
    if ( [packagePayload isKindOfClass:[NSString class]] ) {
        NSString *newStringPayload = (NSString*)packagePayload;
        id JSONFormatPayload = [newStringPayload JSONValue];
        if ( [JSONFormatPayload isKindOfClass:[NSDictionary class]] ) {
            packagePayload = JSONFormatPayload;
        }
    }
    
    if ( [packagePayload isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *messageBody = (NSDictionary*)packagePayload;
        NSDictionary *aps = [messageBody objectForKey:g_pdr_string_aps];
        //如果有aps认为是aps消息
        if ( [aps isKindOfClass:[NSDictionary class]] ) {
            retRemote = [aps objectForKey:@"content-available"]?YES:NO;
            // 如果推送消息里有body节点这个就不是静默消息
            id alertNode = [aps objectForKey:g_pdr_string_alert];
            if (alertNode && [alertNode isKindOfClass:[NSDictionary class]]) {
                if ([alertNode objectForKey:g_pdr_string_body])
                    retRemote = NO;
            }
            
            if ( retRemote ) {
                if(remote)
                    *remote = retRemote;
                NSMutableDictionary* newPayload = [NSMutableDictionary dictionaryWithDictionary:messageBody];
                [newPayload removeObjectForKey:g_pdr_string_aps];
                if ( [newPayload count] ) {
                    [javascriptPushMessage setObject:newPayload forKey:g_pdr_string_payload];
                } else {
                    [javascriptPushMessage setObject:[NSNull null] forKey:g_pdr_string_payload];
                }
                
                // 设置title
                if ( applicationName ) {
                    [javascriptPushMessage setObject:applicationName forKey:g_pdr_string_title];
                } else {
                    [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_title];
                }
                
                // 设置content
                [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_content];
                
                // 设置aps 节点
                [javascriptPushMessage setObject:aps forKey:g_pdr_string_aps];

                // 接收类型
                [javascriptPushMessage setObject:g_pdr_string_receive forKey:g_pdr_string_type];
                
                return javascriptPushMessage;
            }
            // 设置title
            if ( applicationName ) {
                [javascriptPushMessage setObject:applicationName forKey:g_pdr_string_title];
            } else {
                [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_title];
            }
            //设置content
            id content = [aps objectForKey:g_pdr_string_alert];
            if ( [content isKindOfClass:[NSDictionary class]] ) {
                NSDictionary *contentDict = (NSDictionary*)content;
                NSString *body = [contentDict objectForKey:g_pdr_string_body];
                if ( [body isKindOfClass:[NSString class]] ) {
                    content = body;
                } else {
                    NSString *locKey = [contentDict objectForKey:@"loc-key"];
                    NSArray *locArg = [contentDict objectForKey:@"loc-args"];
                    if ( [locKey isKindOfClass:[NSString class]] ) {
                        NSString *value = NSLocalizedString(locKey, nil);
                        if ( [value isKindOfClass:[NSString class]] ) {
                            if ( [locArg isKindOfClass:[NSArray class]] && [locArg count] > 0 ) {
                                NSString *newValue = [self stringWithFormat:value args:locArg];
                                if ( [newValue isKindOfClass:[NSString class]] ) {
                                    content = newValue;
                                } else {
                                    content = value;
                                }
                            } else {
                                content = value;
                            }
                        } else {
                            content = locKey;
                        }
                    }
                }
            }
            if ( content ) {
                [javascriptPushMessage setObject:content forKey:g_pdr_string_content];
            } else {
                [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_content];
            }
            //设置payload
            NSMutableDictionary *newPayload = [messageBody objectForKey:g_pdr_string_payload];
            if ( [newPayload isKindOfClass:[NSString class]] ) {
                newPayload = [(NSString*)newPayload JSONValue];
            }
            if ( [newPayload isKindOfClass:[NSDictionary class]] ) {
               [javascriptPushMessage setObject:newPayload forKey:g_pdr_string_payload];
            } else {
                newPayload = [NSMutableDictionary dictionaryWithDictionary:messageBody];
                [newPayload removeObjectForKey:g_pdr_string_aps];
                if ( [newPayload count] ) {
                    [javascriptPushMessage setObject:newPayload forKey:g_pdr_string_payload];
                } else {
                    [javascriptPushMessage setObject:[NSNull null] forKey:g_pdr_string_payload];
                }
            }
            
            //设置aps
            [javascriptPushMessage setObject:aps forKey:g_pdr_string_aps];
        } else {
            
            NSString *titile = [messageBody objectForKey:g_pdr_string_title];
            NSString *content = [messageBody objectForKey:g_pdr_string_content];
            id payload = [messageBody objectForKey:g_pdr_string_payload];
            
            //设置aps
            [javascriptPushMessage setObject:[NSNull null] forKey:g_pdr_string_aps];
            if ( titile && content && payload ) {
                // 设置title
                [javascriptPushMessage setObject:titile forKey:g_pdr_string_title];
                //设置content
                [javascriptPushMessage setObject:content forKey:g_pdr_string_content];
                //设置payload
                [javascriptPushMessage setObject:payload forKey:g_pdr_string_payload];
            } else {
                // 设置title
                if ( applicationName ) {
                    [javascriptPushMessage setObject:applicationName forKey:g_pdr_string_title];
                } else {
                    [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_title];
                }
                //设置content
                [javascriptPushMessage setObject:[packagePayload JSONFragment] forKey:g_pdr_string_content];
                // 设置payload
                [javascriptPushMessage setObject:packagePayload forKey:g_pdr_string_payload];
            }
        }
    } else if ( [packagePayload isKindOfClass:[NSString class]] ) {
        // 设置title
        if ( applicationName ) {
            [javascriptPushMessage setObject:applicationName forKey:g_pdr_string_title];
        } else {
            [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_title];
        }
        //设置content
        [javascriptPushMessage setObject:packagePayload forKey:g_pdr_string_content];
        // 设置payload
        [javascriptPushMessage setObject:packagePayload forKey:g_pdr_string_payload];
        //设置aps
        [javascriptPushMessage setObject:[NSNull null] forKey:g_pdr_string_aps];
    } else {
        [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_title];
        [javascriptPushMessage setObject:g_pdr_string_empty forKey:g_pdr_string_content];
        [javascriptPushMessage setObject:[NSNull null] forKey:g_pdr_string_payload];
        [javascriptPushMessage setObject:[NSNull null] forKey:g_pdr_string_aps];
    }
    [javascriptPushMessage setObject:revType forKey:g_pdr_string_type];
    return javascriptPushMessage;
}

- (void)onDestroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRCoreAppDidRevLocalNotificationKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRCoreAppDidRevApnsKey object:nil];
}

- (void)dealloc {

    [self clearRemoteMessage];
    [self clearLocalMessage];
    
    [m_pApsListenerList removeAllObjects];
    [m_pApsListenerList release];
    [super dealloc];
}

@end
