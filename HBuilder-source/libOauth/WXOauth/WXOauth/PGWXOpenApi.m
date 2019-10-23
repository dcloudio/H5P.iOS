//
//  PGWXOpenApi.m
//  WXOauth
//
//  Created by DCloud on 2018/8/29.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "PGWXOpenApi.h"


#define PGWXAPI_ServiceURL @"https://api.weixin.qq.com/"
#define PGWXAPI_AccessTokenURL @"sns/oauth2/access_token"
#define PGWXAPI_RefreshTokenURL @"sns/oauth2/refresh_token"
#define PGWXAPI_UserinfoURL @"sns/userinfo"


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
