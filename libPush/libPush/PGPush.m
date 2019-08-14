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
#import "DCH5ScreenAdvertisingBrowser.h"

BOOL g_bStartFromePushNotification = false;
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

@interface PGPush()<DCH5ScreenAdvertisingBrowserDelegate> {
    NSMutableArray *m_pApsListenerList;
    NSMutableDictionary *_apsCache;
    NSMutableDictionary *_localNotiCache;
}
@property(nonatomic, retain)UINavigationController *navigationController;
@end

BOOL bIsDeactivate = NO;
static PGPush * g_pushInstanceHandle = nil;
@implementation PGPush

@synthesize handleOfflineMsg;

+ (instancetype)instance{
    return g_pushInstanceHandle;
}

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
    
    if(nil == g_pushInstanceHandle){
        g_pushInstanceHandle = self;
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

/**
 判断是否响应通知消息
 如果是广告推送则发送广告推送通知，本类不做响应
 
 @param info 推送消息
 @param isClick 是否点击点击推送消息触发
 @return YES or NO
 */
- (BOOL)canRespondAction:(id)info isClick:(BOOL)isClick
{
    NSString *pAction = nil;
    if ([info isKindOfClass:[UNNotificationContent class]]) {
        UNNotificationContent *notiContent = (UNNotificationContent *)info;
        pAction = notiContent.categoryIdentifier;
    } else if ([info isKindOfClass:[UILocalNotification class]]) {
        UILocalNotification *localNoti = (UILocalNotification *)info;
        NSDictionary* pInfoObj = localNoti.userInfo;
        if(pInfoObj && [pInfoObj isKindOfClass:[NSDictionary class]]){
            NSDictionary* pPayloadDic = [pInfoObj objectForKey:@"payload"];
            if(pPayloadDic && [pPayloadDic isKindOfClass:[NSDictionary class]]){
                pAction = [pPayloadDic objectForKey:@"pushAction"];
            }
        }
    }
    
    if ([pAction isEqualToString:g_pdr_string_adpushaction]) {
        if (isClick) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PDRCoreAppDidClickADNotificationKey object:info];
        }
        return NO;
    }
    
    return YES;
}

- (void) onRevLocationNotification:(NSObject *)userInfo isReceive:(BOOL)isReceive {
    
    // 过滤广告消息，本类中不在处理
    if (![self canRespondAction:userInfo isClick:!isReceive]) {
        return;
    }
    
    if ( [self processLocalMessage:userInfo type:isReceive ? g_pdr_string_receive :g_pdr_string_click] ) {
    } else {
        [self saveLocalMessage:userInfo isReceive:isReceive];
    }
}

- (void) onRevLocationNotification:(NSNotification *)userInfo {
    
    // 过滤广告消息，本类中不在处理
    if (![self canRespondAction:userInfo.object isClick:bIsDeactivate]) {
        return;
    }
    
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
    NSString* image = nil;
    
    pMessage = [PGPluginParamHelper getStringValue:[pMethod getArgumentAtIndex:0]];
    pPayload = [PGPluginParamHelper getStringValue:[pMethod getArgumentAtIndex:1]];
    NSDictionary *options = [pMethod getArgumentAtIndex:2];
    fDelay = [PGPluginParamHelper getFloatValueInDict:options forKey:g_pdr_string_delay defalut:0.0f];
    sound = [PGPluginParamHelper getStringValueInDict:options forKey:@"sound" defalut:g_pdr_string_system];
    image = [PGPluginParamHelper getStringValueInDict:options forKey:@"icon"];
    
    

    if(kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_9_x_Max)
    {
        void (^sendNotificationBlock)(UNMutableNotificationContent* content ,UNTimeIntervalNotificationTrigger* trigger) = ^(UNMutableNotificationContent* content ,UNTimeIntervalNotificationTrigger* trigger){
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"DCPushID232" content:content trigger:trigger];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = self;
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%@", error);
                }
            }];
        };
    
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        if(content)
        {
            
            @try {
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:fDelay==0?1:fDelay repeats:NO];
                content.body = pMessage;
                if ( [pPayload isKindOfClass:[NSString class]] || [pPayload isKindOfClass:[NSDictionary class]]){
                    content.userInfo =  [NSDictionary dictionaryWithObjectsAndKeys:pPayload ? pPayload:@"",@"payload", nil];
                }
                if ( !(sound && NSOrderedSame == [sound caseInsensitiveCompare:g_pdr_string_none])){
                    content.sound = [UNNotificationSound defaultSound];//系统的声音
                }
                
                if(image && [image isKindOfClass:[NSString class]] && image.length)
                {
                    NSString *localPath = nil;
                    if([image isWebUrlString]){
                        NSURLRequest* pRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:image]];
                        if(pRequest)
                        {
                            [NSURLConnection sendAsynchronousRequest:pRequest
                                                               queue:[NSOperationQueue currentQueue]
                                                   completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                                                       NSArray* pArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                                                       NSString *localPath = [[pArray firstObject] stringByAppendingPathComponent: response.suggestedFilename?response.suggestedFilename:@"localNotificationImage.png"];
                                                       if(data && connectionError == nil && response)
                                                       {
                                                           [data writeToFile:localPath atomically:NO];
                                                           if (localPath && ![localPath isEqualToString:@""]) {
                                                               UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:[NSUUID UUID].UUIDString URL:[NSURL URLWithString:[@"file://" stringByAppendingString:localPath]] options:nil error:nil];
                                                               if (attachment) {
                                                                   content.attachments = @[attachment];
                                                               }
                                                           }
                                                       }
                                                       sendNotificationBlock(content, trigger);
                                                   }];
                        }
                        
                    }
                    else{
                        if([image isAbsolutePath])
                            localPath = image;
                        else
                            localPath = [PTPathUtil absolutePath:image withContext:self.appContext];
                        
                        if (localPath && ![localPath isEqualToString:@""])
                        {
                            NSString *tmpLocalPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"localNotificationImage.png"];
                            [[NSFileManager defaultManager] copyItemAtPath:localPath toPath:tmpLocalPath error:nil];
                            localPath = tmpLocalPath;
                            if(localPath && [localPath isAbsolutePath])
                            {
                                UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:[NSUUID UUID].UUIDString URL:[NSURL URLWithString:[@"file://" stringByAppendingString:localPath]] options:nil error:nil];
                                if (attachment) {
                                    content.attachments = @[attachment];
                                }
                            }
                        }
                        sendNotificationBlock(content, trigger);
                    }
                }
                else{
                    sendNotificationBlock(content, trigger);
                }
 
            } @catch (NSException *exception) {
                
            }
        }
        
    }else{
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
}
#pragma mark - 创建本地消息

