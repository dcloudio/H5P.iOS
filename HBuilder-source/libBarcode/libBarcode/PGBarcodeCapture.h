//
//  PGBarcodeCapture.h
//  libBarcode
//
//  Created by DCloud on 15/12/9.
//  Copyright © 2015年 DCloud. All rights reserved.
//

#import "ZXCapture.h"
#import "ZXResult.h"
#import "PGBarcodeDef.h"


typedef ZXResult PGBarcodeResult;
typedef ZXCapture PGBarcodeCapture;
typedef ZXDecodeHints PGBarcodeHints;
//
@interface ZXCapture(PGBarcode)
- (void) setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation;
+ (PGBarcodeResult*)decodeWithCGImage:(CGImageRef)imageToDecode
                            withHints:(PGBarcodeHints*)hints error:(NSError**)error;
+ (PGBarcodeHints*)decodeHintsWithFilters:(NSArray*)filters;
@end

@interface ZXResult(PGBarcode)
-(PGBarcodeFormat)scanBarcodeFormat;
+ (ZXBarcodeFormat)H5PForamt2ZX:(PGBarcodeFormat)h5pFormat;
+ (PGBarcodeFormat)ZXForamt2H5P:(ZXBarcodeFormat)zxFormat;
@end

//@protocol PGBarcodeCapture <NSObject>
//@property (nonatomic, assign) BOOL torch; //是否开启闪光灯
//@property (nonatomic, strong) PGBarcodeHints *hints;
//@property (nonatomic, copy) NSString *captureToFilename;//识别图片保存地址
//@property (nonatomic, strong, readonly) CALayer *layer; //视频输出layer
//@property (nonatomic, assign) CGRect scanRect;//扫描窗的大小
//- (void)start;//开始&结束捕获视频
//- (void)stop;//结束捕获视频
//+ (PGBarcodeHints*)decodeHintsWithFilters:(NSArray*)filters;
//- (void) setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation;
//@end