//
//  PGBaiduKeyVerify.h
//  PGBaiduKeyVerify
//
//  Created by X on 15/7/6.
//  Copyright (c) 2015年 io.dcloud.baiduKeyVerify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Base/BMKMapManager.h>
#import <BaiduMapAPI_Base/BMKGeneralDelegate.h>
#import <BaiduMapAPI_Base/BMKTypes.h>
#import <BaiduMapAPI_Location/BMKLocationService.h>
#import "PDRCoreDefs.h"

typedef enum {
    PGBKErrorCodeNotConfig = -1
}PGBKErrorCode;

@interface PGBaiduKeyVerify : H5Server<BMKGeneralDelegate>{
    BMKMapManager *_mapManager;
}
@property(nonatomic, retain)NSString *appKey;
@property(nonatomic, assign)int errorCode;
+(PGBaiduKeyVerify*)Verify;
- (NSString*)errorMessage;
@end

@interface BMKLocationServiceWrap : NSObject<BMKLocationServiceDelegate> {
    NSMutableArray *_observers;
    BMKLocationService *_locationService;
}
@property(nonatomic, readonly)BMKLocationService *locationService;
+(BMKLocationServiceWrap*)sharedLocationServer;
- (void)addObserver:(id<BMKLocationServiceDelegate>)observer;
- (void)removeObserver:(id<BMKLocationServiceDelegate>)observer;
@end