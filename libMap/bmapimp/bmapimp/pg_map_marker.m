/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map_marker.mm
 *  Description:
 *      地图标记和标记视图实现文件
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

#import "pg_map_marker.h"
#import "pg_map_view.h"
#import "pg_map.h"
#import "PTPathUtil.h"
#import "NSData+Base64.h"
#import <BaiduMapAPI_Map/BMKActionPaopaoView.h>
#import "H5CoreJavaScriptText.h"

// 标记排版时图片和文字之间的间隙
#define PG_MAP_MARKERVIEW_GAP 2.0f
// 标记使用文字的尺寸
#define PG_MAP_MARKERVIEW_TEXTFONTSIZE 12.0f


@implementation PGMapCoordinate

@synthesize latitude;
@synthesize longitude;

/*
 *------------------------------------------------
 *@summay:  根据经纬度生成PGMapCoordinate对象
 *@param 
 *  [1] longitude
 *  [2] latitude
 *@return
 *   PGMapCoordinate*
 *@remark
 *------------------------------------------------
 */
+(PGMapCoordinate*)pointWithLongitude:(CLLocationDegrees)longitude latitude:(CLLocationDegrees)latitude
{
    PGMapCoordinate *point = [[[PGMapCoordinate alloc] init] autorelease];
    point.latitude = latitude;
    point.longitude = longitude;
    return point;
}

/*
 *------------------------------------------------
 *@summay: 根据json数据数组生成PGMapCoordinate对象数组
 *@param jsonObj 
 *@return
 *     NSArray* PGMapCoordinate对象数组
 *@remark
 *------------------------------------------------
 */
+(NSArray*)arrayWithJSON:(NSArray*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSArray class]] )
        return nil;
    
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:10];
    for ( NSMutableDictionary *dict in jsonObj )
    {
        PGMapCoordinate *point =  [PGMapCoordinate pointWithJSON:dict];
        if ( point )
            [objects addObject:point];
    }
    return objects;
}

/*
 *------------------------------------------------
 *@summay: 根据json数据生成PGMapCoordinate对象
 *@param jsonObj
 *@return
 *     PGMapCoordinate* PGMapCoordinate对象
 *@remark
 *------------------------------------------------
 */
+(PGMapCoordinate*)pointWithJSON:(NSDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSDictionary class]] )
        return nil;
    
    PGMapCoordinate *point = [[[PGMapCoordinate alloc] init] autorelease];
    
    NSNumber *longitude = [jsonObj objectForKey:@"longitude"];
    if ( [longitude isKindOfClass:[NSNumber class]]
        || [longitude isKindOfClass:[NSString class]])
        point.longitude = [longitude floatValue];
    
    NSNumber *latitude = [jsonObj objectForKey:@"latitude"];
    if ([latitude isKindOfClass:[NSNumber class]]
        || [latitude isKindOfClass:[NSString class]])
        point.latitude = [latitude floatValue];

    return point;
}

-(NSDictionary*)toJSON
{
    return @{@"longitude":@(self.longitude),@"latitude":@(self.latitude)};
}


/*
 *------------------------------------------------
 *@summay: 将PGMapCoordinate转化为js对象
 *@param 
 *@return
 *     NSString* 生成js对象的function
 *@remark
 *------------------------------------------------
 */
-(NSString*)JSObject
{
    NSString *jsonObjectFormat =
    @"function (){\
        var point = new plus.maps.Point(%f, %f);\
        return point;\
    }()";
    return [NSString stringWithFormat:jsonObjectFormat, self.longitude, self.latitude];
    /*
    NSString *jsonObjectFormat = @"{ \"point\":{\"longitude\":%f, \"latitude\":%f }}";
    return [NSString stringWithFormat:jsonObjectFormat, self.longitude, self.latitude];*/
}

/*
 *------------------------------------------------
 *@summay: 将经纬度字符串转化为经纬度数组
 *@param
 * coordinateList 格式：log1,lat1,log2,lat2....
 *@return
 *     NSArray* PGMapCoordinate对象数组
 *@remark
 *------------------------------------------------
 */
+(NSArray*)coordinateListString2Array:(NSString*)coordinateList
{
    if ( coordinateList )
    {
        NSArray *coordinateLists = [coordinateList componentsSeparatedByString:@","];
        if ( [coordinateLists count] )
        {
            NSMutableArray *points = [NSMutableArray arrayWithCapacity:10];
            for (int index = 0; index < [coordinateLists count]; index+=2 )
            {
                PGMapCoordinate *point = [PGMapCoordinate pointWithLongitude:[[coordinateLists objectAtIndex:index] doubleValue]
                                                            latitude:[[coordinateLists objectAtIndex:index+1] doubleValue]];
                if ( point )
                    [points addObject:point];
            }
            return points;
        }
    }
    return nil;
}

