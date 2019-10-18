//
//  DCMap.m
//  AMapImp
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMap.h"
#import <MAMapKit/MAMapView.h>
#import "WXConvert+DCMap.h"
#import "WXConvert+DCAmap.h"
#import "DCMapMarker.h"
#import "DCAnnotationView.h"
#import "DCPolyline.h"
#import "DCPolygon.h"
#import "DCCircle.h"
#import "WXImgLoaderProtocol.h"
#import "WXHandlerFactory.h"
#import "DCUniUtility.h"
#import "Masonry.h"
#import "DCMapControl.h"






#define kDCCalloutViewMargin          -8

@interface DCMap () <DCMapCalloutViewDelegate>

@property (nonatomic, strong) MAAnnotationView *userLocationAnnotationView;
@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate;
@property (nonatomic, strong) NSMutableArray *pointAnnotations;
@property (nonatomic, strong) NSMutableArray *polylines;
@property (nonatomic, strong) NSMutableArray *polygons;
@property (nonatomic, strong) NSMutableArray *circles;
@property (nonatomic, strong) NSMutableArray *controls;
@property (nonatomic, strong) id<WXImageOperationProtocol> imageOperation;

@end

@implementation DCMap


#pragma mark - Setter

- (void)dealloc {
    [_mapView removeAnnotations:_pointAnnotations];
    [_pointAnnotations removeAllObjects];
    _mapView.delegate = nil;
    [_mapView removeFromSuperview];
}

- (NSMutableArray *)pointAnnotations {
    if (!_pointAnnotations) {
        _pointAnnotations = [[NSMutableArray alloc] init];
    }
    return _pointAnnotations;
}

- (NSMutableArray *)polylines {
    if (!_polylines) {
        _polylines = [[NSMutableArray alloc] init];
    }
    return _polylines;
}

- (NSMutableArray *)polygons {
    if (!_polygons) {
        _polygons = [[NSMutableArray alloc] init];
    }
    return _polygons;
}

- (NSMutableArray *)circles {
    if (!_circles) {
        _circles = [[NSMutableArray alloc] init];
    }
    return _circles;
}

- (NSMutableArray *)controls {
    if (!_controls) {
        _controls = [[NSMutableArray alloc] init];
    }
    return _controls;
}

- (id<WXImgLoaderProtocol>)imageLoader
{
    static id<WXImgLoaderProtocol> imageLoader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageLoader = [WXHandlerFactory handlerForProtocol:@protocol(WXImgLoaderProtocol)];
    });
    return imageLoader;
}

- (UIView *)creatMapview {
    
    [[AMapServices sharedServices] setEnableHTTPS:YES];
    NSString *amapAppkey = nil;
    NSDictionary *amapInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"amap"];
    if ( [amapInfo isKindOfClass:[NSDictionary class]] ) {
        NSString *tempAK = [amapInfo objectForKey:@"appkey"];
        if ( [tempAK isKindOfClass:[NSString class]] ) {
            amapAppkey = tempAK;
        }
    }
    
    // 测试 bundle id: io.dcloud.amapdemo
//     amapAppkey = @"623c0396a9b879461c971a14baa678fb";
    
    if ( amapAppkey ) {
        [AMapServices sharedServices].apiKey = amapAppkey;
    }
    
    self.mapView = [[MAMapView alloc] init];
    self.mapView.delegate = self;
    
    self.mapView.zoomLevel = 16;
    
    self.mapView.showsUserLocation = NO;
    self.mapView.showsBuildings = NO;
    self.mapView.showsCompass = NO;
    self.mapView.rotateEnabled = NO;
    self.mapView.rotateCameraEnabled = NO;
    self.mapView.showTraffic = NO;
    self.mapView.showsScale = NO;
    
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    self.mapView.touchPOIEnabled = YES;
    
    return self.mapView;
}

