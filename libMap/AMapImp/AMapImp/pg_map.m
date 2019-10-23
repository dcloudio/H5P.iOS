/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map.m
 *  Description:
 *      地图插件实现文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2012-12-07 创建文件
 *   Reviewed @ 20130105 by Lin Xinzheng
 *------------------------------------------------------------------
 */

#import "PGMethod.h"
#import "pg_map.h"
#import "pg_map_view.h"
#import "pg_map_marker.h"
#import "pg_map_overlay.h"
#import "pg_gis_overlay.h"
#import "pg_gis_search.h"
#import "PGObject.h"
#import "PDRCoreAppFrame.h"

#import <Mapkit/MKGeometry.h>

@implementation PGMap

- (PGPlugin*) initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp*)app {
    self = [super initWithWebView:theWebView withAppContxt:app];
    if (self) {
        self.content = @"高德地图";
        self.sdkErrorURL = @"http://lbs.amap.com/api/ios-sdk/guide/map-tool/errorcode/";
    }
    return self;
}
- (void)dealloc
{
    [_geocodeReqs removeAllObjects];
    [_geocodeReqs release];
    _geocodeReqs = nil;
    [_codeSearch release];
    
    [super dealloc];
}
-(PGMapView*)createMapViewWithArgs:(id)args {
    return [[[PGMAMapView alloc] initViewWithArray:args] autorelease];
}

- (void)onAppFrameWillClose:(PDRCoreAppFrame *)theAppframe {
    [super onAppFrameWillClose:theAppframe];
    NSMutableArray *removeMapKeys = [NSMutableArray array];
    [_nativeObjectDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, PGMapMarker * _Nonnull marker, BOOL * _Nonnull stop) {
        if ( [marker isKindOfClass:[PGMapMarker class]] ) {
            if ( [marker.createWebviewId isEqualToString:theAppframe.frameID] && nil == marker.belongMapview) {
                [removeMapKeys addObject:key];
            }
        }
    }];
    [_nativeObjectDict removeObjectsForKeys:removeMapKeys];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      创建js native对象
 * @Parameters:
 *    [1] command, js调用格式应该为 [uuid, type, [args]]
 * @Returns:
 *    无
 * @Remark:
 *   
 * @Changelog:
 *------------------------------------------------------------------
 */
- (id)createOverlayWithUUID:(NSString*)UUID withType:(NSString*)type args:(id)args inWebview:(NSString*)webviewId{
    if ( [type isEqualToString:@"marker"] )
    {
        //NSString *baseURL = [self writeJavascript:@"window.location.href" ];
        PGMapMarker *mapMarker = [PGMapMarker markerWithArray:args baseURL:self.JSFrameContext.baseURL];
        mapMarker.UUID = UUID;
        mapMarker.belongWebview = webviewId;
        mapMarker.createWebviewId = webviewId;
        return mapMarker;
    }
    else if ( [type isEqualToString:@"circle"] )
    {
        PGMapCircle *circle = [[PGMapCircle alloc] initWithUUID:UUID args:args];
        return [circle autorelease];
    }
    else if ( [type isEqualToString:@"polygon"] )
    {
        PGMapPolygon *polygon = [[PGMapPolygon alloc] initWithUUID:UUID args:args];
        return [polygon autorelease];
    }
    else if ( [type isEqualToString:@"polyline"] )
    {
        PGMapPolyline *polyline = [[PGMapPolyline alloc] initWithUUID:UUID args:args];
        return [polyline autorelease];
    }
    else if ( [type isEqualToString:@"route"] )
    {
        PGGISRoute* gisRoute = [[PGGISRoute alloc]initWithUUID:UUID args:args];
        return gisRoute;
    }
    else if ( [type isEqualToString:@"search"] )
    {
        PGGISSearch *search = [[PGGISSearch alloc] initWithUUID:UUID];
        search.jsBridge = self;
        return [search autorelease];
    }
    return nil;
}

