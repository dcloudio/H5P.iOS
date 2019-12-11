//
//  DCMapSearchAPI.m
//  AMapImp
//
//  Created by XHY on 2019/5/22.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMapSearchAPI.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "DCMapConstant.h"
#import "WXConvert+DCMap.h"
#import "DCErrorInfoUtility.h"
#import "DCUniUtility.h"
#import "DCModel.h"


@interface DCMapSearchAPI () <AMapSearchDelegate>

@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, copy) void (^reverseGeocodeBlock)(NSDictionary *ret);
@property (nonatomic, copy) void (^poiSearchBlock)(NSDictionary *ret);
@property (nonatomic, copy) void (^poiKeywordsSearchBlock)(NSDictionary *ret);
@property (nonatomic, copy) void (^inputTipsSearchBlock)(NSDictionary *ret);
@property (nonatomic, assign) NSInteger pageCapacity;

@end

@implementation DCMapSearchAPI

- (AMapSearchAPI *)search {
    if (!_search) {
        _search = [[AMapSearchAPI alloc] init];
        _search.delegate = self;
        _pageCapacity = 10;
    }
    return _search;
}


#pragma mark - Public Method
/** 逆地理编码 */
- (void)reverseGeocode:(NSDictionary *)info block:(void(^)(NSDictionary *))block
{
    if (!info[@"point"] || ![info[@"point"] isKindOfClass:[NSDictionary class]]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
        return;
    }
    
    NSDictionary *point = info[@"point"];
    
    if (!point[dc_map_longitude] || !point[dc_map_latitude]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
        return;
    }
    
    self.reverseGeocodeBlock = block;
    
    float lat = [point[dc_map_latitude] floatValue];
    float lon = [point[dc_map_longitude] floatValue];
    
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:lat longitude:lon];
//    regeo.requireExtension = YES;
    [self.search AMapReGoecodeSearch:regeo];
}

/** 周边POI查询 */
- (void)poiSearchNearBy:(NSDictionary *)info block:(void(^)(NSDictionary *))block
{
    if (!info[@"point"] || ![info[@"point"] isKindOfClass:[NSDictionary class]] || !info[@"key"]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
        return;
    }
    
    NSDictionary *point = info[@"point"];
    
    if (!point[dc_map_longitude] || !point[dc_map_latitude]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
        return;
    }
    
    self.poiSearchBlock = block;
    
    NSString *key = info[@"key"];
    NSInteger index = info[@"index"] ? [info[@"index"] integerValue] : 1;
    NSInteger radius = info[dc_map_radius] ? [info[dc_map_radius] integerValue] : 3000;
    float lat = [point[dc_map_latitude] doubleValue];
    float lon = [point[dc_map_longitude] doubleValue];
    
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:lat longitude:lon];
    request.keywords = key;
    request.radius = radius;
    request.page = index;
    request.offset = self.pageCapacity;
    
    if (info[@"city"]) {
        request.city = info[@"city"];
    }
    
    if (info[@"types"]) {
        request.types = info[@"types"];
    }
    
    [self.search AMapPOIAroundSearch:request]; 
}


///  poi 关键字搜索
- (void)poiKeywordsSearch:(NSDictionary *)info block:(void(^)(NSDictionary *))block
{
    if (!info[@"key"]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
        return;
    }
    
    self.poiKeywordsSearchBlock = block;
    
    AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
    
    NSString *key = info[@"key"];
    NSInteger index = info[@"index"] ? [info[@"index"] integerValue] : 1;
    request.keywords = key;
    request.page = index;
    request.offset = self.pageCapacity;
    
    if (info[@"city"]) {
        request.city = info[@"city"];
    }
    
    if (info[@"types"]) {
        request.types = info[@"types"];
    }
    
    NSDictionary *point = info[@"point"];
    if (point[dc_map_longitude] && point[dc_map_latitude]) {
        float lat = [point[dc_map_latitude] doubleValue];
        float lon = [point[dc_map_longitude] doubleValue];
        request.location = [AMapGeoPoint locationWithLatitude:lat longitude:lon];
    }
    
    [self.search AMapPOIKeywordsSearch:request];
}


