//
//  QQAuth.m
//  QQAuth
//
//  Created by X on 15/3/12.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import "PGQQOauth.h"
#import "PDRCore.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#import "PDRToolSystemEx.h"
#import <TencentOpenAPI/QQApiInterface.h>

NSString *kPGQQApiKeyOpenid = @"openid";
NSString *kPGQQApiKeyAccessToken = @"access_token";
NSString *kPGQQApiKeyExpriesin = @"expires_in";
NSString *kPGQQApiKeyUserInfo = @"userInfo";
NSString *kPGQQApiKeyExtra = @"extra";
NSString *kPGQQApiKeyScope = @"scope";

@implementation PGQQOauth

@synthesize accessToken;
@synthesize expireTime;
@synthesize appId;
@synthesize userInfo;
@synthesize mscope;

@synthesize callbackId, extra;

-(void)initalize {
    NSString *appid = nil;
    NSArray *urlSchemes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *urlScheme in urlSchemes ) {
        NSString *urlName = [urlScheme objectForKey:@"CFBundleURLName"];
        if ( NSOrderedSame == [@"tencentopenapi" caseInsensitiveCompare:urlName] ) {
            NSArray *appids = [urlScheme objectForKey:@"CFBundleURLSchemes"];
            appid = [appids objectAtIndex:0];
            NSRange range = [appid rangeOfString:@"tencent"];
            if ( 0 == range.location ) {
                appid = [appid substringFromIndex:range.length];
            }
            self.appId = appid;
            break;
        }
    }
    self.identify = @"qq";
    self.note = @"QQ";
    if ( self.appId ) {
        [self decodeOauthInfo];
        _tencentOAuth = [[TencentOAuth alloc] initWithAppId:self.appId
                                                andDelegate:self];
        [_tencentOAuth setAccessToken:self.accessToken];
        [_tencentOAuth setExpirationDate:[NSDate dateWithTimeIntervalSince1970:self.expireTime]];
        [_tencentOAuth setOpenId:self.openid];
        [super initalize];
    }
}

- (void)login:(NSString*)cbId withParams:(NSDictionary*)params{
    NSString *scope = [params objectForKey:kPGQQApiKeyScope];
    NSString *state = [params objectForKey:@"state"];
    if ( ![scope isKindOfClass:[NSString class]]
        || 0 == scope.length ) {
        scope = @"snsapi_userinfo";
    }

    self.mscope = scope;

    if ( ![state isKindOfClass:[NSString class]] ) {
        state = nil;
    }
    
    self.callbackId = cbId;
    if ( !self.appId ) {
        [self executeJSErrorCallback:PGPluginErrorInvalidArgument];
        return;
    }
    self.extra = state;
    if ( [_tencentOAuth isSessionValid] ) {
        [self executeJSSucessCallback];
    } else {
        //用户登录
        NSArray *permissions = [NSArray arrayWithObjects:
                                  kOPEN_PERMISSION_GET_USER_INFO,
                                  kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                                  nil];
        BOOL ret = [_tencentOAuth authorize:permissions inSafari:NO];
        if ( !ret ) {
            [self executeJSErrorCallback:PGPluginErrorInvalidArgument];
        }
    }
}

- (void)logout:(NSString*)cbId {
    self.callbackId = cbId;
   // [[self getWXAPI] cancelPreConn];
    [_tencentOAuth logout:nil];
    [_tencentOAuth release];
    _tencentOAuth = nil;
    _tencentOAuth = [[TencentOAuth alloc] initWithAppId:self.appId
                                            andDelegate:self];
    [self clear];
    [self executeJSSucessCallback];
    self.callbackId = nil;
    self.needToSaveFile = YES;
}

- (void)getUserInfo:(NSString*)cbId {
    self.callbackId = cbId;
    if ( ![_tencentOAuth isSessionValid] || ![_tencentOAuth getUserInfo]) {
        [self executeJSErrorCallback:PGOauthErrorNeedLogin];
    }
}

- (void)clear {
    self.openid = nil;
    self.accessToken = nil;
    self.userInfo = nil;
    self.extra = nil;
}

- (NSDictionary*)JSDict {
    NSDictionary *baseDict = [super JSDict];
   // NSDictionary *extendDict = [self getOauthInfo];
    NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithDictionary:baseDict];
    //[retDict addEntriesFromDictionary:extendDict];
    return retDict;
}

