//
//  PGBarcode.m
//  libBarcode
//
//  Created by DCloud on 15/12/9.
//  Copyright © 2015年 DCloud. All rights reserved.
//
#import "PGBarcode.h"
#import "PTPathUtil.h"
#import "PTLog.h"
#import "PDRToolSystemEx.h"
#import "PDRCoreWindowManager.h"
#import "PDRCommonString.h"
#import "PDRCoreAppFramePrivate.h"
#import "PGBarcodeCapture.h"
#import "PGBarcodeOverlayView.h"

@interface PGBarcode()<PGBarcodeScanViewDelegate>
@end

@implementation PGBarcode

@synthesize callBackID;
@synthesize scaning;
@synthesize decodeImgWToFile;
@synthesize decodeImgPath;

- (void) onAppEnterBackground {
    if ( _widget ) {
        [_widget pauseScan];
      //  [_widget removeFromSuperview];
    }
}

- (void) onAppEnterForeground {
    if (_widget ) {
      //  [self.JSFrameContext.webView.scrollView addSubview:_widget];
        if ( self.scaning ) {
            [_widget resumeScan];
        }
    }
}

- (void)resize:(PGMethod*)command {
    if ( _widget ) {
        NSArray *size = [command.arguments objectAtIndex:0];
        _widget.frame = [self JSRect2CGRect:size];
    }
}

- (ScanviewStyle*)JSStyle2Native:(NSDictionary*)style {
    ScanviewStyle *nativeStyle = [ScanviewStyle new];
    if ( [style isKindOfClass:[NSDictionary class]] ) {
        nativeStyle.frameColor = [UIColor colorWithCSS:[style objectForKey:@"frameColor"]];
        nativeStyle.scanBackground = [UIColor colorWithCSS:[style objectForKey:g_pdr_string_background]];
        nativeStyle.scanbarColor = [UIColor colorWithCSS:[style objectForKey:@"scanbarColor"]];
    }
    return nativeStyle;
}

