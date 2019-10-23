//
//  DCMapLabel.m
//  DCUniAmap
//
//  Created by XHY on 2019/6/1.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCMapLabel.h"
#import "DCMapConstant.h"

@interface DCMapLabel ()
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

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) NSString *title;

@end

@implementation DCMapLabel

- (void)dealloc {
    NSLog(@"dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
        [self initSubViews];
    }
    return self;
}

- (void)setModel:(DCMapLabelModel *)model {
    if (model == _model) {
        return;
    }
    _model = model;
    
    _rect4CalloutView = CGRectMake(0, 0, k_dcmap_CalloutMinWidth, k_dcmap_CalloutMinHeight);
    self.title = model.content;
    _fontSize = model.fontSize;
    
    _borderRadius = model.borderRadius;
    _borderWidth = model.borderWidth;
    _borderColor = model.borderColor;
    _bgColor = model.bgColor;
    _padding = model.padding;
    _textAlign = model.textAlign;
    _color = model.color;
    
    if ([self.title length]) {
        CGRect rect4Title = [self.title boundingRectWithSize:CGSizeMake(k_dcmap_CalloutMaxWidth - (_padding * 2 + _borderWidth * 2), MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:_fontSize]} context:nil];
        _size4Title = rect4Title.size;
        _rect4CalloutView.size = CGSizeMake(_padding * 2 + _size4Title.width + _borderWidth * 2,
                                            _padding * 2 + _size4Title.height + _borderWidth * 2);
    }
    self.frame = _rect4CalloutView;
    
    //title
    self.titleLabel.frame = CGRectMake(_padding + _borderWidth, _padding + _borderWidth, _size4Title.width, _size4Title.height);
    self.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
    self.titleLabel.textColor = _color;
    self.titleLabel.text = self.title;
    self.titleLabel.textAlignment = _textAlign;
    
    [self setNeedsDisplay];
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

- (void)initSubViews
{
    // 添加标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.userInteractionEnabled = YES;
    self.titleLabel.numberOfLines = 0;
    [self addSubview:self.titleLabel];
}

- (void)drawRect:(CGRect)rect
{

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat sw = _borderWidth; //线的宽度
    float minX = sw / 2.0; //画布最左边x点
    float minY = minX; //画布最上边y点
    float maxWidth = self.bounds.size.width - minX; //画布最右边x点
    float maxHeight = self.bounds.size.height - minX - minX; //画布最下边y点
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
