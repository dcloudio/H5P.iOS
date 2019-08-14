//
//  DCMap.h
//  AMapImp
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCMapProtocol.h"
#import <MAMapKit/MAMapKit.h>
#import "WeexSDK.h"

typedef void(^DCMapEventhandle)(NSString * _Nullable event,NSDictionary * _Nullable params);

NS_ASSUME_NONNULL_BEGIN

@interface DCMap : NSObject <DCMapProtocol, MAMapViewDelegate>

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, copy, nullable) DCMapEventhandle eventHandle;
@property (nonatomic, weak) WXSDKInstance *weexInstance;

@end

NS_ASSUME_NONNULL_END
