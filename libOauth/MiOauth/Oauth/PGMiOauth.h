//
//  PGMiOauth.h
//  MiOauth
//
//  Created by EICAPITAN on 16/11/22.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import "PGOauth.h"
#import <MiPassport/MiPassport.h>

typedef void (^PGXiaoMiOpenAPIResult)(NSDictionary* dic, NSError *error);


@interface PGMiOauth : PGOauth 

@property(nonatomic, retain)NSString*   appId;
@property(nonatomic, retain)NSString*   redirectUrl;
@property(nonatomic, retain)NSString*   code;
@property(nonatomic, retain)NSString*   extra;
@property(nonatomic, retain)NSString*   callbackId;
@property(nonatomic, retain)NSString*   openId;
//@property(nonatomic, retain)NSString*   scope;
@property(nonatomic, retain)NSDictionary *userInfo;


- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;
@end


@interface PGMiOpenAPI : NSObject
@property(nonatomic, retain)NSString *appId;
@property(nonatomic, retain)NSString *appSecret;
@property(nonatomic, retain)NSString *regURL;
- (void)getAccessTokenWithCode:(NSString*)code result:(PGXiaoMiOpenAPIResult) result;
- (void)getRefreshTokenWithRefreshToken:(NSString*)refreshToken result:(PGXiaoMiOpenAPIResult) result;
- (void)getUseinfoWithAccessToken:(NSString*)accessToken result:(PGXiaoMiOpenAPIResult) result;

@end