/*
 *------------------------------------------------
 *@summay: 将经纬度字符串转化为经纬度数组
 *@param
 * coordinateList 格式：log1,lat1,log2,lat2....
 *@return
 *     NSArray* PGMapCoordinate对象数组
 *@remark
 *------------------------------------------------
 */
+(NSArray*)coordinateListWithPoints:(BMKMapPoint *)points count:(NSUInteger)count
{
    if ( points )
    {
        NSMutableArray *pointList = [NSMutableArray arrayWithCapacity:10];
        for (int index = 0; index < count; index++)
        {
            BMKMapPoint point = points[index];
            PGMapCoordinate *pdrPt = [PGMapCoordinate pointWithLongitude:point.x latitude:point.y];
            [pointList addObject:pdrPt ];
        }
        return pointList;
    }
    return nil;
}

/*
 *------------------------------------------------
 *@summay: 获取CLLocationCoordinate2D格式的经纬度
 *@param
 * 
 *@return
 *     CLLocationCoordinate2D 经纬度
 *@remark
 *------------------------------------------------
 */
-(CLLocationCoordinate2D)point2CLCoordinate
{
    CLLocationCoordinate2D coordinate = { self.latitude, self.longitude };
    return coordinate;
}

/*
 *------------------------------------------------
 *@summay: 获取coordinates经纬度数组
 *@param
 *      coordinates PGMapCoordinate*对象数组
 *@return
 *     CLLocationCoordinate2D* 经纬度数组
 *@remark
 *------------------------------------------------
 */
+(CLLocationCoordinate2D*)array2CLCoordinatesAlloc:(NSArray*)coordinates
{
    NSInteger count = [coordinates count];
    if ( coordinates && count)
    {
        CLLocationCoordinate2D* points =  malloc( sizeof(CLLocationCoordinate2D)*count);
        for ( int i = 0; i < count; i++ )
        {
            PGMapCoordinate *point = (PGMapCoordinate*)[coordinates objectAtIndex:i];
            points[i] = [point point2CLCoordinate];
        }
        return points;
    }
    return NULL;
}

@end

@implementation PGMapBounds

@synthesize northease;
@synthesize southwest;

+(PGMapBounds*)boundsWithJSON:(NSMutableDictionary*)jsonObj {
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    PGMapCoordinate *tmpNorthease = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"northease"]];
    PGMapCoordinate *tmpSouthwest = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"southwest"]];
    
    if ( tmpNorthease && tmpSouthwest ) {
        PGMapBounds *bounds = [[[PGMapBounds alloc] init] autorelease];
        bounds.northease = tmpNorthease;
        bounds.southwest = tmpSouthwest;
        return bounds;
    }
    return nil;
}

+(PGMapBounds*)boundsWithNorthEase:(CLLocationCoordinate2D)northease
                         southWest:(CLLocationCoordinate2D)southwest {
    PGMapBounds *bounds = [[[PGMapBounds alloc] init] autorelease];
    bounds.northease = [PGMapCoordinate pointWithLongitude:northease.longitude latitude:northease.latitude];
    bounds.southwest = [PGMapCoordinate pointWithLongitude:southwest.longitude latitude:southwest.latitude];
    return bounds;
}

- (NSDictionary*)toJSON {
    return @{@"northease":[self.northease toJSON],@"southwest":[self.southwest toJSON]};
}
@end

#pragma PGMapBubble
#pragma mark -----------------
@implementation PGMapBubble
@synthesize label;
@synthesize icon;
@synthesize contentImage;
-(void)dealloc
{
    [label release];
    [icon release];
    self.contentImage = nil;
    [super dealloc];
}

/*
 *------------------------------------------------
 *@summay: 根据json数据创建bubble对象
 *@param jsonObj js 对象
 *@return
 *   PGMapBubble *    
 *@remark
 *------------------------------------------------
 */
+(PGMapBubble*)bubbleWithJSON:(NSMutableDictionary*)jsonObj
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    
    PGMapBubble *bubble = [[[PGMapBubble alloc] init] autorelease];
    
    NSString *lable = [jsonObj objectForKey:@"label"];
    if ( lable && [lable isKindOfClass:[NSString class]] )
        bubble.label = lable;
    
    NSString *icon = [jsonObj objectForKey:@"icon"];
    if ( icon && [icon isKindOfClass:[NSString class]] )
        bubble.icon = icon;
    
    return bubble;
}

@end

#pragma PGMapBubble
#pragma mark -----------------
// 标记排版时图片和文字之间的间隙
#define MKEYMAP_MARKERVIEW_GAP 4.0f
// 标记使用文字的尺寸
#define MKEYMAP_MARKERVIEW_TEXTFONTSIZE 15.0f
// 二级标题文字的尺寸
#define MKEYMAP_MARKERVIEW_SUBTITLEFONTSIZE 12.0f
#define MEKYMAP_MARKERVIEW_FONT [UIFont systemFontOfSize:MKEYMAP_MARKERVIEW_TEXTFONTSIZE]
//气泡使用的字体
#define MEKYMAP_MARKERVIEW_BUBBLE_FONT MEKYMAP_MARKERVIEW_FONT

