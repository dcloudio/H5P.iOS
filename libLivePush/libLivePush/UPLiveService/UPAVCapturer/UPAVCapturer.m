//
//  UPAVCapturer.m
//  UPAVCaptureDemo
//
//  Created by DING FENG on 3/31/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import "UPAVCapturer.h"
#import <CommonCrypto/CommonDigest.h>
#import <UPLiveSDKDll/UPAVStreamer.h>
#import "GPUImage.h"
#import "GPUImageFramebuffer.h"
#import "LFGPUImageBeautyFilter.h"
#import <UPLiveSDKDll/UPLiveSDKLogger.h>
#import <UPLiveSDKDll/UPLiveSDKConfig.h>
#import "AudioMonitorPlayer.h"

typedef void(^ShotPhotoCompletionBlock)(UIImage *photo);


@interface UPAVCapturer()<RtcManagerDataOutProtocol>
@property (nonatomic, strong) RtcManager *rtc;
@end


@import  Accelerate;


@interface UPAVCapturer()<UPAVStreamerDelegate, UPAudioCaptureProtocol, UPVideoCaptureProtocol> {
    NSError *_capturerError;

    CVPixelBufferRef _backGroundPixBuffer;
    
    
    int _backGroundFrameSendloopid;
    BOOL _backGroundFrameSendloopOn;
    
    //video size, capture size
    CGSize _capturerPresetLevelFrameCropSize;
    dispatch_queue_t _pushFrameQueue;
    UIView *_preview;
    NSString *_outStreamPath;
    NSMutableArray *_autoReconnectionLogs;
    AudioMonitorPlayer *_audioMonitorPlayer;
    
    
    //拍照。 todo 连麦直播拍照
    BOOL _needShotPhoto;
    ShotPhotoCompletionBlock _shotPhotoCompletionBlock;
}

@property (nonatomic, assign) int pushStreamReconnectCount;

@property (nonatomic, strong) UPAVStreamer *rtmpStreamer; // rtmp 推流器
@property (nonatomic, strong) UPVideoCapture *upVideoCapture; // 视频采集器
@property (nonatomic, strong) UPAudioCapture *audioUnitRecorder; // 音频采集器


@property (nonatomic, assign) NSTimeInterval startReconnectTimeInterval;
@property (nonatomic, strong) NSTimer *delayTimer;
@property (nonatomic, assign) int timeSec;
@property (nonatomic, assign) int reconnectCount;
@end



#pragma mark capturer dashboard

@interface UPAVCapturerDashboard()

@property(nonatomic, weak) UPAVCapturer *infoSource_Capturer;

@end

@class UPAVCapturer;

@implementation UPAVCapturerDashboard

- (float)fps_capturer {
    return self.infoSource_Capturer.rtmpStreamer.fps_capturer;
}

- (float)fps_streaming {
    return self.infoSource_Capturer.rtmpStreamer.fps_streaming;
}

- (float)bps {
    return self.infoSource_Capturer.rtmpStreamer.bps;
}

- (int64_t)vFrames_didSend {
    return self.infoSource_Capturer.rtmpStreamer.vFrames_didSend;
}
- (int64_t)aFrames_didSend {
    return self.infoSource_Capturer.rtmpStreamer.aFrames_didSend;
}

- (int64_t)streamSize_didSend {
    return self.infoSource_Capturer.rtmpStreamer.streamSize_didSend;
}

- (int64_t)streamTime_lasting {
    return self.infoSource_Capturer.rtmpStreamer.streamTime_lasting;
}

- (int64_t)cachedFrames {
    return self.infoSource_Capturer.rtmpStreamer.cachedFrames;
}

- (int64_t)dropedFrames {
    return self.infoSource_Capturer.rtmpStreamer.dropedFrames;
}

- (NSString *)description {
    NSString *descriptionString = [NSString stringWithFormat:@"fps_capturer: %f \nfps_streaming: %f \nbps: %f \nvFrames_didSend: %lld \naFrames_didSend:%lld \nstreamSize_didSend: %lld \nstreamTime_lasting: %lld \ncachedFrames: %lld \ndropedFrames:%lld",
                                   self.fps_capturer,
                                   self.fps_streaming,
                                   self.bps,
                                   self.vFrames_didSend,
                                   self.aFrames_didSend,
                                   self.streamSize_didSend,
                                   self.streamTime_lasting,
                                   self.cachedFrames,
                                   self.dropedFrames];
    return descriptionString;
}

@end

@implementation UPAVCapturer

