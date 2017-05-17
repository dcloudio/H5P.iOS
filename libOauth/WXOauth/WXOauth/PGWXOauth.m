//
//  WXOauth.m
//  WXOauth
//
//  Created by X on 15/3/3.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import "PGWXOauth.h"
#import "PDRCore.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#import "PDRToolSystemEx.h"

#define PGWXAPI_ServiceURL @"https://api.weixin.qq.com/"
#define PGWXAPI_AccessTokenURL @"sns/oauth2/access_token"
#define PGWXAPI_RefreshTokenURL @"sns/oauth2/refresh_token"
#define PGWXAPI_UserinfoURL @"sns/userinfo"

NSString *kPGWXApiKeyCode = @"code";
NSString *kPGWXApiKeyOpenid = @"openid";
NSString *kPGWXApiKeyAccessToken = @"access_token";
NSString *kPGWXApiKeyRrefreshToken = @"refresh_token";
NSString *kPGWXApiKeyExpriesin = @"expires_in";
NSString *kPGWXApiKeyUserInfo = @"userInfo";
NSString *kPGWXApiKeyExtra = @"extra";
NSString *kPGWXApiKeyScope = @"scope";

@implementation PGWXAPI
@synthesize appId;
@synthesize appSecret;
- (void)cancelPreConn {
    if ( _connection ) {
        [_connection cancel];
        [_connection release];
        _connection = nil;
        [_responseData release];
        _responseData = nil;
        Block_release(_resultBlock);
        _resultBlock = nil;
    }
}
- (void)newConnWithURL:(NSString*)url {
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    _connection = [NSURLConnection connectionWithRequest:req delegate:self];
    [_connection retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ( !_responseData ) {
        _responseData = [[NSMutableData alloc] initWithData:data];
    } else {
        [_responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ( _resultBlock ) {
        NSError *error = nil;
        NSDictionary *resultDic = nil;
        if ( _responseData ) {
            resultDic = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableLeaves error:&error];
        }
        if ( error ) {
            _resultBlock(nil, error);
        } else {
            NSNumber *errCode = [resultDic objectForKey:@"errcode"];
            if ( errCode || !resultDic ) {
                error = [NSError errorWithDomain:@"PGWXAPI" code:-1 userInfo:nil];
                _resultBlock(nil, error );
            } else {
                _resultBlock(resultDic, nil);
            }
        }
        [self cancelPreConn];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ( _resultBlock ) {
        _resultBlock(nil, error);
        [self cancelPreConn];
    }
}

- (void)reqWithURL:(NSString*)url result:(PGWXAPIResult)result {
    [self cancelPreConn];
    [self newConnWithURL:url];
    [_connection start];
    _resultBlock = Block_copy(result);
}

- (void)reqAccessTokenWithCode:(NSString*)code result:(PGWXAPIResult)result {
    [self reqWithURL:[self getAccessTokenURLWithCode:code]
              result:^(NSDictionary *response, NSError *error) {
                  result(response, error);
    }];
}

- (void)reqAccessTokenWithRefreshToken:(NSString*)refreshToken result:(PGWXAPIResult)result {
    [self reqWithURL:[self getRefreshTokenURLWithRefreshToken:refreshToken]
              result:^(NSDictionary *response, NSError *error) {
                  result(response, error);
              }];
}

- (void)reqUserInfoWithAccessToken:(NSString*)accessToken withOpenId:(NSString*)openId result:(PGWXAPIResult)result {
    [self reqWithURL:[self getUseinfoURLWithAccessToken:accessToken withOpenid:openId]
              result:^(NSDictionary *response, NSError *error) {
                  result(response, error);
              }];
}

- (NSString*)getAccessTokenURLWithCode:(NSString*)code {
    return [NSString stringWithFormat:
            @"%@%@?appid=%@&secret=%@&code=%@&grant_type=authorization_code",
            PGWXAPI_ServiceURL,
            PGWXAPI_AccessTokenURL,
            self.appId,
            self.appSecret,
            code];
}

- (NSString*)getRefreshTokenURLWithRefreshToken:(NSString*)refreshToken {
    return [NSString stringWithFormat:
            @"%@%@?appid=%@&refresh_token=%@&grant_type=refresh_token",
            PGWXAPI_ServiceURL,
            PGWXAPI_RefreshTokenURL,
            self.appId,
            refreshToken];
}

- (NSString*)getUseinfoURLWithAccessToken:(NSString*)accessToken withOpenid:(NSString*)openid {
    return [NSString stringWithFormat:
            @"%@%@?access_token=%@&openid=%@&lang=zh-CN",
            PGWXAPI_ServiceURL,
            PGWXAPI_UserinfoURL,
            accessToken,
            openid];
}

- (void)dealloc {
    self.appId = nil;
    self.appSecret = nil;
    [self cancelPreConn];
    [super dealloc];
}
@end

@implementation PGWXOauth
@synthesize accessToken;
@synthesize code;
@synthesize refreshToken;
@synthesize expireTime;
@synthesize appId;
@synthesize appSecret;
@synthesize mscope;
@synthesize userInfo;
@synthesize authResult;
@synthesize isRevOpenUrl;

@synthesize callbackId, extra;

- (id) init {
    if ( self = [super init] ) {
        NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"weixinoauth"];
        if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
            self.appId = [dhDict objectForKey:@"appid"];
            self.appSecret = [dhDict objectForKey:@"appSecret"];
        }
        self.identify = @"weixin";
        self.note = @"微信";
        if ( self.appId && self.appSecret ) {
            [WXApi registerApp:self.appId];
        }
    }
    return self;
}

- (void)initalize {
    [super initalize];
    [self decodeOauthInfo];
}
- (PGWXAPI*)getWXAPI {
    if ( nil == _openApi ) {
        _openApi = [[PGWXAPI alloc] init];
        _openApi.appId = self.appId;
        _openApi.appSecret = self.appSecret;
    }
    return _openApi;
}

- (void)login:(NSString*)cbId withParams:(NSDictionary*)params{
    NSString *scope = [params objectForKey:kPGWXApiKeyScope];
    NSString *state = [params objectForKey:@"state"];
    NSString *optAppSecret = [params objectForKey:@"appsecret"];
    if ( ![scope isKindOfClass:[NSString class]]
        || 0 == scope.length ) {
        scope = @"snsapi_userinfo";
    }
    
    self.mscope = scope;    
    if ( ![state isKindOfClass:[NSString class]] ) {
        state = nil;
    }
    
    if (optAppSecret != nil && [optAppSecret isKindOfClass:[NSString class]] && optAppSecret.length > 0) {
        self.appSecret = [optAppSecret retain];
        _openApi.appSecret = [optAppSecret retain];
    }
    
    self.callbackId = cbId;
    if ( !self.appId || !self.appSecret ) {
        [self executeJSErrorCallback:PGPluginErrorInvalidArgument];
        return;
    }
   // if ( ![WXApi isWXAppInstalled] ){
       // [self executeJSErrorCallback:PGOauthErrorNotInstall];
       // return;
 //   }
        
    self.extra = state;
    if ( self.accessToken ) {
        if ([[NSDate date] timeIntervalSince1970] < self.expireTime){
            [self executeJSSucessCallback];
        } else {
            //过期刷新token
            [[self getWXAPI] reqAccessTokenWithRefreshToken:self.refreshToken result:^(NSDictionary *result, NSError *error) {
                if ( result ) {
                    self.accessToken = [result objectForKey:kPGWXApiKeyAccessToken];
                    self.expireTime = [[result objectForKey:kPGWXApiKeyExpriesin] integerValue]+[[NSDate date] timeIntervalSince1970];
                    self.openid = [result objectForKey:kPGWXApiKeyOpenid];
                    self.refreshToken = [result objectForKey:kPGWXApiKeyRrefreshToken];
                    [self executeJSSucessCallback];
                    self.needToSaveFile = YES;
                } else {
                    BOOL ret = [self loginWithScope:scope state:state];
                    if ( !ret ) {
                        [self executeJSErrorCallback:PGPluginErrorInvalidArgument];
                    }
                }
            }];
        }
    } else {
        //用户登录
        BOOL ret = [self loginWithScope:scope state:state];
        if ( !ret ) {
            [self executeJSErrorCallback:PGPluginErrorInvalidArgument];
        }
    }
}

- (void)logout:(NSString*)cbId {
    self.callbackId = cbId;
    [[self getWXAPI] cancelPreConn];
    [self clear];
    [self executeJSSucessCallback];
    self.callbackId = nil;
    self.needToSaveFile = YES;
}

- (void)getUserInfo:(NSString*)cbId {
    self.callbackId = cbId;
    if ( self.accessToken ) {
        if ([[NSDate date] timeIntervalSince1970] < self.expireTime){
            [[self getWXAPI] reqUserInfoWithAccessToken:self.accessToken withOpenId:self.openid result:^(NSDictionary *result, NSError *error) {
                if ( result ) {
                    self.userInfo = result;
                    [self executeJSSucessCallback];
                    self.needToSaveFile = YES;
                } else {
                    [self toErrorCallback:self.callbackId withInnerCode:(int)error.code withMessage:error.description];
                   // [self executeJSErrorCallback:(int)error.code withMessage:error.description];
                }
            }];
        } else {
            //过期刷新token
            [[self getWXAPI] reqAccessTokenWithRefreshToken:self.refreshToken result:^(NSDictionary *result, NSError *error) {
                if ( result ) {
                    self.accessToken = [result objectForKey:kPGWXApiKeyAccessToken];
                    self.expireTime = [[result objectForKey:kPGWXApiKeyExpriesin] integerValue]+[[NSDate date] timeIntervalSince1970];
                    self.openid = [result objectForKey:kPGWXApiKeyOpenid];
                    self.refreshToken = [result objectForKey:kPGWXApiKeyRrefreshToken];
                    [[self getWXAPI] reqUserInfoWithAccessToken:self.accessToken withOpenId:self.openid result:^(NSDictionary *result, NSError *error) {
                        if ( result ) {
                            self.userInfo = result;
                            [self executeJSSucessCallback];
                            self.needToSaveFile = YES;
                        } else {
                            [self toErrorCallback:self.callbackId withInnerCode:(int)error.code withMessage:error.description];
                            //[self executeJSErrorCallback:(int)error.code withMessage:error.description];
                        }
                    }];
                }
            }];
        }
    } else {
        //用户登录
        [self executeJSErrorCallback:PGOauthErrorNeedLogin];
    }
}

- (void)clear {
    self.code = nil;
    self.openid = nil;
    self.accessToken = nil;
    self.refreshToken = nil;
    self.userInfo = nil;
    self.extra = nil;
    self.authResult = nil;
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
    NSMutableDictionary *retAuthResult = [NSMutableDictionary dictionary];
    [retAuthResult setObject:self.code?self.code:@"" forKey:kPGWXApiKeyCode];
    if ( self.authResult ) {
        [retAuthResult addEntriesFromDictionary:self.authResult];
    } else {
        [retAuthResult setObject:self.accessToken?self.accessToken:@"" forKey:kPGWXApiKeyAccessToken];
        if ( self.expireTime ) {
            [retAuthResult setObject:[NSNumber numberWithFloat:self.expireTime-[[NSDate date] timeIntervalSince1970]] forKey:kPGWXApiKeyExpriesin];
        }
        [retAuthResult setObject:self.openid?self.openid:@"" forKey:kPGWXApiKeyOpenid];
        [retAuthResult setObject:self.refreshToken?self.refreshToken:@"" forKey:kPGWXApiKeyRrefreshToken];
        [retAuthResult setObject:self.mscope?self.mscope:@"" forKey:kPGWXApiKeyScope];
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ( retAuthResult ) {
        [params setObject:retAuthResult forKey:@"authResult"];
    }
    // extra
    if ( self.extra ) {
        [params setObject:self.extra forKey:kPGWXApiKeyExtra];
    }
    // userInfo
    if ( self.userInfo ) {
        [params setObject:self.userInfo forKey:kPGWXApiKeyUserInfo];
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
    SendAuthReq* req =[[[SendAuthReq alloc ] init ] autorelease ];
    req.scope = scope;
    req.state = state;
    //第三方向微信终端发送一个SendAuthReq消息结构
    
    if ( [WXApi isWXAppInstalled] ) {
        self.isRevOpenUrl = true;
        return [WXApi sendReq:req];
    } else {
        return [WXApi sendAuthReq:req viewController:[self rootViewController] delegate:self];
    }
    
    //if ( [WXApi isWXAppSupportApi] ) {
        ///self.isRevOpenUrl = true;
       /// return [WXApi sendReq:req];
    //}else {
   // }
    return NO;
    
}

-(void) onResp:(BaseResp*)resp {
    if( [resp isKindOfClass:[SendAuthResp class]] ) {
        SendAuthResp *authresp = (SendAuthResp*)resp;

        if ( WXSuccess == authresp.errCode ) {
            self.code = authresp.code;
            [[self getWXAPI] reqAccessTokenWithCode:self.code result:^(NSDictionary *result, NSError *error) {
                if ( !error ) {
                    self.accessToken = [result objectForKey:kPGWXApiKeyAccessToken];
                    self.expireTime = [[result objectForKey:kPGWXApiKeyExpriesin] integerValue]+[[NSDate date] timeIntervalSince1970];
                    self.openid = [result objectForKey:kPGWXApiKeyOpenid];
                    self.refreshToken = [result objectForKey:kPGWXApiKeyRrefreshToken];
                    self.authResult = result;
                    [self executeJSSucessCallback];
                    self.needToSaveFile = YES;
                } else {
                    [self toErrorCallback:self.callbackId withNSError:error];
                }
            }];
        } else {
            [self toErrorCallback:self.callbackId withInnerCode:(int)authresp.errCode withMessage:authresp.errStr];
           // [self executeJSErrorCallback:authresp.errCode withMessage:authresp.errStr];
        }
    }
    
}

- (NSString*)getSaveFilePath {
    return [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"weixin_oauth"];
}

- (NSString*)getAesKey {
    return @"weixinoauth";
}

- (void)decodeOauthInfo {
    NSDictionary *dict = [self decodeSaveDict];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        self.code = [dict objectForKey:kPGWXApiKeyCode];
        self.openid = [dict objectForKey:kPGWXApiKeyOpenid];
        self.accessToken = [dict objectForKey:kPGWXApiKeyAccessToken];
        self.refreshToken = [dict objectForKey:kPGWXApiKeyRrefreshToken];
        self.userInfo = [dict objectForKey:kPGWXApiKeyUserInfo];
        self.extra = [dict objectForKey:kPGWXApiKeyExtra];
        self.expireTime = [[dict objectForKey:kPGWXApiKeyExpriesin] doubleValue];
    }
}

-(NSDictionary*)getSaveDict {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    if ( self.code ) {
        [output setObject:self.code forKey:kPGWXApiKeyCode];
    }
    if ( self.openid ) {
        [output setObject:self.openid forKey:kPGWXApiKeyOpenid];
    }
    if ( self.accessToken ) {
        [output setObject:self.accessToken forKey:kPGWXApiKeyAccessToken];
    }
    if ( self.refreshToken ) {
        [output setObject:self.refreshToken forKey:kPGWXApiKeyRrefreshToken];
    }
    if ( self.userInfo ) {
        [output setObject:self.userInfo forKey:kPGWXApiKeyUserInfo];
    }
    if ( self.extra ) {
        [output setObject:self.extra forKey:kPGWXApiKeyExtra];
    }
    [output setObject:[NSNumber numberWithDouble:self.expireTime] forKey:kPGWXApiKeyExpriesin];
    return output;
}

- (void)handleOpenURL:(NSNotification*)notification {
    if ( self.isRevOpenUrl ) {
        [WXApi handleOpenURL:[notification object] delegate:self];
        self.isRevOpenUrl = false;
    }
}

- (void)dealloc {

    [self clear];
    self.appSecret = nil;
    self.appId = nil;
    [_openApi release];
    [super dealloc];
}
@end