//static CGFloat kTransitionDuration = 0.45f;

/*
 ** @气泡视图实现
 *
 */
@implementation PGMapBubbleView

@synthesize bubbleLabel;
@synthesize bubbleImage;
@synthesize userContentImg;
- (id)initWithFrame:(CGRect)frame
{
    if ( (self = [super initWithFrame:frame] ) )
    {
        UIImage *imageNormal, *imageHighlighted;
        imageNormal = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_left"] stretchableImageWithLeftCapWidth:10 topCapHeight:13];
        imageHighlighted = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_left_highlighted"]
                            stretchableImageWithLeftCapWidth:10 topCapHeight:13];
        UIImageView *leftBgd = [[UIImageView alloc] initWithImage:imageNormal
                                                 highlightedImage:imageHighlighted];
        leftBgd.tag = 11;
        
        imageNormal = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_right"] stretchableImageWithLeftCapWidth:10 topCapHeight:13];
        imageHighlighted = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_right_highlighted"]
                            stretchableImageWithLeftCapWidth:10 topCapHeight:13];
        UIImageView *rightBgd = [[UIImageView alloc] initWithImage:imageNormal
                                                  highlightedImage:imageHighlighted];
        rightBgd.tag = 12;
        
        [self addSubview:leftBgd];
        [self sendSubviewToBack:leftBgd];
        [self addSubview:rightBgd];
        [self sendSubviewToBack:rightBgd];
        [leftBgd release];
        [rightBgd release];
    }
    return self;
}

- (void) reload
{
    //加上箭头的高度
    
	
}
-(void)dealloc
{
    [_textView removeFromSuperview];
    [_textView release];
    [_iconView removeFromSuperview];
    [_iconView release];
    [super dealloc];
}

-(void)layoutSubviews
{
    CGSize size = CGSizeZero;
    size.width += 4*MKEYMAP_MARKERVIEW_GAP;
    size.height += 2*MKEYMAP_MARKERVIEW_GAP;
    
    if ( _textView && !self.userContentImg )
    {
        CGRect textRect = _textView.bounds;
        textRect.origin.x = 2*MKEYMAP_MARKERVIEW_GAP;
        textRect.origin.y = MKEYMAP_MARKERVIEW_GAP;
        size.width += _textView.bounds.size.width;
        size.height += _textView.bounds.size.height;
        _textView.frame = textRect;
    }
    
    if( _iconView )
    {
        size.width += _iconView.bounds.size.width;
        if ( _textView.bounds.size.height < _iconView.bounds.size.height )
        { size.height += (_iconView.bounds.size.height - _textView.bounds.size.height); }
        CGRect imgRect = _iconView.bounds;
        if ( _textView )
        { imgRect.origin.x = _textView.bounds.size.width + 2*MKEYMAP_MARKERVIEW_GAP; }
        imgRect.origin.y = MKEYMAP_MARKERVIEW_GAP;
        _iconView.frame = imgRect;
    }
    
    //加上箭头的高度
    if ( !self.userContentImg ) {
        size.height += 12;
    }
    CGRect rect0 = self.bounds;
	rect0.size = CGSizeMake( size.width, size.height);
	//self.frame = rect0;
    
    CGFloat halfWidth = rect0.size.width/2;
    UIView *image = [self viewWithTag:11];
    CGRect iRect = CGRectZero;
    iRect.size.width = halfWidth;
    iRect.size.height = rect0.size.height;
    image.frame = iRect;
    image = [self viewWithTag:12];
    iRect.origin.x = halfWidth;
    image.frame = iRect;
    self.bounds = CGRectMake(0, 0, size.width, size.height);
}

-(void)setBubbleLabel:(NSString *)text
{
    if ( !text || self.userContentImg )
    { return; }
    
    if ( !_textView )
    {
        _textView = [[UILabel alloc] init];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = [UIColor blackColor];
        _textView.font = [UIFont systemFontOfSize:PG_MAP_MARKERVIEW_TEXTFONTSIZE];
        [self addSubview:_textView];
    }
    NSArray *subTexts = [text componentsSeparatedByString:@"\n"];
    if ( [subTexts count] > 1 )
    { _textView.numberOfLines = [subTexts count]; }
    _textView.text = text;
    [_textView sizeToFit];
    
    [self layoutSubviews];
}

