//
//  AMapLocationPlugin.h
//  AMapLocationPlugin
//
//  Created by dcloud on 2019/1/25.
//  Copyright © 2019 dcloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGGeolocation.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface PGLocationAMap : PGLocationServer<PGLocationServer,AMapLocationManagerDelegate> {
@private BOOL __locationStarted;
@private BOOL __highAccuracyEnabled;
}
@property (nonatomic, retain) AMapLocationManager* locationManager;
@end
//
@interface PGAMapAddress : PGLocationAddress
+ (id)addressWithGeoCodeResult:(AMapLocationReGeocode*)geoCodeResult;
@end
