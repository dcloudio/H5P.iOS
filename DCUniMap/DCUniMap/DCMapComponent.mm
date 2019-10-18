//
//  DCMapComponent.m
//  libWeexMap
//
//  Created by XHY on 2019/4/9.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMapComponent.h"
#import "DCMap.h"
#import "DCMapConstant.h"
#import "WXComponent+Layout.h"


@interface DCMapContainerView : WXView
@end

@implementation DCMapContainerView
@end






@interface DCMapComponent ()
//{
//    CGRect _lastViewFrame;  /**< 记录上一次 self.view 的frame */
//}

@property (nonatomic, strong) DCMap *map;
@property (nonatomic, strong) NSDictionary *atts;

// Events
@property (nonatomic, assign) BOOL bindtap;             /**< 点击地图时触发 */
@property (nonatomic, assign) BOOL bindmarkertap;       /**< 点击标记点时触发，会返回marker的id */
@property (nonatomic, assign) BOOL bindcontroltap;      /**< 点击控件时触发，会返回control的id */
@property (nonatomic, assign) BOOL bindcallouttap;      /**< 点击标记点对应的气泡时触发，会返回marker的id */
@property (nonatomic, assign) BOOL bindupdated;         /**< 在地图渲染更新完成时触发 */
@property (nonatomic, assign) BOOL bindregionchange;    /**< 视野发生变化时触发 */
@property (nonatomic, assign) BOOL bindpoitap;          /**< 点击地图poi点时触发 */

@end

@implementation DCMapComponent

#pragma mark - Component lifeCycle

- (void)dealloc {
    _map = nil;
}

- (instancetype)initWithRef:(NSString *)ref
                       type:(NSString*)type
                     styles:(nullable NSDictionary *)styles
                 attributes:(nullable NSDictionary *)attributes
                     events:(nullable NSArray *)events
               weexInstance:(WXSDKInstance *)weexInstance
{
    self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance];
    if (self) {
        _map = [[DCMap alloc] init];
        
    }
    
    return self;
}

- (UIView *)loadView
{
    UIView *view = [[DCMapContainerView alloc] init];
    [view addSubview:[self.map creatMapview]];
    return view;
}

- (void)layoutDidFinish {
    self.map.mapView.frame = self.view.bounds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.map.mapView.frame = self.view.bounds;

    // 设置默认宽高
    [self dc_setDefaultWidthPixel:300 defaultHeightPixel:150];
    
    self.map.weexInstance = self.weexInstance;
    [self.map setMapAttribute:self.attributes];
    [self onMapEventHandle];
}

- (void)viewDidUnload {
    _map.eventHandle = nil;
}

- (void)updateAttributes:(NSDictionary *)attributes
{
//    NSLog(@"updateAttributes: %@",attributes);
    [self.map setMapAttribute:attributes];
}

- (void)insertSubview:(WXComponent *)subcomponent atIndex:(NSInteger)index {
    
    [super insertSubview:subcomponent atIndex:index];
    [self.view bringSubviewToFront:subcomponent.view];
}

- (void)addEvent:(NSString *)eventName {
    if ([eventName isEqualToString:dc_map_bindtap]) {
        self.bindtap = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindmarkertap]) {
        self.bindmarkertap = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindcontroltap]) {
        self.bindcontroltap = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindcallouttap]) {
        self.bindcallouttap = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindupdated]) {
        self.bindupdated = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindregionchange]) {
        self.bindregionchange = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindpoitap]) {
        self.bindpoitap = YES;
    }
    else if ([eventName isEqualToString:dc_map_bindcontroltap])
    {
        self.bindcontroltap = YES;
    }
}

- (void)removeEvent:(NSString *)eventName {
    if ([eventName isEqualToString:dc_map_bindtap]) {
        self.bindtap = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindmarkertap]) {
        self.bindmarkertap = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindcontroltap]) {
        self.bindcontroltap = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindcallouttap]) {
        self.bindcallouttap = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindupdated]) {
        self.bindupdated = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindregionchange]) {
        self.bindregionchange = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindpoitap]) {
        self.bindpoitap = NO;
    }
    else if ([eventName isEqualToString:dc_map_bindcontroltap]) {
        self.bindcontroltap = NO;
    }
}

