//
//  PGLocationServer.m
//  libGeolocation
//
//  Created by DCloud on 2018/3/1.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "PGLocationServer.h"

@implementation PGLocationServer
@synthesize  providerName;
@synthesize delegate;
@synthesize allowsBackgroundLocationUpdates;

- (BOOL)isLocationServicesEnabled
{
    return [CLLocationManager locationServicesEnabled];
}

- (BOOL)isLocationServiceValid{
    return YES;
}
- (NSString*)getDefalutCoorType{return @"wgs84";}
- (NSString*)getSupportCoorType:(NSString*)coorType {return nil;}

- (void)startLocation:(BOOL)enableHighAccuracy {}
- (void)stopLocation {}
- (void)reverseGeocodeLocation:(CLLocation*)location {}
+ (CLAuthorizationStatus)authorizedStatus {
    return [CLLocationManager authorizationStatus];
}

- (void)addLocations:(NSArray*)locations {
    if ( !_reverseLocations ) {
        _reverseLocations = [[NSMutableArray alloc] init];
    }
    [_reverseLocations addObjectsFromArray:locations];
}

- (id)getFirstLocation {
    if ( [_reverseLocations count]) {
        return [_reverseLocations objectAtIndex:0];
    }
    return nil;
}

- (void)removeFirstLocation {
    if ( [_reverseLocations count]) {
        [_reverseLocations removeObjectAtIndex:0];
    }
}

- (void)removeAllLocation{
    [_reverseLocations removeAllObjects];
}

- (void)dealloc {
    [_reverseLocations release];
    [super dealloc];
}
@end
