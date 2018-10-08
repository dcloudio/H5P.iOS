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
#import <MAMapKit/MAMapKit.h>
#import "PGMapDefs.h"
@class PGMapView;

@interface PGMapCoordinate(MAMap)
+(NSArray*)coordinateListWithPoints:(MAMapPoint *)points count:(NSUInteger)count;
@end

/*
 ===========================================
 *@Marker创建的气泡对象对象
 *==========================================
 */
 
@protocol PGMapBubbleViewDelegate<NSObject>
-(void)click:(id)sender;
@end

//气泡视图
@interface PGMapBubbleView : UIView
{
@private
    //描述文本
    UILabel *_textView;
    UIImageView *_iconView;
}
@property (nonatomic, assign)id<PGMapBubbleViewDelegate> delegate;
@property(nonatomic, retain)NSString *bubbleLabel;
@property(nonatomic, retain)UIImage *bubbleImage;
@property(nonatomic, assign)BOOL userContentImg;
//当气泡内容改变时更细气泡
//- (void) reload;
@end

/*
 ===========================================
 *@Marker创建地图标点Marker对象
 *==========================================
 */
@interface PGMapMarker:MAPointAnnotation
{
    @private
    NSString *_baseURL;
    NSArray *_animationImages;
}
@property(nonatomic, assign)BOOL selected;
@property(nonatomic, assign)BOOL hidden;
@property(nonatomic, assign)PGMapView *belongMapview;
@property(nonatomic, retain)NSString *baseURL;
@property(nonatomic, retain)NSString *UUID;
@property(nonatomic, copy)NSString *label;//标点的文本标注
@property(nonatomic, copy)NSString *icon; //标点的图标
@property(nonatomic, retain)PGMapBubble *bubble; //关联的气泡
@property(nonatomic, assign)BOOL canDraggable;
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

@end

/*
 *@Marker创建地图标点MarkervView对象
 */
@interface PGMapMarkerView : MAAnnotationView<PGMapBubbleViewDelegate> {
    UIImageView *_annotationImageView;
}
- (void)reload;
- (void)reloadLabel:(BOOL)isLoadLabel loadIcon:(BOOL)isLoadIcon;
- (void)reloadBubble;
- (void)reloadBubbleLabel:(BOOL)isLoadLabel loadIcon:(BOOL)isLoadIcon;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) UIImage *portrait;
@property (nonatomic, strong) UIView *calloutView;
@end
