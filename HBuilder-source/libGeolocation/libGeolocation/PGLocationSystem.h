//
//  PGLocationSystem.h
//  libGeolocation
//
//  Created by X on 15/7/6.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGGeolocation.h"

@interface PGSystemLocationServer : PGLocationServer<PGLocationServer,CLLocationManagerDelegate> {
@private BOOL __locationStarted;
@private BOOL __highAccuracyEnabled;
}
@property (nonatomic, retain) CLLocationManager* locationManager;
@end

@interface PGSystemLocationAddress : PGLocationAddress
+ (PGSystemLocationAddress*)addressWithCLPlacemark:(CLPlacemark*)placeMark;
@end