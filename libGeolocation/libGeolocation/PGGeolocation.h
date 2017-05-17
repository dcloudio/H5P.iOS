/*
 *------------------------------------------------------------------
 *  pandora/feature/PGGeolocation.h
 *  Description:
 *      位置服务器头文件定义
 *      负责和js层代码交互，js native层对象维护
 *  @copyright
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *   distributed with this work for additional information
 *   regarding copyright ownership.  The ASF licenses this file
 *   to you under the Apache License, Version 2.0 (the
 *   "License"); you may not use this file except in compliance
 *   with the License.  You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 *   Unless required by applicable law or agreed to in writing,
 *   software distributed under the License is distributed on an
 *   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *   KIND, either express or implied.  See the License for the
 *   specific language governing permissions and limitations
 *  under the License.
 *  Changelog:
 *	number	author	modify date modify record

 *------------------------------------------------------------------
 */

#import <CoreLocation/CoreLocation.h>

#import "PGPlugin.h"
#import "PGMethod.h"

//typedef NSInteger PGHeadingStatus;

typedef NS_ENUM(NSInteger, PGLocationCoorType) {
    PGLocationCoorTypeGPS, //表示WGS-84坐标
    PGLocationCoorTypeGCJ02, //表示国测局经纬度坐标系
    PGLocationCoorTypeBD09, //表示百度墨卡托坐标系
    PGLocationCoorTypeBD09LL //表示百度经纬度坐标系
};
//NSLocationWhenInUseUsageDescription 允许在前台使用时获取GPS的描述
//NSLocationAlwaysUsageDescription 允许永远可获取GPS的描述
typedef NS_ENUM(NSInteger, PGLocationDescription) {
    PGLocationDescriptionWhenInUse,
    PGLocationDescriptionAlwaysUsage
};

enum {
    PGLocationErrorLocationNoEnabled = PGPluginErrorNext,
    PGLocationErrorPERMISSIONDENIED,
    PGLocationErrorNotSupportProvider,
    PGLocationErrorNotSupportCoordType,
    PGLocationErrorUnableGetLocation
};
@class PGLocationAddress;
@class PGLocationServer;
@protocol PGLocationServerDelegete <NSObject>
- (void)locationServer:(PGLocationServer*)manager
    didUpdateLocations:(NSArray *)locations;
- (void)locationServer:(PGLocationServer*)manager didFailWithError:(NSError*)error;
- (void)locationServer:(PGLocationServer*)manager geocodeCompletion:(PGLocationAddress *) placemark;
@end

@protocol PGLocationServer <NSObject>
@property(nonatomic, copy)NSString *providerName;
@property (nonatomic, assign) id<PGLocationServerDelegete> delegate;

- (BOOL)isLocationServicesEnabled;
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

@interface PGLocationAddress : NSObject
@property(nonatomic, copy)NSString *country;
@property(nonatomic, copy)NSString *province;
@property(nonatomic, copy)NSString *city;
@property(nonatomic, copy)NSString *district;
@property(nonatomic, copy)NSString *street;
@property(nonatomic, copy)NSString *streetNum;
@property(nonatomic, copy)NSString *poiName;
@property(nonatomic, copy)NSString *postalCode;
@property(nonatomic, copy)NSString *cityCode;
@property(nonatomic, copy)NSString *addresses;
- (NSDictionary*)toJSObject:(BOOL)isNull;
@end

@interface PGLocationReqest : NSObject
@property(nonatomic, copy)NSString *providerType;
@property(nonatomic, copy)NSString *JSResponseId;
@property(nonatomic, assign)BOOL isWatchReq;
@property(nonatomic, copy)NSString *watchId;
@property(nonatomic, copy)NSString *coordType;
@property(nonatomic, assign)BOOL isGeocode;
@end

@interface PGLocationReqestSet : NSObject {
    NSMutableDictionary *_locationReq;
}
-(void)addLocationRequest:(PGLocationReqest*)request;
-(void)removeLocationRequest:(PGLocationReqest*)request;
-(PGLocationReqest*)getRequestByWathId:(NSString*)watchId;
-(NSArray*)getLocationReq:(NSString*)providerType;
-(BOOL)isReqEmpty:(NSString*)providerType;
@end

/*
 **PGGeolocation
 */
@interface PGGeolocation : PGPlugin <PGLocationServerDelegete>{
    PGLocationReqestSet *_locationReqSet;
    NSMutableDictionary *_locationServerProviders;
    BOOL _allowsBackgroundLocationUpdates;
    PGLocationDescription _loationDescription;
}
- (PGLocationServer*)getLocationServerPorvider:(NSString*)provider;
- (void)getCurrentPosition:(PGMethod*)command;
- (void)watchPosition:(PGMethod*)command;
- (void)clearWatch:(PGMethod*)command;
- (void)reverseGeocodeLocation:(PGLocationServer*)manager;
@end
