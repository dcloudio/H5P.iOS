//
//  PGMapDefs.m
//  libMap
//
//  Created by DCloud on 2018/7/13.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "PGMapDefs.h"

@implementation PGMapCoordinate

@synthesize latitude;
@synthesize longitude;

/*
 *------------------------------------------------
 *@summay:  根据经纬度生成PGMapCoordinate对象
 *@param
 *  [1] longitude
 *  [2] latitude
 *@return
 *   PGMapCoordinate*
 *@remark
 *------------------------------------------------
 */
+(PGMapCoordinate*)pointWithLongitude:(CLLocationDegrees)longitude latitude:(CLLocationDegrees)latitude
{
    PGMapCoordinate *point = [[[PGMapCoordinate alloc] init] autorelease];
    point.latitude = latitude;
    point.longitude = longitude;
    return point;
}

/*
 *------------------------------------------------
 *@summay: 根据json数据数组生成PGMapCoordinate对象数组
 *@param jsonObj
 *@return
 *     NSArray* PGMapCoordinate对象数组
 *@remark
 *------------------------------------------------
 */
+(NSArray*)arrayWithJSON:(NSArray*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSArray class]] )
        return nil;
    
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:10];
    for ( NSMutableDictionary *dict in jsonObj )
    {
        PGMapCoordinate *point =  [PGMapCoordinate pointWithJSON:dict];
        if ( point )
            [objects addObject:point];
    }
    return objects;
}

-(NSDictionary*)toJSON
{
    return @{@"longitude":@(self.longitude),@"latitude":@(self.latitude)};
}

/*
 *------------------------------------------------
 *@summay: 根据json数据生成PGMapCoordinate对象
 *@param jsonObj
 *@return
 *     PGMapCoordinate* PGMapCoordinate对象
 *@remark
 *------------------------------------------------
 */
+(PGMapCoordinate*)pointWithJSON:(NSDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSDictionary class]] )
        return nil;
    
    PGMapCoordinate *point = [[[PGMapCoordinate alloc] init] autorelease];
    
    NSNumber *longitude = [jsonObj objectForKey:@"longitude"];
    if ( [longitude isKindOfClass:[NSNumber class]]
        ||[longitude isKindOfClass:[NSString class]])
        point.longitude = [longitude doubleValue];
    
    NSNumber *latitude = [jsonObj objectForKey:@"latitude"];
    if ( [latitude isKindOfClass:[NSNumber class]]
        ||[latitude isKindOfClass:[NSString class]])
        point.latitude = [latitude doubleValue];
//    
//    if ( !CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(point.latitude, point.longitude)) ) {
//        return nil;
//    }
    
    return point;
}

/*
 *------------------------------------------------
 *@summay: 将PGMapCoordinate转化为js对象
 *@param
 *@return
 *     NSString* 生成js对象的function
 *@remark
 *------------------------------------------------
 */
-(NSString*)JSObject
{
    NSString *jsonObjectFormat =
    @"function (){\
    var point = new plus.maps.Point(%f, %f);\
    return point;\
    }()";
    return [NSString stringWithFormat:jsonObjectFormat, self.longitude, self.latitude];
    /*
     NSString *jsonObjectFormat = @"{ \"point\":{\"longitude\":%f, \"latitude\":%f }}";
     return [NSString stringWithFormat:jsonObjectFormat, self.longitude, self.latitude];*/
}

/*
 *------------------------------------------------
 *@summay: 将经纬度字符串转化为经纬度数组
 *@param
 * coordinateList 格式：log1,lat1,log2,lat2....
 *@return
 *     NSArray* PGMapCoordinate对象数组
 *@remark
 *------------------------------------------------
 */
+(NSArray*)coordinateListString2Array:(NSString*)coordinateList
{
    if ( coordinateList )
    {
        NSArray *coordinateLists = [coordinateList componentsSeparatedByString:@","];
        if ( [coordinateLists count] )
        {
            NSMutableArray *points = [NSMutableArray arrayWithCapacity:10];
            for (int index = 0; index < [coordinateLists count]; index+=2 )
            {
                PGMapCoordinate *point = [PGMapCoordinate pointWithLongitude:[[coordinateLists objectAtIndex:index] doubleValue]
                                                                    latitude:[[coordinateLists objectAtIndex:index+1] doubleValue]];
                if ( point )
                    [points addObject:point];
            }
            return points;
        }
    }
    return nil;
}

/*
 *------------------------------------------------
 *@summay: 将经纬度字符串转化为经纬度数组
 *@param
 * coordinateList 格式：log1,lat1,log2,lat2....
 *@return
 *     NSArray* PGMapCoordinate对象数组
 *@remark
 *------------------------------------------------
 */
