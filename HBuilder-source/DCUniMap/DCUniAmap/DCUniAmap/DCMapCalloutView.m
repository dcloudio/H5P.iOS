//
//  DCMapCalloutView.m
//  AMapImp
//
//  Created by XHY on 2019/4/13.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMapCalloutView.h"



@interface DCMapCalloutView ()
{
    CGFloat _borderRadius;
    CGFloat _borderWidth;
    UIColor *_borderColor;
    UIColor *_bgColor;
    CGFloat _padding;
    NSTextAlignment _textAlign;
    UIColor *_color;
    CGRect _rect4CalloutView;
    CGSize _size4Title;
    CGFloat _fontSize;
}

@property (nonatomic, strong) UIImageView *portraitView;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *titleLabel;


@property (nonatomic, copy) NSString *title;

@end

@implementation DCMapCalloutView

- (void)dealloc {
    NSLog(@"dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
        [self initSubViews];
    }
    return self;
}

- (void)setAnnotation:(DCMapMarker *)annotation {
    
    if (_annotation == annotation) {
        return;
    }
    
    _annotation = annotation;
    
    _rect4CalloutView = CGRectMake(0, 0, k_dcmap_CalloutMinWidth, k_dcmap_CalloutMinHeight);
    self.title = annotation.callout.content ?: annotation.title;
    _fontSize = annotation.callout ? annotation.callout.fontSize : k_dcmap_CalloutDefTitleFontsize;
    
    _borderRadius = annotation.callout ? annotation.callout.borderRadius : 0;
    _borderWidth = annotation.callout ? annotation.callout.borderWidth : 0;
    _borderColor = annotation.callout ? annotation.callout.borderColor : [UIColor clearColor];
    _bgColor = annotation.callout ? annotation.callout.bgColor : [UIColor whiteColor];
    _padding = annotation.callout ? annotation.callout.padding : 0;
    _textAlign = annotation.callout ? annotation.callout.textAlign : NSTextAlignmentCenter;
    _color = annotation.callout ? annotation.callout.color : [UIColor blackColor];
    
    if ([self.title length]) {
        CGRect rect4Title = [self.title boundingRectWithSize:CGSizeMake(k_dcmap_CalloutMaxWidth - (_padding * 2 + _borderWidth * 2), MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:_fontSize]} context:nil];
        _size4Title = rect4Title.size;
        _rect4CalloutView.size = CGSizeMake(_padding * 2 + _size4Title.width + _borderWidth * 2,
                                            _padding * 2 + _size4Title.height + _borderWidth * 2 + k_dcmap_ArrorHeight);
    }
    self.frame = _rect4CalloutView;
    
    //title
    self.titleLabel.frame = CGRectMake(_padding + _borderWidth, _padding + _borderWidth, _size4Title.width, _size4Title.height);
    self.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textColor = _color;
    self.titleLabel.text = self.title;
    self.titleLabel.textAlignment = _textAlign;
    
    self.tapButton.frame = self.bounds;
    
    [self setNeedsDisplay];
}

- (void)calloutViewClicked {
    if (self.delegate && [self.delegate respondsToSelector:@selector(calloutViewDidClicked:)]) {
        [self.delegate calloutViewDidClicked:self.annotation];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        [self initSubViews];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

- (void)setImage:(UIImage *)image
{
    self.portraitView.image = image;
}

- (void)initSubViews
{
    // 添加图片
//    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(kPortraitMargin, kPortraitMargin, kPortraitWidth, kPortraitHeight)];
//    self.portraitView.backgroundColor = [UIColor blackColor];
//    [self addSubview:self.portraitView];
    
    // 添加标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.userInteractionEnabled = YES;
    [self addSubview:self.titleLabel];
    
    // 添加点击事件
    self.tapButton = [[UIButton alloc] init];
    [self.tapButton addTarget:self action:@selector(calloutViewClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.tapButton];
    
    // 添加副标题
//    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPortraitMargin * 2 + kPortraitWidth, kPortraitMargin * 2 + kTitleHeight, kTitleWidth, kTitleHeight)];
//    self.subtitleLabel.font = [UIFont systemFontOfSize:12];
//    self.subtitleLabel.textColor = [UIColor lightGrayColor];
//    self.subtitleLabel.text = @"subtitleLabelsubtitleLabelsubtitleLabel";
//    [self addSubview:self.subtitleLabel];
}

- (void)drawRect:(CGRect)rect
{
    if (!_annotation) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat sw = _borderWidth; //线的宽度
    float arrorHeight = k_dcmap_ArrorHeight; //箭头高度
    float minX = sw / 2.0; //画布最左边x点
    float minY = minX; //画布最上边y点
    float maxWidth = self.bounds.size.width - minX; //画布最右边x点
    float maxHeight = self.bounds.size.height - minX - arrorHeight - minX; //画布最下边y点
    float midX = CGRectGetMidX(self.bounds); //画布中心点
    float r = _borderRadius; //圆角角度
    
    //画笔线的颜色
    CGContextSetStrokeColorWithColor(context, _borderColor.CGColor);
    //设置线宽
    CGContextSetLineWidth(context, sw);
    //设置填充颜色
    CGContextSetFillColorWithColor(context, _bgColor.CGColor);
    //开始落笔从坐标右边开始
    CGContextMoveToPoint(context, maxWidth, maxHeight-r);
    
    //画右下角角度
    CGContextAddArcToPoint(context, maxWidth, maxHeight, maxWidth-r, maxHeight, r);
    //画箭头
    CGContextAddLineToPoint(context, midX + arrorHeight, maxHeight);
    CGContextAddLineToPoint(context,midX, maxHeight + arrorHeight);
    CGContextAddLineToPoint(context,midX - arrorHeight, maxHeight);
    //画左下角角度
    CGContextAddArcToPoint(context, minX, maxHeight, minX, maxHeight-r, r);
    //画左上角
    CGContextAddArcToPoint(context, minX, minY, maxWidth-r, minY, r);
    //画右上角
    CGContextAddArcToPoint(context, maxWidth, minY, maxWidth, maxHeight-r, r);
    //将最后的笔触和起始点连接起来
    CGContextClosePath(context);
    //根据绘制路径并填充颜色
    CGContextDrawPath(context, kCGPathFillStroke);
}

@end
