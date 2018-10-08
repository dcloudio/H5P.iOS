/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map_marker.h
 *  Description:
 *      地图标记和标记视图头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-10  创建文件
 *------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Base/BMKTypes.h>
#import <BaiduMapAPI_Map/BMKAnnotation.h>
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>
#import <BaiduMapAPI_Map/BMKPinAnnotationView.h>
#import "PGMapDefs.h"
@class PGBaiduMapView;

@interface PGMapCoordinate(BaiduMap)
+(NSArray*)coordinateListWithPoints:(BMKMapPoint *)points count:(NSUInteger)count;
@end

//气泡视图
@interface PGMapBubbleView : UIView
{
@private
    //描述文本
    UILabel *_textView;
    UIImageView *_iconView;
}

@property(nonatomic, assign)BOOL userContentImg;
@property(nonatomic, retain)NSString *bubbleLabel;
@property(nonatomic, retain)UIImage *bubbleImage;
//当气泡内容改变时更细气泡
- (void) reload;

@end

/*
 ===========================================
 *@Marker创建地图标点Marker对象
 *==========================================
 */
@interface PGMapMarker:BMKPointAnnotation
{
    @private
    NSString *_baseURL;
    NSArray *_animationImages;
}
@property(nonatomic, assign)BOOL selected;
@property(nonatomic, assign)BOOL hidden;
@property(nonatomic, assign)PGBaiduMapView *belongMapview;
@property(nonatomic, retain)NSString *baseURL;
@property(nonatomic, retain)NSString *UUID;
@property(nonatomic, copy)NSString *label;//标点的文本标注
@property(nonatomic, copy)NSString *icon; //标点的图标
@property(nonatomic, assign)BOOL canDraggable;
@property(nonatomic, retain)PGMapBubble *bubble; //关联的气泡
@property(nonatomic, retain, readonly)NSArray *animationImages;
@property(nonatomic, assign)CGFloat duration;

/**
 *转化js marker obj to
 */
+(PGMapMarker*)markerWithJSON:(NSMutableDictionary*)jsonObj baseURL:(NSString*)baseUL;
+(PGMapMarker*)markerWithArray:(NSArray*)jsonObj baseURL:(NSString*)baseURL;
//- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;
- (BOOL)updateObject:(NSMutableArray*)command;
- (NSString*)getFullPath:(NSString*)fileName;
- (void)setBaseURL:(NSString*)baseURL;
- (void)setAnimationImages:(NSArray *)animationImages;
@end

/*
*@Marker创建地图标点MarkervView对象
*/
@interface PGMapMarkerView : BMKPinAnnotationView<UIGestureRecognizerDelegate>
{
    // 文字的高度
    CGFloat _textHeight;
    UIImageView *_annotationImageView;
    UITapGestureRecognizer *_taprecognizer;
}@property(nonatomic, retain)UIImage *drawImage;
- (void)reload;
- (void)addTapGestureRecognizer;
@end
