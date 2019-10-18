//
//  libWXBarcodeComponent.m
//  DCUniBarcode
//
//  Created by 4Ndf on 2019/4/9.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#import "WXBarcodeComponent.h"
#import "WXConvert.h"
#import "WXComponent+Layout.h"
#import "PDRToolSystemEx.h"
#import "PGPlugin.h"
#import "PDRCommonString.h"
#import "PTPathUtil.h"
#import "PDRCore.h"
#import "PDRCoreAppManager.h"
#import "PGWXBarcodeCapture.h"
#import "PGWXBarcodeOverlayView.h"

#import "WXComponentManager.h"

@interface WXBarcodeComponent()<PGWXBarcodeScanViewDelegate>{
        BOOL _isOnmarked;
        BOOL _isOnerror;
}

@property(nonatomic,retain)NSDictionary * pattributes;
@end

@implementation WXBarcodeComponent
@synthesize decodeImgWToFile;
@synthesize decodeImgPath;

WX_EXPORT_METHOD(@selector(start:))
WX_EXPORT_METHOD(@selector(cancel))
WX_EXPORT_METHOD(@selector(setFlash:))

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance {
    if(self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance]) {
        _pattributes  = attributes;
        _filters = attributes[@"filters"];      
    }
    
    return self;
}

-(UIView *)loadView{
     [self BarcodeWithPattributes:_pattributes];
    return _barcodeView;
}

-(void)viewDidLoad{
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self close];
}
- (void)updateStyles:(NSDictionary *)styles{
    
}
- (void)updateAttributes:(NSDictionary *)attributes {
    _pattributes = attributes;
    if ( _pattributes && [_pattributes isKindOfClass:[NSDictionary class]]) {
        _barcodeView.overlayView.style = [self JSStyle2Native:_pattributes];
    }
}
- (void)addEvent:(NSString *)eventName {
    if ([eventName isEqualToString:@"marked"]) {
        _isOnmarked = YES;
    }
    if ([eventName isEqualToString:@"error"]) {
        _isOnerror = YES;
    }
}
- (void)removeEvent:(NSString *)eventName{
    if ([eventName isEqualToString:@"marked"]) {
        _isOnmarked = NO;
    }
    if ([eventName isEqualToString:@"error"]) {
        _isOnerror = NO;
    }
}

#pragma mark -method
- (void) onAppEnterBackground {
    if ( _barcodeView ) {
        [_barcodeView pauseScan];
    }
}

