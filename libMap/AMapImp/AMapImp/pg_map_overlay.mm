/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map_overlay.mm
 *  Description:
 *      地图覆盖物实现文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2012-12-10  创建文件
 *   Reviewed @ 20130105 by Lin Xinzheng
 *------------------------------------------------------------------
 */

#import "pg_map_overlay.h"
#import "pg_map_marker.h"
#import "pg_map_view.h"
#import "PDRToolSystemEx.h"


UIColor* NSString2UIColor(NSString* color)
{
    return [UIColor colorWithCSS:color];
}

typedef enum {
    PGMapOverlayPropertyFillColor,
    PGMapOverlayPropertyFillOpacity,
    PGMapOverlayPropertyStrokeColor,
    PGMapOverlayPropertyStrokeOpacity,
    PGMapOverlayPropertyLineWidth
}PGMapOverlayPropertyType;

@implementation PGMapOverlayBase
@synthesize UUID;
@synthesize belongMapview;
@synthesize hidden;

-(void)dealloc
{
    self.UUID = nil;
    [super dealloc];
}

@end

/*
*@Overlay基类
*/
#pragma mark ------------------------
@implementation PGMapOverlay

@synthesize fillColor;
@synthesize fillOpacity;
@synthesize strokeColor;
@synthesize strokeOpacity;
@synthesize lineWidth;
@synthesize overlay;
//@synthesize overlayView;

-(void)dealloc
{
    self.overlay = nil;
  //  self.overlayView = nil;
    self.fillColor = nil;
    self.strokeColor = nil;
    [super dealloc];
}

/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapOverlay对象
 *@param jsobj 
 *@return
 *@remark
 *------------------------------------------------
 */
- (id)initWithJSON:(NSMutableDictionary*)jsobj
{
    if ( self = [super init] )
    {
        self.fillColor = [UIColor blackColor];
        self.fillOpacity = 1.0f;
        self.strokeColor = [UIColor blackColor];
        self.strokeOpacity = 1.0f;
        self.lineWidth = 5.0f;
        self.hidden = false;
        return self;
    }
    return nil;
}

- (void)setProperty:(PGMapOverlayPropertyType)property newValue:(id)value {
    MAOverlayPathView *overlayView = (MAOverlayPathView*)[self.belongMapview viewForOverlay:self.overlay];
    if ( overlayView ) {
        switch (property) {
            case PGMapOverlayPropertyFillColor:
                overlayView.fillColor = self.fillColor;
                //break;
            case PGMapOverlayPropertyFillOpacity:
                //overlayView.fillColor = self.fillColor;
                break;
            case PGMapOverlayPropertyStrokeColor:
                //overlayView.strokeColor = self.strokeColor;
                //break;
            case PGMapOverlayPropertyStrokeOpacity:
                overlayView.strokeColor = self.strokeColor;
                break;
            case PGMapOverlayPropertyLineWidth:
                overlayView.lineWidth = self.lineWidth;
                break;
            default:
                break;
        }
        [overlayView setNeedsDisplay];
    }
   
}

//js invoke method
- (BOOL)setFillColorJS:(NSArray*)args
{
    NSString *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSString class]] )
    {
        [self updateFillColor:value];
     //   [self.overlayView setNeedsDisplay];
        //return TRUE;
    }
    return FALSE;
}

//js invoke method
- (BOOL)setFillOpacityJS:(NSArray*)args
{
    NSNumber *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        [self updateFillOpacity:[value floatValue]];
     //   [self.overlayView setNeedsDisplay];
        //return TRUE;
    }
    return FALSE;
}

//js invoke method
- (BOOL)setStrokeColorJS:(NSArray*)args
{
    NSString *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSString class]] )
    {
        [self updateStrokeColor:value];
       // [self.overlayView setNeedsDisplay];
        // return TRUE;
    }
    return FALSE;
}

//js invoke method
- (BOOL)setStrokeOpacityJS:(NSArray*)args
{
    NSNumber *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        [self updateStrokeOpacity:[value floatValue]];
     //   [self.overlayView setNeedsDisplay];
        // return TRUE;
    }
    return FALSE;
}

//js invoke method
- (BOOL)setLineWidthJS:(NSArray*)args
{
    NSNumber *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        [self updateLineWidth:[value floatValue]];
       // [self.overlayView setNeedsDisplay];
        // return TRUE;
    }
    return FALSE;
}