- (void)setMapAttribute:(NSDictionary *)attributes {
    // 中心位置
    if (attributes[dc_map_longitude] && attributes[dc_map_latitude]) {
        double lon = [[attributes dc_safeObjectForKey:dc_map_longitude] doubleValue];
        double lat = [[attributes dc_safeObjectForKey:dc_map_latitude] doubleValue];
        self.centerCoordinate = [WXConvert CLLocationCoordinate2DLongitude:lon latitude:lat];
        self.mapView.centerCoordinate = self.centerCoordinate;
    }
    
    // 缩放级别
    if (attributes[dc_map_scale]) {
        CGFloat scale = [[attributes dc_safeObjectForKey:dc_map_scale] floatValue];
        [self.mapView setZoomLevel:scale];
    }
    
    // 显示带有方向的当前定位点
    if (attributes[dc_map_showlocation]) {
        [self.mapView setUserTrackingMode:MAUserTrackingModeNone animated:YES];
        self.mapView.showsUserLocation = [WXConvert BOOL:attributes[dc_map_showlocation]];
    }
    
    // 展示3D楼块
    if (attributes[dc_map_enable3D]) {
        self.mapView.showsBuildings = [WXConvert BOOL:attributes[dc_map_enable3D]];
    }
    
    // 显示指南针
    if (attributes[dc_map_showCompass]) {
        self.mapView.showsCompass = [WXConvert BOOL:attributes[dc_map_showCompass]];
    }
    
    if (attributes[dc_map_showScale]) {
        self.mapView.showsScale = [WXConvert BOOL:attributes[dc_map_showScale]];
    }
    
    // 开启俯视
    if (attributes[dc_map_enableOverlooking]) {
        self.mapView.rotateCameraEnabled = [WXConvert BOOL:attributes[dc_map_enableOverlooking]];
    }
    
    // 是否支持缩放
    if (attributes[dc_map_enableZoom]) {
        self.mapView.zoomEnabled = [WXConvert BOOL:attributes[dc_map_enableZoom]];
    }
    
    // 是否支持拖动
    if (attributes[dc_map_enableScroll]) {
        self.mapView.scrollEnabled = [WXConvert BOOL:attributes[dc_map_enableScroll]];
    }
    
    // 是否支持旋转
    if (attributes[dc_map_enableRotate]) {
        self.mapView.rotateEnabled = [WXConvert BOOL:attributes[dc_map_enableRotate]];
    }
    
    // 是否开卫星图
    if (attributes[dc_map_enableSatellite]) {
        self.mapView.mapType = [WXConvert BOOL:attributes[dc_map_enableSatellite]] ? MAMapTypeSatellite : MAMapTypeStandard;
    }
    
    // 是否显示实时交通路况
    if (attributes[dc_map_enableTraffic]) {
        self.mapView.showTraffic = [WXConvert BOOL:attributes[dc_map_enableTraffic]];
    }
    
    // 设置旋转角度
    if (attributes[dc_map_rotate]) {
        self.mapView.rotationDegree = [attributes[dc_map_rotate] floatValue];
    }
    
    // 设置倾斜角度
    if (attributes[dc_map_skew]) {
        self.mapView.cameraDegree = [attributes[dc_map_skew] floatValue];
    }
    
    // 标注
    if (attributes[dc_map_markers] && [attributes[dc_map_markers] isKindOfClass:[NSArray class]]) {
        [self addMarker:[attributes dc_safeObjectForKey:dc_map_markers]];
    }
    
    // 折线
    if (attributes[dc_map_polyline] && [attributes[dc_map_polyline] isKindOfClass:[NSArray class]]) {
        [self addPolyline:attributes[dc_map_polyline]];
    }
    
    // 多边形
    if (attributes[dc_map_polygons] && [attributes[dc_map_polygons] isKindOfClass:[NSArray class]]) {
        [self addPolygon:attributes[dc_map_polygons]];
    }
    
    // 圆形
    if (attributes[dc_map_circles] && [attributes[dc_map_circles] isKindOfClass:[NSArray class]]) {
        [self addCircle:attributes[dc_map_circles]];
    }
    
    // controls
    if (attributes[dc_map_controls] && [attributes[dc_map_controls] isKindOfClass:[NSArray class]]) {
        [self addControls:attributes[dc_map_controls]];
    }
    
    // 缩放地图以包含所有点
    if (attributes[dc_map_includePoints] && [attributes[dc_map_includePoints] isKindOfClass:[NSArray class]]) {
        [self includePoints:attributes[dc_map_includePoints] padding:UIEdgeInsetsZero];
    }
}

