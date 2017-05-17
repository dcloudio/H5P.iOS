/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_gis_overlay.mm
 *  Description:
 *      GIS查询覆盖物实现文件
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

#import "pg_gis_overlay.h"
#import "pg_map_overlay.h"
#import "pg_map_marker.h"
#import "PGObject.h"
#import "pg_map_view.h"

/*
 **@MAPOI扩充支持js方式
 */
#pragma mark ------------------------

@implementation BMKPoiInfo(JSOject)

/*
 *------------------------------------------------------------------
 * @Summary:
 *      生成js plus.maps.Position对象
 * @Parameters:
 *       无
 * @Returns:
 *     NSString* js对象生成function
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSString*)JSObject
{
    NSString *jsonObjectFormat =
    @"function(){\
        var poi = new plus.maps.Position();\
        poi.point = new plus.maps.Point(%f,%f);\
        poi.address = '%@';\
        poi.city = '%@';\
        poi.name = '%@';\
        poi.phone = '%@';\
        poi.postcode = '%@';\
        return poi;\
    }()";
    
    return [NSString stringWithFormat:jsonObjectFormat,
            self.pt.longitude, self.pt.latitude,
            self.address, self.city, self.name, self.phone, self.postcode];
}

@end

/*
 **@gis查询出的标记封装
*/
#pragma mark ------------------------
@implementation PGGISMarker

@synthesize hidden;
@synthesize type; ///<0:起点 1：终点 2：公交 3：地铁 4:驾乘
@synthesize degree;

@end

#pragma mark ------------------------
@implementation PGGISOverlay

@synthesize startPoint;
@synthesize endPoint;
@synthesize pointCount;
@synthesize distance;
@synthesize pointList;
@synthesize routeTip;

@synthesize markers;
@synthesize polyline;

@synthesize belongMapview;

-(void)dealloc
{
    [startPoint release];
    [endPoint release];
    [pointList release];
    [routeTip release];
    [markers release];
    [polyline release];
    [super dealloc];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      生成js plus.maps.Route对象
 * @Parameters:
 *       无
 * @Returns:
 *     NSString* js对象生成function
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSString*)JSObject
{
    NSString *jsonObjectFormat =
    @" function (){\
        var route = new plus.maps.Route(%@, %@, false);\
        route._UUID_ = '%@';\
        route.pointCount = %d;\
        route.pointList = %@;\
        route.distance = %d;\
        route.routeTip = '%@';\
        return route;\
    }()";
    return [NSString stringWithFormat:jsonObjectFormat,
            [self.startPoint JSObject],
            [self.endPoint JSObject],
            self.UUID,
            self.pointCount,
            [PGMapCoordinate JSArray:self.pointList],
            self.distance,
            self.routeTip];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      设置覆盖物是否显示
 * @Parameters:
 *       [1] visable, TURE 显示 FALSE 隐藏
 * @Returns:
 *      BOOL 属性是否修改
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)setVisable:(BOOL)visable
{
    PGMapView *innerMapView = self.belongMapview;
    if ( innerMapView )
    {
        for ( PGGISMarker *marker in self.markers )
        {
            BMKAnnotationView *view = [innerMapView.mapView viewForAnnotation:marker];
            view.hidden = !visable;
            marker.hidden = !visable;
        }
        BMKOverlayView *polylinewView = [innerMapView.mapView viewForOverlay:(id <BMKOverlay>)self.polyline];
        polylinewView.hidden = !visable;
    }
    self.hidden = !visable;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      显示覆盖物
 * @Parameters:
 *       [1] args, 参数
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)showJS:(NSArray*)args
{
    [self setVisable:YES];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      隐藏覆盖物
 * @Parameters:
 *       [1] args, 参数
 * @Returns:
 *      无
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)hideJS:(NSArray*)args
{
    [self setVisable:NO];
}

@end

#pragma mark ------------------------
@implementation PGGISRoute

