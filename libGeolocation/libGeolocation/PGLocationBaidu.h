//
//  PGLocationBaidu.h
//  libGeolocation
//
//  Created by X on 15/7/3.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGGeolocation.h"
#import <BaiduMapAPI_Location/BMKLocationService.h>
#import <BaiduMapAPI_Search/BMKGeocodeSearch.h>
#import <BaiduMapAPI_Search/BMKPoiSearchType.h>

@interface PGLocationBaidu : PGLocationServer<PGLocationServer,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate> {
@private BOOL __locationStarted;
@private BOOL __highAccuracyEnabled;
    BMKGeoCodeSearch *_geoSearch;
}
//@property(nonatomic, copy)NSString *providerName;
//@property (nonatomic, assign) id<PGLocationServerDelegete> delegate;
//@property (nonatomic, retain) BMKLocationService* locationManager;
//- (NSString*)getSupportCoorType:(NSString*)coorType;
///- (void)startLocation:(BOOL)enableHighAccuracy;
//- (void)stopLocation;
//- (void)reverseGeocodeLocation:(CLLocation*)location;
//- (BOOL)isLocationServicesEnabled;
@end

@interface PGBaiduAddress : PGLocationAddress
+ (id)addressWithGeoCodeResult:(BMKReverseGeoCodeResult*)geoCodeResult;
@end