//js invoke method
- (BOOL)showJS:(NSArray*)args
{
   // self.overlayView.hidden = NO;
    self.hidden = NO;
    [self.belongMapview setMapOverlay:self isVisable:true];
    return FALSE;
}

//js invoke method
- (BOOL)hideJS:(NSArray*)args
{
    //self.overlayView.hidden = YES;
    self.hidden = YES;
    [self.belongMapview setMapOverlay:self isVisable:false];
    return FALSE;
}

/*
 *------------------------------------------------
 *@summay: 设置覆盖物的线条颜色
 *@param value 
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)updateStrokeColor:(NSString*)value
{
    UIColor *innerStrokeColor = NSString2UIColor(value);
    if ( innerStrokeColor )
    {
        if ( self.strokeColor )
        {
            CGFloat alpha = 1.0f;
            [self.strokeColor getRed:nil green:nil blue:nil alpha:&alpha];
            self.strokeColor = [innerStrokeColor colorWithAlphaComponent:alpha];
        } else {
            self.strokeColor = innerStrokeColor;
        }
       // overlayView.strokeColor = innerStrokeColor;
        //self.strokeColor = innerStrokeColor;
        [self setProperty:PGMapOverlayPropertyStrokeColor newValue:self.strokeColor];
        //[self setProperty:PGMapOverlayPropertyStrokeColor newValue:newColor];
    }
}

/*
 *------------------------------------------------
 *@summay: 设置覆盖物的线条透明度
 *@param value
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)updateStrokeOpacity:(CGFloat)opactiy
{
    UIColor *oldColor = self.strokeColor;
    CGFloat red = 1.0f;
    CGFloat green = 1.0f;
    CGFloat blue = 1.0f;
    CGFloat alpha = 1.0f;
    if ( oldColor )
    {
        [oldColor getRed:&red green:&green blue:&blue alpha:&alpha];
        UIColor *newColor = [UIColor colorWithRed:red green:green blue:blue alpha:opactiy];
       // overlayView.strokeColor = newColor;
        self.strokeColor = newColor;
        self.strokeOpacity = opactiy;
        [self setProperty:PGMapOverlayPropertyStrokeColor newValue:newColor];
    }
}

/*
 *------------------------------------------------
 *@summay: 设置覆盖物的线条填充色
 *@param value
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)updateFillColor:(NSString*)value
{
    UIColor *innerFillColor = NSString2UIColor(value);
    if ( innerFillColor )
    {
        if ( self.fillColor )
        {
            CGFloat alpha = 1.0f;
            [self.fillColor getRed:nil green:nil blue:nil alpha:&alpha];
            self.fillColor = [innerFillColor colorWithAlphaComponent:alpha];
        } else {
            self.fillColor = innerFillColor;
        }
        //overlayView.fillColor = innerFillColor;
        [self setProperty:PGMapOverlayPropertyFillColor newValue:innerFillColor];
    }
}

/*
 *------------------------------------------------
 *@summay: 设置覆盖物的线条填充色透明度
 *@param value
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)updateFillOpacity:(CGFloat)opactiy
{
    UIColor *oldColor = self.fillColor;//overlayView.fillColor;
    CGFloat red = 1.0f;
    CGFloat green = 1.0f;
    CGFloat blue = 1.0f;
    CGFloat alpha = 1.0f;
    if ( oldColor )
    {
        [oldColor getRed:&red green:&green blue:&blue alpha:&alpha];
        UIColor *newColor = [UIColor colorWithRed:red green:green blue:blue alpha:opactiy];
      //  overlayView.fillColor = newColor;
        self.fillColor = newColor;
        self.fillOpacity = opactiy;
        [self setProperty:PGMapOverlayPropertyFillColor newValue:newColor];
    }
}

/*
 *------------------------------------------------
 *@summay: 设置覆盖物的线条宽度
 *@param value
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)updateLineWidth:(CGFloat)value
{
  //  overlayView.lineWidth = value;
    self.lineWidth = value;
    [self setProperty:PGMapOverlayPropertyLineWidth newValue:nil];
}

@end

/*
*@PGMapCircle对象用于在地图上显示的圆，从PGMapOverlay对象继承而来
*/
#pragma mark ------------------------
@implementation PGMapCircle

@synthesize center;
@synthesize radius;

-(void)dealloc
{
    self.center = nil;
    [super dealloc];
}