-(void)setContentImage:(UIImage *)img
{
    if ( !img )
    { return; }
    self.userContentImg = true;
    UIView *image = [self viewWithTag:11];
    image.hidden = YES;
    image = [self viewWithTag:12];
    image.hidden = YES;
    _textView.frame = CGRectZero;
    _textView.hidden = YES;
    if ( !_iconView )
    {
        _iconView = [[UIImageView alloc] init];
        [self addSubview:_iconView];
    }
    _iconView.image = img;
    [_iconView sizeToFit];
    [self layoutSubviews];
}

-(void)setBubbleImage:(UIImage *)img
{
    if ( !img || self.userContentImg)
    { return; }
    
    if ( !_iconView )
    {
        _iconView = [[UIImageView alloc] init];
        [self addSubview:_iconView];
    }
    _iconView.image = img;
    [_iconView sizeToFit];
    [self layoutSubviews];
}

@end

#pragma PGMapBubble
#pragma mark -----------------
@implementation PGMapMarker
@synthesize animationImages = _animationImages;
@synthesize duration;
@synthesize selected;
@synthesize belongMapview;
@synthesize UUID;
@synthesize label;
@synthesize icon;
@synthesize bubble;
@synthesize hidden;
@synthesize baseURL = _baseURL;
@synthesize canDraggable;

- (void)dealloc
{
    [_animationImages release];
    [_baseURL release];
    [UUID release];
    [label release];
    [icon release];
    [bubble release];
    [super dealloc];
}

/*
 *------------------------------------------------
 *@summay: 根据json格式的js对象生成native对象
 *@param
 *       [1] jsonObj json对象
 *       [2] baseURL baseurl
 *@return
 *        PGMapMarker*
 *@remark
 *------------------------------------------------
 */
+(PGMapMarker*)markerWithArray:(NSArray*)jsonObj baseURL:(NSString*)baseURL
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSArray class]] )
        return nil;
    
    PGMapMarker *marker = [[[PGMapMarker alloc] init] autorelease];
    
    marker.baseURL = [baseURL retain];
    
    PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:[jsonObj objectAtIndex:0]];
    marker.coordinate = [point point2CLCoordinate];
    
    if ( !marker.bubble )
        marker.bubble = [[[PGMapBubble alloc] init] autorelease];
    
    return marker;
}

/*
 *------------------------------------------------
 *@summay: 根据json格式的js对象生成native对象
 *@param
 *       [1] jsonObj json对象
 *       [2] baseURL baseurl
 *@return
 *        PGMapMarker*
 *@remark
 *------------------------------------------------
 */
+(PGMapMarker*)markerWithJSON:(NSMutableDictionary*)jsonObj baseURL:(NSString*)baseURL
{
    if ( !jsonObj )
        return nil;
    if ( ![jsonObj isKindOfClass:[NSMutableDictionary class]] )
        return nil;
    
    PGMapMarker *marker = [[[PGMapMarker alloc] init] autorelease];
    
    marker.baseURL = [baseURL retain];
    
    NSString *UUID = [jsonObj objectForKey:@"_UUID_"];
    if ( UUID && [UUID isKindOfClass:[NSString class]])
        marker.UUID = UUID;
    
    NSString *label = [jsonObj objectForKey:@"caption"];
    if ( label && [label isKindOfClass:[NSString class]])
        marker.label = label;
    
    NSString *icon = [jsonObj objectForKey:@"icon"];
    if ( icon && [icon isKindOfClass:[NSString class]])
        marker.icon = [marker getFullPath:icon];
    
    marker.bubble = [PGMapBubble bubbleWithJSON:[jsonObj objectForKey:@"bubble"]];
    {
        PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:[jsonObj objectForKey:@"point"]];
        // [marker setCoordinate:[point point2CLCoordinate]];
        marker.coordinate = [point point2CLCoordinate];
    }
    if ( !marker.bubble )
        marker.bubble = [[[PGMapBubble alloc] init] autorelease];
    
    if ( marker.bubble.icon )
        marker.bubble.icon = [marker getFullPath:marker.bubble.icon];
    return marker;
}

- (void)setAnimationImages:(NSArray *)animationImages {
    if ( _animationImages ) {
        [_animationImages release];
        _animationImages = nil;
    }
    if ( [animationImages count] ) {
        _animationImages = [animationImages retain];
    }
    
}

-(BOOL)setPoint:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSMutableDictionary *dict = [args objectAtIndex:0];
        if ( dict && [dict isKindOfClass:[NSMutableDictionary class]] )
        {
            PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:dict];
            if ( point )
            {
                [self setCoordinate:[point point2CLCoordinate]];
                bRet = TRUE;
            }
        }
    }
    return bRet;
}

-(BOOL)__setIcon:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        self.icon = nil;
        NSString *value = [args objectAtIndex:0];
        if ( value && [value isKindOfClass:[NSString class]] )
            self.icon = [self getFullPath:value];
        bRet = TRUE;
    }
    return bRet;
}

