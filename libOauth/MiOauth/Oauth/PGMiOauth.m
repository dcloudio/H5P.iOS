//
//  PGMiOauth.m
//  MiOauth
//
//  Created by EICAPITAN on 16/11/22.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import "PGMiOauth.h"
#import "PDRCore.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#import "PDRToolSystemEx.h"

typedef void (^PGMiRequestResult)(NSData* dic, NSError *error);

NSString *kPGMiApiKeyOpenid         = @"openId";
NSString *kPGMiApiKeyAccessToken    = @"access_token";
NSString *kPGMiApiKeyRrefreshToken  = @"refresh_token";
NSString *kPGMiApiKeyExpriesin      = @"expires_in";
NSString *kPGMiApiKeyUserInfo       = @"userInfo";
NSString *kPGMiApiKeyExtra          = @"extra";
NSString *kPGMiApiKeyExpDate        = @"expireTime";
NSString *kPGMiApiKeyCode           = @"code";
NSString *kPGMiApiKeyAuthResult    = @"authResult";



@interface PGMiOauth()<MPSessionDelegate>
{
    PGMiOpenAPI*    _XmiOpenAPI;
    MiPassport*     _XmiPassPort;
}

@property(nonatomic, retain)NSDate*     expDate;
@property(nonatomic, retain)NSString*   appSecret;
@property(nonatomic, retain)NSString*   expires_in;
@property(nonatomic, retain)NSString*   accessToken;
@property(nonatomic, retain)NSString*   refreshtoken;
@property(nonatomic, retain)NSMutableDictionary* oauthResult;

@end


@implementation PGMiOauth
@synthesize appSecret;
@synthesize appId;
@synthesize redirectUrl;
@synthesize callbackId;
@synthesize expDate;
@synthesize expires_in;
@synthesize accessToken;
@synthesize refreshtoken;
@synthesize code;
@synthesize extra;
@synthesize openId;
@synthesize userInfo;
@synthesize oauthResult;


- (void)initalize
{
    NSDictionary* pMiOauth = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"xiaomioauth"];
    if (pMiOauth) {
        appId = [pMiOauth objectForKey:@"appid"];
        redirectUrl = [pMiOauth objectForKey:@"redirectURI"];
        appSecret = [pMiOauth objectForKey:@"appsecret"];
    }
    
    self.identify = @"xiaomi";
    self.note = @"小米";
    
    [self initOauthData];
    [super initalize];
    
//    if (appId) {
//        if (self.accessToken == nil) {
//            _XmiPassPort = [[MiPassport alloc] initWithAppId:appId redirectUrl:redirectUrl andDelegate:self];
//        }
//    }

}


- (void)login:(NSString*)cbId withParams:(NSDictionary*)params
{
    NSString *Optappkey = [params objectForKey:@"appkey"];
    NSString *optAppsecret = [params objectForKey:@"appsecret"];
    NSString *optRedirectURL = [params objectForKey:@"redirecturl"];
    
    if (optRedirectURL != nil && [optRedirectURL isKindOfClass:[NSString class]] && optRedirectURL.length > 0) {
        redirectUrl = [optRedirectURL retain];
    }
    if ( optAppsecret != nil && [optAppsecret isKindOfClass:[NSString class]] && optAppsecret.length > 0 ) {
        appSecret = [optAppsecret retain];
    }
    
    self.callbackId = cbId;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (nil == accessToken) {
            if (_XmiPassPort) {
                [_XmiPassPort applyPassCodeWithPermissions:nil];
            }
            else{
                _XmiPassPort = [[MiPassport alloc] initWithAppId:self.appId redirectUrl:redirectUrl andDelegate:self];
                [_XmiPassPort applyPassCodeWithPermissions:nil];
            }
        }else{
            if ([self tokenAvailed]) {
                [self executeJSSucessCallback];
            }
            else if(_XmiPassPort){
                [_XmiPassPort applyPassCodeWithPermissions:nil];
            }
            else{
                _XmiPassPort = [[MiPassport alloc] initWithAppId:self.appId redirectUrl:redirectUrl andDelegate:self];
                [_XmiPassPort applyPassCodeWithPermissions:nil];
            }
        }
    });
}