/*
 *------------------------------------------------------------------
 * @Summary:
 *      根据数组参数格式对象生成PGGISRoute*对象
 * @Parameters:
 *       [1] uID, NSString* js object id
 *       [1] args, 参数
 * @Returns:
 *      PGGISRoute* 路线包括步行和驾车
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args
{
    if ( self = [super init] )
    {
        self.UUID = uID;
        if ( args && [args isKindOfClass:[NSArray class]] )
        {
            NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];
            
            PGMapCoordinate *startPoint = [PGMapCoordinate pointWithJSON:[args objectAtIndex:0]];
            PGGISMarker *marker = [[[PGGISMarker alloc] init] autorelease];
            marker.coordinate = [startPoint point2CLCoordinate];
            marker.degree = 0;
            marker.type = 0; //起点
            marker.title = @"起点";
            [markers addObject:marker];
            
            PGMapCoordinate *endPoint = [PGMapCoordinate pointWithJSON:[args objectAtIndex:1]];
            PGGISMarker *endMarker = [[[PGGISMarker alloc] init] autorelease];
            endMarker.coordinate = [endPoint point2CLCoordinate];
            endMarker.degree = 0;
            endMarker.type = 1; //终点
            endMarker.title = @"终点";
            [markers addObject:endMarker];
            
            self.markers = markers;
            
            //生成线路
            NSArray *pointList = [[[NSArray alloc ]initWithObjects:startPoint, endPoint, nil] autorelease];
            CLLocationCoordinate2D *coordinates = [PGMapCoordinate array2CLCoordinatesAlloc:pointList];
            if ( coordinates )
            {
                BMKPolyline *polyline = [BMKPolyline polylineWithCoordinates:coordinates count:2];
                self.polyline = polyline;
                free( coordinates);
            }
        }
    }
    return self;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      根据数组参数格式对象生成PGGISRoute*对象
 * @Parameters:
 *       [1] args, 参数
 * @Returns:
 *      PGGISRoute* 路线包括步行和驾车
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
+(PGGISRoute*)routeWithArray:(NSArray*)args
{
    if ( !args )
        return nil;
    if ( ![args isKindOfClass:[NSArray class]] )
        return nil;
    
    PGGISRoute *route = [[[PGGISRoute alloc] init] autorelease];
    
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];
    
    PGMapCoordinate *startPoint = [PGMapCoordinate pointWithJSON:[args objectAtIndex:0]];
    PGGISMarker *marker = [[[PGGISMarker alloc] init] autorelease];
    marker.coordinate = [startPoint point2CLCoordinate];
    marker.degree = 0;
    marker.type = 0; //起点
    marker.title = @"起点";
    [markers addObject:marker];
    
    PGMapCoordinate *endPoint = [PGMapCoordinate pointWithJSON:[args objectAtIndex:1]];
    PGGISMarker *endMarker = [[[PGGISMarker alloc] init] autorelease];
    endMarker.coordinate = [endPoint point2CLCoordinate];
    endMarker.degree = 0;
    endMarker.type = 1; //终点
    endMarker.title = @"终点";
    [markers addObject:endMarker];
    
    route.markers = markers;
    
    //生成线路
    NSArray *pointList = [[[NSArray alloc ]initWithObjects:startPoint, endPoint, nil] autorelease];
    CLLocationCoordinate2D *coordinates = [PGMapCoordinate array2CLCoordinatesAlloc:pointList];
    if ( coordinates )
    {
        BMKPolyline *polyline = [BMKPolyline polylineWithCoordinates:coordinates count:2];
        route.polyline = polyline;
        free( coordinates);
    }
    
    return route;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      根据json格式对象生成PGGISRoute*对象
 * @Parameters:
 *       [1] jsonObj, json对象
 * @Returns:
 *      PGGISRoute* 路线包括步行和驾车
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
+(PGGISRoute*)routeWithJSON:(NSMutableDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    
    PGGISRoute *route = [[[PGGISRoute alloc] init] autorelease];
    route.UUID = [jsonObj objectForKey:@"_UUID_"];
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];
    
    PGMapCoordinate *startPoint = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"startPoint"]];
    
    PGGISMarker *marker = [[[PGGISMarker alloc] init] autorelease];
    marker.coordinate = [startPoint point2CLCoordinate];
    marker.degree = 0;
    marker.type = 0; //起点
    marker.title = @"起点";
    [markers addObject:marker];
    
    PGMapCoordinate *endPoint = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"endPoint"]];
    PGGISMarker *endMarker = [[[PGGISMarker alloc] init] autorelease];
    endMarker.coordinate = [endPoint point2CLCoordinate];
    endMarker.degree = 0;
    endMarker.type = 1; //终点
    endMarker.title = @"终点";
    [markers addObject:endMarker];
    
    route.markers = markers;
    
    /*生成线路*/
    NSArray *pointList = [[[NSArray alloc ]initWithObjects:startPoint, endPoint, nil] autorelease];
    CLLocationCoordinate2D *coordinates = [PGMapCoordinate array2CLCoordinatesAlloc:pointList];
    if ( coordinates )
    {
        BMKPolyline *polyline = [BMKPolyline polylineWithCoordinates:coordinates count:2];
        route.polyline = polyline;
        free( coordinates);
    }
    
    return route;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      根据百度搜索结果创建GIS覆盖物对象
 * @Parameters:
 *       [1] result, 线路搜索结果类
 * @Returns:
 *      PGGISRoute* 路线包括步行和驾车
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
+(PGGISRoute*)routeWithRoute:(BMKDrivingRouteResult*)result
{
    BMKDrivingRouteLine* plan = [result.routes objectAtIndex:0];
    
    PGGISRoute *routeLine = [[[PGGISRoute alloc] init] autorelease];
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];

    // 计算路线方案中的路段数目
    NSUInteger size = [plan.steps count];
    NSUInteger planPointCounts = 0;
    for (int i = 0; i < size; i++) {
        BMKDrivingStep* transitStep = [plan.steps objectAtIndex:i];
        if(i==0){
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = plan.starting.location;
            item.title = @"起点";
            item.type = 0;
            [markers addObject:item];
            [item release];
            
        }else if(i==size-1){
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = plan.terminal.location;
            item.title = @"终点";
            item.type = 1;
            [markers addObject:item];
            [item release];
        }
        //添加annotation节点
        PGGISMarker* item = [[PGGISMarker alloc]init];
        item.coordinate = transitStep.entrace.location;
        item.title = transitStep.entraceInstruction;
        item.degree = transitStep.direction * 30;
        item.type = 4;
        [markers addObject:item];
        [item release];
        //轨迹点总数累计
        planPointCounts += transitStep.pointsCount;
    }
    // 添加途经点
    if (plan.wayPoints) {
        for (BMKPlanNode* tempNode in plan.wayPoints) {
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = tempNode.pt;
            item.type = 5;
            item.title = tempNode.name;
            [markers addObject:item];
            [item release];
        }
    }
    //轨迹点
    BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
    int i = 0;
    for (int j = 0; j < size; j++) {
        BMKDrivingStep* transitStep = [plan.steps objectAtIndex:j];
        int k=0;
        for(k=0;k<transitStep.pointsCount;k++) {
            temppoints[i].x = transitStep.points[k].x;
            temppoints[i].y = transitStep.points[k].y;
            i++;
        }
        
    }
    // 通过points构建BMKPolyline
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
    routeLine.markers = markers;
    routeLine.polyline = polyLine;
    routeLine.distance = plan.distance;
    routeLine.pointList = [PGMapCoordinate coordinateListWithPoints:temppoints count:planPointCounts ];
    routeLine.pointCount = planPointCounts;
    routeLine.routeTip = @"";
    routeLine.startPoint = [PGMapCoordinate pointWithLongitude:plan.starting.location.longitude
                                                      latitude:plan.starting.location.latitude];
    routeLine.endPoint = [PGMapCoordinate pointWithLongitude:plan.terminal.location.longitude
                                                    latitude:plan.terminal.location.latitude];
    delete []temppoints;
    return routeLine;
}

