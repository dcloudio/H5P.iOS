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
#import "H5CoreJavaScriptText.h"
#import "PDRToolSystemEx.h"
// 标记排版时图片和文字之间的间隙
#define PG_MAP_MARKERVIEW_GAP 2.0f// 标记使用文字的尺寸
#define PG_MAP_MARKERVIEW_TEXTFONTSIZE 12.0f
#define PG_MAP_BUBBLE_ARRORHEIGHT 10

@implementation PGMapCoordinate(MAMap)
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
+(NSArray*)coordinateListWithPoints:(MAMapPoint *)points count:(NSUInteger)count
{
    if ( points )
    {
        NSMutableArray *pointList = [NSMutableArray arrayWithCapacity:10];
        for (int index = 0; index < count; index++)
        {
            MAMapPoint point = points[index];
            PGMapCoordinate *pdrPt = [PGMapCoordinate pointWithLongitude:point.x latitude:point.y];
            [pointList addObject:pdrPt ];
        }
        return pointList;
    }
    return nil;
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

@synthesize delegate;
@synthesize bubbleLabel;
@synthesize bubbleImage;
@synthesize userContentImg;
- (id)initWithFrame:(CGRect)frame
{
    if ( (self = [super initWithFrame:frame] ) )
    {
        self.backgroundColor = [UIColor clearColor];
//        UIImage *imageNormal, *imageHighlighted;
//        imageNormal = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_left"] stretchableImageWithLeftCapWidth:10 topCapHeight:13];
//        imageHighlighted = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_left_highlighted"]
//                            stretchableImageWithLeftCapWidth:10 topCapHeight:13];
//        UIImageView *leftBgd = [[UIImageView alloc] initWithImage:imageNormal
//                                                 highlightedImage:imageHighlighted];
//        leftBgd.tag = 11;
//        
//        imageNormal = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_right"] stretchableImageWithLeftCapWidth:10 topCapHeight:13];
//        imageHighlighted = [[UIImage imageNamed:@"mapapi.bundle/images/icon_paopao_middle_right_highlighted"]
//                            stretchableImageWithLeftCapWidth:10 topCapHeight:13];
//        UIImageView *rightBgd = [[UIImageView alloc] initWithImage:imageNormal
//                                                  highlightedImage:imageHighlighted];
//        rightBgd.tag = 12;
//        
//        [self addSubview:leftBgd];
//        [self sendSubviewToBack:leftBgd];
//        [self addSubview:rightBgd];
//        [self sendSubviewToBack:rightBgd];
//        [leftBgd release];
//        [rightBgd release];
        
        UITapGestureRecognizer *taprecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCallback:)];
        taprecognizer.numberOfTouchesRequired = 1;
        taprecognizer.numberOfTapsRequired = 1;
        taprecognizer.cancelsTouchesInView = NO;
        // taprecognizer.delaysTouchesBegan = YES;
        // taprecognizer.delaysTouchesEnded = YES;
        [self addGestureRecognizer:taprecognizer];
        [taprecognizer release];
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
    if ( self.userContentImg ) {
        [super drawRect:rect];
        return;
    }
    [self drawInContext:UIGraphicsGetCurrentContext()];
    
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    
}

- (void)drawInContext:(CGContextRef)context
{
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8].CGColor);
    
    [self getDrawPath:context];
    CGContextFillPath(context);
    
}

- (void)getDrawPath:(CGContextRef)context
{
    CGRect rrect = self.bounds;
    CGFloat radius = 6.0;
    CGFloat minx = CGRectGetMinX(rrect),
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect),
    maxy = CGRectGetMaxY(rrect)-PG_MAP_BUBBLE_ARRORHEIGHT;
    
    CGContextMoveToPoint(context, midx+PG_MAP_BUBBLE_ARRORHEIGHT, maxy);
    CGContextAddLineToPoint(context,midx, maxy+PG_MAP_BUBBLE_ARRORHEIGHT);
    CGContextAddLineToPoint(context,midx-PG_MAP_BUBBLE_ARRORHEIGHT, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}

-(void)dealloc
{
    [_textView removeFromSuperview];
    [_textView release];
    [_iconView removeFromSuperview];
    [_iconView release];
    [super dealloc];
}

- (CGSize)needLayout {
    CGSize size = CGSizeZero;
    size.width += 4*MKEYMAP_MARKERVIEW_GAP;
    size.height += 2*MKEYMAP_MARKERVIEW_GAP;
    
    if ( _textView )
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
        size.height += PG_MAP_BUBBLE_ARRORHEIGHT;
    }
    
    
