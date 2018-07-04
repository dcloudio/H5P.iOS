//
//  PGLocationServerManager.h
//  libGeolocation
//
//  Created by DCloud on 2018/3/1.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGLocationServer.h"

@interface PGLocationServerManager : NSObject
+ (PGLocationServer*)getLocationServerPorvider:(NSString*)provider;
+ (PGLocationServer*)getLocationServer;
@end

typedef void(^LocationResult)(NSDictionary*, NSError*);
@interface PGLocationHelper :NSObject
+ (void)getLocationTestAuthentication:(BOOL)testAuthentication withReslutBlock:(LocationResult)block;
@end