+(PGGISRoute*)routeWithWalkingRoute:(BMKWalkingRouteResult*)result {
    PGGISRoute *routeLine = [[[PGGISRoute alloc] init] autorelease];
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];
    BMKWalkingRouteLine* plan = (BMKWalkingRouteLine*)[result.routes objectAtIndex:0];
    NSUInteger size = [plan.steps count];
    NSUInteger planPointCounts = 0;
    for (int i = 0; i < size; i++) {
        BMKWalkingStep* transitStep = [plan.steps objectAtIndex:i];
        if(i==0){
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = plan.starting.location;
            item.title = @"起点";
            item.type = 0;
            [markers addObject:item]; // 添加起点标注
            [item release];
            
        }else if(i==size-1){
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = plan.terminal.location;
            item.title = @"终点";
            item.type = 1;
            [markers addObject:item]; // 添加起点标注
            [item release];
        }
        //添加annotation节点
        PGGISMarker* item = [[PGGISMarker alloc]init];
        item.coordinate = transitStep.entrace.location;
        item.title = transitStep.entraceInstruction;
        item.degree = transitStep.direction * 30;
        item.type = 4;
        [markers addObject:item];
        [item release];
        //轨迹点总数累计
        planPointCounts += transitStep.pointsCount;
    }
    
    //轨迹点
    BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
    int i = 0;
    for (int j = 0; j < size; j++) {
        BMKWalkingStep* transitStep = [plan.steps objectAtIndex:j];
        int k=0;
        for(k=0;k<transitStep.pointsCount;k++) {
            temppoints[i].x = transitStep.points[k].x;
            temppoints[i].y = transitStep.points[k].y;
            i++;
        }
        
    }
    // 通过points构建BMKPolyline
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
    routeLine.markers = markers;
    routeLine.polyline = polyLine;
    routeLine.distance = plan.distance;
    routeLine.pointList = [PGMapCoordinate coordinateListWithPoints:temppoints count:planPointCounts ];
    routeLine.pointCount = planPointCounts;
    routeLine.routeTip = @"";
    routeLine.startPoint = [PGMapCoordinate pointWithLongitude:plan.starting.location.longitude
                                                      latitude:plan.starting.location.latitude];
    routeLine.endPoint = [PGMapCoordinate pointWithLongitude:plan.terminal.location.longitude
                                                    latitude:plan.terminal.location.latitude];
    delete []temppoints;
    return routeLine;
}
@end