/** 添加地图标注 */
- (void)addMarker:(NSArray *)markers {
    
    [self.mapView removeAnnotations:self.pointAnnotations];
    [self.pointAnnotations removeAllObjects];
    
    for (NSDictionary *item in markers) {
        DCMapMarker *marker = [WXConvert Marker:item pixelScaleFactor:self.weexInstance.pixelScaleFactor];
        if (marker) {
            [self.pointAnnotations addObject:marker];
        }
    }
    
    [self.mapView addAnnotations:self.pointAnnotations];
}


/** 添加地图折线 */
- (void)addPolyline:(NSArray *)polylines {
    
    [self.mapView removeOverlays:self.polylines];
    [self.polygons removeAllObjects];
    
    for (NSDictionary *item in polylines) {
        DCPolyline *line = [WXConvert Polyline:item pixelScaleFactor:self.weexInstance.pixelScaleFactor];
        if (line) {
            [self.polylines addObject:line];
        }
    }
    
    [self.mapView addOverlays:self.polylines];
}

/** 添加多边形 */
- (void)addPolygon:(NSArray *)polygons {
    
    [self.mapView removeOverlays:self.polygons];
    [self.polygons removeAllObjects];
    
    for (NSDictionary *item in polygons) {
        DCPolygon *polygon = [WXConvert Polygon:item pixelScaleFactor:self.weexInstance.pixelScaleFactor];
        if (polygon) {
            [self.polygons addObject:polygon];
        }
    }
    
    [self.mapView addOverlays:self.polygons];
}

/** 添加圆 */
- (void)addCircle:(NSArray *)circles {
    
    [self.mapView removeOverlays:self.circles];
    [self.circles removeAllObjects];
    
    for (NSDictionary *item in circles) {
        DCCircle *circle = [WXConvert Circle:item pixelScaleFactor:self.weexInstance.pixelScaleFactor];
        if (circle) {
            [self.circles addObject:circle];
        }
    }
    
    [self.mapView addOverlays:self.circles];
}


/** 添加控件 */
- (void)addControls:(NSArray *)controls {
    for (UIView *control in self.controls) {
        [control removeFromSuperview];
    }
    [self.controls removeAllObjects];
    
    for (NSDictionary *item in controls) {
        DCMapControl *control = [WXConvert Control:item pixelScaleFactor:self.weexInstance.pixelScaleFactor];
        if (control) {
            
            if (control.clickable) {
                [control addTarget:self action:@selector(mapControlClicked:) forControlEvents:UIControlEventTouchUpInside];
            }
            
            __weak typeof(self) weakSelf = self;
            weakSelf.imageOperation = [[weakSelf imageLoader] downloadImageWithURL:control.iconPath imageFrame:CGRectZero userInfo:nil completed:^(UIImage *image, NSError *error, BOOL finished) {
                if (image) {
                    [control setBackgroundImage:image forState:UIControlStateNormal];
                    [weakSelf.mapView addSubview:control];
                    [control mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.mas_equalTo(control.position.top);
                        make.left.mas_equalTo(control.position.left);
                        make.width.mas_equalTo(control.position.width);
                        make.height.mas_equalTo(control.position.height);
                    }];
                }
            }];
            
            
            [self.controls addObject:control];
        }
    }
}

/** 点击控件回调 */
- (void)mapControlClicked:(DCMapControl *)control {
    [self handleMapEvent:dc_map_bindcontroltap params:@{dc_map_id: @(control._id)}];
}

