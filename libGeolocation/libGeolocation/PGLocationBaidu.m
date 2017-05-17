//
//  PGLocationBaidu.m
//  libGeolocation
//
//  Created by X on 15/7/3.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import "PGLocationBaidu.h"
#import "PGBaiduKeyVerify.h"

@implementation PGLocationBaidu
//@synthesize locationManager;
@synthesize providerName;
@synthesize delegate;
- (id)init {
    if ( self = [super init] ) {
        __locationStarted = NO;
        __highAccuracyEnabled = NO;
     //   self.locationManager = [[[BMKLocationService alloc] init] autorelease];
        //self.locationManager.delegate = self; // Tells the location manager to send updates to this object
    }
    return self;
}

- (NSString*)getSupportCoorType:(NSString*)coorType {
    if ( [coorType isKindOfClass:[NSNull class]] ) {
        coorType = @"bd09ll";
    }
    if ( [coorType isKindOfClass:[NSString class]]) {
        if ( NSOrderedSame == [@"bd09ll" caseInsensitiveCompare:coorType] ) {
            return coorType;
        }
    }
    return nil;
}

- (void)startLocation:(BOOL)enableHighAccuracy
{
//    [self.locationManager stopUserLocationService];
//    [self.locationManager startUserLocationService];
//    self.locationManager.delegate = self;
    [[BMKLocationServiceWrap sharedLocationServer] addObserver:self];
    __locationStarted = YES;
    if (enableHighAccuracy) {
        __highAccuracyEnabled = YES;
        [BMKLocationServiceWrap sharedLocationServer].locationService.distanceFilter = kCLDistanceFilterNone;
        [BMKLocationServiceWrap sharedLocationServer].locationService.desiredAccuracy = kCLLocationAccuracyBest;
      //  [BMKLocationService setLocationDistanceFilter:kCLDistanceFilterNone];
       // [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyBest];
    } else {
        __highAccuracyEnabled = NO;
        [BMKLocationServiceWrap sharedLocationServer].locationService.distanceFilter = 10;
        [BMKLocationServiceWrap sharedLocationServer].locationService.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        // TODO: Set distance filter to 10 meters? and desired accuracy to nearest ten meters? arbitrary.
      //  [BMKLocationService setLocationDistanceFilter:10];
      //  [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    }
    [BMKLocationServiceWrap sharedLocationServer].locationService.pausesLocationUpdatesAutomatically = NO;
    if ( self.allowsBackgroundLocationUpdates ) {
        [BMKLocationServiceWrap sharedLocationServer].locationService.allowsBackgroundLocationUpdates = self.allowsBackgroundLocationUpdates;
    }
}

- (void)stopLocation
{
    if (__locationStarted) {
        if (![self isLocationServicesEnabled]) {
            return;
        }
        [[BMKLocationServiceWrap sharedLocationServer] removeObserver:self];
       // [self.locationManager stopUserLocationService];
        __locationStarted = NO;
        __highAccuracyEnabled = NO;
    }
}

/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    if ( [self.delegate respondsToSelector:@selector(locationServer:didUpdateLocations:)] ) {
        [self.delegate locationServer:self didUpdateLocations:[NSArray arrayWithObjects:userLocation.location, nil]];
    }
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error {
//    [self.locationManager stopUserLocationService];
    [[BMKLocationServiceWrap sharedLocationServer] removeObserver:self];
    __locationStarted = NO;
    NSError *newError = [NSError errorWithDomain:@"PGLocation"
                                            code:PGLocationErrorUnableGetLocation
                                        userInfo:@{NSLocalizedDescriptionKey:@"不能获取到位置"}];
    if ( [self.delegate respondsToSelector:@selector(locationServer:didFailWithError:)] ) {
        [self.delegate locationServer:self didFailWithError:newError];
    }
}

- (void)reverseGeocodeLocation:(CLLocation*)location {
    if ( !_geoSearch && E_PERMISSION_OK == [PGBaiduKeyVerify Verify].errorCode){
        _geoSearch = [[BMKGeoCodeSearch alloc] init];
        _geoSearch.delegate = self;
        BMKReverseGeoCodeOption *geoOption = [[[BMKReverseGeoCodeOption alloc] init] autorelease];
        geoOption.reverseGeoPoint = location.coordinate;
        [_geoSearch reverseGeoCode:geoOption];
    } else {
        [self onGetReverseGeoCodeResult:_geoSearch result:nil errorCode:BMK_SEARCH_RESULT_NOT_FOUND];
    }
}

/**
 *返回反地理编码搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结果
 *@param error 错误号，@see BMKSearchErrorCode
 */
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher
                           result:(BMKReverseGeoCodeResult *)result
                        errorCode:(BMKSearchErrorCode)error{
    _geoSearch.delegate = nil;
    [_geoSearch release];
    _geoSearch = nil;
    if ( [self.delegate respondsToSelector:@selector(locationServer:geocodeCompletion:)] ) {
        PGBaiduAddress *address = [PGBaiduAddress addressWithGeoCodeResult:result];
        NSError *errorObj = nil;
        if ( BMK_SEARCH_NO_ERROR == error ) {
            
        } else {
            errorObj = [NSError errorWithDomain:@"" code:error userInfo:nil];
        }
        [self.delegate locationServer:self geocodeCompletion:errorObj?nil:address];
    }
}


- (void)dealloc
{
    _geoSearch.delegate = nil;
    [_geoSearch release];
  //  [self.locationManager stopUserLocationService];
  //  self.locationManager.delegate = nil;
 //   self.locationManager = nil;
    [[BMKLocationServiceWrap sharedLocationServer] removeObserver:self];
    [super dealloc];
}

@end

@implementation PGBaiduAddress
+ (id)addressWithGeoCodeResult:(BMKReverseGeoCodeResult*)geoCodeResult {
    PGBaiduAddress *address = [[[PGBaiduAddress alloc] initWithGeoCodeResult:geoCodeResult] autorelease];
    return address;
}

- (id)initWithGeoCodeResult:(BMKReverseGeoCodeResult*)geoCodeResult {
    if ( self = [super init] ) {
        
        self.country = nil;
        self.province = geoCodeResult.addressDetail.province;
        self.city = geoCodeResult.addressDetail.city;
        self.district = geoCodeResult.addressDetail.district;
        self.street = geoCodeResult.addressDetail.streetName;
        self.streetNum = geoCodeResult.addressDetail.streetNumber;
        
        self.poiName = nil;
        if ( [geoCodeResult.poiList count] ) {
            BMKPoiInfo *poiInfo = [geoCodeResult.poiList objectAtIndex:0];
            self.poiName = poiInfo.name;
        }
        self.addresses = geoCodeResult.address;
        self.postalCode = geoCodeResult.addressDetail.streetNumber;
        self.postalCode = nil;
        self.cityCode = nil;
    }
    return self;
}

@end




