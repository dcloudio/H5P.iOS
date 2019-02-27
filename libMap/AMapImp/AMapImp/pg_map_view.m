/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map_view.mm
 *  Description:
 *      地图视图实现
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-10  创建文件
 *   Reviewed @ 20130105 by Lin Xinzheng
 *------------------------------------------------------------------
 */

#import "pg_map.h"
#import "pg_map_view.h"
#import "pg_gis_search.h"
#import "pg_gis_overlay.h"
#import "pg_map_marker.h"
#import "pg_map_overlay.h"
#import "PDRToolSystemEx.h"
#import <MapKit/MapKit.h>
#import "H5CoreJavaScriptText.h"

//默认经纬度和缩放值
#define PG_MAP_DEFALUT_ZOOM 12
#define PG_MAP_DEFALUT_CENTER_LONGITUDE 116.403865
#define PG_MAP_DEFALUT_CENTER_LATITUDE 39.915136

@implementation PGAMapKey

+(NSString*)verify {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AMapServices sharedServices] setEnableHTTPS:YES];
        NSString *amapAppkey = nil;
        NSDictionary *amapInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"amap"];
        if ( [amapInfo isKindOfClass:[NSDictionary class]] ) {
            NSString *tempAK = [amapInfo objectForKey:@"appkey"];
            if ( [tempAK isKindOfClass:[NSString class]] ) {
                amapAppkey = tempAK;
            }
        }
        if ( amapAppkey ) {
            [AMapServices sharedServices].apiKey = amapAppkey;
        }
    });
    return [AMapServices sharedServices].apiKey;
}

@end


@implementation PGMAMapView

@synthesize jsBridge;
@synthesize UUID;

-(void)dealloc
{
    self.jsBridge = nil;
    _mapView.showsUserLocation = NO;
    _mapView.delegate = nil;
//    if ( _localService ) {
//        [_localService stopUserLocationService];
//        _localService.delegate = nil;
//        [_localService release];
//    }
    [self removeAllOverlay];
    [_markersDict release];
    [_overlaysDict release];
    [_gisOverlaysDict release];
    [_jsCallbackDict release];

    [super dealloc];
}

- (void)close {
   [self removeFromSuperview];
    _mapView.delegate = nil;
}

/*
 *------------------------------------------------
 *@summay: 创建一个地图控件
 *@param frame CGRect
 *@return PGMapView*
 *------------------------------------------------
 */
- (id)initWithFrame:(CGRect)frame params:(NSDictionary*)setInfo {
    if ( self = [super initWithFrame:frame params:setInfo] ) {
        [PGAMapKey verify];
        _mapView = [[MAMapView alloc] initWithFrame:frame];
        _mapView.delegate = self;
        _mapView.mapType = MAMapTypeStandard;
        _mapView.showsScale = TRUE;
        _mapView.rotateEnabled = NO;
        _mapView.rotateCameraEnabled = NO;
        _mapView.showsCompass = NO;
        _mapView.touchPOIEnabled = NO;
        _mapView.rotationDegree = 0;
        _mapView.runLoopMode = NSDefaultRunLoopMode;
        self.clipsToBounds = YES;
        [self addSubview:_mapView];
        
        CLLocationCoordinate2D center = {PG_MAP_DEFALUT_CENTER_LATITUDE,PG_MAP_DEFALUT_CENTER_LONGITUDE};
        [self setCenterCoordinate:center animated:YES];
        
        PGMapCoordinate *centerCoordinate = [PGMapCoordinate pointWithJSON:[setInfo objectForKey:@"center"]];
        if ( centerCoordinate ) {
            [self setCenterCoordinate:[centerCoordinate point2CLCoordinate]
                             animated:YES];
        }
        _mapView.zoomLevel = [self MapToolFitZoom:[[setInfo objectForKey:@"zoom"] intValue]];
        _mapView.showTraffic = [[setInfo objectForKey:@"traffic"] boolValue];
        BOOL zoomControls = [[setInfo objectForKey:@"zoomControls"] boolValue];
        if ( zoomControls ) {
            [self showZoomControl];
        }
        [self setMapTypeJS:[NSArray arrayWithObject:[setInfo objectForKey:@"type"]]];
        self.positionType = PGMapViewPositionStatic;
        NSString *position = [setInfo objectForKey:@"position"];
        if ( [position isKindOfClass:[NSString class]]
            && NSOrderedSame == [@"absolute" caseInsensitiveCompare:position]) {
            self.positionType = PGMapViewPositionAbsolute;
        }
        
        //        UITapGestureRecognizer *taprecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCallback:)];
        //        taprecognizer.numberOfTouchesRequired = 1;
        //        taprecognizer.numberOfTapsRequired = 1;
        //        taprecognizer.cancelsTouchesInView = NO;
        //       // taprecognizer.delaysTouchesBegan = YES;
        //       // taprecognizer.delaysTouchesEnded = YES;
        //        [self addGestureRecognizer:taprecognizer];
        //        [taprecognizer release];
        return self;
    }
    return nil;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _mapView;
}

