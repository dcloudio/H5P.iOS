/*
 *------------------------------------------------------------------
 *  pandora/feature/PGGeolocation.mm
 *  Description:
 *    位置服务器实现定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-04-07 创建文件
 *------------------------------------------------------------------
*/
#import "PGGeolocation.h"
#import "PDRCoreWindowManager.h"
#import "PDRCommonString.h"
#import <CoreLocation/CoreLocation.h>
#pragma mark Constants

#define kPGLocationErrorDomain @"kPGLocationErrorDomain"
#define kPGLocationDesiredAccuracyKey @"desiredAccuracy"
#define kPGLocationForcePromptKey @"forcePrompt"
#define kPGLocationDistanceFilterKey @"distanceFilter"
#define kPGLocationFrequencyKey @"frequency"

static NSDictionary *g_support_provider =
@{
  @"system" : @"PGSystemLocationServer",
  @"baidu"  : @"PGLocationBaidu",
  @"amap"   : @"PGLocationAMap"
};


@implementation PGLocationAddress : NSObject
@synthesize country;
@synthesize province;
@synthesize city;
@synthesize district;
@synthesize street;
@synthesize streetNum;
@synthesize poiName;
@synthesize postalCode;
@synthesize cityCode;
@synthesize addresses;

- (void)setDict:(NSMutableDictionary*)dict
          value:(id)value
         forKey:(NSString *)key
         isNull:(BOOL)isNull {
    if ( value || isNull) {
        [dict setObject:value ? value:[NSNull null] forKey:key];
    }
}


- (NSDictionary*)toJSObject:(BOOL)isNull {
    NSMutableDictionary *JSObject = [NSMutableDictionary dictionary];
    NSMutableDictionary *addressInfo = [NSMutableDictionary dictionary];
    
    [self setDict:addressInfo value:self.country forKey:@"country" isNull:isNull];
    [self setDict:addressInfo value:self.province forKey:@"province" isNull:isNull];
    [self setDict:addressInfo value:self.city forKey:@"city" isNull:isNull];
    [self setDict:addressInfo value:self.district forKey:@"district" isNull:isNull];
    [self setDict:addressInfo value:self.street forKey:@"street" isNull:isNull];
    [self setDict:addressInfo value:self.poiName forKey:@"poiName" isNull:isNull];
    [self setDict:addressInfo value:self.postalCode forKey:@"postalCode" isNull:isNull];
    [self setDict:addressInfo value:self.cityCode forKey:@"cityCode" isNull:isNull];
    [self setDict:addressInfo value:self.streetNum forKey:@"streetNum" isNull:isNull];
    
    [self setDict:JSObject value:addressInfo forKey:@"address" isNull:isNull];
    [self setDict:JSObject value:self.addresses forKey:@"addresses" isNull:isNull];
    
    return JSObject;
}

- (NSString*)fullAddress{
    NSMutableString *retAddress = [NSMutableString string];
    if ( self.country ) {
       // [retAddress appendString:self.country];
    }
    if ( self.province ) {
        //[retAddress appendString:self.province];
    }
    if ( self.city ) {
        [retAddress appendString:self.city];
    }
    if ( self.district ) {
        [retAddress appendString:self.district];
    }
    if ( self.street ) {
        [retAddress appendString:self.street];
    }
    if ( self.addresses ) {
        [retAddress appendString:self.addresses];
    }
    return retAddress;
}

- (void)dealloc {
    self.country = nil;
    self.province = nil;
    self.city = nil;
    self.district = nil;
    self.street = nil;
    self.streetNum = nil;
    self.poiName = nil;
    self.postalCode = nil;
    self.cityCode = nil;
    [super dealloc];
}

@end