/// 搜索提示请求
- (void)inputTipsSearch:(NSDictionary *)info block:(void(^)(NSDictionary *))block
{
    if (!info[@"key"]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
        return;
    }
    
    self.inputTipsSearchBlock = block;
    
    AMapInputTipsSearchRequest *request = [[AMapInputTipsSearchRequest alloc] init];
    request.keywords = info[@"key"];
    
    if (info[@"city"]) {
        request.city = info[@"city"];
    }
    
    if (info[@"types"]) {
        request.types = info[@"types"];
    }
    
    NSDictionary *point = info[@"point"];
    if (point[dc_map_longitude] && point[dc_map_latitude]) {
        request.location = [NSString stringWithFormat:@"%@,%@",point[dc_map_longitude],point[dc_map_latitude]];
    }
    
    [self.search AMapInputTipsSearch:request];
}

#pragma mark - AMapSearchDelegate
/** 查询失败回调 */
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
//    NSLog(@"%@",[ErrorInfoUtility errorDescriptionWithCode:error.code]);
    NSString *errMsg = [DCUniCallbackUtility errorMessageWithPluginName:@"mapSearch"
                                                                SDKName:@"AmapSDK"
                                                           SDKErrorCode:(int)error.code
                                                        SDKErrorMessage:[ErrorInfoUtility errorDescriptionWithCode:error.code]];
    if ([request isKindOfClass:[AMapReGeocodeSearchRequest class]] && self.reverseGeocodeBlock) {
        self.reverseGeocodeBlock([DCUniCallbackUtility errorResult:DCUniPluginErrorInner errorMessage:errMsg]);
    }
    else if ([request isKindOfClass:[AMapPOIAroundSearchRequest class]] && self.poiSearchBlock) {
        self.poiSearchBlock([DCUniCallbackUtility errorResult:DCUniPluginErrorInner errorMessage:errMsg]);
    }
    else if ([request isKindOfClass:[AMapPOIKeywordsSearchRequest class]] && self.poiKeywordsSearchBlock) {
        self.poiKeywordsSearchBlock([DCUniCallbackUtility errorResult:DCUniPluginErrorInner errorMessage:errMsg]);
    }
    else if ([request isKindOfClass:[AMapInputTipsSearchRequest class]] && self.inputTipsSearchBlock) {
        self.inputTipsSearchBlock([DCUniCallbackUtility errorResult:DCUniPluginErrorInner errorMessage:errMsg]);
    }
}

/** 逆地理编码回调 */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
//    NSLog(@"%@",response.regeocode.formattedAddress);
    
    if (self.reverseGeocodeBlock) {
        if (response.regeocode) {
            NSDictionary *data = @{
                                   dc_map_address: response.regeocode.formattedAddress?:@"",
                                   dc_map_latitude: @(response.regeocode.addressComponent.streetNumber.location.latitude),
                                   dc_map_longitude: @(response.regeocode.addressComponent.streetNumber.location.longitude)
                                   };
            self.reverseGeocodeBlock([DCUniCallbackUtility successResult:data]);
        } else {
            self.reverseGeocodeBlock([DCUniCallbackUtility errorResult:DCUniPluginErrorInner]);
        }
    } 
}

/** POI 搜索回调 */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    
    NSDictionary *data = @{
                            @"totalNumber": @(response.count),
                            @"currentNumber": @(response.pois.count),
                            @"pageNumber": @((response.count % self.pageCapacity) ? (response.count / self.pageCapacity + 1) : (response.count / self.pageCapacity)),
                            @"pageIndex": @(request.page),
                            @"poiList": [response.pois dc_modelToJSONObject] ?: @[]
                         };
    if ([request isKindOfClass:[AMapPOIAroundSearchRequest class]] && self.poiSearchBlock) {
        self.poiSearchBlock([DCUniCallbackUtility successResult:data]);
    }
    else if ([request isKindOfClass:[AMapPOIKeywordsSearchRequest class]] && self.poiKeywordsSearchBlock) {
        self.poiKeywordsSearchBlock([DCUniCallbackUtility successResult:data]);
    }
}

- (void)onInputTipsSearchDone:(AMapInputTipsSearchRequest *)request response:(AMapInputTipsSearchResponse *)response {
    if (self.inputTipsSearchBlock) {
        NSDictionary *data = @{
            @"count": @(response.count),
            @"tips": [response.tips dc_modelToJSONObject] ?: @[]
        };
        self.inputTipsSearchBlock([DCUniCallbackUtility successResult:data]);
    }
}

@end
