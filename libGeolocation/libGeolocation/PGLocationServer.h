//
//  PGLocationServer.h
//  libGeolocation
//
//  Created by DCloud on 2018/3/1.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

//NSLocationWhenInUseUsageDescription 允许在前台使用时获取GPS的描述
//NSLocationAlwaysUsageDescription 允许永远可获取GPS的描述
typedef NS_ENUM(NSInteger, PGLocationDescription) {
    PGLocationDescriptionWhenInUse,
    PGLocationDescriptionAlwaysUsage
};

@class PGLocationAddress;
@class PGLocationServer;
@protocol PGLocationServerDelegete <NSObject>
@optional
- (void)locationServer:(PGLocationServer*)manager
    didUpdateLocations:(NSArray *)locations;
- (void)locationServer:(PGLocationServer*)manager didFailWithError:(NSError*)error;
- (void)locationServer:(PGLocationServer*)manager geocodeCompletion:(PGLocationAddress *) placemark;
@end

@protocol PGLocationServer <NSObject>
@property(nonatomic, copy)NSString *providerName;
@property (nonatomic, assign) id<PGLocationServerDelegete> delegate;

- (BOOL)isLocationServicesEnabled;
+ (CLAuthorizationStatus)authorizedStatus;
- (NSString*)getDefalutCoorType;
- (NSString*)getSupportCoorType:(NSString*)coorType;
- (void)startLocation:(BOOL)enableHighAccuracy;
- (void)stopLocation;
- (void)reverseGeocodeLocation:(CLLocation*)location;
@end


@interface PGLocationServer :NSObject <PGLocationServer>{
    NSMutableArray *_reverseLocations;
}
@property(nonatomic, assign) PGLocationDescription locationDescription;
@property(nonatomic, assign) BOOL allowsBackgroundLocationUpdates;
@property(nonatomic, assign)BOOL isReversing;
- (void)addLocations:(NSArray*)locations;
- (id)getFirstLocation;
- (void)removeFirstLocation;
- (void)removeAllLocation;
@end
