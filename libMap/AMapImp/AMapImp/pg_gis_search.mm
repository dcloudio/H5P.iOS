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

typedef NS_ENUM(NSInteger, AMapSearchType)
{
    AMapSearchType_NaviDrive,
    AMapSearchType_NaviWalking
};

#define MAP_GIS_PI 3.14159265358979
#define MAP_GIS_EARTH_RADIUS  6378.137
static AMapGeoPoint* object2AMapGeoPoint(NSObject* obj);

@class XTaskExecute;

typedef void (^XTaskExecuteRuslut)(BOOL error, id info);
typedef void (^XTaskExecuteRunSucess)(id result);
typedef void (^XTaskExecuteRunFailed)(NSError *info);

@interface XTask : NSObject {
    XTaskExecuteRuslut _result;
}
- (void)mainInContext:(XTaskExecute*)context
              result:(XTaskExecuteRuslut)result;
- (void)complete:(id)info;
@end

@implementation XTask
-(void)mainInContext:(XTaskExecute*)context
              result:(XTaskExecuteRuslut)result {
    _result = Block_copy(result);
}
- (void)complete:(id)info {
    if ( info ) {
        _result (true, info);
    } else {
        _result(false, nil);
    }
}
- (void)dealloc {
    Block_release(_result);
    _result = nil;
    [super dealloc];
}
@end

@interface XTaskExecute : NSObject {
    NSMutableArray *_tasks;
    NSInteger _currentIndex;
    XTaskExecuteRunSucess _sucess;
    XTaskExecuteRunFailed _failed;
}
@property(readonly, getter=taskQueues)NSArray *tasks;
-(void)addTask:(XTask*)task;
-(void)runSucess:(XTaskExecuteRunSucess)sucess failed:(XTaskExecuteRunFailed)failed;
@end

@implementation XTaskExecute

-(void)run {
    XTask *task = (XTask*)[self->_tasks objectAtIndex:self->_currentIndex];
    if ( [task isKindOfClass:[XTask class]] ) {
        __block XTaskExecute* weakSelf = self;
        [task mainInContext:weakSelf result:^(BOOL error, id info) {
            if ( !error ) {
                weakSelf->_currentIndex++;
                if ( weakSelf->_currentIndex < [ weakSelf->_tasks count] ) {
                    [weakSelf run];
                } else {
                    weakSelf->_sucess(nil);
                }
            } else {
                weakSelf->_failed(info);
            }
        }];
    }
}

-(void)runSucess:(XTaskExecuteRunSucess)sucess  failed:(XTaskExecuteRunFailed)failed {
    _sucess = Block_copy(sucess);
    _failed = Block_copy(failed);
    [self run];
}

-(void)addTask:(XTask *)task {
    if ( nil == _tasks ) {
        _tasks = [[NSMutableArray alloc] initWithCapacity:2];
    }
    [_tasks addObject:task];
}
- (void)dealloc {
    Block_release(_sucess);
    Block_release(_failed);
    [_tasks release];
    [super dealloc];
}
@end

@interface PGGISGeoTask : XTask<AMapSearchDelegate>
@property(nonatomic, assign)AMapSearchAPI *search;
@property(nonatomic, retain)id place;
@property(nonatomic, retain)NSString *city;
@property(nonatomic, retain)AMapGeoPoint *geocode;
@end

@implementation PGGISGeoTask
@synthesize search, place, city,geocode;
-(void)mainInContext:(XTaskExecute*)context
              result:(XTaskExecuteRuslut)result {
    [super mainInContext:context result:result];
    if ( [place isKindOfClass:[NSString class]] ) {
        AMapGeocodeSearchRequest *navi = [[[AMapGeocodeSearchRequest alloc] init] autorelease];
        navi.address = place;
        navi.city = self.city;
        self.search.delegate = self;
        [self.search AMapGeocodeSearch:navi];
    } else {
        self.geocode = object2AMapGeoPoint(self.place);
        [self complete:nil];
    }
}

- (void)searchRequest:(id)request didFailWithError:(NSError *)error {
    self.search = nil;
    [self complete:error];
}

- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response {
    if ( response && [response count] > 0 ) {
        AMapGeocode *geo = [response.geocodes objectAtIndex:0];
        self.geocode = geo.location;
        [self complete:nil];
    }
    self.search = nil;
}
- (void)dealloc {
    self.geocode = nil;
    self.city = nil;
    self.place = nil;
    [super dealloc];
}
@end

@interface PGGISNaviSearchTask : XTask<AMapSearchDelegate>
@property(nonatomic, assign)AMapSearchAPI *search;
@property(nonatomic, retain)AMapRouteSearchResponse *response;
@property(nonatomic, retain)AMapRouteSearchBaseRequest *request;
@end

@implementation PGGISNaviSearchTask
@synthesize search;
-(void)mainInContext:(XTaskExecute*)context
              result:(XTaskExecuteRuslut)result {
    [super mainInContext:context result:result];
    PGGISGeoTask *startTask = [context.taskQueues objectAtIndex:0];
    PGGISGeoTask *endTask = [context.taskQueues objectAtIndex:1];
    if ( nil == self.request ) {
        AMapRouteSearchBaseRequest *navi = [[[AMapRouteSearchBaseRequest alloc] init] autorelease];
        self.request = navi;
    }
//    self.request.searchType = self.searchType;
//    self.request.requireExtension = YES;
//    self.request.city = city;
    /* 出发点. */
    self.request.origin = startTask.geocode;
    /* 目的地. */
    self.request.destination = endTask.geocode;
    self.search.delegate = self;
    if ( [self.request isKindOfClass:[AMapTransitRouteSearchRequest class]] ) {
        [self.search AMapTransitRouteSearch:(AMapTransitRouteSearchRequest*)self.request];
    } else if ( [self.request isKindOfClass:[AMapDrivingRouteSearchRequest class]] ) {
        [self.search AMapDrivingRouteSearch:(AMapDrivingRouteSearchRequest*)self.request];
    } else if ( [self.request isKindOfClass:[AMapWalkingRouteSearchRequest class]] ) {
        [self.search AMapWalkingRouteSearch:(AMapWalkingRouteSearchRequest*)self.request];
    }
}

- (void)searchRequest:(id)request didFailWithError:(NSError *)error {
    self.search.delegate = nil;
    [self complete:error];
}

- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest*)request
                      response:(AMapRouteSearchResponse*)response {
    self.response = response;
    [self complete:nil];
    self.search.delegate = nil;
}

- (void)dealloc {
    self.response = nil;
    self.request = nil;
    [super dealloc];
}
@end




//static double rad(double d)
//{
//    return d * MAP_GIS_PI / 180.0;
//}