+ (UPAVCapturer *)sharedInstance {
    static UPAVCapturer *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[UPAVCapturer alloc] init];
    });
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _videoOrientation = AVCaptureVideoOrientationPortrait;
        self.capturerPresetLevel = UPAVCapturerPreset_640x480;
        _capturerPresetLevelFrameCropSize = CGSizeZero;
        _fps = 24;
        _viewZoomScale = 1;
        _streamingOn = YES;
        _beautifyOn = NO;
        _increaserRate = 100;//原声
        _pushFrameQueue = dispatch_queue_create("UPAVCapturer.pushFrameQueue", DISPATCH_QUEUE_SERIAL);
        
        _dashboard = [UPAVCapturerDashboard new];
        _dashboard.infoSource_Capturer = self;
        
        //注意:为了与 rtc 系统衔接这里的 samplerate 需要与 rtc 保持一致 32Khz。
        _audioUnitRecorder = [[UPAudioCapture alloc] initWith:UPAudioUnitCategory_recorder
                                                   samplerate:32000];
        _audioUnitRecorder.delegate = self;
        
        _upVideoCapture = [[UPVideoCapture alloc]init];
        _upVideoCapture.delegate = self;
        
        _timeSec = 30;
        _reconnectCount = 0;
        _autoReconnectionLogs = [[NSMutableArray alloc] init];//记录重连事件
        _audioMonitorPlayer = [[AudioMonitorPlayer alloc] init];
    }
    return self;
}


- (void)addNotifications {
#ifndef UPYUN_APP_EXTENSIONS
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidResignActive:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:[UIApplication sharedApplication]];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:[UIApplication sharedApplication]];

#endif
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setBeautifyOn:(BOOL)beautifyOn {
    _beautifyOn = beautifyOn;
    _upVideoCapture.beautifyOn = beautifyOn;
}


- (GPUImageBeautifyFilter *)beautifyFilter {
    return _upVideoCapture.beautifyFilter;
}

- (void)setCapturerStatus:(UPAVCapturerStatus)capturerStatus {
    if (_capturerStatus == capturerStatus) {
        return;
    }
    _capturerStatus = capturerStatus;
    //代理方式回调采集器状态
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:capturerStatusDidChange:)]) {
            [self.delegate capturer:self capturerStatusDidChange:_capturerStatus];
        }
        
        switch (_capturerStatus) {
            case UPAVCapturerStatusStopped:
                break;
            case UPAVCapturerStatusLiving:
                break;
            case UPAVCapturerStatusError: {
                [self stop];
                if ([self.delegate respondsToSelector:@selector(capturer:capturerError:)]) {
                    [self.delegate capturer:self capturerError:_capturerError];
                }
            }
                break;
            default:
                break;
        }
    });
}

- (void)setPushStreamStatus:(UPPushAVStreamStatus)pushStreamStatus {
    
    if (_pushStreamStatus == pushStreamStatus) {
        return;
    }
    _pushStreamStatus = pushStreamStatus;
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:pushStreamStatusDidChange:)]) {
            [self.delegate capturer:self pushStreamStatusDidChange:_pushStreamStatus];
        }
        
        switch (pushStreamStatus) {//原来是  _pushStreamStatus， 因线程和异步问题，引起重连的重复调用，引发失败。
            case UPPushAVStreamStatusClosed:{
                if (!self.delegate ) {
                    //代理可能提前销毁了，在这里提示一下推流结束.
                    [UPLiveSDKLogger log:@"UPAVCapturer.UPAVStreamerStatusClosed" level:UP_Level_debug tag:UP_Tag_event];
                }
            }
                break;
            case UPPushAVStreamStatusConnecting:
                [UPLiveSDKLogger log:@"UPAVCapturer.UPPushAVStreamStatusConnecting" level:UP_Level_debug tag:UP_Tag_event];
                break;
            case UPPushAVStreamStatusReady:
                [UPLiveSDKLogger log:@"UPAVCapturer.UPPushAVStreamStatusReady" level:UP_Level_debug tag:UP_Tag_event];
                break;
            case UPPushAVStreamStatusPushing:
                [UPLiveSDKLogger log:@"UPAVCapturer.UPPushAVStreamStatusPushing" level:UP_Level_debug tag:UP_Tag_event];
                break;
            case UPPushAVStreamStatusError: {
                [UPLiveSDKLogger log:@"UPAVCapturer.UPPushAVStreamStatusError" level:UP_Level_debug tag:UP_Tag_event];

                if ([self autoReconnectionShouldConnect]) {
                    [self autoReconnectionLogsAdd];
                    [UPLiveSDKLogger log:@"UPAVCapturer.尝试重新连接..." level:UP_Level_debug tag:UP_Tag_event];
                    [_rtmpStreamer reconnect];
                } else {
                    self.capturerStatus = UPAVCapturerStatusError;
                }
                /*失败重连尝试三次
                 if (_reconnectCount == 0) {
                 [self reconnectTimes];
                 }
                 self.pushStreamReconnectCount = self.pushStreamReconnectCount + 1;
                 NSString *message = [NSString stringWithFormat:@"UPAVPacketManagerStatusStreamWriteError %@, reconnect %d times", _capturerError, self.pushStreamReconnectCount];
                 
                 NSLog(@"reconnect --%@",message);
                 
                 if (self.pushStreamReconnectCount < 3 && _reconnectCount < 20) {
                 _reconnectCount++;
                 [_rtmpStreamer reconnect];
                 return ;
                 } else {
                 self.capturerStatus = UPAVCapturerStatusError;
                 }
                 */
                break;
            }
        }
    });
}

