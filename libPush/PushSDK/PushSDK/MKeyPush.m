//
//  PushSDK.m
//  PushSDK
//
//  Created by X on 13-4-17.
//  Copyright (c) 2013年 io.dcloud. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MKeyPush.h"

NSString * const kMkeyPushConfigFile = @"__mkeypush__.plist";

NSString * const kMkeyPushConfigAppIDKey = @"appid";
NSString * const kMkeyPushConfigdeviceToken = @"deviceToken";
NSString * const kMkeyPushConfigIsFirstKey = @"first";
NSString * const kMkeyPushConfigURLKey = @"url";

@interface NSData(HexByte)
- (NSString*)stringWithHexBytes;
@end

#pragma mark ----------
#pragma mark MkeyPushConfig
/*
 **@MkeyPushConfig
 */
@interface MkeyPushConfig : NSObject

@property(nonatomic, assign)BOOL runFirst;
@property(nonatomic, copy)NSString *appID;
@property(nonatomic, copy)NSString *deviceToken;
@property(nonatomic, copy)NSString *url;
@property(nonatomic, assign)BOOL debug;
@end

@implementation MkeyPushConfig

@synthesize runFirst;
@synthesize appID;
@synthesize deviceToken;
@synthesize url;
@synthesize debug;

- (id)init {
    if ( self = [super init] ) {
        self.runFirst = YES;
        [self load];
    }
    return self;
}

- (NSDictionary*)load {
    NSString *configFile = [self configFileFullPath];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:configFile];
    if ( dict ) {
        NSNumber *value = nil;
        value = [dict objectForKey:kMkeyPushConfigIsFirstKey];
        if ( [value isKindOfClass:[NSNumber class]]  ) {
            self.runFirst = [value boolValue];
        }
        self.deviceToken = [dict objectForKey:kMkeyPushConfigdeviceToken];
        self.url = [dict objectForKey:kMkeyPushConfigURLKey];
       // self.appKey = [dict objectForKey:kMkeyPushConfigAppKeyKey];
        self.appID = [dict objectForKey:kMkeyPushConfigAppIDKey];
    }
    return dict;
}

- (void)save {
    NSString *configFile = [self configFileFullPath];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithBool:self.runFirst] forKey:kMkeyPushConfigIsFirstKey];
    if ( self.deviceToken ) {
        [dict setObject:self.deviceToken forKey:kMkeyPushConfigdeviceToken];
    }
    if ( self.url ) {
        [dict setObject:self.url forKey:kMkeyPushConfigURLKey];
    }
    if ( self.appID ) {
        [dict setObject:self.appID forKey:kMkeyPushConfigAppIDKey];
    }
    
    [dict writeToFile:configFile atomically:YES];
}