//    CGRect rect0 = self.bounds;
//    rect0.size = CGSizeMake( size.width, size.height);
    //self.frame = rect0;
    
//    CGFloat halfWidth = rect0.size.width/2;
//    UIView *image = [self viewWithTag:11];
//    CGRect iRect = CGRectZero;
//    iRect.size.width = halfWidth;
//    iRect.size.height = rect0.size.height;
//    image.frame = iRect;
//    image = [self viewWithTag:12];
//    iRect.origin.x = halfWidth;
//    image.frame = iRect;
    return size;
}

-(void)layoutSubviews
{
   // CGSize size = [self needLayout];
   // self.bounds = CGRectMake(0, 0, size.width, size.height);
}

-(void)setBubbleLabel:(NSString *)text
{
    if ( !text )
    { return; }
    
    if ( !_textView )
    {
        _textView = [[UILabel alloc] init];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = [UIColor whiteColor];
        _textView.font = [UIFont systemFontOfSize:PG_MAP_MARKERVIEW_TEXTFONTSIZE];
        
        [self addSubview:_textView];
    }
    _textView.text = text;
    NSArray *subTexts = [text componentsSeparatedByString:@"\n"];
    if ( [subTexts count] > 1 )
    {
        _textView.numberOfLines = [subTexts count];
    } else {
        _textView.numberOfLines = 1;
    }
    [_textView sizeToFit];
    
    [self setNeedsLayout];
}


-(void)setBubbleImage:(UIImage *)img
{
    if ( !img )
    { return; }
    
    if ( !_iconView )
    {
        _iconView = [[UIImageView alloc] init];
        [self addSubview:_iconView];
    }
    _iconView.image = img;
    [_iconView sizeToFit];
   // [self setNeedsLayout];
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
    [self setNeedsLayout];
}


-(void)tapCallback:(UITapGestureRecognizer*)sender
//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( self.delegate )
    { [self.delegate click:self]; }
}


@end

#pragma PGMapBubble
#pragma mark -----------------
@implementation PGMapMarker

