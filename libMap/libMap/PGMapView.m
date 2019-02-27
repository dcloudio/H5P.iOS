//
//  PGMapView.m
//  libMap
//
//  Created by DCloud on 2018/7/13.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "PGMapView.h"
#import "PGMapDefs.h"
#import <MapKit/MapKit.h>
#import "PDRToolSystemEx.h"
#import "H5CoreJavaScriptText.h"

//缩放控件距离地图边界值
#define PG_MAP_ZOOMCONTROL_GAP 3

@implementation PGMapZoomControlView

@end

@interface PGMapView()
@property(nonatomic,retain)NSMutableArray *onEventWebviewIds;
@property(nonatomic,retain)NSMutableDictionary *jsCallbackIdDict;
@end

@implementation PGMapView
- (void)dealloc {
    self.onEventWebviewIds = nil;
    self.jsCallbackIdDict = nil;
    self.userLocation = nil;
    self.UUID = nil;
    self.webviewId = nil;
     [_zoomControlView release];
    [super dealloc];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self resizeZoomControl];
}

- (int)MapToolFitZoom:(int)zoom{
    if ( zoom < 3 )
        return 3;
    else if( zoom > 19 )
        return 19;
    return zoom;
}

- (instancetype)initViewWithArray:(NSArray*)args
{
    if ( args )
    {
        CGFloat left = .0f, top = .0f, width = .0f, height = .0f;
        NSDictionary *options = [args objectAtIndex:0];
        if ( [options isKindOfClass:[NSDictionary class]] ) {
            
            NSString *value = [options objectForKey:@"position"];
            if ( !value ) {
                NSMutableDictionary *newOptions = [NSMutableDictionary dictionaryWithDictionary:options];
                [newOptions setObject:@"static" forKey:@"position"];
                options = newOptions;
            }
        }
        
        if ( [args count] > 1 ) {
            left   = [[args objectAtIndex:1] floatValue];
            top    = [[args objectAtIndex:2] floatValue];
            width  = [[args objectAtIndex:3] floatValue];
            height = [[args objectAtIndex:4] floatValue];
        } else {
            left = [PGPluginParamHelper getFloatValueInDict:options forKey:@"left" defalut:left];
            top = [PGPluginParamHelper getFloatValueInDict:options forKey:@"top" defalut:top];
            width = [PGPluginParamHelper getFloatValueInDict:options forKey:@"width" defalut:width];
            height = [PGPluginParamHelper getFloatValueInDict:options forKey:@"height" defalut:height];
        }
        return [self initWithFrame:CGRectMake(left, top, width, height)
                            params:options];
    }
    return nil;
}

- (id)initWithFrame:(CGRect)frame params:(NSDictionary*)setInfo {
    if ( self = [super initWithFrame:frame withOptions:setInfo withJsContext:nil] ) {
        
    }
    return self;
}

- (void)addEvtCallbackId:(NSString*)cbId {
    if ( !self.onEventWebviewIds ) {
        self.onEventWebviewIds = [NSMutableArray array];
    }
    if ( ![self.onEventWebviewIds containsObject:cbId] ){
        [self.onEventWebviewIds addObject:cbId];
    }
}

/*
 *------------------------------------------------
 *@summay: 调整地图缩放控件
 *@param
 *@return
 *@remark
 *
 *------------------------------------------------
 */
- (void)resizeZoomControl
{
    if ( _zoomControlView )
    {
        CGRect mapRect = self.bounds;
        CGSize zoomControlSize = _zoomControlView.bounds.size;
        CGPoint center;
        center.x = mapRect.size.width - zoomControlSize.width/2 - PG_MAP_ZOOMCONTROL_GAP;
        center.y = mapRect.size.height - zoomControlSize.height/2 - PG_MAP_ZOOMCONTROL_GAP;
        _zoomControlView.center = center;
    }
}

