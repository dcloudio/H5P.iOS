/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_gis_overlay.h
 *  Description:
 *      GIS查询覆盖物头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-13  创建文件
 *------------------------------------------------------------------
 */

#import <BaiduMapAPI_Map/BMKMapView.h>
#import <BaiduMapAPI_Search/BMKPoiSearchType.h>
#import <BaiduMapAPI_Search/BMKRouteSearchType.h>
#import <BaiduMapAPI_Search/BMKRouteSearchType.h>
#import <BaiduMapAPI_Map/BMKPolyline.h>
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>
#import "pg_map_overlay.h"

@class PGMapCoordinate;

/*
*@BMKPoiInfo扩充支持js方式
*/
#pragma mark -----------------------------------------------
@interface BMKPoiInfo(JSOject)
-(NSString*)JSObject;
@end

/*
*@该类用于GIS导航后的提示标记
*/
#pragma mark ------------------------------------------------
@interface PGGISMarker : BMKPointAnnotation
@property (nonatomic) BOOL hidden; 
@property (nonatomic) int type;   //标记的类型<0:起点 1：终点 2：公交 3：地铁 4:驾乘
@property (nonatomic) int degree; //标记选择的角度一般用来指示节点行驶的方向
@end

/*
*@gis查询覆盖物基类
*/
#pragma mark ------------------------------------------------
@interface PGGISOverlay :  PGMapOverlayBase
{
}
@property(nonatomic,retain)NSArray *markers;     //路线的关键节点
@property(nonatomic,retain)BMKPolyline *polyline;//路线的轨迹
@property(nonatomic,retain)PGMapCoordinate *startPoint;//起始点
@property(nonatomic,retain)PGMapCoordinate *endPoint;//终点
@property(nonatomic,assign)NSUInteger pointCount; //节点数目
@property(nonatomic,assign)NSUInteger distance;   //路线的长度
@property(nonatomic,retain)NSArray *pointList; //节点坐标数组
@property(nonatomic,retain)NSString *routeTip; //路线的提示

@property(nonatomic, assign)PGMapView *belongMapview; //路线添加到的地图

-(NSString*)JSObject;
- (void)setVisable:(BOOL)visable;
//invoke js method
- (void)showJS:(NSArray*)args;
- (void)hideJS:(NSArray*)args;
@end

/*
*@该类为gis查询后步行和驾车路径
*/
#pragma mark ------------------------------------------------
@interface PGGISRoute :  PGGISOverlay

+(PGGISRoute*)routeWithJSON:(NSMutableDictionary*)jsonObj;
+(PGGISRoute*)routeWithRoute:(BMKDrivingRouteResult*)route;
+(PGGISRoute*)routeWithWalkingRoute:(BMKWalkingRouteResult*)route;
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args;
@end

/*
*@该类为gis查询后公交路径
*/
#pragma mark ------------------------------------------------
@interface PGGISBusline :  PGGISOverlay

+(PGGISBusline*)routeWithMABus:(BMKTransitRouteLine*)bus;

@end


