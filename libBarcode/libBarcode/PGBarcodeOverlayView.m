//
//  PGBarcodeOverlayView.m
//  libBarcode
//
//  Created by DCloud on 15/12/8.
//  Copyright © 2015年 DCloud. All rights reserved.
//

#import "PGBarcodeOverlayView.h"

void drawLinearGradient(CGContextRef context,
                        CGRect rect,
                        CGColorRef startColor,
                        CGColorRef endColor)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0,1.0}; //颜色所在位置
    
    NSArray *colors = [NSArray arrayWithObjects:(__bridge id)startColor,(__bridge id)endColor, nil];//渐变颜色数组
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef) colors, locations);//构造渐变
    
    CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
    
    CGContextSaveGState(context);//保存状态，主要是因为下面用到裁剪。用完以后恢复状态。不影响以后的绘图
    CGContextAddRect(context, rect);//设置绘图的范围
    CGContextClip(context);//裁剪
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);//绘制渐变效果图
    CGContextRestoreGState(context);//恢复状态
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@implementation ScanviewStyle
@end

@implementation ScanlineLayer

- (void)drawInContext:(CGContextRef)context {
    CGColorRef whiteColor = nil;
    CGColorRef lightGrayColor = nil;
    if ( self.scanbarColor ) {
        whiteColor = [self.scanbarColor colorWithAlphaComponent:0.0].CGColor;
        lightGrayColor = [self.scanbarColor colorWithAlphaComponent:1.0].CGColor;
    } else {
        whiteColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.0].CGColor;
        lightGrayColor = [UIColor colorWithRed:1.0 green: 0.0 blue:0.0 alpha:1.0].CGColor;
    }
    CGRect paperRect = CGRectMake(0, 0, self.bounds.size.width/2, self.bounds.size.height);
    drawLinearGradient(context, paperRect, whiteColor,lightGrayColor);
    CGRect paperRect2 = CGRectMake(self.bounds.size.width/2, 0, self.bounds.size.width/2, self.bounds.size.height);
    drawLinearGradient(context, paperRect2, lightGrayColor, whiteColor);
}

@end

///static const CGFloat kPadding = 10;
//static const CGFloat kLicenseButtonPadding = 10;
//扫描区域的最大长度
static CGFloat kRegionalMaxsize = 640.0f;
static CGFloat kRegionalMinsize = 240.0f;
//扫描区域占覆盖view的百分比
static CGFloat kRegionalPercent = 0.6f;
//扫描线的宽度
static CGFloat kScanLineWidth = 4.0f;
static CGFloat kScanLineHeightPercent = 0.10f;
static CGFloat kBorderwidth = -2.0f;
static CGFloat kOverlayColor[] = {0.0f, 0.0f, 0.0f, 0.6f};
static CGFloat kLineColor[] = {1.0f, 0.0f, 0.0f, 1.0f};

@interface PGBarcodeOverlayView()
@end


@implementation PGBarcodeOverlayView
@synthesize cropRect;

////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if( self ) {
//        CGFloat cropsize = [self getCropSize];
//        CGPoint margin = [self getMarginWithCropSize:cropsize];
//        cropRect = CGRectMake(margin.x, margin.y, cropsize, cropsize);
        
        self.backgroundColor = [UIColor clearColor];
        self.layer.needsDisplayOnBoundsChange = YES;
        _scanLineLayer = [[ScanlineLayer alloc] init];
        _scanLineLayer.frame = CGRectZero;
        _scanLineLayer.needsDisplayOnBoundsChange = YES;
    }
    return self;
}

- (void)stopScanline {
    [_scanLineLayer removeAllAnimations];
    //[_scanLineLayer removeFromSuperlayer];
}

- (CGFloat)getCropSize {
    CGFloat height = self.bounds.size.height;
    CGFloat width  = self.bounds.size.width;
    CGFloat cropsize = height > width ? width : height;
    CGFloat shortsize = cropsize;
    
    cropsize *= kRegionalPercent;
    if ( cropsize > kRegionalMaxsize ) {
        cropsize = kRegionalMaxsize;
    } else if (cropsize < kRegionalMinsize) {
        cropsize = kRegionalMinsize;
        if ( cropsize > shortsize ) {
            cropsize = shortsize;
        }
    }
    return cropsize;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGFloat cropsize = [self getCropSize];
    CGPoint margin = [self getMarginWithCropSize:cropsize];
    cropRect = CGRectMake(margin.x, margin.y, cropsize, cropsize);
}

- (CGPoint)getMarginWithCropSize:(CGFloat)cropSize {
    CGFloat marginY = (self.bounds.size.height - cropSize) /2;
    CGFloat marginX = (self.bounds.size.width - cropSize) /2;
    return CGPointMake(marginX, marginY);
}

