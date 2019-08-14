//
//  UpYunLivePusher.m
//  DCUniLivePush
//
//  Created by 4Ndf on 2019/5/13.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "WXUpYunLivePusher.h"

#import "PGWXLivePusherComponent.h"
#import "PDRCoreAppFrame.h"
#import "PDRCoreAppFramePrivate.h"
#import "UPAVCapturer.h"
#import <UPLiveSDKDll/UPAVStreamer.h>
#import <UPLiveSDKDll/RtcManager.h>
#import <os/availability.h>
#import <AdSupport/ASIdentifierManager.h>
@interface WXUpYunLivePusher()<UPAVCapturerDelegate>

@property (nonatomic, retain) UPAVCapturer* upavCapturehandle;
@property (nonatomic, assign) UPAVCapturerPresetLevel cameraLevel;
@property (nonatomic, copy)DCLivePushHandle startPushHandle;

@end

@implementation WXUpYunLivePusher

- (id)initWithOption
{
    if ([self init]) {
        _upavCapturehandle = [[UPAVCapturer alloc] init] ; 
    }
    return self;
}
- (void)setWithOption:(NSDictionary *)optionObject{
    if (_upavCapturehandle) {
        _livePushView = [_upavCapturehandle previewWithFrame:self.bounds
                                                 contentMode:UIViewContentModeScaleAspectFit];
        if (_livePushView) {
            [self addSubview:_livePushView];
        }
        _upavCapturehandle.delegate = self;
        self.bIsPlaying = NO;
    }
    [self setVideoOption:optionObject];
}
- (void)onLayout_ {
    self.livePushView.frame = self.bounds;
}

- (void)preview:(BOOL)ispreview {
    [_upavCapturehandle setCamaraPosition:AVCaptureDevicePositionFront];
    [_upavCapturehandle openCamera:ispreview];
}


- (void)start:(DCLivePushHandle)callBackhandle{
    if (!self.bIsPlaying) {
        if (_upavCapturehandle == nil || ![self urlMatch:self.pushStreamURL]) {
            if(callBackhandle){
                NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:@"rtmp url invalidate", @"message",
                                       [NSNumber numberWithInt:-1], @"code",
                                       @"fail",@"type",
                                       nil];
                callBackhandle(dic);
            }
        }
        _startPushHandle = callBackhandle;
        [self prepareLiveOptions];
        [_upavCapturehandle start];
        [_upavCapturehandle setCamaraPosition:AVCaptureDevicePositionFront];
        self.bIsPlaying = YES;
    }
}


- (void)stop {
    if (self.bIsPlaying) {
        self.bIsPlaying = NO;
        [_upavCapturehandle stop];
    }
}

- (void)resume{
    if (!self.bIsPlaying) {
        self.bIsPlaying = YES;
        [self prepareLiveOptions];
        [_upavCapturehandle start];
    }
}

- (void)pause{
    if (self.bIsPlaying) {
        self.bIsPlaying = NO;
        [_upavCapturehandle stop];
    }
}

- (void)close{
    if (_upavCapturehandle) {
        _upavCapturehandle.networkSateBlock = nil;
        [_upavCapturehandle stop];
        _upavCapturehandle = nil;
    }
    
    [self.pListneerArray removeAllObjects];
    self.pListneerArray = nil;
    //self.pListenEventFrame = nil;
    
    if (self.pushStreamURL) {
        self.pushStreamURL = nil;
    }
}



- (void)setVideoOption:(NSDictionary*)pOptions{
    [super setVideoOption:pOptions];
    
    if (nil != _upavCapturehandle ) {
        if ([pOptions objectForKey:@"mode"]) {
            NSString* pModeType = [pOptions objectForKey:@"mode"];
            if ([[pModeType lowercaseString] compare:@"SD"]) {
                self.liveMode = EDCLiveMode_SD;
                self.upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_480x360;
            }else if ([[pModeType lowercaseString] compare:@"HD"]){
                self.liveMode = EDCLiveMode_HD;
                self.upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_640x480;
            }else if ([[pModeType lowercaseString] compare:@"FHD"]){
                self.liveMode = EDCLiveMode_FHD;
                self.upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_960x540;
            }else if ([[pModeType lowercaseString] compare:@"RTC"]){
                self.liveMode = EDCLiveMode_RTC;
                self.upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_640x480;
            }
        }
        
        [self prepareLiveOptions];
    }
}

- (void)switchCamera{
    [_upavCapturehandle switchCamera];
}

- (void)snapshot:(void (^)(UIImage *))completion{
    [_upavCapturehandle shotPhoto:^(UIImage *photo) {
        if (completion) {
            completion(photo);
        }
    }];
}

