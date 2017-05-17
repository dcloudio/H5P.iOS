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

/*
 **@MAPOI扩充支持js方式
 */
#pragma mark ------------------------

@implementation AMapPOI(JSOject)

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
            self.location.longitude, self.location.latitude,
            self.address, self.city, self.name, self.tel, self.postcode];
}

@end

@implementation AMapGeoPoint(geoPoint)
+(PGMapCoordinate*)getPGMapCoordiante:(AMapGeoPoint*)geoPoint {
    return [PGMapCoordinate pointWithLongitude:geoPoint.longitude latitude:geoPoint.latitude];
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
            MAAnnotationView *view = [innerMapView viewForAnnotation:marker];
            view.hidden = !visable;
            marker.hidden = !visable;
        }
        MAOverlayView *polylinewView = [innerMapView viewForOverlay:(id <MAOverlay>)self.polyline];
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

@implementation AMapStep(degress)
- (int)getDegressWithOrientation {
    if ( self.orientation && [self.orientation length] ) {
        if ( NSOrderedSame == [self.orientation caseInsensitiveCompare:@"东"] ) {
            return 90;
        } else if ( NSOrderedSame ==  [self.orientation caseInsensitiveCompare:@"南"] ) {
            return  180;
        } else if (  NSOrderedSame ==  [self.orientation caseInsensitiveCompare:@"西"] ) {
            return 270;
        }
    } else {
        return -1;
    }
    return 0;
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
                MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:2];
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
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:2];
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
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:2];
        route.polyline = polyline;
        free( coordinates);
    }
    
    return route;
}

