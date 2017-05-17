//
//  PGBaiduKeyVerify.m
//  PGBaiduKeyVerify
//
//  Created by X on 15/7/6.
//  Copyright (c) 2015年 io.dcloud.baiduKeyVerify. All rights reserved.
//

#import "PGBaiduKeyVerify.h"
#import "PDRCorePrivate.h"

@implementation PGBaiduKeyVerify
@synthesize errorCode;

- (id)init {
    if ( self = [super init] ) {
        self.errorCode = E_PERMISSION_OK;
        NSDictionary *mapInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"baidu"];
        if ( [mapInfo isKindOfClass:[NSDictionary class]] ) {
            NSString *tempAK = [mapInfo objectForKey:@"appkey"];
            if ( [tempAK isKindOfClass:[NSString class]] ) {
                self.appKey = tempAK;
            } else {
                self.errorCode = PGBKErrorCodeNotConfig;
            }
        }
        if ( self.appKey ) {
            [self start];
        }
    }
    return self;
}

- (BOOL)start{
    if ( !_mapManager ) {
        _mapManager = [[BMKMapManager alloc]init];
        return [_mapManager start:self.appKey generalDelegate:self];
    }
    return TRUE;
}

- (BOOL)stop {
    BOOL ret = TRUE;
    if ( _mapManager ) {
        ret = [_mapManager stop];
        _mapManager = nil;
    }
    return ret;
}

+(PGBaiduKeyVerify*)Verify {
    return [[PDRCore Instance] getServerByIdentifier:@"com.baidu.keyverify"];
}

/**
 *返回网络错误
 *@param iError 错误号
 */
- (void)onGetNetworkState:(int)iError{
    
}

/**
 *返回授权验证错误
 *@param iError 错误号 : BMKErrorPermissionCheckFailure 验证失败
 */
- (void)onGetPermissionState:(int)iError {
    self.errorCode = iError;
    if ( E_PERMISSION_OK != iError ) {
        NSLog(@"baidu maponGetPermissionState--[%d]", iError);
    }
}

- (NSString*)errorMessage {
    switch (self.errorCode) {
        case PGBKErrorCodeNotConfig:
            return @"配置的appkey错误";
        case E_PERMISSIONCHECK_KEY_FORBIDEN:
            return @"APP被用户自己禁用，请在控制台解禁";
        case E_PERMISSIONCHECK_UID_KEY_ERROR:
            return @"配置的appkey,找不到对应的APP,请确保Bundle identifier和appkey配置对应";
        case E_PERMISSIONCHECK_CONNECT_ERROR:
            return @"链接服务器错误";
        case E_PERMISSIONCHECK_DATA_ERROR:
            return @"服务返回数据异常";
        case E_PERMISSIONCHECK_KEY_ERROR:
            return @"appkey不存在";
        default:
            break;
    }
    return [NSString stringWithFormat:@"错误码:%d,详情请参考:http://developer.baidu.com/map/index.php?title=lbscloud/api/appendix",self.errorCode];
}

-(void)dealloc {
    [self stop];
    self.appKey = nil;
    [super dealloc];
}
@end

static BMKLocationServiceWrap *g_locationService = nil;

@implementation BMKLocationServiceWrap
@synthesize locationService = _locationService;
+(BMKLocationServiceWrap*)sharedLocationServer {
    @synchronized(self) {
        if ( ! g_locationService ) {
            g_locationService = [[BMKLocationServiceWrap alloc] init];
        }
    }
    return g_locationService;
}

- (void)addObserver:(NSObject *)observer {
    if ( observer ) {
        if ( nil == _observers ) {
            _observers = [[NSMutableArray alloc] init];
        }
        if ( ![_observers containsObject:observer] ) {
            [_observers addObject:observer];
        }
        [self startUserLocationService];
    }
}

- (void)removeObserver:(NSObject *)observer {
    if ( observer && _observers ) {
        [_observers removeObject:observer];
        if ( 0 == [_observers count] ) {
            [self stopUserLocationService];
        }
    }
}

- (void)startUserLocationService {
    if ( nil == _locationService ) {
        _locationService = [[BMKLocationService alloc] init];
        _locationService.delegate = self;
    }
    [_locationService stopUserLocationService];
    [_locationService startUserLocationService];
}

- (void)stopUserLocationService {
    if ( _locationService ) {
        [_locationService stopUserLocationService];
        _locationService.delegate = nil;
        [_locationService release];
        _locationService = nil;
    }
}

/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    for ( id<BMKLocationServiceDelegate> delegate in _observers ) {
        if ( [delegate respondsToSelector:@selector(didUpdateBMKUserLocation:)] ) {
            [delegate performSelector:@selector(didUpdateBMKUserLocation:) withObject:userLocation];
        }
    }
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error {
    for ( id<BMKLocationServiceDelegate> delegate in _observers ) {
        if ( [delegate respondsToSelector:@selector(didFailToLocateUserWithError:)] ) {
            [delegate performSelector:@selector(didFailToLocateUserWithError:) withObject:error];
        }
    }
}

- (void)dealloc {
    [_observers removeAllObjects];
    [_observers release];
    _observers = nil;
    [_locationService stopUserLocationService];
    [super dealloc];
}

@end