- (void)Barcode:(PGMethod*)command {
    NSArray *args = command.arguments;
    NSString *cbID = [args objectAtIndex:0];
    NSArray *size = [args objectAtIndex:1];
    NSArray *filters = [args objectAtIndex:2];
    NSDictionary *styles = [args objectAtIndex:3];

    self.callBackID = cbID;
    
    PGBarcodeHints *hints = [PGBarcodeCapture decodeHintsWithFilters:filters];
    if ( !hints ) {
        [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
        return;
    }
    if ( nil == _widget ) {  
        _widget = [[PGBarcodeScanView alloc] initWithFrame:[self JSRect2CGRect:size]];
        _widget.delegate = self;
        _widget.overlayView.style = [self JSStyle2Native:styles];
        _widget.clipsToBounds = YES;
    
        _widget.capture.hints = hints;
        _widget.capture.torch = NO;
        [self.JSFrameContext.webEngine.scrollView addSubview:_widget];
    }
    PDR_LOG_INFO(@"Barcode create-!!");
}

- (void)start:(PGMethod*)command {
    if (_widget && !self.scaning ) {
        NSDictionary *dict = [command.arguments objectAtIndex:0];
        if ( [dict isKindOfClass:[NSDictionary class]] ) {
            NSNumber *conserveV = [dict objectForKey:@"conserve"];
            self.decodeImgWToFile = [PGPluginParamHelper getBoolValue:conserveV defalut:NO];
            if ( self.decodeImgWToFile ) {
                NSString *nameValue = [PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_filename defalut:nil];
                if ( nameValue ) {
                    self.decodeImgPath = [PTPathUtil absolutePath:nameValue prefix:@"barcode_" suffix:g_pdr_string_jpg context:self.appContext];
                    _widget.capture.captureToFilename = self.decodeImgPath;
                }
            }
            BOOL vibrate = [PGPluginParamHelper getBoolValueInDict:dict forKey:@"vibrate" defalut:true];
            _widget.vibrate = vibrate;
            
            NSString *passPath = [PGPluginParamHelper getStringValueInDict:dict forKey:@"sound" defalut:g_pdr_string_default];
            NSString *soundPath = nil;;
            if ( passPath ) {
                if ( NSOrderedSame == [passPath caseInsensitiveCompare:g_pdr_string_default] ) {
                    soundPath = [[NSBundle mainBundle] pathForResource:@"beep-beep" ofType:@"caf" inDirectory:@"PandoraApi.bundle"];
                } else if (NSOrderedSame == [passPath caseInsensitiveCompare:g_pdr_string_none]) {}else {
                    soundPath = [PTPathUtil h5Path2SysPath:passPath basePath:self.JSFrameContext.baseURL context:self.appContext];
                }
            }
            if ( soundPath && [soundPath length]) {
                _widget.soundToPlay = [NSURL fileURLWithPath:soundPath];
            }
        }
        self.scaning = TRUE;
        [_widget resumeScan];
    }
}

- (void)cancel:(PGMethod*)command {
    if (_widget && self.scaning ) {
        self.decodeImgWToFile = NO;
        self.scaning = FALSE;
        [_widget pauseScan];
    }
}

- (void)close:(PGMethod*)command {
    [self cancel:nil];
    [_widget removeFromSuperview];
    _widget = nil;
}


- (void)setFlash:(PGMethod*)command {
    NSNumber *open = [command.arguments objectAtIndex:0];
    if ( _widget && [open isKindOfClass:[NSNumber class]]){
       // [_widget setTorch:[open boolValue]];
        _widget.capture.torch = [open boolValue];
    }
}

- (void)scan:(PGMethod*)command {
    NSString *cbID = [command.arguments objectAtIndex:0];
    NSString *argImgPath = [command.arguments objectAtIndex:1];
    NSArray *filters = [command.arguments objectAtIndex:2];
    
    if ( ![argImgPath isKindOfClass:NSString.class] ) {
        [self toErrorCallback:cbID withCode:PGPluginErrorInvalidArgument];
        return;
    }
    BOOL resume = NO;
    if ( self.scaning ) {
        resume = YES;
        [_widget pauseScan];
    }

    NSString *imgPath = [PTPathUtil absolutePath:argImgPath withContext:self.appContext];
    UIImage *barcodeImg = [UIImage imageWithContentsOfFile:imgPath];

    if ( !barcodeImg ) {
        [self toErrorCallback:cbID withCode:PGPluginErrorFileNotFound];
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
    PGBarcodeHints *hints = [PGBarcodeCapture decodeHintsWithFilters:filters];
    if ( nil == hints ) {
        [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
        return;
    }
    
    NSError *error = nil;
    PGBarcodeResult *decodeResult = [PGBarcodeCapture decodeWithCGImage:barcodeImg.CGImage withHints:hints error:&error];
    if ( resume ) {
        [_widget resumeScan];
    }
    if ( error ) {
        [self toErrorCallback:cbID withCode:PGBarcodeErrorDecodeError];
    } else {
        [self toSucessCallback:cbID withJSON:[self decodeResutWithText:decodeResult.text format:[decodeResult scanBarcodeFormat] file:argImgPath]];
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

- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGBarcodeErrorDecodeError: return @"未发现指定的条码";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}

#pragma mark -
#pragma mark  widget decoder delegate
- (void)captureResult:(PGBarcodeScanView *)capture result:(PGBarcodeResult*)result{
    NSString *relativeDecodeFilePath = nil;
    if ( self.decodeImgWToFile ) {
        NSString *decodeImgFilePath = self.decodeImgPath;// [PTPathUtil uniqueNameInAppDocHasPrefix:@"barcode" suffix:@"png"];
        if ( decodeImgFilePath ) {
            relativeDecodeFilePath = [PTPathUtil relativePath:decodeImgFilePath];
        }
    }
    self.scaning = FALSE;
    PDRPluginResult *jsRet = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                           messageAsDictionary:[self decodeResutWithText:result.text format:[result scanBarcodeFormat] file:relativeDecodeFilePath]];
    [jsRet setKeepCallback:YES];
    [self toCallback:self.callBackID withReslut:[jsRet toJSONString]];
    PDR_LOG_INFO(@"zxingController exec end");
}

#pragma mark -
#pragma mark tools
- (CGRect)JSRect2CGRect:(NSArray*)size {
    CGFloat left = [[size objectAtIndex:0] floatValue];
    CGFloat top = [[size objectAtIndex:1] floatValue];
    CGFloat width = [[size objectAtIndex:2] floatValue];
    CGFloat height = [[size objectAtIndex:3] floatValue];
    return CGRectMake(left, top, width, height);
}

- (NSDictionary*)decodeResutWithText:(NSString*)text format:(PGBarcodeFormat)barcodeFormat file:(NSString*)filePath {
    return [NSDictionary dictionaryWithObjectsAndKeys:text, g_pdr_string_message,
            [NSNumber numberWithLong:barcodeFormat], g_pdr_string_type,
            filePath?filePath:[NSNull null] , g_pdr_string_file,
            nil];
}

- (void)dealloc {
    [_widget removeFromSuperview];
  
    self.callBackID = nil;
    self.decodeImgPath = nil;
 
}

@end
