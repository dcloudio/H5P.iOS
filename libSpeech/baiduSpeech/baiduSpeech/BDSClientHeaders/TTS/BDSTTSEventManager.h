//
//  BDSTTSEventManager.h
//  BDSpeechClient
//
//  Created by baidu on 16/6/6.
//  Copyright © 2016年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* BDS_ETTS_MODEL_MANAGER_NAME;

@interface BDSTTSEventManager : NSObject

+ (BDSTTSEventManager *)createEventManagerWithName:(NSString *)name;
- (BOOL)setParameter:(id)param forKey:(NSString *)key;
- (void)sendCommand:(NSString *)command;
- (void)sendCommand:(NSString *)command withParameters:(NSDictionary*)params;
- (BOOL)setDelegate:(id)delegate;
- (NSString *)libver;

@end
