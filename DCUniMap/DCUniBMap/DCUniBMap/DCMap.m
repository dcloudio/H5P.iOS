//
//  DCMap.m
//  BMapImp
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMap.h"

@implementation DCMap

/** 预留接口 待实现 */
#pragma mark - DCMapProtocol Methods
- (UIView *)creatMapview {
    NSLog(@"调用百度地图");
    
    UIView *view = [[UIView alloc] init];
    return view;
}
- (void)setMapAttribute:(NSDictionary *)attributes {
    
}

- (NSDictionary *)getCenterLocation {return @{};}
- (NSDictionary *)getUserLocation {return @{};}
- (NSDictionary *)getRegion {return @{};}
- (NSDictionary *)getScale {return @{};}
- (NSDictionary *)getSkew {return @{};}
- (NSDictionary *)getRotate {return @{};}
- (NSDictionary *)setIncludePoints:(NSDictionary *)info {return @{};}
- (NSDictionary *)moveToLocation:(NSDictionary *)info {return @{};}
- (void)translateMarker:(NSDictionary *)info block:(void(^)(NSDictionary *))block {}

@end