- (void)getUserInfo:(NSString*)cbId
{
    self.callbackId = cbId;
    if ([self tokenAvailed])
    {
        if (userInfo && [userInfo isKindOfClass:[NSDictionary class]]) {
            [self executeJSSucessCallback];
        }
        else
        {
            [[self getOpenAPI] getUseinfoWithAccessToken:self.accessToken result:^(NSDictionary *dic, NSError *error) {
                if (dic != nil) {
                    if ([[dic objectForKey:@"result"] isEqualToString:@"ok"]) {
                        self.userInfo = [NSDictionary dictionaryWithDictionary: [dic objectForKey:@"data"]];
                        [self executeJSSucessCallback];
                        self.needToSaveFile = YES;
                    }else{
                        [self executeJSErrorCallback:PGPluginErrorInner withMessage:dic.description];
                    }

                }else{
                    [self executeJSErrorCallback:error.code withMessage:error.description];
                }
            }];
        }
    }
    else
    {
        if (self.accessToken) {
            // 需要刷新token
            [[self getOpenAPI] getRefreshTokenWithRefreshToken:self.refreshtoken result:^(NSDictionary *dic, NSError *error) {
                
                if (dic) {
                    if ([dic objectForKey:@"error"] == nil) {
                        [self makeOauthInfoByDic:dic];
                        [[self getOpenAPI] getUseinfoWithAccessToken:self.accessToken result:^(NSDictionary *dic, NSError *error) {
                            if (dic) {
                                if ([[dic objectForKey:@"result"] isEqualToString:@"ok"]) {
                                    self.userInfo = [dic objectForKey:@"data"];
                                    self.needToSaveFile = YES;
                                    [self executeJSSucessCallback];
                                }
                                else{
                                    [self executeJSErrorCallback:PGOauthErrorNeedLogin];
                                }
                                
                            }
                            else{
                                [self executeJSErrorCallback:PGOauthErrorNeedLogin];
                            }
                        }];
                    }
                    else{
                        [self executeJSErrorCallback:PGOauthErrorNeedLogin];
                    }
                }
                else{
                    [self executeJSErrorCallback:PGOauthErrorNeedLogin];
                }
            }];
        }
        else{
            //用户登录
            [self executeJSErrorCallback:PGOauthErrorNeedLogin];
        }        
    }
}



- (void)logout:(NSString*)cbId
{
    self.callbackId = cbId;
    if (_XmiPassPort) {
        [_XmiPassPort logOut];
    }
    else{
        [self logoutSucess];
    }
}


#pragma mark - local Functions

- (void)initOauthData
{
    NSDictionary* pSaveDic = [self decodeSaveDict];
    if (pSaveDic) {
        accessToken = [[pSaveDic objectForKey:kPGMiApiKeyAccessToken] retain];
        refreshtoken = [[pSaveDic objectForKey:kPGMiApiKeyRrefreshToken] retain];
        openId = [[pSaveDic objectForKey:kPGMiApiKeyOpenid] retain];
        extra = [[pSaveDic objectForKey:kPGMiApiKeyExtra] retain];
        expDate = [[self getDateFromString:[pSaveDic objectForKey:kPGMiApiKeyExpDate]] retain];
        expires_in = [[pSaveDic objectForKey:kPGMiApiKeyExpriesin] retain];        
        userInfo = [[pSaveDic objectForKey:kPGMiApiKeyUserInfo] retain];
        oauthResult = [[pSaveDic objectForKey:kPGMiApiKeyAuthResult] retain];
    }
}

- (PGMiOpenAPI*)getOpenAPI
{
    if (nil == _XmiOpenAPI) {
        _XmiOpenAPI = [[PGMiOpenAPI alloc] init];
        if (_XmiOpenAPI) {
            _XmiOpenAPI.appId = self.appId;
            _XmiOpenAPI.appSecret = self.appSecret;
            _XmiOpenAPI.regURL = self.redirectUrl;
        }
    }
    return _XmiOpenAPI;
}

