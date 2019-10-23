//
//  PGWXOpenApi.h
//  WXOauth
//
//  Created by DCloud on 2018/8/29.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PGWXAPIResult)(NSDictionary*, NSError *);

@interface PGWXAPI : NSObject<NSURLConnectionDelegate>{
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    PGWXAPIResult _resultBlock;
}
@property(nonatomic, retain)NSString *appId;
@property(nonatomic, retain)NSString *appSecret;
- (void)reqAccessTokenWithCode:(NSString*)code result:(PGWXAPIResult)result;
- (void)reqAccessTokenWithRefreshToken:(NSString*)refreshToken result:(PGWXAPIResult)result;
- (void)reqUserInfoWithAccessToken:(NSString*)accessToken withOpenId:(NSString*)openId result:(PGWXAPIResult)result;
- (NSString*)getAccessTokenURLWithCode:(NSString*)code;
- (NSString*)getRefreshTokenURLWithRefreshToken:(NSString*)refreshToken;
- (NSString*)getUseinfoURLWithAccessToken:(NSString*)accessToken withOpenid:(NSString*)openid;
- (void)cancelPreConn;
@end
