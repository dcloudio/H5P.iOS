//
//  UPAVCapturer.h
//  UPAVCaptureDemo
//
//  Created by DING FENG on 3/31/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <UPLiveSDKDll/UPAVStreamer.h>
#import "UPAudioCapture.h"
#import "UPVideoCapture.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import <UPLiveSDKDll/RtcManager.h>

typedef NS_ENUM(NSInteger, UPAVCapturerStatus) {
    UPAVCapturerStatusStopped,
    UPAVCapturerStatusPreview,
    UPAVCapturerStatusLiving,
    UPAVCapturerStatusError
};

typedef NS_ENUM(NSInteger, UPPushAVStreamStatus) {
    UPPushAVStreamStatusClosed,
    UPPushAVStreamStatusConnecting,
    UPPushAVStreamStatusReady,
    UPPushAVStreamStatusPushing,
    UPPushAVStreamStatusError
};


typedef void(^NetworkStateBlock)(UPAVStreamerNetworkState level);


@interface UPAVCapturerDashboard: NSObject
@property (nonatomic, readonly) float fps_capturer;
@property (nonatomic, readonly) float fps_streaming;
@property (nonatomic, readonly) float bps;
@property (nonatomic, readonly) int64_t vFrames_didSend;
@property (nonatomic, readonly) int64_t aFrames_didSend;
@property (nonatomic, readonly) int64_t streamSize_didSend;
@property (nonatomic, readonly) int64_t streamTime_lasting;
@property (nonatomic, readonly) int64_t cachedFrames;
@property (nonatomic, readonly) int64_t dropedFrames;
@end

@class UPAVCapturer;
@protocol UPAVCapturerDelegate <NSObject>

/// 采集状态回调
@optional
- (void)capturer:(UPAVCapturer *)capturer capturerStatusDidChange:(UPAVCapturerStatus)capturerStatus;
/// 错误回调
@required
- (void)capturer:(UPAVCapturer *)capturer capturerError:(NSError *)error;
/// 推流状态回调
@optional
- (void)capturer:(UPAVCapturer *)capturer pushStreamStatusDidChange:(UPPushAVStreamStatus)streamStatus;

@optional
- (void)streamer:(UPAVStreamer *)streamer statusDidChange:(UPAVStreamerStatus)status error:(NSError *)error;


@optional//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidJoinedOfUid:(NSUInteger)uid;
@optional//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidOfflineOfUid:(NSUInteger)uid reason:(NSUInteger)reason;
@optional//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidOccurWarning:(NSUInteger)warningCode;
@optional//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcDidOccurError:(NSUInteger)errorCode;
@optional//连麦回调
- (void)capturer:(UPAVCapturer *)capturer rtcConnectionDidLost:(id)rtcmanager;
@end



/*** rtc 远程用户进出房间回调接口 ***/


@interface UPAVCapturer : NSObject
/// 推流地址
@property (nonatomic, strong) NSString *outStreamPath;
@property (nonatomic) AVCaptureDevicePosition camaraPosition;
@property (nonatomic) AVCaptureVideoOrientation videoOrientation;
/// 采集等级
@property (nonatomic) UPAVCapturerPresetLevel capturerPresetLevel;
@property (nonatomic) CGSize capturerPresetLevelFrameCropSize;
/// 设置采集帧频
@property (nonatomic) int32_t fps;
/// 设置目标推流比特率
@property (nonatomic) int64_t bitrate;
/// 默认为 YES，即 UPAVCapturer start 之后会立即推流直播;
@property (nonatomic) BOOL streamingOn;
/// 闪光灯开关
@property (nonatomic) BOOL camaraTorchOn;
/// 美颜开关
@property (nonatomic) BOOL beautifyOn;
/// 美颜参数调整
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;

/// camera zoom scale default 1.0, between 1.0 ~ 3.0
@property (nonatomic, assign) CGFloat viewZoomScale;

@property (nonatomic, weak) id<UPAVCapturerDelegate> delegate;
@property (nonatomic, readonly) UPAVCapturerStatus capturerStatus;
@property (nonatomic, readonly) UPPushAVStreamStatus pushStreamStatus;
@property (nonatomic, strong, readonly) UPAVCapturerDashboard *dashboard;
/// 单音频推流，默认值 NO
@property (nonatomic) BOOL audioOnly;
/// 静音推流，默认值 NO
@property (nonatomic) BOOL audioMute;
/// 音量增益, 默认值 100 即原声音量
@property (nonatomic) int increaserRate;
/// 消除噪音
@property (nonatomic) BOOL deNoise;
/// 网络状态回调
@property (nonatomic, copy) NetworkStateBlock networkSateBlock;
/// 背景音url
@property (nonatomic, strong) NSString *backgroudMusicUrl;
/// 背景音开关
@property (nonatomic) BOOL backgroudMusicOn;
/// 背景音量默认值为 1， 即原声音量
@property (nonatomic, assign) Float32 backgroudMusicVolume;
/// 动态码率
@property (nonatomic, assign) BOOL openDynamicBitrate;

///手机进入后台之后，画面默认显示文字“后台推流”。
@property (nonatomic, strong) NSString *markTextForBackGroundPush;

+ (UPAVCapturer *)sharedInstance;
- (UIView *)previewWithFrame:(CGRect)frame contentMode:(UIViewContentMode)mode;
- (void)start;
- (void)stop;
- (void)stop:(BOOL)closeCamera;
- (void)switchCamera;
- (void)switchCamera:(AVCaptureDevicePosition)camPos;
//截图
- (void)shotPhoto:(void(^)(UIImage *photo))completion;
- (void)openCamera:(BOOL)openCamera;

/****** 连麦功能******/

- (void)rtcSetViewMode:(int)mode;//设置连麦视图模式，0:主播模式，1:观众模式。
- (void)rtcInitWithAppId:(NSString *)appid;//连麦模块初始化
- (int)rtcConnect:(NSString *)channelId;//连麦
- (void)rtcClose;//关闭
- (UIView *)rtcRemoteView0WithFrame:(CGRect)frame;//连麦窗口0
- (UIView *)rtcRemoteView1WithFrame:(CGRect)frame;//连麦窗口1


/**
 *  Mutes / Unmutes local audio.
 *
 *  @param mute true: Mutes the local audio. false: Unmutes the local audio.
 *
 *  @return 0 when executed successfully. return negative value if failed.
 */
- (int)rtcMuteLocalAudioStream:(BOOL)mute;


/**
 *  Mutes / Unmutes all remote audio.
 *
 *  @param mute true: Mutes all remote received audio. false: Unmutes all remote received audio.
 *
 *  @return 0 when executed successfully. return negative value if failed.
 */

- (int)rtcMuteAllRemoteAudioStreams:(BOOL)mute;

- (int)rtcMuteRemoteAudioStream:(NSUInteger)uid
                        mute:(BOOL)mute;


/// 设置水印和动态处理的 block
- (void)setWatermarkView:(UIView *)watermarkView Block:(WatermarkBlock)block;
/// 单个滤镜 用户可以使用自定义滤镜
- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter;
/// 单个滤镜 用户可以使用已定义好的滤镜名字
- (void)setFilterName:(UPCustomFilter)filterName;
/// 多个滤镜 用户可以使用自定义滤镜 filters : 自定义滤镜数组 按照先后顺序加入滤镜链
- (void)setFilters:(NSArray *)filters;
/// 多个滤镜 用户可以使用已定义滤镜 filterNames: 已定义滤镜的数组, 按照先后顺序加入滤镜链
- (void)setFilterNames:(NSArray *)filterNames;




@end

