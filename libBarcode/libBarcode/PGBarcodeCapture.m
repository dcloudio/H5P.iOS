//
//  PGBarcodeCapture.m
//  libBarcode
//
//  Created by DCloud on 15/12/9.
//  Copyright © 2015年 DCloud. All rights reserved.
//

#import "PGBarcodeCapture.h"
#import "ZXDecodeHints.h"
#import "ZXMultiFormatReader.h"
#import "ZXCGImageLuminanceSource.h"
#import "ZXBinaryBitmap.h"
#import "ZXHybridBinarizer.h"

@implementation ZXCapture(PGBarcode)

- (void) setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    AVCaptureVideoPreviewLayer *videoLayer = (AVCaptureVideoPreviewLayer*)self.layer;
    if ( NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0 ) {
        if ([[videoLayer connection] isVideoOrientationSupported]) {
            [[videoLayer connection] setVideoOrientation:videoOrientation];
        }
    } else {
        if ( [videoLayer isOrientationSupported] ) {
            videoLayer.orientation = videoOrientation;
        }
    }
}

+ (PGBarcodeResult*)decodeWithCGImage:(CGImageRef)imageToDecode withHints:(PGBarcodeHints*)hints error:(NSError**)error {
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    // There are a number of hints we can give to the reader, including
    // possible formats, allowed lengths, and the string encoding.
    if ( !hints ) {
        hints = [ZXDecodeHints hints];
    }
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:error];
    return result;
}

+ (PGBarcodeHints*)decodeHintsWithFilters:(NSArray*)filters {
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    if ( [filters isKindOfClass:[NSArray class]]
        && [filters count] > 0 ) {
        for ( NSNumber *filter in filters ) {
            PGBarcodeFormat type = (PGBarcodeFormat)[filter intValue];
            ZXBarcodeFormat zxbarcode = [ZXResult H5PForamt2ZX:type];
            if ( zxbarcode > kBarcodeFormatUPCEANExtension ) {
                continue;
            }
            [hints addPossibleFormat:zxbarcode];
        }
        if ( [hints numberOfPossibleFormats] ) {
            return hints;
        }
        return nil;
    }
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    [hints addPossibleFormat:kBarcodeFormatEan13];
    [hints addPossibleFormat:kBarcodeFormatEan8];
    return hints;
}

@end

@implementation ZXResult(PGBarcode)

+ (ZXBarcodeFormat)H5PForamt2ZX:(PGBarcodeFormat)h5pFormat {
    switch (h5pFormat) {
        case PGBarcodeFormatQR:
            return kBarcodeFormatQRCode;
        case PGBarcodeFormatENA8:
            return kBarcodeFormatEan8;
        case PGBarcodeFormatENA13:
            return kBarcodeFormatEan13;
        case PGBarcodeFormatAZTEC :
            return kBarcodeFormatAztec;
        case PGBarcodeFormatDATAMATRIX :
            return kBarcodeFormatDataMatrix;
        case PGBarcodeFormatUPCA :
            return kBarcodeFormatUPCA;
        case PGBarcodeFormatUPCE:
            return kBarcodeFormatUPCE;
        case PGBarcodeFormatPDF417 :
            return kBarcodeFormatPDF417;
        case PGBarcodeFormatRSS14:
            return kBarcodeFormatRSS14;
        case PGBarcodeFormatRSSEXPANDED:
            return kBarcodeFormatRSSExpanded;
        case PGBarcodeFormatMAXICODE:
            return kBarcodeFormatMaxiCode;
        case PGBarcodeFormatCODE128:
            return kBarcodeFormatCode128;
        case PGBarcodeFormatITF:
            return kBarcodeFormatITF;
        case PGBarcodeFormatCODE39:
            return kBarcodeFormatCode39;
        case PGBarcodeFormatCODE93:
            return kBarcodeFormatCode93;
        case PGBarcodeFormatCODABAR:
            return kBarcodeFormatCodabar;
        default:
            break;
    }
    return kBarcodeFormatUPCEANExtension+1;
}

+ (PGBarcodeFormat)ZXForamt2H5P:(ZXBarcodeFormat)zxFormat {
    switch (zxFormat) {
        case kBarcodeFormatQRCode:
            return PGBarcodeFormatQR;
        case kBarcodeFormatEan8:
            return PGBarcodeFormatENA8;
        case kBarcodeFormatEan13:
            return PGBarcodeFormatENA13;
        case kBarcodeFormatAztec:
            return PGBarcodeFormatAZTEC;
        case kBarcodeFormatDataMatrix:
            return PGBarcodeFormatDATAMATRIX;
        case kBarcodeFormatUPCA:
            return PGBarcodeFormatUPCA;
        case kBarcodeFormatUPCE:
        case kBarcodeFormatUPCEANExtension:
            return PGBarcodeFormatUPCE;
        case kBarcodeFormatPDF417:
            return PGBarcodeFormatPDF417;
        case kBarcodeFormatRSS14:
            return PGBarcodeFormatRSS14;
        case kBarcodeFormatRSSExpanded:
            return PGBarcodeFormatRSSEXPANDED;
        case kBarcodeFormatMaxiCode:
            return PGBarcodeFormatMAXICODE;
        case kBarcodeFormatCode128:
            return PGBarcodeFormatCODE128;
        case kBarcodeFormatITF:
            return PGBarcodeFormatITF;
        case kBarcodeFormatCode39:
            return PGBarcodeFormatCODE39;
        case kBarcodeFormatCode93:
            return PGBarcodeFormatCODE93;
        case kBarcodeFormatCodabar:
            return PGBarcodeFormatCODABAR;
        default:
            break;
    }
    return PGBarcodeFormatOther;
}

- (PGBarcodeFormat)scanBarcodeFormat {
    return [ZXResult ZXForamt2H5P:self.barcodeFormat];
}

@end