+(PGGISRoute*)routeWithRoute:(AMapPath*)plan withOrigin:(AMapGeoPoint*)origin withDest:(AMapGeoPoint*)destination {
    if ( !plan )
        return nil;
    
    PGGISRoute *busline = [[[PGGISRoute alloc] init] autorelease];
    if ( !busline )
        return nil;
    
    /*生成标记*/
    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:10];
    if ( !markers )
        return nil;
    
    //  PGGISMarker* item = nil;
    
    // 计算路线方案中的路段数目
    CLLocationCoordinate2D *coordinates = 0;
    NSUInteger size = [plan.steps count];
    NSUInteger planPointCounts = 0;
    for (int i = 0; i < size; i++) {
        AMapStep* transitStep = [plan.steps objectAtIndex:i];
        PGGISMarker* node = [[PGGISMarker alloc]init];
        
        NSUInteger pointsCount = 0;
        CLLocationCoordinate2D *stepCoords = [PGMapCoordinate coordinatesForString:transitStep.polyline coordinateCount:&pointsCount parseToken:@";"];
        
        node.coordinate = stepCoords[0];
        node.title = transitStep.instruction;
        node.degree = [transitStep getDegressWithOrientation];
        
        if ( i == 0 ) {
            node.type = 0;
        } else {
            if ( -1 == node.degree ) {
                node.degree = 0;
                node.type = 3;
            } else {
                node.type = 4;
            }
        }

        [markers addObject:node];
        [node release];
        
        if ( NULL == coordinates ) {
            coordinates = stepCoords;
        } else {
            coordinates = (CLLocationCoordinate2D*)realloc(coordinates, (planPointCounts + pointsCount) * sizeof(CLLocationCoordinate2D) );
            memcpy(coordinates + planPointCounts , stepCoords, pointsCount * sizeof(CLLocationCoordinate2D));
            free(stepCoords);
        }
        //轨迹点总数累计
        planPointCounts += pointsCount;
    }
    
    if ( planPointCounts > 0 ) {
        PGGISMarker* endNode = [[PGGISMarker alloc]init];
        endNode.coordinate =  coordinates[planPointCounts - 1];
        endNode.title = @"终点";
        endNode.type = 1;
        [markers addObject:endNode]; // 添加起点标注
        [endNode release];
    }
    
    /*创建公交行驶轨迹*/
    MAPolyline* polyLine = [MAPolyline polylineWithCoordinates:coordinates count:planPointCounts];
    busline.markers = markers;
    busline.polyline = polyLine;
    busline.pointList = [PGMapCoordinate coordinateListWithCoords:coordinates count:planPointCounts ];
    busline.pointCount = planPointCounts;
    busline.distance = plan.distance;
    busline.startPoint = [AMapGeoPoint getPGMapCoordiante:origin];
    busline.endPoint = [AMapGeoPoint getPGMapCoordiante:destination];
    busline.routeTip = nil;
    free( coordinates );

    return busline;

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
+(PGGISRoute*)routeWithRoute:(AMapPath*)plan
{
    return nil;
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
+(PGGISBusline*)routeWithMABus:(AMapTransit*)plan
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
    CLLocationCoordinate2D *coordinates = 0;
    NSUInteger size = [plan.segments count];
    NSUInteger planPointCounts = 0;
    NSUInteger totoalDistance = 0;
    BOOL isStartSet = false;
    for (int i = 0; i < size; i++) {
        AMapSegment* transitSeg = [plan.segments objectAtIndex:i];
        PGGISMarker* item = [[PGGISMarker alloc]init];
        
        AMapWalking *walkingStep = transitSeg.walking;
        if ( walkingStep ) {
            NSUInteger walkingStepCount = [walkingStep.steps count];
            for (int stepIndex = 0; stepIndex < walkingStepCount; stepIndex++) {
                AMapStep* step = [walkingStep.steps objectAtIndex:stepIndex];
                PGGISMarker* item = [[PGGISMarker alloc]init];

                NSUInteger pointsCount = 0;
                CLLocationCoordinate2D *stepCoords = [PGMapCoordinate coordinatesForString:step.polyline coordinateCount:&pointsCount parseToken:@";"];
                item.coordinate = stepCoords[0];
                item.title = step.instruction;
                item.degree = [step getDegressWithOrientation];
                if ( i == 0 && !isStartSet) {
                    isStartSet = true;
                    item.type = 0;
                } else {
                    if ( -1 == item.degree ) {
                        item.type = 3;
                    } else {
                        item.type = 4;
                    }
                }
                [markers addObject:item];
                [item release];
                if ( NULL == coordinates ) {
                    coordinates = stepCoords;
                } else {
                    coordinates = (CLLocationCoordinate2D*)realloc(coordinates, (planPointCounts + pointsCount) * sizeof(CLLocationCoordinate2D) );
                    memcpy(coordinates + planPointCounts , stepCoords, pointsCount * sizeof(CLLocationCoordinate2D));
                    free(stepCoords);
                }
                planPointCounts += pointsCount;
                totoalDistance += step.distance;
            }
        }
        
        AMapBusLine *buslineStep = nil;
        if ( [transitSeg.buslines count] ) {
            buslineStep = [transitSeg.buslines objectAtIndex:0];
        }
        if ( buslineStep ) {
            NSUInteger pointsCount = 0;
            CLLocationCoordinate2D *stepCoords = [PGMapCoordinate coordinatesForString:buslineStep.polyline coordinateCount:&pointsCount parseToken:@";"];
            item.coordinate = stepCoords[0];
            item.title = [NSString stringWithFormat:@"乘坐%@:在%@上车途径%ld站在%@下车", buslineStep.name, buslineStep.departureStop.name, (long)[buslineStep.viaBusStops count], buslineStep.arrivalStop.name];
            if ( i == 0 && !isStartSet ) {
                isStartSet = true;
                item.type = 0;
            } else  {
                item.type = 2;
            }
            [markers addObject:item];
            [item release];
            if ( NULL == coordinates ) {
                coordinates = stepCoords;
            } else {
                coordinates = (CLLocationCoordinate2D*)realloc(coordinates, (planPointCounts + pointsCount) * sizeof(CLLocationCoordinate2D) );
                memcpy(coordinates + planPointCounts , stepCoords, pointsCount * sizeof(CLLocationCoordinate2D));
                free(stepCoords);
            }
            totoalDistance += buslineStep.distance;
            planPointCounts += pointsCount;
        }
    }

    if ( planPointCounts > 0 ) {
        PGGISMarker* endNode = [[PGGISMarker alloc]init];
        endNode.coordinate =  coordinates[planPointCounts - 1];
        endNode.title = @"终点";
        endNode.type = 1;
        [markers addObject:endNode]; // 添加起点标注
        [endNode release];
    }
    /*创建公交行驶轨迹*/
    MAPolyline* polyLine = [MAPolyline polylineWithCoordinates:coordinates count:planPointCounts];
    busline.markers = markers;
    busline.polyline = polyLine;
    busline.pointList = [PGMapCoordinate coordinateListWithCoords:coordinates count:planPointCounts ];
    busline.pointCount = planPointCounts;
    busline.distance = plan.distance;
    busline.routeTip = nil;
    free( coordinates );
    return busline;
}
@end