- (void) onAppEnterForeground {
    if (_barcodeView ) {
        if ( _barcodeView.scaning ) {
            [_barcodeView resumeScan];
        }
    }
}
-(PGWXBarcodeScanView*)BarcodeWithPattributes:(NSDictionary*)pattributes{
    
     _barcodeView = nil;
    PGWXBarcodeHints *hints = [PGWXBarcodeCapture wxdecodeHintsWithFilters:_filters];
    if ( !hints ) {
        if (_isOnerror) {
            [self fireEvent:@"error" params:[self errorWithid:[NSNumber numberWithInt:PGPluginErrorNotSupport] errorMes:@"Not Support"]];
        }
        return nil;
    }
    
    if (nil == _barcodeView) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            dispatch_async(dispatch_get_main_queue(), ^{
                self.barcodeView = [[PGWXBarcodeScanView alloc] initWithFrame:CGRectZero];
                self.barcodeView.delegate = self;
        self.barcodeView.autostart = [PGPluginParamHelper getBoolValueInDict:pattributes forKey:@"autostart" defalut:NO];
                self.barcodeView.overlayView.style = [self JSStyle2Native:pattributes];
                self.barcodeView.clipsToBounds = YES;
                self.barcodeView.capture.hints = hints;
                self.barcodeView.capture.torch = NO;
        
//            });
//        });
        
    }
    return _barcodeView ;
    
}


-(void)start:(NSDictionary*)dict{
    if (_barcodeView && !_barcodeView.scaning ) {
        if ( [dict isKindOfClass:[NSDictionary class]] ) {
            NSNumber *conserveV = [dict objectForKey:@"conserve"];
            self.decodeImgWToFile = [PGPluginParamHelper getBoolValue:conserveV defalut:NO];
            if ( self.decodeImgWToFile ) {
                NSString *nameValue = [PGPluginParamHelper getStringValueInDict:dict forKey:g_pdr_string_filename defalut:nil];
                if ( nameValue ) {
                    PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
                    self.decodeImgPath = [PTPathUtil absolutePath:nameValue prefix:@"barcode_" suffix:g_pdr_string_jpg context:coreApp];
                    _barcodeView.capture.captureToFilename = self.decodeImgPath;
                }
            }
            BOOL vibrate = [PGPluginParamHelper getBoolValueInDict:dict forKey:@"vibrate" defalut:true];
            _barcodeView.vibrate = vibrate;
            
            NSString *passPath = [PGPluginParamHelper getStringValueInDict:dict forKey:@"sound" defalut:g_pdr_string_default];
            NSString *soundPath = nil;
            if ( passPath ) {
                if ( NSOrderedSame == [passPath caseInsensitiveCompare:g_pdr_string_default] ) {
                    soundPath = [[NSBundle mainBundle] pathForResource:@"beep-beep" ofType:@"caf" inDirectory:@"PandoraApi.bundle"];
                } else if (NSOrderedSame == [passPath caseInsensitiveCompare:g_pdr_string_none]) {
                    
                }else {
                    PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
                    soundPath = [PTPathUtil h5Path2SysPath:passPath basePath:coreApp.workRootPath context:coreApp];
                }
            }
            if ( soundPath && [soundPath length]) {
                _barcodeView.soundToPlay = [NSURL fileURLWithPath:soundPath];
            }
        }
        _barcodeView.scaning = TRUE;
        [_barcodeView resumeScan];
    }
    
}
-(void)cancel{
    if (_barcodeView && _barcodeView.scaning ) {
        self.decodeImgWToFile = NO;
        _barcodeView.scaning = FALSE;
        [_barcodeView pauseScan];
    }
}
-(void)setFlash:(NSNumber*)open{
    if ( _barcodeView && [open isKindOfClass:[NSNumber class]]){
        _barcodeView.capture.torch = [open boolValue];
    }
}
- (void)close {
    [_barcodeView clearListener];
    [self cancel];
    [_barcodeView removeFromSuperview];
    _barcodeView = nil;
}
#pragma mark -

#pragma mark  widget decoder delegate
- (void)captureResult:(PGWXBarcodeScanView *)capture result:(PGWXBarcodeResult*)result{
    NSString *relativeDecodeFilePath = nil;
    if ( self.decodeImgWToFile ) {
        NSString *decodeImgFilePath = self.decodeImgPath;// [PTPathUtil uniqueNameInAppDocHasPrefix:@"barcode" suffix:@"png"];
        if ( decodeImgFilePath ) {
            PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
            relativeDecodeFilePath = [PTPathUtil relativePath:decodeImgFilePath withContext:coreApp];
        }
    }
    capture.scaning = FALSE;
    if (_isOnmarked) {
        [self fireEvent:@"marked" params:[self decodeResutWithText:result.text format:[result wxscanBarcodeFormat] file:relativeDecodeFilePath]?:@{}];
    }
    H5CORE_LOG(@"zxingController exec end");
}

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
    return CGRectZero;
}

- (WXScanviewStyle*)JSStyle2Native:(NSDictionary*)style {
    WXScanviewStyle *nativeStyle = [WXScanviewStyle new];
    if ( [style isKindOfClass:[NSDictionary class]] ) {
        nativeStyle.frameColor = [UIColor colorWithCSS:[style objectForKey:@"frameColor"]];
        if (![style objectForKey:@"background"]) {
            if (self.barcodeView.autostart == YES) {
                nativeStyle.scanBackground =  [UIColor clearColor];
            }else{
                self.barcodeView.pbackGroundColor = [UIColor blackColor];
                nativeStyle.scanBackground =  [UIColor blackColor];
            }
        }else{
            if (self.barcodeView.autostart == YES) {
                nativeStyle.scanBackground =  [UIColor clearColor];
            }else{
                self.barcodeView.pbackGroundColor = [UIColor colorWithCSS:[style objectForKey:@"background"]];
                nativeStyle.scanBackground =  [UIColor colorWithCSS:[style objectForKey:@"background"]];
            }
        }
        nativeStyle.scanbarColor = [UIColor colorWithCSS:[style objectForKey:@"scanbarColor"]];
        
    }
    return nativeStyle;
}


- (NSDictionary*)decodeResutWithText:(NSString*)text format:(PGWXBarcodeFormat)barcodeFormat file:(NSString*)filePath {
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:text, @"message",
    [NSNumber numberWithLong:barcodeFormat], @"code",
    filePath?filePath:[NSNull null] , @"file",
    @"success",@"type",
    nil];
    return [NSDictionary dictionaryWithObjectsAndKeys:dic, @"detail",nil];
}
-(NSDictionary *)errorWithid:(NSNumber*)Errorid errorMes:(NSString*)mes{
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:mes, @"message",
    Errorid, @"code",
    @"fail",@"type",
    nil];
   return [NSDictionary dictionaryWithObjectsAndKeys:dic, @"detail",nil];
}
@end

