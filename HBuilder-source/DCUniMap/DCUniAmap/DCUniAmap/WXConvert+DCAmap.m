//
//  WXConvert+DCAmap.m
//  AMapImp
//
//  Created by XHY on 2019/4/22.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "WXConvert+DCAmap.h"
#import "DCMapMarker.h"
#import "DCPolyline.h"
#import "DCPolygon.h"
#import "DCCircle.h"
#import "DCMapControl.h"
#import "DCMapLabelModel.h"
#import "WXUtility.h"

@implementation WXConvert (DCAmap)

+ (DCMapMarker *)Marker:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor{
    DCMapMarker *marker = [[DCMapMarker alloc] init];
    double lon = [[info dc_safeObjectForKey:dc_map_longitude] doubleValue];
    double lat = [[info dc_safeObjectForKey:dc_map_latitude] doubleValue];
    marker.coordinate = [WXConvert CLLocationCoordinate2DLongitude:lon latitude:lat];
    marker._id = [info dc_safeObjectForKey:dc_map_id] ? [[info dc_safeObjectForKey:dc_map_id] integerValue] : 0;
    marker.title = [info dc_safeObjectForKey:dc_map_title];
    marker.alpha = [info dc_safeObjectForKey:dc_map_alpha] ? [[info dc_safeObjectForKey:dc_map_alpha] floatValue] : 1;
    marker.zIndex = [info dc_safeObjectForKey:dc_map_zIndex] ? [[info dc_safeObjectForKey:dc_map_zIndex] integerValue] : 0;
    marker.rotate = [info dc_safeObjectForKey:dc_map_rotate] ? [[info dc_safeObjectForKey:dc_map_rotate] integerValue] : 0;
    marker.width = info[dc_map_width] ? [WXConvert WXPixelType:info[dc_map_width] scaleFactor:pixelScaleFactor] : 0;
    marker.height = info[dc_map_height] ? [WXConvert WXPixelType:info[dc_map_height] scaleFactor:pixelScaleFactor] : 0;
    marker.iconPath = [info dc_safeObjectForKey:dc_map_iconPath];
    
    if ([info dc_safeObjectForKey:dc_map_anchor] && [[info dc_safeObjectForKey:dc_map_anchor] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *anchor = [info dc_safeObjectForKey:dc_map_anchor];
        CGFloat x = [anchor dc_safeObjectForKey:@"x"] ? [[anchor dc_safeObjectForKey:@"x"] floatValue] : 0.5;
        CGFloat y = [anchor dc_safeObjectForKey:@"y"] ? [[anchor dc_safeObjectForKey:@"y"] floatValue] : 1;
        marker.anchor = CGPointMake(x, y);
    } else {
        marker.anchor = CGPointMake(0.5, 1);
    }
    
    if (info[dc_map_callout] && [info[dc_map_callout] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *calloutInfo = info[dc_map_callout];
        DCMapCalloutModel *calloutModel = [[DCMapCalloutModel alloc] init];
        calloutModel.content = calloutInfo[dc_map_content] ? [WXConvert NSString:calloutInfo[dc_map_content]] : @"";
        calloutModel.color = calloutInfo[dc_map_color] ? [WXConvert UIColor:calloutInfo[dc_map_color]] : [UIColor blackColor];
        calloutModel.fontSize = calloutInfo[dc_map_fontSize] ? [WXConvert CGFloat:calloutInfo[dc_map_fontSize]] : k_dcmap_CalloutDefTitleFontsize;
        calloutModel.borderRadius = calloutInfo[dc_map_borderRadius] ? [WXConvert CGFloat:calloutInfo[dc_map_borderRadius]] : 0;
        calloutModel.borderWidth = calloutInfo[dc_map_borderWidth] ? [WXConvert WXPixelType:calloutInfo[dc_map_borderWidth] scaleFactor:pixelScaleFactor] : 0;
        calloutModel.borderColor = calloutInfo[dc_map_borderColor] ? [WXConvert UIColor:calloutInfo[dc_map_borderColor]] : [UIColor whiteColor];
        calloutModel.bgColor = calloutInfo[dc_map_bgColor] ? [WXConvert UIColor:calloutInfo[dc_map_bgColor]] : [UIColor whiteColor];
        calloutModel.padding = calloutInfo[dc_map_padding] ? [WXConvert CGFloat:calloutInfo[dc_map_padding]] : 0;
        calloutModel.display = calloutInfo[dc_map_display] ? [WXConvert NSString:calloutInfo[dc_map_display]] : dc_map_BYCLICK;
        calloutModel.textAlign = NSTextAlignmentCenter;
        if (calloutInfo[dc_map_textAlign]) {
            NSString *textAlign = [WXConvert NSString:calloutInfo[dc_map_textAlign]];
            if ([textAlign isEqualToString:@"left"]) {
                calloutModel.textAlign = NSTextAlignmentLeft;
            } else if ([textAlign isEqualToString:@"right"]) {
                calloutModel.textAlign = NSTextAlignmentRight;
            }
        }
        marker.callout = calloutModel;
    }
    
    if (info[@"label"]) {
        NSDictionary *labelInfo = info[@"label"];
        if (labelInfo[dc_map_content]) {
            DCMapLabelModel *label = [[DCMapLabelModel alloc] init];
            label.content = labelInfo[dc_map_content] ?: @"";
            label.color = labelInfo[dc_map_color] ? [WXConvert UIColor:labelInfo[dc_map_color]] : [UIColor blackColor];
            label.fontSize = labelInfo[dc_map_fontSize] ? [WXConvert CGFloat:labelInfo[dc_map_fontSize]] : 16;
            label.anchorX = labelInfo[@"anchorX"] ? [WXConvert WXPixelType:labelInfo[@"anchorX"] scaleFactor:pixelScaleFactor] : 0;
            label.anchorY = labelInfo[@"anchorY"] ? [WXConvert WXPixelType:labelInfo[@"anchorY"] scaleFactor:pixelScaleFactor] : 0;
            label.borderWidth = labelInfo[dc_map_borderWidth] ? [WXConvert WXPixelType:labelInfo[dc_map_borderWidth] scaleFactor:pixelScaleFactor] : 0;
            label.borderColor = labelInfo[dc_map_borderColor] ? [WXConvert UIColor:labelInfo[dc_map_borderColor]] : [UIColor clearColor];
            label.borderRadius = labelInfo[dc_map_borderRadius] ? [WXConvert WXPixelType:labelInfo[dc_map_borderRadius] scaleFactor:pixelScaleFactor] : 0;
            label.bgColor = labelInfo[dc_map_bgColor] ? [WXConvert UIColor:labelInfo[dc_map_bgColor]] : [UIColor clearColor];
            label.padding = labelInfo[dc_map_padding] ? [WXConvert WXPixelType:labelInfo[dc_map_padding] scaleFactor:pixelScaleFactor] : 0;
            label.textAlign = NSTextAlignmentCenter;
            if (labelInfo[dc_map_textAlign]) {
                NSString *textAlign = [NSString stringWithFormat:@"%@",labelInfo[dc_map_textAlign]];
                if ([textAlign isEqualToString:@"left"]) {
                    label.textAlign = NSTextAlignmentLeft;
                }
                else if ([textAlign isEqualToString:@"right"]) {
                    label.textAlign = NSTextAlignmentRight;
                }
            }
            marker.labelModel = label;
        }
    }
    
    return marker;
}

+ (DCPolyline *)Polyline:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor{
    
    if (!info[dc_map_points] || ![info[dc_map_points] isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *points = info[dc_map_points];
    CLLocationCoordinate2D linePoints[points.count];
    for (int i = 0; i < points.count; i++) {
        NSDictionary *dic = points[i];
        if (![dic isKindOfClass:[NSDictionary class]]) continue;
        
        if (dic[dc_map_longitude] && dic[dc_map_latitude]) {
            linePoints[i].latitude = [WXConvert CGFloat:dic[dc_map_latitude]];
            linePoints[i].longitude = [WXConvert CGFloat:dic[dc_map_longitude]];
        }
    }

    DCPolyline *polyline = [DCPolyline polylineWithCoordinates:linePoints count:points.count];
    polyline.color = info[dc_map_color] ?: nil;
    polyline.width = info[dc_map_width] ? [WXConvert WXPixelType:info[dc_map_width] scaleFactor:pixelScaleFactor] : 0;
    polyline.dottedLine = info[dc_map_dottedLine] ? [WXConvert BOOL:info[dc_map_dottedLine]] : NO;
    polyline.arrowLine = info[dc_map_arrowLine] ? [WXConvert BOOL:info[dc_map_arrowLine]] : NO;
    polyline.arrowIconPath = info[@"arrowIconPath"];
    polyline.borderColor = info[dc_map_borderColor] ?: nil;
    polyline.borderWidth = info[dc_map_borderWidth] ? [WXConvert WXPixelType:info[dc_map_borderWidth] scaleFactor:pixelScaleFactor] : 0;
    
    return polyline;
}

+ (DCPolygon *)Polygon:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor{
    
    if (!info[dc_map_points] || ![info[dc_map_points] isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *points = info[dc_map_points];
    CLLocationCoordinate2D linePoints[points.count];
    for (int i = 0; i < points.count; i++) {
        NSDictionary *dic = points[i];
        if (![dic isKindOfClass:[NSDictionary class]]) continue;
        
        if (dic[dc_map_longitude] && dic[dc_map_latitude]) {
            linePoints[i].latitude = [WXConvert CGFloat:dic[dc_map_latitude]];
            linePoints[i].longitude = [WXConvert CGFloat:dic[dc_map_longitude]];
        }
    }
    
    DCPolygon *polygon = [DCPolygon polygonWithCoordinates:linePoints count:points.count];
    polygon.fillColor = info[dc_map_fillColor] ?: nil;
    polygon.strokeWidth = info[dc_map_strokeWidth] ? [WXConvert WXPixelType:info[dc_map_strokeWidth] scaleFactor:pixelScaleFactor] : 0;
    polygon.strokeColor = info[dc_map_strokeColor] ?: nil;
    polygon.zIndex = info[dc_map_zIndex] ? [WXConvert CGFloat:info[dc_map_zIndex]] : 0;
    
    return polygon;
}

+ (DCCircle *)Circle:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor{
    
    if (!info[dc_map_longitude] || !info[dc_map_latitude]) {
        return nil;
    }
    
    double lon = [[info dc_safeObjectForKey:dc_map_longitude] doubleValue];
    double lat = [[info dc_safeObjectForKey:dc_map_latitude] doubleValue];
    double r = info[dc_map_radius] ? [WXConvert CGFloat:info[dc_map_radius]] : 0;
    DCCircle *circle = [DCCircle circleWithCenterCoordinate:[WXConvert CLLocationCoordinate2DLongitude:lon latitude:lat] radius:r];
    circle.strokeWidth = info[dc_map_strokeWidth] ? [WXConvert WXPixelType:info[dc_map_strokeWidth] scaleFactor:pixelScaleFactor] : 0;
    circle.color = info[dc_map_color] ?: nil;
    circle.fillColor = info[dc_map_fillColor] ?: nil;
    
    return circle;
}

+ (DCMapControl *)Control:(NSDictionary *)info pixelScaleFactor:(CGFloat)pixelScaleFactor {
    
    if (!info[dc_map_position] || !info[dc_map_iconPath]) {
        return nil;
    }
    
    DCMapControl *control = [DCMapControl buttonWithType:UIButtonTypeCustom];
    control._id = info[dc_map_id] ? [info[dc_map_id] integerValue] : 0;
    control.iconPath = info[dc_map_iconPath];
    control.clickable = info[@"clickable"] ? [info[@"clickable"] boolValue] : NO;
    DCMapPosition *position = [[DCMapPosition alloc] init];
    control.position = position;
    if ([info[dc_map_position] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *pt = info[dc_map_position];
        position.left = pt[@"left"] ? [WXConvert WXPixelType:pt[@"left"] scaleFactor:pixelScaleFactor] : 0;
        position.top = pt[@"top"] ? [WXConvert WXPixelType:pt[@"top"] scaleFactor:pixelScaleFactor] : 0;
        position.width = pt[@"width"] ? [WXConvert WXPixelType:pt[@"width"] scaleFactor:pixelScaleFactor] : 0;
        position.height = pt[@"height"] ? [WXConvert WXPixelType:pt[@"height"] scaleFactor:pixelScaleFactor] : 0;
    }
    
    return control;
}

@end
