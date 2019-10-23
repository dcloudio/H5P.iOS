//
//  UIImage+DCImageExtend.h
//  libPDRCore
//
//  Created by XHY on 2019/8/29.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDCImageCompressPixel 4096

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (DCImageExtend)

/** 等比例压缩图片 */
- (UIImage *)scaleToWidth:(CGFloat)width;

/** 压缩物理像素界限大小，当图片超过这个值将会被压缩显示，默认为 4096*4096 */
- (BOOL)shouldCompress;

/** 通过ImageIO 方式压缩图片*/
+ (UIImage *)imageFromeData:(NSData *)data scaleToWidth:(CGFloat)width;

/** 通过 CIImage 处理图片旋转解决之前使用 CGContextDrawImage 图片过大内存溢出的问题 */
- (UIImage *)rotationWithAngle:(CGFloat)angle withZoom:(CGSize)outSize;

/** 矫正图片方向 */
- (UIImage *)adjustOrientationUp;

@end

NS_ASSUME_NONNULL_END
