/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_gis_search.mm
 *  Description:
 *      GIS查询实现文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-13  创建文件
 *   Reviewed @ 20130105 by Lin Xinzheng
 *------------------------------------------------------------------
 */

#import "pg_gis_search.h"
#import "pg_map.h"
#import "pg_gis_overlay.h"
#import "PGObject.h"
#import "H5CoreJavaScriptText.h"

#define MAP_GIS_PI 3.14159265358979
#define MAP_GIS_EARTH_RADIUS  6378.137

static double rad(double d)
{
    return d * MAP_GIS_PI / 180.0;
}
/*
 *------------------------------------------
 *@Summay:
 *     计算两个经纬度之间的距离
 *@Param:
 *       [i] lat1 double  点1纬度
 *       [i] lng1 double  点1经度
 *       [i] lat2 double  点2纬度
 *       [i] lng2 double  点2经度
 *@Return:
 *     double 单位为公里
 *-------------------------------------------
 */
static double GIS_GetDistance(double lat1, double lng1, double lat2, double lng2)
{
    double radLat1 = rad(lat1);
    double radLat2 = rad(lat2);
    double a = radLat1 - radLat2;
    double b = rad(lng1) - rad(lng2);
    double s = 2 * asin(sqrt(pow(sin(a/2),2) +
                                       cos(radLat1)*cos(radLat2)*pow(sin(b/2),2)));
    s = s * MAP_GIS_EARTH_RADIUS;
    s = round(s * 10000) / 10000;
    return s;
}

BMKPlanNode* object2PlanNode(NSObject* obj, NSString*cityname)
{
    if ( obj )
    {
        BMKPlanNode *node = [[BMKPlanNode alloc] autorelease];
        if ( [obj isKindOfClass:[NSString class]] )
        {
            node.name = (NSString*)obj;
            node.cityName = cityname;
        }
        else
        {
            PGMapCoordinate *pt = [PGMapCoordinate pointWithJSON:(NSMutableDictionary*)obj];
            node.pt = [pt point2CLCoordinate];
            node.cityName = cityname;
        }
        return node;
    }
    return nil;
}

@implementation PGGISSearch

@synthesize jsBridge;
@synthesize UUID = _UUID;
@synthesize pageCapacity;
@synthesize busRouteType;
@synthesize transitRouteType;
@synthesize drivingPolicy;
@synthesize transitPolicy;

-(void)dealloc
{
    [_UUID release];
    _search.delegate = nil;
    _routeSearch.delegate = nil;
    [_search release];
    [busRouteType release];
    [transitRouteType release];
    [super dealloc];
}