- (void)prepareLiveOptions
{
    _upavCapturehandle.outStreamPath = self.pushStreamURL;
    
    switch (self.liveMode) {
        case EDCLiveMode_SD:
            _upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_480x360;
            break;
        case EDCLiveMode_HD:
            _upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_640x480;
            break;
        case EDCLiveMode_FHD:
            _upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_1280x720;
            break;
        case EDCLiveMode_RTC:
            _upavCapturehandle.capturerPresetLevel = UPAVCapturerPreset_640x480;
            break;
        default:
            break;
    }
    
    _upavCapturehandle.beautifyOn = self.bBeauty;
    
    _upavCapturehandle.audioMute = self.bSilence;
    
    _upavCapturehandle.audioOnly = self.bCameraEnable;
    
    _upavCapturehandle.bitrate = (self.maxbitrate + self.minbitrate)/2;
    
    __block typeof (self) weakself = self;
    _upavCapturehandle.networkSateBlock = ^(UPAVStreamerNetworkState level) {
        NSDictionary * dic = nil;
        if(level == UPAVStreamerNetworkState_BAD){
                dic =  [NSDictionary dictionaryWithObjectsAndKeys:@"网络断连, 已启动自动重连", @"message", [NSNumber numberWithInt:1102], @"code",nil];
        }else if(level == UPAVStreamerNetworkState_NORMAL){
            dic =  [NSDictionary dictionaryWithObjectsAndKeys:@"网络状况不佳：上行带宽太小，上传数据受阻", @"message", [NSNumber numberWithInt:1101], @"code",nil];
            
        }else if(level == UPAVStreamerNetworkState_GOOD){
            dic =  [NSDictionary dictionaryWithObjectsAndKeys:@"connected", @"message", [NSNumber numberWithInt:1002], @"code",
                    nil];
        }
        if (dic) {
            [weakself dispatchListenerEvent:@{@"detail":dic} EventType:@"netstatus"];
        }
        
    };
    
    // 设置美白需要写一个过滤器
    if (self.bWhiteCat){
        GPUImageBrightnessFilter* filter = [[GPUImageBrightnessFilter alloc] init];
        if (filter){
            filter.brightness = 0.3f;
            [_upavCapturehandle setFilter:filter];
        }
    }
}

#pragma mark - delegates

- (void)streamer:(UPAVStreamer *)streamer statusDidChange:(UPAVStreamerStatus)status error:(NSError *)error
{
    NSDictionary * dic = nil;
    switch (status) {
        case UPAVStreamerStatusConnecting: {
             dic =  [NSDictionary dictionaryWithObjectsAndKeys:error==nil?@"connecting...":error.localizedDescription, @"message", [NSNumber numberWithInt:1001], @"code",nil];
        }
            break;
        case UPAVStreamerStatusWriting: {
        }
            break;
        case UPAVStreamerStatusConnected: {
                dic =  [NSDictionary dictionaryWithObjectsAndKeys:error==nil?@"connected...":error.localizedDescription, @"message", [NSNumber numberWithInt:1002], @"code",nil];
        }
            break;
        case UPAVStreamerStatusWriteError: {
        }
            break;
        case UPAVStreamerStatusOpenError: {
        }
            break;
        case UPAVStreamerStatusClosed: {
        }
            break;
        case UPAVStreamerStatusIdle: {
        }
            break;
    }
    
    if(dic){
        [self dispatchListenerEvent:@{@"detail":dic} EventType:@"statechange"];
    }
}

- (void)dispatchListenerEvent:(NSDictionary*)resuest EventType:(NSString*)EventType{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate listenerEvent:resuest EventType:@"statechange"];
    });
}

/// 采集状态回调
- (void)capturer:(UPAVCapturer *)capturer capturerStatusDidChange:(UPAVCapturerStatus)capturerStatus{
    NSLog(@"capturerStatusDidChange %d", (int)capturer);
}
/// 错误回调
- (void)capturer:(UPAVCapturer *)capturer capturerError:(NSError *)error{
    NSLog(@"capturerError %@", error.localizedDescription);
        
        NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:error.localizedDescription, @"errMsg", [NSNumber numberWithInt:-2], @"errCode",
                               nil];
    [self dispatchListenerEvent:@{@"detail":dic} EventType:@"error"];
}
/// 推流状态回调
- (void)capturer:(UPAVCapturer *)capturer pushStreamStatusDidChange:(UPPushAVStreamStatus)streamStatus{
    NSLog(@"pushStreamStatusDidChange %d", (int)streamStatus);
    if (streamStatus == UPPushAVStreamStatusClosed) {
        NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:@"rtmp disconnected", @"message", [NSNumber numberWithInt:3004], @"code",
                               nil];
        [self dispatchListenerEvent:@{@"detail":dic} EventType:@"statechange"];
    }
}

//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidJoinedOfUid:(NSUInteger)uid{
    NSLog(@"rtcDidJoinedOfUid %d", (int)uid);
}
//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidOfflineOfUid:(NSUInteger)uid reason:(NSUInteger)reason{
    NSLog(@"rtcDidOfflineOfUid 2 %d", (int)uid);
}
//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidOccurWarning:(NSUInteger)warningCode{
    NSLog(@"rtcDidOccurWarning %d", (int)warningCode);
}
//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidOccurError:(NSUInteger)errorCode{
    NSLog(@"rtcDidOccurError %d", (int)errorCode);
}
//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcConnectionDidLost:(id)rtcmanager{
    NSLog(@"rtcConnectionDidLost %@", rtcmanager);
}
@end
