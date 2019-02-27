//
//  PGLocationSystem.m
//  libGeolocation
//
//  Created by X on 15/7/6.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import "PGLocationSystem.h"

#pragma mark -
#pragma mark PGSystemLocationServer
@implementation PGSystemLocationServer
@synthesize locationManager;
@synthesize providerName;
@synthesize delegate;
- (id)init {
    if ( self = [super init] ) {
        __locationStarted = NO;
        __highAccuracyEnabled = NO;
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object
    }
    return self;
}

- (BOOL)isAuthorized
{
    BOOL authorizationStatusClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
    
    if (authorizationStatusClassPropertyAvailable) {
        NSUInteger authStatus = [CLLocationManager authorizationStatus];
        return (authStatus == kCLAuthorizationStatusAuthorized)
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_0
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_0
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
        || (authStatus == kCLAuthorizationStatusAuthorizedAlways)
        || (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse)
#endif
#endif
#endif
#endif
        || (authStatus == kCLAuthorizationStatusNotDetermined);
    }
    
    // by default, assume YES (for iOS < 4.2)
    return YES;
}

- (NSString*)getSupportCoorType:(NSString*)coorType {
    if ( [coorType isKindOfClass:[NSNull class]] ) {
        coorType = @"wgs84";
    }
    if ( [coorType isKindOfClass:[NSString class]]) {
        if ( NSOrderedSame == [@"wgs84" caseInsensitiveCompare:coorType] ) {
            return coorType;
        }
    }
    return nil;
}

- (void)startLocation:(BOOL)enableHighAccuracy
{
    if (![self isAuthorized]) {
        NSString* message = @"";
        BOOL authStatusAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
        if ( authStatusAvailable ) {
            NSUInteger code = [CLLocationManager authorizationStatus];
            if (code == kCLAuthorizationStatusNotDetermined) {
                // could return POSITION_UNAVAILABLE but need to coordinate with other platforms
                message = @"User undecided on application's use of location services.";
            } else if (code == kCLAuthorizationStatusRestricted) {
                message = @"Application's use of location services is restricted.";
            } else if (code == kCLAuthorizationStatusDenied){
                message = @"User has explicitly denied authorization for this application";
            }
        }
        NSError *error = [NSError errorWithDomain:@"PGLocation"
                                             code:PGLocationErrorPERMISSIONDENIED
                                         userInfo:@{NSLocalizedDescriptionKey:message}];
        if ( [self.delegate respondsToSelector:@selector(locationServer:didFailWithError:)] ) {
            [self.delegate locationServer:self didFailWithError:error];
        }
        return;
    }
    [self.locationManager stopUpdatingLocation];
    
    if ( [self.locationManager respondsToSelector:@selector(setPausesLocationUpdatesAutomatically:)] ) {
        [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    }
    
    if ([[UIDevice currentDevice].systemVersion floatValue] > 9
        && self.allowsBackgroundLocationUpdates )
    {
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }

    __locationStarted = YES;
    if (enableHighAccuracy) {
        __highAccuracyEnabled = YES;
        // Set to distance filter to "none" - which should be the minimum for best results.
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        // Set desired accuracy to Best.
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    } else {
        __highAccuracyEnabled = NO;
        // TODO: Set distance filter to 10 meters? and desired accuracy to nearest ten meters? arbitrary.
        self.locationManager.distanceFilter = 10;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
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

- (void)reverseGeocodeLocation:(CLLocation*)location {
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    __block PGSystemLocationServer *weakSelf = self;
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if ( [weakSelf.delegate respondsToSelector:@selector(locationServer:geocodeCompletion:error:)] ) {
            PGLocationAddress *address = nil;
            if ( [placemarks count] ) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                address = [PGSystemLocationAddress addressWithCLPlacemark:placemark];
            }
            [weakSelf.delegate locationServer:self geocodeCompletion:error?nil:address error:error];
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        {
            SEL aSelector = (PGLocationDescriptionAlwaysUsage == self.locationDescription)? @selector(requestAlwaysAuthorization) : @selector(requestWhenInUseAuthorization);
            if ([locationManager respondsToSelector:aSelector]) {
                [self.locationManager performSelector:aSelector];
            }
        }
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    if ( [self.delegate respondsToSelector:@selector(locationServer:didUpdateLocations:)] ) {
        [self.delegate locationServer:self didUpdateLocations:locations];
    }
}

- (void)locationManager:(CLLocationManager*)manager
    didUpdateToLocation:(CLLocation*)newLocation
           fromLocation:(CLLocation*)oldLocation
{
    [self locationManager:manager didUpdateLocations:[NSArray arrayWithObjects:newLocation, nil]];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    [self.locationManager stopUpdatingLocation];
    __locationStarted = NO;
    
    NSError *newError = [NSError errorWithDomain:@"PGLocation"
                                         code:PGLocationErrorUnableGetLocation
                                     userInfo:@{NSLocalizedDescriptionKey:@"不能获取到位置"}];
    if ( [self.delegate respondsToSelector:@selector(locationServer:didFailWithError:)] ) {
        [self.delegate locationServer:self didFailWithError:newError];
    }
}

- (void)dealloc
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
    [super dealloc];
}

@end

@implementation PGSystemLocationAddress

-(PGSystemLocationAddress*)initWithCLPlacemark:(CLPlacemark*)placeMark {
    if ( self = [super init] ) {
        self.country = placeMark.country;
        self.province = placeMark.administrativeArea;
        self.city = placeMark.locality;
        self.district = placeMark.subLocality;
        self.street = placeMark.thoroughfare;
        self.poiName = nil;
        self.postalCode = placeMark.postalCode;
        self.cityCode = nil;
        self.streetNum = placeMark.subThoroughfare;
        self.addresses = placeMark.name;
    }
    return self;
}

+ (PGSystemLocationAddress*)addressWithCLPlacemark:(CLPlacemark*)placeMark {
    PGSystemLocationAddress *address = [[[PGSystemLocationAddress alloc] initWithCLPlacemark:placeMark] autorelease];
    return address;
}

@end