-(BOOL)__setLabel:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        self.label = nil;
        NSString *value = [args objectAtIndex:0];
        if ( value && [value isKindOfClass:[NSString class]] )
            self.label = value;
        bRet =  TRUE;
    }
    return bRet;
}

-(BOOL)setBubbleLabel:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        self.bubble.label = nil;
        NSString *labelValue = [args objectAtIndex:0];
        if ( labelValue && [labelValue isKindOfClass:[NSString class]] )
            self.bubble.label = labelValue;
        bRet = TRUE;
    }
    return bRet;
}

-(BOOL)setBubbleIcon:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        self.bubble.icon = nil;
        NSString *value = [args objectAtIndex:0];
        if ( value && [value isKindOfClass:[NSString class]] )
            self.bubble.icon = [self getFullPath:value];
        bRet = TRUE;
    }
    return bRet;
}

-(BOOL)setBubbleImgContent:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *imgPath = [self getFullPath:[args objectAtIndex:0]];
        if ( imgPath ) {
            UIImage *newImg = [UIImage imageWithContentsOfFile:imgPath];
            if ( newImg ){
                self.bubble.contentImage = newImg;
                bRet = TRUE;
            }
        }
    }
    return bRet;
}

- (NSData*)dataWithDataURL:(NSString*)base64Data {
    if ( [base64Data isKindOfClass:[NSString class]] ) {
        if ( [base64Data hasPrefix:@"data:"] ) {
            NSRange range = [base64Data rangeOfString:@";base64,"];
            if ( range.location < base64Data.length ) {
                base64Data = [base64Data substringFromIndex:range.location+range.length];
            }
        }
        NSData *data = [NSData dataFromBase64String:base64Data];
        return data;
    }
    return nil;
}

-(BOOL)setBubbleImgDataURLContent:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *base64Data = [args objectAtIndex:0];
        if ( [base64Data isKindOfClass:[NSString class]] ) {
            if ( [base64Data hasPrefix:@"data:"] ) {
                NSRange range = [base64Data rangeOfString:@";base64,"];
                if ( range.location < base64Data.length ) {
                    base64Data = [base64Data substringFromIndex:range.location+range.length];
                }
            }
            NSData *data = [NSData dataFromBase64String:base64Data];
            if ( data ) {
                UIImage *newImg = [UIImage imageWithData:data];
                if ( newImg ){
                    self.bubble.contentImage = newImg;
                    bRet = TRUE;
                }
            }
        }
    }
    return bRet;
}

-(BOOL)setIcons:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSMutableArray *imgs = [NSMutableArray array];
        NSArray *icons = [args objectAtIndex:0];
        if ( [icons isKindOfClass:[NSArray class]] ) {
            for ( int i = 0; i < [icons count]; i++) {
                NSString *imgPath = [self getFullPath:[icons objectAtIndex:i]];
                if ( imgPath ) {
                    UIImage *newImg = [UIImage imageWithContentsOfFile:imgPath];
                    if ( newImg ) {
                        [imgs addObject:newImg];
                    }
                }
            }
            self.animationImages = imgs;
        }
        bRet = true;
        self.duration = [PGPluginParamHelper getFloatValue:[args objectAtIndex:1] defalut:0.5];
    }
    return bRet;
}

-(BOOL)setDraggable:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSNumber *draggableValue = [args objectAtIndex:0];
        if ( draggableValue && [draggableValue isKindOfClass:[NSNumber class]] )
        {
            self.canDraggable = [draggableValue boolValue];
            if ( self.belongMapview )
            {
                BMKAnnotationView *view = [self.belongMapview.mapView viewForAnnotation:self];
                view.draggable = [draggableValue boolValue];
            }
            bRet = !self.canDraggable;
        }
    }
    return bRet;
}

- (BOOL)isReplaceValue:(NSString*)oldValue
            toNewValue:(NSString*)willSetValue
          willSetValue:(NSString**)newValue {
    BOOL bRet = NO;
    if ( [willSetValue isKindOfClass:[NSString class]] ) {
        if ( oldValue
            && NSOrderedSame != [oldValue caseInsensitiveCompare:willSetValue]) {
            bRet = NO;
        }
        if ( newValue ) {
            *newValue = willSetValue;
        }
        bRet = YES;
    } else {
        bRet = oldValue ? YES : NO;
    }
    return bRet;
}

