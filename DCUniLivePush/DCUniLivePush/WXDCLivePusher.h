//
//  WXDCLivePusher.h
//  DCUniLivePush
//
//  Created by 4Ndf on 2019/5/13.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "PDRNView.h"
#import <AVFoundation/AVCaptureSession.h>
#import "PGWXLivePusherComponent.h"

typedef void (^DCLivePushHandle)(NSDictionary* result);
NS_ASSUME_NONNULL_BEGIN

@interface WXDCLivePusher : PDRNView

@property (nonatomic, retain) NSString* belongFrameID;

@property (nonatomic, strong) NSString*  pushStreamURL;
@property (nonatomic, assign) WXEDCLiveMode liveMode;
@property (nonatomic, assign) WXEDCLiveOrientation liveOri;
@property (nonatomic, assign) int maxbitrate;
@property (nonatomic, assign) int minbitrate;
@property (nonatomic, retain) UIImage* waittingImage;
@property (nonatomic, retain) NSString* waittingImageHash;
@property (nonatomic, retain) NSMutableArray* pListneerArray;


@property (nonatomic, assign) BOOL hHasActivePusher;
@property (nonatomic, assign) BOOL bInLiveing;
@property (nonatomic, assign) BOOL bBeauty;
@property (nonatomic, assign) BOOL bCameraEnable;
@property (nonatomic, assign) BOOL bWhiteCat;
@property (nonatomic, assign) BOOL bAutoFocus;
@property (nonatomic, assign) BOOL bSilence;

@property (nonatomic, assign) BOOL bIsPlaying;


+(WXDCLivePusher*)getPusherInstance:(NSString*)pusherIdentify;
- (id)initWithOption:(NSArray*)options;
- (void)setVideoOption:(NSDictionary*)options;
- (void)prepareLiveOptions;
- (BOOL)urlMatch:(NSString*)prtmpURL;
- (void)start:(DCLivePushHandle)callBackhandle;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)close;
- (void)switchCamera;
- (void)setParentView:(PDRCoreAppFrame*)pFrame;
- (void)resize:(NSArray*)sizeArg;
- (void)snapshot:(void(^)(UIImage *photo))completion;
- (void)orientChange:(AVCaptureVideoOrientation)captureOri;
@end

NS_ASSUME_NONNULL_END
