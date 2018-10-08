//
//  PGMapDefs.h
//  libMap
//
//  Created by DCloud on 2018/7/13.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface PGMapCoordinate : NSObject
@property(nonatomic, assign)CLLocationDegrees latitude;//标点的文本标注
@property(nonatomic, assign)CLLocationDegrees longitude; //标点的图标;

-(NSString*)JSObject;
+(PGMapCoordinate*)pointWithJSON:(NSDictionary*)jsonObj;
+(NSArray*)arrayWithJSON:(NSArray*)jsonObj;
-(NSDictionary*)toJSON;
//工具类封装
-(CLLocationCoordinate2D)point2CLCoordinate;
+(CLLocationCoordinate2D*)array2CLCoordinatesAlloc:(NSArray*)coordinates;
+(PGMapCoordinate*)pointWithLongitude:(CLLocationDegrees)longitude latitude:(CLLocationDegrees)latitude;
+(NSArray*)coordinateListString2Array:(NSString*)coordinateList;

+(NSArray*)coordinateListWithCoords:(CLLocationCoordinate2D *)points count:(NSUInteger)count;
+(CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                coordinateCount:(NSUInteger *)coordinateCount
                                     parseToken:(NSString *)token;
@end


@interface PGMapBounds : NSObject
@property(nonatomic, retain)PGMapCoordinate *northease;
@property(nonatomic, retain)PGMapCoordinate *southwest;

+(PGMapBounds*)boundsWithJSON:(NSMutableDictionary*)jsonObj;
+(PGMapBounds*)boundsWithNorthEase:(CLLocationCoordinate2D)northease southWest:(CLLocationCoordinate2D)southwest;
- (NSDictionary*)toJSON;
@end

@interface PGMapBubble : NSObject
@property(nonatomic, copy)NSString *label;//标点的文本标注
@property(nonatomic, copy)NSString *icon; //标点的图标
@property(nonatomic, retain)UIImage *contentImage;
+(PGMapBubble*)bubbleWithJSON:(NSMutableDictionary*)jsonObj;
@end

@interface PGMapUserLocation : NSObject
@property ( nonatomic, getter=isUpdating) BOOL updating;
@property ( nonatomic,strong) CLLocation *location;
@property ( nonatomic, strong) CLHeading *heading;
@end