@implementation PGLocationReqest : NSObject
@synthesize providerType;
@synthesize JSResponseId;
@synthesize isWatchReq;
@synthesize watchId;
@synthesize coordType;
@synthesize isGeocode;
- (void)dealloc {
    self.coordType = nil;
    self.watchId = nil;
    self.JSResponseId = nil;
    self.providerType = nil;
    [super dealloc];
}
@end
#pragma mark -
#pragma mark PGLocationReqestSet
@implementation PGLocationReqestSet
-(void)addLocationRequest:(PGLocationReqest*)request {
    if ( !_locationReq ) {
        _locationReq = [[NSMutableDictionary alloc] init];
    }
    if ( request.providerType ) {
        NSMutableArray *reqs = [_locationReq objectForKey:request.providerType];
        if ( !reqs ) {
            reqs = [[NSMutableArray alloc] init];
            [_locationReq setObject:reqs forKey:request.providerType];
            [reqs release];
        }
        [reqs addObject:request];
    }
}

-(void)removeLocationRequest:(PGLocationReqest*)request {
    if ( _locationReq && request.providerType ) {
        NSMutableArray *reqs = [_locationReq objectForKey:request.providerType];
        if ( reqs ) {
            [reqs removeObject:request];
        }
    }
}

-(PGLocationReqest*)getRequestByWathId:(NSString*)watchId {
    __block PGLocationReqest *retReq = nil;
    if ( watchId ) {
        [_locationReq enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSMutableArray *reqs = [_locationReq objectForKey:key];
            [reqs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PGLocationReqest *req = (PGLocationReqest*)obj;
                if ( NSOrderedSame == [req.watchId caseInsensitiveCompare:watchId] ) {
                    retReq = req;
                    *stop = TRUE;
                }
            }];
        }];
    }
    return retReq;
}


-(NSArray*)getLocationReq:(NSString*)providerType {
    if ( _locationReq && providerType ) {
        NSMutableArray *reqs = [_locationReq objectForKey:providerType];
        if ( reqs ) {
            return [NSArray arrayWithArray:reqs];
        }
    }
    return nil;
}

-(BOOL)isReqEmpty:(NSString*)providerType {
    if ( providerType ) {
        NSMutableArray *reqs = [_locationReq objectForKey:providerType];
        return [reqs count] == 0 ? TRUE: FALSE;
    }
    return true;
}

-(void)dealloc {
    [_locationReq release];
    [super dealloc];
}
@end

#pragma mark -
#pragma mark PGGeolocation

@implementation PGGeolocation

-(PGPlugin *)initWithWebView:(PDRCoreAppFrame *)theWebView withAppContxt:(PDRCoreApp *)app {
    if ( self = [super initWithWebView:theWebView withAppContxt:app] ) {
        _allowsBackgroundLocationUpdates = NO;
        NSArray *UIBackgroundModes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIBackgroundModes"];
        if ( [UIBackgroundModes isKindOfClass:[NSArray class]] ) {
            for ( NSString*item in UIBackgroundModes ) {
                if ( [@"location" isEqualToString:item] ) {
                    _allowsBackgroundLocationUpdates = YES;
                    break;
                }
            }
        }
        _loationDescription = PGLocationDescriptionWhenInUse;
        NSString *description = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSLocationAlwaysUsageDescription"];
        if ( description ) {
            _loationDescription = PGLocationDescriptionAlwaysUsage;
        }
        //NSLocationWhenInUseUsageDescription 允许在前台使用时获取GPS的描述
        //NSLocationAlwaysUsageDescription 允许永远可获取GPS的描述
    }
    return self;
}

- (void)getCurrentPosition:(PGMethod*)command
{
    NSString* callbackId = [command.arguments objectAtIndex:0];
    NSNumber* enableHighAccuracyValue = [command.arguments objectAtIndex:1];
    NSString *coorsTypeValue = [command.arguments objectAtIndex:3];
    NSString *jsProviderValue = [command.arguments objectAtIndex:4];
    NSNumber *geocodeValue = [command.arguments objectAtIndex:5];
    
    BOOL isGeocode = [PGPluginParamHelper getBoolValue:geocodeValue defalut:true];
    BOOL enableHighAccuracy = [PGPluginParamHelper getBoolValue:enableHighAccuracyValue defalut:false];
    
    [self getLocationWithProvider:jsProviderValue
               withCoorsTypeValue:coorsTypeValue
               enableHighAccuracy:enableHighAccuracy
                        isGeocode:isGeocode
                 withJSCallbackId:callbackId
                       withWathId:nil];
    
}