/** 缩放地图以显示所有点 */
- (void)includePoints:(NSArray *)points padding:(UIEdgeInsets)insets{
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:points.count];
    for (NSDictionary *item in points) {
        MAPointAnnotation *point = [[MAPointAnnotation alloc] init];
        double lon = [[item dc_safeObjectForKey:dc_map_longitude] doubleValue];
        double lat = [[item dc_safeObjectForKey:dc_map_latitude] doubleValue];
        point.coordinate = [WXConvert CLLocationCoordinate2DLongitude:lon latitude:lat];
        [annotations addObject:point];
    }
    
    
    if (UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero)) {
        [self.mapView showAnnotations:annotations animated:YES];
    } else {
        [self.mapView showAnnotations:annotations edgePadding:insets animated:YES];
    }
}

#pragma mark - MAMapViewDelegate

/**
 添加地图标注
 */
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation
{
    // 自定义标注
    if ([annotation isKindOfClass:[DCMapMarker class]])
    {
//        DCMapMarker *marker = (DCMapMarker *)annotation;
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        DCAnnotationView *annotationView = (DCAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[DCAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
            annotationView.calloutView.delegate = self;
        }
        annotationView.annotation = annotation;
        //更新标注数据
        [annotationView updateInfo];
    
        return annotationView;
    }
    // 自定义userLocation对应的annotationView
    else if ([annotation isKindOfClass:[MAUserLocation class]])
    {
        static NSString *userLocationStyleReuseIndetifier = @"userLocationStyleReuseIndetifier";
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:userLocationStyleReuseIndetifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"userPosition"];
        
        self.userLocationAnnotationView = annotationView;
        
        return annotationView;
    }
    return nil;
}