@synthesize belongMapview;
@synthesize UUID;
@synthesize label;
@synthesize icon;
@synthesize bubble;
@synthesize hidden;
@synthesize baseURL = _baseURL;
@synthesize canDraggable;
@synthesize animationImages = _animationImages;
@synthesize selected;
- (void)dealloc
{
    self.belongWebview = nil;
    self.belongMapview = nil;
    self.animationImages = nil;
    self.baseURL = nil;
    self.label = nil;
    self.UUID = nil;
    self.icon = nil;
    self.bubble = nil;
    [super dealloc];
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
                MAAnnotationView *view = [self.belongMapview viewForAnnotation:self];
                view.draggable = [draggableValue boolValue];
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

-(BOOL)__setBubble:(NSArray*)args {
    BOOL bRet = FALSE;
    if ( args && [args isKindOfClass:[NSArray class]] )
    {
        //self.bubble.icon = nil;
        //self.bubble.label = nil;
        NSString *labelValue = [PGPluginParamHelper getStringValue:[args objectAtIndex:0]];
        if ( (!self.bubble.label || !labelValue) && self.bubble.label != labelValue ) {
            self.bubble.label = labelValue;
            bRet = TRUE;
        } else {
            if ( NSOrderedSame !=  [self.bubble.label caseInsensitiveCompare:labelValue]) {
                self.bubble.label = labelValue;
                bRet = TRUE;
            }
        }
        NSString *value = [PGPluginParamHelper getStringValue:[args objectAtIndex:1]];
        NSString *newValue = [self getFullPath:value];
        if ( (!self.bubble.icon || !newValue) && self.bubble.icon != newValue ) {
            self.bubble.icon = newValue;
            bRet = TRUE;
        } else {
            if ( NSOrderedSame !=  [self.bubble.icon caseInsensitiveCompare:newValue]) {
                self.bubble.icon = newValue;
                bRet = TRUE;
            }
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
        if ( !bRet ) {
            if ( self.belongMapview )
            {
                if ( self.selected ) {
                    [self.belongMapview selectAnnotation:self animated:NO];
                } else {
                    [self.belongMapview deselectAnnotation:self animated:NO];
                }
            }
        }
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
    if ( property && [property isKindOfClass:[NSString class]] )
    {
        if ( [property isEqualToString:@"setPoint"] )
        {
            NSArray *args = [jsonObj objectAtIndex:1];
            if ( args && [args isKindOfClass:[NSArray class]] )
            {
                NSMutableDictionary *dict = [args objectAtIndex:0];
                if ( dict && [dict isKindOfClass:[NSMutableDictionary class]] )
                {
                    PGMapCoordinate *point = [PGMapCoordinate pointWithJSON:dict];
                    if ( point )
                    {
                        [self setCoordinate:[point point2CLCoordinate]];
                        bRet = false;
                    }
                }
            }
        } else if( [property isEqualToString:@"loadImage"] ) {
            bRet = [self setBubbleImgContent:[jsonObj objectAtIndex:1]];
        }/*loadImageDataURL*/ else if( [property isEqualToString:@"loadImageDataURL"] ) {
            bRet = [self setBubbleImgDataURLContent:[jsonObj objectAtIndex:1]];
        }
        else if( [property isEqualToString:@"setIcons"] ) {
            bRet = [self setIcons:[jsonObj objectAtIndex:1]];
        }
        else if( [property isEqualToString:@"setIcon"] )
        {
            NSArray *args = [jsonObj objectAtIndex:1];
            if ( args && [args isKindOfClass:[NSArray class]] )
            {
                self.icon = nil;
                NSString *value = [args objectAtIndex:0];
                if ( value && [value isKindOfClass:[NSString class]] )
                    self.icon = [self getFullPath:value];
                bRet = false;
                PGMapView *belongView = self.belongMapview;
                if ( belongView )
                {
                    PGMapMarkerView *markerView = (PGMapMarkerView*)[belongView viewForAnnotation:self];
                    [markerView reloadLabel:NO loadIcon:YES];
                    [markerView setNeedsLayout];
                   // [markerView setNeedsDisplay];
                }
            }
        }
        else if( [property isEqualToString:@"setLabel"] )
        {
            NSArray *args = [jsonObj objectAtIndex:1];
            if ( args && [args isKindOfClass:[NSArray class]] )
            {
                self.label = nil;
                NSString *value = [args objectAtIndex:0];
                if ( value && [value isKindOfClass:[NSString class]] )
                    self.label = value;
                bRet =  false;
                PGMapView *belongView = self.belongMapview;
                if ( belongView )
                {
                    PGMapMarkerView *markerView = (PGMapMarkerView*)[belongView viewForAnnotation:self];
                    [markerView reloadLabel:YES loadIcon:NO];
                    [markerView setNeedsLayout];
                  //  [markerView setNeedsDisplay];
                }
            }
        }
        else if( [property isEqualToString:@"setBubble"] )
        {
            bRet = [self __setBubble:[jsonObj objectAtIndex:1]];
//            NSArray *args = [jsonObj objectAtIndex:1];
//            if ( args && [args isKindOfClass:[NSArray class]] )
//            {
//                self.bubble.icon = nil;
//                self.bubble.label = nil;
//                NSString *labelValue = [args objectAtIndex:0];
//                if ( labelValue && [labelValue isKindOfClass:[NSString class]] )
//                    self.bubble.label = labelValue;
//                NSString *value = [args objectAtIndex:1];
//                if ( value && [value isKindOfClass:[NSString class]] )
//                    self.bubble.icon = [self getFullPath:value];
//                
//                bRet = false;
//                PGMapView *belongView = self.belongMapview;
//                if ( belongView )
//                {
//                    PGMapMarkerView *markerView = (PGMapMarkerView*)[belongView viewForAnnotation:self];
//                    [markerView reloadBubble];
//                }
//            }
        } else if( [property isEqualToString:@"setDraggable"]) {
            bRet = [self setDraggable:[jsonObj objectAtIndex:1]];
        } else if( [property isEqualToString:@"hideBubble"] ) {
            [self.belongMapview deselectAnnotation:self animated:NO];
        }
        else if( [property isEqualToString:@"show"]
                ||[property isEqualToString:@"hide"])
        {
            NSArray *args = [jsonObj objectAtIndex:1];
            if ( args && [args isKindOfClass:[NSArray class]] )
            {
                NSString *visable = [args objectAtIndex:0];
                if ( visable && [visable isKindOfClass:[NSString class]] )
                {
                    self.hidden = ![visable boolValue];
                    if ( self.belongMapview )
                    {
                        MAAnnotationView *view = [self.belongMapview viewForAnnotation:self];
                        view.hidden = self.hidden;
                        view.enabled = !self.hidden;
//                        if ( view.rightCalloutAccessoryView
//                            && view.rightCalloutAccessoryView.superview
//                            && view.rightCalloutAccessoryView.superview.superview)
//                        { view.rightCalloutAccessoryView.superview.superview.hidden = self.hidden; }
                    }
                }
            }
           
            bRet = FALSE;
        }
        else if( [property isEqualToString:@"setBubbleIcon"] )
        {
            NSArray *args = [jsonObj objectAtIndex:1];
            if ( args && [args isKindOfClass:[NSArray class]] )
            {
                self.bubble.icon = nil;
                NSString *value = [args objectAtIndex:0];
                if ( value && [value isKindOfClass:[NSString class]] )
                    self.bubble.icon = [self getFullPath:value];
                bRet = false;
                PGMapView *belongView = self.belongMapview;
                if ( belongView )
                {
                    PGMapMarkerView *markerView = (PGMapMarkerView*)[belongView viewForAnnotation:self];
                    [markerView reloadBubbleLabel:NO loadIcon:YES];
                }
            }
        }
        else if( [property isEqualToString:@"setBubbleLabel"] )
        {
            NSArray *args = [jsonObj objectAtIndex:1];
            if ( args && [args isKindOfClass:[NSArray class]] )
            {
                self.bubble.label = nil;
                NSString *labelValue = [args objectAtIndex:0];
                if ( labelValue && [labelValue isKindOfClass:[NSString class]] )
                    self.bubble.label = labelValue;
                bRet = false;
                PGMapView *belongView = self.belongMapview;
                if ( belongView )
                {
                    PGMapMarkerView *markerView = (PGMapMarkerView*)[belongView viewForAnnotation:self];
                    [markerView reloadBubbleLabel:YES loadIcon:NO];
                }
            }
        }
        
        if ( bRet )
        {
            PGMapView *belongView = self.belongMapview;
            if ( belongView )
            {
                BOOL s = self.selected;
                [belongView removeMarker:self];
                self.selected = s;
                [belongView addMarker:self];
            }
            return TRUE;
        }
    }
    return FALSE;
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
    return [PTPathUtil h5Path2SysPath:fileName basePath:_baseURL];
}

//- (void)setBaseURL:(NSString*)baseURL
//{
//    NSURL *url = [NSURL URLWithString:baseURL];
//    [_baseURL release];
//    _baseURL = [[url.path stringByDeletingLastPathComponent] retain];
//}
@end

#define kWidth  150.f
#define kHeight 60.f

@interface PGMapMarkerView ()

@property (nonatomic, strong) UIImageView *portraitImageView;
@property (nonatomic, strong) UILabel *nameLabel;

@end

@implementation PGMapMarkerView

@synthesize calloutView;
@synthesize portraitImageView   = _portraitImageView;
@synthesize nameLabel           = _nameLabel;

#pragma mark - Override
- (NSString *)name
{
    return self.nameLabel.text;
}

- (void)setName:(NSString *)name
{
    self.nameLabel.text = name;
}

- (UIImage *)portrait
{
    return self.portraitImageView.image;
}

- (void)setPortrait:(UIImage *)portrait
{
    self.portraitImageView.image = portrait;
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
//    if ( true ==  selected ) {
////        dispatch_async(dispatch_get_main_queue(), ^(void) {
////            [self tapCallback];
////        });
//    }
    if ( self.selected == selected ) {
        return;
    }
    
    if ( selected )
    {
        if ( nil == self.calloutView ) {
            PGMapMarker *marker = (PGMapMarker*)self.annotation;
            PGMapBubble *bubble = marker.bubble;
            if ( bubble && (bubble.label || bubble.icon || bubble.contentImage))  {
                PGMapBubbleView *bubbleView = [[[PGMapBubbleView alloc] init] autorelease];
                bubbleView.delegate = self;
                self.calloutView = bubbleView;
                [self reloadBubble];
            }
        }
        [self addSubview:self.calloutView];
    }
    else
    {
        [self.calloutView removeFromSuperview];
    }
    
    [super setSelected:selected animated:animated];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    /* Points that lie outside the receiver’s bounds are never reported as hits,
     even if they actually lie within one of the receiver’s subviews.
     This can occur if the current view’s clipsToBounds property is set to NO and the affected subview extends beyond the view’s bounds.
     */
    if (!inside && self.selected)
    {
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    
    return inside;
}

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.bounds = CGRectMake(0.f, 0.f, kWidth, kHeight);
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)activeAnnotationImageView {
    
}

- (void)setupImageView:(UIImage*)icon {
    if ( !self.portraitImageView ) {
        /* Create portrait image view and add to view hierarchy. */
        UIImageView *iconView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
        self.portraitImageView = iconView;
        [self addSubview:self.portraitImageView];
    }
    self.portraitImageView.hidden = NO;
    self.portraitImageView.image = icon;
}

- (void)setupAnnotationImageView {
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    if ( !_annotationImageView ) {
        _annotationImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _annotationImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_annotationImageView];
    }
    _annotationImageView.hidden = NO;
    if ([_annotationImageView isAnimating]) {
        [_annotationImageView stopAnimating];
    }
    
    _annotationImageView.animationImages = marker.animationImages;
    _annotationImageView.animationDuration = marker.duration * [marker.animationImages count];
    _annotationImageView.animationRepeatCount = 0;
    [_annotationImageView startAnimating];
}

- (void)deactiveAnnotationImageView {
    if ([_annotationImageView isAnimating]) {
        [_annotationImageView stopAnimating];
    }
    _annotationImageView.hidden = YES;
}

- (void)setupNameLabel {
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    if ( !self.nameLabel ) {
        /* Create name label. */
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        self.nameLabel = label;
        self.nameLabel.backgroundColor  = [UIColor clearColor];
        self.nameLabel.textAlignment    = NSTextAlignmentCenter;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        self.nameLabel.textColor        = [UIColor blackColor];
        self.nameLabel.font             = [UIFont systemFontOfSize:PG_MAP_MARKERVIEW_TEXTFONTSIZE];
        [self addSubview:self.nameLabel];
    }
    self.nameLabel.hidden = NO;
    self.nameLabel.text = marker.label;
}

- (void)reloadLabel:(BOOL)isLoadLabel loadIcon:(BOOL)isLoadIcon
{
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    UIImage *icon = nil;
    if ( isLoadIcon ) {
//        if ( marker.icon )  {
//            icon = [UIImage getRetainImage:marker.icon];
//        }
        if ( marker.icon )
        {
            icon = [UIImage dcloud_imageWithContentsOfFile:marker.icon];
            
        }
        if ( !icon ) {
            icon = [UIImage imageNamed:@"AMap.bundle/images/pin_red"];
        }
        [self setupImageView:icon];
    }
    if ( isLoadLabel ) {
        [self setupNameLabel];
    }
}

- (void)reload {
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    if ( [marker.animationImages count] > 0 ) {
        self.nameLabel.hidden = YES;
        self.portraitImageView.hidden = YES;
        [self setupAnnotationImageView];
        [self setAnnotationImages:marker.animationImages duration:marker.duration];
    } else {
        [self deactiveAnnotationImageView];
        [self reloadLabel:true loadIcon:true];
    }
    [self setNeedsLayout];
}
- (void)reloadBubble {
    [self reloadBubbleLabel:YES loadIcon:YES];
}

- (void)reloadBubbleLabel:(BOOL)isLoadLabel loadIcon:(BOOL)isLoadIcon
{
    PGMapMarker *marker = (PGMapMarker*)self.annotation;
    PGMapBubble *bubble = marker.bubble;
    if ( bubble ){
        PGMapBubbleView *bubbleView = (PGMapBubbleView*)self.calloutView;
        if ( isLoadIcon  ) {
            UIImage *icon = [UIImage imageWithContentsOfFile:bubble.icon];
            //UIImage *icon = [UIImage getRetainImage:bubble.icon];
            [bubbleView setBubbleImage:icon];
        }
        if ( isLoadLabel ) {
            [bubbleView setBubbleLabel:bubble.label];
        }
        [bubbleView setContentImage:bubble.contentImage];
        if ( isLoadLabel || isLoadIcon ) {
            CGSize size = [bubbleView needLayout];
            bubbleView.frame = CGRectMake(0, 0, size.width, size.height);
            
            self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
                                                  -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
            [self.calloutView setNeedsDisplay];
        }
    }
}

- (void)layoutSubviews {
    CGSize maxSize = CGSizeZero;
    _annotationImageView.frame = CGRectZero;
    self.nameLabel.frame = CGRectZero;
    self.portraitImageView.frame = CGRectZero;
    PGMapMarker *mapMarker = (PGMapMarker*)self.annotation;
    if ( [mapMarker.animationImages count] ) {
        CGSize maxSize = CGSizeZero;
        for ( int i = 0 ; i < [mapMarker.animationImages count]; i++ ) {
            UIImage *img = [mapMarker.animationImages objectAtIndex:i];
            if ( img.size.width > maxSize.width
                || img.size.height > maxSize.height ) {
                maxSize = img.size;
            }
        }
        
        [self setBounds:CGRectMake(0.f, 0.f, maxSize.width, maxSize.height)];
        _annotationImageView.frame = self.bounds;
    } else {
        UIImage *portraitImage = self.portraitImageView.image;
        if ( portraitImage )
        {
            maxSize.width = MAX(maxSize.width, portraitImage.size.width);
        }
        CGSize textSize = CGSizeZero;
        if ( mapMarker.label )
        {
            textSize = [ mapMarker.label sizeWithFont:[UIFont systemFontOfSize:PG_MAP_MARKERVIEW_TEXTFONTSIZE]];
            maxSize.width = MAX(maxSize.width, textSize.width);
        }
        maxSize.width += 2*PG_MAP_MARKERVIEW_GAP;
        
        CGFloat heightOffset = PG_MAP_MARKERVIEW_GAP;
        // 绘制图片
        if ( portraitImage )
        {
            //计算图片的绘制位置
            CGRect imgRect = CGRectZero;
            imgRect.size = portraitImage.size;
            imgRect.origin.x = (maxSize.width - portraitImage.size.width)/2.0f;
            imgRect.origin.y = heightOffset;
            self.portraitImageView.frame = imgRect;
            heightOffset = (portraitImage.size.height + PG_MAP_MARKERVIEW_GAP);
        }
        // 绘制文字
        if ( mapMarker.label )
        {
            CGRect labelRect = CGRectZero;
            labelRect.size = textSize;
            labelRect.origin.x = (maxSize.width - textSize.width)/2.0f;
            labelRect.origin.y = heightOffset;
            self.nameLabel.frame  = labelRect;
            heightOffset += textSize.height;
        }
        heightOffset += PG_MAP_MARKERVIEW_GAP;
        self.bounds = CGRectMake(0, 0, maxSize.width, heightOffset);
    }
   // self.centerOffset = CGPointMake(0, -CGRectGetMidY(self.bounds));
    if ( self.calloutView ) {
        self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
                                              -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
    }
}
//- (void)addTapGestureRecognizer{
//    UITapGestureRecognizer *taprecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCallback:)];
//    taprecognizer.delegate = self;
//    taprecognizer.numberOfTouchesRequired = 1;
//    taprecognizer.numberOfTapsRequired = 1;
//    taprecognizer.cancelsTouchesInView = NO;
//    // taprecognizer.delaysTouchesBegan = YES;
//    // taprecognizer.delaysTouchesEnded = YES;
//    [self addGestureRecognizer:taprecognizer];
//    [taprecognizer release];
//}

-(void)click:(id)sender
{
    if ( [sender isKindOfClass:[PGMapBubbleView class]] )
    {
        //PGMapBubbleView *bubbleView = (PGMapBubbleView*)sender;
        PGMapMarker *marker = (PGMapMarker*)self.annotation;
        if ( marker && [marker isKindOfClass:[PGMapMarker class]] )
        {
            NSString *jsObjectF =
            @"%@.maps.__bridge__.execCallback('%@', {type:'bubbleclick'});";
            NSString *javaScript = [NSString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject],marker.UUID];
            [marker.belongMapview.jsBridge asyncWriteJavascript:javaScript inWebview:marker.belongWebview];
        }
    }
}
-(void)doClickForEvt
{
    id<MAAnnotation> annotation = self.annotation;
    if ( annotation && [annotation isKindOfClass:[PGMapMarker class]] )
    {
        PGMapMarker *marker = (PGMapMarker*)annotation;
        NSString * jsObjectF = @"var args = {type:'markerclick'};\
        %@.maps.__bridge__.execCallback('%@', args);";
        NSString *javaScript = [NSString stringWithFormat:jsObjectF, [H5CoreJavaScriptText plusObject], marker.UUID];
        [marker.belongMapview.jsBridge asyncWriteJavascript:javaScript inWebview:marker.belongWebview];
    }
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

- (void)dealloc {
    [_annotationImageView release];
    self.name = nil;
    self.portrait = nil;
    self.calloutView = nil;
    [super dealloc];
}

@end
