//
//  AMapLocationPlugin.m
//  AMapLocationPlugin
//
//  Created by dcloud on 2019/1/25.
//  Copyright © 2019 dcloud. All rights reserved.
//

#import "PGLocationAMap.h"

@implementation PGLocationAMap
//@synthesize locationManager;
@synthesize providerName;
@synthesize delegate;
- (id)init {
    if ( self = [super init] ) {
        __locationStarted = NO;
        __highAccuracyEnabled = NO;
        self.locationManager = [[AMapLocationManager alloc] init];
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object
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
    __locationStarted = YES;
    if (enableHighAccuracy) {
        __highAccuracyEnabled = YES;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    } else {
        __highAccuracyEnabled = NO;
        self.locationManager.distanceFilter = 10;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    }
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    if ( self.allowsBackgroundLocationUpdates ) {
        self.locationManager.allowsBackgroundLocationUpdates = self.allowsBackgroundLocationUpdates;
    }
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocation
{
    if (__locationStarted) {
        if (![self isLocationServicesEnabled]) {
            return;
        }

        [self.locationManager stopUpdatingLocation];
        __locationStarted = NO;
        __highAccuracyEnabled = NO;
    }
}

/**
 *用户位置更新后，会调用此函数
 *@param location 新的用户位置
 */
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    if ( [self.delegate respondsToSelector:@selector(locationServer:didUpdateLocations:geocodeCompletion:)] ) {
        PGLocationAddress *address = nil;
        if ( reGeocode ) {
            address = [PGAMapAddress addressWithGeoCodeResult:reGeocode];
        }
        [self.delegate locationServer:self didUpdateLocations:[NSArray arrayWithObjects:location, nil] geocodeCompletion:address];
    }
}
/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error {
    //    [self.locationManager stopUserLocationService];
    __locationStarted = NO;
    NSError *newError = [NSError errorWithDomain:@"PGLocation"
                                            code:PGLocationErrorUnableGetLocation
                                        userInfo:@{NSLocalizedDescriptionKey:@"不能获取到位置"}];
    if ( [self.delegate respondsToSelector:@selector(locationServer:didFailWithError:)] ) {
        [self.delegate locationServer:self didFailWithError:newError];
    }
}

//- (void)reverseGeocodeLocation:(CLLocation*)location {
//    if ( !_geoSearch && E_PERMISSION_OK == [PGBaiduKeyVerify Verify].errorCode){
//        _geoSearch = [[BMKGeoCodeSearch alloc] init];
//        _geoSearch.delegate = self;
//        BMKReverseGeoCodeSearchOption *geoOption = [[BMKReverseGeoCodeSearchOption alloc] init];
//        geoOption.location = location.coordinate;
//        [_geoSearch reverseGeoCode:geoOption];
//    } else {
//        [self onGetReverseGeoCodeResult:_geoSearch result:nil errorCode:[PGBaiduKeyVerify Verify].errorCode];
//    }
//}
//
///**
// *返回反地理编码搜索结果
// *@param searcher 搜索对象
// *@param result 搜索结果
// *@param error 错误号，@see BMKSearchErrorCode
// */
//- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher
//                           result:(BMKReverseGeoCodeSearchResult *)result
//                        errorCode:(BMKSearchErrorCode)error{
//    _geoSearch.delegate = nil;
//    _geoSearch = nil;
//    if ( [self.delegate respondsToSelector:@selector(locationServer:geocodeCompletion:error:)] ) {
//        PGBaiduAddress *address = [PGBaiduAddress addressWithGeoCodeResult:result];
//        NSError *errorObj = nil;
//        if ( BMK_SEARCH_NO_ERROR == error ) {
//            
//        } else {
//            errorObj = [NSError errorWithDomain:@"PGLocation"
//                                           code:error
//                                       userInfo:@{NSLocalizedDescriptionKey:[PGBaiduKeyVerify Verify].errorMessage}];
//        }
//        [self.delegate locationServer:self geocodeCompletion:errorObj?nil:address error:errorObj];
//    }
//}
//
//- (void)dealloc
//{
//    _geoSearch.delegate = nil;
//    //  [self.locationManager stopUserLocationService];
//    //  self.locationManager.delegate = nil;
//    //   self.locationManager = nil;
//    [[BMKLocationServiceWrap sharedLocationServer] removeObserver:self];
//}

@end

@implementation PGAMapAddress
+ (id)addressWithGeoCodeResult:(AMapLocationReGeocode*)geoCodeResult {
    PGAMapAddress *address = [[PGAMapAddress alloc] initWithGeoCodeResult:geoCodeResult];
    return address;
}

- (id)initWithGeoCodeResult:(AMapLocationReGeocode*)geoCodeResult {
    if ( self = [super init] ) {

        self.country = nil;
        self.province = geoCodeResult.province;
        self.city = geoCodeResult.city;
        self.district = geoCodeResult.district;
        self.street = geoCodeResult.street;
        self.streetNum = geoCodeResult.number;
        self.poiName = geoCodeResult.POIName;
        self.addresses = geoCodeResult.formattedAddress;
        self.postalCode = geoCodeResult.adcode;
        self.postalCode = nil;
        self.cityCode = nil;
    }
    return self;
}

@end
