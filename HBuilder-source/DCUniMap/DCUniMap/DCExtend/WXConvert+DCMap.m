//
//  WXConvert+DCMap.m
//  libWeexMap
//
//  Created by XHY on 2019/4/11.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "WXConvert+DCMap.h"

@implementation WXConvert (DCMap)

+ (CLLocationCoordinate2D)CLLocationCoordinate2DLongitude:(double)longitude latitude:(double)latitude
{
    return (CLLocationCoordinate2D){
        latitude,
        longitude
    };
}

+ (UIImage*)resizeWithImage:(UIImage *)image scaleSize:(CGSize)size {
    
    if (nil == image) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimage;
    
//    NSData *data = UIImagePNGRepresentation(image);
//    if(!data) {
//        return nil;
//    }
//
//    // Create the image source
//    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
//
//    if(!imageSourceRef) {
//        return nil;
//    }
//
//    CGFloat maxPixelSize = MAX(size.width, size.height);
//    // Create thumbnail options
//    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
//                                                           (__bridge id)kCGImageSourceShouldCacheImmediately: (__bridge id)kCFBooleanFalse,
//                                                           (__bridge id)kCGImageSourceShouldCache: (__bridge id)kCFBooleanFalse,
//                                                           (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways: (__bridge id)kCFBooleanTrue,
//                                                           (__bridge id)kCGImageSourceThumbnailMaxPixelSize: [NSNumber numberWithFloat:maxPixelSize]
//                                                           };
//
//    // Generate the thumbnail
//    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSourceRef, 0, options);
//    UIImage *thumbnailImage = [UIImage imageWithCGImage:imageRef];
//    CFRelease(imageSourceRef);
//    CGImageRelease(imageRef);
//    return thumbnailImage;
}

+ (CGSize)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect
{
    CGFloat nudgeRight = fmaxf(0, CGRectGetMinX(outerRect) - (CGRectGetMinX(innerRect)));
    CGFloat nudgeLeft = fminf(0, CGRectGetMaxX(outerRect) - (CGRectGetMaxX(innerRect)));
    CGFloat nudgeTop = fmaxf(0, CGRectGetMinY(outerRect) - (CGRectGetMinY(innerRect)));
    CGFloat nudgeBottom = fminf(0, CGRectGetMaxY(outerRect) - (CGRectGetMaxY(innerRect)));
    return CGSizeMake(nudgeLeft ?: nudgeRight, nudgeTop ?: nudgeBottom);
}

+ (UIEdgeInsets)Padding:(NSArray *)padding {
    CGFloat top = [padding dc_safeObjectForKey:0] ? [[padding dc_safeObjectForKey:0] floatValue] : 0;
    CGFloat left = [padding dc_safeObjectForKey:1] ? [[padding dc_safeObjectForKey:1] floatValue] : 0;
    CGFloat bottom = [padding dc_safeObjectForKey:2] ? [[padding dc_safeObjectForKey:2] floatValue] : 0;
    CGFloat right = [padding dc_safeObjectForKey:3] ? [[padding dc_safeObjectForKey:3] floatValue] : 0;
    return UIEdgeInsetsMake(top, left, bottom, right);
}

@end