- (void)setStreamingOn:(BOOL)streamingOn {
    _streamingOn = streamingOn;
    _rtmpStreamer.streamingOn = _streamingOn;
}

- (NSString *)outStreamPath{
    return _outStreamPath;
}

- (void)setOutStreamPath:(NSString *)outStreamPath {
    _outStreamPath = outStreamPath;
}

- (void)setCamaraPosition:(AVCaptureDevicePosition)camaraPosition {
    
    if (self.audioOnly) {
        return;
    }
    
    if (AVCaptureDevicePositionUnspecified == camaraPosition) {
        return;
    }
    if (_camaraPosition == camaraPosition) {
        return;
    }
    _camaraPosition = camaraPosition;

    [_upVideoCapture setCamaraPosition:camaraPosition];
    
}

- (void)setCapturerPresetLevelFrameCropSize:(CGSize)capturerPresetLevelFrameCropSize {
    _capturerPresetLevelFrameCropSize = capturerPresetLevelFrameCropSize;
    [_upVideoCapture resetCapturerPresetLevelFrameSizeWithCropRect:capturerPresetLevelFrameCropSize];
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    _videoOrientation = videoOrientation;
    [_upVideoCapture setVideoOrientation:videoOrientation];
}

- (void)setCapturerPresetLevel:(UPAVCapturerPresetLevel)capturerPresetLevel {
    _capturerPresetLevel = capturerPresetLevel;
    [_upVideoCapture setCapturerPresetLevel:capturerPresetLevel];
    
    switch (_capturerPresetLevel) {
        case UPAVCapturerPreset_480x360:{
            _bitrate = 400000;
            break;
        }
        case UPAVCapturerPreset_640x480:{
            _bitrate = 600000;
            break;
        }
        case UPAVCapturerPreset_960x540:{
            _bitrate = 900000;
            break;
        }
        case UPAVCapturerPreset_1280x720:{
            _bitrate = 1200000;
            break;
        }
        default:{
            _bitrate = 600000;
            break;
        }
    }
    [self setBitrate:_bitrate];
}

- (void)setFps:(int32_t)fps{
    _fps = fps;
    _upVideoCapture.fps = fps;
}


- (NSString *)backgroudMusicUrl{
    return self.audioUnitRecorder.backgroudMusicUrl;
}

- (void)setBackgroudMusicUrl:(NSString *)backgroudMusicUrl {
    self.audioUnitRecorder.backgroudMusicUrl = backgroudMusicUrl;
}

- (void)setBackgroudMusicOn:(BOOL)backgroudMusicOn {
    self.audioUnitRecorder.backgroudMusicOn = backgroudMusicOn;
}

- (BOOL)backgroudMusicOn {
    return  self.audioUnitRecorder.backgroudMusicOn;
}

- (CGFloat)fpsCapture {
    return _rtmpStreamer.fps_capturer;
}

- (void)setIncreaserRate:(int)increaserRate {
    _increaserRate = increaserRate;
    _audioUnitRecorder.increaserRate = increaserRate;
}

- (void)setDeNoise:(BOOL)deNoise {
    _deNoise = deNoise;
    _audioUnitRecorder.deNoise = deNoise;
}

- (void)setBackgroudMusicVolume:(Float32)backgroudMusicVolume {
    _audioUnitRecorder.backgroudMusicVolume = backgroudMusicVolume;
}

- (Float32)backgroudMusicVolume {
    return _audioUnitRecorder.backgroudMusicVolume;
}

- (UIView *)previewWithFrame:(CGRect)frame contentMode:(UIViewContentMode)mode {
    _preview = [_upVideoCapture previewWithFrame:frame contentMode:mode];
    return _preview;
}

- (void)setWatermarkView:(UIView *)watermarkView Block:(WatermarkBlock)block {
    [_upVideoCapture setWatermarkView:watermarkView Block:block];
}

- (void)openCamera:(BOOL)openCamera{
       
  //  dispatch_async(_pushFrameQueue, ^{
        if (openCamera) {
            [_upVideoCapture start];
        }else{
            [_upVideoCapture stop];
        }
    //});
}

