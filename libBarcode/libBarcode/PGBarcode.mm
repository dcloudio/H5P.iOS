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
#import "PDRCoreApp.h"
#import "PDRCoreAppWindow.h"
#import "PDRCoreWindowManager.h"
#import "PDRCommonString.h"
#import "PDRCoreAppFramePrivate.h"
#import "PGBarcodeCapture.h"
#import "PGBarcodeOverlayView.h"

@interface PGBarcode()<PGBarcodeScanViewDelegate>
{
    PGBarcodeScanView *_curScanWidget;
}
@end

@implementation PGBarcode
@synthesize decodeImgWToFile;
@synthesize decodeImgPath;
static NSMutableDictionary * barcodeDict;
static NSMutableDictionary * barcodeUUIDDic;

- (void) onAppEnterBackground {
    if ( _curScanWidget ) {
        [_curScanWidget pauseScan];
      //  [_widget removeFromSuperview];
    }
}

- (void) onAppEnterForeground {
    if (_curScanWidget ) {
      //  [self.JSFrameContext.webView.scrollView addSubview:_widget];
        if ( _curScanWidget.scaning ) {
            [_curScanWidget resumeScan];
        }
    }
}

- (void)resize:(PGMethod*)command {
    if ( _curScanWidget ) {
        NSArray *size = [command.arguments objectAtIndex:0];
        _curScanWidget.frame = [self JSRect2CGRect:size];
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

- (BOOL)JSStyle2NativeLayout:(NSDictionary*)style{
    if ([style isKindOfClass:[NSDictionary class]]) {
        NSArray* allLayoutStyle = [style allKeys];
        if ([allLayoutStyle containsObject:g_pdr_string_left] ||
            [allLayoutStyle containsObject:g_pdr_string_top] ||
            [allLayoutStyle containsObject:g_pdr_string_width] ||
            [allLayoutStyle containsObject: g_pdr_string_height] ) {
            return false;
        }
    }
    return true;
}

- (void)Barcode:(PGMethod*)command {
    
    if (barcodeDict == nil) {
        barcodeDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    
    if (barcodeUUIDDic == nil) {
        barcodeUUIDDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    
    NSArray *args = command.arguments;
    NSString *cbID = [args objectAtIndex:1];
    NSString* barcodeid = [args objectAtIndex:2];
    NSString* barcodeUUID = [args objectAtIndex:0];
    NSArray *domsize = [args objectAtIndex:3];
    NSArray *filters = [args objectAtIndex:4];
    NSDictionary *styles = [args objectAtIndex:5];

    PGBarcodeScanView* barcodeView = nil;
    PDRCoreAppFrame* pBarcodeFrame = NULL;
    
    PGBarcodeHints *hints = [PGBarcodeCapture decodeHintsWithFilters:filters];
    if ( !hints ) {
        [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
        return;
    }
    
    if (barcodeid) {
        barcodeView = [barcodeDict objectForKey: barcodeid];
    }
    
    if ([domsize isKindOfClass:[NSArray class]]) {
        pBarcodeFrame = self.JSFrameContext;
    }
    
    if (nil == barcodeView) {
        if (domsize && [domsize isKindOfClass:[NSArray class]]) {
            barcodeView = [[PGBarcodeScanView alloc] initWithFrame:[self JSRect2CGRect:domsize] withOptions:styles withJsContext:self];
        }else{
            barcodeView = [[PGBarcodeScanView alloc] initWithFrame:CGRectZero withOptions:styles withJsContext:self];
        }

        barcodeView.delegate = self;
        barcodeView.overlayView.style = [self JSStyle2Native:styles];
        
        barcodeView.clipsToBounds = YES;
        barcodeView.capture.hints = hints;
        barcodeView.capture.torch = NO;
        
        
        if (barcodeView.callbackStack == NULL) {
            barcodeView.callbackStack = [[NSMutableDictionary alloc] init];
        }
        BOOL isDivLayout = [self JSStyle2NativeLayout:styles];
        
        [barcodeDict setObject:barcodeView forKey: barcodeUUID];
        [barcodeUUIDDic setObject:barcodeUUID forKey:barcodeid];
        
        [barcodeView.callbackStack setObject:cbID forKey:self.JSFrameContext.frameID];
        
        if (pBarcodeFrame && isDivLayout) {
            barcodeView.belongFrameId = pBarcodeFrame.frameID;
            [pBarcodeFrame.webEngine.scrollView addSubview:barcodeView];
        }
    }

    PDR_LOG_INFO(@"Barcode create-!!");
}

- (UIView*)__getNativeViewById:(NSString*)barcodeUUID{
    if (barcodeDict) {
        return [barcodeDict objectForKey:barcodeUUID];
    }
    return nil;
}


- (void)onAppFrameWillClose:(PDRCoreAppFrame *)theAppframe{
    if (barcodeDict) {
        NSEnumerator *enumerator = [barcodeDict keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            PGBarcodeScanView* scanView = [barcodeDict objectForKey:key];
            if (scanView) {
                if([scanView.belongFrameId isEqualToString:theAppframe.frameID]){
                    [scanView clearListener];
                    [scanView pauseScan];
                    [scanView removeFromSuperview];
                    [barcodeDict removeObjectForKey:key];
                    return;
                }
            }
        }
    }
}

- (void)addCallBack:(PGMethod*)command{
    PGBarcodeScanView* pgBarcodeView = NULL;
    NSString* callBackID = [command.arguments objectAtIndex:1];
    NSString* barcodeID = [command.arguments objectAtIndex:0];
    if (barcodeDict) {
        pgBarcodeView = [barcodeDict objectForKey:barcodeID];
        if (pgBarcodeView) {
            if (pgBarcodeView.callbackStack == NULL) {
                pgBarcodeView.callbackStack = [[NSMutableDictionary alloc] init];
            }
            [pgBarcodeView.callbackStack setObject:callBackID forKey:self.JSFrameContext.frameID];
        }
    }
}

- (NSData*)getBarcodeById:(PGMethod*)command{
    NSString* barcodeUUID = nil;
    if (barcodeUUIDDic != nil){
        NSString* barcodeID = [command.arguments objectAtIndex:0];
        if (barcodeID) {
            barcodeUUID = [barcodeUUIDDic objectForKey:barcodeID];
            if (barcodeUUID) {
                PGBarcodeScanView* pView  = [barcodeDict objectForKey:barcodeUUID];
                if (pView) {
                    NSDictionary* barcodeStyleDic = @{@"uuid":barcodeUUID,
                                                      @"filters":@"null",@"options":@"null"};
                    return [self resultWithJSON:barcodeStyleDic];
                }
                
            }
        }
    }
    return [self resultWithNull];
}


- (void)start:(PGMethod*)command {
    PGBarcodeScanView* curScanView = NULL;
    NSString* barcodeID = [command.arguments objectAtIndex:0];
    if (barcodeID) {
        curScanView = [barcodeDict objectForKey:barcodeID];
    }

    if (curScanView && !curScanView.scaning ) {
        NSDictionary *dict = [command.arguments objectAtIndex:1];
        if ( [dict isKindOfClass:[NSDictionary class]] ) {
            NSNumber *conserveV = [dict objectForKey:@"conserve"];
            self.decodeImgWToFile = [PGPluginParamHelper getBoolValue:conserveV defalut:NO];
            if ( self.decodeImgWToFile ) {
                NSString *nameValue = [PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_filename defalut:nil];
                if ( nameValue ) {
                    self.decodeImgPath = [PTPathUtil absolutePath:nameValue prefix:@"barcode_" suffix:g_pdr_string_jpg context:self.appContext];
                    curScanView.capture.captureToFilename = self.decodeImgPath;
                }
            }
            BOOL vibrate = [PGPluginParamHelper getBoolValueInDict:dict forKey:@"vibrate" defalut:true];
            curScanView.vibrate = vibrate;
            
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
                curScanView.soundToPlay = [NSURL fileURLWithPath:soundPath];
            }
        }
        curScanView.scaning = TRUE;
        [curScanView resumeScan];
        _curScanWidget = curScanView;
    }
}

- (void)cancel:(PGMethod*)command {
    PGBarcodeScanView* curScanView = NULL;
    NSString* barcodeID = [command.arguments objectAtIndex:0];
    if (barcodeID) {
        curScanView = [barcodeDict objectForKey:barcodeID];
    }

    if (curScanView && curScanView.scaning ) {
        self.decodeImgWToFile = NO;
        curScanView.scaning = FALSE;
        [curScanView pauseScan];
        _curScanWidget = NULL;
    }
}

- (void)close:(PGMethod*)command {
    PGBarcodeScanView* curScanView = NULL;
    NSString* barcodeID = [command.arguments objectAtIndex:0];
    if (barcodeID && barcodeDict) {
        curScanView = [barcodeDict objectForKey:barcodeID];
        [curScanView clearListener];
    }
    
    [self cancel:nil];
    _curScanWidget = NULL;
    
    [curScanView removeFromSuperview];
    curScanView = nil;
    [barcodeDict removeObjectForKey:barcodeID];
}


- (void)setFlash:(PGMethod*)command {
    PGBarcodeScanView* curScanView = NULL;
    NSString* barcodeID = [command.arguments objectAtIndex:0];
    if (barcodeID) {
        curScanView = [barcodeDict objectForKey:barcodeID];
    }
    
    NSNumber *open = [command.arguments objectAtIndex:1];
    if ( curScanView && [open isKindOfClass:[NSNumber class]]){
       // [_widget setTorch:[open boolValue]];
        curScanView.capture.torch = [open boolValue];
    }
}

- (void)setStyle:(PGMethod*)command{
    PGBarcodeScanView* curScanView = NULL;
    NSString* barcodeID = [command.arguments objectAtIndex:0];
    NSDictionary* barcodeStyles = [command.arguments objectAtIndex:1];
    if (barcodeID && barcodeStyles && [barcodeStyles isKindOfClass:[NSDictionary class]]) {
        curScanView = [barcodeDict objectForKey:barcodeID];
        [curScanView setOptions:barcodeStyles];
        curScanView.overlayView.style = [self JSStyle2Native:barcodeStyles];
    }
}

- (void)scan:(PGMethod*)command {
    
    PGBarcodeScanView*  curScanView = [[barcodeDict allValues] firstObject];
    
    NSString *cbID = [command.arguments objectAtIndex:0];
    NSString *argImgPath = [command.arguments objectAtIndex:1];
    NSArray *filters = [command.arguments objectAtIndex:2];
    
    if ( ![argImgPath isKindOfClass:NSString.class] ) {
        [self toErrorCallback:cbID withCode:PGPluginErrorInvalidArgument];
        return;
    }
    BOOL resume = NO;
    if ( curScanView.scaning ) {
        resume = YES;
        [curScanView pauseScan];
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
        [curScanView resumeScan];
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
            relativeDecodeFilePath = [PTPathUtil relativePath:decodeImgFilePath withContext:self.appContext];
        }
    }
    capture.scaning = FALSE;
    PDRPluginResult *jsRet = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                           messageAsDictionary:[self decodeResutWithText:result.text format:[result scanBarcodeFormat] file:relativeDecodeFilePath]];
    [jsRet setKeepCallback:YES];
    
    if (capture.callbackStack) {
        NSArray* allFrames = [capture.callbackStack allKeys];
        for (NSString* frameID in allFrames) {
            NSString* callbackid = [capture.callbackStack objectForKey:frameID];
            if (callbackid) {
                [self toCallback:callbackid withReslut:[jsRet toJSONString] inWebview:frameID];
            }
        }
    }
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

- (CGRect)JSValue2CGRect:(NSDictionary*)dict{
    CGFloat left = [[PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_left] floatValue];
    CGFloat top = [[PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_top] floatValue];
    CGFloat width = [[PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_width] floatValue];
    CGFloat height = [[PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_height] floatValue];
    return CGRectMake(left, top, width, height);
}

- (NSDictionary*)decodeResutWithText:(NSString*)text format:(PGBarcodeFormat)barcodeFormat file:(NSString*)filePath {
    return [NSDictionary dictionaryWithObjectsAndKeys:text, g_pdr_string_message,
            [NSNumber numberWithLong:barcodeFormat], g_pdr_string_type,
            filePath?filePath:[NSNull null] , g_pdr_string_file,
            nil];
}

- (void)dealloc {
    //PGBarcodeScanView* scanView = NULL;
    //[_widget removeFromSuperview];
  
    //self.callBackID = nil;
    self.decodeImgPath = nil;
 
}

@end
