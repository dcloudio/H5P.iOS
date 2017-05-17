//
//  PGSinaWBOauth.m
//  PGSinaWBOauth
//
//  Created by X on 15/3/12.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import "PGSinaWBOauth.h"
#import "PDRCore.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#import "PDRToolSystemEx.h"

static NSString *kPGWBApiKeyuid = @"uid";
static NSString *kPGWBApiKeyAccessToken = @"access_token";
static NSString *kPGWBApiKeyRrefreshToken = @"refresh_token";
static NSString *kPGWBApiKeyExpriesin = @"expires_in";
static NSString *kPGWBApiKeyUserInfo = @"userInfo";
static NSString *kPGWBApiKeyExtra = @"extra";

@implementation PGSinaWBOauth

@synthesize accessToken, redirectURI;
@synthesize expireTime;
@synthesize appId;
@synthesize userInfo;
@synthesize isMeSend;

@synthesize callbackId, extra;

#pragma mark - js invoke
- (void)login:(NSString*)cbId withParams:(NSDictionary*)params{
    NSString *scope = [params objectForKey:@"scope"];
    NSString *state = [params objectForKey:@"state"];
    if ( ![scope isKindOfClass:[NSString class]]
        || 0 == scope.length ) {
        scope = nil;
    }
    if ( ![state isKindOfClass:[NSString class]] ) {
        state = nil;
    }
    
    self.callbackId = cbId;
    if ( !self.appId || !self.redirectURI ) {
        [self toErrorCallback:self.callbackId withCode:PGPluginErrorInvalidArgument];
        return;
    }
    self.extra = state;
    
    if ( self.accessToken ) {
        if ([[NSDate date] timeIntervalSince1970] < self.expireTime) {
            [self executeJSSucessCallback];
            return;
        } else {
            if ( self.refreshToken ) {
                NSOperationQueue *newQueue = [[[NSOperationQueue alloc] init] autorelease];
                [WBHttpRequest requestForRenewAccessTokenWithRefreshToken:self.refreshToken
                                                                    queue:newQueue
                                                    withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
                                                        NSDictionary *retInfo = (NSDictionary*)result;
                                                        if ( [result isKindOfClass:NSDictionary.class] )  {
                                                            self.accessToken = [retInfo objectForKey:kPGWBApiKeyAccessToken];
                                                            self.refreshToken = [retInfo objectForKey:kPGWBApiKeyRrefreshToken];
                                                            NSString *newId = [retInfo objectForKey:kPGWBApiKeyuid];
                                                            if ( newId && NSOrderedSame != [newId caseInsensitiveCompare:self.uid]) {
                                                                self.uid = newId;
                                                                self.userInfo = nil;
                                                            }
                                                            self.needToSaveFile = true;
                                                            self.expireTime = [[retInfo objectForKey:kPGWBApiKeyExpriesin] floatValue]+[[NSDate date] timeIntervalSince1970];
                                                            [self executeJSSucessCallback];
                                                        } else if ( error ) {
                                                            [self toErrorCallback:self.callbackId withInnerCode:(int)error.code withMessage:error.domain];
                                                         //   [self toErrorCallback:self.callbackId withCode:(int)error.code withMessage:error.domain];
                                                        }
                                                        self.callbackId = nil;
                                                    }];
                return;
            }
        }
        
    }
    
    BOOL ret = [self loginWithScope:scope state:state];
    if ( !ret ) {
        [self toErrorCallback:self.callbackId withCode:PGPluginErrorInvalidArgument];
        self.callbackId = nil;
    }
}

- (void)logout:(NSString*)cbId {
    self.callbackId = cbId;
    [WeiboSDK logOutWithToken:self.accessToken delegate:nil withTag:nil];
    [self clear];
    [self executeJSSucessCallback];
    self.callbackId = nil;
    self.needToSaveFile = YES;
}

- (void)getUserInfo:(NSString*)cbId {
    self.callbackId = cbId;
    if ([[NSDate date] timeIntervalSince1970] < self.expireTime) {
        NSOperationQueue *newQueue = [[[NSOperationQueue alloc] init] autorelease];
        [WBHttpRequest requestForUserProfile:self.uid
                             withAccessToken:self.accessToken
                          andOtherProperties:nil
                                       queue:newQueue
                       withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
                           WeiboUser *wbUser = (WeiboUser*)result;
                           if ( [wbUser isKindOfClass:[WeiboUser class]] ) {
                               self.userInfo = wbUser.originParaDict;
                               self.needToSaveFile = TRUE;
                               [self executeJSSucessCallback];
                           } else if ( error ) {
                               [self toErrorCallback:self.callbackId withInnerCode:(int)error.code withMessage:error.domain];
                               //[self toErrorCallback:self.callbackId withCode:(int)error.code withMessage:error.domain];
                           } else {
                               [self toErrorCallback:self.callbackId withCode:PGPluginErrorUnknown];
                           }
                           self.callbackId = nil;
                       }];
        return;
    }
    [self toErrorCallback:self.callbackId withCode:PGOauthErrorNeedLogin];
    self.callbackId = nil;
}