- (void)start {
    
    [UPLiveSDKLogger log:@"UPAVCapturer.start" level:UP_Level_debug tag:UP_Tag_event];
    [self addNotifications];
    //实例化推流器 _rtmpStreamer
    dispatch_async(_pushFrameQueue, ^{
        //_outStreamPath 是 nil 时候，只预览拍摄，不初始化推流器
        if (_outStreamPath) {
            _rtmpStreamer = [[UPAVStreamer alloc] initWithUrl:_outStreamPath];
            if (!_rtmpStreamer) {
                NSError *error = [NSError errorWithDomain:@"UPAVCapturer_error"
                                                     code:100
                                                 userInfo:@{NSLocalizedDescriptionKey:@"_rtmpStreamer init failed, please check the push url"}];
                
                _capturerError = error;
                
                if (_streamingOn && [self.delegate respondsToSelector:@selector(capturer:capturerError:)]) {
                    
                    /*抛出推流器实例失败错误
                     在只拍摄不推流的情况下，例如观众端连麦时候 outStreamPath 是 nil 或者无效地址，这个错误不必抛出。
                     除此之外的大多数正常推流、主播连麦都需要推流器，所以这里默认初始化一个 _rtmpStreamer 备用。
                     */
                    
                    [self.delegate capturer:self capturerError:_capturerError];
                }
            }
            _rtmpStreamer.audioOnly = self.audioOnly;
            _rtmpStreamer.bitrate = _bitrate;
            _rtmpStreamer.delegate = self;
            _rtmpStreamer.streamingOn = _streamingOn;
            _rtmpStreamer.videoSize = _capturerPresetLevelFrameCropSize;//有些播放器需要用预设尺寸展示，预设尺寸不准确画面会变形。
            
            if (_openDynamicBitrate) {
                [self openStreamDynamicBitrate:YES];
            }
        }
    });

    _rtmpStreamer.audioOnly = self.audioOnly;
    if (!self.audioOnly) {
        [_upVideoCapture start];
    }
    [_audioUnitRecorder start];
    
    
    BOOL audioMonitorTestOn = NO;
    if (audioMonitorTestOn) {
        _audioUnitRecorder.bgmPlayerType = -1;
        [_audioMonitorPlayer start];
    }
    
    self.capturerStatus = UPAVCapturerStatusLiving;
    
#ifndef UPYUN_APP_EXTENSIONS
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
#endif
    
}

-(void)stop:(BOOL)closePreview {
    [UPLiveSDKLogger log:@"UPAVCapturer.stop" level:UP_Level_debug tag:UP_Tag_event];
    [self stopFrameSendLoop];
    [self removeNotifications];
    //关闭背景音播放器
    if([UPAVCapturer sharedInstance].backgroudMusicOn) {
        [UPAVCapturer sharedInstance].backgroudMusicOn = NO;
    }
    
    //关闭视频采集
    if ( closePreview ){
        [_upVideoCapture stop];
    }
    //关闭反听
    [_audioMonitorPlayer stop];
    
    //关闭音频采集
    [_audioUnitRecorder stop];
    
    //关闭连麦模块
    if (self.rtc.channelConnected) {
        [self.rtc stop];
    }
    
    self.capturerStatus = UPAVCapturerStatusStopped;
    
    //关闭推流器
    dispatch_async(_pushFrameQueue, ^{
        [_rtmpStreamer stop];
        _rtmpStreamer = nil;
    });
#ifndef UPYUN_APP_EXTENSIONS
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
#endif
    _reconnectCount = 0;
    [self autoReconnectionLogsCleanAll];
    if (_backGroundPixBuffer) {
        CFRelease(_backGroundPixBuffer);
        _backGroundPixBuffer = nil;
    }
    if (_delayTimer) {
        [_delayTimer invalidate];
        _delayTimer = nil;
    }
    
}

- (void)stop {
    [self stop:YES];
}

- (void)dealloc {
    [self removeNotifications];
    NSString *message = [NSString stringWithFormat:@"UPAVCapturer dealloc %@", self];
    [UPLiveSDKLogger log:message level:UP_Level_debug tag:UP_Tag_event];

}

- (void)switchCamera{
    [_upVideoCapture switchCamera];
}

- (void)switchCamera:(AVCaptureDevicePosition)camPos{
    [_upVideoCapture setCamaraPosition:camPos];
}

- (void)setCamaraTorchOn:(BOOL)camaraTorchOn {
    _camaraTorchOn = camaraTorchOn;
    [_upVideoCapture setCamaraTorchOn:camaraTorchOn];
}

- (void)setBitrate:(int64_t)bitrate {
    if (bitrate < 0) {
        return;
    }
    _bitrate = bitrate;
    _rtmpStreamer.bitrate = _bitrate;
}

- (void)setViewZoomScale:(CGFloat)viewZoomScale {
    _upVideoCapture.viewZoomScale = viewZoomScale;
}

- (void)setOpenDynamicBitrate:(BOOL)openDynamicBitrate {
    _openDynamicBitrate = openDynamicBitrate;
    if (_rtmpStreamer) {
        [self openStreamDynamicBitrate:_openDynamicBitrate];
    }
}


