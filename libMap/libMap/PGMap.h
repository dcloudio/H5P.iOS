//
//  PGMap.h
//  libMap
//
//  Created by X on 14-5-12.
//  Copyright (c) 2014年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PGPlugin.h"
#import "PGMethod.h"

typedef enum {
    PGMapReqTypeGeocode,
    PGMapReqTypeReverseGeocode
}PGMapGeoReqType;

@interface PGMapGeoReq : NSObject
@property(nonatomic, assign)PGMapGeoReqType reqType;
@property(nonatomic, copy)NSString *city;
@property(nonatomic, copy)NSString *address;
@property(nonatomic, assign)CLLocationCoordinate2D coordinate2D;
@property(nonatomic, copy)NSString *callbackId;
@end


@class PGMapView;
@protocol PGMapPluginDelegate <NSObject>
@required
- (PGMapView*)createMapViewWithArgs:(id)args;
- (id)createOverlayWithUUID:(NSString*)UUID withType:(NSString*)type args:(id)args;
@end

@interface PGMapPlugin : PGPlugin<PGMapPluginDelegate>
{
    @public
    //js中创建的地图字典
    NSMutableDictionary *_nativeObjectDict;
}
@property(nonatomic, readonly)NSDictionary *nativeOjbectDict;

@end