-(BOOL)__setBubble:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        
        NSString *newValue = nil;
        if ( [self isReplaceValue:self.bubble.label
                       toNewValue:[args objectAtIndex:0] willSetValue:&newValue] ) {
            self.bubble.label = newValue;
            newValue = nil;
            bRet = TRUE;
        }
        
        NSString *newIconPath = [self getFullPath:[args objectAtIndex:1]];
        if ( [self isReplaceValue:self.bubble.icon
                       toNewValue:newIconPath willSetValue:&newValue] ) {
            self.bubble.icon = newValue;
            newValue = nil;
            bRet = TRUE;
        }
        {
            NSString *loadDataURLValue = [PGPluginParamHelper getStringValue:[args objectAtIndex:2]];
            NSString *loadImageValue = [PGPluginParamHelper getStringValue:[args objectAtIndex:3]];
            if ( loadImageValue ) {
                NSString *imgPath = [self getFullPath:loadImageValue];
                if ( imgPath ) {
                    UIImage *newImg = [UIImage imageWithContentsOfFile:imgPath];
                    if ( newImg ){
                        self.bubble.contentImage = newImg;
                        bRet = TRUE;
                    }
                }
            } else if ( loadDataURLValue ){
                NSData *data = [self dataWithDataURL:loadDataURLValue];
                if ( data ) {
                    UIImage *newImg = [UIImage imageWithData:data];
                    if ( newImg ){
                        self.bubble.contentImage = newImg;
                        bRet = TRUE;
                    }
                }
            } else  {
                self.bubble.contentImage = nil;
                bRet = TRUE;
            }
        }
        
        self.selected = [PGPluginParamHelper getBoolValue:[args objectAtIndex:4] defalut:false];
        if ( !bRet && self.belongMapview )
        {
            if ( self.selected ) {
                [self.belongMapview.mapView selectAnnotation:self animated:NO];
            } else {
                [self.belongMapview.mapView deselectAnnotation:self animated:NO];
            }
        }
    }
    return bRet;
}

- (BOOL)setVisable:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        NSString *visable = [args objectAtIndex:0];
        if ( visable && [visable isKindOfClass:[NSString class]] )
        {
            self.hidden = ![visable boolValue];
            if ( self.belongMapview )
            {
                BMKAnnotationView *view = [self.belongMapview.mapView viewForAnnotation:self];
                view.hidden = self.hidden;
                view.enabled = !self.hidden;
                // view.paopaoView.hidden = !self.hidden;
                //   [view.paopaoView setNeedsDisplay];
                
                //                        if ( view.rightCalloutAccessoryView
                //                            && view.rightCalloutAccessoryView.superview
                //                            && view.rightCalloutAccessoryView.superview.superview)
                //                        { view.rightCalloutAccessoryView.superview.superview.hidden = self.hidden; }
            }
        }
    }
    
    bRet = FALSE;
    return bRet;
}

/*
 *------------------------------------------------
 *@summay: 更新marker对象
 *@param jsonObj
 *@return
 *@remark
 *------------------------------------------------
 */

- (BOOL)updateObject:(NSMutableArray*)jsonObj
{
    BOOL bRet = FALSE;
    if ( !jsonObj )
        return FALSE;
    if ( ![jsonObj isKindOfClass:[NSMutableArray class]] )
        return FALSE;
    
    NSString *property = [jsonObj objectAtIndex:0];
    if ( property && [property isKindOfClass:[NSString class]] ) {
        if ( [property isEqualToString:@"setPoint"] ){ //## setPoint
            bRet = [self setPoint:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"setIcon"] ) {
            bRet = [self __setIcon:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"setLabel"] ) {
            bRet = [self __setLabel:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"setBubbleLabel"] ) {
            bRet = [self setBubbleLabel:[jsonObj objectAtIndex:1]];
        } else if ( [property isEqualToString:@"setBubbleIcon"]){
            bRet = [self setBubbleIcon:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"loadImage"] ) {
            bRet = [self setBubbleImgContent:[jsonObj objectAtIndex:1]];
        }/*loadImageDataURL*/ else if( [property isEqualToString:@"loadImageDataURL"] ) {
            bRet = [self setBubbleImgDataURLContent:[jsonObj objectAtIndex:1]];
        }/*setIcons*/  else if( [property isEqualToString:@"setIcons"] ) {
            bRet = [self setIcons:[jsonObj objectAtIndex:1]];
        }/*setDraggable*/ else if( [property isEqualToString:@"setDraggable"]) {
            bRet = [self setDraggable:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"bringToTop"]) {
        } else if( [property isEqualToString:@"hideBubble"] ) {
            [self.belongMapview.mapView deselectAnnotation:self animated:NO];
        }else if( [property isEqualToString:@"setBubble"] ) {
            bRet = [self __setBubble:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"show"]
                ||[property isEqualToString:@"hide"])
        {
            bRet = [self setVisable:[jsonObj objectAtIndex:1]];
        }

        if ( bRet )
        {
            PGMapView *belongView = self.belongMapview;
            if ( belongView )
            {
                BOOL selSta = self.selected;
                [belongView removeMarker:self];
                self.selected = selSta;
                [belongView addMarker:self];
            }
            return TRUE;
        }
    }
    return FALSE;
}

