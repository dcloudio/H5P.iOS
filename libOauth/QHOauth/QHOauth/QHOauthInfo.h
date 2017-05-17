//
//  NSObject_QHOauthInfo.h
//  QHOauth
//
//  Created by MacPro on 15-9-16.
//  Copyright (c) 2015年 MacPro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <qucFrameWorkAll/QUCUserModel.h>

@interface QHOauthInfo : NSObject



+ (id)instance;
+ (id)instance:(NSString*)pAppDataPath;

- (id)readOauthInfo;
- (id)initalize:(QUCUserModel*)user;

- (void)setToken:(NSString*)pToken;
- (void)saveOauthInfo;
- (void)removeOauthInfo;
- (void)clearOauthInfo;
- (NSDictionary*)getOauthInfo;
- (NSDictionary*)CallbackInfo;
@end
