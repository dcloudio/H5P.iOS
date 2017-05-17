//
//  PGBarcodeOverlayView.h
//  libBarcode
//
//  Created by DCloud on 15/12/8.
//  Copyright © 2015年 DCloud. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ScanviewStyle : NSObject
@property (nonatomic, strong) UIColor *frameColor;// 扫描框颜色
@property (nonatomic, strong) UIColor *scanbarColor;// 扫描条颜色
@property (nonatomic, strong) UIColor *scanBackground;// 条码识别控件背景颜色
@end

@interface ScanlineLayer : CALayer
@property (nonatomic, strong) UIColor *scanbarColor;// 扫描条颜色
@end


@interface PGBarcodeOverlayView : UIView {
    CGRect cropRect;
    ScanlineLayer *_scanLineLayer;
}

@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, strong) ScanviewStyle* style;
- (void)stopScanline;
- (void)startScanline;
@end
