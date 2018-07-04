//
//  PGLocationServerManager.m
//  libGeolocation
//
//  Created by DCloud on 2018/3/1.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "PGLocationServerManager.h"

@implementation PGLocationServerManager
+ (PGLocationServer*)getLocationServerPorvider:(NSString*)provider {
    NSDictionary *g_support_provider = @{@"system" : @"PGSystemLocationServer",
                                                      @"baidu"  : @"PGLocationBaidu"};
    if ( [provider isKindOfClass:[NSNull class]] ) {
        provider = @"system";
    }
    if ( [provider isKindOfClass:[NSString class]]) {
        provider = [provider lowercaseString];
        NSString *providerServerName = [g_support_provider objectForKey:provider];
        PGLocationServer *providerServer = nil;
        if ( providerServerName ) {
            providerServer = [[[NSClassFromString(providerServerName) alloc] init] autorelease];
            if ( providerServer ){
                providerServer.providerName = provider;
            }
        }
        return providerServer;
    }
    return nil;
}

+ (PGLocationServer*)getLocationServer {
    BOOL allowsBackgroundLocationUpdates = NO;
    NSArray *UIBackgroundModes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIBackgroundModes"];
    if ( [UIBackgroundModes isKindOfClass:[NSArray class]] ) {
        for ( NSString*item in UIBackgroundModes ) {
            if ( [@"location" isEqualToString:item] ) {
                allowsBackgroundLocationUpdates = YES;
                break;
            }
        }
    }
    PGLocationDescription loationDescription = PGLocationDescriptionWhenInUse;
    NSString *description = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSLocationAlwaysUsageDescription"];
    if ( description ) {
        loationDescription = PGLocationDescriptionAlwaysUsage;
    }
    
    PGLocationServer *locationService = [PGLocationServerManager getLocationServerPorvider:@"baidu"];
    if ( !locationService ) {
        locationService = [PGLocationServerManager getLocationServerPorvider:@"system"];
    }
    locationService.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
    locationService.locationDescription = loationDescription;
    return locationService;
}

@end

@interface PGLocationHelper()<PGLocationServerDelegete>
@property(nonatomic, retain)PGLocationServer *locationServer;
@property(nonatomic, copy)LocationResult block;
@property(nonatomic, retain)NSString *coorsTypeValue;
@property(nonatomic, retain)NSTimer *timeoutTimer;
@end

@implementation PGLocationHelper
+ (void)getLocationTestAuthentication:(BOOL)testAuthentication withReslutBlock:(LocationResult)block {
    if ( testAuthentication ) {
        CLAuthorizationStatus as = [CLLocationManager authorizationStatus];
        if ( kCLAuthorizationStatusAuthorized == as
            ||kCLAuthorizationStatusAuthorizedWhenInUse == as
            || kCLAuthorizationStatusAuthorizedAlways == as ) {
        } else {
            block(nil,nil);
            return;
        }
    }
    PGLocationHelper *helper = [[PGLocationHelper alloc] init];
    helper.block = block;
    PGLocationServer *locationServer = [PGLocationServerManager getLocationServer];
    helper.locationServer = locationServer;
    helper.coorsTypeValue = [locationServer getDefalutCoorType];
    locationServer.delegate = helper;
    [locationServer startLocation:YES];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5 target:helper selector:@selector(timeoutTimer:) userInfo:nil repeats:NO];
    helper.timeoutTimer = timer;
}

- (void)timeoutTimer:(NSTimer*)timer {
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.block(nil, nil);
    [self destory];
}

- (void)locationServer:(PGLocationServer*)manager
    didUpdateLocations:(NSArray *)locations {
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    if ( [locations count] ) {
        CLLocation *location = [locations objectAtIndex:0];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@(location.coordinate.latitude) forKey:@"lat"];
        [dict setObject:@(location.coordinate.longitude) forKey:@"lon"];
        CLLocationAccuracy Accuracy = MAX(location.verticalAccuracy, location.horizontalAccuracy);
        [dict setObject:@(Accuracy) forKey:@"accuracy"];
        [dict setObject:self.coorsTypeValue?self.coorsTypeValue:@"" forKey:@"type"];
        [dict setObject:@([[NSDate date] timeIntervalSince1970] * 1000) forKey:@"ts"];
        self.block(dict, nil);
    } else {
        self.block(nil, nil);
    }
    [self destory];
}

- (void)locationServer:(PGLocationServer*)manager didFailWithError:(NSError*)error {
    self.block(nil, error);
    [self destory];
}

- (void)destory {
    self.block = nil;
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    [self.locationServer stopLocation];
    [self release];
}

- (void)dealloc {
    self.coorsTypeValue = nil;
    self.locationServer = nil;
    self.timeoutTimer = nil;
    self.block = nil;
    [super dealloc];
}
@end

