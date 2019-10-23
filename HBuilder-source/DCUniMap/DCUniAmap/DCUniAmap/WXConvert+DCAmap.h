//
//  WXConvert+DCAmap.h
//  AMapImp
//
//  Created by XHY on 2019/4/22.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "WXConvert.h"

@class DCMapMarker;
@class DCPolyline;
@class DCPolygon;
@class DCCircle;
@class DCMapControl;

NS_ASSUME_NONNULL_BEGIN

@interface WXConvert (DCAmap)

+ (DCMapMarker *)Marker:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor;
+ (DCPolyline *)Polyline:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor;
+ (DCPolygon *)Polygon:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor;
+ (DCCircle *)Circle:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor;
+ (DCMapControl *)Control:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor;

@end

NS_ASSUME_NONNULL_END