- (void)createLocalActionMessage:(NSDictionary*)pMessageDic
{
    // 如果当前是从推送启动不再发送启动
    if(g_bStartFromePushNotification)
        return;
    
    CGFloat fDelay = 1.0f;
    NSString* pMessage = nil;
    NSString* image = nil;
    NSString* pUrl = nil;
    NSString* pAppid = nil;
    NSMutableDictionary* pPayload = nil;
    
    pMessage = [pMessageDic objectForKey:@"content"];
    image = [pMessageDic objectForKey:@"icon"];
    pUrl = [pMessageDic objectForKey:@"url"];
    pAppid = [pMessageDic objectForKey:@"appid"];
    fDelay = [[pMessageDic objectForKey:@"delay"] floatValue] / 1000.0f;
    pPayload = [NSMutableDictionary dictionaryWithDictionary:pMessageDic];
    [pPayload setObject:g_pdr_string_adpushaction forKey:@"pushAction"];
    
    if(kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_9_x_Max)
    {
        
        void (^sendNotificationBlock)(UNMutableNotificationContent* content ,UNTimeIntervalNotificationTrigger* trigger) = ^(UNMutableNotificationContent* content ,UNTimeIntervalNotificationTrigger* trigger){
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:content trigger:trigger];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = self;
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%@", error);
                }
            }];
        };
        
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        if(content){
            @try {
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:fDelay==0?1:fDelay repeats:NO];
                content.body = pMessage;
                content.categoryIdentifier = g_pdr_string_adpushaction;
                if ( [pMessageDic isKindOfClass:[NSString class]] || [pMessageDic isKindOfClass:[NSDictionary class]]){
                    content.userInfo =  [NSDictionary dictionaryWithObjectsAndKeys:pMessageDic ? pMessageDic:@"",@"payload", nil];
                }
                
                if(image && [image isKindOfClass:[NSString class]] && image.length)
                {
                    NSString* pFilePath = nil;
                    NSString *localPath = nil;
                    if([image isWebUrlString]){
                        NSURLRequest* pRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:image]];
                        if(pRequest)
                        {
                            [NSURLConnection sendAsynchronousRequest:pRequest
                                                               queue:[NSOperationQueue currentQueue]
                                                   completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                                                       //NSArray* pArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                                                       NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent: response.suggestedFilename?response.suggestedFilename:@"localNotificationImage.png"];
                                                       if(data && connectionError == nil && response)
                                                       {
                                                           [data writeToFile:localPath atomically:NO];
                                                           if (localPath && ![localPath isEqualToString:@""]) {
                                                               UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:[NSUUID UUID].UUIDString URL:[NSURL URLWithString:[@"file://" stringByAppendingString:localPath]] options:nil error:nil];
                                                               if (attachment) {
                                                                   content.attachments = @[attachment];
                                                               }
                                                           }
                                                       }
                                                       sendNotificationBlock(content, trigger);
                                                   }];
                        }
                        
                    }
                    else{
                        if([image isAbsolutePath])
                            localPath = image;
                        
                        if (localPath && ![localPath isEqualToString:@""]){
                            NSString *tmpLocalPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"localNotificationImage.png"];
                            [[NSFileManager defaultManager] copyItemAtPath:localPath toPath:tmpLocalPath error:nil];
                            localPath = tmpLocalPath;
                            if(localPath && [localPath isAbsolutePath]){
                                UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:[NSUUID UUID].UUIDString URL:[NSURL URLWithString:[@"file://" stringByAppendingString:localPath]] options:nil error:nil];
                                if (attachment) {
                                    content.attachments = @[attachment];
                                }
                            }
                        }
                        sendNotificationBlock(content, trigger);
                    }
                }
                else{
                    sendNotificationBlock(content, trigger);
                }
                
            } @catch (NSException *exception) {
                
            }
        }
        
    }else
    {
        UILocalNotification* pLocalNot = [[[UILocalNotification alloc] init] autorelease];
        if (pLocalNot)
        {
            pLocalNot.fireDate = [[[NSDate alloc] initWithTimeIntervalSinceNow:fDelay] autorelease];
            pLocalNot.alertBody = pMessage;
            if ( [pPayload isKindOfClass:[NSString class]]
                || [pPayload isKindOfClass:[NSDictionary class]]) {
                pLocalNot.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pPayload ? pPayload:@"",@"payload", nil];
            }
            
            [[UIApplication sharedApplication] scheduleLocalNotification:pLocalNot];
        }
    }
}