- (void)watchPosition:(PGMethod*)command
{
    NSString* callbackId = [command.arguments objectAtIndex:0];
    NSString* timerId = [command.arguments objectAtIndex:1];
    NSString *enableHighAccuracyValue = [command.arguments objectAtIndex:2];
    NSString *coorsTypeValue = [command.arguments objectAtIndex:3];
    NSString *jsProviderValue = [command.arguments objectAtIndex:4];
    NSNumber *geocodeValue = [command.arguments objectAtIndex:5];
    
    BOOL isGeocode = [PGPluginParamHelper getBoolValue:geocodeValue defalut:true];
    BOOL enableHighAccuracy = [PGPluginParamHelper getBoolValue:enableHighAccuracyValue defalut:false];
    
    [self getLocationWithProvider:jsProviderValue
               withCoorsTypeValue:coorsTypeValue
               enableHighAccuracy:enableHighAccuracy
                        isGeocode:isGeocode
                 withJSCallbackId:callbackId
                       withWathId:timerId];
}

- (void)clearWatch:(PGMethod*)command
{
    NSString* timerId = [command.arguments objectAtIndex:0];
    PGLocationReqest *req = [_locationReqSet getRequestByWathId:timerId];
    if ( req ) {
        NSString *providerType = [req.providerType copy];
        [_locationReqSet removeLocationRequest:req];
        if ( [_locationReqSet isReqEmpty:providerType] ) {
            PGLocationServer *locationServer = [self getLocationServerPorvider:providerType];
            [locationServer stopLocation];
            [locationServer removeAllLocation];
        }
        [providerType release];
    }
}

- (PGLocationServer*)getPriorityLocationServerPorvider:(NSString*)provider {
    PGLocationServer *locationService = [self getLocationServerPorvider:provider];
    if ( !locationService ) {
        return [self getLocationServerPorvider:@"system"];
    }
    return locationService;
}
-(NSString*)providerForname:(NSString*)name{
    NSString *providerServerName = [g_support_provider objectForKey:name];
    if ( providerServerName ) {
        Class  providerServer  = NSClassFromString(providerServerName);
        if ( providerServer != nil){
            if ([name isEqualToString:@"system"]) {
                return  @"system";
            }
            if ([name isEqualToString:@"baidu"]) {
                return  @"baidu";
            }
            if ([name isEqualToString:@"amap"]) {
                return  @"amap";
            }
        }
    }
    return @"";
}
- (PGLocationServer*)getLocationServerPorvider:(NSString*)provider {
    if ( [provider isKindOfClass:[NSNull class]] ) {
        NSString * provider1 = [self providerForname:@"system"];
        NSString * provider2 = [self providerForname:@"baidu"];
        NSString * provider3 = [self providerForname:@"amap"];
        if (![provider1 isEqualToString:@""]&&[provider2 isEqualToString:@""] &&[provider3 isEqualToString:@""]) {
            provider = @"system";
        }
        if(![provider2 isEqualToString:@""]&& [provider3 isEqualToString:@""]){
            provider = @"baidu";
        }
        if(![provider3 isEqualToString:@""] ){
            provider = @"amap";
        }
    }
    if ( [provider isKindOfClass:[NSString class]]) {
        provider = [provider lowercaseString];
        if ( !_locationServerProviders ) {
            _locationServerProviders = [[NSMutableDictionary alloc] init];
        }
        PGLocationServer* providerServer = [_locationServerProviders objectForKey:provider];
        if ( !providerServer ) {
            NSString *providerServerName = [g_support_provider objectForKey:provider];
            if ( providerServerName ) {
                providerServer = [[[NSClassFromString(providerServerName) alloc] init] autorelease];
                if ( providerServer ){
                    if ( [providerServer isLocationServiceValid] ) {
                        providerServer.providerName = provider;
                        [_locationServerProviders setObject:providerServer forKey:provider];
                    } else {
                        providerServer = nil;
                    }
                }
            }
        }
        return providerServer;
    }
    return nil;
}

