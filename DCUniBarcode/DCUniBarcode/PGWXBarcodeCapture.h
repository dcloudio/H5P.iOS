//
//  PGWXBarcodeCapture.h
//  DCUniBarcode
//
//  Created by 4Ndf on 2019/4/12.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#import "ZXCapture.h"
#import "ZXResult.h"
#import "PGWXBarcodeDef.h"


typedef ZXResult PGWXBarcodeResult;
typedef ZXCapture PGWXBarcodeCapture;
typedef ZXDecodeHints PGWXBarcodeHints;
//
@interface ZXCapture(PGWXBarcode)
- (void) setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation;
+ (PGWXBarcodeResult*)wxdecodeWithCGImage:(CGImageRef)imageToDecode
                            withHints:(PGWXBarcodeHints*)hints error:(NSError**)error;
+ (PGWXBarcodeHints*)wxdecodeHintsWithFilters:(NSArray*)filters;
@end

@interface ZXResult(PGWXBarcode)
-(PGWXBarcodeFormat)wxscanBarcodeFormat;
+ (ZXBarcodeFormat)wxH5PForamt2ZX:(PGWXBarcodeFormat)h5pFormat;
+ (PGWXBarcodeFormat)wxZXForamt2H5P:(ZXBarcodeFormat)zxFormat;
@end