/**
 添加地图覆盖物
 */
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    //折线
    if ([overlay isKindOfClass:[DCPolyline class]])
    {
        DCPolyline *polyline = (DCPolyline *)overlay;
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.lineCapType = kCGLineCapSquare;
        polylineRenderer.fillColor = polyline.color ? [WXConvert UIColor:polyline.color] : kMAOverlayRendererDefaultFillColor;
        polylineRenderer.lineWidth = polyline.width;
        polylineRenderer.lineDashType = polyline.dottedLine ? kMALineDashTypeDot : kMALineDashTypeNone;
        if (polyline.arrowLine) {
            if (polyline.arrowIconPath && polyline.arrowIconPath.length) {
                __weak typeof(self) weakSelf = self;
                weakSelf.imageOperation = [[weakSelf imageLoader] downloadImageWithURL:polyline.arrowIconPath imageFrame:CGRectZero userInfo:nil completed:^(UIImage *image, NSError *error, BOOL finished) {
                    if (!error) {
                        polylineRenderer.strokeImage = image;
                    } else {
                        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"AMap" withExtension:@"bundle"]];
                        UIImage *image = [UIImage imageWithContentsOfFile:[[bundle resourcePath] stringByAppendingPathComponent:@"images/traffic_texture_blue.png"]];
                        polylineRenderer.strokeImage = image;
                    }
                }];
            } else {
                NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"AMap" withExtension:@"bundle"]];
                UIImage *image = [UIImage imageWithContentsOfFile:[[bundle resourcePath] stringByAppendingPathComponent:@"images/traffic_texture_blue.png"]];
                polylineRenderer.strokeImage = image;
            }
        }
        polylineRenderer.strokeColor = polyline.borderColor ? [WXConvert UIColor:polyline.borderColor] : kMAOverlayRendererDefaultStrokeColor;
        
        return polylineRenderer;
    }
    // 多边形
    else if ([overlay isKindOfClass:[DCPolygon class]]) {
        DCPolygon *polygon = (DCPolygon *)overlay;
        MAPolygonRenderer *polygonRenderer = [[MAPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.lineWidth = polygon.strokeWidth;
        polygonRenderer.strokeColor = polygon.strokeColor ? [WXConvert UIColor:polygon.strokeColor] : kMAOverlayRendererDefaultStrokeColor;
        polygonRenderer.fillColor = polygon.fillColor ? [WXConvert UIColor:polygon.fillColor] : kMAOverlayRendererDefaultFillColor;
        polygon.zIndex = polygon.zIndex;
        return polygonRenderer;
    }
    // 圆形
    else if ([overlay isKindOfClass:[DCCircle class]]) {
        DCCircle *circle = (DCCircle *)overlay;
        MACircleRenderer *circleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        
        circleRenderer.lineWidth   = circle.strokeWidth;
        circleRenderer.strokeColor = circle.color ? [WXConvert UIColor:circle.color] : kMAOverlayRendererDefaultStrokeColor;
        circleRenderer.fillColor   = circle.fillColor ? [WXConvert UIColor:circle.fillColor] : kMAOverlayRendererDefaultFillColor;
        
        return circleRenderer;
    }
    // 自定义定位精度对应的MACircleView
    else if (overlay == mapView.userLocationAccuracyCircle) {
        MACircleRenderer *accuracyCircleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        
        accuracyCircleRenderer.lineWidth    = 2.f;
        accuracyCircleRenderer.strokeColor  = [UIColor lightGrayColor];
        accuracyCircleRenderer.fillColor    = [UIColor colorWithRed:1 green:0 blue:0 alpha:.3];
        return accuracyCircleRenderer;
    }
    
    
    return nil;
}

/** 定位更新 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (!updatingLocation && self.userLocationAnnotationView != nil)
    {
        [UIView animateWithDuration:0.1 animations:^{
            
            double degree = userLocation.heading.trueHeading - self.mapView.rotationDegree;
            self.userLocationAnnotationView.transform = CGAffineTransformMakeRotation(degree * M_PI / 180.f );
            
        }];
    }
}

/** 地图标注被选中回调 */
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    /* Adjust the map center in order to show the callout view completely. */
    if ([view isKindOfClass:[DCAnnotationView class]]) {
        DCAnnotationView *cusView = (DCAnnotationView *)view;
        CGRect frame = [cusView convertRect:cusView.calloutView.frame toView:self.mapView];
        
        frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(kDCCalloutViewMargin, kDCCalloutViewMargin, kDCCalloutViewMargin, kDCCalloutViewMargin));
        
        if (!CGRectContainsRect(self.mapView.frame, frame))
        {
            /* Calculate the offset to make the callout view show up. */
            CGSize offset = [WXConvert offsetToContainRect:frame inRect:self.mapView.frame];
            
            CGPoint theCenter = self.mapView.center;
            theCenter = CGPointMake(theCenter.x - offset.width, theCenter.y - offset.height);
            
            CLLocationCoordinate2D coordinate = [self.mapView convertPoint:theCenter toCoordinateFromView:self.mapView];
            
            [self.mapView setCenterCoordinate:coordinate animated:YES];
        }
        
    }
}

/** 回调地图事件 */
- (void)handleMapEvent:(NSString *)event params:(NSDictionary *)params {
    if (self.eventHandle) {
        self.eventHandle(event, params);
    }
}

/**
 * @brief 单击地图回调，返回经纬度
 * @param mapView 地图View
 * @param coordinate 经纬度
 */
- (void)mapView:(MAMapView *)mapView didSingleTappedAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [self handleMapEvent:dc_map_bindtap params:nil];
}

/**
 * @brief 标注view被点击时，触发该回调。（since 5.7.0）
 * @param mapView 地图的view
 * @param view annotationView
 */
- (void)mapView:(MAMapView *)mapView didAnnotationViewTapped:(MAAnnotationView *)view {
    
    if (![view.annotation isKindOfClass:[DCMapMarker class]]) {
        return;
    }
    
    DCMapMarker *marker = (DCMapMarker *)view.annotation;
    [self handleMapEvent:dc_map_bindmarkertap params:@{dc_map_markerId: @(marker._id)}];
}

