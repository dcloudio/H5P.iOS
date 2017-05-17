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
#import "PDRCoreAppFramePrivate.h"

#import <Mapkit/MKGeometry.h>

@implementation PGMapGeoReq
@synthesize reqType;
@synthesize city;
@synthesize address;
@synthesize coordinate2D;
@synthesize callbackId;

- (void)dealloc {
    self.callbackId = nil;
    self.address = nil;
    self.city = nil;
    [super dealloc];
}

@end



@implementation PGMap

@synthesize nativeOjbectDict = _nativeObjectDict;
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
    NSArray *allViews = [_nativeObjectDict allValues];
    for ( PGMapView *target in allViews ) {
        if ( [target isKindOfClass:[PGMapView class]] ) {
            [target close];
        }
    }
    [_nativeObjectDict release];
    
    [_geocodeReqs removeAllObjects];
    [_geocodeReqs release];
    _geocodeReqs = nil;
    [_codeSearch release];
    
    [super dealloc];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      js执行native类方法
 * @Parameters:
 *       [1] command, js传入格式应该为 [uuid, [args]]
 * @Returns:
 *      BOOL 是否执行成功
 * @Remark:
 *    该方法会自动调用各自对象的execMethod
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)execMethod:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return; }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        if ( [UUID isEqualToString:@"map"] )
        {
            NSArray *args = [command.arguments objectAtIndex:1];
            if ( args )
            {
                [PGMapView openSysMap:[args objectAtIndex:1]];
            }
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      js执行native对象方法
 * @Parameters:
 *       [1] command, js传入格式应该为 [uuid, [args]]
 * @Returns:
 *      BOOL 是否执行成功
 * @Remark:
 *    该方法会自动调用各自对象的updateobject
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)updateObject:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return; }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        NSObject *object = [_nativeObjectDict objectForKey:UUID];
        if ( [object isKindOfClass:[PGMapMarker class]] )
        {
            [object updateObject:(NSArray*)[command.arguments objectAtIndex:1]];
        }
        else if ( [object respondsToSelector:@selector(updateObject:) ] )
        {
            [object updateObject:(NSArray*)[command.arguments objectAtIndex:1]];
        }
    }
}

- (NSData*)updateObjectSYNC:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return nil; }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        NSObject *object = [_nativeObjectDict objectForKey:UUID];
        if ( [object isKindOfClass:[PGMapMarker class]] )
        {
            return [object updateObjectSync:(NSArray*)[command.arguments objectAtIndex:1]];
        }
        else if ( [object respondsToSelector:@selector(updateObject:) ] )
        {
            return [object updateObjectSync:(NSArray*)[command.arguments objectAtIndex:1]];
        }
    }
    return nil;
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
- (void)createObject:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return; }

    NSString *UUID = [command.arguments objectAtIndex:0];
    
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        if ( !_nativeObjectDict )
        { _nativeObjectDict = [[NSMutableDictionary alloc] initWithCapacity:10]; }
        NSString *type = [command.arguments objectAtIndex:1];
        if ( type && [type isKindOfClass:[NSString class]] )
        {
            //如果创建过就不在创建
            if ( [_nativeObjectDict objectForKey:UUID] )
            { return; }
            
            if ( [type isEqualToString:@"marker"] )
            {
                //NSString *baseURL = [self writeJavascript:@"window.location.href" ];
                PGMapMarker *mapMarker = [PGMapMarker markerWithArray:[command.arguments objectAtIndex:2] baseURL:self.JSFrameContext.baseURL];
                mapMarker.UUID = UUID;
                if ( mapMarker )
                {
                    [_nativeObjectDict setObject:mapMarker forKey:mapMarker.UUID];
                }
            }
            else if ( [type isEqualToString:@"circle"] )
            {
                PGMapCircle *circle = [[PGMapCircle alloc] initWithUUID:UUID args:[command.arguments objectAtIndex:2]];
                if ( circle )
                {
                    [_nativeObjectDict setObject:circle forKey:circle.UUID];
                    [circle release];
                }
            }
            else if ( [type isEqualToString:@"polygon"] )
            {
                PGMapPolygon *polygon = [[PGMapPolygon alloc] initWithUUID:UUID args:[command.arguments objectAtIndex:2]];
                if ( polygon )
                {
                    [_nativeObjectDict setObject:polygon forKey:polygon.UUID];
                    [polygon release];
                }
            }
            else if ( [type isEqualToString:@"polyline"] )
            {
                PGMapPolyline *polyline = [[PGMapPolyline alloc] initWithUUID:UUID args:[command.arguments objectAtIndex:2]];
                if ( polyline )
                {
                    [_nativeObjectDict setObject:polyline forKey:polyline.UUID];
                    [polyline release];
                }
            }
            else if ( [type isEqualToString:@"route"] )
            {
                PGGISRoute* gisRoute = [[PGGISRoute alloc]initWithUUID:UUID args:[command.arguments objectAtIndex:2]];
                if ( gisRoute )
                {
                    [_nativeObjectDict setObject:gisRoute forKey:gisRoute.UUID];
                    [gisRoute release];
                }
            }
            else if ( [type isEqualToString:@"search"] )
            {
                PGGISSearch *search = [[PGGISSearch alloc] initWithUUID:UUID];
                if ( search )
                {
                    search.jsBridge = self;
                    [_nativeObjectDict setObject:search forKey:UUID];
                    [search release];
                }
            }
            else if ( [type isEqualToString:@"mapview"] )
            {
                PGMapView *mapView = [PGMapView viewWithArray:[command.arguments objectAtIndex:2]];
                if ( mapView )
                {
                    mapView.jsBridge = self;
                    mapView.UUID = UUID;
                    if ( PGMapViewPositionAbsolute == mapView.positionType ) {
                        [self.JSFrameContext.webEngine.webview addSubview:mapView];
                    } else {
                        [self.JSFrameContext.webEngine.scrollView addSubview:mapView];
                    }
                    [_nativeObjectDict setObject:mapView forKey:UUID];
                }
            }
        }
    }
}

/**
 *invake js marker object
 *@param command PGMethod*
 *@return 无
 */
- (void)insertGisOverlay:(id)object withKey:(NSString*)key
{
    if( !key || !object )
        return;
    
    if ( !_nativeObjectDict )
    {
        _nativeObjectDict = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    [_nativeObjectDict setObject:object forKey:key];
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