- (void)layoutSubviews {
    _mapView.frame = self.bounds;
    [super layoutSubviews];
}
#pragma mark - PGMapViewDelegate
- (int)zoomLevel {
    return _mapView.zoomLevel;
}

- (void)setZoomLevel:(int)zl {
    _mapView.zoomLevel = zl;
}

- (CLLocationCoordinate2D)centerCoordinate {
    return _mapView.centerCoordinate;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    [_mapView setCenterCoordinate:coordinate animated:animated];
}

- (void)setShowsUserLocation:(BOOL)showsUserLocation {
    _mapView.showsUserLocation = YES;
}
- (BOOL)showsUserLocation {
    return _mapView.showsUserLocation;
}

- (CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(UIView *)view {
    return [_mapView convertPoint:point toCoordinateFromView:view];
}

/*
 *------------------------------------------------
 *@summay: 地图点击事件回调
 *@param sender UITapGestureRecognizer*
 *@return 
 *@remark
 *    该函数没有排除覆盖物区域
 *------------------------------------------------
 */
//
//-(void)tapCallback:(UITapGestureRecognizer*)sender
//{
//    CGPoint point = [sender locationInView:self];
//
//    //排除缩放控件区域
//    if ( _zoomControlView
//        && CGRectContainsPoint(_zoomControlView.frame, point))
//        return;
//
//    //排除覆盖物区域
//
//    CLLocationCoordinate2D coordiante = [_mapView convertPoint:point toCoordinateFromView:self];
//    NSString *jsObjectF =
//    @"{\
//        var plus = %@; \
//        var args = new plus.maps.Point(%f,%f);\
//        plus.maps.__bridge__.execCallback('%@', args);\
//      }";
//    NSString *javaScript = [NSString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], coordiante.longitude, coordiante.latitude, self.UUID];
//    [jsBridge asyncWriteJavascript:javaScript];
//}


#pragma mark invoke js method
#pragma mark -----------------------------
/*
 *------------------------------------------------
 *@summay: 设置地图中心缩放级别
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)setMapTypeJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *mapType = [args objectAtIndex:0];
        if ( [mapType isKindOfClass:[NSString class]]  )
        {
            if ( [mapType isEqualToString:@"MAPTYPE_SATELLITE"] )
            {
                if ( MAMapTypeSatellite!= _mapView.mapType )
                    _mapView.mapType = MAMapTypeSatellite;
            }
            else if( [mapType isEqualToString:@"MAPTYPE_NORMAL"] )
            {
                if ( MAMapTypeStandard!= _mapView.mapType )
                    _mapView.mapType = MAMapTypeStandard;
            }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 设置是否显示用户位置蓝点
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)showUserLocationJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSNumber *visable = [args objectAtIndex:0];
//        if ( nil == _localService ) {
//            _localService = [[BMKLocationService alloc] init];
//            _localService.delegate = self;
//            [_localService startUserLocationService];
//        }
        _mapView.showsUserLocation = [visable boolValue];
      //  self.userLocation.title = nil;
    }
}

/*
 *------------------------------------------------
 *@summay: 设置是否显示交通图
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)setTrafficJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSNumber *value = [args objectAtIndex:0];
        if ( value && [value isKindOfClass:[NSNumber class]] )
        {
            if ( [value boolValue] )
            { _mapView.showTraffic = true; }
            else { _mapView.showTraffic = false; }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 添加覆盖物
 *@param sender js pass
 *@return
 *@remark
 *     重置地图只恢复经纬度和zoomlevel
 *------------------------------------------------
 */
- (void)addOverlayJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *overlayUUID = [args objectAtIndex:0];
        if ( overlayUUID && [overlayUUID isKindOfClass:[NSString class]] )
        {
            NSObject *overlay = [self.jsBridge.nativeOjbectDict objectForKey:overlayUUID];
            if ( [overlay isKindOfClass:[PGMapMarker class]] )
            {
                [self addMarker:(PGMapMarker*)overlay];
            }
            else if( [overlay isKindOfClass:[PGMapOverlay class]] )
            {
                [self addMapOverlay:(PGMapOverlay*)overlay];
            }
            else if( [overlay isKindOfClass:[PGGISOverlay class]] )
            {
                [self addGISOverlay:(PGGISOverlay*)overlay];
            }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 移走地图覆盖物
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)removeOverlayJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *overlayUUID = [args objectAtIndex:0];
        if ( overlayUUID && [overlayUUID isKindOfClass:[NSString class]] )
        {
            NSObject *overlay = [self.jsBridge.nativeOjbectDict objectForKey:overlayUUID];
            if ( [overlay isKindOfClass:[PGMapMarker class]] )
            {
                [self removeMarker:(PGMapMarker*)overlay];
            }
            else if( [overlay isKindOfClass:[PGMapOverlay class]] )
            {
                [self removeMapOverlay:(PGMapOverlay*)overlay];
            }
            else if( [overlay isKindOfClass:[PGGISOverlay class]] )
            {
                [self removeGISOverlay:(PGGISOverlay*)overlay];
            }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 移走所有的覆盖
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)clearOverlaysJS:(NSArray*)args
{
    [self removeAllOverlay];
}

/*
 *------------------------------------------------
 *@summay: 重置地图
 *@param sender js pass
 *@return
 *@remark
 *     重置地图只恢复经纬度和zoomlevel
 *------------------------------------------------
 */
- (void)resetJS:(NSArray*)args
{
    CLLocationCoordinate2D center = {PG_MAP_DEFALUT_CENTER_LATITUDE,PG_MAP_DEFALUT_CENTER_LONGITUDE};
    _mapView.zoomLevel = PG_MAP_DEFALUT_ZOOM;
    if ( _zoomControlView )
    { _zoomControlView.value = _mapView.zoomLevel; }
    [_mapView setCenterCoordinate:center animated:NO];
   // self.rotationDegree = 0;
}

- (NSData*)getBoundsJS:(NSArray*)args {
    CLLocationCoordinate2D tl = [_mapView convertPoint:CGPointMake(self.bounds.size.width, 0) toCoordinateFromView:self];
    CLLocationCoordinate2D rb = [_mapView convertPoint:CGPointMake(0, self.bounds.size.height) toCoordinateFromView:self];
    PGMapBounds *bounds = [PGMapBounds boundsWithNorthEase:tl southWest:rb];
    
    return [jsBridge resultWithJSON:[bounds toJSON]];
}
#pragma mark Map tools
#pragma mark -----------------------------
/*
 *------------------------------------------------
 *@summay: 该接口用来添加gis search中获取到的路径
 *@param 
 *       overlay js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)addGISOverlay:(PGGISOverlay*)overlay
{
    if ( !overlay )
        return;
    if ( overlay.belongMapview )
        return;
    
    if ( !_gisOverlaysDict )
        _gisOverlaysDict = [[NSMutableArray alloc] initWithCapacity:10];
    overlay.belongMapview = self;
   // [_overlaysDict setObject:overlay forKey:overlay.UUID ];
    [_gisOverlaysDict addObject:overlay];
    [_mapView addAnnotations:overlay.markers];
    [_mapView addOverlay:overlay.polyline];
}

/*
 *------------------------------------------------
 *@summay: 该接口用来 移除gis search中获取到的路径
 *@param
 *       overlay js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)removeGISOverlay:(PGGISOverlay*)overlay
{
    if ( !overlay )
        return;
    if ( !overlay.belongMapview )
        return;
    
    overlay.belongMapview = nil;
    [_gisOverlaysDict removeObject:overlay];
    // [_overlaysDict setObject:overlay forKey:overlay.UUID ];
    [_mapView removeAnnotations:overlay.markers];
    [_mapView removeOverlay:overlay.polyline];
}

/*
 *------------------------------------------------
 *@summay: 该接口用来添加标记
 *@param
 *       marker js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)addMarker:(PGMapMarker*)marker
{
    if ( !marker )
        return;
    //添加过不在添加
    if ( marker.belongMapview )
        return;
    
    if ( !_markersDict )
        _markersDict = [[NSMutableArray alloc] initWithCapacity:10];
    marker.belongMapview = self;
    [_markersDict addObject:marker];
    [_mapView addAnnotation:(id<MAAnnotation>)marker];
}

/*
 *------------------------------------------------
 *@summay: 移走一个标记
 *@param
 *       marker js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)removeMarker:(PGMapMarker*)marker
{
    if ( !marker )
        return;
    if ( !marker.belongMapview )
        return;
    
    marker.belongMapview = nil;
    [_markersDict removeObject:marker];
    [_mapView removeAnnotation:(id<MAAnnotation>)marker];
}

/*
 *------------------------------------------------
 *@summay: 移走一个标记
 *@param
 *       marker js pass
 *@return
 *@remark
 *
 *------------------------------------------------
 */
- (void)addMapOverlay:(PGMapOverlay*)overlay;
{
    if ( !overlay )
        return;
    if ( !overlay.overlay/* || !overlay.overlayView*/ )
        return;
    //添加过不在添加
    if ( overlay.belongMapview )
        return;
    
    if ( !_overlaysDict )
        _overlaysDict = [[NSMutableArray alloc] initWithCapacity:10];
    overlay.belongMapview = self;
    [_overlaysDict addObject:overlay];
    if ( !overlay.hidden ) {
        [_mapView addOverlay:overlay.overlay];
    }
}

- (void)setMapOverlay:(PGMapOverlay*)overlay isVisable:(BOOL)visable {
    if ( visable ) {
        [_mapView addOverlay:overlay.overlay];
    } else {
        [_mapView removeOverlay:overlay.overlay];
    }
}

/*
 *------------------------------------------------
 *@summay: 移走一个标记
 *@param
 *       marker js pass
 *@return
 *@remark
 *
 *------------------------------------------------
 */
- (void)removeMapOverlay:(PGMapOverlay*)overlay
{
    if ( !overlay || !overlay.overlay  )
        return;
    if ( !overlay.belongMapview )
        return;
    [_mapView removeOverlay:overlay.overlay];
    [_overlaysDict removeObject:overlay];
    overlay.belongMapview = nil;
}

- (MAOverlayRenderer *)viewForOverlay:(PGMapOverlay*)overlay {
    if ( !overlay || !overlay.overlay  )
        return nil;
    if ( !overlay.belongMapview )
        return nil;
    return [_mapView rendererForOverlay:overlay.overlay];
}

/*------------------------------------------------
 *@summay: 移走所有的标记
 *@param
 *       marker js pass
 *@return
 *@remark
 *
 *------------------------------------------------
 */
- (void)removeAllOverlay
{
    for (PGMapMarker *marker in _markersDict )
    {
        [_mapView removeAnnotation:marker];
    }
    
    for ( PGMapOverlay *pdlOvlery in _overlaysDict)
    {
        if ( pdlOvlery && pdlOvlery.overlay  )
        {
            pdlOvlery.belongMapview = nil;
            [_mapView removeOverlay:pdlOvlery.overlay];
        }
    }
    
    for ( PGGISOverlay *gisOverlay in _gisOverlaysDict )
    {
        gisOverlay.belongMapview = nil;
        [_mapView removeAnnotations:gisOverlay.markers];
        [_mapView removeOverlay:gisOverlay.polyline];
    }
    
    [_markersDict removeAllObjects];
    [_overlaysDict removeAllObjects];
    [_gisOverlaysDict removeAllObjects];
}

/*
- (NSString*)getPDLBundle:(NSString *)filename
{
#define MYBUNDLE_NAME @ "pdlmap.bundle"
#define MYBUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: MYBUNDLE_NAME]
#define MYBUNDLE [NSBundle bundleWithPath: MYBUNDLE_PATH]
	NSBundle * libBundle = MYBUNDLE ;
	if ( libBundle && filename )
    {
		NSString * s=[[libBundle resourcePath ] stringByAppendingPathComponent : filename];
		return s;
	}
	return nil ;
}
*/

/*------------------------------------------------
 *@summay: 生成gis 路线中标记点展现视图
 *@param
 *       mapview 地图实例
 *       routeAnnotation
 *@return
 *       MAAnnotationView*
 *@remark
 *
 *------------------------------------------------
 */
#pragma mark Map tools
#pragma mark -----------------------------
//- (void)mapView:(BMKMapView *)mapView onClickedMapBlank:(CLLocationCoordinate2D)coordinate {
//    NSString *jsObjectF =
//    @"var args = new plus.maps.Point(%f,%f);\
//    window.plus.maps.__bridge__.execCallback('%@', args);";
//    NSString *javaScript = [NSString stringWithFormat:jsObjectF, coordinate.longitude, coordinate.latitude, self.UUID];
//    [jsBridge asyncWriteJavascript:javaScript];
//}

- (MAAnnotationView*)getRouteAnnotationView:(MAMapView *)mapview viewForAnnotation:(PGGISMarker*)routeAnnotation
{
	MAAnnotationView* view = nil;
	switch (routeAnnotation.type) {
		case 0:
		{
			view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"start_node"];
			if (view == nil) {
				view = [[[MAAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"] autorelease];
				view.image = [UIImage imageNamed:@"AMap.bundle/images/icon_nav_start"];
				view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
				view.canShowCallout = TRUE;
			}
			view.annotation = routeAnnotation;
		}
			break;
		case 1:
		{
			view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
			if (view == nil) {
				view = [[[MAAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"] autorelease];
				view.image = [UIImage imageNamed:@"AMap.bundle/images/icon_nav_end"];
				view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
				view.canShowCallout = TRUE;
			}
			view.annotation = routeAnnotation;
		}
			break;
		case 2:
		{
			view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"bus_node"];
			if (view == nil) {
				view = [[[MAAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"bus_node"] autorelease];
				view.image = [UIImage imageNamed:@"AMap.bundle/images/icon_nav_bus"];
				view.canShowCallout = TRUE;
			}
			view.annotation = routeAnnotation;
		}
			break;
		case 3:
		{
			view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"rail_node"];
			if (view == nil) {
				view = [[[MAAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"rail_node"] autorelease];
				view.image = [UIImage imageNamed:@"AMap.bundle/images/icon_nav_rail"];
				view.canShowCallout = TRUE;
			}
			view.annotation = routeAnnotation;
		}
			break;
		case 4:
		{
			view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
			if (view == nil) {
				view = [[[MAAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"]autorelease];
				view.canShowCallout = TRUE;
			} else {
				[view setNeedsDisplay];
			}
			
			UIImage* image = [UIImage imageNamed:@"AMap.bundle/images/icon_direction"];
			view.image = [image imageRotatedByDegrees:routeAnnotation.degree supportRetina:YES scale:1.0f];
			view.annotation = routeAnnotation;
			
		}
			break;
		default:
			break;
	}
	
	return view;
}

/*
 *------------------------------------------------
 *根据anntation生成对应的View
 *@param mapView 地图View
 *@param annotation 指定的标注
 *@return 生成的标注View
 *------------------------------------------------
 */
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation
{
    if ( [annotation isKindOfClass:[PGGISMarker class]] )
    {
        PGGISMarker *marker = (PGGISMarker*)annotation;
        MAAnnotationView *view = [self getRouteAnnotationView:mapView viewForAnnotation:annotation];
        view.hidden = marker.hidden;
        return view;
    }
    else if ( [annotation isMemberOfClass:[PGMapMarker class]] )
    {
        PGMapMarker *marker = (PGMapMarker*)annotation;
        NSString *reusableIdentifier = @"io_dcloud_map_markerView";
        PGMapMarkerView *pinAnnView = (PGMapMarkerView*)[mapView dequeueReusableAnnotationViewWithIdentifier:reusableIdentifier];
        if ( nil == pinAnnView ) {
            pinAnnView = [[[PGMapMarkerView alloc]initWithAnnotation:marker reuseIdentifier:reusableIdentifier] autorelease];
            pinAnnView.annotation = annotation;
        } else {
            pinAnnView.annotation = annotation;
        }
        pinAnnView.canShowCallout = NO;
        pinAnnView.draggable = marker.canDraggable;
        [pinAnnView setDragState:MAAnnotationViewDragStateNone];
        pinAnnView.hidden = marker.hidden;
      //  pinAnnView.selected = marker.bubblePop;
        //[pinAnnView setSelected:YES];
        //pinAnnView.enabled = !marker.hidden;
        [pinAnnView reload];
        if ( marker.selected ) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [mapView selectAnnotation:marker animated:NO];
            });
        }
        return pinAnnView;
    }
    return nil;
}

/*
 *------------------------------------------------
 *根据overlay生成对应的View
 *@param mapView 地图View
 *@param overlay 指定的overlay
 *@return 生成的覆盖物View
 *------------------------------------------------
 */
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    //if ( [overlay isKindOfClass:[PGMapOverlay class]] )
    {
        for ( PGMapOverlay *pdlOverlay in _overlaysDict)
        {
            if ( pdlOverlay.overlay == overlay ){
                //return pdlOverlay.overlayView;
                MAOverlayPathRenderer *pathView = nil;
                if ( [pdlOverlay isKindOfClass:[PGMapCircle class]] ) {
                    pathView = [[[MACircleRenderer alloc]initWithCircle:overlay] autorelease];
                } else if ( [pdlOverlay isKindOfClass:[PGMapPolyline class]]){
                    pathView = [[[MAPolylineRenderer alloc] initWithPolyline:overlay] autorelease];
                } else if ( [pdlOverlay isKindOfClass:[PGMapPolygon class]]){
                    pathView = [[[MAPolygonRenderer alloc] initWithPolygon:overlay] autorelease];
                }
                pathView.fillColor = pdlOverlay.fillColor;
                pathView.strokeColor = pdlOverlay.strokeColor;
                pathView.lineWidth = pdlOverlay.lineWidth;
                return pathView;
            }
        }
    }
    
    
    
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer* polylineView = [[[MAPolylineRenderer alloc] initWithPolyline:overlay] autorelease];
        polylineView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:1];
        polylineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:1];
        polylineView.lineWidth = 4.0;
        return polylineView;
    }
    return nil;
}

/*
 *------------------------------------------------
 *当选中一个annotation views时，调用此接口
 *@param mapView 地图View
 *@param views 选中的annotation views
 *------------------------------------------------
 */
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    id<MAAnnotation> annotation = view.annotation;
    if ( annotation && [annotation isKindOfClass:[PGMapMarker class]] )
    {
        PGMapMarker *marker = (PGMapMarker*)annotation;
        marker.selected = YES;
//        NSString * jsObjectF = @"var args = {type:'markerclick'};\
//        window.plus.maps.__bridge__.execCallback('%@', args);";
//        NSString *javaScript = [NSString stringWithFormat:jsObjectF, marker.UUID];
//        [jsBridge asyncWriteJavascript:javaScript];
    }
}

- (void)mapView:(MAMapView *)mapView didDeselectAnnotationView:(MAAnnotationView *)view
{
    id<MAAnnotation> annotation = view.annotation;
    if ( annotation && [annotation isKindOfClass:[PGMapMarker class]] )
    {
        PGMapMarker *marker = (PGMapMarker*)annotation;
        marker.selected = NO;
       // [markerView showBubble:NO animated:NO];
    }
}

- (void)mapView:(MAMapView *)mapView didAnnotationViewTapped:(MAAnnotationView *)view {
    if ( [view isKindOfClass:[PGMapMarkerView class]] ) {
        PGMapMarkerView *markerView = (PGMapMarkerView*)view;
        [markerView doClickForEvt];
    }
}

/*
 *------------------------------------------------
 *用户位置更新后，会调用此函数
 *@param mapView 地图View
 *@param userLocation 新的用户位置
 *------------------------------------------------
 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    PGMapUserLocation *mkUserLocation = [[[PGMapUserLocation alloc] init] autorelease];
    mkUserLocation.location = userLocation.location;
    [super mapView:self didUpdateUserLocation:mkUserLocation updatingLocation:updatingLocation];
}
/*
 *------------------------------------------------
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 *------------------------------------------------
 */
- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error;
{
    [super mapView:self didFailToLocateUserWithError:error];
}

/*
 *------------------------------------------------
 *地图区域改变完成后会调用此接口
 *@param mapview 地图View
 *@param animated 是否动画
 *------------------------------------------------
 */
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self mapViewRegionDidChange:self];
}

