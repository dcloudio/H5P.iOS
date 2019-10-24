//
//  PGBarcodeScanView.h
//  libBarcode
//
//  Created by DCloud on 15/12/8.
//  Copyright © 2015年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGBarcodeCapture.h"
#import "PGBarcodeOverlayView.h"
#import "PDRNView.h"
@class PGBarcodeScanView;

@protocol PGBarcodeScanViewDelegate <NSObject>
- (void)captureResult:(PGBarcodeScanView *)capture result:(PGBarcodeResult*)result;
@end

@interface PGBarcodeScanView : PDRNView
@property (nonatomic, weak) id<PGBarcodeScanViewDelegate> delegate;
@property (nonatomic, retain) NSURL *soundToPlay;
@property (nonatomic, assign) BOOL vibrate;
@property (nonatomic, strong) PGBarcodeCapture *capture;
@property (nonatomic, strong) PGBarcodeOverlayView *overlayView;

@property(nonatomic, assign)BOOL scaning;
@property(nonatomic, strong)NSMutableDictionary* callbackStack;
@property(nonatomic, assign)NSString* belongFrameId;
- (void)pauseScan;
- (void)resumeScan;
- (void)clearListener;
@end