- (void)getLocationWithProvider:(NSString*)providerValue
             withCoorsTypeValue:(NSString*)coorsTypeValue
             enableHighAccuracy:(BOOL)enableHighAccuracy
                      isGeocode:(BOOL)geocode
               withJSCallbackId:(NSString*)callbackId
                     withWathId:(NSString*)watchId {
//    BOOL isChoice = NO;
    PGLocationServer* locationServer = [self getLocationServerPorvider:providerValue];
//    if ( !locationServer ) {
//        isChoice = YES;
//        locationServer = [self getLocationServerPorvider:@"system"];
//    }
    if ( !locationServer ) {
        [self toErrorCallback:callbackId withCode:-1503 withMessage:@"Not Support Provider"];
        return;
    }
    
    coorsTypeValue = [locationServer getSupportCoorType:coorsTypeValue];
//    if ( !coorsTypeValue&& isChoice) {
//        coorsTypeValue = [locationServer getDefalutCoorType];
//    }
    if ( !coorsTypeValue ) {
        [self toErrorCallback:callbackId withCode:-1504 withMessage:@"Not Support CoordsType"];
        return;
    }
    
    if ( ![locationServer isLocationServicesEnabled] ) {
        [self toErrorCallback:callbackId withCode:-1505 withMessage:@"Location Services No Enabled"];
        return;
    }
    
    PGLocationReqest *req = [[[PGLocationReqest alloc] init] autorelease];
    req.providerType = locationServer.providerName;
    req.isWatchReq = watchId?YES:NO;
    req.watchId = watchId;
    req.coordType = coorsTypeValue;
    req.JSResponseId = callbackId;
    req.isGeocode = geocode;
    
    if ( !_locationReqSet ) {
        _locationReqSet = [[PGLocationReqestSet alloc] init];
    }
    [_locationReqSet addLocationRequest:req];
    locationServer.delegate = self;
    locationServer.locationDescription = _loationDescription;
    locationServer.allowsBackgroundLocationUpdates = _allowsBackgroundLocationUpdates;
    [locationServer startLocation:enableHighAccuracy];
    
}
- (void)returnResponseWithReq:(PGLocationReqest*)request
                 withLocation:(CLLocation*)lInfo
         withReveredPlacemark:(PGLocationAddress*)plcaemark
              isPlacemakrNull:(BOOL)isNull error:(NSError*)error {
    PDRPluginResult* result = nil;
    
    NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:8];
    NSNumber* timestamp = [NSNumber numberWithDouble:([/*lInfo.timestamp*/[NSDate date] timeIntervalSince1970] * 1000)];
    [returnInfo setObject:timestamp forKey:g_pdr_string_timestamp];
    if ( -1 != lInfo.speed ) {
        [returnInfo setObject:[NSNumber numberWithDouble:lInfo.speed] forKey:g_pdr_string_velocity];
    }
    if ( -1 != lInfo.verticalAccuracy ) {
        [returnInfo setObject:[NSNumber numberWithDouble:lInfo.verticalAccuracy] forKey:g_pdr_string_altitudeAccuracy];
    }
    [returnInfo setObject:[NSNumber numberWithDouble:lInfo.horizontalAccuracy] forKey:g_pdr_string_accuracy];
    if ( -1 != lInfo.course ) {
        [returnInfo setObject:[NSNumber numberWithDouble:lInfo.course] forKey:g_pdr_string_heading];
    }
    [returnInfo setObject:[NSNumber numberWithDouble:lInfo.altitude] forKey:g_pdr_string_altitude];
    
    CLLocationCoordinate2D coords = lInfo.coordinate;
    [returnInfo setObject:request.coordType forKey:@"coordsType"];
    [returnInfo setObject:[NSNumber numberWithDouble:coords.latitude] forKey:g_pdr_string_latitude];
    [returnInfo setObject:[NSNumber numberWithDouble:coords.longitude] forKey:g_pdr_string_longitude];
    
    if ( plcaemark ) {
        NSDictionary *address = [plcaemark toJSObject:isNull];
        if ( [address count] ) {
            [returnInfo addEntriesFromDictionary:address];
        }
    } else if ( isNull ) {
        [returnInfo setObject:[NSNull null] forKey:@"address"];
        [returnInfo setObject:[NSNull null] forKey:@"addresses"];
    }
    
    
    result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:returnInfo];
    result.keepCallback = request.isWatchReq?YES:NO;
