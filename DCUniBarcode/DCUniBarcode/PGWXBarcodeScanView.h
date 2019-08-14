//
//  PGWXBarcodeScanView.h
//  DCUniBarcode
//
//  Created by 4Ndf on 2019/4/12.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGWXBarcodeCapture.h"
#import "PGWXBarcodeOverlayView.h"

@class PGWXBarcodeScanView;
NS_ASSUME_NONNULL_BEGIN

@protocol PGWXBarcodeScanViewDelegate <NSObject>

- (void)captureResult:(PGWXBarcodeScanView *)capture result:(PGWXBarcodeResult*)result;
@end
@interface PGWXBarcodeScanView : UIView

@property (nonatomic, weak) id<PGWXBarcodeScanViewDelegate> delegate;
@property (nonatomic, retain) NSURL *soundToPlay;
@property (nonatomic, assign) BOOL vibrate;
@property (nonatomic, strong) PGWXBarcodeCapture *capture;
@property (nonatomic, strong) PGWXBarcodeOverlayView *overlayView;

@property(nonatomic, assign)BOOL scaning;
@property(nonatomic, strong)NSMutableDictionary* callbackStack;

@property(nonatomic,assign)BOOL autostart;
@property(nonatomic,retain)UIColor * pbackGroundColor;
- (void)pauseScan;
- (void)resumeScan;
- (void)clearListener;
@end

NS_ASSUME_NONNULL_END