- (NSDictionary*)getOauthInfo {
    //authResult
    NSMutableDictionary *authResult = [NSMutableDictionary dictionary];
    [authResult setObject:self.accessToken?self.accessToken:@"" forKey:kPGQQApiKeyAccessToken];
    if ( self.expireTime ) {
        [authResult setObject:[NSNumber numberWithFloat:self.expireTime-[[NSDate date] timeIntervalSince1970]] forKey:kPGQQApiKeyExpriesin];
    }
    // scope
    [authResult setObject:self.mscope?self.mscope:@"" forKey:kPGQQApiKeyScope];
    // openid
    [authResult setObject:self.openid?self.openid:@"" forKey:kPGQQApiKeyOpenid];
    // extra
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:authResult forKey:@"authResult"];
    if ( self.extra ) {
        [params setObject:self.extra forKey:kPGQQApiKeyExtra];
    }
    
    if ( self.userInfo ) {
        NSMutableDictionary* pUserInfoM = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
        if(pUserInfoM)
        {
            NSString* headImgUrl = [pUserInfoM objectForKey:@"figureurl"];
            [pUserInfoM setObject:headImgUrl?headImgUrl:@"" forKey:@"headimgurl"];
            [pUserInfoM setObject:self.openid?self.openid:@"" forKey:kPGQQApiKeyOpenid];
            [params setObject:pUserInfoM forKey:kPGQQApiKeyUserInfo];
        }
        else{
            [params setObject:self.userInfo forKey:kPGQQApiKeyUserInfo];
        }
    }
    return params;
}

- (void)executeJSErrorCallback:(int)erroCode withMessage:(NSString*)message {
    PDRPluginResult *outJS = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:erroCode withMessage:message];
    [self toCallback:self.callbackId withReslut:[outJS toJSONString]];
}

- (void)executeJSErrorCallback:(int)erroCode {
    [self executeJSErrorCallback:erroCode withMessage:[self errorMsgWithCode:erroCode]];
}

- (void)executeJSSucessCallback {
    NSDictionary *params = [self getOauthInfo];
    PDRPluginResult *outJS = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:params];
    [self toCallback:self.callbackId withReslut:[outJS toJSONString]];
}

-(BOOL)loginWithScope:(NSString*)scope state:(NSString*)state {
    return false;
}

#pragma mark -
- (NSString*)getSaveFilePath {
    return [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"tencent_oauth"];
}

- (NSString*)getAesKey {
    return @"tencentoauth";
}

- (void)decodeOauthInfo {
    NSDictionary *dict = [self decodeSaveDict];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        self.openid = [dict objectForKey:kPGQQApiKeyOpenid];
        self.accessToken = [dict objectForKey:kPGQQApiKeyAccessToken];
        self.userInfo = [dict objectForKey:kPGQQApiKeyUserInfo];
        self.extra = [dict objectForKey:kPGQQApiKeyExtra];
        self.expireTime = [[dict objectForKey:kPGQQApiKeyExpriesin] doubleValue];
    }
}

- (void)handleOpenURL:(NSNotification*)notification {
    NSURL *url = [notification object];
    if ( [TencentOAuth CanHandleOpenURL:url] ) {
        [TencentOAuth HandleOpenURL:url];
    }
}

-(NSDictionary*)getSaveDict {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    if ( self.openid ) {
        [output setObject:self.openid forKey:kPGQQApiKeyOpenid];
    }
    if ( self.accessToken ) {
        [output setObject:self.accessToken forKey:kPGQQApiKeyAccessToken];
    }

    if ( self.userInfo ) {
        [output setObject:self.userInfo forKey:kPGQQApiKeyUserInfo];
    }
    if ( self.extra ) {
        [output setObject:self.extra forKey:kPGQQApiKeyExtra];
    }
    [output setObject:[NSNumber numberWithDouble:self.expireTime] forKey:kPGQQApiKeyExpriesin];
    return output;
}

- (void)tencentDidLogin {
    self.accessToken = _tencentOAuth.accessToken;
    self.expireTime = [_tencentOAuth.expirationDate timeIntervalSince1970];
    self.openid = _tencentOAuth.openId;
    self.needToSaveFile = true;
    [self executeJSSucessCallback];
    self.callbackId = nil;
}

/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled {
    [self executeJSErrorCallback:PGPluginErrorUserCancel];
    self.callbackId = nil;
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork {
    [self executeJSErrorCallback:PGPluginErrorNet];
    self.callbackId = nil;
}

- (void)getUserInfoResponse:(APIResponse*) response {
    if ( URLREQUEST_SUCCEED == response.retCode
        && kOpenSDKErrorSuccess == response.detailRetCode ) {
            self.userInfo = response.jsonResponse;
            self.needToSaveFile = true;
            [self executeJSSucessCallback];
    } else {
        [self toErrorCallback:self.callbackId withInnerCode:response.detailRetCode withMessage:response.errorMsg];
        //[self executeJSErrorCallback:response.detailRetCode withMessage:response.errorMsg];
    }
    self.callbackId = nil;
}

- (void)dealloc {
    [self clear];
    self.appId = nil;
    [_tencentOAuth release];
    [super dealloc];
}
@end
