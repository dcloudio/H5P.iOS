//
//  WXBarcodeModule.m
//  DCUniBarcode
//
//  Created by 4Ndf on 2019/5/21.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "WXBarcodeModule.h"
#import "PGPlugin.h"
#import "PTPathUtil.h"
#import "PDRCore.h"
#import "PDRCoreAppManager.h"
#import "PDRToolSystemEx.h"

@interface WXBarcodeModule()
@end

@implementation WXBarcodeModule
@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(scan:callback: filters:))
-(instancetype)init{
    self = [super init];
    if (self) {
       self.barcodeView = [self BarcodeWithPattributes:@{}];
    }
    return self;
}

- (void)scan:(NSString*)argImgPath callback:(WXModuleKeepAliveCallback)callback filters:(NSArray*)filters{//
    if (![argImgPath isKindOfClass:[NSString class]]) {
        if (callback) {
            callback([self errorWithid:[NSNumber numberWithInt:-98] errorMes:@"not path"],NO);
        }
        return;
    }
    
    if ( ![argImgPath isKindOfClass:NSString.class] ) {
        if (callback) {
            callback([self errorWithid:[NSNumber numberWithInt:PGPluginErrorInvalidArgument] errorMes:@"InvalidArgument"],NO);
        }
        return;
    }
    PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
    NSString *imgPath = [PTPathUtil absolutePath:argImgPath withContext:coreApp];
    UIImage *barcodeImg = [UIImage imageWithContentsOfFile:imgPath];
    
    if ( !barcodeImg ) {
        if (callback) {
            callback([self errorWithid:[NSNumber numberWithInt:PGPluginErrorFileNotFound] errorMes:@"NotFound"],NO);
        }
        return;
    }
    
    UIImageOrientation orientation = barcodeImg.imageOrientation;
    float degress = 0;
    switch (orientation) {
        case UIImageOrientationLeft:
            degress = 270;
            break;
        case UIImageOrientationRight:
            degress = 90;
            break;
        case UIImageOrientationDown:
            degress = 180;
            break;
        default:
            break;
    }
    CGImageRef sc = [self createRotatedImage:barcodeImg.CGImage degrees:degress];
    CGSize scaleTosize = barcodeImg.size;
    while ( scaleTosize.width > 640 || scaleTosize.height > 640) {
        scaleTosize.width *= 0.9;
        scaleTosize.height *= 0.9;
    }
    barcodeImg = [barcodeImg scaleToSize:[UIImage imageWithCGImage:sc] size:CGSizeMake(scaleTosize.width, scaleTosize.height)];
    PGWXBarcodeHints *hints = [PGWXBarcodeCapture wxdecodeHintsWithFilters:filters];
    if ( nil == hints ) {
        if (callback) {
            callback([self errorWithid:[NSNumber numberWithInt:PGPluginErrorNotSupport] errorMes:@"NotSupport"],NO);
        }
        return;
    }
    
    NSError *error = nil;
    PGWXBarcodeResult *decodeResult = [PGWXBarcodeCapture wxdecodeWithCGImage:barcodeImg.CGImage withHints:hints error:&error];

    [self.barcodeView resumeScan];
    if ( error ) {
        NSDictionary * dic = [self errorWithid:[NSNumber numberWithInt:PGBarcodeErrorDecodeError]errorMes:error.description];
        if (callback) {
            callback(dic,NO);
        }
    } else {
        NSDictionary * dic = [self decodeResutWithText:decodeResult.text format:[decodeResult wxscanBarcodeFormat] file:argImgPath];
        if (callback) {
            callback(dic,NO);
        }
    }
}

- (CGImageRef)createRotatedImage:(CGImageRef)original degrees:(float)degrees CF_RETURNS_RETAINED {
    if (degrees == 0.0f) {
        CGImageRetain(original);
        return original;
    } else {
        double radians = degrees * M_PI / 180;
        
#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
        radians = -1 * radians;
#endif
        
        size_t _width = CGImageGetWidth(original);
        size_t _height = CGImageGetHeight(original);
        
        CGRect imgRect = CGRectMake(0, 0, _width, _height);
        
        CGAffineTransform __transform = CGAffineTransformMakeRotation(radians);
        CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, __transform);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     rotatedRect.size.width,
                                                     rotatedRect.size.height,
                                                     CGImageGetBitsPerComponent(original),
                                                     0,
                                                     colorSpace,
                                                     kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
        CGContextSetAllowsAntialiasing(context, FALSE);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGColorSpaceRelease(colorSpace);
        
        CGContextTranslateCTM(context,
                              +(rotatedRect.size.width/2),
                              +(rotatedRect.size.height/2));
        CGContextRotateCTM(context, radians);
        
        CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                               -imgRect.size.height/2,
                                               imgRect.size.width,
                                               imgRect.size.height),
                           original);
        
        CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        
        return rotatedImage;
    }
}

-(void)dealloc{
    [self close];
}

@end
