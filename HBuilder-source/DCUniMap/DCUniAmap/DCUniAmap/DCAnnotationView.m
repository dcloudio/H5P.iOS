//
//  DCAnnotationView.m
//  AMapImp
//
//  Created by XHY on 2019/4/13.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "DCAnnotationView.h"
#import "WXImgLoaderProtocol.h"
#import "WXHandlerFactory.h"
#import "DCMapLabel.h"


@interface DCAnnotationView ()

@property (nonatomic, strong) DCMapLabel *label;
@property (nonatomic, strong, readwrite) DCMapCalloutView *calloutView;
@property (nonatomic, strong) id<WXImageOperationProtocol> imageOperation;

@end

@implementation DCAnnotationView

- (DCMapCalloutView *)calloutView {
    if (!_calloutView) {
        _calloutView = [[DCMapCalloutView alloc] init];
        [self addSubview:_calloutView];
        
        UITapGestureRecognizer *tapges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(calloutViewDidClicked)];
        [_calloutView addGestureRecognizer:tapges];
    }
    return _calloutView;
}

- (DCMapLabel *)label {
    if (!_label) {
        _label = [[DCMapLabel alloc] init];
        [self addSubview:_label];
        
        UITapGestureRecognizer *tapges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelClicked)];
        [_label addGestureRecognizer:tapges];
    }
    return _label;
}

- (void)showLabel {
    DCMapMarker *marker = (DCMapMarker *)self.annotation;
    self.label.model = marker.labelModel;
    CGRect labelFrame = self.label.frame;
    labelFrame.origin = CGPointMake(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds));
    self.label.frame = labelFrame;
    self.label.hidden = NO;
}

- (void)hiddenLabel {
    self.label.hidden = YES;
}

- (void)showCalloutView {
    DCMapMarker *marker = (DCMapMarker *)self.annotation;
    self.calloutView.annotation = marker;
    self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
                                          -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
    self.calloutView.hidden = NO;
}

- (void)hiddedCalloutView {
    self.calloutView.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    DCMapMarker *marker = (DCMapMarker *)self.annotation;
    //如果长显当取消选择的时候不响应
    if ([marker.callout.display isEqualToString:dc_map_ALWAYS] && !selected) {
        return;
    }
    
    if (self.selected == selected)
    {
        return;
    }
    
    selected ? [self showCalloutView] : [self hiddedCalloutView];

    [super setSelected:selected animated:animated];
}

- (instancetype)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.annotation = annotation;
        self.canShowCallout = NO;
        self.draggable = NO; //设置标注可以拖动
    }
    return self;
}

- (id<WXImgLoaderProtocol>)imageLoader
{
    static id<WXImgLoaderProtocol> imageLoader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageLoader = [WXHandlerFactory handlerForProtocol:@protocol(WXImgLoaderProtocol)];
    });
    return imageLoader;
}

- (void)updateInfo {
    DCMapMarker *marker = (DCMapMarker *)self.annotation;
    
    self.zIndex = marker.zIndex;
    self.alpha = marker.alpha;
    //设置自定义图标
    if (marker.iconPath && marker.iconPath.length) {
        __weak typeof(self) weakSelf = self;
        weakSelf.imageOperation = [[weakSelf imageLoader] downloadImageWithURL:marker.iconPath imageFrame:self.imageView.frame userInfo:nil completed:^(UIImage *image, NSError *error, BOOL finished) {
            if (weakSelf && !error) {
                if (marker.width && marker.height) {
                    image = [WXConvert resizeWithImage:image scaleSize:CGSizeMake(marker.width, marker.height)];
                }
                weakSelf.image = image;
                [weakSelf setMarkerUseDefaultIcon:NO];
            } else {
                [weakSelf setMarkerUseDefaultIcon:YES];
            }
        }];
    } else {
        [self setMarkerUseDefaultIcon:YES];
    }
}

- (void)setMarkerUseDefaultIcon:(BOOL)useDefaultIcon {
    DCMapMarker *marker = (DCMapMarker *)self.annotation;
    
    if (useDefaultIcon) {
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"AMap" withExtension:@"bundle"]];
        UIImage *image = [UIImage imageWithContentsOfFile:[[bundle resourcePath] stringByAppendingPathComponent:@"images/pin_red.png"]];
        //        UIImage *image = [UIImage imageNamed:@"gps_03"];
        //        image = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
        if (marker.width && marker.height) {
            image = [WXConvert resizeWithImage:image scaleSize:CGSizeMake(marker.width, marker.height)];
        }
        self.image = image;
    }
    
    //锚点(默认底边中点)
    CGFloat centerX = (marker.anchor.x - 0.5) * self.imageView.frame.size.width;
    CGFloat centerY = (marker.anchor.y - 0.5) * -self.imageView.frame.size.height;
    self.centerOffset = CGPointMake(centerX, centerY);
    
    //旋转
    if (marker.rotate) {
        self.imageView.transform = CGAffineTransformMakeRotation( M_PI / 180.0  * marker.rotate);
    }
    
    //是否长显
    if ([marker.callout.display isEqualToString:dc_map_ALWAYS]) {
        [self showCalloutView];
        self.selected = YES;
    } else {
        [self hiddedCalloutView];
        self.selected = NO;
    }
    
    if (marker.labelModel) {
        [self showLabel];
    } else {
        [self hiddenLabel];
    }
    
}

/** 使 不在坐标系中的子视图 可以响应点击事件 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        CGPoint tempoint = [self.calloutView convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.calloutView.bounds, tempoint))
        {
            return self.calloutView;
        }
        tempoint = [self.label convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.label.bounds, tempoint)) {
            return self.label;
        }
    }
    return view;
}

#pragma mark - DCMapCalloutViewDelegate

/// 点击 CalloutView
- (void)calloutViewDidClicked {
    if (self.delegate && [self.delegate respondsToSelector:@selector(annotationCalloutViewTapped:)]) {
        [self.delegate annotationCalloutViewTapped:(DCMapMarker *)self.annotation];
    }
}


/// 点击 label
- (void)labelClicked {
    if (self.delegate && [self.delegate respondsToSelector:@selector(annotationLabelTapped:)]) {
        [self.delegate annotationLabelTapped:(DCMapMarker *)self.annotation];
    }
}

@end