/** 点击标注气泡回调 */
- (void)calloutViewDidClicked:(DCMapMarker *)marker {
    [self handleMapEvent:dc_map_bindcallouttap params:@{dc_map_markerId: @(marker._id)}];
}

/**
 * @brief 地图加载成功
 * @param mapView 地图View
 */
- (void)mapViewDidFinishLoadingMap:(MAMapView *)mapView {
    [self handleMapEvent:dc_map_bindupdated params:nil];
}

/**
 * @brief 地图区域即将改变时会调用此接口
 * @param mapView 地图View
 * @param animated 是否动画
 */
- (void)mapView:(MAMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
}

/**
 * @brief 地图区域改变完成后会调用此接口
 * @param mapView 地图View
 * @param animated 是否动画
 */
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
}

/**
 * @brief 地图将要发生移动时调用此接口
 * @param mapView       地图view
 * @param wasUserAction 标识是否是用户动作
 */
- (void)mapView:(MAMapView *)mapView mapWillMoveByUser:(BOOL)wasUserAction {
    [self handleMapEvent:dc_map_bindregionchange params:@{
                                                          @"type" : @"begin",
                                                          @"causedBy" : @"drag"
                                                          }];
}

/**
 * @brief 地图移动结束后调用此接口
 * @param mapView       地图view
 * @param wasUserAction 标识是否是用户动作
 */
- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction {
    [self handleMapEvent:dc_map_bindregionchange params:@{
                                                          @"type" : @"end",
                                                          @"causedBy" : @"drag"
                                                          }];
}

/**
 * @brief 地图将要发生缩放时调用此接口
 * @param mapView       地图view
 * @param wasUserAction 标识是否是用户动作
 */
- (void)mapView:(MAMapView *)mapView mapWillZoomByUser:(BOOL)wasUserAction {
    [self handleMapEvent:dc_map_bindregionchange params:@{
                                                          @"type" : @"begin",
                                                          @"causedBy" : @"scale"
                                                          }];
}

/**
 * @brief 地图缩放结束后调用此接口
 * @param mapView       地图view
 * @param wasUserAction 标识是否是用户动作
 */
- (void)mapView:(MAMapView *)mapView mapDidZoomByUser:(BOOL)wasUserAction {
    [self handleMapEvent:dc_map_bindregionchange params:@{
                                                          @"type" : @"end",
                                                          @"causedBy" : @"scale"
                                                          }];
}

/**
 * @brief 当touchPOIEnabled == YES时，单击地图使用该回调获取POI信息
 * @param mapView 地图View
 * @param pois 获取到的poi数组(由MATouchPoi组成)
 */
- (void)mapView:(MAMapView *)mapView didTouchPois:(NSArray *)pois {
    NSDictionary *data = @{};
    if (pois.count) {
        MATouchPoi *poi = pois.firstObject;
        data = @{
                 @"name": poi.name,
                 @"longitude": @(poi.coordinate.longitude),
                 @"latitude": @(poi.coordinate.latitude)
                 };
    }
    
    [self handleMapEvent:dc_map_bindpoitap params:@{@"datail":data}];
}

- (void)mapViewRequireLocationAuth:(CLLocationManager *)locationManager {
    [locationManager requestAlwaysAuthorization];
}

#pragma mark - Component Method
- (NSDictionary *)getCenterLocation {

    if (self.mapView.centerCoordinate.latitude && self.mapView.centerCoordinate.longitude) {
        return [DCUniCallbackUtility successResult:@{
                                                     dc_map_latitude: @(self.mapView.centerCoordinate.latitude),
                                                     dc_map_longitude: @(self.mapView.centerCoordinate.longitude)
                                                     }];
        
    }
    return [DCUniCallbackUtility errorResult:DCUniPluginErrorInner errorMessage:nil];
}