static AMapGeoPoint* object2AMapGeoPoint(NSObject* obj)
{
    if ( [obj isKindOfClass:[NSDictionary class]] )
    {
        PGMapCoordinate *coordinate = [PGMapCoordinate pointWithJSON:(NSMutableDictionary*)obj];
        AMapGeoPoint *pt = [AMapGeoPoint locationWithLatitude:coordinate.latitude
                                                        longitude:coordinate.longitude];
        return pt;
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
    _search.delegate = nil;
    [_execute release];
    [_UUID release];
    [_search release];
    [busRouteType release];
    [transitRouteType release];
    [super dealloc];
}

-(id)initWithUUID:(NSString*)UUID
{
    if ( self = [super init] )
    {
        NSString *amapAppkey = nil;
        NSDictionary *amapInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"amap"];
        if ( [amapInfo isKindOfClass:[NSDictionary class]] ) {
            NSString *tempAK = [amapInfo objectForKey:@"appkey"];
            if ( [tempAK isKindOfClass:[NSString class]] ) {
                amapAppkey = tempAK;
            }
        }
        _UUID = [UUID copy];
        _search = [[AMapSearchAPI alloc] init];
        _search.delegate = self;
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
    int pageIndex = 1;
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
                pageIndex = [index intValue]+1;
            }
        }
        
        NSArray *points = [NSArray arrayWithObjects:
                           [AMapGeoPoint locationWithLatitude:ptLB.latitude longitude:ptLB.longitude],
                           [AMapGeoPoint locationWithLatitude:ptRT.latitude longitude:ptRT.longitude],
                           nil];
        AMapGeoPolygon *polygon = [AMapGeoPolygon polygonWithPoints:points];
        
        AMapPOIPolygonSearchRequest *request = [[[AMapPOIPolygonSearchRequest alloc] init] autorelease];
        
        request.polygon = polygon;
        request.keywords = key;
        request.page = pageIndex;
        request.offset = self.pageCapacity;
        [_search AMapPOIPolygonSearch:request];
    }
    return 0;
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
    int pageIndex = 1;
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
                pageIndex = [index intValue]+1;
        }
        
        AMapGeoPoint *geoPoint = [AMapGeoPoint locationWithLatitude:pt.latitude longitude:pt.longitude];
        AMapPOIAroundSearchRequest *request = [[[AMapPOIAroundSearchRequest alloc] init] autorelease];
        
        request.location = geoPoint;
        request.radius = [radius integerValue];
        request.keywords = key;
        request.sortrule = 1;
        request.page = pageIndex;
        request.offset = self.pageCapacity;
        [_search AMapPOIAroundSearch:request];
    }
    return 0;
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
    int pageIndex = 1;
    NSString *city = [jsonObj objectAtIndex:0];
    NSString *key = [jsonObj objectAtIndex:1];
    if ( city && [city isKindOfClass:[NSString class]]
         && key && [key isKindOfClass:[NSString class]])
    {
        if ( [jsonObj count] > 2 )
        {
            NSNumber *index = [jsonObj objectAtIndex:2];
            if ( index && [index isKindOfClass:[NSNumber class]] )
                pageIndex = [index intValue]+1;
        }
        
        AMapPOIKeywordsSearchRequest *request = [[[AMapPOIKeywordsSearchRequest alloc] init] autorelease];
        request.city = city;
        request.keywords = key;
        request.page = pageIndex;
        request.offset = self.pageCapacity;
        [_search AMapPOIKeywordsSearch:request];
    }
    return 0;
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
      // 策略：
      // 驾车导航策略：0-速度优先（时间）；
      1-费用优先（不走收费路段的最快道路）；
      2-距离优先；3-不走快速路；4-结合实时交通（躲避拥堵）；
      5-多策略（同时使用速度优先、费用优先、距离优先三个策略）
      ；6-不走高速；7-不走高速且避免收费；8-躲避收费和拥堵；
      9-不走高速且躲避收费和拥堵
      // 公交换乘策略：0-最快捷模式；1-最经济模式；2-最少换乘模式；3-最少步行模式；4-最舒适模式；5-不乘地铁模式*/
        if ( [policy isEqualToString:@"TRANSIT_TIME_FIRST"] )
        {
            self.transitPolicy = 0;
        }
        else if ( [policy isEqualToString:@"TRANSIT_TRANSFER_FIRST"] )
        {
            self.transitPolicy = 2;
        }
        else if ( [policy isEqualToString:@"TRANSIT_WALK_FIRST"] )
        {
            self.transitPolicy = 3;
        }
        else if ( [policy isEqualToString:@"TRANSIT_FEE_FIRST"] )
        {
            self.transitPolicy = 1;
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
     // 策略：
     // 驾车导航策略：0-速度优先（时间）；
     1-费用优先（不走收费路段的最快道路）；
     2-距离优先；3-不走快速路；4-结合实时交通（躲避拥堵）；
     5-多策略（同时使用速度优先、费用优先、距离优先三个策略）
     ；6-不走高速；7-不走高速且避免收费；8-躲避收费和拥堵；
     9-不走高速且躲避收费和拥堵
     // 公交换乘策略：0-最快捷模式；1-最经济模式；2-最少换乘模式；3-最少步行模式；4-最舒适模式；5-不乘地铁模式
     @*/
    
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
    { return; }

    NSString *policy = [jsonObj objectAtIndex:0];
    if ( policy && [policy isKindOfClass:[NSString class]])
    {
        if ( [policy isEqualToString:@"DRIVING_DIS_FIRST"] )
        {
            self.drivingPolicy = 2;
        }
        else if ( [policy isEqualToString:@"DRIVING_NO_EXPRESSWAY"] )
        {
             self.drivingPolicy = 6;
        }
        else if ( [policy isEqualToString:@"DRIVING_FEE_FIRST"] )
        {
            self.drivingPolicy = 1;
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
//        AMapNavigationSearchRequest *navi = [[[AMapNavigationSearchRequest alloc] init] autorelease];
//        navi.searchType       = AMapSearchType_NaviBus;
//        navi.requireExtension = YES;
//        navi.city             = city;
//        /* 出发点. */
//        navi.origin = object2AMapGeoPoint(start);
//        /* 目的地. */
//        navi.destination = object2AMapGeoPoint(end);
//        
//        [_search AMapNavigationSearch:navi];
        if ( !_execute ) {
            PGGISGeoTask *originGeoTask = [[[PGGISGeoTask alloc] init] autorelease];
            originGeoTask.city = city;
            originGeoTask.place = start;
            originGeoTask.search = _search;
            
            PGGISGeoTask *destGeoTask = [[[PGGISGeoTask alloc] init] autorelease];
            destGeoTask.city = city;
            destGeoTask.place = end;
            destGeoTask.search = _search;
            
            
            AMapTransitRouteSearchRequest *navi = [[[AMapTransitRouteSearchRequest alloc] init] autorelease];
            navi.requireExtension = YES;
            navi.city             = city;
            navi.strategy = self.transitPolicy;
            
            PGGISNaviSearchTask *naviTask = [[[PGGISNaviSearchTask alloc] init] autorelease];
            naviTask.search = _search;
            naviTask.request = navi;
            
            _execute = [[XTaskExecute alloc] init];
            [_execute addTask:originGeoTask];
            [_execute addTask:destGeoTask];
            [_execute addTask:naviTask];
            __block XTaskExecute *weakExecute = _execute;
            __block PGGISSearch *weakSelf = self;
            [_execute runSucess:^(id info) {
                weakSelf->_search.delegate = weakSelf;
                weakSelf->_execute = nil;
                [self onRouteSearchDone:naviTask.request response:naviTask.response];
                [weakExecute release];
            } failed:^(id info) {
                weakSelf->_search.delegate = weakSelf;
                weakSelf->_execute = nil;
                [self AMapSearchRequest:naviTask.request didFailWithError:info];
                [weakExecute release];
            }];
        } else {
            [self evalRouteErrorJavascript];
        }
    }
    return 0;
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
//    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]])
//    { return -1; }
//    
//    NSObject *start = [jsonObj objectAtIndex:0];
//    NSString *startCity = [jsonObj objectAtIndex:1];
//    NSObject *end = [jsonObj objectAtIndex:2];
//    NSString *endCity = [jsonObj objectAtIndex:3];
//    
//    if ( start && end && startCity && endCity)
//    {
//        AMapNavigationSearchRequest *navi = [[[AMapNavigationSearchRequest alloc] init] autorelease];
//        navi.searchType       = AMapSearchType_NaviDrive;
//        navi.requireExtension = YES;
//        navi.strategy = self.transitPolicy;
//        /* 出发点. */
//        navi.origin = object2AMapGeoPoint(start);
//        /* 目的地. */
//        navi.destination = object2AMapGeoPoint(end);
//        
//        [_search AMapNavigationSearch:navi];
//    }
    return [self naviSearch:jsonObj searchType:AMapSearchType_NaviDrive];
}

- (NSInteger) naviSearch:(NSArray*)jsonObj searchType:(AMapSearchType)searchType {
    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]])
    { return -1; }
    
    NSObject *start = [jsonObj objectAtIndex:0];
    NSString *startCity = [jsonObj objectAtIndex:1];
    NSObject *end = [jsonObj objectAtIndex:2];
    NSString *endCity = [jsonObj objectAtIndex:3];
    
    if ( start && end && startCity && endCity)
    {
        if ( !_execute ) {
            PGGISGeoTask *originGeoTask = [[[PGGISGeoTask alloc] init] autorelease];
            originGeoTask.city = startCity;
            originGeoTask.place = start;
            originGeoTask.search = _search;
            
            PGGISGeoTask *destGeoTask = [[[PGGISGeoTask alloc] init] autorelease];
            destGeoTask.city = endCity;
            destGeoTask.place = end;
            destGeoTask.search = _search;
            
            AMapRouteSearchBaseRequest *navi = nil;
            if (AMapSearchType_NaviDrive == searchType ) {
                AMapDrivingRouteSearchRequest *tmpNavi = [[[AMapDrivingRouteSearchRequest alloc] init] autorelease];
                tmpNavi.requireExtension = YES;
                tmpNavi.strategy = self.drivingPolicy;
                navi = tmpNavi;
                // [_search AMapNavigationSearch:navi];
            } else {
                navi = [[[AMapWalkingRouteSearchRequest alloc] init] autorelease];
            }
            
            
            PGGISNaviSearchTask *naviTask = [[[PGGISNaviSearchTask alloc] init] autorelease];
            naviTask.search = _search;
            naviTask.request = navi;
            
            _execute = [[XTaskExecute alloc] init];
            [_execute addTask:originGeoTask];
            [_execute addTask:destGeoTask];
            [_execute addTask:naviTask];
            __block XTaskExecute *weakExecute = _execute;
            __block PGGISSearch *weakSelf = self;
            [_execute runSucess:^(id info) {
                weakSelf->_search.delegate = weakSelf;
                weakSelf->_execute = nil;
                [self onRouteSearchDone:naviTask.request response:naviTask.response];
                [weakExecute release];
            } failed:^(id info) {
                weakSelf->_search.delegate = weakSelf;
                weakSelf->_execute = nil;
                [self AMapSearchRequest:naviTask.request didFailWithError:info];
                [weakExecute release];
            }];
        } else {
            [self evalRouteErrorJavascript];
        }
    }
    return 0;
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
//    if ( !jsonObj || ![jsonObj isKindOfClass:[NSArray class]] )
//    { return -1; }
//    
//    NSObject *start = [jsonObj objectAtIndex:0];
//    NSString *startCity = [jsonObj objectAtIndex:1];
//    NSObject *end = [jsonObj objectAtIndex:2];
//    NSString *endCity = [jsonObj objectAtIndex:3];
//    
//    if ( start && end && startCity && endCity)
//    {
//        
//        AMapNavigationSearchRequest *navi = [[[AMapNavigationSearchRequest alloc] init] autorelease];
//        navi.searchType       = AMapSearchType_NaviWalking;
//        navi.requireExtension = YES;
//        navi.strategy = self.drivingPolicy;
//        /* 出发点. */
//        navi.origin = object2AMapGeoPoint(start);
//        /* 目的地. */
//        navi.destination = object2AMapGeoPoint(end);
//        
//        [_search AMapNavigationSearch:navi];
//    }
//    return 0;AMapSearchType_NaviDrive
    return [self naviSearch:jsonObj searchType:AMapSearchType_NaviWalking];
}