- (void)onMapEventHandle {
    __weak __typeof(self)weakSelf = self;
    self.map.eventHandle = ^(NSString * _Nullable eventName, NSDictionary * _Nullable params) {
        params = @{@"detail":(params?:@{})};
        if ([eventName isEqualToString:dc_map_bindtap] && self.bindtap) {
            [weakSelf fireEvent:dc_map_bindtap params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindmarkertap] && self.bindmarkertap) {
            [weakSelf fireEvent:dc_map_bindmarkertap params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindcontroltap] && self.bindcontroltap) {
            [weakSelf fireEvent:dc_map_bindcontroltap params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindcallouttap] && self.bindcallouttap) {
            [weakSelf fireEvent:dc_map_bindcallouttap params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindupdated] && self.bindupdated) {
            [weakSelf fireEvent:dc_map_bindupdated params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindregionchange] && self.bindregionchange) {
            [weakSelf fireEvent:dc_map_bindregionchange params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindpoitap] && self.bindpoitap) {
            [weakSelf fireEvent:dc_map_bindpoitap params:params];
        }
        else if ([eventName isEqualToString:dc_map_bindcontroltap] && self.bindcontroltap) {
            [weakSelf fireEvent:dc_map_bindcontroltap params:params];
        }
    };
}

#pragma mark - Export Method

WX_EXPORT_METHOD(@selector(getCenterLocation:))
WX_EXPORT_METHOD(@selector(getUserLocation:))
WX_EXPORT_METHOD(@selector(getRegion:))
WX_EXPORT_METHOD(@selector(getScale:))
WX_EXPORT_METHOD(@selector(getSkew:))
WX_EXPORT_METHOD(@selector(getRotate:))
WX_EXPORT_METHOD(@selector(includePoints::))
WX_EXPORT_METHOD(@selector(moveToLocation:))
WX_EXPORT_METHOD(@selector(translateMarker::))

/** 获取当前地图中心的经纬度 */
- (void)getCenterLocation:(WXKeepAliveCallback)callback {
    if (callback) {
        NSDictionary *res = [self.map getCenterLocation];
        callback(res,NO);
    }
}

/** 获取当前位置 */
- (void)getUserLocation:(WXKeepAliveCallback)callback {
    if (callback) {
        callback([self.map getUserLocation],NO);
    }
}

/** 获取当前地图的视野范围 */
- (void)getRegion:(WXKeepAliveCallback)callback {
    if (callback) {
        NSDictionary *res = [self.map getRegion];
        callback(res,NO);
    }
}

/** 获取当前地图的缩放级别 */
- (void)getScale:(WXKeepAliveCallback)callback {
    if (callback) {
        NSDictionary *res = [self.map getScale];
        callback(res,NO);
    }
    
}

/** 获取当前地图的倾斜角 */
- (void)getSkew:(WXKeepAliveCallback)callback {
    if (callback) {
        NSDictionary *res = [self.map getSkew];
        callback(res,NO);
    }
}

/** 获取当前地图的旋转角 */
- (void)getRotate:(WXKeepAliveCallback)callback {
    if (callback) {
        NSDictionary *res = [self.map getRotate];
        callback(res,NO);
    }
}

/** 缩放视野展示所有经纬度 */
- (void)includePoints:(NSDictionary *)info :(WXKeepAliveCallback)callback {
    if (callback) {
        NSDictionary *res = [self.map setIncludePoints:info];
        callback(res,NO);
    }
}

/** 将地图中心移置当前定位点 */
- (void)moveToLocation:(NSDictionary *)info {
    [self.map moveToLocation:info];
}

/** 平移marker，带动画 */
- (void)translateMarker:(NSDictionary *)info :(WXKeepAliveCallback)callback {
    [self.map translateMarker:info block:^(NSDictionary * res) {
        if (callback) {
            callback(res,YES);
        }
    }];
}

@end
