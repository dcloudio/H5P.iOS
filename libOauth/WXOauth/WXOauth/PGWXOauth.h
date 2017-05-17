//
//  WXOauth.h
//  WXOauth
//
//  Created by X on 15/3/3.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGOauth.h"
#import "WXApi.h"
#import "WXApiObject.h"

typedef void (^PGWXAPIResult)(NSDictionary*, NSError *);

@interface PGWXAPI : NSObject<NSURLConnectionDelegate>{
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    PGWXAPIResult _resultBlock;
}
@property(nonatomic, retain)NSString *appId;
@property(nonatomic, retain)NSString *appSecret;
@end

@interface PGWXOauth : PGOauth<WXApiDelegate> {
    PGWXAPI *_openApi;
}
@property(nonatomic, retain)NSString *appId;
@property(nonatomic, retain)NSString *code;
@property(nonatomic, retain)NSString *openid;
@property(nonatomic, retain)NSString *appSecret;
@property(nonatomic, retain)NSString *accessToken;
@property(nonatomic, retain)NSString *refreshToken;
@property(nonatomic, assign)NSTimeInterval expireTime;
@property(nonatomic, retain)NSDictionary *userInfo;
@property(nonatomic, retain)NSDictionary *authResult;
@property(nonatomic, assign)BOOL isRevOpenUrl;

@property(nonatomic, retain)NSString *extra;
@property(nonatomic, retain)NSString *callbackId;
- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;
@end
