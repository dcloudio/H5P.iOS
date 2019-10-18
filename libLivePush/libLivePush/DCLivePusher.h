//
//  LivePusher.h
//  libLivePush
//
//  Created by nearwmy on 2018/7/12.
//  Copyright © 2018年 EICAPITAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureSession.h>
#import "PGLivePush.h"
#import "PDRNView.h"

extern NSString* const EVENT_TEMPLATE;
extern NSString* const EVENT_RESULT_TEMPLATE;
extern NSString* const EventType;

typedef void (^DCLivePushHandle)(NSString* result, NSString* callbackID);

@interface DCLivePusher : PDRNView
//@property (nonatomic, assign) PDRCoreAppFrame* pListenEventFrame;
@property (nonatomic, retain) NSString* startCallbackID;
@property (nonatomic, retain) NSString* belongFrameID;

@property (nonatomic, strong) NSString*  pushStreamURL;
@property (nonatomic, assign) EDCLiveMode liveMode;
@property (nonatomic, assign) EDCLiveOrientation liveOri;
@property (nonatomic, assign) int maxbitrate;
@property (nonatomic, assign) int minbitrate;
//@property (nonatomic, retain) UIImage* waittingImage;
//@property (nonatomic, retain) NSString* waittingImageHash;
@property (nonatomic, retain) NSMutableArray* pListneerArray;


//@property (nonatomic, assign) BOOL hHasActivePusher;
//@property (nonatomic, assign) BOOL bInLiveing;
@property (nonatomic, assign) BOOL bBeauty;
@property (nonatomic, assign) BOOL bCameraEnable;
@property (nonatomic, assign) BOOL bWhiteness;
@property (nonatomic, assign) BOOL bAutoFocus;
@property (nonatomic, assign) BOOL bSilence;
@property (nonatomic,copy)NSString * bAspect;
@property (nonatomic, assign) BOOL bIsPlaying;

@property (nonatomic, assign) BOOL isDivLayout;
@property (nonatomic, retain) NSString* lpPosition;



+(DCLivePusher*)getPusherInstance:(NSString*)pusherIdentify;
- (id)initWithOption:(NSArray*)options;
- (void)setVideoOption:(NSDictionary*)options;
- (void)addEventListener:(PDRCoreAppFrame*)pFrame;
- (void)prepareLiveOptions;
- (BOOL)urlMatch:(NSString*)prtmpURL;
- (void)preview;
- (void)start:(DCLivePushHandle)callBackhandle;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)stop:(BOOL)stopPrview;
- (void)close;
- (void)switchCamera;
- (void)setParentView:(PDRCoreAppFrame*)pFrame;
- (void)resize:(NSArray*)sizeArg;
- (void)snapshot:(void(^)(UIImage *photo))completion;
- (void)orientChange:(AVCaptureVideoOrientation)captureOri;
@end