- (void)calculateDistance:(PGMethod*)command {
    NSString *callbackId = [command getArgumentAtIndex:2];
    PGMapCoordinate *start = [PGMapCoordinate pointWithJSON:[command getArgumentAtIndex:0]];
    PGMapCoordinate *end = [PGMapCoordinate pointWithJSON:[command getArgumentAtIndex:1]];
    if ( start && end ) {
        CLLocationDistance distance = MKMetersBetweenMapPoints( MKMapPointForCoordinate([start point2CLCoordinate]),
                                                                MKMapPointForCoordinate([end point2CLCoordinate]));
        [self toSucessCallback:callbackId withDouble:distance];
        return;
    }
    [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
}

- (void)calculateArea:(PGMethod*)command {
    NSString *callbackId = [command getArgumentAtIndex:1];
    [self toErrorCallback:callbackId withCode:PGPluginErrorNotSupport];
}

- (void)convertCoordinates:(PGMethod*)command {
    NSString *callbackId = [command getArgumentAtIndex:2];
    [self toErrorCallback:callbackId withCode:PGPluginErrorNotSupport];
}

- (void)geocode:(PGMethod*)command {
    NSString *address = [PGPluginParamHelper getStringValue:[command getArgumentAtIndex:0]];
    NSDictionary *options = [command getArgumentAtIndex:1];
    NSString *callbackId = [command getArgumentAtIndex:2];
    NSString *city = nil;
    
    if ( !address || 0 == [address length]) {
        [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
        return;
    }
    
    if ( [options isKindOfClass:[NSDictionary class]] ) {
        city = [PGPluginParamHelper getStringValue:[options objectForKey:@"city"]];
    }
    
    PGMapGeoReq *req = [[[PGMapGeoReq alloc] init] autorelease];
    req.city = city;
    req.callbackId = callbackId;
    req.address = address;
    req.reqType = PGMapReqTypeGeocode;
    
    if ( !_geocodeReqs ) {
        _geocodeReqs = [[NSMutableArray alloc] init];
    }
    [_geocodeReqs addObject:req];
    
    [self geoReq];
}

- (void)reverseGeocode:(PGMethod*)command {
    NSDictionary *point = [command getArgumentAtIndex:0];
    NSDictionary *options = [command getArgumentAtIndex:1];
    NSString *callbackId = [command getArgumentAtIndex:2];
    CLLocationCoordinate2D coorinate2D;
    
    PGMapCoordinate *cooinate = [PGMapCoordinate pointWithJSON:point];
    if ( !cooinate ) {
        [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
        return;
    }
    coorinate2D = [cooinate point2CLCoordinate];
    if ( [options isKindOfClass:[NSDictionary class]] ) {
        NSString *coordType = [PGPluginParamHelper getStringValue:[options objectForKey:@"coordType"] defalut:@"gcj02"];
        if ( NSOrderedSame == [@"gcj02" caseInsensitiveCompare:coordType]) {
        } else {
            [self toErrorCallback:callbackId withCode:PGPluginErrorNotSupport];
            return;
        }
    }
    
    PGMapGeoReq *req = [[[PGMapGeoReq alloc] init] autorelease];
    req.coordinate2D = coorinate2D;
    req.callbackId = callbackId;
    req.reqType = PGMapReqTypeReverseGeocode;
    
    if ( !_geocodeReqs ) {
        _geocodeReqs = [[NSMutableArray alloc] init];
    }
    [_geocodeReqs addObject:req];
    [self geoReq];
}

- (void)geoReq {
    if ( _codeSearchRuning ) {
        return;
    }
    
    if ( 0 == [_geocodeReqs count] ) {
        _codeSearch.delegate = nil;
        [_codeSearch release];
        _codeSearch = nil;
        return;
    }
    PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
    
    if ( !_codeSearch ) {
        [PGAMapKey verify];
        _codeSearch = [[AMapSearchAPI alloc] init];
        _codeSearch.delegate = self;
    }
    
    if ( PGMapReqTypeGeocode == req.reqType  ) {
        AMapGeocodeSearchRequest *option = [[[AMapGeocodeSearchRequest alloc] init] autorelease];
      //  option.searchType = AMapSearchType_Geocode;
        option.city = req.city;
        option.address = req.address;
        [_codeSearch AMapGeocodeSearch:option];
    } else {
        AMapReGeocodeSearchRequest *option = [[[AMapReGeocodeSearchRequest alloc] init] autorelease];
     //   option.searchType = AMapSearchType_ReGeocode;
        option.location = [AMapGeoPoint locationWithLatitude:req.coordinate2D.latitude longitude:req.coordinate2D.longitude];//req.coordinate2D;
        [_codeSearch AMapReGoecodeSearch:option];
    }
    _codeSearchRuning = TRUE;
}
/*
- (void)searchRequest:(id)request didFailWithError:(NSError *)error {
    if ( [_geocodeReqs count] ) {
        PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
        [self toErrorCallback:req.callbackId withSDKError:(int)error.code withMessage:[error localizedDescription]];
     //   [self toErrorCallback:req.callbackId withCode:PGPluginErrorUnknown];
        [_geocodeReqs removeObjectAtIndex:0];
    }
    _codeSearchRuning = false;
    [self performSelector:@selector(geoReq) withObject:nil afterDelay:0];
}*/
/*!
 @brief 地理编码查询回调函数
 @param request 发起查询的查询选项(具体字段参考AMapGeocodeSearchRequest类中的定义)
 @param response 查询结果(具体字段参考AMapGeocodeSearchResponse类中的定义)
 */
- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response {
    if ( [_geocodeReqs count] ) {
        PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
        if ( 0 == response.count ) {
            [self toErrorCallback:req.callbackId withCode:PGPluginErrorUnknown];
          //  [self toErrorCallback:req.callbackId withSDKError:AMapSearchErrorUnknown withMessage:nil];
        } else {
            AMapGeocode *gecode = [response.geocodes objectAtIndex:0];
            [self toSucessCallback:req.callbackId withJSON:@{@"long":@(gecode.location.longitude),
                                                             @"lat":@(gecode.location.latitude),
                                                             @"addr":gecode.formattedAddress,
                                                             @"type":@"gcj02"}];
        }
        [_geocodeReqs removeObjectAtIndex:0];

    }
    _codeSearchRuning = false;
    [self performSelector:@selector(geoReq) withObject:nil afterDelay:0];
}

/*!
 @brief 逆地理编码查询回调函数
 @param request 发起查询的查询选项(具体字段参考AMapReGeocodeSearchRequest类中的定义)
 @param response 查询结果(具体字段参考AMapReGeocodeSearchResponse类中的定义)
 */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    if ( [_geocodeReqs count] ) {
        PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
        if ( response.regeocode ) {
            [self toSucessCallback:req.callbackId withJSON:@{@"long":@(response.regeocode.addressComponent.streetNumber.location.longitude),
                                                             @"lat":@(response.regeocode.addressComponent.streetNumber.location.latitude),
                                                             @"addr":response.regeocode.formattedAddress,
                                                             @"type":@"gcj02"}];
        } else {
            //[self toErrorCallback:req.callbackId withSDKError:AMapSearchErrorUnknown withMessage:nil];
            [self toErrorCallback:req.callbackId withCode:PGPluginErrorUnknown];
        }
        [_geocodeReqs removeObjectAtIndex:0];
    }
    _codeSearchRuning = false;
    [self performSelector:@selector(geoReq) withObject:nil afterDelay:0];
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    if ( [request isKindOfClass:[AMapReGeocodeSearchRequest class]]
        || [request isKindOfClass:[AMapGeocodeSearchRequest class]]) {
        
        if ( [_geocodeReqs count] ) {
            PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
            [self toErrorCallback:req.callbackId withSDKError:(int)error.code withMessage:[error localizedDescription]];
            //   [self toErrorCallback:req.callbackId withCode:PGPluginErrorUnknown];
            [_geocodeReqs removeObjectAtIndex:0];
        }
        _codeSearchRuning = false;
        [self performSelector:@selector(geoReq) withObject:nil afterDelay:0];
    }
}

@end