- (void)logoutSucess
{
    [self clear];
    if (self.callbackId)
        [self executeJSSucessCallback];
    self.callbackId = nil;
    self.needToSaveFile = YES;
    [self resetPassPort];
}


- (void)resetPassPort
{
    if (_XmiPassPort) {
        [_XmiPassPort release];
        _XmiPassPort = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            _XmiPassPort = [[MiPassport alloc] initWithAppId:self.appId redirectUrl:redirectUrl andDelegate:self];
        });
    }
}

-(NSDictionary*)getSaveDict {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    
    if ( self.accessToken )
        [output setObject:self.accessToken forKey:kPGMiApiKeyAccessToken];
    
    if ( self.userInfo )
        [output setObject:self.userInfo forKey:kPGMiApiKeyUserInfo];
    
    if ( self.extra )
        [output setObject:self.extra forKey:kPGMiApiKeyExtra];
    
    if (self.expires_in)
        [output setObject:expires_in forKey:kPGMiApiKeyExpriesin];
    
    if(self.refreshtoken)
        [output setObject:refreshtoken forKey:kPGMiApiKeyRrefreshToken];
    
    if (expDate)
        [output setObject:expDate.description forKey:kPGMiApiKeyExpDate];

    if (oauthResult) {
        [output setObject:oauthResult forKey:kPGMiApiKeyAuthResult];
    }

    return output;
    
}

- (NSDictionary*)getOauthInfo {

    NSMutableDictionary *retAuthResult = [NSMutableDictionary dictionary];
    if (oauthResult) {
        [retAuthResult addEntriesFromDictionary:oauthResult];
    }else{
        [retAuthResult setObject:accessToken?accessToken:@"" forKey:kPGMiApiKeyAccessToken];
        [retAuthResult setObject:openId?openId:@"" forKey:kPGMiApiKeyOpenid];
        [retAuthResult setObject:code?code:@"" forKey:kPGMiApiKeyCode];
        [retAuthResult setObject:extra?extra:@"" forKey:kPGMiApiKeyExtra];
        [retAuthResult setObject:expires_in?expires_in:@"" forKey:kPGMiApiKeyExpriesin];
        [retAuthResult setObject:refreshtoken?refreshtoken:@"" forKey:kPGMiApiKeyRrefreshToken];
    }
    
    if (expires_in)
        [retAuthResult setObject:self.expires_in forKey:kPGMiApiKeyExpriesin];
    
    
    NSMutableDictionary* pParam = [NSMutableDictionary dictionary];
    if (pParam) {
        [pParam setObject:retAuthResult forKey:@"authResult"];
    }
    
    if (self.userInfo)
    {
        NSMutableDictionary* pUserDic = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
        if(pUserDic)
        {
            NSString* nickName = [self.userInfo objectForKey:@"miliaoNick"];
            NSString* headImageurl = [self.userInfo objectForKey:@"miliaoIcon_orig"];
            [pUserDic setObject:nickName?nickName:@"" forKey:@"nickname"];
            [pUserDic setObject:headImageurl?headImageurl:@"" forKey:@"headimgurl"];
            [pUserDic setObject:openId?openId:@"" forKey:kPGMiApiKeyOpenid];
            
            [pParam setObject:pUserDic forKey:kPGMiApiKeyUserInfo];
        }
        else{
            [pParam setObject:self.userInfo forKey:kPGMiApiKeyUserInfo];
        }
    }
    
    if (self.extra)
        [pParam setObject:extra forKey:kPGMiApiKeyExtra];

    return pParam;
}


- (NSDate*)getDateFromString:(NSString*)pData
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss +0000"];
    return  [dateFormatter dateFromString:pData];
}


