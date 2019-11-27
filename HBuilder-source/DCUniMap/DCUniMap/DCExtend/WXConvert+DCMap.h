//
//  WXConvert+DCMap.h
//  libWeexMap
//
//  Created by XHY on 2019/4/11.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "WXConvert.h"
#import <CoreLocation/CoreLocation.h>
#import "NSArray+DCExtend.h"
#import "NSDictionary+DCExtend.h"
#import "DCMapConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface WXConvert (DCMap)

+ (CLLocationCoordinate2D)CLLocationCoordinate2DLongitude:(double)longitude latitude:(double)latitude;
+ (UIImage*)resizeWithImage:(UIImage *)image scaleSize:(CGSize)size;
+ (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect;
+ (UIEdgeInsets)Padding:(NSArray *)padding;
+ (BOOL)CLLocationCoordinateEqualToCoordinate:(CLLocationCoordinate2D)c1 :(CLLocationCoordinate2D)c2;

@end

NS_ASSUME_NONNULL_END
