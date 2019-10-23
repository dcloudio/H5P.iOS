//
//  DCMapModule.m
//  libWeexMap
//
//  Created by XHY on 2019/4/26.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMapModule.h"
#import "DCMapSearchAPI.h"

@interface DCMapModule ()

@property (nonatomic, strong) DCMapSearchAPI *search;
@property (nonatomic, copy) WXModuleKeepAliveCallback reverseGeocodeCallback;
@property (nonatomic, copy) WXModuleKeepAliveCallback poiSearchCallback;

@end


@implementation DCMapModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(reverseGeocode::))
WX_EXPORT_METHOD(@selector(poiSearchNearBy::))

- (DCMapSearchAPI *)search {
    if (!_search) {
        _search = [[DCMapSearchAPI alloc] init];
    }
    return _search;
}

/**
 逆地理编码
 */
- (void)reverseGeocode:(NSDictionary *)info :(WXModuleKeepAliveCallback)callback {
    
    [self.search reverseGeocode:info block:^(NSDictionary * _Nonnull data) {
        if (callback) {
            callback(data,NO);
        }
    }];
}


/**
 周边检索
 */
- (void)poiSearchNearBy:(NSDictionary *)info :(WXModuleKeepAliveCallback)callback {
    
    [self.search poiSearchNearBy:info block:^(NSDictionary * _Nonnull data) {
        if (callback) {
            callback(data,NO);
        }
    }];
}
@end
