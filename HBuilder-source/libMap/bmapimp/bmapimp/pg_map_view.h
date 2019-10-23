/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map_view.h
 *  Description:
 *      地图视图头文件定义
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
#import <BaiduMapAPI_Map/BMKMapView.h>
#import <BaiduMapAPI_Map/BMKPolygonView.h>
#import <BaiduMapAPI_Location/BMKLocationService.h>
#import "PGMapView.h"

@class PGMap;
@class PGMapMarker;
@class PGGISOverlay;
@class PGMapOverlay;

@interface PGBaiduMapView : PGMapView<BMKMapViewDelegate,BMKLocationServiceDelegate, PGMapViewDelegte>
{
    BMKMapView *_BMKMapView;
    NSMutableArray *_markersDict;
    NSMutableArray *_overlaysDict;
    NSMutableArray *_gisOverlaysDict;
    NSMutableArray *_jsCallbackDict;
  //  BMKLocationService *_localService;
}

@property(nonatomic, readonly)BMKMapView* mapView;
//@property(nonatomic, assign)int zoom;

//invoke js method
- (id)initWithFrame:(CGRect)frame params:(NSDictionary*)setInfo;
- (void)setMapTypeJS:(NSArray*)args;
- (void)showUserLocationJS:(NSArray*)args;
- (void)resetJS:(NSArray*)args;
- (void)setTrafficJS:(NSArray*)args;

- (void)addOverlayJS:(NSArray*)args;
- (void)removeOverlayJS:(NSArray*)args;
- (void)clearOverlaysJS:(NSArray*)args;

- (NSData*)getBoundsJS:(NSArray*)args;
- (void)close;
//native
- (void)hideZoomControl;
- (void)resizeZoomControl;
- (void)showZoomControl;
//自定义标记管理
- (void)addMarker:(PGMapMarker*)marker;
- (void)removeMarker:(PGMapMarker*)marker;

- (void)addGISOverlay:(PGGISOverlay*)overlay;
- (void)removeGISOverlay:(PGGISOverlay*)overlay;

- (void)addMapOverlay:(PGMapOverlay*)overlay;
- (void)removeMapOverlay:(PGMapOverlay*)overlay;

- (void)removeAllOverlay;
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation;
@end