//    [self toCallback:request.JSResponseId withReslut:[result toJSONString]];
    [self toErrorCallback:request.JSResponseId withCode:-1501 withMessage:@"坐标地址解析失败" withResult:[result toJSONString] keepCallback:NO];
    // LXZ 保存到 UserDefaults里
    NSUserDefaults* pStandUserDef = [NSUserDefaults standardUserDefaults];
    if (pStandUserDef) {
        
        NSMutableDictionary *adPos = [NSMutableDictionary dictionary];
        [adPos setObject:request.coordType?:@"" forKey:@"type"];
        [adPos setObject:@(coords.longitude) forKey:@"lon"];
        [adPos setObject:@(coords.latitude) forKey:@"lat"];
        CLLocationAccuracy Accuracy = MAX(lInfo.verticalAccuracy, lInfo.horizontalAccuracy);
        [adPos setObject:@(Accuracy) forKey:@"accuracy"];
        [adPos setObject:timestamp forKey:@"ts"];
        [pStandUserDef setObject:adPos forKey:@"DCADPosition"];
        
        [pStandUserDef setObject:[result toJSONString] forKey:@"PDRPlusLastPosInfomation"];
        [pStandUserDef synchronize];
    }
}
- (void)returnResponseWithReq:(PGLocationReqest*)request
                 withLocation:(CLLocation*)lInfo
         withReveredPlacemark:(PGLocationAddress*)plcaemark
              isPlacemakrNull:(BOOL)isNull {
    PDRPluginResult* result = nil;
    
    NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:8];
    NSNumber* timestamp = [NSNumber numberWithDouble:([/*lInfo.timestamp*/[NSDate date] timeIntervalSince1970] * 1000)];
    [returnInfo setObject:timestamp forKey:g_pdr_string_timestamp];
    if ( -1 != lInfo.speed ) {
        [returnInfo setObject:[NSNumber numberWithDouble:lInfo.speed] forKey:g_pdr_string_velocity];
    }
    if ( -1 != lInfo.verticalAccuracy ) {
        [returnInfo setObject:[NSNumber numberWithDouble:lInfo.verticalAccuracy] forKey:g_pdr_string_altitudeAccuracy];
    }
    [returnInfo setObject:[NSNumber numberWithDouble:lInfo.horizontalAccuracy] forKey:g_pdr_string_accuracy];
    if ( -1 != lInfo.course ) {
        [returnInfo setObject:[NSNumber numberWithDouble:lInfo.course] forKey:g_pdr_string_heading];
    }
    [returnInfo setObject:[NSNumber numberWithDouble:lInfo.altitude] forKey:g_pdr_string_altitude];
        
    CLLocationCoordinate2D coords = lInfo.coordinate;