-(id)initWithUUID:(NSString*)UUID
{
    if ( self = [super init] )
    {
        _UUID = [UUID copy];
        _search = [[BMKPoiSearch alloc] init];
        _search.delegate = self;
        _routeSearch = [[BMKRouteSearch alloc] init];
        _routeSearch.delegate = self;
        self.pageCapacity = 10;
        self.transitRouteType = [NSString stringWithFormat:@"%d", 0];
        return self;
    }
    return nil;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于根据范围和检索词发起范围检索，搜索完成后触发onPoiSearchComplete()事件
 * @Parameters:
 *       jsonObj 参数说明
 *      [1] key    String  检索的关键字  必选
 *      [2] ptLB    Point   检索范围的左下角坐标  必选
 *      [3] ptRT    Point   检索范围的右上角坐标  必选
 *      [4] index   Number  检索结果的页面，默认值为0   可选
 * @Returns:
 *     NSInteger
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSInteger)poiSearchInboundsJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
    { return -1; }
    
    int pageIndex = 0;
    NSString *key = [jsonObj objectAtIndex:0];
    PGMapCoordinate *ptLB  = [PGMapCoordinate pointWithJSON:[jsonObj objectAtIndex:1]];
    PGMapCoordinate *ptRT  = [PGMapCoordinate pointWithJSON:[jsonObj objectAtIndex:2]];
    if ( key && [key isKindOfClass:[NSString class]]
        && ptLB && [ptLB isKindOfClass:[PGMapCoordinate class]]
        && ptRT && [ptRT isKindOfClass:[PGMapCoordinate class]])
    {
        if ( [jsonObj count] > 3 )
        {
            NSNumber *index = [jsonObj objectAtIndex:3];
            if ( index && [index isKindOfClass:[NSNumber class]] )
            {
                pageIndex = [index intValue];
            }
        }
        BMKBoundSearchOption *searchOption = [[[BMKBoundSearchOption alloc] init] autorelease];
        searchOption.pageIndex = pageIndex;
        searchOption.pageCapacity = self.pageCapacity;
        searchOption.keyword = key;
        searchOption.leftBottom = [ptLB point2CLCoordinate];
        searchOption.rightTop = [ptRT point2CLCoordinate];

        if ( [_search poiSearchInbounds:searchOption] )
        {
            return 0;
        }
    }
    [self evalPoiErrorJavascript];
    return -1;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于周边检索，根据中心点、半径与检索词进行检索，搜索完成后触发onPoiSearchComplete()事件
 * @Parameters:
 *       jsonObj 参数说明
 *      [1] key    String  检索的关键字  必选
 *      [2] pt  Point   检索的中心点坐标    必选
 *      [3] radius  Number  检索的半径，单位为米  必选
 *      [4] index   Number  检索结果的页面，默认值为0   可选
 * @Returns:
 *     NSInteger
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSInteger)poiSearchNearByJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
    { return -1; }
    int pageIndex = 0;
    NSString *key = [jsonObj objectAtIndex:0];
    PGMapCoordinate *pt  = [PGMapCoordinate pointWithJSON:[jsonObj objectAtIndex:1]];
    NSNumber *radius = [jsonObj objectAtIndex:2];
    if ( pt && key && [key isKindOfClass:[NSString class]]
        && radius && [radius isKindOfClass:[NSNumber class]])
    {
        if ( [jsonObj count] > 3 )
        {
            NSNumber *index = [jsonObj objectAtIndex:3];
            if ( index && [index isKindOfClass:[NSNumber class]] )
                pageIndex = [index intValue];
        }
        CLLocationCoordinate2D center;
        center.latitude = pt.latitude;
        center.longitude = pt.longitude;
        
        BMKNearbySearchOption *searchOption = [[[BMKNearbySearchOption alloc] init] autorelease];
        searchOption.pageIndex = pageIndex;
        searchOption.pageCapacity = self.pageCapacity;
        searchOption.keyword = key;
        searchOption.radius = [radius intValue];
        searchOption.location = center;
        
        if ( [_search poiSearchNearBy:searchOption] )
        {
            return 0;
        }
    }
    [self evalPoiErrorJavascript];
    return -1;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于城市兴趣点检索，搜索完成后触发onPoiSearchComplete()事件
 * @Parameters:
 *       jsonObj 参数说明
 *      [1] city String  检索的城市名称，如果设置为空字符串则在地图所在的当前城市内进行检索   必选
 *      [2] key String  检索的关键字  必选
 *      [3] index   Number  检索结果的页面，默认值为0
 * @Returns:
 *     NSInteger
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSInteger)poiSearchInCityJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]]  )
    { return FALSE; }
    int pageIndex = 0;
    NSString *city = [jsonObj objectAtIndex:0];
    NSString *key = [jsonObj objectAtIndex:1];
    if ( city && [city isKindOfClass:[NSString class]]
         && key && [key isKindOfClass:[NSString class]])
    {
        if ( [jsonObj count] > 2 )
        {
            NSNumber *index = [jsonObj objectAtIndex:2];
            if ( index && [index isKindOfClass:[NSNumber class]] )
                pageIndex = [index intValue];
        }

        BMKCitySearchOption *searchOption = [[[BMKCitySearchOption alloc] init] autorelease];
        searchOption.keyword = key;
        searchOption.city = city;
        searchOption.pageIndex = pageIndex;
        searchOption.pageCapacity = self.pageCapacity;
        if ( [_search poiSearchInCity:searchOption] )
        { return 0; }
    }
    [self evalPoiErrorJavascript];
    return -1;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      设置每次POI页数的容量
 * @Parameters:
 *       jsonObj 参数说明
 *      [1] pageCapacity 容量
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)setPageCapacityJS:(NSArray*)args;
{
    NSNumber *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        self.pageCapacity = [value intValue];
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于公交路线搜索策略，默认采用plus.maps.SearchPolicy.TRANSIT_TIME_FIRST策略
 * @Parameters:
 *       jsonObj 参数说明
 *       TRANSIT_TIME_FIRST	常量，公交搜索策略：时间优先	Android/iOS
 *       TRANSIT_TRANSFER_FIRST	常量，公交搜索策略：最少换乘优先	Android/iOS
 *       TRANSIT_WALK_FIRST	常量，公交搜索策略：最少步行距离优先	Android/iOS
 *       TRANSIT_FEE_FIRST	常量，公交搜索策略：选择车票花销最少优先	Android/iOS
 * @Returns:
 *      无
 * @Remark:    
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)setTransitPolicyJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]]  )
    { return; }

    NSString *policy = [jsonObj objectAtIndex:0];
    if ( policy && [policy isKindOfClass:[NSString class]])
    {/*
      B{
      BMK_TRANSIT_TIME_FIRST = 3,		//较快捷(公交)
      BMK_TRANSIT_TRANSFER_FIRST = 4,	//少换乘(公交)
      BMK_TRANSIT_WALK_FIRST = 5,		//少步行(公交)
      BMK_TRANSIT_NO_SUBWAY = 6,		//不坐地铁
      }BMKTransitPolicy;
      
      typedef enum*/
        if ( [policy isEqualToString:@"TRANSIT_TIME_FIRST"] )
        {
            self.transitPolicy = BMK_TRANSIT_TIME_FIRST;
        }
        else if ( [policy isEqualToString:@"TRANSIT_TRANSFER_FIRST"] )
        {
            self.transitPolicy = BMK_TRANSIT_TRANSFER_FIRST;
        }
        else if ( [policy isEqualToString:@"TRANSIT_WALK_FIRST"] )
        {
            self.transitPolicy = BMK_TRANSIT_WALK_FIRST;
        }
        else if ( [policy isEqualToString:@"TRANSIT_FEE_FIRST"] )
        {
            self.transitPolicy = BMK_TRANSIT_NO_SUBWAY;
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于驾车路线搜索策略，默认采用plus.maps.SearchPolicy.DRIVING_TIME_FIRST策略
 * @Parameters:
 *       jsonObj 参数说明
 *       DRIVING_DIS_FIRST	常量，驾车搜索策略：最短距离优先	Android/iOS
 *       DRIVING_NO_EXPRESSWAY	常量，驾车搜索策略：无高速公路线路	Android/iOS
 *       DRIVING_FEE_FIRST	常量，驾车搜索策略：最少费用优先	Android/iOS
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)setDrivingPolicyJS:(NSArray*)jsonObj
{
    /*
     {
     BMK_DRIVING_BLK_FIRST = -1, //躲避拥堵(自驾)
     BMK_DRIVING_TIME_FIRST = 0,	//最短时间(自驾)
     BMK_DRIVING_DIS_FIRST = 1,	//最短路程(自驾)
     BMK_DRIVING_FEE_FIRST,		//少走高速(自驾)*/
    
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
    { return; }

    NSString *policy = [jsonObj objectAtIndex:0];
    if ( policy && [policy isKindOfClass:[NSString class]])
    {
        if ( [policy isEqualToString:@"DRIVING_DIS_FIRST"] )
        {
            self.drivingPolicy = BMK_DRIVING_DIS_FIRST;
        }
        else if ( [policy isEqualToString:@"DRIVING_NO_EXPRESSWAY"] )
        {
             self.drivingPolicy = BMK_DRIVING_FEE_FIRST;
        }
        else if ( [policy isEqualToString:@"DRIVING_FEE_FIRST"] )
        {
            self.drivingPolicy = BMK_DRIVING_FEE_FIRST;
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于公交路线搜索，搜索完成后触发onRouteSearchComplete()事件
 * @Parameters:
 *       jsonObj 参数说明
 *       [1]start  String/Point    公交线路搜索的起点，可以为关键字、坐标两种方式 必选
 *       [2]end    String/Point    公交线路搜索的终点，可以为关键字、坐标两种方式 必选
 *       [3]city   String  搜索范围的城市名称   必选
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSInteger)transitSearchJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
    { return -1; }

    NSObject *start = [jsonObj objectAtIndex:0];
    NSObject *end  =  [jsonObj objectAtIndex:1];
    NSString *city  = [jsonObj objectAtIndex:2];
    
    if ( start && end && city && [city isKindOfClass:[NSString class]])
    {
        BMKTransitRoutePlanOption *routeOption = [[[BMKTransitRoutePlanOption alloc] init] autorelease];
        routeOption.from = object2PlanNode(start, city);
        routeOption.to = object2PlanNode(end, city);
        routeOption.city = city;
        routeOption.transitPolicy = self.transitPolicy;
        BOOL flag = [_routeSearch transitSearch:routeOption];
        if ( flag )
        { return 0; }
    }
    [self evalRouteErrorJavascript];
    return -1;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于驾车路线搜索策略，默认采用plus.maps.SearchPolicy.DRIVING_TIME_FIRST策略
 * @Parameters:
 *       jsonObj 参数说明
 *       [1]start   String/Point    驾车线路搜索的起点，可以为关键字、坐标两种方式 必选
 *       [2]startCity   String  驾车线路搜索的起点所在城市，如果start为坐标则可填入空字符串    必选
 *       [3]end String/Point    驾车线路搜索的终点，可以为关键字、坐标两种方式 必选
 *       [4]endCity String  驾车线路搜索的终点所在城市，如果end为坐标则可填入空字符串  必选
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSInteger)drivingSearchJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]])
    { return -1; }
    
    NSObject *start = [jsonObj objectAtIndex:0];
    NSString *startCity = [jsonObj objectAtIndex:1];
    NSObject *end = [jsonObj objectAtIndex:2];
    NSString *endCity = [jsonObj objectAtIndex:3];
    
    if ( start && end && startCity && endCity)
    {
        BMKDrivingRoutePlanOption *routeOption = [[[BMKDrivingRoutePlanOption alloc] init] autorelease];
        routeOption.from = object2PlanNode(start, startCity);
        routeOption.to = object2PlanNode(end, endCity);
        routeOption.drivingPolicy = self.drivingPolicy;
        
        BOOL flag = [_routeSearch drivingSearch:routeOption];
        if ( flag )
            return 0;
    }
    [self evalRouteErrorJavascript];
    return -1;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      用于步行路线搜索，搜索完成后触发onRouteSearchComplete()事件
 * @Parameters:
 *       jsonObj 参数说明
 *       [1]start  String/Point    步行线路搜索的起点，可以为关键字、坐标两种方式 必选
 *       [2]startCity   String  步行线路搜索的起点所在城市，如果start为坐标则可传入空字符串    必选
 *       [3]end String/Point    步行线路搜索的终点，可以为关键字、坐标两种方式 必选
 *       [4]endCity String  步行线路搜索的终点所在城市，如果end为坐标则可传入空字符串  必选
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSInteger)walkingSearchJS:(NSArray*)jsonObj
{
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
    { return -1; }
    
    NSObject *start = [jsonObj objectAtIndex:0];
    NSString *startCity = [jsonObj objectAtIndex:1];
    NSObject *end = [jsonObj objectAtIndex:2];
    NSString *endCity = [jsonObj objectAtIndex:3];
    
    if ( start && end && startCity && endCity)
    {
        
        BMKWalkingRoutePlanOption *routeOption = [[[BMKWalkingRoutePlanOption alloc] init] autorelease];
        routeOption.from = object2PlanNode(start, startCity);
        routeOption.to = object2PlanNode(end, endCity);
        BOOL flag = [_routeSearch walkingSearch:routeOption];
        if ( flag )
            return 0;
    }
    [self evalRouteErrorJavascript];
    return -1;
}