#pragma mark 动态码率


- (void)openStreamDynamicBitrate:(BOOL)open {
    int max = -1;
    int min = -1;
    switch (_capturerPresetLevel) {
        case UPAVCapturerPreset_480x360:{
            max = 600;
            min = 200;
            break;
        }
        case UPAVCapturerPreset_640x480:{
            max = 720;
            min = 400;
            break;
        }
        case UPAVCapturerPreset_960x540:{
            max = 960;
            min = 500;
            break;
        }
        case UPAVCapturerPreset_1280x720:{
            max = 1440;
            min = 800;
            break;
        }
    }
    [_rtmpStreamer dynamicBitrate:open Max:max * 1000 Min:min * 1000];
}

#pragma mark-- filter 滤镜
- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter {
    [_upVideoCapture setFilter:filter];
}

- (void)setFilterName:(UPCustomFilter)filterName {
    [_upVideoCapture setFilterName:filterName];
}

- (void)setFilters:(NSArray *)filters {
    [_upVideoCapture setFilters:filters];
}

- (void)setFilterNames:(NSArray *)filterNames {
    [_upVideoCapture setFilterNames:filterNames];
}

#pragma mark UPAVStreamerDelegate

-(void)streamer:(UPAVStreamer *)streamer networkSates:(UPAVStreamerNetworkState)status {
    if (_networkSateBlock) {
        _networkSateBlock(status);
    }
}


- (void)streamer:(UPAVStreamer *)streamer statusDidChange:(UPAVStreamerStatus)status error:(NSError *)error {
    
    switch (status) {
        case UPAVStreamerStatusConnecting: {
            self.pushStreamStatus = UPPushAVStreamStatusConnecting;
        }
            break;
        case UPAVStreamerStatusWriting: {
            self.pushStreamStatus = UPPushAVStreamStatusPushing;
            [self autoReconnectionMarkConnected];
//            self.pushStreamReconnectCount = 0;
        }
            break;
        case UPAVStreamerStatusConnected: {
            self.pushStreamStatus = UPPushAVStreamStatusReady;
        }
            break;
        case UPAVStreamerStatusWriteError: {
            _capturerError = error;
            self.pushStreamStatus = UPPushAVStreamStatusError;
        }
            break;
        case UPAVStreamerStatusOpenError: {
            _capturerError = error;
            self.pushStreamStatus = UPPushAVStreamStatusError;
        }
            break;
        case UPAVStreamerStatusClosed: {
            self.pushStreamStatus = UPPushAVStreamStatusClosed;
        }
            break;
            
        case UPAVStreamerStatusIdle: {
        }
            break;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(streamer:statusDidChange:error:)]) {
        [_delegate streamer:streamer statusDidChange:status error:error];
    }
}

#pragma mark UPAudioCaptureProtocol

- (void)didReceiveBuffer:(AudioBuffer)audioBuffer info:(AudioStreamBasicDescription)asbd {
    [self didCaptureAudioBuffer:audioBuffer withInfo:asbd];
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [self startFrameSendLoopWith:_backGroundFrameSendloopid];
        } else {
            if (_backGroundFrameSendloopOn) {
                [self stopFrameSendLoop];
            }
        }
    });
}

#pragma mark applicationActiveSwitch

- (void)applicationDidResignActive:(NSNotification *)notification {
    [UPLiveSDKLogger log:@"UPAVCapturer.ApplicationActive NO" level:UP_Level_debug tag:UP_Tag_event];
    [_upVideoCapture.videoCamera pauseCameraCapture];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [UPLiveSDKLogger log:@"UPAVCapturer.ApplicationActive YES" level:UP_Level_debug tag:UP_Tag_event];

    //电话打断（接通），推流失败问题
    [_audioUnitRecorder start];
    [_upVideoCapture.videoCamera resumeCameraCapture];
}

#pragma mark backgroud push frame loop

- (void)stopFrameSendLoop {
    _backGroundFrameSendloopOn = NO;
    _backGroundFrameSendloopid = _backGroundFrameSendloopid + 1;
    NSLog(@"stop---------%d", _backGroundFrameSendloopid);
}

- (void)startFrameSendLoopWith:(int)loopid {
    if (_backGroundFrameSendloopOn) {
        return;
    }
    _backGroundFrameSendloopOn = YES;
    [self backGroundFrameSendLoopStart:loopid];
}