//    if ( PGLocationCoorTypeBD09LL == coorType ) {
//        NSDictionary *info = BMKConvertBaiduCoorFrom(coords, BMK_COORDTYPE_GPS);
//        coords = BMKCoorDictionaryDecode(info);
//        [returnInfo setObject:@"bd09ll" forKey:@"coordsType"];
//    } else {
//        [returnInfo setObject:@"wgs84" forKey:@"coordsType"];
//    }
    [returnInfo setObject:request.coordType forKey:@"coordsType"];
    [returnInfo setObject:[NSNumber numberWithDouble:coords.latitude] forKey:g_pdr_string_latitude];
    [returnInfo setObject:[NSNumber numberWithDouble:coords.longitude] forKey:g_pdr_string_longitude];
    
    if ( plcaemark ) {
        NSDictionary *address = [plcaemark toJSObject:isNull];
        if ( [address count] ) {
            [returnInfo addEntriesFromDictionary:address];
        }
    } else if ( isNull ) {
        [returnInfo setObject:[NSNull null] forKey:@"address"];
        [returnInfo setObject:[NSNull null] forKey:@"addresses"];
    }

    
    result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:returnInfo];
    result.keepCallback = request.isWatchReq?YES:NO;
    [self toCallback:request.JSResponseId withReslut:[result toJSONString]];
    
    // LXZ 保存到 UserDefaults里
    NSUserDefaults* pStandUserDef = [NSUserDefaults standardUserDefaults];
    if (pStandUserDef) {
        
        NSMutableDictionary *adPos = [NSMutableDictionary dictionary];
        [adPos setObject:request.coordType?:@"" forKey:@"type"];
        [adPos setObject:@(coords.longitude) forKey:@"lon"];
        [adPos setObject:@(coords.latitude) forKey:@"lat"];
        CLLocationAccuracy Accuracy = MAX(lInfo.verticalAccuracy, lInfo.horizontalAccuracy);
        [adPos setObject:@(Accuracy) forKey:@"accuracy"];
        [adPos setObject:timestamp forKey:@"ts"];
        [pStandUserDef setObject:adPos forKey:@"DCADPosition"];
        
        [pStandUserDef setObject:[result toJSONString] forKey:@"PDRPlusLastPosInfomation"];
        [pStandUserDef synchronize];
    }
}
- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGLocationErrorLocationNoEnabled: return @"未开启位置服务";
        case PGLocationErrorPERMISSIONDENIED: return @"权限验证失败";
        case PGLocationErrorNotSupportProvider: return @"不支持的provider";
        case PGLocationErrorNotSupportCoordType: return @"不支持的coordsType";
        case PGLocationErrorUnableGetLocation:return @"不能获取到位置";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}
#pragma mark
#pragma mark delegate
- (void)locationServer:(PGLocationServer*)manager
    didUpdateLocations:(NSArray *)locations geocodeCompletion:(PGLocationAddress *) placemark {
    __block BOOL postGeo = false;
    if ( [locations count]) {
        NSArray *reqs = [_locationReqSet getLocationReq:manager.providerName];
        if ( [reqs count] ) {
            [reqs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PGLocationReqest *req = (PGLocationReqest*)obj;
                if ( !req.isGeocode || placemark ) {
                    [self returnResponseWithReq:req withLocation:[locations objectAtIndex:0] withReveredPlacemark:placemark?:nil isPlacemakrNull:false];
                    if ( !req.isWatchReq ) {
                        [_locationReqSet removeLocationRequest:req];
                    }
                    if ( [_locationReqSet isReqEmpty:manager.providerName] ) {
                        [manager removeAllLocation];
                        [manager stopLocation];
                    }
                } else {
                    postGeo = true;
                }
            }];
        }
        if ( postGeo ) {
            [manager addLocations:locations];
            [self reverseGeocodeLocation:manager];
        }
    }
}

