//
//  QQAuth.h
//  QQAuth
//
//  Created by X on 15/3/12.
//  Copyright (c) 2015年 io.dcloud.Oauth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "PGOauth.h"

@interface PGQQOauth : PGOauth<TencentSessionDelegate> {
    TencentOAuth *_tencentOAuth;
}
@property(nonatomic, strong)NSString *appId;
@property(nonatomic, strong)NSString *openid;
@property(nonatomic, strong)NSString *accessToken;
@property(nonatomic, assign)NSTimeInterval expireTime;
@property(nonatomic, strong)NSDictionary *userInfo;

@property(nonatomic, strong)NSString *extra;
@property(nonatomic, strong)NSString *callbackId;
- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;
@end