- (void)backGroundFrameSendLoopStart:(int)loopid {
    if (!_backGroundFrameSendloopOn) {
        NSLog(@"should be closed=id===%d,  now loopid ==%d", loopid, _backGroundFrameSendloopid);
    }
    if (_backGroundFrameSendloopid != loopid) {
        return;
    }
    double delayInSeconds = 1.0 / _fps;
    __weak UPAVCapturer *weakself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (_streamingOn) {
            [_rtmpStreamer pushPixelBuffer:_backGroundPixBuffer];
        }
        
        [UPLiveSDKLogger log:[NSString stringWithFormat:@"UPAVCapturer.backGroundFrameSendLoopStart==loopid=%d", loopid] level:UP_Level_error tag:UP_Tag_event];
        [weakself backGroundFrameSendLoopStart:loopid];
    });
}

#pragma mark push Capture audio/video buffer


- (void)didCapturePixelBuffer:(CVPixelBufferRef)pixelBuffer {
    //kCVPixelFormatType_420YpCbCr8PlanarFullRange
//    NSLog(@"PixelFormatType %@", NSStringFromCode(CVPixelBufferGetPixelFormatType(pixelBuffer)));
    
    if (_needShotPhoto && _shotPhotoCompletionBlock) {
        UIImage *image = [UPAVCapturer imageFromPixelBuffer:pixelBuffer];
        _shotPhotoCompletionBlock(image);
        _needShotPhoto = NO;
        _shotPhotoCompletionBlock = nil;
    }

    if (!_backGroundPixBuffer) {
        size_t width_o = CVPixelBufferGetWidth(pixelBuffer);
        size_t height_o = CVPixelBufferGetHeight(pixelBuffer);
        OSType format_o = CVPixelBufferGetPixelFormatType(pixelBuffer);
        CVPixelBufferRef pixelBuffer_c;
        CVPixelBufferCreate(nil, width_o, height_o, format_o, nil, &pixelBuffer_c);
        
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferLockBaseAddress(pixelBuffer_c, 0);

        size_t dataSize_o = CVPixelBufferGetDataSize(pixelBuffer);
        void *target = CVPixelBufferGetBaseAddress(pixelBuffer_c);
        bzero(target, dataSize_o);
        
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        CIContext *ciContext = [CIContext contextWithEAGLContext:eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];
        
        CGFloat scale = [[UIScreen mainScreen] scale];

        NSInteger fontSize = (width_o / 360. ) * 10;
        
        if (fontSize < 10 ) {
            fontSize = 10;
        }
        
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:fontSize];
        NSDictionary *attributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: [UIColor whiteColor]};
        
        if (!self.markTextForBackGroundPush) {
            self.markTextForBackGroundPush = @"后台推流...";
        }
        NSString *text = self.markTextForBackGroundPush;
        CGSize size = CGSizeMake(width_o / scale, height_o / scale);
        CGSize size_font  = [text sizeWithAttributes:attributes];

        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        [text drawAtPoint:CGPointMake(size.width / 2. - size_font.width / 2., size.height / 2.  - size_font.height / 2.) withAttributes:attributes];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CIImage *filteredImage = [[CIImage alloc] initWithCGImage:image.CGImage];
        CGRect extent = [filteredImage extent];
        [ciContext render:filteredImage
          toCVPixelBuffer:pixelBuffer_c
                   bounds:extent
               colorSpace:CGColorSpaceCreateDeviceRGB()];
        
        _backGroundPixBuffer = pixelBuffer_c;
        CVPixelBufferUnlockBaseAddress(pixelBuffer_c, 0);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
    
    if (self.rtc.channelConnected) {
        // rtc 已经连接视频切换到 rtc 系统
        [[RtcManager sharedInstance] deliverVideoFrame:pixelBuffer];
        return;
    }

    
    //视频数据压入列发送队列
    dispatch_sync(_pushFrameQueue, ^{
        if (_streamingOn) {
            [_rtmpStreamer pushPixelBuffer:pixelBuffer];
        } else {
            //_streaming off 提示。
            NSString *message = [NSString stringWithFormat:@"UPAVCapturer._streaming off %d", _streamingOn];
            [UPLiveSDKLogger log:message level:UP_Level_debug tag:UP_Tag_event];

        }
        if (pixelBuffer) {
            CFRelease(pixelBuffer);
        }
    });
}


- (void)didCaptureAudioBuffer:(AudioBuffer)audioBuffer withInfo:(AudioStreamBasicDescription)asbd{
    if (self.rtc.channelConnected) {
        // rtc 已经连接音频切换到 rtc 系统
        return;
    }
    
    //反听功能，反耳功能
    if (self.capturerStatus == UPAVCapturerStatusLiving) {
        [_audioMonitorPlayer renderAudioBuffer:audioBuffer info:asbd];
    }
    
    //音频数据压缩入列发送队列
    dispatch_sync(_pushFrameQueue, ^{
        
        if (self.audioMute) {
            if (audioBuffer.mData) {
                memset(audioBuffer.mData, 0, audioBuffer.mDataByteSize);
            }
        }
        if (_streamingOn) {
            [_rtmpStreamer pushAudioBuffer:audioBuffer info:asbd];
        }
        
    });
}


