//
//  DCMapSearchAPI.m
//  DCUniBMap
//
//  Created by XHY on 2019/7/12.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMapSearchAPI.h"

@implementation DCMapSearchAPI

- (void)reverseGeocode:(NSDictionary *)info block:(void(^)(NSDictionary *))block {}
- (void)poiSearchNearBy:(NSDictionary *)info block:(void(^)(NSDictionary *))block {}

@end