#pragma mark - 消息保存接口
- (void)saveLocalMessage:(UILocalNotification*)localMessage isReceive:(BOOL)receive {
    if ( nil == _localNotiCache ) {
        _localNotiCache = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    
    if(!receive && !g_bStartFromePushNotification)
    {
        if ([localMessage respondsToSelector:@selector(category)] && [[localMessage category] isEqualToString:g_pdr_string_adpushaction]){
            NSDictionary* pInfoObj = localMessage.userInfo;
            if(pInfoObj && [pInfoObj isKindOfClass:[NSDictionary class]]){
                NSDictionary* pPayloadDic = [pInfoObj objectForKey:@"payload"];
                if(pPayloadDic){
                    g_bStartFromePushNotification = YES;
                    [self procressPushActions:pPayloadDic];
                    return ;
                }
            }
        }else{
            NSDictionary* pInfoObj = localMessage.userInfo;
            if(pInfoObj && [pInfoObj isKindOfClass:[NSDictionary class]]){
                NSDictionary* pPayloadDic = [pInfoObj objectForKey:@"payload"];
                if(pPayloadDic && [pPayloadDic isKindOfClass:[NSDictionary class]]){
                    NSString* pUshAction = [pPayloadDic objectForKey:@"pushAction"];
                    if(pPayloadDic && [pUshAction isEqualToString:g_pdr_string_adpushaction]){
                        g_bStartFromePushNotification = YES;
                        [self procressPushActions:pPayloadDic];
                        return ;
                    }
                }
            }
        }
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
    [self webviewWillClosed:nil];
    [super onAppFrameWillClose:theAppframe];
}

- (void)procressPushActions:(NSDictionary*)pPayloadObj{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(pPayloadObj){
            if(pPayloadObj){
                NSString* pTid = [NSString stringWithFormat:@"%d",[[pPayloadObj objectForKey:@"tid"] intValue]];
                if(pTid != nil){
                    [self performSelectorOnMainThread:@selector(reportPushActionOnMainThread:) withObject:pTid waitUntilDone:NO];
                }
                NSString *deepLink = [pPayloadObj objectForKey:@"dplk"];
                if ( deepLink ) {
                    NSURL *url = [NSURL URLWithString:deepLink];
                    if ( url ) {
                        if ( [[UIApplication sharedApplication] canOpenURL:url] ){
                            [[UIApplication sharedApplication] openURL:url];
                            return;
                        }
                    }
                }
                NSString *click_action = [pPayloadObj objectForKey:@"click_action"];
                if ( click_action ) {
                    if ( NSOrderedSame ==  [click_action caseInsensitiveCompare:@"browser"] ) {
                        NSString* purl = [pPayloadObj objectForKey:g_pdr_string_url];
                        if(purl){
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:purl]];
                        }
                        return;
                    } else if ( NSOrderedSame ==  [click_action caseInsensitiveCompare:@"url"] ) {
                        NSString* purl = [pPayloadObj objectForKey:g_pdr_string_url];
                        DCH5ScreenAdvertisingBrowser *advBrowser = [[[DCH5ScreenAdvertisingBrowser alloc] init] autorelease];
                        if(advBrowser){
                            advBrowser.delegate = self;
                            [advBrowser loadURL:[NSURL URLWithString:purl]];
                            UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:advBrowser] autorelease];
                            [self presentViewController:navigationController animated:NO completion:nil];
                            self.navigationController = navigationController;
                        }
                        return;
                    } else if ( NSOrderedSame ==  [click_action caseInsensitiveCompare:@"streamapp"] ) {
                        NSString* pActAppid = [pPayloadObj objectForKey:g_pdr_string_appid];
                        if(pActAppid){
                            NSMutableDictionary* pParameters = [NSMutableDictionary dictionaryWithDictionary:[pPayloadObj objectForKey:@"parameters"]];
                            if(pParameters){
                                // 发送一个消息处理
                                [pParameters setObject:pActAppid forKey:g_pdr_string_appid];
                                [self performSelectorOnMainThread:@selector(procressPushCmdOnMainThread:) withObject:pParameters waitUntilDone:NO];
                            }
                        }
                        return;
                    }
                }
                
                NSString* pActAppid = [pPayloadObj objectForKey:g_pdr_string_appid];
                if(pActAppid){
                    NSMutableDictionary* pParameters = [NSMutableDictionary dictionaryWithDictionary:[pPayloadObj objectForKey:@"parameters"]];
                    if(pParameters){
                        // 发送一个消息处理
                        [pParameters setObject:pActAppid forKey:g_pdr_string_appid];
                        [self performSelectorOnMainThread:@selector(procressPushCmdOnMainThread:) withObject:pParameters waitUntilDone:NO];
                    }
                }
                else{
                    NSString* purl = [pPayloadObj objectForKey:g_pdr_string_url];
                    if(purl){
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:purl]];
                    }
                }
            }
        }
    });
}