- (void)rtcInitWithAppId:(NSString *)appid {

    self.rtc = [RtcManager sharedInstance];
    self.rtc.delegate = self;
    [self.rtc setAppId:appid];
    [UPLiveSDKLogger log:@"UPAVCapturer.连麦模块 InitWithAppId" level:UP_Level_debug tag:UP_Tag_event];


}

- (void)rtcSetViewMode:(int)mode {

    [self.rtc setViewMode:mode];

}

- (UIView *)rtcRemoteView0WithFrame:(CGRect)frame{

    self.rtc.remoteView0.frame = frame;
    return self.rtc.remoteView0;

}

- (UIView *)rtcRemoteView1WithFrame:(CGRect)frame{

    self.rtc.remoteView1.frame = frame;
    return self.rtc.remoteView1;

}

- (int)rtcConnect:(NSString *)channelId{

    [_audioUnitRecorder stop];
    if (![self trySetRtcInputVideoSize]) {
        [UPLiveSDKLogger log:@"UPAVCapturer.连麦错误：请检查 appID 及 采集视频尺寸" level:UP_Level_error tag:UP_Tag_event];
        return -2;
    }
    if (self.audioOnly) {
        [self.rtc muteLocalVideoStream:YES];
    }
    
    [self.rtc startWithRtcChannel:channelId];
    return 0;
}

- (void)rtcClose {

    
    [UPLiveSDKLogger log:@"UPAVCapturer.rtcClose" level:UP_Level_debug tag:UP_Tag_event];
    [self.rtc stop];
    //rtc _audioUnitRecorder
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.capturerStatus == UPAVCapturerStatusLiving) {
            [_audioUnitRecorder stop];
            
            [UPLiveSDKLogger log:@"UPAVCapturer._audioUnitRecorder stop" level:UP_Level_debug tag:UP_Tag_event];
            [_audioUnitRecorder start];
            [UPLiveSDKLogger log:@"UPAVCapturer._audioUnitRecorder start" level:UP_Level_debug tag:UP_Tag_event];
        }
    });

}

- (int)rtcMuteLocalAudioStream:(BOOL)mute {
    if (!self.rtc.channelConnected) return -1;
    return [self.rtc muteLocalAudioStream:mute];
}

- (int)rtcMuteAllRemoteAudioStreams:(BOOL)mute {
    if (!self.rtc.channelConnected) return -1;
    return [self.rtc muteAllRemoteAudioStreams:mute];
}

- (int)rtcMuteRemoteAudioStream:(NSUInteger)uid
                           mute:(BOOL)mute {
    if (!self.rtc.channelConnected) return -1;
    return [self.rtc muteRemoteAudioStream:uid mute:mute];
}


- (BOOL)trySetRtcInputVideoSize{
    int w = _upVideoCapture.capturerPresetLevelFrameCropSize.width;
    int h = _upVideoCapture.capturerPresetLevelFrameCropSize.height;
    return  [self.rtc setInputVideoWidth:w height:h];
}


/*** rtc 音视频输出接口 ***/
-(void)rtc:(RtcManager *)manager didReceiveAudioBuffer:(AudioBuffer)audioBuffer info:(AudioStreamBasicDescription)asbd {
    dispatch_sync(_pushFrameQueue, ^{
        if (_streamingOn) {
            [_rtmpStreamer pushAudioBuffer:audioBuffer info:asbd];
        }
    });
}

-(void)rtc:(RtcManager *)manager didReceiveVideoBuffer:(CVPixelBufferRef)pixelBuffer {
    if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        //应用进入了后台
        return;
    }
    dispatch_sync(_pushFrameQueue, ^{
        if (_streamingOn) {
            [_rtmpStreamer pushPixelBuffer:pixelBuffer];
        }
    });
}

/*** rtc 远程用户进出房间回调接口 ***/
-(void)rtc:(RtcManager *)manager didJoinedOfUid:(NSUInteger)uid {
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:rtcDidJoinedOfUid:)]) {
            [self.delegate capturer:self rtcDidJoinedOfUid:uid];
        }
    });
    

    NSString *message = [NSString stringWithFormat:@"UPAVCapturer.rtc didJoinedOfUid: %lu   onlineUids:  %@",  (unsigned long)uid, manager.onlineUids];
    
    [UPLiveSDKLogger log:message level:UP_Level_debug tag:UP_Tag_event];

}
-(void)rtc:(RtcManager *)manager didOfflineOfUid:(NSUInteger)uid reason:(NSUInteger)reason {
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:rtcDidOfflineOfUid:reason:)]) {
            [self.delegate capturer:self rtcDidOfflineOfUid:uid reason:reason];
        }
    });
    
    NSString *message = [NSString stringWithFormat:@"UPAVCapturer.rtc didOfflineOfUid: %lu   onlineUids: %@", (unsigned long)uid, manager.onlineUids];
    [UPLiveSDKLogger log:message level:UP_Level_debug tag:UP_Tag_event];
}