-(void)initalize {
    NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"sinaweibo"];
    if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
        self.appId = [dhDict objectForKey:@"appkey"];
        self.redirectURI = [dhDict objectForKey:@"redirectURI"];
    }

    self.identify = @"sinaweibo";
    self.note = @"新浪微博";
    if ( self.appId ) {
        [WeiboSDK registerApp:self.appId];
        [self decodeOauthInfo];
        [super initalize];
    }
}

#pragma mark - tool
-(BOOL)loginWithScope:(NSString*)scope state:(NSString*)state {
    //用户登录
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = self.redirectURI;
    request.scope = scope;
    self.isMeSend = true;
    return  [WeiboSDK sendRequest:request];
}


- (void)clear {
    self.uid = nil;
    self.refreshToken = nil;
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
    [authResult setObject:self.accessToken?self.accessToken:@"" forKey:kPGWBApiKeyAccessToken];
    if ( self.expireTime ) {
        [authResult setObject:[NSNumber numberWithFloat:self.expireTime-[[NSDate date] timeIntervalSince1970]] forKey:kPGWBApiKeyExpriesin];
    }
    // uid
    [authResult setObject:self.uid ?self.uid:@"" forKey:kPGWBApiKeyuid];
    // extra
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:authResult forKey:@"authResult"];
    if ( self.extra ) {
        [params setObject:self.extra forKey:kPGWBApiKeyExtra];
    }
    if ( self.userInfo ) {
        NSMutableDictionary* pUserInfoM = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
        if(pUserInfoM)
        {
            NSString* headImgUrl = [pUserInfoM objectForKey:@"profile_image_url"];
            NSString* nickname = [pUserInfoM objectForKey:@"name"];
            [pUserInfoM setObject:headImgUrl?headImgUrl:@"" forKey:@"headimgurl"];
            [pUserInfoM setObject:nickname?nickname:@"" forKey:@"nickname"];
            [params setObject:pUserInfoM forKey:kPGWBApiKeyUserInfo];
        }
        else{
            [params setObject:self.userInfo forKey:kPGWBApiKeyUserInfo];
        }
    }
    return params;
}


- (void)executeJSSucessCallback {
    NSDictionary *params = [self getOauthInfo];
    PDRPluginResult *outJS = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:params];
    [self toCallback:self.callbackId withReslut:[outJS toJSONString]];
}

- (void)decodeOauthInfo {
    NSDictionary *dict = [self decodeSaveDict];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        self.uid = [dict objectForKey:kPGWBApiKeyuid];
        self.accessToken = [dict objectForKey:kPGWBApiKeyAccessToken];
        self.refreshToken = [dict objectForKey:kPGWBApiKeyRrefreshToken];
        self.userInfo = [dict objectForKey:kPGWBApiKeyUserInfo];
        self.extra = [dict objectForKey:kPGWBApiKeyExtra];
        self.expireTime = [[dict objectForKey:kPGWBApiKeyExpriesin] doubleValue];
    }
}

#pragma mark - PGOauth delegate
- (NSString*)getSaveFilePath {
    return [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"htuaobwanis"];
}

- (NSString*)getAesKey {
    return @"htuaob_wanis";
}

-(NSDictionary*)getSaveDict {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    if ( self.uid ) {
        [output setObject:self.uid forKey:kPGWBApiKeyuid];
    }
    if ( self.accessToken ) {
        [output setObject:self.accessToken forKey:kPGWBApiKeyAccessToken];
    }
    
    if ( self.refreshToken ) {
        [output setObject:self.refreshToken forKey:kPGWBApiKeyRrefreshToken];
    }
    
    if ( self.userInfo ) {
        [output setObject:self.userInfo forKey:kPGWBApiKeyUserInfo];
    }
    if ( self.extra ) {
        [output setObject:self.extra forKey:kPGWBApiKeyExtra];
    }
    
    [output setObject:[NSNumber numberWithDouble:self.expireTime] forKey:kPGWBApiKeyExpriesin];
    return output;
}

- (void)handleOpenURL:(NSNotification*)notification {
    NSURL *url = [notification object];
    if ( self.isMeSend ) {
        [WeiboSDK handleOpenURL:url delegate:self];
        self.isMeSend = false;
    }
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {

}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:WBAuthorizeResponse.class]) {
        WBAuthorizeResponse *authResponse = (WBAuthorizeResponse*)response;
        if ( WeiboSDKResponseStatusCodeSuccess == authResponse.statusCode ) {
            self.accessToken = authResponse.accessToken;
            self.refreshToken = authResponse.refreshToken;
            self.expireTime = [authResponse.expirationDate timeIntervalSince1970];
           // self.uid = authResponse.userID;
            NSString *newId = authResponse.userID;
            if ( newId && NSOrderedSame != [newId caseInsensitiveCompare:self.uid]) {
                self.uid = newId;
                self.userInfo = nil;
            }
            self.needToSaveFile = true;
            [self executeJSSucessCallback];
            self.callbackId = nil;
        } else {
            [self toErrorCallback:self.callbackId withInnerCode:authResponse.statusCode withMessage:nil];
            //[self toErrorCallback:self.callbackId withCode:PGPluginErrorUserCancel];
            self.callbackId = nil;
        }
    }
}

- (void)dealloc {
   [self clear];
    self.appId = nil;
    self.redirectURI = nil;
    self.callbackId = nil;
    [super dealloc];
}
@end
