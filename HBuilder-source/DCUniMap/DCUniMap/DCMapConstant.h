//
//  DCMapConstant.h
//  libWeexMap
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#define k_dcmap_ArrorHeight        10
#define k_dcmap_DefMargin           1

#define k_dcmap_CalloutDefTitleFontsize 14.0
#define k_dcmap_CalloutMinWidth 50
#define k_dcmap_CalloutMinHeight 50
#define k_dcmap_CalloutMaxWidth [UIScreen mainScreen].bounds.size.width

// 属性
extern NSString *const dc_map_longitude;
extern NSString *const dc_map_latitude;
extern NSString *const dc_map_scale;
extern NSString *const dc_map_showlocation;
extern NSString *const dc_map_enable3D;
extern NSString *const dc_map_showCompass;
extern NSString *const dc_map_showScale;
extern NSString *const dc_map_enableOverlooking;
extern NSString *const dc_map_enableZoom;
extern NSString *const dc_map_enableScroll;
extern NSString *const dc_map_enableRotate;
extern NSString *const dc_map_enableSatellite;
extern NSString *const dc_map_enableTraffic;
extern NSString *const dc_map_markers;
extern NSString *const dc_map_id;
extern NSString *const dc_map_title;
extern NSString *const dc_map_zIndex;
extern NSString *const dc_map_iconPath;
extern NSString *const dc_map_alpha;
extern NSString *const dc_map_rotate;
extern NSString *const dc_map_skew;
extern NSString *const dc_map_anchor;
extern NSString *const dc_map_callout;
extern NSString *const dc_map_content;
extern NSString *const dc_map_color;
extern NSString *const dc_map_fontSize;
extern NSString *const dc_map_borderRadius;
extern NSString *const dc_map_borderWidth;
extern NSString *const dc_map_borderColor;
extern NSString *const dc_map_bgColor;
extern NSString *const dc_map_padding;
extern NSString *const dc_map_display;
extern NSString *const dc_map_textAlign;
extern NSString *const dc_map_BYCLICK;
extern NSString *const dc_map_ALWAYS;
extern NSString *const dc_map_width;
extern NSString *const dc_map_height;
extern NSString *const dc_map_polyline;
extern NSString *const dc_map_points;
extern NSString *const dc_map_dottedLine;
extern NSString *const dc_map_arrowLine;
extern NSString *const dc_map_strokeWidth;
extern NSString *const dc_map_strokeColor;
extern NSString *const dc_map_fillColor;
extern NSString *const dc_map_polygons;
extern NSString *const dc_map_circles;
extern NSString *const dc_map_controls;
extern NSString *const dc_map_position;
extern NSString *const dc_map_radius;
extern NSString *const dc_map_includePoints;
extern NSString *const dc_map_setting;
extern NSString *const dc_map_padding;
extern NSString *const dc_map_markerId;
extern NSString *const dc_map_destination;
extern NSString *const dc_map_autoRotate;
extern NSString *const dc_map_duration;
extern NSString *const dc_map_animationEnd;
extern NSString *const dc_map_address;
extern NSString *const dc_map_errorMsg;

// Events
extern NSString *const dc_map_bindtap;
extern NSString *const dc_map_bindmarkertap;
extern NSString *const dc_map_bindcontroltap;
extern NSString *const dc_map_bindcallouttap;
extern NSString *const dc_map_bindupdated;
extern NSString *const dc_map_bindregionchange;
extern NSString *const dc_map_bindpoitap;
extern NSString *const dc_map_bindlabeltap;
extern NSString *const dc_map_binduserlocationchange;

NS_ASSUME_NONNULL_BEGIN

@interface DCMapConstant : NSObject
@end

NS_ASSUME_NONNULL_END