+(NSArray*)coordinateListWithCoords:(CLLocationCoordinate2D *)points count:(NSUInteger)count
{
    if ( points )
    {
        NSMutableArray *pointList = [NSMutableArray arrayWithCapacity:10];
        for (int index = 0; index < count; index++)
        {
            CLLocationCoordinate2D point = points[index];
            PGMapCoordinate *pdrPt = [PGMapCoordinate pointWithLongitude:point.longitude latitude:point.latitude];
            [pointList addObject:pdrPt ];
        }
        return pointList;
    }
    return nil;
}
+ (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token
{
    if (string == nil) {
        return NULL;
    }
    if (token == nil) {
        token = @",";
    }
    NSString *str = @"";
    if (![token isEqualToString:@","]) {
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    }
    else {
        str = [NSString stringWithString:string];
    }
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL) {
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D*)malloc(count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < count; i++) {
        coordinates[i].longitude = [[components objectAtIndex:2 * i]     doubleValue];
        coordinates[i].latitude  = [[components objectAtIndex:2 * i + 1] doubleValue];
    }
    
    return coordinates;
}
/*
 *------------------------------------------------
 *@summay: 获取CLLocationCoordinate2D格式的经纬度
 *@param
 *
 *@return
 *     CLLocationCoordinate2D 经纬度
 *@remark
 *------------------------------------------------
 */
-(CLLocationCoordinate2D)point2CLCoordinate
{
    CLLocationCoordinate2D coordinate = { self.latitude, self.longitude };
    return coordinate;
}

/*
 *------------------------------------------------
 *@summay: 获取coordinates经纬度数组
 *@param
 *      coordinates PGMapCoordinate*对象数组
 *@return
 *     CLLocationCoordinate2D* 经纬度数组
 *@remark
 *------------------------------------------------
 */
+(CLLocationCoordinate2D*)array2CLCoordinatesAlloc:(NSArray*)coordinates
{
    NSInteger count = [coordinates count];
    if ( coordinates && count)
    {
        CLLocationCoordinate2D* points =  malloc( sizeof(CLLocationCoordinate2D)*count);
        for ( int i = 0; i < count; i++ )
        {
            PGMapCoordinate *point = (PGMapCoordinate*)[coordinates objectAtIndex:i];
            points[i] = [point point2CLCoordinate];
        }
        return points;
    }
    return NULL;
}

@end


@implementation PGMapBounds

@synthesize northease;
@synthesize southwest;

+(PGMapBounds*)boundsWithJSON:(NSMutableDictionary*)jsonObj {
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    PGMapCoordinate *tmpNorthease = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"northease"]];
    PGMapCoordinate *tmpSouthwest = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"southwest"]];
    
    if ( tmpNorthease && tmpSouthwest ) {
        PGMapBounds *bounds = [[[PGMapBounds alloc] init] autorelease];
        bounds.northease = tmpNorthease;
        bounds.southwest = tmpSouthwest;
        return bounds;
    }
    return nil;
}

+(PGMapBounds*)boundsWithNorthEase:(CLLocationCoordinate2D)northease
                         southWest:(CLLocationCoordinate2D)southwest {
    PGMapBounds *bounds = [[[PGMapBounds alloc] init] autorelease];
    bounds.northease = [PGMapCoordinate pointWithLongitude:northease.longitude latitude:northease.latitude];
    bounds.southwest = [PGMapCoordinate pointWithLongitude:southwest.longitude latitude:southwest.latitude];
    return bounds;
}

- (NSDictionary*)toJSON {
    return @{@"northease":[self.northease toJSON],@"southwest":[self.southwest toJSON]};
}

-(void)dealloc {
    self.northease = nil;
    self.southwest = nil;
    [super dealloc];
}

@end


#pragma PGMapBubble
#pragma mark -----------------
@implementation PGMapBubble
@synthesize label;
@synthesize icon;
@synthesize contentImage;

-(void)dealloc
{
    self.contentImage = nil;
    [label release];
    [icon release];
    [super dealloc];
}

/*
 *------------------------------------------------
 *@summay: 根据json数据创建bubble对象
 *@param jsonObj js 对象
 *@return
 *   PGMapBubble *
 *@remark
 *------------------------------------------------
 */
+(PGMapBubble*)bubbleWithJSON:(NSMutableDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    
    PGMapBubble *bubble = [[[PGMapBubble alloc] init] autorelease];
    
    NSString *lable = [jsonObj objectForKey:@"label"];
    if ( lable && [lable isKindOfClass:[NSString class]] )
        bubble.label = lable;
    
    NSString *icon = [jsonObj objectForKey:@"icon"];
    if ( icon && [icon isKindOfClass:[NSString class]] )
        bubble.icon = icon;
    
    return bubble;
}

@end

@implementation PGMapUserLocation
- (void)dealloc {
    self.location = nil;
    self.heading = nil;
    [super dealloc];
}
@end