- (BOOL)tokenAvailed
{
    if (accessToken && [accessToken isKindOfClass:[NSString class]]) {
        if([[NSDate date] compare:self.expDate] == NSOrderedAscending)
        {
            return true;
        }
    }
    return false;
}


- (NSString*)getSaveFilePath {
    return [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"xiaomi_oauth"];
}

- (NSString*)getAesKey {
    return @"xiaominoauth";
}


- (void)clear {
    expDate = nil;
    expires_in = nil;
    accessToken = nil;
    refreshtoken = nil;
    code = nil;
    extra = nil;
    userInfo = nil;
    oauthResult = nil;
    openId = nil;
    appSecret = nil;
}


#pragma mark - CallBackFunction

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

#pragma mark - make ClassData With Dic
- (void)makeOauthInfoByDic:(NSDictionary*)pInfoDic
{
    if (pInfoDic) {
        NSArray* pAllKeys = [pInfoDic allKeys];
        for (NSString* pItem in pAllKeys) {
            NSString* pStrValue = [pInfoDic objectForKey:pItem];
            if([pItem isEqualToString:kPGMiApiKeyAccessToken])
            {
                self.accessToken = [pStrValue retain];
            }
            else if([pItem isEqualToString:kPGMiApiKeyRrefreshToken])
            {
                self.refreshtoken = [pStrValue retain];
            }
            else if([pItem isEqualToString:kPGMiApiKeyExpriesin])
            {
                self.expires_in = [pStrValue retain];
                self.expDate = [NSDate dateWithTimeIntervalSince1970: [[NSDate date] timeIntervalSince1970] + [self.expires_in integerValue]];
            }
        }
    }
}


#pragma mark - MPSessionDelegate

//登录失败
- (void)passport:(MiPassport *)passport failedWithError:(NSError *)error{
    [self executeJSErrorCallback:PGPluginErrorInner withMessage:error.localizedDescription];
}

// 用户取消登录
- (void)passportDidCancel:(MiPassport *)passport{
    [self executeJSErrorCallback:PGPluginErrorUserCancel];
}

//登出成功
- (void)passportDidLogout:(MiPassport *)passport{
    [self logoutSucess];
}

// 获取Code
- (void)passport:(MiPassport *)passport didGetCode:(NSString *)Oauthcode{
    code = [[NSString stringWithString:Oauthcode] retain];
    [[self getOpenAPI] getAccessTokenWithCode:code result:^(NSDictionary *dic, NSError *error) {
        if (dic != nil && error == nil) {
            [self makeOauthInfoByDic:dic];
            if(self.oauthResult == nil)
                self.oauthResult = [NSMutableDictionary dictionaryWithDictionary:dic];
            else
                [self.oauthResult addEntriesFromDictionary:dic];
            // 判断登录
            if ([dic objectForKey:@"error"]) {
                [self toErrorCallback:self.callbackId withInnerCode:[[dic objectForKey:@"error"] intValue] withMessage:[dic objectForKey:@"error_description"]];
                if (_XmiPassPort) {
                    self.callbackId = nil;
                    [_XmiPassPort logOut];
                }
            }else if([dic objectForKey:kPGMiApiKeyAccessToken] != nil){
                [self executeJSSucessCallback];
            }
        }
        
    }];
}


//token过期
- (void)passport:(MiPassport *)passport accessTokenInvalidOrExpired:(NSError *)error{
    
}

#pragma mark - MPRequestDelegate

// 请求失败， error包含错误信息
- (void)request:(MPRequest *)request didFailWithError:(NSError *)error{
    if (error) {
        [self toErrorCallback:self.callbackId withInnerCode:error.code withMessage:error.domain];
    }
    else{
        [self executeJSErrorCallback:PGPluginErrorUnknown];
    }
    self.callbackId = nil;
}

// 请求成功，result为处理后的请求结果
- (void)request:(MPRequest *)request didLoad:(id)result{
    if (result) {
        self.userInfo = result;
        self.needToSaveFile = YES;
        [self executeJSSucessCallback];
    }
    self.callbackId = nil;
}
@end