/*** rtc 错误及警告***/
- (void)rtc:(RtcManager *)manager didOccurWarning:(NSUInteger)warningCode {
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:rtcDidOccurWarning:)]) {
            [self.delegate capturer:self rtcDidOccurWarning:warningCode];
        }
    });
}
- (void)rtc:(RtcManager *)manager didOccurError:(NSUInteger)errorCode {
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:rtcDidOccurError:)]) {
            [self.delegate capturer:self rtcDidOccurError:errorCode];
        }
    });
    
    NSString *message = [NSString stringWithFormat:@"UPAVCapturer.rtc didOccurError: %lu", (unsigned long)errorCode];
    [UPLiveSDKLogger log:message level:UP_Level_debug tag:UP_Tag_event];
}

- (void)rtcConnectionDidLost:(RtcManager *)manager {
    //连麦异常断开
    [UPLiveSDKLogger log:@"UPAVCapturer.rtcConnectionDidLost" level:UP_Level_error tag:UP_Tag_event];

    [self rtcClose];
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([self.delegate respondsToSelector:@selector(capturer:rtcConnectionDidLost:)]) {
            [self.delegate capturer:self rtcConnectionDidLost:manager];
        }
    });
}


#pragma mark auto reconnnection
//自动重连计数与限制
- (void)autoReconnectionLogsAdd{
   // log {date:date, flag:0-重连发送 1-连接初步成功，只是前几个数据帧发送成功}
    NSMutableDictionary *log = [NSMutableDictionary new];
    [log setObject:[NSDate date] forKey:@"date"];
    [log setObject:@"0" forKey:@"flag"];
    [_autoReconnectionLogs addObject:log];
}

- (void)autoReconnectionLogsCleanAll{
    [_autoReconnectionLogs removeAllObjects];
}

//连接初步成功, 标记flag
- (void)autoReconnectionMarkConnected{
    [_autoReconnectionLogs.lastObject setObject:@"1" forKey:@"flag"];
}


//重连限制策略定义
- (BOOL)autoReconnectionShouldConnect {
    NSInteger logsCount = _autoReconnectionLogs.count;

    //一次直播最多重连次数限制 10 次
    int reconnectionMaxCountLimit = 10;
    if (logsCount > reconnectionMaxCountLimit) {
        
        [UPLiveSDKLogger log:@"UPAVCapturer.autoReconnection: 最多重连次数限制 10 次, 停止自动重连" level:UP_Level_error tag:UP_Tag_event];
        return NO;
    }

    // 15秒内重连次数限制 3 次
    int reconnectionFrequencyLimit  = 3;
    int tempCount = 0;
    for (NSDictionary *log in _autoReconnectionLogs) {
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[log objectForKey:@"date"]];
        if (interval < 15) {
            tempCount ++;
        }
    }
    if (tempCount > reconnectionFrequencyLimit) {
        [UPLiveSDKLogger log:@"UPAVCapturer.autoReconnection: 15秒内重连次数限制 3 次, 停止自动重连" level:UP_Level_error tag:UP_Tag_event];
        return NO;
    }
    
    //连续重连失败次数限制 2 次
    int reconnectionFailedLimit = 2;
    if (logsCount >= reconnectionFailedLimit) {
        for (NSInteger index = logsCount - 1;
             index >= logsCount - reconnectionFailedLimit;
             index --) {
            
            NSString *flag = [[_autoReconnectionLogs objectAtIndex:index] objectForKey:@"flag"];
            if ([flag isEqualToString:@"1"]) {
                //最近几次重连不是连续的失败，返回YES
                return YES;
            }
        }
        //最近几次重连是连续的失败，返回 NO
        [UPLiveSDKLogger log:@"UPAVCapturer.autoReconnection: 连续重连失败次数限制 2 次, 停止自动重连" level:UP_Level_error tag:UP_Tag_event];

        return NO;
        
    }
    return  YES;
}


- (void)reconnectTimes {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delayTimer) {
            [_delayTimer invalidate];
            _delayTimer = nil;
        }
        _delayTimer = [NSTimer scheduledTimerWithTimeInterval:_timeSec target:self selector:@selector(afterTimes) userInfo:nil repeats:NO];
    });
}

- (void)afterTimes {
    _reconnectCount = 0;
}

- (void)shotPhoto:(void(^)(UIImage *photo))complete {
    _needShotPhoto = YES;
    _shotPhotoCompletionBlock = complete;
}

+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBufferRef];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(pixelBufferRef),
                                                 CVPixelBufferGetHeight(pixelBufferRef))];
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return uiImage;
}


#pragma mark upyun token

+ (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned int)strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}

@end
