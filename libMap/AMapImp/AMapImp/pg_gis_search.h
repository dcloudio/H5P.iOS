/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_gis_search.h
 *  Description:
 *      GIS查询头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-13  创建文件
 *------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>
#import "pg_map_marker.h"
#import <AMapSearchKIt/AMapSearchKit.h>
#import <AMapSearchKit/AMapCommonObj.h>
#import <AMapSearchKit/AMapSearchObj.h>

@class XTaskExecute;
@class PGMap;

@interface PGGISSearch : NSObject<AMapSearchDelegate>
{
    AMapSearchAPI *_search;
    XTaskExecute *_execute;
    
    NSString *_UUID;
}

@property(nonatomic,assign)int pageCapacity;
@property(nonatomic, assign)int drivingPolicy;
@property (nonatomic, assign) int transitPolicy;
@property(nonatomic, assign)PGMap* jsBridge;
@property(nonatomic, readonly)NSString* UUID;
@property(nonatomic, retain)NSString* busRouteType;
@property(nonatomic, retain)NSString* transitRouteType;

//js invoke method
- (id)initWithUUID:(NSString*)UUID;
- (NSInteger)poiSearchInCityJS:(NSArray*)jsobj;
- (NSInteger)poiSearchNearByJS:(NSArray*)jsobj;
- (NSInteger)poiSearchInboundsJS:(NSArray*)jsobj;
- (void)setPageCapacityJS:(NSArray*)jsobj;
- (void)setTransitPolicyJS:(NSArray*)jsobj;
- (NSInteger)transitSearchJS:(NSArray*)jsobj;
- (void)setDrivingPolicyJS:(NSArray*)jsobj;
- (NSInteger)drivingSearchJS:(NSArray*)jsobj;
- (NSInteger)walkingSearchJS:(NSArray*)jsobj;
//end

- (void)evalPoiErrorJavascript;
- (void)evalRouteReslutWithStartPoint:(PGMapCoordinate*)startPoint
                             endPoint:(PGMapCoordinate*)endPoint
                          resultCount:(NSInteger)count
                           resultList:(NSArray*)reslutList;
- (void)evalRouteErrorJavascript;

@end
