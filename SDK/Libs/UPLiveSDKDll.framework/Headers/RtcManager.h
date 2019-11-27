//
//  RtcManager.h
//  UPLiveSDKDemo
//
//  Created by DING FENG on 10/21/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>



@class RtcManager;

@protocol RtcManagerDataOutProtocol <NSObject>

/*** rtc 音视频输出接口 ***/
-(void)rtc:(RtcManager *)manager didReceiveAudioBuffer:(AudioBuffer)audioBuffer info:(AudioStreamBasicDescription)asbd;
-(void)rtc:(RtcManager *)manager didReceiveVideoBuffer:(CVPixelBufferRef)pixelBuffer;


/*** rtc 远程用户进出房间回调接口 ***/
-(void)rtc:(RtcManager *)manager didJoinedOfUid:(NSUInteger)uid;
-(void)rtc:(RtcManager *)manager didOfflineOfUid:(NSUInteger)uid reason:(NSUInteger)reason;


/*** rtc 错误及警告***/
- (void)rtc:(RtcManager *)manager didOccurWarning:(NSUInteger)warningCode;
- (void)rtc:(RtcManager *)manager didOccurError:(NSUInteger)errorCode;

/*** rtc 错误ConnectionDidLost***/
- (void)rtcConnectionDidLost:(RtcManager *)manager;

@end

@interface RtcManager : NSObject

+ (RtcManager *)sharedInstance;


/*** 初始设置 ***/
- (void)setAppId:(NSString *)appid;//设置 AppId


- (bool)setInputVideoWidth:(int)w height:(int)h;//设置视频尺寸 1280x720/640x480/480x360/640x360
- (void)setViewMode:(int)mode;//0:主播模式，1:观众连麦模式


/*** 连接与关闭 ***/
- (void)startWithRtcChannel:(NSString *)channelId;//开启
- (void)startWithRtcChannel:(NSString *)channelId UID:(NSInteger) uid;
/// 自定义长宽和码率
- (void)startWithRtcChannel:(NSString *)channelId UID:(NSInteger)uid Width:(int)width Heigth:(int)heigth FrameRate:(int)frameRate Bitrate:(int)bitrate;



- (void)stop;//结束


/*** rtc视频输入接口*/
- (void)deliverVideoFrame:(CVPixelBufferRef)pixelBuffer;

/*** rtc视频输入接口, 适配不同格式增加 format 字段
 format: 1: I420 2: ARGB 3: NV21 4: RGBA */
- (void)deliverVideoFrame:(CVPixelBufferRef)pixelBuffer Format:(int)format;

/*** log level
 • 1: INFO
 • 2: WARNING
 • 4: ERROR
 • 8: FATAL
 */
- (void)setLogLevel:(int)level;


@property (strong, nonatomic) UIView *remoteView0;//小窗视图0，可以设置frame，可以用 hidden 控制显示
@property (strong, nonatomic) UIView *remoteView1;//小窗视图1，可以设置frame，可以用 hidden 控制显示

@property (nonatomic, weak) id<RtcManagerDataOutProtocol> delegate;//数据回调
@property (assign) BOOL channelConnected;//连接状态
@property (nonatomic, strong, readonly) NSMutableDictionary *onlineUids;//在线 user


/**
 *  Mutes / Unmutes local audio.
 *
 *  @param mute true: Mutes the local audio. false: Unmutes the local audio.
 *
 *  @return 0 when executed successfully. return negative value if failed.
 */
- (int)muteLocalAudioStream:(BOOL)mute;

- (int)muteLocalVideoStream:(BOOL)mute;


/**
 *  Mutes / Unmutes all remote audio.
 *
 *  @param mute true: Mutes all remote received audio. false: Unmutes all remote received audio.
 *
 *  @return 0 when executed successfully. return negative value if failed.
 */

- (int)muteAllRemoteAudioStreams:(BOOL)mute;

- (int)muteRemoteAudioStream:(NSUInteger)uid
                        mute:(BOOL)mute;

@end