/*
 *------------------------------------------------
 *@summay: 显示地图缩放控件
 *@param
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)showZoomControl
{
    if ( !_zoomControlView )
    {
        PGMapZoomControlView *zoomControlView = [[PGMapZoomControlView alloc] init];
        zoomControlView.alpha = 0.5f;
        zoomControlView.minimumValue= 3;
        zoomControlView.maximumValue= 19;
        zoomControlView.stepValue= 1;
        zoomControlView.value= self.zoomLevel;
        [zoomControlView addTarget:self action:@selector(zoomControlCallback:) forControlEvents:UIControlEventValueChanged];
        _zoomControlView = zoomControlView;
        [self resizeZoomControl];
        [self addSubview:_zoomControlView];
    }
    if ( _zoomControlView.hidden )
    { _zoomControlView.hidden = NO; }
}

/*
 *------------------------------------------------
 *@summay: 隐藏地图缩放控件
 *@param
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)hideZoomControl
{
    if ( _zoomControlView && !_zoomControlView.hidden)
    { _zoomControlView.hidden = YES; }
}

-(void)zoomControlCallback:(PGMapZoomControlView*)sender
{/*
  CGFloat value = _zoomControlView.value;
  CGFloat currentZoom = self.zoomLevel;
  if ( value >= currentZoom ) {
  [self zoomIn];
  } else {
  [self zoomOut];
  }*/
    [self setZoomLevel:_zoomControlView.value];
   // _BMKMapView.zoomLevel =  //MapToolFitZoom(_zoomControlView.value);
}


/*
 *------------------------------------------------
 *@summay: 设置地图中心缩放级别
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)setZoomJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSNumber *innerZoom = [args objectAtIndex:0];
        if ( innerZoom && [innerZoom isKindOfClass:[NSNumber class]])
        {
            int nZoom = [self MapToolFitZoom:([innerZoom intValue])];
            [self setZoomLevel:nZoom];
            if ( _zoomControlView )
            { _zoomControlView.value = self.zoomLevel; }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 设置地图中心区域
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)setCenterJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        PGMapCoordinate *center = [PGMapCoordinate pointWithJSON:[args objectAtIndex:0]];
        if ( center )
        {
            [self setCenterCoordinate:[center point2CLCoordinate] animated:YES];
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 设置地图显示区域
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)centerAndZoomJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        PGMapCoordinate *center = [PGMapCoordinate pointWithJSON:[args objectAtIndex:0]];
        NSNumber *innerZoom = [args objectAtIndex:1];
        if ( center
            && innerZoom
            && [innerZoom isKindOfClass:[NSNumber class]])
        {
            int nZoom = [self MapToolFitZoom:[innerZoom intValue]];
            self.zoomLevel = nZoom;
            if ( _zoomControlView )
            { _zoomControlView.value = self.zoomLevel; }
            [self setCenterCoordinate:[center point2CLCoordinate] animated:YES];
        }
    }
}


/*
 *------------------------------------------------
 *@summay: 获取当前中心点的经纬度
 *@param sender js pass
 *@return
 *@remark
 *     该接口和getCenterCoordinate的区别为该接口会通知js
 *------------------------------------------------
 */
- (void)getCurrentCenterJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *uuid = [args objectAtIndex:0];
        CLLocationCoordinate2D coordinate = self.centerCoordinate;
        NSString *jsObjectF =
        @"{\
        var plus = %@;\
        var point = new plus.maps.Point(%f,%f);\
        var args = {'state':0, 'point':point};\
        plus.maps.__bridge__.execCallback('%@', args);}";
        NSMutableString *javascript = [NSMutableString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject],coordinate.longitude, coordinate.latitude, uuid];
        [self.jsBridge asyncWriteJavascript:javascript];
    }
}
/*
 *------------------------------------------------
 *@summay: 获取用户当前的位置
 *@param sender js pass
 *@return
 *@remark
 *   该接口会通知js
 *------------------------------------------------
 */
- (void)getUserLocationJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *uuid = [args objectAtIndex:0];
        NSString *webviewId = [args objectAtIndex:1];
        
        if ( NO == self.showsUserLocation ) {
            self.showsUserLocation = true;
        }
        
        PGMapUserLocation *userLocation = self.userLocation;
        if ( userLocation.location )
        {
            CLLocation *location = userLocation.location;
            CLLocationCoordinate2D coordinate = location.coordinate;
            NSString *jsObjectF =
            @"{ var plus = %@;\
            var point = new plus.maps.Point(%f,%f);\
            var args = {'state':0, 'point':point};\
            plus.maps.__bridge__.execCallback('%@', args);}";
            NSMutableString *javascript = [NSMutableString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], coordinate.longitude, coordinate.latitude, uuid];
            [self.jsBridge asyncWriteJavascript:javascript];
        }
        else
        {
            if ( !self.jsCallbackIdDict )
                self.jsCallbackIdDict = [[NSMutableDictionary alloc] initWithCapacity:10];
            [self.jsCallbackIdDict setObject:webviewId forKey:uuid];
        }
    }
}