- (NSDictionary *)getUserLocation {
    
    if (self.mapView.userLocation.location) {
        return [DCUniCallbackUtility successResult:@{
                                                     dc_map_latitude: @(self.mapView.userLocation.location.coordinate.latitude),
                                                     dc_map_longitude: @(self.mapView.userLocation.location.coordinate.longitude)
                                                     }];
    }
    
    return [DCUniCallbackUtility errorResult:DCUniPluginErrorInner];
}

- (NSDictionary *)getRegion {
    //地图右上点（东北角）坐标
    CLLocationCoordinate2D northeast = [self.mapView convertPoint:CGPointMake(self.mapView.bounds.size.width, 0) toCoordinateFromView:self.mapView];
    //地图左下点（新南角）坐标
    CLLocationCoordinate2D southwest = [self.mapView convertPoint:CGPointMake(0, self.mapView.bounds.size.height) toCoordinateFromView:self.mapView];
 
    NSDictionary *data = @{
                           @"southwest": @{
                                   dc_map_latitude: @(southwest.latitude),
                                   dc_map_longitude: @(southwest.longitude)
                                   },
                           @"northeast": @{
                                   dc_map_latitude: @(northeast.latitude),
                                   dc_map_longitude: @(northeast.longitude)
                                   }
                           };
    return [DCUniCallbackUtility successResult:data];
    
}

- (NSDictionary *)getScale {
    NSDictionary *data= @{
                          dc_map_scale: @(self.mapView.zoomLevel)
                          };
    return [DCUniCallbackUtility successResult:data];
}

- (NSDictionary *)getSkew {
    NSDictionary *data = @{
        dc_map_skew: @(self.mapView.cameraDegree)
    };
    return [DCUniCallbackUtility successResult:data];
}

- (NSDictionary *)getRotate {
    NSDictionary *data = @{
        dc_map_rotate: @(self.mapView.rotationDegree)
    };
    return [DCUniCallbackUtility successResult:data];
}

- (NSDictionary *)setIncludePoints:(NSDictionary *)info {
    NSArray *points = info[dc_map_points];
    NSArray *padding = info[dc_map_padding];
    if (points) {
        [self includePoints:points padding:[WXConvert Padding:padding]];
        return [DCUniCallbackUtility success];
    }
    return [DCUniCallbackUtility errorResult:DCUniPluginErrorInner];
}

- (NSDictionary *)moveToLocation:(NSDictionary *)info {
    if (self.mapView.showsUserLocation && self.mapView.userLocation.location) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
        return [DCUniCallbackUtility success];
    }
    return [DCUniCallbackUtility errorResult:DCUniPluginErrorInner];
}

- (void)translateMarker:(NSDictionary *)info block:(void(^)(NSDictionary *))block {
    
    if (!info[dc_map_markerId] || !info[dc_map_destination]) {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
    }
    
    NSInteger markId = [info[dc_map_markerId] integerValue];
    NSDictionary *destination = info[dc_map_destination];
    
    CLLocationCoordinate2D des[1];
    if (destination[dc_map_longitude] && destination[dc_map_latitude]) {
        double lon = [[destination dc_safeObjectForKey:dc_map_longitude] doubleValue];
        double lat = [[destination dc_safeObjectForKey:dc_map_latitude] doubleValue];
        des[0].latitude = lat;
        des[0].longitude = lon;
    } else {
        block([DCUniCallbackUtility errorResult:DCUniPluginErrorInvalidArgument]);
    }
    
    CGFloat duration = info[dc_map_duration] ? [WXConvert CGFloat:info[dc_map_duration]] / 1000.0 : 1;
    
    for (DCMapMarker *marker in self.pointAnnotations) {
        if (markId == marker._id) {
            [marker addMoveAnimationWithKeyCoordinates:des count:1 withDuration:duration withName:nil completeCallback:^(BOOL isFinished) {
                block(@{dc_uni_callback_type: dc_map_animationEnd});
            } stepCallback:nil];
        }
    }
    block([DCUniCallbackUtility success]);
}

@end