- (void)locationServer:(id<PGLocationServer>)manager didFailWithError:(NSError*)error {
   NSArray *reqs = [_locationReqSet getLocationReq:manager.providerName];
    if ( [reqs count] ) {
        [reqs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PGLocationReqest *req = (PGLocationReqest*)obj;
            [self toErrorCallback:req.JSResponseId withCode:-1502 withMessage:error.description];
            [_locationReqSet removeLocationRequest:req];
        }];
    }
}

- (void)reverseGeocodeLocation:(PGLocationServer*)manager {
    if ( manager.isReversing ) {
        return;
    }
//   // [CLGeocoder reverseGeocodeLocation:nil completionHandler:nil];
//    
//    NSArray *allTypes = [_locatonCachesSet getAllProviderType];
//    
//    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//
//    dispatch_queue_t queue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_CONCURRENT);
//    
//    [allTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        dispatch_async(queue, ^{
//            
//        });
//    }];
//
//    NSArray *reqs = [_locationReqSet getLocationReq:manager.providerName];
//    if ( 0 == [reqs count] ) {
//        _isGeoAddress = false;
//        [[self getLocationServerProvider:manager.providerName] stopLocation];
//        return;
//    }
//
    CLLocation *geoLocation = [manager getFirstLocation];
    if ( geoLocation ) {
        manager.isReversing = YES;
        [manager reverseGeocodeLocation:geoLocation];
    }
}

- (void)locationServer:(PGLocationServer*)manager geocodeCompletion:(PGLocationAddress *) placemark error:(NSError*)error {
    CLLocation *geoLocation = [manager getFirstLocation];
    if ( geoLocation ) {
        NSArray *reqs = [_locationReqSet getLocationReq:manager.providerName];
        if ( [reqs count] ) {
            [reqs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PGLocationReqest *req = (PGLocationReqest*)obj;
                if ( error ) {
                    [self returnResponseWithReq:req withLocation:geoLocation withReveredPlacemark:placemark isPlacemakrNull:NO error:error];
                } else {
                    [self returnResponseWithReq:req withLocation:geoLocation withReveredPlacemark:placemark isPlacemakrNull:NO];
                }
                if ( !req.isWatchReq ) {
                    [_locationReqSet removeLocationRequest:req];
                }
            }];
        }
    }
    [manager removeFirstLocation];
    manager.isReversing = NO;
    if ( [_locationReqSet isReqEmpty:manager.providerName] ) {
        [manager removeAllLocation];
        [manager stopLocation];
    } else {
        [self reverseGeocodeLocation:manager];
    }
}

- (PGPluginAuthorizeStatus)authorizeStatus {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CLAuthorizationStatus authstatus = [CLLocationManager authorizationStatus];
    if (authstatus ==kCLAuthorizationStatusDenied
        || authstatus ==kCLAuthorizationStatusRestricted ){
        return PGPluginAuthorizeStatusDenied;
    } else if (authstatus ==kCLAuthorizationStatusNotDetermined) {
        return PGPluginAuthorizeStatusNotDetermined;
    } else if (authstatus ==kCLAuthorizationStatusAuthorizedAlways
               ||authstatus ==kCLAuthorizationStatusAuthorizedWhenInUse
               ||authstatus ==kCLAuthorizationStatusAuthorized) {
        return PGPluginAuthorizeStatusAuthorized;
    }
    return PGPluginAuthorizeStatusAuthorized;
#pragma clang diagnostic pop
}

+ (BOOL)authorizeSystemStatus{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if(status == kCLAuthorizationStatusAuthorizedAlways ||
       status == kCLAuthorizationStatusAuthorizedWhenInUse ||
       status == kCLAuthorizationStatusDenied){
        return YES;
    }    
    return NO;
}

- (void)dealloc
{
    [_locationReqSet release];
    [_locationServerProviders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id<PGLocationServer> locationServer = (id<PGLocationServer>)obj;
        locationServer.delegate = nil;
        [locationServer stopLocation];
    }];
    [_locationServerProviders release];
    [super dealloc];
}

@end