- (void)mapView:(PGMapView *)mapView onClicked:(CLLocationCoordinate2D)coordinate {
    NSString *jsObjectF =
    @"{var plus = %@; var args = new plus.maps.Point(%f,%f);\
    plus.maps.__bridge__.execCallback('%@', {callbackType:'click',payload:args});}";
    NSString *javaScript = [NSString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], coordinate.longitude, coordinate.latitude, self.UUID];
    for ( NSString *webviewId in self.onEventWebviewIds ) {
        [self.jsBridge asyncWriteJavascript:javaScript inWebview:webviewId];
    }
}

/*
 *------------------------------------------------
 *用户位置更新后，会调用此函数
 *@param mapView 地图View
 *@param userLocation 新的用户位置
 *------------------------------------------------
 */
- (void)mapView:(PGMapView *)mapView didUpdateUserLocation:(PGMapUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if ( userLocation && userLocation.location && [self.jsCallbackIdDict count])
    {
        self.userLocation = userLocation;
        CLLocation *location = userLocation.location;
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        [self.jsCallbackIdDict enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull aUUID, NSString*   _Nonnull webviewId, BOOL * _Nonnull stop) {
            NSString *jsObjectF =
            @"{ var plus = %@;\
            var point = new plus.maps.Point(%f,%f);\
            var args = {'state':0, 'point':point};\
            plus.maps.__bridge__.execCallback('%@', args);}";
            NSMutableString *javascript = [NSMutableString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject],coordinate.longitude, coordinate.latitude, aUUID];
            [self.jsBridge asyncWriteJavascript:javascript inWebview:webviewId];
        }];
        [self.jsCallbackIdDict removeAllObjects];
    }
}
/*
 *------------------------------------------------
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 *------------------------------------------------
 */
- (void)mapView:(PGMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    if ( [self.jsCallbackIdDict count] )
    {
        [self.jsCallbackIdDict enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull aUUID, NSString*   _Nonnull webviewId, BOOL * _Nonnull stop) {
            NSString *jsObjectF =
            @"{ var plus = %@;\
            var point = new plus.maps.Point(%f,%f);\
            var args = {'state':-1, 'point':point};\
            plus.maps.__bridge__.execCallback('%@', args);}";
            NSMutableString *javascript = [NSMutableString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], 0.0f, 0.0f, aUUID];
            [self.jsBridge asyncWriteJavascript:javascript inWebview:webviewId];
        }];
        [self.jsCallbackIdDict removeAllObjects];
    }
}

- (void)mapViewRegionDidChange:(PGMapView *)mapView {
    if ( _zoomControlView ){
        _zoomControlView.value = self.zoomLevel;
    }
    CLLocationCoordinate2D tl = [self convertPoint:CGPointMake(self.bounds.size.width, 0) toCoordinateFromView:self];
    CLLocationCoordinate2D rb = [self convertPoint:CGPointMake(0, self.bounds.size.height) toCoordinateFromView:self];
    
    NSString *jsObjectF =
    @"window.setTimeout(function(){ %@.maps.__bridge__.execCallback('%@', {callbackType:'change',zoom:%d,center:{long:%f,lat:%f},northease:{long:%f,lat:%f},southwest:{long:%f,lat:%f}});},0)";
    NSString *javaScript = [NSString stringWithFormat:jsObjectF,
                            [H5CoreJavaScriptText plusObject],
                            self.UUID,
                            self.zoomLevel,
                            self.centerCoordinate.longitude, self.centerCoordinate.latitude,
                            tl.longitude, tl.latitude, rb.longitude, rb.latitude];
    for ( NSString *webviewId in self.onEventWebviewIds ) {
        [self.jsBridge asyncWriteJavascript:javaScript inWebview:webviewId];
    }
}

/*
 *------------------------------------------------
 *invake js openSysMap
 *@param command PDLMethod*
 *@return 无
 *------------------------------------------------
 */
