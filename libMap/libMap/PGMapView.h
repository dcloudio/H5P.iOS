//
//  PGMapView.h
//  libMap
//
//  Created by DCloud on 2018/7/13.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "PDRNView.h"
#import "PGMapDefs.h"

@class PGMapPlugin;

@interface PGMapZoomControlView : UIStepper

@end

typedef NS_ENUM(NSInteger, PGMapViewPosition) {
    //地图控件在页面中正常布局模式，如果页面存在滚动条则随窗口内容滚动
    PGMapViewPositionStatic,
    // 地图控件在页面中绝对布局模式，如果页面存在滚动条不随窗口内容滚动
    PGMapViewPositionAbsolute
};
@class PGMapView;
@protocol PGMapViewDelegte
@required
- (id)initWithFrame:(CGRect)frame params:(NSDictionary*)setInfo;
- (int)zoomLevel;
- (void)setZoomLevel:(int)zl;
- (CLLocationCoordinate2D)centerCoordinate;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;
//userlocation
- (void)setShowsUserLocation:(BOOL)showsUserLocation;
- (BOOL)showsUserLocation;
- (CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(UIView *)view;
//callback
- (void)mapView:(PGMapView *)mapView didFailToLocateUserWithError:(NSError *)error;
- (void)mapView:(PGMapView *)mapView didUpdateUserLocation:(PGMapUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation;
- (void)mapView:(PGMapView *)mapView onClicked:(CLLocationCoordinate2D)coordinate;
- (void)mapViewRegionDidChange:(PGMapView *)mapView;
@end

@interface PGMapView : PDRNView<PGMapViewDelegte>{
     PGMapZoomControlView *_zoomControlView;
}
@property(nonatomic, assign)PGMapPlugin* jsBridge;
@property(nonatomic, retain)NSString* UUID;
@property(nonatomic, retain)NSString* webviewId;
@property(nonatomic, retain)PGMapUserLocation*userLocation;
@property(nonatomic, assign)PGMapViewPosition positionType;
//@property(nonatomic, assign)int zoom;

- (void)addEvtCallbackId:(NSString*)cbId;

+ (void)openSysMap:(NSArray*)command;
- (instancetype)initViewWithArray:(NSArray*)args;
- (id)initWithFrame:(CGRect)frame params:(NSDictionary*)setInfo;
//invoke js method
- (void)setStyles:(NSDictionary *)styles;
- (void)resizeJS:(NSArray*)args;
- (void)centerAndZoomJS:(NSArray*)args;
- (void)setCenterJS:(NSArray*)args;
- (void)setZoomJS:(NSArray*)args;
- (void)setMapTypeJS:(NSArray*)args;
- (void)showUserLocationJS:(NSArray*)args;
- (void)resetJS:(NSArray*)args;
- (void)setTrafficJS:(NSArray*)args;
- (void)hideJS:(NSArray*)args;
- (void)showJS:(NSArray*)args;
- (NSData*)getBoundsJS:(NSArray*)args;
- (void)addOverlayJS:(NSArray*)args;
- (void)removeOverlayJS:(NSArray*)args;
- (void)clearOverlaysJS:(NSArray*)args;

- (void)getCurrentCenterJS:(NSArray*)args;
- (void)getUserLocationJS:(NSArray*)args;

- (NSArray*)close;
//native
- (void)hideZoomControl;
- (void)resizeZoomControl;
- (void)showZoomControl;
- (int)MapToolFitZoom:(int)zoom;
@end



//导航图标旋转接口
@interface UIImage(InternalMethod)
+ (UIImage*)getRetainImage:(NSString *)filepath;
@end