#pragma mark ------------------------
@implementation PGGISBusline
/*
 *------------------------------------------------------------------
 * @Summary:
 *      根据百度搜索结果创建GIS公交导航路线
 * @Parameters:
 *       [1] result, 公交方案详情类
 * @Returns:
 *      PGGISBusline* 路线包括步行和驾车
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
+(PGGISBusline*)routeWithMABus:(BMKTransitRouteLine*)plan
{
    if ( !plan )
        return nil;
    
    PGGISBusline *busline = [[[PGGISBusline alloc] init] autorelease];
    if ( !busline )
        return nil;
  
    /*生成标记*/
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];
    if ( !markers )
        return nil;

  //  PGGISMarker* item = nil;

    // 计算路线方案中的路段数目
    NSUInteger size = [plan.steps count];
    NSUInteger planPointCounts = 0;
    for (int i = 0; i < size; i++) {
        BMKTransitStep* transitStep = [plan.steps objectAtIndex:i];
        PGGISMarker* item = [[PGGISMarker alloc]init];
        item.coordinate = transitStep.entrace.location;
        item.title = transitStep.instruction;
        item.type = 3;
        [markers addObject:item];;
        [item release];
        if(i==0){
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = transitStep.entrace.location;
            item.title = @"起点";
            item.type = 0;
            [markers addObject:item]; // 添加起点标注
            [item release];
            
        }else if(i==size-1){
            PGGISMarker* item = [[PGGISMarker alloc]init];
            item.coordinate = transitStep.exit.location;
            item.title = @"终点";
            item.type = 1;
            [markers addObject:item]; // 添加起点标注
            [item release];
        }
        //轨迹点总数累计
        planPointCounts += transitStep.pointsCount;
    }
    
    //轨迹点
    BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
    int i = 0;
    for (int j = 0; j < size; j++) {
        BMKTransitStep* transitStep = [plan.steps objectAtIndex:j];
        int k=0;
        for(k=0;k<transitStep.pointsCount;k++) {
            temppoints[i].x = transitStep.points[k].x;
            temppoints[i].y = transitStep.points[k].y;
            i++;
        }
        
    }

    /*创建公交行驶轨迹*/
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
    busline.markers = markers;
    busline.polyline = polyLine;
    busline.pointList = [PGMapCoordinate coordinateListWithPoints:temppoints count:planPointCounts ];
    busline.pointCount = planPointCounts;
    busline.distance = plan.distance;
    busline.routeTip = plan.title;
    
    busline.startPoint = [PGMapCoordinate pointWithLongitude:plan.starting.location.longitude
                                                      latitude:plan.starting.location.latitude];
    busline.endPoint = [PGMapCoordinate pointWithLongitude:plan.terminal.location.longitude
                                                    latitude:plan.terminal.location.latitude];
    
    delete []temppoints;

    return busline;
}

@end