#pragma mark 搜索回调接口
#pragma mark ---------------------------
/*
 *------------------------------------------------------------------
 * @Summary:
 *      POI查询回调函数
 * @Parameters:
 *       [1]poiResultList 搜索结果列表，成员类型为BMKPoiResult
 *       [2]type 返回结果类型： BMKTypePoiList,BMKTypeAreaPoiList,BMKAreaMultiPoiList
 *       [3] error 错误号，@see BMKErrorCode
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)result errorCode:(BMKSearchErrorCode)errorCode
{
    if ( BMK_SEARCH_NO_ERROR == errorCode )
    {
       // BMKPoiResult* result = [poiResult.poiInfoList objectAtIndex:0];
        if ( result )
        {
            NSString *jsonResultF =
            @"{var plus =%@;\
            var result = new plus.maps.__SearchPoiResult__();\
            result.__state__ = 0;\
            result.__type__ = 0;\
            result.totalNumber = %d;\
            result.currentNumber = %d;\
            result.pageNumber = %d;\
            result.pageIndex = %d;\
            result.poiList = %@;\
            plus.maps.__bridge__.execCallback('%@', result);}";
            NSMutableString *jsResult = [NSMutableString stringWithFormat:jsonResultF,
                                         [H5CoreJavaScriptText plusObject],
                                         result.totalPoiNum, //totalNumber
                                         result.currPoiNum, //currentNumber
                                         result.pageNum,//pageNumber
                                         result.pageIndex, //pageIndex
                                         [BMKPoiInfo JSArray:result.poiInfoList],
                                         _UUID];//poiList
            [jsBridge asyncWriteJavascript:jsResult];
            return;
        }
    }
    [self evalPoiErrorJavascript];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      公交查询回调函数
 * @Parameters:
 *       [1]result 线路搜索结果类
 *       [2]error error 错误号，@see BMKErrorCode
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)onGetTransitRouteResult:(BMKRouteSearch*)searcher result:(BMKTransitRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    if ( error == BMK_SEARCH_NO_ERROR )
    {
        NSMutableArray* buslines = [NSMutableArray arrayWithCapacity:10];
        if ( buslines )
        {
            for ( BMKTransitRouteLine *bus in result.routes )
            {
                PGGISBusline *route = [PGGISBusline routeWithMABus:bus];
                if ( route )
                {
                    //分配id
                    NSString *UUID = [PGObject genUUID:@"nativeroute"];//[jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
                    route.UUID = UUID;
                    [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
                    [buslines addObject:route];
                }
            }

            if ( [buslines count ] )
            {
                PGGISBusline *route = [buslines objectAtIndex:0];
                [self evalRouteReslutWithStartPoint:route.startPoint
                                           endPoint:route.endPoint
                                        resultCount:[result.routes count]
                                         resultList:buslines];
                return;
            }
        }//end of buslines
    }
    [self evalRouteErrorJavascript];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      返回驾乘搜索结果
 * @Parameters:
 *       [1]result 线路搜索结果类
 *       [2]error error 错误号，@see BMKErrorCode
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)onGetDrivingRouteResult:(BMKRouteSearch*)searcher result:(BMKDrivingRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    if ( error == BMK_SEARCH_NO_ERROR )
    {
        PGGISRoute *route = [PGGISRoute routeWithRoute:result];
        //分配id
        NSString *UUID = [PGObject genUUID:@"nativeroute"];//[jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
        route.UUID = UUID;
        [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
        
        if ( route.startPoint && route.endPoint )
        {
            [self evalRouteReslutWithStartPoint:route.startPoint
                                       endPoint:route.endPoint
                                    resultCount:1
                                     resultList:[NSArray arrayWithObject:route]];
            return;
        }
    }
    [self evalRouteErrorJavascript];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      返回驾乘搜索结果
 * @Parameters:
 *       [1]result 线路搜索结果类
 *       [2]error error 错误号，@see BMKErrorCode
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)onGetWalkingRouteResult:(BMKRouteSearch*)searcher result:(BMKWalkingRouteResult*)result errorCode:(BMKSearchErrorCode)error
//- (void)onGetDrivingRouteResult:(BMKPlanResult*)result errorCode:(int)error
{
    if ( error == BMK_SEARCH_NO_ERROR )
    {
        PGGISRoute *route = [PGGISRoute routeWithWalkingRoute:result];
        //分配id
        NSString *UUID = [PGObject genUUID:@"nativeroute"];//[jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
        route.UUID = UUID;
        [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
        
        if ( route.startPoint && route.endPoint )
        {
            [self evalRouteReslutWithStartPoint:route.startPoint
                                       endPoint:route.endPoint
                                    resultCount:1
                                     resultList:[NSArray arrayWithObject:route]];
            return;
        }
    }
    [self evalRouteErrorJavascript];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      生成路线查询结果
 * @Parameters:
 *       [1]startPoint 起点
 *       [2]endPoint 终点
 *       [3]count 数目
 *       [4]reslutList 结果数组
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)evalRouteReslutWithStartPoint:(PGMapCoordinate*)startPoint
                             endPoint:(PGMapCoordinate*)endPoint
                          resultCount:(NSInteger)count
                           resultList:(NSArray*)reslutList
{
    NSString *jsonResultF =
    @"{var plus = %@;\
        var result = new plus.maps.__SearchRouteResult__();\
        result.__state__ = 0;\
        result.__type__ = 1;\
        result.startPosition = %@;\
        result.endPosition = %@;\
        result.routeNumber = %d;\
        result.routeList = %@;\
        plus.maps.__bridge__.execCallback('%@', result);}";
    
    NSMutableString *jsResult = [NSMutableString stringWithFormat:jsonResultF,
                                 [H5CoreJavaScriptText plusObject],
                                 [startPoint JSObject], //startPosition
                                 [endPoint JSObject], //endPosition
                                 count,
                                 [PGGISBusline JSArray:reslutList],
                                 _UUID];
    [jsBridge asyncWriteJavascript:jsResult];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      生成路线查询错误的jS脚本
 * @Parameters:
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)evalRouteErrorJavascript
{
    NSString *jsonResultF =
    @"{var plus = %@;\
        var result = new plus.maps.__SearchRouteResult__();\
        result.__state__ = -1;\
        result.__type__ = 1;\
        result.startPosition = null;\
        result.endPosition = null;\
        result.routeNumber = 0;\
        result.routeList = null;\
        plus.maps.__bridge__.execCallback('%@', result);}";
    
    NSMutableString *jsResult = [NSMutableString stringWithFormat:jsonResultF, [H5CoreJavaScriptText plusObject], _UUID];
    [jsBridge asyncWriteJavascript:jsResult];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      生成POI查询错误的jS脚本
 * @Parameters:
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)evalPoiErrorJavascript
{
    NSString *jsonResultF =
    @"{var plus = %@;\
        var result = new plus.maps.__SearchPoiResult__();\
        result.__state__ = -1;\
        result.__type__ = 0;\
        result.totalNumber = 0;\
        result.currentNumber = 0;\
        result.pageNumber = 0;\
        result.pageIndex = 0;\
        result.poiList = null;\
        plus.maps.__bridge__.execCallback('%@', result);}";
    NSMutableString *jsResult = [NSMutableString stringWithFormat:jsonResultF,  [H5CoreJavaScriptText plusObject], _UUID];//poiList
    [jsBridge asyncWriteJavascript:jsResult];
}

@end