- (void)webviewWillClosed:(DCH5ScreenAdvertisingBrowser*)browserHandle {
    [self dismissViewControllerAnimated:NO completion:nil];
    self.navigationController = nil;
}

- (void)reportPushActionOnMainThread:(NSString*)pTid{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PDRCoreAppPushActionClicked" object:pTid];
}

- (void)procressPushCmdOnMainThread:(NSDictionary* )dicObj{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PDRCoreAppPushActionStartAppKey" object:dicObj];
}

- (BOOL)processLocalMessage:(UILocalNotification *)pUserInfo type:(NSString*)pType {
    BOOL bProcess = false;
    BOOL isNotificationContent = NO;
    if ( [pUserInfo isKindOfClass:[UNNotificationContent class]] ) {
        isNotificationContent = YES;
    }
    
    if(isNotificationContent && [((UNNotificationContent*)pUserInfo).categoryIdentifier isEqualToString:g_pdr_string_adpushaction]){
        if([pType isEqualToString:g_pdr_string_click]){
            [self procressPushActions:[pUserInfo.userInfo objectForKey:@"payload"]];
            return YES;
        }
        else if([pType isEqualToString:g_pdr_string_receive]){
            return YES;
        }
    }else{
        NSDictionary* pInfoObj = pUserInfo.userInfo;
        if(pInfoObj && [pInfoObj isKindOfClass:[NSDictionary class]] && [pType isEqualToString:g_pdr_string_click]){
            NSDictionary* pPayloadDic = [pInfoObj objectForKey:@"payload"];
            if(pPayloadDic && [pPayloadDic isKindOfClass:[NSDictionary class]]){
                NSString* pAction = [pPayloadDic objectForKey:@"pushAction"];
                if(pAction && [pAction isKindOfClass:[NSString class]] && [pAction isEqualToString:g_pdr_string_adpushaction]){
                    [self procressPushActions:pPayloadDic];
                    return YES;
                }
            }
        }
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
                            stringWithFormat:@"setTimeout(function(){var cbHandle = plus.push.__Mkey__Push__  || __Mkey__Push__; cbHandle.execCallback_Push('%@','%@', %@ )},0);",
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
	NSString *so = [[[NSString alloc] initWithFormat:format arguments:data.mutableBytes] autorelease];
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
                NSDictionary *playloadDic = [(NSString*)newPayload JSONValue];
                if ([playloadDic isKindOfClass:[NSDictionary class]]) {
                    [javascriptPushMessage setObject:playloadDic forKey:g_pdr_string_payload];
                } else {
                    [javascriptPushMessage setObject:newPayload forKey:g_pdr_string_payload];
                }
                
            } else if ([newPayload isKindOfClass:[NSDictionary class]]) {
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
    self.navigationController = nil;
    [super dealloc];
}

@end