+ (void)openSysMap:(NSArray*)command
{
    NSMutableDictionary *dstDict = [command objectAtIndex:0];
    NSString *dstAddr = [PGPluginParamHelper getStringValue:[command objectAtIndex:1]];
    NSMutableDictionary *srcDict = [command objectAtIndex:2];
    
    if ( srcDict && [srcDict isKindOfClass:[NSMutableDictionary class]]
        && dstDict && [dstDict isKindOfClass:[NSMutableDictionary class]])
    {
        PGMapCoordinate *srcPoi = [PGMapCoordinate pointWithJSON:srcDict];
        PGMapCoordinate *dstPoi = [PGMapCoordinate pointWithJSON:dstDict];
        if ( srcPoi && dstPoi ) {
            if ( [PTDeviceOSInfo systemVersion] > PTSystemVersion7Series ) {
                NSString *mapURL = [NSString stringWithFormat:@"http://maps.apple.com/?saddr=%f,%f&daddr=%f,%f",
                                    srcPoi.latitude, srcPoi.longitude,
                                    dstPoi.latitude, dstPoi.longitude ];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapURL]];
            } else if ([PTDeviceOSInfo systemVersion] > PTSystemVersion5Series){
                MKPlacemark *srcPlaceMark = [[[MKPlacemark alloc] initWithCoordinate:[srcPoi point2CLCoordinate] addressDictionary:nil] autorelease];
                MKPlacemark *dstPlaceMark = [[[MKPlacemark alloc] initWithCoordinate:[dstPoi point2CLCoordinate] addressDictionary:dstAddr?@{@"Name":dstAddr}:nil] autorelease];
                MKMapItem *srcLocation = [[[MKMapItem alloc] initWithPlacemark:srcPlaceMark] autorelease];
                MKMapItem *dstLocation = [[[MKMapItem alloc] initWithPlacemark:dstPlaceMark] autorelease];
                [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:srcLocation, dstLocation, nil]
                               launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeDriving, [NSNumber numberWithBool:YES], nil]
                                                                         forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, MKLaunchOptionsShowsTrafficKey, nil]]];
            } else {
                NSString *urlF  = @"http://maps.google.com/maps?daddr=%f,%f&saddr=%f,%f";
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:urlF,
                                                                                 srcPoi.latitude, srcPoi.longitude,
                                                                                 dstPoi.latitude, dstPoi.longitude ]]];
            }
        }
    }
    
    //    NSMutableDictionary *srcDict = [command objectAtIndex:0];
    //    NSString *srcAddr = [PGPluginParamHelper getStringValue:[command objectAtIndex:1]];
    //    NSMutableDictionary *dstDict = [command objectAtIndex:2];
    //    NSString *dstAddr = [PGPluginParamHelper getStringValue:[command objectAtIndex:2]];
    //    if ( srcDict && [srcDict isKindOfClass:[NSMutableDictionary class]]
    //        && dstDict && [dstDict isKindOfClass:[NSMutableDictionary class]])
    //    {
    //        PGMapCoordinate *srcPoi = [PGMapCoordinate pointWithJSON:srcDict];
    //        PGMapCoordinate *dstPoi = [PGMapCoordinate pointWithJSON:dstDict];
    //        if ( srcPoi && dstPoi )
    //        {
    //            if ( [PTDeviceOSInfo systemVersion] > PTSystemVersion5Series ) {
    ////                [PGMapView reverseGeocodeLocation:[srcPoi point2CLCoordinate] completionHandler:^(MKPlacemark * _Nullable srcPlacemark ) {
    ////                    if ( srcPlacemark ) {
    ////                        [PGMapView reverseGeocodeLocation:[dstPoi point2CLCoordinate] completionHandler:^(MKPlacemark * _Nullable dstPlacemark ) {
    ////                            if ( dstPlacemark ) {
    ////                                MKMapItem *srcLocation = [[[MKMapItem alloc] initWithPlacemark:srcPlacemark] autorelease];
    ////                                MKMapItem *dstLocation = [[[MKMapItem alloc] initWithPlacemark:dstPlacemark] autorelease];
    ////                                [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:srcLocation, dstLocation, nil]
    ////                                               launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeDriving, [NSNumber numberWithBool:YES], nil]
    ////                                                                                         forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, MKLaunchOptionsShowsTrafficKey, nil]]];
    ////                            }
    ////                        }];
    ////                    }
    ////                }];
    //////
    ////
    ////                CLLocationCoordinate2D src;
    ////                CLLocationCoordinate2D dst;
    ////                src.latitude = srcPoi.longitude;
    ////                src.longitude = srcPoi.latitude;
    ////                dst.latitude = dstPoi.longitude;
    ////                dst.longitude = dstPoi.latitude;
    //                MKPlacemark *srcPlaceMark = [[[MKPlacemark alloc] initWithCoordinate:[srcPoi point2CLCoordinate] addressDictionary:srcAddr?@{@"Name":srcAddr}:nil] autorelease];
    //                MKPlacemark *dstPlaceMark = [[[MKPlacemark alloc] initWithCoordinate:[dstPoi point2CLCoordinate] addressDictionary:dstAddr?@{@"Name":dstAddr}:nil] autorelease];
    //                MKMapItem *srcLocation = [[[MKMapItem alloc] initWithPlacemark:srcPlaceMark] autorelease];
    //                MKMapItem *dstLocation = [[[MKMapItem alloc] initWithPlacemark:dstPlaceMark] autorelease];
    //                [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:srcLocation, dstLocation, nil]
    //                               launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeDriving, [NSNumber numberWithBool:YES], nil]
    //                                                                         forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, MKLaunchOptionsShowsTrafficKey, nil]]];
    //            } else {
    //                NSString *urlF  = @"http://maps.google.com/maps?daddr=%f,%f&saddr=%f,%f";
    //                /* NSString *url = [NSString stringWithFormat:urlF,
    //                 srcPoi.latitude, srcPoi.longitude,
    //                 dstPoi.latitude, dstPoi.longitude];*/
    //                NSString *url = [NSString stringWithFormat:urlF,
    //                                 srcPoi.longitude, srcPoi.latitude,
    //                                 dstPoi.longitude, dstPoi.latitude ];
    //                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    //            }
    //        }
    //    }
}
#pragma mark invoke js method
#pragma mark -----------------------------
/*
 *------------------------------------------------
 *@summay: 设置是否显示地图
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)showJS:(NSArray*)args
{
    self.hidden = NO;
    if ( !self.hidden ) {
        NSNumber *value = [args objectAtIndex:0];
        if ( value && [value isKindOfClass:[NSNumber class]] )
        {
            CGFloat left   = [[args objectAtIndex:0] floatValue];
            CGFloat top    = [[args objectAtIndex:1] floatValue];
            CGFloat width  = [[args objectAtIndex:2] floatValue];
            CGFloat height = [[args objectAtIndex:3] floatValue];
            self.frame = CGRectMake(left, top, width, height);
            [self resizeZoomControl];
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 设置是否显示地图
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)hideJS:(NSArray*)args
{
    //  NSNumber *value = [args objectAtIndex:0];
    // if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        self.hidden = YES;
    }
}

/*
 *------------------------------------------------
 *@summay: 调整地图的大小
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)resizeJS:(NSArray*)args
{
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        CGFloat left   = [[args objectAtIndex:0] floatValue];
        CGFloat top    = [[args objectAtIndex:1] floatValue];
        CGFloat width  = [[args objectAtIndex:2] floatValue];
        CGFloat height = [[args objectAtIndex:3] floatValue];
        self.frame = CGRectMake(left, top, width, height);
    }
}

/*
 *------------------------------------------------
 *@summay: 设置是否显示缩放控件
 *@param sender js pass
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)showZoomControlsJS:(NSArray*)args
{
    NSNumber *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        if ( [value boolValue] )
        {
            [self showZoomControl];
        }
        else
        {
            [self hideZoomControl];
        }
    }
}
@end

/*
 *------------------------------------------------
 *@ UIImage(InternalMethod)
 * 添加旋转图片的功能
 ------------------------------------------------
 */