- (NSString *)title
{
  //  return @" ";
    if ( self.bubble )
        return self.bubble.label;
    return nil;
}

/*
 *------------------------------------------------
 *@summay: 获取文件的全路径
 *@param fileName NSString*
 *@return
 *@remark
 *    NSString*
 *------------------------------------------------
 */
- (NSString*)getFullPath:(NSString*)fileName
{
    if ( [fileName isKindOfClass:[NSString class]] ) {
        return [PTPathUtil h5Path2SysPath:fileName basePath:_baseURL];
    }
    return nil;
}

//- (void)setBaseURL:(NSString*)baseURL
//{
//    NSURL *url = [NSURL URLWithString:baseURL];
//    [_baseURL release];
//    _baseURL = [[url.path stringByDeletingLastPathComponent] retain];
//}

@end

@implementation PGMapMarkerView

-(void)dealloc
{
    _taprecognizer.delegate = nil;
    [self removeGestureRecognizer:_taprecognizer];
    [_taprecognizer release];
    _taprecognizer = nil;
    [_annotationImageView release];
   // [self addTapGestureRecognizer];
    self.drawImage = nil;
    [super dealloc];
}

/*
 *------------------------------------------------
 *@summay: 刷新标记
 *@param 
 *@return
 *@remark
 *------------------------------------------------
 */
- (void)reload
{
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    
    if ([marker.animationImages count]){
        [self setAnnotationImages:marker.animationImages duration:marker.duration];
    } else {
        //标记不知为什么不能自定义尺寸，在这里只能采用低效率的方法先填充个图片
        if ( marker.icon )
        { self.drawImage = [UIImage imageWithContentsOfFile:marker.icon]; }
       // if ( marker.icon )
        //{ _drawImage = [UIImage getRetainImage:marker.icon]; }
        if ( !self.drawImage )
        { self.drawImage = [UIImage imageNamed:@"mapapi.bundle/images/pin_purple"]; }//map-redpin.png
        
        self.image = [self drawImage:marker];
        self.drawImage =nil;
    }
    self.centerOffset = CGPointMake(0, -self.frame.size.height/2+_textHeight );
    [self reloadBubble];
}
/*
 *------------------------------------------------
 *@summay: 刷新气泡视图
 *@param 
 *@return
 *@remark
 *------------------------------------------------   
 */
-(void)reloadBubble
{
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    self.canShowCallout = NO;
    self.paopaoView = nil;
    PGMapBubble *bubble = marker.bubble;
    if ( bubble )
    {
      //  UIImage *icon = [UIImage getRetainImage:bubble.icon];
        UIImage *icon = [UIImage imageWithContentsOfFile:bubble.icon];
        /*if ( icon || (bubble.label && [bubble.label length]) )
        {
          //  PGMapBubbleView *bubbleView = [[[PGMapBubbleView alloc] init] autorelease];
          //  [bubbleView setBubbleImage:icon];
          //  [bubbleView setBubbleLabel:bubble.label];//bubble.label];
           // bubbleView.delegate = self;
           // self.canShowCallout = YES;
           // self.leftCalloutAccessoryView = bubbleView;
            self.canShowCallout = YES;
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:icon] autorelease];
            self.leftCalloutAccessoryView = imageView;
        }*/
        
//        if ( bubble.contentImage ) {
//            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,
//                                                                                 bubble.contentImage.size.width,
//                                                                                 bubble.contentImage.size.height)];
//            BMKActionPaopaoView *paopoaView = [[BMKActionPaopaoView alloc] initWithCustomView:imgView];
//            self.canShowCallout = YES;
//            
//        } else
        if ( icon || (bubble.label && [bubble.label length]) ) {
            PGMapBubbleView *bubbleView = [[[PGMapBubbleView alloc] init] autorelease];
            [bubbleView setBubbleImage:icon];
            [bubbleView setBubbleLabel:bubble.label];//bubble.label];
            [bubbleView setContentImage:bubble.contentImage];
          //  bubbleView.delegate = self;
            self.canShowCallout = YES;
           // self.leftCalloutAccessoryView = bubbleView;
            BMKActionPaopaoView *paopaoView = [[BMKActionPaopaoView alloc] initWithCustomView:bubbleView];
            self.paopaoView = paopaoView;
            [paopaoView autorelease];
        }
    }
}

/*
- (void)setAnnotation:(id<MAAnnotation>)annotation
{
    [super setAnnotation:annotation];
    [self reload];
    [self reloadBubble];
}*/