#pragma mark 搜索回调接口
#pragma mark ---------------------------
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    if ( [request isKindOfClass:[AMapPOIIDSearchRequest class]]
        || [request isKindOfClass:[AMapPOIPolygonSearchRequest class]]
        || [request isKindOfClass:[AMapPOIAroundSearchRequest class]] ) {
        [self evalPoiErrorJavascript];
    } else if ( [request isKindOfClass:[AMapTransitRouteSearchRequest class]]
               ||  [request isKindOfClass:[AMapWalkingRouteSearchRequest class]]
               ||  [request isKindOfClass:[AMapDrivingRouteSearchRequest class]]) {
        [self evalRouteErrorJavascript];
    }
}
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
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if ( response )
    {
        NSString *jsonResultF =
        @"{ var plus =%@;\
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
                                     [self.jsBridge plusObject],
                                     response.count, //totalNumber
                                     [response.pois count], //currentNumber
                                     response.count/self.pageCapacity+1,//response.pageNum,//pageNumber
                                     request.page,//response.pageIndex, //pageIndex
                                     [AMapPOI JSArray:response.pois],
                                     _UUID];//poiList
        [jsBridge asyncWriteJavascript:jsResult];
    }
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
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest*)request response:(AMapRouteSearchResponse*)response
{
    if ( response )
    {
        NSMutableArray* routeLines = [NSMutableArray arrayWithCapacity:10];
        if ( routeLines )
        {
            if ( [request isKindOfClass:[AMapTransitRouteSearchRequest class]] ) {
                for ( AMapTransit *bus in response.route.transits )
                {
                    PGGISBusline *route = [PGGISBusline routeWithMABus:bus];
                    if ( route )
                    {
                        //分配id
                        NSString *UUID = [PGObject genUUID:@"nativeroute"];//[NSString stringWithFormat:@"route%ld"]]; [jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
                        route.UUID = UUID;
                        [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
                        [routeLines addObject:route];
                        route.startPoint = [AMapGeoPoint getPGMapCoordiante:response.route.origin];
                        route.endPoint = [AMapGeoPoint getPGMapCoordiante:response.route.destination];
                    }
                }
            } else {
                for ( AMapPath *bus in response.route.paths )
                {
                    PGGISRoute *route = [PGGISRoute routeWithRoute:bus withOrigin:response.route.origin withDest:response.route.destination];
                    if ( route )
                    {
                        //分配id
                        NSString *UUID = [PGObject genUUID:@"nativeroute"];//[jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
                        route.UUID = UUID;
                        [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
                        [routeLines addObject:route];
                    }
                }
            }
            
            if ( [routeLines count ] )
            {
               // PGGISBusline *route = [routeLines objectAtIndex:0];
                [self evalRouteReslutWithStartPoint:[PGMapCoordinate pointWithLongitude:response.route.origin.longitude latitude:response.route.origin.latitude]
                                           endPoint:[PGMapCoordinate pointWithLongitude:response.route.destination.longitude latitude:response.route.destination.latitude]
                                        resultCount:response.count
                                         resultList:routeLines];
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
//- (void)onGetDrivingRouteResult:(BMKRouteSearch*)searcher result:(BMKDrivingRouteResult*)result errorCode:(BMKSearchErrorCode)error
//{
//    if ( error == BMK_SEARCH_NO_ERROR )
//    {
//        PGGISRoute *route = [PGGISRoute routeWithRoute:result];
//        //分配id
//        NSString *UUID = [jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
//        route.UUID = UUID;
//        [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
//        
//        if ( route.startPoint && route.endPoint )
//        {
//            [self evalRouteReslutWithStartPoint:route.startPoint
//                                       endPoint:route.endPoint
//                                    resultCount:1
//                                     resultList:[NSArray arrayWithObject:route]];
//            return;
//        }
//    }
//    [self evalRouteErrorJavascript];
//}

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
//- (void)onGetWalkingRouteResult:(BMKRouteSearch*)searcher result:(BMKWalkingRouteResult*)result errorCode:(BMKSearchErrorCode)error
////- (void)onGetDrivingRouteResult:(BMKPlanResult*)result errorCode:(int)error
//{
//    if ( error == BMK_SEARCH_NO_ERROR )
//    {
//        PGGISRoute *route = [PGGISRoute routeWithWalkingRoute:result];
//        //分配id
//        NSString *UUID = [jsBridge writeJavascript:@"window.plus.tools.UUID('route');"];
//        route.UUID = UUID;
//        [(PGMap*)jsBridge insertGisOverlay:route withKey:UUID];
//        
//        if ( route.startPoint && route.endPoint )
//        {
//            [self evalRouteReslutWithStartPoint:route.startPoint
//                                       endPoint:route.endPoint
//                                    resultCount:1
//                                     resultList:[NSArray arrayWithObject:route]];
//            return;
//        }
//    }
//    [self evalRouteErrorJavascript];
//}

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
                                 [self.jsBridge plusObject],
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
    
    NSMutableString *jsResult = [NSMutableString stringWithFormat:jsonResultF, [self.jsBridge plusObject], _UUID];
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
        var args = new plus.maps.__SearchPoiResult__();\
        args.__state__ = -1;\
        args.__type__ = 0;\
        args.totalNumber = 0;\
        args.currentNumber = 0;\
        args.pageNumber = 0;\
        args.pageIndex = 0;\
        args.poiList = null;\
        plus.maps.__bridge__.execCallback('%@', args);}";
    NSMutableString *jsResult = [NSMutableString stringWithFormat:jsonResultF, [self.jsBridge plusObject], _UUID];//poiList
    [jsBridge asyncWriteJavascript:jsResult];
}

@end
