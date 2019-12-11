//
//  DCMapSearchAPI.h
//  AMapImp
//
//  Created by XHY on 2019/5/22.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCMapSearchAPI : NSObject

- (void)reverseGeocode:(NSDictionary *)info block:(void(^)(NSDictionary *))block;
- (void)poiSearchNearBy:(NSDictionary *)info block:(void(^)(NSDictionary *))block;
- (void)poiKeywordsSearch:(NSDictionary *)info block:(void(^)(NSDictionary *))block;
- (void)inputTipsSearch:(NSDictionary *)info block:(void(^)(NSDictionary *))block;
@end

NS_ASSUME_NONNULL_END