/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapCircle对象
 *@param jsonObj
 *@return
 *@remark
 *------------------------------------------------
 */
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args
{
    if ( self = [super initWithJSON:nil])
    {
        self.UUID = uID;
        if ( args && [args isKindOfClass:[NSArray class]] )
        {
            PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:[args objectAtIndex:0]];
            NSNumber *radiusJSValue = [args objectAtIndex:1];
            if ( [radiusJSValue isKindOfClass:[NSString class]]
                ||[radiusJSValue isKindOfClass:[NSNumber class]] ) {
                self.radius = [radiusJSValue floatValue];
            }
            [self updateWithCenter:point radius:self.radius];
        }
    }
    return self;
}

/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapPolygon对象
 *@param jsonObj
 *@return
 *@remark
 *------------------------------------------------
 */
+(PGMapCircle*)circleWithJSON:(NSMutableDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    PGMapCircle *circle = [[[PGMapCircle alloc] initWithJSON:jsonObj] autorelease];
    if ( circle )
    {
        circle.UUID = [jsonObj objectForKey:@"_UUID_"];
        CLLocationDistance radius = [[jsonObj objectForKey:@"radius"] floatValue];
        PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"center"]];
        [circle updateWithCenter:point radius:radius];
    }
    return circle;
}

/*
 *------------------------------------------------
 *@summay: 设置圆的中心位置和半径
 *@param 
 *    [1] point 中心点
 *    [1] innerRadius 半径
 *@return
 *@remark
 *------------------------------------------------
 */
-(void)updateWithCenter:(PGMapCoordinate*)point radius:(CGFloat)innerRadius
{
    if ( !point )
        return;
    
    MACircle *circle = [MACircle circleWithCenterCoordinate:[point point2CLCoordinate] radius:innerRadius];
//    MACircleView *circleView = [[[MACircleView alloc]initWithCircle:circle] autorelease];
//    circleView.fillColor = self.fillColor;
//    circleView.strokeColor = self.strokeColor;
//    circleView.lineWidth = self.lineWidth;
//    circleView.hidden = self.hidden;
    
    self.overlay = circle;
  //  self.overlayView = circleView;
    
    self.center = point;
    self.radius = innerRadius;
}

/*
 *------------------------------------------------
 *@summay: 修改对象属性
 *@param
 *   jsonObjinvoke js method
 *@return
 *  BOOL 属性是否修改
 *@remark
 *------------------------------------------------
 */
-(BOOL)setCenterJS:(NSArray*)args
{
    NSMutableDictionary *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSMutableDictionary class]] )
    {
        PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:value];
        if ( point )
        {
            PGMapView *innerBelogMapView = self.belongMapview;
            [innerBelogMapView removeMapOverlay:self];
            [self updateWithCenter:point radius:self.radius];
            [innerBelogMapView addMapOverlay:self];
            return TRUE;
        }
    }
    return TRUE;
}

/*
 *------------------------------------------------
 *@summay: invoke js method
 *@param
 *   jsonObj
 *@return
 *  BOOL 属性是否修改
 *@remark
 *------------------------------------------------
 */
-(BOOL)setRadiusJS:(NSArray*)args
{
    NSNumber *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSNumber class]] )
    {
        PGMapView *innerBelogMapView = self.belongMapview;
        [innerBelogMapView removeMapOverlay:self];
        CLLocationDistance innerRadius = [value doubleValue];
        [self updateWithCenter:self.center radius:innerRadius];
        [innerBelogMapView addMapOverlay:self];
        return TRUE;
    }
    return TRUE;
}

@end

/*
*@PGMapPolygon对象用于在地图上显示的多边形，从PGMapOverlay对象继承而来
*/
#pragma mark ------------------------
@implementation PGMapPolygon
/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapPolygon对象
 *@param jsonObj
 *@return
 *@remark
 *------------------------------------------------
 */
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args
{
    if ( self = [super initWithJSON:nil] )
    {
        self.UUID = uID;
        if ( args && [args isKindOfClass:[NSArray class]] )
        {
            NSArray *points = [args objectAtIndex:0];
            [self updateWithPath:points];
        }
    }
    return self;
}
/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapPolygon对象
 *@param jsonObj 
 *@return
 *@remark
 *------------------------------------------------
 */
+(PGMapPolygon*)polygonWithJSON:(NSMutableDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;

    PGMapPolygon *polygon = [[[PGMapPolygon alloc] initWithJSON:jsonObj] autorelease];
    if ( polygon )
    {
        polygon.UUID = [jsonObj objectForKey:@"_UUID_"];
        NSArray *points = [jsonObj objectForKey:@"path"];
        [polygon updateWithPath:points];
    }
    return polygon;
}

