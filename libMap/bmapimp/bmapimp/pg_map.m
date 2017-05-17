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
#import <BaiduMapAPI_Utils/BMKGeometry.h>
#import "pg_map_marker.h"
#import "PGBaiduKeyVerify.h"


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
        self.content = @"百度地图";
        self.sdkErrorURL = @"http://wiki.lbsyun.baidu.com/cms/iossdk/doc/v2_8_0/html/_b_m_k_types_8h_source.html";
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
    _codeSearch.delegate = nil;
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
              //  NSString *baseURL = [self writeJavascript:@"window.location.href" ];
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
        CLLocationDistance distance = BMKMetersBetweenMapPoints( BMKMapPointForCoordinate([start point2CLCoordinate]),
                                                                BMKMapPointForCoordinate([end point2CLCoordinate]));
        [self toSucessCallback:callbackId withDouble:distance];
        return;
    }
    [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
}

- (void)calculateArea:(PGMethod*)command {
    NSString *callbackId = [command getArgumentAtIndex:1];
    PGMapBounds *area = [PGMapBounds boundsWithJSON:[command getArgumentAtIndex:0]];
    if ( area ) {
        CLLocationCoordinate2D tr = [area.northease point2CLCoordinate];
        CLLocationCoordinate2D bl = [area.southwest point2CLCoordinate];
        
        double distance = BMKAreaBetweenCoordinates( CLLocationCoordinate2DMake(tr.latitude, bl.longitude),
                                                    CLLocationCoordinate2DMake(bl.latitude, tr.longitude));
        [self toSucessCallback:callbackId withDouble:distance];
        return;
    }
    [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
}

- (void)convertCoordinates:(PGMethod*)command {
    NSDictionary *point = [command getArgumentAtIndex:0];
    NSDictionary *options = [command getArgumentAtIndex:1];
    NSString *callbackId = [command getArgumentAtIndex:2];
    
    PGMapCoordinate *coord = [PGMapCoordinate pointWithJSON:point];
    if ( coord ) {
        BMK_COORD_TYPE coordType = BMK_COORDTYPE_GPS;
        BOOL needConvert = true;
        CLLocationCoordinate2D converTo;
        if ( [options isKindOfClass:[NSDictionary class]] ) {
            NSString *jsCoordType = [options objectForKey:@"coordType"];
            if ( [jsCoordType isKindOfClass:[NSString class]] ) {
                if ( NSOrderedSame == [@"gcj02" caseInsensitiveCompare:jsCoordType] ) {
                    coordType = BMK_COORDTYPE_COMMON;
                } else if ( NSOrderedSame == [@"bd09ll" caseInsensitiveCompare:jsCoordType]
                           ||NSOrderedSame == [@"bd09" caseInsensitiveCompare:jsCoordType]) {
                    needConvert = false;
                }
            }
        }
        if ( needConvert ) {
            NSDictionary *dict = BMKConvertBaiduCoorFrom([coord point2CLCoordinate], coordType);
            if ( dict ) {
                converTo = BMKCoorDictionaryDecode(dict);
            } else {
                [self toErrorCallback:callbackId withCode:PGPluginErrorUnknown];
                return;
            }
        } else {
            converTo = [coord point2CLCoordinate];
        }
        [self toSucessCallback:callbackId withJSON:@{@"lat":@(converTo.latitude),@"long":@(converTo.longitude),@"type":@"bd09" }];
        return;
    }
    [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
}

- (void)geocode:(PGMethod*)command {
    NSString *address = [PGPluginParamHelper getStringValue:[command getArgumentAtIndex:0]];
    NSDictionary *options = [command getArgumentAtIndex:1];
    NSString *callbackId = [command getArgumentAtIndex:2];
    NSString *city = [PGPluginParamHelper getStringValueInDict:options forKey:@"city"];

    if ( [PGPluginParamHelper isEmptyString:address]
        || [PGPluginParamHelper isEmptyString:city] ) {
        [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
        return;
    }
    PGBaiduKeyVerify *verify = [PGBaiduKeyVerify Verify];
    if ( E_PERMISSION_OK != verify.errorCode ) {
        [self toErrorCallback:callbackId withSDKError:verify.errorCode withMessage:[verify errorMessage]];
        return;
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
    NSString *coordType = @"wgs84";
    CLLocationCoordinate2D coorinate2D;
    
    PGBaiduKeyVerify *verify = [PGBaiduKeyVerify Verify];
    if ( E_PERMISSION_OK != verify.errorCode ) {
        [self toErrorCallback:callbackId withSDKError:verify.errorCode withMessage:[verify errorMessage]];
        return;
    }
    
    PGMapCoordinate *cooinate = [PGMapCoordinate pointWithJSON:point];
    if ( !cooinate ) {
        [self toErrorCallback:callbackId withCode:PGPluginErrorInvalidArgument];
        return;
    }
    coorinate2D = [cooinate point2CLCoordinate];
    if ( [options isKindOfClass:[NSDictionary class]] ) {
        coordType = [PGPluginParamHelper getStringValue:[options objectForKey:@"coordType"] defalut:@"wgs84"];
        if ( NSOrderedSame == [@"wgs84" caseInsensitiveCompare:coordType]
            ||NSOrderedSame == [@"gcj02" caseInsensitiveCompare:coordType]
            ||NSOrderedSame == [@"bd09" caseInsensitiveCompare:coordType]
            ||NSOrderedSame == [@"bd09ll" caseInsensitiveCompare:coordType]) {
        } else {
            [self toErrorCallback:callbackId withCode:PGPluginErrorNotSupport];
            return;
        }
    }
    if ( NSOrderedSame == [@"wgs84" caseInsensitiveCompare:coordType] ) {
        NSDictionary *dict = BMKConvertBaiduCoorFrom(coorinate2D, BMK_COORDTYPE_GPS);
        coorinate2D = BMKCoorDictionaryDecode(dict);
    } else if ( NSOrderedSame == [@"gcj02" caseInsensitiveCompare:coordType] ) {
        NSDictionary *dict = BMKConvertBaiduCoorFrom(coorinate2D, BMK_COORDTYPE_COMMON);
        coorinate2D = BMKCoorDictionaryDecode(dict);
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
        _codeSearch = [[BMKGeoCodeSearch alloc] init];
        _codeSearch.delegate = self;
    }
    
    if ( PGMapReqTypeGeocode == req.reqType  ) {
        BMKGeoCodeSearchOption *option = [[[BMKGeoCodeSearchOption alloc] init] autorelease];
        option.city = req.city;
        option.address = req.address;
        BOOL ret = [_codeSearch geoCode:option];
        if ( !ret ) {
            [self toErrorCallback:req.callbackId withCode:PGPluginErrorUnknown];
            [_geocodeReqs removeObjectAtIndex:0];
            _codeSearchRuning = false;
            [self geoReq];
            return;
        }
    } else {
        BMKReverseGeoCodeOption *option = [[[BMKReverseGeoCodeOption alloc] init] autorelease];
        option.reverseGeoPoint = req.coordinate2D;
        
        BOOL ret = [_codeSearch reverseGeoCode:option];
        if ( !ret ) {
            [self toErrorCallback:req.callbackId withCode:PGPluginErrorUnknown];
            [_geocodeReqs removeObjectAtIndex:0];
            _codeSearchRuning = false;
            [self geoReq];
            return;
        }
    }
    _codeSearchRuning = TRUE;
}

/**
 *返回地址信息搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结BMKGeoCodeSearch果
 *@param error 错误号，@see BMKSearchErrorCode
 */
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher
                    result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error {
    if ( [_geocodeReqs count] ) {
        PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
        if ( BMK_SEARCH_NO_ERROR == error ) {
            [self toSucessCallback:req.callbackId withJSON:@{@"long":@(result.location.longitude),
                                                             @"lat":@(result.location.latitude),
                                                             @"addr":result.address,
                                                             @"type":@"bd09"}];
        } else {
            if ( BMK_SEARCH_PERMISSION_UNFINISHED == error ){
                _codeSearchRuning = false;
                [self performSelector:@selector(geoReq) withObject:nil afterDelay:2];
                return;
            }
            //[self toErrorCallback:req.callbackId withCode:error];
            [self toErrorCallback:req.callbackId withSDKError:error withMessage:nil];
        }
        [_geocodeReqs removeObjectAtIndex:0];
    }
    _codeSearchRuning = false;
    [self performSelector:@selector(geoReq) withObject:nil afterDelay:0];
}

/**
 *返回反地理编码搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结果
 *@param error 错误号，@see BMKSearchErrorCode
 */
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result
                        errorCode:(BMKSearchErrorCode)error {
    if ( [_geocodeReqs count] ) {
        PGMapGeoReq *req = [_geocodeReqs objectAtIndex:0];
        if ( BMK_SEARCH_NO_ERROR == error ) {
            [self toSucessCallback:req.callbackId withJSON:@{@"long":@(result.location.longitude),
                                                             @"lat":@(result.location.latitude),
                                                             @"addr":result.address,
                                                             @"type":@"bd09"}];
        } else {
           // [self toErrorCallback:req.callbackId withCode:error];
            [self toErrorCallback:req.callbackId withSDKError:error withMessage:nil];
        }
        [_geocodeReqs removeObjectAtIndex:0];
    }
    _codeSearchRuning = false;
    [self performSelector:@selector(geoReq) withObject:nil afterDelay:0];
}

@end