#pragma mark - XiaoMi Open API
@implementation PGMiOpenAPI
@synthesize appId;
@synthesize appSecret;
@synthesize regURL;

- (void)requestXiaoMiOauthAPI:(NSURL*)pURL result:(PGMiRequestResult)result
{
    NSURLSessionTask* pSessionTask = [[NSURLSession sharedSession] dataTaskWithURL:pURL
                                                                 completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                                                                     result(data, error);
                                                                 }];
    [pSessionTask resume];
}

- (void)getAccessTokenWithCode:(NSString*)code result:(PGXiaoMiOpenAPIResult) result{
    NSString* URLStr = [NSString stringWithFormat:@"https://account.xiaomi.com/oauth2/token?client_id=%@&redirect_uri=%@&client_secret=%@&code=%@&grant_type=authorization_code",self.appId, self.regURL, [self.appSecret URLEncodedStringEx],code];
    [self requestXiaoMiOauthAPI:[NSURL URLWithString:URLStr] result:^(NSData * dic, NSError * error) {
        
        if (dic){
            NSMutableData* pMutabResult = [NSMutableData dataWithData:dic];
            [pMutabResult replaceBytesInRange:NSMakeRange(0, 11) withBytes:NULL length:0];
            NSDictionary* pResultDic = [NSJSONSerialization JSONObjectWithData:pMutabResult
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:&error];
            if (pResultDic) {
                result(pResultDic, error);
            }
            else
            {
                NSError* pError = [NSError errorWithDomain:@"PGWXAPI" code:-1 userInfo:nil];
                result(nil, pError);
            }
        }
        else{
            result(nil, error);
        }
    }];
}

- (void)getRefreshTokenWithRefreshToken:(NSString*)refreshToken result:(PGXiaoMiOpenAPIResult) result{
    NSString* URLStr =  [NSString stringWithFormat:@"https://account.xiaomi.com/oauth2/token?client_id=%@&redirect_uri=%@&client_secret=%@&refresh_token=%@&grant_type=refresh_token",self.appId,self.regURL,[self.appSecret URLEncodedStringEx], refreshToken];
    [self requestXiaoMiOauthAPI:[NSURL URLWithString:URLStr] result:^(NSData * dic, NSError * error) {
        if (dic) {
            NSMutableData* pMutabResult = [NSMutableData dataWithData:dic];
            [pMutabResult replaceBytesInRange:NSMakeRange(0, 11) withBytes:NULL length:0];
            NSDictionary* pResultDic = [NSJSONSerialization JSONObjectWithData:pMutabResult
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:&error];
            if (pResultDic) {
                result(pResultDic, error);
            }
            else
            {
                NSError* pError = [NSError errorWithDomain:@"PGWXAPI" code:-1 userInfo:nil];
                result(nil, pError);
            }
        }
        else{
            result(nil, error);
        }
    }];
}

- (void)getUseinfoWithAccessToken:(NSString*)accessToken result:(PGXiaoMiOpenAPIResult) result{
    NSString* URLStr =  [NSString stringWithFormat:@"https://open.account.xiaomi.com/user/profile?clientId=%@&token=%@", self.appId,accessToken];
    [self requestXiaoMiOauthAPI:[NSURL URLWithString:URLStr] result:^(NSData * dic, NSError * error) {
        if (dic){
            NSMutableData* pMutabResult = [NSMutableData dataWithData:dic];
            NSDictionary* pResultDic = [NSJSONSerialization JSONObjectWithData:pMutabResult
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:&error];
            if (pResultDic) {
                result(pResultDic, error);
            }
            else
            {
                NSError* pError = [NSError errorWithDomain:@"PGWXAPI" code:-1 userInfo:nil];
                result(nil, pError);
            }
        }
        else{
            result(nil, error);
        }
    }];
}

- (void)dealloc {
    self.appId = nil;
    self.appSecret = nil;
    self.regURL = nil;
    [super dealloc];
}
@end
