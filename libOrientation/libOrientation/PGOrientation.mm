/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "PGOrientation.h"

@interface PGOrientation () {}
@property (readwrite, assign) BOOL isRunning;
@end

@implementation PGOrientation

@synthesize callbackId, isRunning, locationManager;

// defaults to 10 msec
#define kAccelerometerInterval 40
// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81

- (PGOrientation*)init
{
    self = [super init];
    if (self) {
        x = 0;
        y = 0;
        z = 0;
        magneticHeading = 0;
        trueHeading = 0;
        headingAccuracy = 0;
        
        self.callbackId = nil;
        self.isRunning = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stop:nil];
    [super dealloc];
}

- (void)start:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *cbId = [command.arguments objectAtIndex:0];
    
    if ([self hasHeadingSupport] == NO) {
        PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:20];
        [self toCallback:cbId  withReslut:[result toJSONString]];
        return;
    }
    if ( nil == self.locationManager ) {
        [self startHeadingWithFilter:0.2];
    }
    self.callbackId = cbId;
    if (!self.isRunning) {
        self.locationManager.delegate = self;
        self.isRunning = YES;
    }
}

- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(PGMethod*)command
{
    [self stopHeading];
    self.isRunning = NO;
}

- (void)startHeadingWithFilter:(CLLocationDegrees)filter
{
    CLLocationManager *lm = [[CLLocationManager alloc] init];
    self.locationManager = lm;
    [lm release];
    self.locationManager.headingOrientation = (CLDeviceOrientation)[self rootViewController].interfaceOrientation;
    self.locationManager.headingFilter = filter;
    [self.locationManager startUpdatingHeading];
}

- (void)stopHeading {
    self.locationManager.delegate = nil;
    [self.locationManager stopUpdatingHeading];
    self.locationManager = nil;
}

- (BOOL)hasHeadingSupport
{
    BOOL headingInstancePropertyAvailable = [self.locationManager respondsToSelector:@selector(headingAvailable)]; // iOS 3.x
    BOOL headingClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(headingAvailable)]; // iOS 4.x
    
    if (headingInstancePropertyAvailable) { // iOS 3.x
        return [(id)self.locationManager headingAvailable];
    } else if (headingClassPropertyAvailable) { // iOS 4.x
        return [CLLocationManager headingAvailable];
    } else { // iOS 2.x
        return NO;
    }
}

- (void)locationManager:(CLLocationManager*)manager
       didUpdateHeading:(CLHeading*)heading
{
    if (self.isRunning) {
        x = heading.x;
        y = heading.y;
        z = heading.z;
        magneticHeading = heading.magneticHeading;
        trueHeading = heading.trueHeading;
        headingAccuracy = heading.headingAccuracy;
        [self returnAccelInfo];
    }
}

- (void)locationManager:(CLLocationManager*)manager
       didFailWithError:(NSError*)error {
    // Compass Error
    if ([error code] == kCLErrorHeadingFailure) {

    }
}

- (void)returnAccelInfo
{
    // Create an acceleration object
    NSMutableDictionary* accelProps = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [accelProps setValue:[NSNumber numberWithDouble:x * kGravitationalConstant] forKey:@"alpha"];
    [accelProps setValue:[NSNumber numberWithDouble:y * kGravitationalConstant] forKey:@"beta"];
    [accelProps setValue:[NSNumber numberWithDouble:z * kGravitationalConstant] forKey:@"gamma"];
    [accelProps setValue:[NSNumber numberWithDouble:magneticHeading] forKey:@"magneticHeading"];
    [accelProps setValue:[NSNumber numberWithDouble:trueHeading] forKey:@"trueHeading"];
    [accelProps setValue:[NSNumber numberWithDouble:headingAccuracy] forKey:@"headingAccuracy"];
    
    PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:accelProps];
    [result setKeepCallback:YES];
    [self toCallback:self.callbackId  withReslut:[result toJSONString]];
}

// TODO: Consider using filtering to isolate instantaneous data vs. gravity data -jm

/*
 #define kFilteringFactor 0.1
 
 // Use a basic low-pass filter to keep only the gravity component of each axis.
 grav_accelX = (acceleration.x * kFilteringFactor) + ( grav_accelX * (1.0 - kFilteringFactor));
 grav_accelY = (acceleration.y * kFilteringFactor) + ( grav_accelY * (1.0 - kFilteringFactor));
 grav_accelZ = (acceleration.z * kFilteringFactor) + ( grav_accelZ * (1.0 - kFilteringFactor));
 
 // Subtract the low-pass value from the current value to get a simplified high-pass filter
 instant_accelX = acceleration.x - ( (acceleration.x * kFilteringFactor) + (instant_accelX * (1.0 - kFilteringFactor)) );
 instant_accelY = acceleration.y - ( (acceleration.y * kFilteringFactor) + (instant_accelY * (1.0 - kFilteringFactor)) );
 instant_accelZ = acceleration.z - ( (acceleration.z * kFilteringFactor) + (instant_accelZ * (1.0 - kFilteringFactor)) );
 
 
 */
@end