//计算view的大小
- (CGRect)size
{
    // 图片在上文字在下取各项的最大宽度为宽
    // 各项之和为各项之长
    CGRect frame = CGRectZero;
    PGMapMarker *mapMarker = (PGMapMarker*)self.annotation;
    if ( _drawImage )
    {
        UIImage *image = _drawImage;
        frame.size.width = MAX(frame.size.width, image.size.width);
        frame.size.height += image.size.height;
        frame.size.height += PG_MAP_MARKERVIEW_GAP;
    }
    
    if ( mapMarker.label )
    {
        CGSize textSize = [ mapMarker.label sizeWithFont:[UIFont systemFontOfSize:PG_MAP_MARKERVIEW_TEXTFONTSIZE]];
        frame.size.width = MAX(frame.size.width, textSize.width);
        frame.size.height += textSize.height;
        _textHeight = textSize.height;
    }
    
    return frame;
}
/*
 *------------------------------------------------
 *@summay: 生成标记显示的图片
 *@param annotation id <MAAnnotation>
 *@return
 *@remark
 *    高德地图标记视图不知道为什么不能设置大小,只能暂时自己生成一副图片
 *------------------------------------------------
 */
- (UIImage*)drawImage:(id <BMKAnnotation>)annotation
{
    UIImage *image = nil;
    CGRect rect = [self size];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    PGMapMarker *mapMarker = (PGMapMarker*)self.annotation;
    if ( mapMarker && width && height )
    {
        if (NULL != &UIGraphicsBeginImageContextWithOptions)
        {
            CGFloat scale = [UIScreen mainScreen].scale;
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, scale);
        }
        else
        {
            UIGraphicsBeginImageContext(CGSizeMake(width, height));
        }
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        if ( context )
        {
            CGFloat heightOffset = 0.0f;
            // 绘制图片
            if ( _drawImage )
            {
                //计算图片的绘制位置
                CGRect imgRect = CGRectZero;
                imgRect.size = _drawImage.size;
                imgRect.origin.x = (rect.size.width - _drawImage.size.width)/2.0f;
                [_drawImage drawInRect:imgRect];
                heightOffset = (_drawImage.size.height + PG_MAP_MARKERVIEW_GAP);
            }
            // 绘制文字
            if ( mapMarker.label )
            {
                CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor );
                [mapMarker.label drawInRect:CGRectMake(0, heightOffset, rect.size.width, _textHeight)
                                   withFont:[UIFont systemFontOfSize:PG_MAP_MARKERVIEW_TEXTFONTSIZE]
                              lineBreakMode:NSLineBreakByCharWrapping
                                  alignment:NSTextAlignmentCenter];
            }
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    /* for debug
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSData *imgData = UIImagePNGRepresentation(image);
    [imgData writeToFile:[filePath stringByAppendingPathComponent:@"test.png"] atomically:NO];
     */
    return image;
}

- (void)setAnnotationImages:(NSArray*)images duration:(CGFloat)duration {
    if ( 0 == [images count] ) {
        if ( !_annotationImageView ) {
            [_annotationImageView removeFromSuperview];
            [_annotationImageView release];
            _annotationImageView = nil;
        }
        return;
    }
    if ( !_annotationImageView ) {
        CGSize maxSize = CGSizeZero;
        for ( int i = 0 ; i < [images count]; i++ ) {
            UIImage *img = [images objectAtIndex:i];
            if ( img.size.width > maxSize.width
                || img.size.height > maxSize.height ) {
                maxSize = img.size;
            }
        }
        
        [self setBounds:CGRectMake(0.f, 0.f, maxSize.width, maxSize.height)];
        [self setBackgroundColor:[UIColor clearColor]];
        _annotationImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _annotationImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_annotationImageView];
    }
    
    if ([_annotationImageView isAnimating]) {
        [_annotationImageView stopAnimating];
    }
    
    _annotationImageView.animationImages = images;
    _annotationImageView.animationDuration = duration * [images count];
    _annotationImageView.animationRepeatCount = 0;
    [_annotationImageView startAnimating];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
- (void)addTapGestureRecognizer{
    if ( !_taprecognizer ) {
        _taprecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCallback:)];
        _taprecognizer.numberOfTouchesRequired = 1;
        _taprecognizer.numberOfTapsRequired = 1;
        _taprecognizer.cancelsTouchesInView = NO;
        _taprecognizer.delegate = self;
        // taprecognizer.delaysTouchesBegan = YES;
        // taprecognizer.delaysTouchesEnded = YES;
        [self addGestureRecognizer:_taprecognizer];
    }
    
}
-(void)tapCallback:(UITapGestureRecognizer*)sender
{
    id<BMKAnnotation> annotation = self.annotation;
    if ( annotation && [annotation isKindOfClass:[PGMapMarker class]] )
    {
        PGMapMarker *marker = (PGMapMarker*)annotation;
        NSString * jsObjectF = @"{var args = {type:'markerclick'};\
        var p = %@; p.maps.__bridge__.execCallback('%@', args);}";
        NSString *javaScript = [NSString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], marker.UUID];
        [marker.belongMapview.jsBridge asyncWriteJavascript:javaScript];
    }
}

@end