- (NSString*)configFileFullPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *librayDirectory = [paths objectAtIndex:0];
    librayDirectory = [librayDirectory stringByAppendingPathComponent:@"mkeypush"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ( ![manager fileExistsAtPath:librayDirectory] ) {
        [manager createDirectoryAtPath:librayDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [librayDirectory stringByAppendingPathComponent:kMkeyPushConfigFile];
}

- (void)dealloc {
    self.appID = nil;
    self.url = nil;
    self.deviceToken = nil;
    [super dealloc];
}

@end

#pragma mark ----------
#pragma mark MKeyPushUtil
/*
 **@MKeyPushUtil
 */

@interface MKeyPushUtil : NSObject
@property(nonatomic, copy)NSString *model;
@property(nonatomic, assign)CGFloat resolutionHeight;
@property(nonatomic, assign)CGFloat resolutionWidth;
@property(nonatomic, copy)NSString *UDID;
@end

@implementation MKeyPushUtil

@synthesize model;
@synthesize resolutionHeight;
@synthesize resolutionWidth;
@synthesize UDID;

+(MKeyPushUtil*)util {
    MKeyPushUtil *util = [[[MKeyPushUtil alloc] init] autorelease];
    return util;
}

- (id)init {
    if ( self = [super init] ) {
        UIDevice *device = [UIDevice currentDevice];
        self.model = device.localizedModel;
        NSLog(@"%@", model);
        UIScreen *screen = [UIScreen mainScreen];
        self.resolutionWidth = screen.bounds.size.width;
        self.resolutionHeight = screen.bounds.size.height;
        
        CGFloat scale = [UIScreen mainScreen].scale;
        self.resolutionWidth *= scale;
        self.resolutionHeight *= scale;
        
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
        self.UDID = (NSString*)uuidString;
        CFRelease(uuidString);
        CFRelease(uuidRef);
    }
    return self;
}

- (void)dealloc {
    self.model = nil;
    self.UDID = nil;
    [super dealloc];
}

@end

#pragma mark ----------
#pragma mark MKeyPushInternal

typedef NS_ENUM(NSInteger, MKeyPushRunState) {
    MKeyPushRunStateNone = 0,
    MKeyPushRunStateInit = 1,
    MKeyPushStateRegister = 2,
    MKeyPushStateRun = 3,
};

/*
 **@MKeyPushInternal
 */
@interface MKeyPushInternal : NSObject <NSURLConnectionDataDelegate>{
    MkeyPushConfig *_config;
    NSMutableData *_data;
    NSURLConnection *_connection;
    MKeyPushRunState _state;
    id _delegate;
}

@property(nonatomic, copy)NSString *appID;
@property(nonatomic, assign)BOOL debug;

- (void)setDelegate:(id)delegate;
- (void)initWithAppid:(NSString*)appid withOption:(NSDictionary *)launchingOption;
- (void)registerDeviceToken:(NSString *)deviceToken toServer:(NSString*)url;
- (void)handleRemoteNotification:(NSDictionary*)remoteInfo;

@end

@implementation MKeyPushInternal

@synthesize appID;
@synthesize debug;

- (id)init {
    if ( self = [super init] ) {
        _config = [[MkeyPushConfig alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

//启动时调用
- (void)initWithAppid:(NSString*)aAppid withOption:(NSDictionary *)launchOptions {
    if ( MKeyPushRunStateNone == _state ) {
        self.appID = aAppid;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
        //第一次运行
        if ( _config.runFirst ) {
        } else {
            NSDictionary* userInfo  = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
            if ( userInfo ) {
                if ( self.debug )
                { NSLog(@"检测到离线push--[%@]", [userInfo description]); }
                [self handleRemoteNotification:userInfo];
            }
        }
        _state = MKeyPushRunStateInit;
        if ( self.debug )
        { NSLog(@"appid--[%@]--", self.appID);}
    }
}

// 向服务器上报Device Token
- (void)registerDeviceToken:(NSString *)token toServer:(NSString*)url {
    if ( _state == MKeyPushRunStateInit ) {
        BOOL report = FALSE;
        if ( self.debug )
        { NSLog(@"设备token--[%@]--post url--[%@]", token, url);}
        if ( token && url ) {
            if ( _config.runFirst
                || NSOrderedSame != [_config.deviceToken compare:token]
                || NSOrderedSame != [_config.url compare:url]
                || NSOrderedSame != [_config.appID compare:self.appID])
            {
                _config.deviceToken = token;
                _config.url = url;
                _config.runFirst = NO;
                _config.appID = self.appID;
                report = TRUE;
            }
            report = TRUE;
            if ( report ) {
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
                NSString *bodyF = @"action=register&appid=%@&token=%@&platform=iOS&phonemodel=%@&imei=%@&imsi=&screensize=%d*%d&phonenumber=1";
                MKeyPushUtil *util = [MKeyPushUtil util];
                NSString *body = [NSString stringWithFormat:bodyF,
                                  self.appID,
                                  token,
                                  util.model,
                                  util.UDID,
                                  (int)util.resolutionHeight,
                                  (int)util.resolutionWidth];
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
                if ( self.debug )
                { NSLog(@"注册token--[%@]", body);}
                [self startRequest:request];
                _state = MKeyPushStateRegister;
                return;
            }
            if ( self.debug )
            { NSLog(@"以前注册过push不需要在注册了啊");}
        }
    }
}

- (void)startRequest:(NSURLRequest*)request {
    _connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [_connection retain];
    [_connection start];
}

- (void)closeRequest {
    [_connection cancel];
    [_connection release];
    _connection = nil;
}

// 处理收到的APNS消息
- (void)handleRemoteNotification:(NSDictionary*)remoteInfo {
    NSDictionary* apsDict =[remoteInfo objectForKey:@"aps"];
    if ( [apsDict isKindOfClass:[NSDictionary class]] ) {
        NSNumber *badge = [apsDict objectForKey:@"badge"];
        if ( [badge isKindOfClass:[NSNumber class]] ) {
            //炸弹短信
            if ( 9999 == [badge integerValue] ) {
                [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
                if ( [_delegate respondsToSelector:@selector(didReceiveBombMessage)] ) {
                    [_delegate performSelector:@selector(didReceiveBombMessage)];
                }
                return;
            }
        }
    }
    if ( [_delegate respondsToSelector:@selector(didReceiveMessage:)] ) {
        [_delegate performSelector:@selector(didReceiveMessage:) withObject:remoteInfo];
    }
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}

- (void)onAppWillResignActive:(NSNotification*)notification{
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ( self.debug ) {
        NSLog(@"收到服务器响应");
    }
    [_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data  {
    if ( self.debug ) {
        NSLog(@"接收服务器数据...");
    }
    if ( !_data ) {
        _data = [[NSMutableData alloc] initWithCapacity:10];
    }
    [_data appendData:data];
}

- (void)doAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
    NSURLProtectionSpace *  protectionSpace = [challenge protectionSpace];
    NSString *authenticationMethod = [protectionSpace authenticationMethod];
    SecTrustRef trust = nil;
    OSStatus err = noErr;
    SecTrustResultType trustResult = kSecTrustResultInvalid;
    BOOL trusted = FALSE;
    
    if ( NSOrderedSame == [authenticationMethod compare:@"NSURLAuthenticationMethodServerTrust"]) {
        trust = [protectionSpace serverTrust];
        err = SecTrustEvaluate(trust, &trustResult);
        trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
        if ( trusted ) {
            NSURLCredential *credential = nil;
            trust = [protectionSpace serverTrust];
            credential = [NSURLCredential credentialForTrust:trust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        } else {
            NSURLProtectionSpace *  protectionSpace = [challenge protectionSpace];
            SecTrustRef             trust;
            NSURLCredential *   credential;
                
            trust = [protectionSpace serverTrust];
                
            credential = [NSURLCredential credentialForTrust:trust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        }
    }
}

- (BOOL)connection:(NSURLConnection *)connection
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    NSString *authenticationMethod = [protectionSpace authenticationMethod];
    if (  NSOrderedSame == [authenticationMethod compare:@"NSURLAuthenticationMethodServerTrust"]){
        return YES;
    }
    return NO;
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    [self doAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self doAuthenticationChallenge:challenge];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
   // NSString *message = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease];
    BOOL report = TRUE;
    if ( [_data length] ) {
        if ( self.debug ) {
            NSLog(@"服务器返回数据--[%@]", [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease]);
        }
        // NSDictionary *result = [message mutableObjectFromJSONString];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:_data options:NSJSONReadingMutableLeaves error:nil];
        if ( self.debug )
        { NSLog(@"JSON解析服务器返回数据--[%@]", [result description]);}
        NSInteger resultCode = 4;
        NSString *rValue = [result objectForKey:@"status"];
        if ( [rValue isKindOfClass:[NSString class]]
                || [rValue isKindOfClass:[NSNumber class]] ) {
            if ( 0 == [rValue intValue]
                || 1003 == [rValue intValue]) {
                    [_config save];
                    if ( self.debug )
                    { NSLog(@"注册成功");}
                    report = FALSE;
            }
            resultCode = [rValue integerValue];
        }
        if ( report ) {
            NSError *error = [NSError errorWithDomain:@"DHPushErrorDmain" code:resultCode userInfo:result];
            if ( [_delegate respondsToSelector:@selector(didReceiveFailWithError:)] ) {
                [_delegate performSelector:@selector(didReceiveFailWithError:) withObject:error];
            }
        }
    } else {
        if ( self.debug ) {
            NSLog(@"服务器好像没有发送任何数据奥,靠谱点行吗");
        }
    }
    [self closeRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ( self.debug )
    { NSLog(@"连接服务器错误--[%@]", [error description]);}
    if ( [_delegate respondsToSelector:@selector(didReceiveFailWithError:)] ) {
        [_delegate performSelector:@selector(didReceiveFailWithError:) withObject:error];
    }
    [self closeRequest];
}

- (void)dealloc {
    self.appID = nil;
    [self closeRequest];
    [_data release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [_config release];
    [super dealloc];
}

@end

#pragma mark ----------
#pragma mark MKeyPush
/*
 **@MKeyPush
 */
@implementation MKeyPush

+ (MKeyPush*)defaultInstance {
    static dispatch_once_t onceToken;
    static MKeyPush *defaultInstance = nil;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[[self class] alloc] init];
    });
    
    return defaultInstance;
}

- (id)init {
    if ( self = [super init] ) {
        _internal = [[MKeyPushInternal alloc] init];
    }
    return self;
}

- (void)setDelegate:(id)delegate {
    [_internal setDelegate:delegate];
}

- (void)setDebug:(BOOL)debug {
    [_internal setDebug:debug];
}

//启动时调用
- (void)initMkeyPushWithAppID:(NSString*)appid
                       option:(NSDictionary *)launchOptions{
    [_internal initWithAppid:appid withOption:launchOptions];
}

// 向服务器上报Device Token
- (void)registerMkeyPushUseDeviceToken:(NSString *)deviceToken toServer:(NSString*)url {
    [_internal registerDeviceToken:deviceToken toServer:url];
}

// 处理收到的APNS消息
- (void)handleRemoteNotification:(NSDictionary*)remoteInfo {
    [_internal handleRemoteNotification:remoteInfo];
}

- (void)dealloc {
    [_internal release];
    [super dealloc];
}

@end

@implementation NSData(HexByte)

- (NSString*)stringWithHexBytes
{
    NSMutableString* pStringBuffer = [NSMutableString stringWithCapacity:[self length]];
    const unsigned char* dataBuffer = [self bytes];
    
    for (int i = 0; i < [self length]; ++i)
    {
        [pStringBuffer appendFormat:@"%02X", (int)dataBuffer[ i ]];
    }
    return pStringBuffer;
}

@end

