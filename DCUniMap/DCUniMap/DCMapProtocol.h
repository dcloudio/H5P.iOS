//
//  DCMapProtocol.h
//  libWeexMap
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DCMapConstant.h"


NS_ASSUME_NONNULL_BEGIN

@protocol DCMapProtocol <NSObject>

- (UIView *)creatMapview;
- (void)setMapAttribute:(NSDictionary *)attributes;

- (NSDictionary *)getCenterLocation;
- (NSDictionary *)getUserLocation;
- (NSDictionary *)getRegion;
- (NSDictionary *)getScale;
- (NSDictionary *)getSkew;
- (NSDictionary *)getRotate;
- (NSDictionary *)setIncludePoints:(NSDictionary *)info;
- (NSDictionary *)moveToLocation:(NSDictionary *)info;
- (void)translateMarker:(NSDictionary *)info block:(void(^)(NSDictionary *))block;

@end

NS_ASSUME_NONNULL_END
