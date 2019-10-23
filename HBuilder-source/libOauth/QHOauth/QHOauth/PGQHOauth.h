//
//  QHOauth.h
//  QHOauth
//
//  Created by MacPro on 15-9-16.
//  Copyright (c) 2015年 MacPro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGOauth.h"

@interface PGQHOauth : PGOauth

@property (nonatomic,retain)NSString* pCallBackID;
@property (nonatomic,retain)NSDictionary* pParams;
@property (nonatomic,retain)NSString* pSignKey;
@property (nonatomic,retain)NSString* pDestKey;
@property (nonatomic,retain)NSString* pChannelID;
@property (nonatomic,retain)NSString* pAppid;

- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;

@end
