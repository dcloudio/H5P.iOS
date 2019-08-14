//
//  DCMapSearchAPI.h
//  DCUniBMap
//
//  Created by XHY on 2019/7/12.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCMapSearchAPI : NSObject
- (void)reverseGeocode:(NSDictionary *)info block:(void(^)(NSDictionary *))block;
- (void)poiSearchNearBy:(NSDictionary *)info block:(void(^)(NSDictionary *))block;
@end

NS_ASSUME_NONNULL_END
