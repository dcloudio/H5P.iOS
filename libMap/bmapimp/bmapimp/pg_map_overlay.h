/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map_overlay.h
 *  Description:
 *      地图覆盖物头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-10  创建文件
 *------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Base/BMKTypes.h>
#import <BaiduMapAPI_Map/BMKOverlayGLBasicView.h>
@class PGMapView;
@class PGMapCoordinate;

@interface PGMapOverlayBase : NSObject

@property(nonatomic, assign)PGMapView *belongMapview;
@property(nonatomic, assign)BOOL hidden;
@property(nonatomic, retain)NSString *UUID;

@end

/*
*@PGMapOverlay 用于作为其它覆盖物的基类
*/
@interface PGMapOverlay : PGMapOverlayBase

@property(nonatomic, retain)UIColor* fillColor;
@property(nonatomic, assign)CGFloat fillOpacity;
@property(nonatomic, retain)UIColor* strokeColor;
@property(nonatomic, assign)CGFloat strokeOpacity;
@property(nonatomic, assign)CGFloat lineWidth;

@property(nonatomic, retain)id<BMKOverlay> overlay;
@property(nonatomic, retain)BMKOverlayGLBasicView* overlayView;

//同步js和native属性
//js invoke method
- (BOOL)setFillColorJS:(NSArray*)args;
- (BOOL)setFillOpacityJS:(NSArray*)args;
- (BOOL)setStrokeColorJS:(NSArray*)args;
- (BOOL)setStrokeOpacityJS:(NSArray*)args;
- (BOOL)setLineWidthJS:(NSArray*)args;
- (BOOL)showJS:(NSArray*)args;
- (BOOL)hideJS:(NSArray*)args;

@end

/*
*@Circle对象用于在地图上显示的圆圈，从PGMapOverlay对象继承而来
*/
@interface PGMapCircle : PGMapOverlay
{
}

@property(nonatomic, retain)PGMapCoordinate* center;
@property(nonatomic, assign)CLLocationDistance radius;

//从json数据创建native对象
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args;
+(PGMapCircle*)circleWithJSON:(NSMutableDictionary*)jsonObj;
//invoke js method
-(BOOL)setCenterJS:(NSArray*)args;
-(BOOL)setRadiusJS:(NSArray*)args;
@end

/*
*@PGMapPolygon对象用于在地图上显示的多边形，
** 从PGMapOverlay对象继承而来
*/
@interface PGMapPolygon : PGMapOverlay
{
}
//从json数据创建native对象
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args;
+(PGMapPolygon*)polygonWithJSON:(NSMutableDictionary*)jsonObj;
//invoke js method
- (BOOL)setPathJS:(NSArray*)args;
@end

/*
*@PGMapPolyline对象用于在地图上显示的折线，
** 从PGMapOverlay对象继承而来
*/
@interface PGMapPolyline : PGMapOverlay
{
}
//从json数据创建native对象
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args;
+(PGMapPolyline*)polylineWithJSON:(NSMutableDictionary*)jsonObj;
//invoke js method
- (BOOL)setPathJS:(NSArray*)args;
@end