- (CGPoint)getPaddingWithMargin:(CGPoint)marginSize {
    return CGPointMake(marginSize.x + kBorderwidth + kScanLineWidth,
                       marginSize.y + kBorderwidth + kScanLineWidth);
}

- (void)startScanline {
    CGFloat cropsize = [self getCropSize];
    CGPoint margin = [self getMarginWithCropSize:cropsize];
    CGPoint padding = [self getPaddingWithMargin:margin];
    
    _scanLineLayer.frame = CGRectMake(padding.x, padding.y,
                                      cropsize-2*kBorderwidth-2*kScanLineWidth,
                                      kScanLineWidth);
    
    CABasicAnimation *animation =[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.fromValue=[NSNumber numberWithFloat:0];
    animation.toValue=[NSNumber numberWithFloat:cropsize - 2*kScanLineWidth-kBorderwidth];
    animation.delegate = nil;
    animation.duration=3.0;//动画持续时间
    animation.autoreverses = YES;
    animation.repeatCount = 99999999;
    _scanLineLayer.scanbarColor = self.style.scanbarColor;
    [self.layer insertSublayer:_scanLineLayer atIndex:0];
    [_scanLineLayer addAnimation:animation forKey:@"animation"];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}

/*
 
 - (void)drawRect:(CGRect)rect inContext:(CGContextRef)context {
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
	CGContextStrokePath(context);
 }
 */
- (CGPoint)map:(CGPoint)point {
    CGPoint center;
    center.x = cropRect.size.width/2;
    center.y = cropRect.size.height/2;
    float x = point.x - center.x;
    float y = point.y - center.y;
    int rotation = 90;
    switch(rotation) {
        case 0:
            point.x = x;
            point.y = y;
            break;
        case 90:
            point.x = -y;
            point.y = x;
            break;
        case 180:
            point.x = -x;
            point.y = -y;
            break;
        case 270:
            point.x = y;
            point.y = -x;
            break;
    }
    point.x = point.x + center.x;
    point.y = point.y + center.y;
    return point;
}

#define kTextMargin 10
- (void)drawRect:(CGRect)rect
       fillColor:(const CGFloat[])components
       inContext:(CGContextRef)context {
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
    CGContextSetFillColor(context, components);
    CGContextFillPath(context);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    const CGFloat *scanLineColor = self.style.frameColor ? CGColorGetComponents(self.style.frameColor.CGColor):kLineColor;
    const CGFloat *scanOverlayColor = self.style.scanBackground ? CGColorGetComponents(self.style.scanBackground.CGColor):kOverlayColor;
    CGFloat height = self.bounds.size.height;
    CGFloat width  = self.bounds.size.width;
    CGFloat cropsize = height > width ? width : height;
    CGFloat shortsize = cropsize;
    
    cropsize *= kRegionalPercent;
    if ( cropsize > kRegionalMaxsize ) {
        cropsize = kRegionalMaxsize;
    } else if (cropsize < kRegionalMinsize) {
        cropsize = kRegionalMinsize;
        if ( cropsize > shortsize ) {
            cropsize = shortsize;
        }
    }
    CGFloat lineHeight = cropsize * kScanLineHeightPercent;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat marginY = (self.bounds.size.height - cropsize) /2;
    CGFloat marginX = (self.bounds.size.width - cropsize) /2;
    
    CGFloat paddingY = (marginY+kBorderwidth+kScanLineWidth);
    CGFloat paddingX = (marginX+kBorderwidth+kScanLineWidth);
    // top
    [self drawRect:CGRectMake(0, 0, self.bounds.size.width, paddingY)
         fillColor:scanOverlayColor inContext:context];
    // left
    [self drawRect:CGRectMake(0, paddingY, paddingX, self.bounds.size.height - 2*paddingY )
         fillColor:scanOverlayColor inContext:context];
    //right
    [self drawRect:CGRectMake(width - paddingX, paddingY, paddingX, self.bounds.size.height - 2*paddingY)
         fillColor:scanOverlayColor inContext:context];
    //bottom
    [self drawRect:CGRectMake(0, self.bounds.size.height - paddingY, width, paddingY)
         fillColor:scanOverlayColor inContext:context];
    
    // tl line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, marginX+kScanLineWidth/2, marginY + lineHeight);
    CGContextAddLineToPoint(context, marginX+kScanLineWidth/2, marginY+kScanLineWidth/2);
    CGContextAddLineToPoint(context, marginX+lineHeight, marginY+kScanLineWidth/2);
    CGContextSetStrokeColor(context, scanLineColor);
    CGContextSetLineWidth(context, kScanLineWidth);
    CGContextStrokePath(context);
    
    // tr line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, width - marginX - lineHeight, marginY + kScanLineWidth/2);
    CGContextAddLineToPoint(context, width - marginX - kScanLineWidth/2, marginY + kScanLineWidth/2);
    CGContextAddLineToPoint(context, width - marginX - kScanLineWidth/2, marginY + lineHeight);
    CGContextSetStrokeColor(context, scanLineColor);
    CGContextSetLineWidth(context, kScanLineWidth);
    CGContextStrokePath(context);
    
    // lb line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, marginX+kScanLineWidth/2, height - marginY - lineHeight);
    CGContextAddLineToPoint(context, marginX+kScanLineWidth/2, height - marginY - kScanLineWidth/2);
    CGContextAddLineToPoint(context, marginX+lineHeight, height - marginY - kScanLineWidth/2);
    CGContextSetStrokeColor(context, scanLineColor);
    CGContextSetLineWidth(context, kScanLineWidth);
    CGContextStrokePath(context);
    
    // rb line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, width - marginX - lineHeight,  height - marginY - kScanLineWidth/2);
    CGContextAddLineToPoint(context, width - marginX - kScanLineWidth/2, height - marginY - kScanLineWidth/2);
    CGContextAddLineToPoint(context, width - marginX - kScanLineWidth/2, height - marginY - lineHeight);
    CGContextSetStrokeColor(context, scanLineColor);
    CGContextSetLineWidth(context, kScanLineWidth);
    CGContextStrokePath(context);
    /*
     CGColorRef whiteColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2].CGColor;
     CGColorRef lightGrayColor = [UIColor colorWithRed:1.0 green: 0.0 blue:0.0 alpha:1.0].CGColor;
     CGRect paperRect = CGRectMake(paddingX, paddingY+20, cropsize/2, 4);
     drawLinearGradient(context, paperRect, whiteColor,lightGrayColor);
     CGRect paperRect2 = CGRectMake(paddingX+cropsize/2, paddingY+20, cropsize/2, 4);
     drawLinearGradient(context, paperRect2, lightGrayColor, whiteColor);*/
    //CGContextSetStrokeColorWithColor(context, lightGrayColor);
    //CGRect newrRect = CGRectInset(paperRect, 1.5, 1.5);//构造位置
    // CGContextSetLineWidth(context, 1);//设置笔宽
    // CGContextStrokeRect(context, newrRect);//绘图
    
    
    /*
     static CGFloat y = 100;
     
     y +=10;
     if ( y >= (self.bounds.size.height - 100)) {
     y = 100;
     }
     
     CGContextRef context = UIGraphicsGetCurrentContext();
     
     //    CGMutablePathRef pathRef = CGPathCreateMutable();
     CGFloat lineColor[] = {1.0f, 0.0f, 0.0f, 0.5f};
     CGFloat marginColor[] = {0.5f, 0.5f, 0.5f, 0.5f};
     
     CGRect paths[]= {CGRectMake(0, 0, self.bounds.size.width, 100),
     CGRectMake(0, 0, 100, self.bounds.size.height),
     CGRectMake(self.bounds.size.width - 100, 0, 100, self.bounds.size.height),
     CGRectMake(0, self.bounds.size.height - 100, self.bounds.size.width, 100)};
     CGContextBeginPath(context);
     CGContextAddRects(context, paths, 4);
     CGContextSetFillColor(context, marginColor);
     CGContextFillPath(context);
     
     CGContextBeginPath(context);
     CGContextMoveToPoint(context, 100, 140);
     CGContextAddLineToPoint(context, 100, 100);
     CGContextAddLineToPoint(context, 140, 100);
     CGContextSetStrokeColor(context, lineColor);
     CGContextSetLineWidth(context, 5);
     CGContextStrokePath(context);
     
     CGContextBeginPath(context);
     CGContextMoveToPoint(context, 100, self.bounds.size.height - 140);
     CGContextAddLineToPoint(context, 100, self.bounds.size.height - 100);
     CGContextAddLineToPoint(context, 140, self.bounds.size.height - 100);
     CGContextSetStrokeColor(context, lineColor);
     CGContextSetLineWidth(context, 5);
     CGContextStrokePath(context);
     
     
     CGContextBeginPath(context);
     CGContextMoveToPoint(context, self.bounds.size.width-140, 100);
     CGContextAddLineToPoint(context, self.bounds.size.width-100, 100);
     CGContextAddLineToPoint(context, self.bounds.size.width-100, 140);
     CGContextSetStrokeColor(context, lineColor);
     CGContextSetLineWidth(context, 5);
     CGContextStrokePath(context);
     
     CGContextBeginPath(context);
     CGContextMoveToPoint(context, self.bounds.size.width-140, self.bounds.size.height - 100);
     CGContextAddLineToPoint(context, self.bounds.size.width-100, self.bounds.size.height - 100);
     CGContextAddLineToPoint(context, self.bounds.size.width-100, self.bounds.size.height - 140);
     CGContextSetStrokeColor(context, lineColor);
     CGContextSetLineWidth(context, 5);
     CGContextStrokePath(context);*/
    /*
     if (displayedMessage == nil) {
     self.displayedMessage = NSLocalizedStringWithDefaultValue(@"OverlayView displayed message", nil, [NSBundle mainBundle], @"Place a barcode inside the viewfinder rectangle to scan it.", @"Place a barcode inside the viewfinder rectangle to scan it.");
     }
     CGContextRef c = UIGraphicsGetCurrentContext();
     
     CGFloat white[4] = {1.0f, 1.0f, 1.0f, 1.0f};
     CGContextSetStrokeColor(c, white);
     CGContextSetFillColor(c, white);
     [self drawRect:cropRect inContext:c];
     
     //	CGContextSetStrokeColor(c, white);
     //	CGContextSetStrokeColor(c, white);
     CGContextSaveGState(c);
     if (oneDMode) {
     NSString *text = NSLocalizedStringWithDefaultValue(@"OverlayView 1d instructions", nil, [NSBundle mainBundle], @"Place a red line over the bar code to be scanned.", @"Place a red line over the bar code to be scanned.");
     UIFont *helvetica15 = [UIFont fontWithName:@"Helvetica" size:15];
     CGSize textSize = [text sizeWithFont:helvetica15];
     
     CGContextRotateCTM(c, M_PI/2);
     // Invert height and width, because we are rotated.
     CGPoint textPoint = CGPointMake(self.bounds.size.height / 2 - textSize.width / 2, self.bounds.size.width * -1.0f + 20.0f);
     [text drawAtPoint:textPoint withFont:helvetica15];
     }
     else {
     UIFont *font = [UIFont systemFontOfSize:18];
     CGSize constraint = CGSizeMake(rect.size.width  - 2 * kTextMargin, cropRect.origin.y);
     CGSize displaySize = [self.displayedMessage sizeWithFont:font constrainedToSize:constraint];
     CGRect displayRect = CGRectMake((rect.size.width - displaySize.width) / 2 , cropRect.origin.y - displaySize.height, displaySize.width, displaySize.height);
     [self.displayedMessage drawInRect:displayRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
     }
     CGContextRestoreGState(c);
     int offset = rect.size.width / 2;
     if (oneDMode) {
     CGFloat red[4] = {1.0f, 0.0f, 0.0f, 1.0f};
     CGContextSetStrokeColor(c, red);
     CGContextSetFillColor(c, red);
     CGContextBeginPath(c);
     //		CGContextMoveToPoint(c, rect.origin.x + kPadding, rect.origin.y + offset);
     //		CGContextAddLineToPoint(c, rect.origin.x + rect.size.width - kPadding, rect.origin.y + offset);
     CGContextMoveToPoint(c, rect.origin.x + offset, rect.origin.y + kPadding);
     CGContextAddLineToPoint(c, rect.origin.x + offset, rect.origin.y + rect.size.height - kPadding);
     CGContextStrokePath(c);
     }
     if( nil != _points ) {
     CGFloat blue[4] = {0.0f, 1.0f, 0.0f, 1.0f};
     CGContextSetStrokeColor(c, blue);
     CGContextSetFillColor(c, blue);
     if (oneDMode) {
     CGPoint val1 = [self map:[[_points objectAtIndex:0] CGPointValue]];
     CGPoint val2 = [self map:[[_points objectAtIndex:1] CGPointValue]];
     CGContextMoveToPoint(c, offset, val1.x);
     CGContextAddLineToPoint(c, offset, val2.x);
     CGContextStrokePath(c);
     }
     else {
     CGRect smallSquare = CGRectMake(0, 0, 10, 10);
     for( NSValue* value in _points ) {
     CGPoint point = [self map:[value CGPointValue]];
     smallSquare.origin = CGPointMake(
     cropRect.origin.x + point.x - smallSquare.size.width / 2,
     cropRect.origin.y + point.y - smallSquare.size.height / 2);
     [self drawRect:smallSquare inContext:c];
     }
     }
     }*/
}

- (void)layoutSubviews {
    // [super layoutSubviews];
    CGFloat cropsize = [self getCropSize];
    CGPoint margin = [self getMarginWithCropSize:cropsize];
    CGPoint padding = [self getPaddingWithMargin:margin];
    
    cropRect = CGRectMake(margin.x, margin.y, cropsize, cropsize);
    
    _scanLineLayer.frame = CGRectMake(padding.x, padding.y,
                                      cropsize-2*kBorderwidth-2*kScanLineWidth,
                                      kScanLineWidth);
}

@end

