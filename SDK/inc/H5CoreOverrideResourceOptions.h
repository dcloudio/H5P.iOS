//
//  H5CoreOverrideResourceOptions.h
//  libPDRCore
//
//  Created by DCloud on 2016/11/21.
//  Copyright © 2016年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface H5CoreOverrideResource : NSObject
@property(nonatomic, retain)NSString *match;
@property(nonatomic, retain)NSString *redirect;
@property(nonatomic, retain)NSString *mime;
@property(nonatomic, retain)NSString *encoding;
@property(nonatomic, retain)NSDictionary *header;
+(instancetype)overrideResourceWithOptions:(NSDictionary*)dict;
@end


@interface H5CoreOverrideResourceOptions : NSObject
@property(nonatomic, retain)NSString *key;
+(instancetype)overrideResourceWithOptions:(NSArray*)dict;
- (BOOL)isOverrideWithURL:(NSString*)url;
- (H5CoreOverrideResource*)getOverrideResourceWithURL:(NSString*)url;
@end

@interface H5CoreOverrideResourceRuleManager : NSObject
+ (instancetype)ruleManager;
- (void)addRule:(NSArray*)rule
 withWebviewKey:(NSString*)key;
- (void)addRuleWithOR:(H5CoreOverrideResourceOptions*)ov
       withWebviewKey:(NSString*)key;
- (BOOL)isOverrideWithURL:(NSString*)url;
- (H5CoreOverrideResource*)getOverrideResourceWithURL:(NSString*)url;
@end