/*
 *------------------------------------------------
 *@summay: 修改多边形路径
 *@param 
 *     [1] path
 *@return
 *@remark
 *------------------------------------------------
 */
-(void)updateWithPath:(NSArray*)path
{
    if ( path && [path isKindOfClass:[NSArray class]] )
    {
        NSArray *points = [PGMapCoordinate arrayWithJSON:path];
        if ( points )
        {
            NSInteger count = [path count];
            CLLocationCoordinate2D *coordinates = [PGMapCoordinate array2CLCoordinatesAlloc:points];
            if ( coordinates )
            {
                MAPolygon *polygon = [MAPolygon polygonWithCoordinates:coordinates count:count];
//                MAPolygonView *polygonView = [[[MAPolygonView alloc] initWithPolygon:polygon] autorelease];
//                polygonView.fillColor = self.fillColor;
//                polygonView.strokeColor = self.strokeColor;
//                polygonView.lineWidth = self.lineWidth;
//                polygonView.hidden = self.hidden;
                delete []coordinates;
                
                self.overlay = polygon;
               // self.overlayView = polygonView;
            }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 修改对象属性
 *@param
 *   jsonObj
 *@return
 *  BOOL 属性是否修改
 *@remark
 *------------------------------------------------
 */
- (BOOL)setPathJS:(NSArray*)args
{
    NSArray *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSArray class]] )
    {
        PGMapView *innerBelogMapView = self.belongMapview;
        [innerBelogMapView removeMapOverlay:self];
        [self updateWithPath:value];
        [innerBelogMapView addMapOverlay:self];
        return FALSE;
    }
    return TRUE;
}

@end

/*
*@PGMapPolyline对象用于在地图上显示的折线，从PGMapOverlay对象继承而来
*/
#pragma mark ------------------------
@implementation PGMapPolyline
/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapPolygon对象
 *@param jsonObj
 *@return
 *    PGMapPolyline*
 *@remark
 *------------------------------------------------
 */
-(id)initWithUUID:(NSString*)uID args:(NSArray*)args
{
    if ( self = [super initWithJSON:nil] )
    {
        self.UUID = uID;
        if ( args && [args isKindOfClass:[NSArray class]] )
        {
            NSArray *points = [args objectAtIndex:0];
            [self updateWithPath:points];
        }
    }
    return self;
}
/*
 *------------------------------------------------
 *@summay: 根据jsobj生成PGMapPolygon对象
 *@param jsonObj
 *@return
 *    PGMapPolyline*
 *@remark
 *------------------------------------------------
 */
+(PGMapPolyline*)polylineWithJSON:(NSMutableDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    
    PGMapPolyline *polyline = [[[PGMapPolyline alloc] initWithJSON:jsonObj] autorelease];
    if ( polyline )
    {
        polyline.UUID = [jsonObj objectForKey:@"_UUID_"];
        NSArray *points = [jsonObj objectForKey:@"path"];
        [polyline updateWithPath:points];
    }
    return polyline;
}

-(void)updateWithPath:(NSArray*)path
{
    if ( path && [path isKindOfClass:[NSArray class]] )
    {
        NSInteger count = [path count];
        NSArray *points = [PGMapCoordinate arrayWithJSON:path];
        if ( points )
        {
            CLLocationCoordinate2D *coordinates = [PGMapCoordinate array2CLCoordinatesAlloc:points];
            if ( coordinates )
            {
                MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
//                MAPolylineView *polylineView = [[[MAPolylineView alloc] initWithPolyline:polyline] autorelease];
//                polylineView.fillColor = self.fillColor;
//                polylineView.strokeColor = self.strokeColor;
//                polylineView.lineWidth = self.lineWidth;
//                polylineView.hidden = self.hidden;
                delete []coordinates;
                
                self.overlay = polyline;
              //  self.overlayView = polylineView;
            }
        }
    }
}

/*
 *------------------------------------------------
 *@summay: 修改对象属性
 *@param
 *   jsonObj
 *@return
 *  BOOL 属性是否修改
 *@remark
 *------------------------------------------------
 */
- (BOOL)setPathJS:(NSArray*)args
{
    NSArray *value = [args objectAtIndex:0];
    if ( value && [value isKindOfClass:[NSArray class]] )
    {
        PGMapView *innerBelogMapView = self.belongMapview;
        [innerBelogMapView removeMapOverlay:self];
        [self updateWithPath:value];
        [innerBelogMapView addMapOverlay:self];
        return FALSE;
    }
    return FALSE;
}

@end