#pragma mark static method
#pragma mark -----------------------------
- (void)mapView:(MAMapView *)mapView didSingleTappedAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [self mapView:self onClicked:coordinate];
//    NSString *jsObjectF =
//    @"{var plus = %@;var args = new plus.maps.Point(%f,%f);\
//    plus.maps.__bridge__.execCallback('%@', {callbackType:'click',payload:args});}";
//    NSString *javaScript = [NSString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], coordinate.longitude, coordinate.latitude, self.UUID];
//    [jsBridge asyncWriteJavascript:javaScript];
}

//- (void)mapView:(MAMapView *)mapView didTouchPois:(NSArray *)pois{
//    CLLocationCoordinate2D coordiante = {0, 0};
//    
//    if ( [pois count] > 0 ) {
//      //  MATouchPoi *poi = [pois objectAtIndex:0];
//      //  coordiante = poi.coordinate;
//    }
//    NSString *jsObjectF =
//    @"var args = new plus.maps.Point(%f,%f);\
//    window.plus.maps.__bridge__.execCallback('%@', args);";
//    NSString *javaScript = [NSString stringWithFormat:jsObjectF, coordiante.longitude, coordiante.latitude, self.UUID];
//    [jsBridge asyncWriteJavascript:javaScript];
//}

@end
