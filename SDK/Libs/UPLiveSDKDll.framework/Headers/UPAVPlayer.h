//
//  UPAVPlayer.h
//  UPAVPlayerDemo
//
//  Created by DING FENG on 2/16/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UPLiveSDKConfig.h"



typedef NS_ENUM(NSInteger, UPAVPlayerStatus) {
    UPAVPlayerStatusIdle,
    UPAVPlayerStatusPlaying_buffering,
    UPAVPlayerStatusPlaying,
    UPAVPlayerStatusPause,
    UPAVPlayerStatusFailed
};

typedef NS_ENUM(NSInteger, UPAVStreamStatus) {
    UPAVStreamStatusIdle,
    UPAVStreamStatusConnecting,
    UPAVStreamStatusReady,
};


typedef void(^AudioBufferListReleaseBlock)(AudioBufferList *audioBufferListe);


@interface UPAVPlayerStreamInfo : NSObject
@property (nonatomic) float duration;
@property (nonatomic) BOOL canPause;
@property (nonatomic) BOOL canSeek;
@property (nonatomic, strong) NSDictionary *descriptionInfo;
@end

@interface UPAVPlayerDashboard: NSObject
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSString *serverIp;
@property (nonatomic, readonly) NSString *serverName;
@property (nonatomic, readonly) int cid;
@property (nonatomic, readonly) int pid;
@property (nonatomic, readonly) float fps;
@property (nonatomic, readonly) float bps;
@property (nonatomic, readonly) int vCachedFrames;
@property (nonatomic, readonly) int aCachedFrames;

@property (readonly, nonatomic) int decodedVFrameNum;//解码的视频包数量
@property (readonly, nonatomic) int decodedVKeyFrameNum;//解码的关键帧
@property (readonly, nonatomic) int decodedAFrameNum;//解码的音频包数量

@end


@class UPAVPlayer;

@protocol UPAVPlayerDelegate <NSObject>
//播放器状态
@optional
- (void)player:(UPAVPlayer *)player playerStatusDidChange:(UPAVPlayerStatus)playerStatus;
- (void)player:(UPAVPlayer *)player displayPositionDidChange:(float)position;
- (void)player:(UPAVPlayer *)player bufferingProgressDidChange:(float)progress;

@required
- (void)player:(UPAVPlayer *)player playerError:(NSError *)error;

//视频流状态
@optional
- (void)player:(UPAVPlayer *)player streamStatusDidChange:(UPAVStreamStatus)streamStatus;
- (void)player:(UPAVPlayer *)player streamInfoDidReceive:(UPAVPlayerStreamInfo *)streamInfo;

//字幕流回调
@optional
- (void)player:(UPAVPlayer *)player subtitle:(NSString *)text atPosition:(CGFloat)position shouldDisplay:(CGFloat)duration;


/*
 播放音频数据的回调.
 用途如：读取并播放音频文件，同时将音频数据送入混音器来当作背景音乐。
 */
@optional
- (void)player:(UPAVPlayer *)audioManager
willRenderBuffer:(AudioBufferList *)audioBufferList
     timeStamp:(const AudioTimeStamp *)inTimeStamp
        frames:(UInt32)inNumberFrames
          info:(AudioStreamBasicDescription)asbd
         block:(AudioBufferListReleaseBlock)release;

@end



@interface UPAVPlayer : NSObject

@property (nonatomic, strong, readonly) UIView *playView;
@property (nonatomic, strong, readonly) UPAVPlayerDashboard *dashboard;
@property (nonatomic, strong, readonly) UPAVPlayerStreamInfo *streamInfo;
@property (nonatomic, assign, readonly) UPAVPlayerStatus playerStatus;
@property (nonatomic, assign, readonly) UPAVStreamStatus streamStatus;

@property (nonatomic, assign) NSTimeInterval bufferingTime;//(0.1s -- 10s)
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat bright;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) int type;

@property (nonatomic, assign) NSTimeInterval timeoutForBuffering;//视频缓冲超时，默认 60s
@property (nonatomic, assign) NSTimeInterval timeoutForOpenFile;//打开文件超时，默认 10s
@property (nonatomic, assign) NSUInteger maxNumForReopenFile;//打开文件重试次数限制，默认 1 次，最大 10 次

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDictionary *headerDic;
@property (nonatomic, assign, readonly) float displayPosition;//视频播放到的时间点
@property (nonatomic, assign, readonly) float streamPosition;//视频流读取到的时间点
@property (nonatomic, assign, readonly) float audioPosition;//音频播放到的时间点

@property (nonatomic, weak) id<UPAVPlayerDelegate> delegate;
@property (nonatomic) BOOL lipSynchOn;//音画同步，默认值 YES
@property (nonatomic) int lipSynchMode;//0：音频向视频同步, 视频向标准时间轴同步；1：视频向音频同步，音频按照原采样率连续播放。 默认值 为 1。

- (instancetype)initWithURL:(NSString *)url;
- (void)setFrame:(CGRect)frame;
- (void)connect;
- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(CGFloat)position;

@end