#pragma mark ------------------------
@implementation UIImage(InternalMethod)

/*
 *------------------------------------------------
 *@summay: 自动获取高清图片接口
 *@param filepath NSString*文件按路径
 *@return
 *    UIImage*
 *@remark
 *------------------------------------------------
 */
+ (UIImage*)getRetainImage:(NSString *)filepath
{
    if ( filepath ){
        NSURL *loadUrl = nil;
        if ( [filepath hasPrefix:@"http://"]
            ||[filepath hasPrefix:@"file://"]) {
            loadUrl = [NSURL URLWithString:filepath];
        } else {
            loadUrl = [NSURL fileURLWithPath:filepath];
        }
        if ( loadUrl ) {
            if ( [[filepath lastPathComponent ] rangeOfString:@"@2x"].length
                ||  [[filepath lastPathComponent ] rangeOfString:@"@3x"].length)
            {
                if ([UIImage instancesRespondToSelector:@selector(initWithData:scale:)])
                {
                    return [UIImage imageWithData:[NSData dataWithContentsOfURL:loadUrl] scale:[UIScreen mainScreen].scale];
                }
                else
                {
                    UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:loadUrl]];
                    return [UIImage imageWithCGImage:img.CGImage scale:[UIScreen mainScreen].scale orientation:img.imageOrientation];
                }
            }
            return [UIImage imageWithData:[NSData dataWithContentsOfURL:loadUrl]];
        }
    }
    return nil;
}
@end
