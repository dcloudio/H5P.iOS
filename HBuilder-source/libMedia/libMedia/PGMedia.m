//
//  PGMedia.m
//  Pandora
//
//  Created by lxz on 13-3-6.
//
//

#import "PGMedia.h"
#import "PTPathUtil.h"
#import "PDRCoreWindowManager.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#include <objc/message.h>
#import "PDRCommonString.h"
#import "VoiceConverter.h"
#import "PGObject.h"
#import "lame.h"
//#import "PTLog.h"
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPRemoteCommandCenter.h>
#import <MediaPlayer/MPRemoteCommand.h>

typedef enum
{
    EDHA_SUPPORT_WAV,
    EDHA_SUPPORT_MP3,
    EDHA_SUPPORT_AAC,
    EDHA_SUPPORT_AMR
}ESUPPORTFORMAT;

static NSString* const kPGAudioRecorderKey = @"Recorder";

static NSString* const kPGAudioRecorderParams_aac = @"aac";
static NSString* const kPGAudioRecorderParams_amr = @"amr";
static NSString* const kPGAudioRecorderParams_mp3 = @"mp3";
static NSString* const kPGAudioRecorderParams_wav = @"wav";
static NSString* const kPGAudioRecorderKey_cbid   = @"a";
static NSString* const kPGAudioRecorderKey_outFile   = @"b";
static NSString* const kPGAudioRecorderKey_recordFile   = @"c";
static NSString* const kPGAudioRecorderKey_isamr   = @"d";
static NSString* const kPGAudioRecorderKeyUUID   = @"e";

// 播放器属性
static NSString* const kPGAudioPlayerKey_src = @"src";
static NSString* const kPGAudioPlayerKey_startTime = @"startTime";
static NSString* const kPGAudioPlayerKey_autoplay = @"autoplay";
static NSString* const kPGAudioPlayerKey_loop = @"loop";
static NSString* const kPGAudioPlayerKey_volume = @"volume";
static NSString* const kPGAudioPlayerKey_backgroundControl = @"backgroundControl";


// 歌曲信息
static NSString* const kPGPlayerItemInfoKey_title = @"title";
static NSString* const kPGPlayerItemInfoKey_epname = @"epname";
static NSString* const kPGPlayerItemInfoKey_singer = @"singer";
static NSString* const kPGPlayerItemInfoKey_coverImgUrl = @"coverImgUrl";
//static NSString* const kPGPlayerItemInfoKey_webUrl = @"webUrl";
//static NSString* const kPGPlayerItemInfoKey_protocol = @"protocol";

// 播放器事件
static NSString* const kPGPlayerItemKeyPathStatus = @"status";
static NSString* const kPGPlayerItemKeyPathLoadedTimeRanges = @"loadedTimeRanges";
static NSString* const kPGPlayerItemKeyPathPlaybackBufferEmpty = @"playbackBufferEmpty";
static NSString* const kPGPlayerItemKeyPathPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";

// js 监听事件
static NSString* const kPGPlayerEventOnCanplay = @"canplay";
static NSString* const kPGPlayerEventOnPlay = @"play";
static NSString* const kPGPlayerEventOnPause = @"pause";
static NSString* const kPGPlayerEventOnStop = @"stop";
static NSString* const kPGPlayerEventOnEnded = @"ended";
static NSString* const kPGPlayerEventOnError = @"error";
static NSString* const kPGPlayerEventOnWaiting = @"waiting";
static NSString* const kPGPlayerEventOnSeeking = @"seeking";
static NSString* const kPGPlayerEventOnSeeked = @"seeked";
static NSString* const kPGPlayerEventOnPrev = @"prev";
static NSString* const kPGPlayerEventOnNext = @"next";

//@class PGAudio;
@interface PGPlayerItemInfo : PGObject

@property (nonatomic, copy) NSString *title;            /**< 标题 */
@property (nonatomic, copy) NSString *epname;           /**< 专辑名 */
@property (nonatomic, copy) NSString *singer;           /**< 歌手名 */
@property (nonatomic, copy) NSString *coverImgUrl;      /**< 封面 */
@property (nonatomic, weak) PGAudio *delegate;

- (instancetype)initWithInfo:(NSDictionary *)info;

@end

@implementation PGPlayerItemInfo

- (instancetype)initWithInfo:(NSDictionary *)info {
    if (self = [super init]) {
        [self parseInfo:info];
    }
    return self;
}

- (void)parseInfo:(NSDictionary *)info {
    
    if (info[kPGPlayerItemInfoKey_title]) {
        self.title = info[kPGPlayerItemInfoKey_title];
    }
    
    if (info[kPGPlayerItemInfoKey_epname]) {
        self.epname = info[kPGPlayerItemInfoKey_epname];
    }
    
    if (info[kPGPlayerItemInfoKey_singer]) {
        self.singer = info[kPGPlayerItemInfoKey_singer];
    }
    
    if (info[kPGPlayerItemInfoKey_coverImgUrl]) {
        self.coverImgUrl = info[kPGPlayerItemInfoKey_coverImgUrl];
    }
}


/**
 获取playerCenter音频信息
 
 @param handelBlock block回调
 */
- (void)getNowPlayingInfo:(void(^)(NSMutableDictionary *info))handelBlock {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    if (self.title) {
        [info setValue:self.title forKey:MPMediaItemPropertyTitle];
    }
    
    if (self.epname) {
        [info setValue:self.epname forKey:MPMediaItemPropertyAlbumTitle];
    }
    
    if (self.singer) {
        [info setValue:self.singer forKey:MPMediaItemPropertyArtist];
    }
    
    if (self.coverImgUrl) {
        
        if ([self.coverImgUrl hasPrefix:@"http"]) {
            NSURL *imgURL = [NSURL URLWithString:self.coverImgUrl];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:imgURL];
                UIImage *image = [UIImage imageWithData:data];
                
                if (image) {
                    MPMediaItemArtwork *itemArtwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                    [info setValue:itemArtwork forKey:MPMediaItemPropertyArtwork];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    handelBlock(info);
                });
            });
        } else {
            NSString *imgFilePath = [PTPathUtil h5Path2SysPath:self.coverImgUrl basePath:self.delegate.JSFrameContext.baseURL context:self.delegate.appContext];
            if (imgFilePath && [[NSFileManager defaultManager] fileExistsAtPath:imgFilePath]) {
                UIImage *image = [UIImage imageWithContentsOfFile:imgFilePath];
                if (image) {
                    MPMediaItemArtwork *itemArtwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                    [info setValue:itemArtwork forKey:MPMediaItemPropertyArtwork];
                }
                
                handelBlock(info);
            }
        }
    } else {
        handelBlock(info);
    }
}

@end

@interface PGPlayerContext : PGObject
@property(nonatomic,assign)BOOL ready;  /**< 是否准备好播放 */
@property(nonatomic, assign)BOOL isDiscard;
@property(nonatomic, assign)BOOL isNeedPlay; /**< 是否需要开始播放，自动播放 */
@property(nonatomic, assign)BOOL playing; /**< 播放中 */
@property(nonatomic, assign)int loadError;
@property(nonatomic, retain)NSString *playPath;
@property(nonatomic, retain)NSString *jsCallbackId;
@property(nonatomic, retain)AVPlayer *player;
@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) BOOL autoplay; /**< 是否自动播放 */
@property (nonatomic, assign) BOOL loop;  /**< 是否循环播放 */
@property (nonatomic, assign) NSInteger startTime;  /**< 开始播放时间 */
@property (nonatomic, assign) NSTimeInterval buffered; /**< 已缓冲时间 */
@property (nonatomic, strong) NSMutableDictionary *m_listenerList; /**< js监听事件 */
@property (nonatomic, assign) BOOL backgroundControl;   /**< 锁屏控制页 */
@property (nonatomic, strong) PGPlayerItemInfo *itemInfo;
@end

@implementation PGPlayerContext
@synthesize ready;

- (void)dealloc {
    
    if (self.player) {
        [self.player pause];
        // 移除监听事件
        [self removePlayerObservers];
        self.player = nil;
        self.delegate = nil;
    }
    
    [_m_listenerList removeAllObjects];
    _m_listenerList = nil;
    
    self.jsCallbackId = nil;
    self.playPath = nil;
}

- (NSMutableDictionary *)m_listenerList {
    if (!_m_listenerList) {
        _m_listenerList = [[NSMutableDictionary alloc] init];
    }
    return _m_listenerList;
}


- (BOOL)isCacheFinish {
    
    if (!self.player.currentItem) {
        return NO;
    }

    return self.buffered >= CMTimeGetSeconds(self.player.currentItem.duration) - 5;
}

/**
 设置playingCenter 信息
 rate == 0.0 表示暂停状态
 */
- (void)setPlayingCenterInfoWithRate:(float)rate {
    [self setPlayingCenterInfoWithRate:rate delay:YES];
}

- (void)setPlayingCenterInfoWithRate:(NSInteger)rate delay:(BOOL)delay {
    [self setPlayingCenterInfoWithRate:rate delay:delay newInfo:NO];
}

- (void)setPlayingCenterInfoWithRate:(NSInteger)rate delay:(BOOL)delay newInfo:(BOOL)newInfo {
    if (!self.backgroundControl) {
        return;
    }
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    if (newInfo) {
        [self.itemInfo getNowPlayingInfo:^(NSMutableDictionary *info) {
            
            if (delay) {
                // 延时一秒设置，不然同步时间进度会有问题
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [info setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(self.player.currentItem.duration)] forKey:MPMediaItemPropertyPlaybackDuration];
                    [info setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(self.player.currentItem.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                    [info setValue:[NSNumber numberWithInteger:rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
                });
            } else {
                [info setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(self.player.currentItem.duration)] forKey:MPMediaItemPropertyPlaybackDuration];
                [info setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(self.player.currentItem.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                [info setValue:[NSNumber numberWithInteger:rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
            }
        }];
    } else {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
        [info setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(self.player.currentItem.duration)] forKey:MPMediaItemPropertyPlaybackDuration];
        [info setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(self.player.currentItem.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [info setValue:[NSNumber numberWithInteger:rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
    }
}


/**
 清除 PlayingCenterInfo
 */
- (void)clearPlayingCenterInfo {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
}

/**
 监听播放器相关事件
 */
- (void)addPlayerObservers {
    [self.player.currentItem addObserver:self.delegate forKeyPath:kPGPlayerItemKeyPathStatus options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self.delegate forKeyPath:kPGPlayerItemKeyPathLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self.delegate forKeyPath:kPGPlayerItemKeyPathPlaybackBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self.delegate forKeyPath:kPGPlayerItemKeyPathPlaybackLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.delegate selector:NSSelectorFromString(@"playbackFinished:") name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}


/**
 移除播放器监听事件
 */
- (void)removePlayerObservers {
    [self removePlayerObservers:nil];
}
- (void)removePlayerObservers:(id)target {
    if (!self.player.currentItem || (!target && !self.delegate)) {
        return;
    }
    
    [self.player pause];
    [self.player.currentItem removeObserver:target ?: self.delegate forKeyPath:kPGPlayerItemKeyPathStatus];
    [self.player.currentItem removeObserver:target ?: self.delegate forKeyPath:kPGPlayerItemKeyPathLoadedTimeRanges];
    [self.player.currentItem removeObserver:target ?: self.delegate forKeyPath:kPGPlayerItemKeyPathPlaybackBufferEmpty];
    [self.player.currentItem removeObserver:target ?: self.delegate forKeyPath:kPGPlayerItemKeyPathPlaybackLikelyToKeepUp];
    [[NSNotificationCenter defaultCenter] removeObserver:target ?: self.delegate name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

@end

@interface PGAudio ()

@property (nonatomic, assign) BOOL conventToMp3Finish;

@end

@implementation PGAudio

- (void)onDestroy {
    if (isConfigRemoteCommandCenter) {
        [self clearRemoteCommandCenter];
    }
}

static BOOL isConfigRemoteCommandCenter = NO;

/**
 清除控制中心
 */
- (void)clearRemoteCommandCenter {
    
    if (!isConfigRemoteCommandCenter) {
        return;
    }
    
    isConfigRemoteCommandCenter = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        // 播放事件
        MPRemoteCommand *playCommand = remoteCommandCenter.playCommand;
        playCommand.enabled = NO;
        [playCommand removeTarget:self];
        
        // 暂停事件
        MPRemoteCommand *pauseCommand = remoteCommandCenter.pauseCommand;
        pauseCommand.enabled = NO;
        [pauseCommand removeTarget:self];
        
        // 下一曲
        MPRemoteCommand *nextTrack = remoteCommandCenter.nextTrackCommand;
        nextTrack.enabled = NO;
        [nextTrack removeTarget:self];
        
        // 上一曲
        MPRemoteCommand *previousTrack = remoteCommandCenter.previousTrackCommand;
        previousTrack.enabled = NO;
        [previousTrack removeTarget:self];
        
        // 线控
        MPRemoteCommand *togglePlayPause = remoteCommandCenter.togglePlayPauseCommand;
        togglePlayPause.enabled = NO;
        [togglePlayPause removeTarget:self];
    });
}

/**
 配置控制中心事件
 */
- (void)configRemoteCommandCenterWithPlayerContext:(PGPlayerContext *)playerContext {
    
    if (isConfigRemoteCommandCenter) {
        return;
    }
    
    isConfigRemoteCommandCenter = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        // 播放事件
        MPRemoteCommand *playCommand = remoteCommandCenter.playCommand;
        playCommand.enabled = YES;
        [playCommand addTarget:self action:@selector(remoteCommandPlay:)];
        // 暂停事件
        MPRemoteCommand *pauseCommand = remoteCommandCenter.pauseCommand;
        pauseCommand.enabled = YES;
        [pauseCommand addTarget:self action:@selector(remoteCommandPause:)];
        // 下一曲
        MPRemoteCommand *nextTrack = remoteCommandCenter.nextTrackCommand;
        nextTrack.enabled = YES;
        [nextTrack addTarget:self action:@selector(remoteCommandNextTrack:)];
        // 上一曲
        MPRemoteCommand *previousTrack = remoteCommandCenter.previousTrackCommand;
        previousTrack.enabled = YES;
        [previousTrack addTarget:self action:@selector(remoteCommandPreviousTrack:)];
        // 线控
        MPRemoteCommand *togglePlayPause = remoteCommandCenter.togglePlayPauseCommand;
        togglePlayPause.enabled = YES;
        [togglePlayPause addTarget:self action:@selector(remoteCommandTogglePlayPause:)];
        
        [playerContext setPlayingCenterInfoWithRate:[playerContext isCacheFinish] ? 1 : 0 delay:NO newInfo:YES];
    });
}

- (MPRemoteCommandHandlerStatus)remoteCommandPlay:(MPRemoteCommandEvent *)event {
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        pPlayerContext.isNeedPlay = YES;
        [pPlayerContext.player play];
        [pPlayerContext setPlayingCenterInfoWithRate:[pPlayerContext isCacheFinish] ? 1 : 0 delay:NO];
        [self sendEventListener:kPGPlayerEventOnPlay message:nil playerContext:pPlayerContext];
    }];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remoteCommandPause:(MPRemoteCommandEvent *)event {
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        pPlayerContext.isNeedPlay = NO;
        pPlayerContext.playing = NO;
        [pPlayerContext.player pause];
        [pPlayerContext setPlayingCenterInfoWithRate:0 delay:NO];
        [self sendEventListener:kPGPlayerEventOnPause message:nil playerContext:pPlayerContext];
    }];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remoteCommandNextTrack:(MPRemoteCommandEvent *)event {
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        [self sendEventListener:kPGPlayerEventOnNext message:nil playerContext:pPlayerContext];
    }];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remoteCommandPreviousTrack:(MPRemoteCommandEvent *)event {
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        [self sendEventListener:kPGPlayerEventOnPrev message:nil playerContext:pPlayerContext];
    }];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)remoteCommandTogglePlayPause:(MPRemoteCommandEvent *)event {
    __weak __typeof(self)weakSelf = self;
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        // 线控如果在播放 调用暂停 反之调用播放
        if (pPlayerContext.isNeedPlay) {
            [weakSelf remoteCommandPause:nil];
        } else {
            [weakSelf remoteCommandPlay:nil];
        }
    }];
    return MPRemoteCommandHandlerStatusSuccess;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (BOOL)RecorderExecMethod:(PGMethod*)pMethod
{
    BOOL retVal = NO;
    NSString* methodName = [pMethod.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"Recorder_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector]) {
        ((BOOL (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pMethod.arguments objectAtIndex:1]);
        retVal = YES;
    }
    return retVal;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (BOOL)AudioExecMethod:(PGMethod*)pMethod
{
    BOOL retVal = NO;
    NSString* methodName = [pMethod.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"Player_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector]) {
        ((BOOL (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pMethod.arguments objectAtIndex:1]);
        retVal = YES;
    }
    return retVal;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (NSData*)AudioSyncExecMethod:(PGMethod*)pMethod
{
    NSString* methodName = [pMethod.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"Player_Sync_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector]) {
        return ((id (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pMethod.arguments objectAtIndex:1]);
    }
    return nil;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Recorder_record:(NSArray*)pMethod
{
    BOOL bSucess = NO;
    
    NSString* pRecorderFileName = nil;
    NSString* pOutFileName = nil;
    int       numberofChannels = 1;
    NSString* pOptionFileName = @"_doc/";
    CGFloat nSamplateRate = 8000.0f;
    ESUPPORTFORMAT eRecFormat = EDHA_SUPPORT_WAV;
    NSString* fileType = kPGAudioRecorderParams_wav;
    
    NSString* pRecorderUdid = [pMethod objectAtIndex:0];
    NSString* pCallBackID = [pMethod objectAtIndex:1];
    NSDictionary* pRecOption = [pMethod objectAtIndex:2];
    
    
    // 权限判断
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:{
            //没有询问是否开启麦克风
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (!granted) {
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:2 withMessage:@"未授权"];
                    [self toCallback:pCallBackID withReslut:[result toJSONString]];
                    return;
                }
            }];
            break;
        }
        case AVAuthorizationStatusRestricted:{
            //未授权，家长限制
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:1 withMessage:@"未授权，访问限制"];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
            return;
        }
        case AVAuthorizationStatusDenied:{
            //未授权
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:2 withMessage:@"未授权"];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
            return;
        }
        
        case AVAuthorizationStatusAuthorized:
        //已授权
            break;
        default:
            break;
    }
    
    
    if (m_pRecorderDic == nil) {
        m_pRecorderDic = [[NSMutableDictionary alloc] init];
    }
    
    if ( pRecOption && [pRecOption isKindOfClass:[NSDictionary class]]) {
        // 获取文件名
        NSString *fileNameValue = [pRecOption objectForKey:@"filename"];
        if ( [fileNameValue isKindOfClass:[NSString class]] ) {
            pOptionFileName = fileNameValue;
        }
        
        // 获取采样率
        NSNumber *sampValue = [pRecOption objectForKey:@"samplerate"];
        if ( [sampValue isKindOfClass:[NSString class]]
            || [sampValue isKindOfClass:[NSNumber class]]) {
            nSamplateRate = [sampValue floatValue];
        }
        
        NSString *fileTypeJSP = [pRecOption objectForKey:@"format"];
        if ( [fileTypeJSP isKindOfClass:[NSString class]] ) {
            if ( NSOrderedSame == [kPGAudioRecorderParams_aac caseInsensitiveCompare:fileTypeJSP] ) {
                eRecFormat = EDHA_SUPPORT_AAC;
                fileType = kPGAudioRecorderParams_aac;
            } else if (  NSOrderedSame == [kPGAudioRecorderParams_amr caseInsensitiveCompare:fileTypeJSP] ) {
                eRecFormat = EDHA_SUPPORT_AMR;
                fileType = kPGAudioRecorderParams_amr;
            } else if (  NSOrderedSame == [kPGAudioRecorderParams_mp3 caseInsensitiveCompare:fileTypeJSP] ) {
                eRecFormat = EDHA_SUPPORT_MP3;
                fileType = kPGAudioRecorderParams_mp3;
            }
        }
        
        // 声道数，默认是1 mp3格式的必须是2
        NSString* channels = [pRecOption objectForKey:@"channels"];
        if([channels isKindOfClass:[NSString class]] && [channels isEqualToString:@"stereo"]){
            numberofChannels = 2;
        }
    }
    
    pOutFileName = [PTPathUtil absolutePath:pOptionFileName
                              suggestedPath:nil
                          suggestedFilename:nil
                                     prefix:@"Recorder_"
                                     suffix:fileType];
    
    if ( [PTPathUtil allowsWritePath:pOutFileName withContext:self.appContext] ) {
        NSMutableDictionary* FormatDic = [NSMutableDictionary dictionary];
        if ( EDHA_SUPPORT_AMR == eRecFormat  ) {
            pRecorderFileName = [pOutFileName stringByAppendingPathExtension:@"wav"];
        } else if ( EDHA_SUPPORT_MP3 == eRecFormat ) {
            pRecorderFileName = [pOutFileName stringByAppendingPathExtension:@"caf"];
        } else {
            pRecorderFileName = pOutFileName;
        }
        [FormatDic setObject:[NSNumber numberWithFloat:nSamplateRate] forKey: AVSampleRateKey];
        [FormatDic setObject:[NSNumber numberWithInt:numberofChannels] forKey:AVNumberOfChannelsKey];
        switch (eRecFormat){
            case EDHA_SUPPORT_AAC: {
                [FormatDic setObject:[NSNumber numberWithInt: kAudioFormatMPEG4AAC] forKey: AVFormatIDKey];
                //[FormatDic setObject:[NSNumber numberWithInt:44100] forKey:AVEncoderBitRateKey];
                [FormatDic setObject:[NSNumber numberWithInt: AVAudioQualityHigh] forKey: AVEncoderAudioQualityKey];
            }
            break;
            case EDHA_SUPPORT_WAV:
            break;
            case EDHA_SUPPORT_MP3:
            [FormatDic setObject:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
            case EDHA_SUPPORT_AMR: {
                [FormatDic setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
                [FormatDic setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
                [FormatDic setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
                [FormatDic setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
                
            }
            break;
            default:
            break;
        }
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        NSURL* pURL = [NSURL fileURLWithPath:pRecorderFileName];
        NSError *error = nil;
        AVAudioRecorder* pAURecorder = [[AVAudioRecorder alloc] initWithURL:pURL settings:FormatDic error:&error];
        if ( pAURecorder ) {
            [pAURecorder prepareToRecord];
            if ( [pAURecorder record] ) {
                bSucess = YES;
                [FormatDic removeAllObjects];
                [FormatDic setObject:fileType forKey:@"format"];
                [FormatDic setObject:pAURecorder forKey:kPGAudioRecorderKey];
                [FormatDic setObject:pCallBackID forKey:kPGAudioRecorderKey_cbid];
                [FormatDic setObject:pRecorderFileName forKey:kPGAudioRecorderKey_recordFile];
                [FormatDic setObject:@(nSamplateRate) forKey:AVSampleRateKey];
                [FormatDic setObject:pOutFileName forKey:kPGAudioRecorderKey_outFile];
                [FormatDic setObject:pRecorderUdid forKey:kPGAudioRecorderKeyUUID];
                if ( eRecFormat == EDHA_SUPPORT_AMR  ) {
                    // [VoiceConverter changeStu];
                    [FormatDic setObject:[NSNumber numberWithBool:YES] forKey:kPGAudioRecorderKey_isamr];
                } else {
                    [FormatDic setObject:[NSNumber numberWithBool:NO] forKey:kPGAudioRecorderKey_isamr];
                }
                [m_pRecorderDic setObject:FormatDic forKey:pRecorderUdid];
                
                if ( eRecFormat == EDHA_SUPPORT_MP3 ) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self conventToMp3:FormatDic];
                    });
                }
                
                return;
            }
            
        }
        [FormatDic removeAllObjects];
    }
    
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:1 withMessage:@"参数错误"];
    [self toCallback:pCallBackID withReslut:[result toJSONString]];
}

- (void)conventToMp3:(NSDictionary*)dict {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            NSString *recordFilePath = [dict objectForKey:kPGAudioRecorderKey_recordFile];
            NSString *mp3FilePath = [dict objectForKey:kPGAudioRecorderKey_outFile];
            NSNumber *sampleRate = [dict objectForKey:AVSampleRateKey];
            NSString *UUID = [dict objectForKey:kPGAudioRecorderKeyUUID];
            int read, write;
            
            FILE *pcm = fopen([recordFilePath cStringUsingEncoding:NSASCIIStringEncoding], "rb");
            FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:NSASCIIStringEncoding], "wb+");
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE * 2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_in_samplerate(lame, [sampleRate intValue]);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            long curpos;
            BOOL isSkipPCMHeader = NO;
            self.conventToMp3Finish = NO;
            
            do {
                curpos = ftell(pcm);
                long startPos = ftell(pcm);
                fseek(pcm, 0, SEEK_END);
                long endPos = ftell(pcm);
                long length = endPos - startPos;
                fseek(pcm, curpos, SEEK_SET);
                
                if (length > PCM_SIZE * 2 * sizeof(short int)) {
                    
                    if (!isSkipPCMHeader) {
                        //Uump audio file header, If you do not skip file header
                        //you will heard some noise at the beginning!!!
                        fseek(pcm, 4 * 1024, SEEK_CUR);
                        isSkipPCMHeader = YES;
                        //PDR_LOG_INFO(@"skip pcm file header !!!!!!!!!!");
                    }
                    
                    read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                    fwrite(mp3_buffer, write, 1, mp3);
                    //PDR_LOG_INFO(@"read %d bytes", write);
                }
                // 停止录音时 length 不够 PCM_SIZE * 2 导致漏转的问题
                else if (![self->m_pRecorderDic objectForKey:UUID] && length) {
                    read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                    if (read == 0) {
                        write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                    } else {
                        write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                    }
                    fwrite(mp3_buffer, write, 1, mp3);
                    self.conventToMp3Finish = YES;
                }
                else {
                    [NSThread sleepForTimeInterval:0.05];
                    //  PDR_LOG_INFO(@"sleep");
                }//
                
            } while (!self.conventToMp3Finish);
            
            read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            
            //  PDR_LOG_INFO(@"read %d bytes and flush to mp3 file", write);
            lame_mp3_tags_fid(lame, mp3);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
            [[NSFileManager defaultManager] removeItemAtPath:recordFilePath error:nil];
        }
        @catch (NSException *exception) {
            // PDR_LOG_INFO(@"%@", [exception description]);
        }
        @finally {
            
        }
    });
}

//
//- (void)wavToAmrBtnPressed:(NSArray*)originWav{
//    if ([originWav count] == 2){
//        //转格式
//       // [VoiceConverter wavToAmr:[originWav objectAtIndex:0] amrSavePath:[originWav objectAtIndex:1]];
//    }
//}

/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Recorder_pause:(NSArray*)pMethod
{
    return;
    NSString* pRecorderUUID = [pMethod objectAtIndex:0];
    AVAudioRecorder* pRecorder = [m_pRecorderDic objectForKey:pRecorderUUID];
    if (pRecorder)
    {
        [pRecorder pause];
    }
}
/*
 *------------------------------------------------------------------
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)Recorder_stop:(NSArray*)pMethod
{
    NSString* pRecorderUUID = [pMethod objectAtIndex:0];
    if (pRecorderUUID == NULL) {
        return;
    }
    NSMutableDictionary* pDic = [m_pRecorderDic objectForKey:pRecorderUUID];
    if ( pDic ) {
        NSString* pCallBackID = [pDic objectForKey:kPGAudioRecorderKey_cbid];
        NSString* pFileName   = [pDic objectForKey:kPGAudioRecorderKey_outFile];
        NSString* pRecodeFileName   = [pDic objectForKey:kPGAudioRecorderKey_recordFile];
        NSNumber* isAmr = [pDic objectForKey:kPGAudioRecorderKey_isamr];
        NSString* fileType = [pDic objectForKey:@"format"];
        AVAudioRecorder* pRecorder = [pDic objectForKey:kPGAudioRecorderKey];
        if (pRecorder){
            [pRecorder stop];
        }
        if ( [isAmr boolValue] ) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [VoiceConverter wavToAmr:pRecodeFileName amrSavePath:pFileName];
                [[NSFileManager defaultManager] removeItemAtPath:pRecodeFileName error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString * r =[PTPathUtil relativePath:pFileName withContext:self.appContext];
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:r];
                    [self toCallback:pCallBackID withReslut:[result toJSONString]];
                    [self->m_pRecorderDic removeObjectForKey:pRecorderUUID];
                });
            });
        } else if ([fileType isEqualToString:kPGAudioRecorderParams_mp3]) {
            [m_pRecorderDic removeObjectForKey:pRecorderUUID];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                // 转码未完成等待
                while (!self.conventToMp3Finish) {
                    //                    NSLog(@"转码未完成等待");
                    [NSThread sleepForTimeInterval:0.1];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString * r =[PTPathUtil relativePath:pFileName withContext:self.appContext];
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:r];
                    [self toCallback:pCallBackID withReslut:[result toJSONString]];
                });
                
            });
            
        } else {
            NSString * r =[PTPathUtil relativePath:pFileName withContext:self.appContext];
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:r];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
            [self->m_pRecorderDic removeObjectForKey:pRecorderUUID];
        }
    }
    
    // 录音列表空了就释放
    if ([m_pRecorderDic count] == 0) {
        //  [m_pRecorderDic release];
        m_pRecorderDic = nil;
    }
}

- (void)closeRecorder {
    NSArray *recorders = [m_pRecorderDic allValues];
    for ( NSDictionary *dict in recorders ) {
        AVAudioRecorder* pRecorder = [dict objectForKey:kPGAudioRecorderKey];
        if ( pRecorder
            && [pRecorder isKindOfClass:[AVAudioRecorder class]]
            && pRecorder.recording ) {
            [pRecorder stop];
        }
    }
    [m_pRecorderDic removeAllObjects];
    // [m_pRecorderDic release];
    m_pRecorderDic = nil;
}

#pragma mark Player
- (void)getPlayURLWithPlayerContext:(PGPlayerContext *)pPlayerContext handleBlock:(void(^)(NSURL *playURL))block{
    NSString *pMusicPath = pPlayerContext.playPath;
    
    if ([pMusicPath hasPrefix:@"http"]) {
        block([NSURL URLWithString:pMusicPath]);
        return;
    }
    
    pMusicPath = [PTPathUtil h5Path2SysPath:pMusicPath basePath:self.JSFrameContext.baseURL context:self.appContext]; //[PTPathUtil absolutePath:pMusicPath withContext:self.appContext];
    if ( nil == pMusicPath ) {
        pPlayerContext.loadError = PGPluginErrorIO;
        // onError
        [self sendErrorEventListenerWithCode:PGPluginErrorIO playerContext:pPlayerContext];
        block(nil);
        return;
    }
    
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:pMusicPath]  ) {
        pPlayerContext.loadError = PGPluginErrorFileNotFound;
        // onError
        [self sendErrorEventListenerWithCode:PGPluginErrorFileNotFound playerContext:pPlayerContext];
        block(nil);
        return;
    };
    
    NSString *ext = [pMusicPath pathExtension];
    if ( ext && NSOrderedSame == [@"amr" caseInsensitiveCompare:ext] ) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *pPlayPath = pMusicPath;
            NSString *toPath = [PTPathUtil uniqueFileNameWithPrefix:pPlayPath.lastPathComponent.stringByDeletingPathExtension
                                                                ext:@"wav"
                                                             inPath:[PTPathUtil runtimeTmpPath]
                                                             create:YES];
            if ( ![VoiceConverter amrToWav:pPlayPath wavSavePath:toPath] ){
                [self sendErrorEventListenerWithCode:PGPluginErrorIO playerContext:pPlayerContext];
                block(nil);
                return ;
            }
            pPlayPath = toPath;
            if ( pPlayerContext.isDiscard ) {
                [self sendErrorEventListenerWithCode:PGPluginErrorIO playerContext:pPlayerContext];
                block(nil);
                return;
            }
            // 找到文件的绝对路径之后转化成URl
            NSURL* pFileUrl = [NSURL fileURLWithPath:pPlayPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(pFileUrl);
            });
        });
    } else {
        // 找到文件的绝对路径之后转化成URl
        NSURL* pFileUrl = [NSURL fileURLWithPath:pMusicPath];
        block(pFileUrl);
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    __block PGPlayerContext *currentPlayerContext = nil;
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        if (pPlayerContext.player.currentItem == playerItem) {
            currentPlayerContext = pPlayerContext;
            *stop = YES;
        }
    }];
    
    // 播放器的状态
    if ([keyPath isEqualToString:kPGPlayerItemKeyPathStatus]) {
        //status
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        switch (status) {
            case AVPlayerItemStatusUnknown:
            {
                [self sendErrorEventListenerWithCode:PGPluginErrorUnknown playerContext:currentPlayerContext];
                [currentPlayerContext setPlayingCenterInfoWithRate:0];
            }
            break;
            case AVPlayerItemStatusFailed:
            {
                NSString *domain = playerItem.error.domain;
                // 网络错误
                if ([domain isEqualToString:NSURLErrorDomain]) {
                    [self toErrorCallback:currentPlayerContext.jsCallbackId withCode:PGPluginErrorNet];
                    [self sendErrorEventListenerWithCode:PGPluginErrorNet playerContext:currentPlayerContext];
                }
                // 格式错误 报io错误
                else if ([domain isEqualToString:AVFoundationErrorDomain]) {
                    [self toErrorCallback:currentPlayerContext.jsCallbackId withCode:PGPluginErrorIO];
                    [self sendErrorEventListenerWithCode:PGPluginErrorIO playerContext:currentPlayerContext];
                }
                // 未知
                else {
                    [self toErrorCallback:currentPlayerContext.jsCallbackId withCode:PGPluginErrorUnknown];
                    [self sendErrorEventListenerWithCode:PGPluginErrorUnknown playerContext:currentPlayerContext];
                }
                
                [currentPlayerContext setPlayingCenterInfoWithRate:0];
            }
            break;
            case AVPlayerItemStatusReadyToPlay:
            {
                //                                PDR_LOG_INFO(@"准备好播放了");
                if (currentPlayerContext.isNeedPlay) {
                    [currentPlayerContext.player play];
                    
                    if (!currentPlayerContext.playing) {
                        currentPlayerContext.playing = YES;
                        [self sendEventListener:kPGPlayerEventOnPlay message:nil playerContext:currentPlayerContext];
                    }
                }
                // onCanPlay 事件
                [self sendEventListener:kPGPlayerEventOnCanplay message:nil playerContext:currentPlayerContext];
            }
            break;
            default:
            break;
        }
    }
    // 播放器的下载进度
    else if ([keyPath isEqualToString:kPGPlayerItemKeyPathLoadedTimeRanges]) {
        NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        currentPlayerContext.buffered = timeInterval;
        
        //        CMTime duration = playerItem.duration;
        //        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //        PDR_LOG_INFO(@"已缓冲时间：%.2f 缓冲进度：%.2f", timeInterval,timeInterval / totalDuration);
    }
    // 缓存不足暂停
    else if ([keyPath isEqualToString:kPGPlayerItemKeyPathPlaybackBufferEmpty]) {
        //                PDR_LOG_INFO(@"缓冲不足暂停了");
        currentPlayerContext.ready = NO;
        
        // onWaiting 事件
        [self sendEventListener:kPGPlayerEventOnWaiting message:nil playerContext:currentPlayerContext];
        [currentPlayerContext setPlayingCenterInfoWithRate:0 delay:NO];
    }
    // 缓存充足
    else if ([keyPath isEqualToString:kPGPlayerItemKeyPathPlaybackLikelyToKeepUp]) {

//                PDR_LOG_INFO(@"缓冲达到可播放程度了：%f",currentPlayerContext.buffered);

        currentPlayerContext.ready = YES;
        //缓存充足了需要手动播放，才能继续播放
        if (currentPlayerContext.isNeedPlay) {
            [currentPlayerContext.player play];
            
            if (!currentPlayerContext.playing) {
                currentPlayerContext.playing = YES;
                [self sendEventListener:kPGPlayerEventOnPlay message:nil playerContext:currentPlayerContext];
            }
            // 需要判断已缓冲时间是否真正可以开始播放
            [currentPlayerContext setPlayingCenterInfoWithRate:[currentPlayerContext isCacheFinish] ? 1 : 0 delay:NO];
        }
    }
}


/**
 播放结束
 */
- (void)playbackFinished:(NSNotification *)notice {
    //    PDR_LOG_INFO(@"播放完成");
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        PGPlayerContext *pPlayerContext = (PGPlayerContext*)obj;
        if (pPlayerContext.player.currentItem == notice.object) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:0 ];
            [self toCallback:pPlayerContext.jsCallbackId withReslut:[result toJSONString]];
            
            [self player:pPlayerContext seekToTime:0 onEvent:NO];
            
            // onEnded 事件
            [self sendEventListener:kPGPlayerEventOnEnded message:[result toJSONString] playerContext:pPlayerContext];
            
            // 是否需要循环播放
            if (pPlayerContext.loop) {
                //                PDR_LOG_INFO(@"播放结束，开始循环播放");
                [pPlayerContext.player play];
                pPlayerContext.playing = YES;
                [self sendEventListener:kPGPlayerEventOnPlay message:nil playerContext:pPlayerContext];
                [pPlayerContext setPlayingCenterInfoWithRate:[pPlayerContext isCacheFinish] ? 1 : 0];
            } else {
                pPlayerContext.isNeedPlay = NO;
                pPlayerContext.playing = NO;
                [pPlayerContext.player pause];
                [pPlayerContext setPlayingCenterInfoWithRate:0];
            }
            
            *stop = YES;
        }
    }];
}

#pragma mark - PGMethod

/**
 创建播放器
 */
- (NSData*)Player_Sync_CreatePlayer:(NSArray*)pMethod
{
    NSData *pDataRet = [[NSString stringWithFormat:@"null"] dataUsingEncoding:NSUTF8StringEncoding];
    
    if (pMethod && [pMethod count] > 1)
    {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        NSDictionary *option = [[pMethod objectAtIndex:1] isKindOfClass:[NSNull class]] ? @{} : [pMethod objectAtIndex:1];
        
        PGPlayerContext *pPlayerContext = [[PGPlayerContext alloc] init];
        pPlayerContext.playPath = option[kPGAudioPlayerKey_src];
        pPlayerContext.ready = NO;
        pPlayerContext.loadError = PGPluginOK;
        pPlayerContext.delegate = self;
        pPlayerContext.startTime = option[kPGAudioPlayerKey_startTime] ? [option[kPGAudioPlayerKey_startTime] integerValue] : 0;
        pPlayerContext.autoplay = option[kPGAudioPlayerKey_autoplay] ? [option[kPGAudioPlayerKey_autoplay] boolValue] : NO;
        pPlayerContext.isNeedPlay = pPlayerContext.autoplay;
        pPlayerContext.loop = option[kPGAudioPlayerKey_loop] ? [option[kPGAudioPlayerKey_loop] boolValue] : NO;
        float volume = option[kPGAudioPlayerKey_volume] ? [option[kPGAudioPlayerKey_volume] floatValue] : 1.0;
        pPlayerContext.backgroundControl = option[kPGAudioPlayerKey_backgroundControl] ? [option[kPGAudioPlayerKey_backgroundControl] boolValue] : NO;
        pPlayerContext.itemInfo = [[PGPlayerItemInfo alloc] initWithInfo:option];
        if (pPlayerContext.backgroundControl) {
            [self configRemoteCommandCenterWithPlayerContext:pPlayerContext];
        }
        
        if (m_pPlayerDic == nil){
            m_pPlayerDic = [[NSMutableDictionary alloc] init];
        }
        [m_pPlayerDic setObject:pPlayerContext forKey:pPlayerUUID];
        
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        AVPlayer *pPlayer = [[AVPlayer alloc] init];
        [pPlayer setVolume:volume];
        pPlayerContext.player = pPlayer;
        
        typedef void (^doPlayblock)(NSURL*,BOOL);
        __block typeof(self) weakSelf = self;
        doPlayblock playblock = ^(NSURL* pFileUrl, BOOL needPlay){
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:pFileUrl];
            if ( playerItem ) {
                [pPlayer replaceCurrentItemWithPlayerItem:playerItem];
                [pPlayerContext addPlayerObservers];
                // 是否自动播放
                if ( needPlay ) {
                    [pPlayer play];
                }
                // 是否从指定位置播放
                if (pPlayerContext.startTime > 0) {
                    [weakSelf player:pPlayerContext seekToTime:pPlayerContext.startTime onEvent:NO];
                }
                
            } else {
                pPlayerContext.loadError = PGPluginErrorNotSupport;
            }
        };
        
        if (pPlayerContext.playPath) {
            [self getPlayURLWithPlayerContext:pPlayerContext handleBlock:^(NSURL *playURL) {
                if (playURL) {
                    playblock(playURL,pPlayerContext.isNeedPlay);
                }
            }];
        }
    }
    
    return pDataRet;
}

- (void)closePlayer {
    
    [m_pPlayerDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        PGPlayerContext *context = (PGPlayerContext*)obj;
        context.isDiscard = YES;
        [context.player pause];
        [context removePlayerObservers:self];
    }];
    
    [m_pPlayerDic removeAllObjects];
    //[m_pPlayerDic release];
    m_pPlayerDic = nil;
}


/**
 事件监听
 */
- (void)Player_addEventListener:(NSArray *)pMethod {
    //    PDR_LOG_INFO(@"%@",pMethod);
    if ( pMethod && [pMethod count] > 2) {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        NSString *event = [pMethod objectAtIndex:1];
        NSString *jsCallBackID = [pMethod objectAtIndex:2];
        if (pPlayerUUID && event && jsCallBackID) {
            PGPlayerContext* pPlayerContext = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayerContext) {
                [pPlayerContext.m_listenerList setValue:jsCallBackID forKey:event];
            }
            // 处理 onError
            if ([event isEqualToString:kPGPlayerEventOnError] && pPlayerContext.loadError != PGPluginOK) {
                [self sendErrorEventListenerWithCode:pPlayerContext.loadError playerContext:pPlayerContext];
            }
            
        }
    }
}

/**
 移除监听事件
 
 @param event 事件名
 */
- (void)Player_removeEventListener:(NSArray *)pMethod {
    if ( pMethod && [pMethod count] > 1) {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        NSString *event = [pMethod objectAtIndex:1];
        if (pPlayerUUID && event) {
            PGPlayerContext *pPlayerContext = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayerContext) {
                [pPlayerContext.m_listenerList removeObjectForKey:event];
            }
        }
    }
}

/**
 发送js监听事件
 
 @param event 事件名称
 @param msg 参数
 @param pPlayer 控制器context
 */
- (void)sendEventListener:(NSString *)event message:(NSString *)msg playerContext:(PGPlayerContext *)pPlayer {
    NSString *jsCallBackID = [pPlayer.m_listenerList valueForKey:event];
    if (jsCallBackID) {
        [self toSucessCallback:jsCallBackID withString:msg ?: @"" keepCallback:YES];
    }
}


/**
 发送播放失败事件
 
 @param code error code
 @param pPlayer 控制前context
 */
- (void)sendErrorEventListenerWithCode:(int)code playerContext:(PGPlayerContext *)pPlayer {
    NSString *jsCallBackID = [pPlayer.m_listenerList valueForKey:kPGPlayerEventOnError];
    if (jsCallBackID) {
        [self toSucessCallback:jsCallBackID withJSON:@{@"code":@(code), @"message": [self errorMsgWithCode:code]} keepCallback:YES];
    }
}

/**
 开始播放
 */
- (void)Player_play:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    NSString* pCallBackID = nil;
    if ( pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        pCallBackID = [pMethod objectAtIndex:1];
        if (pPlayerUUID)  {
            PGPlayerContext* pPlayerContext = [m_pPlayerDic objectForKey:pPlayerUUID];
            pPlayerContext.isNeedPlay = YES;
            
            if ( !pPlayerContext ) {
                [self toErrorCallback:pCallBackID withCode:PGPluginErrorUnknown];
                return;
            }
            
            pPlayerContext.jsCallbackId = pCallBackID;
            
            if ( PGPluginOK != pPlayerContext.loadError ) {
                [self toErrorCallback:pPlayerContext.jsCallbackId withCode:pPlayerContext.loadError];
                return;
            }
            
            AVPlayer *pPlayer = pPlayerContext.player;
            [pPlayer play];
            pPlayerContext.playing = YES;
            [pPlayerContext setPlayingCenterInfoWithRate:[pPlayerContext isCacheFinish] ? 1 : 0];
            // onPlay event
            [self sendEventListener:kPGPlayerEventOnPlay message:nil playerContext:pPlayerContext];
        }
    }
}

/*
 * Ambient      不中止其他声音播放，不能后台播放，静音后无声音
 * SoloAmbient  中止其他声音播放，不能后台播放，静音后无声音
 * Playback     中止其他声音，可以后台播放，静音后无声音
 */
- (void)Player_setSessionCategory:(NSArray*)pMethod
{
    NSString* catType = AVAudioSessionCategoryPlayback;
    NSString* pCategory = [pMethod firstObject];
    if(pCategory && [pCategory isKindOfClass:[NSString class]]){
        if([[pCategory lowercaseString] isEqualToString:@"ambient"]){
            catType = AVAudioSessionCategoryAmbient;
        }else if([[pCategory lowercaseString] isEqualToString:@"soloambient"]){
            catType = AVAudioSessionCategorySoloAmbient;
        }
    }
    
    @try {
        AVAudioSession* session = [AVAudioSession sharedInstance];
        if(session){
            [session setCategory:catType error:nil];
        }
    } @catch (NSException *exception) {
        
    }
}


/**
 暂停播放
 */
- (void)Player_pause:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0) {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            pPlayer.isNeedPlay = NO;
            [pPlayer.player pause];
            pPlayer.playing = NO;
            [pPlayer setPlayingCenterInfoWithRate:0 delay:NO];
            // onPause event
            [self sendEventListener:kPGPlayerEventOnPause message:nil playerContext:pPlayer];
        }
    }
}


/**
 继续播放
 */
- (void)Player_resume:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0) {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            pPlayer.isNeedPlay = YES;
            [pPlayer.player play];
            pPlayer.playing = YES;
            [pPlayer setPlayingCenterInfoWithRate:[pPlayer isCacheFinish] ? 1 : 0];
            // onPlay event
            [self sendEventListener:kPGPlayerEventOnPlay message:nil playerContext:pPlayer];
        }
    }
}


/**
 停止播放
 下次调用 play 会从头播放
 */
- (void)Player_stop:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0) {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            pPlayer.isNeedPlay = NO;
            pPlayer.playing = NO;
            [pPlayer.player pause];
            [pPlayer setPlayingCenterInfoWithRate:0];
            //
            [self player:pPlayer seekToTime:0 onEvent:NO];
            // onPause event
            [self sendEventListener:kPGPlayerEventOnStop message:nil playerContext:pPlayer];
        }
    }
}


/**
 关闭播放器
 销毁player
 */
- (void)Player_close:(NSArray *)pMethod
{
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            pPlayer.isNeedPlay = NO;
            pPlayer.playing = NO;
            if (pPlayer.ready){
                [pPlayer.player pause];
                [pPlayer clearPlayingCenterInfo];
            }
            [self clearRemoteCommandCenter];
            [m_pPlayerDic removeObjectForKey:pPlayerUUID];
        }
    }
}

/**
 跳转到指定时间播放
 */
- (void)Player_seekTo:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    NSInteger pPlayTime   = 0;
    if ( pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        NSNumber *seekValue = [pMethod objectAtIndex:1];
        if ( [seekValue isKindOfClass:[NSNumber class]]
            || [seekValue isKindOfClass:[NSString class]]) {
            pPlayTime = [seekValue integerValue];
            if (pPlayerUUID){
                PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
                if (pPlayer.ready){
                    [self player:pPlayer seekToTime:pPlayTime onEvent:YES];
                }
            }
        }
    }
}
- (void)player:(PGPlayerContext *)playerContext seekToTime:(NSInteger)time onEvent:(BOOL)onEvent{
    if (onEvent) {
        [self sendEventListener:kPGPlayerEventOnSeeking message:nil playerContext:playerContext];
    }
    
    __weak __typeof(self)weakSelf = self;
    [playerContext.player seekToTime:CMTimeMake(time, 1.0) completionHandler:^(BOOL finished) {
        if (onEvent) {
            [weakSelf sendEventListener:kPGPlayerEventOnSeeked message:nil playerContext:playerContext];
        }
        [playerContext setPlayingCenterInfoWithRate:[playerContext isCacheFinish] ? 1 : 0];
    }];
}

/**
 设置声道
 */
- (void)Player_setRoute:(NSArray*)pMethod
{
    NSString* pPlayerUUID = nil;
    NSInteger nPlayOutput   = 0;
    if ( pMethod && [pMethod count] > 1)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        NSNumber *seekValue = [pMethod objectAtIndex:1];
        if ( [seekValue isKindOfClass:[NSNumber class]]
            || [seekValue isKindOfClass:[NSString class]]) {
            nPlayOutput = [seekValue integerValue];
            if ( pPlayerUUID ){
                AVAudioPlayer* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
                if (pPlayer) {
                    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                    UInt32 audioRouteOverride = PGAudioOutputEarpiece == nPlayOutput ? kAudioSessionOverrideAudioRoute_None:kAudioSessionOverrideAudioRoute_Speaker;
                    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
                }
            }
        }
    }
}


/**
 获取播放总时长
 */
- (NSData*)Player_Sync_getDuration:(NSArray*)pMethod
{
    NSData*   pDataRet = [self resultWithDouble:0.0];
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer.ready){
                pDataRet = [self resultWithDouble:CMTimeGetSeconds(pPlayer.player.currentItem.duration)];
            }
        }
    }
    return pDataRet;
}


/**
 获取当前是否已暂停播放
 */
- (NSData *)Player_Sync_getPaused:(NSArray *)pMethod
{
    NSData *pDataRet = [self resultWithBool:YES];
    if (pMethod && [pMethod count]) {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext *pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer.isNeedPlay && pPlayer.ready) {
                pDataRet = [self resultWithBool:NO];
            }
        }
    }
    return pDataRet;
}


/**
 获取已缓存时间
 */
- (NSData *)Player_Sync_getBuffered:(NSArray *)pMethod
{
    NSData *pDataRet = [self resultWithDouble:0.0];
    if (pMethod && [pMethod count]) {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext *pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer.isNeedPlay && pPlayer.ready) {
                pDataRet = [self resultWithDouble:pPlayer.buffered];
            }
        }
    }
    return pDataRet;
}

/**
 获取当前音量
 */
- (NSData *)Player_Sync_getVolume:(NSArray *)pMethod {
    NSData *pDataRet = [self resultWithDouble:1.0];
    if (pMethod && [pMethod count]) {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext *pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            if (pPlayer.player) {
                pDataRet = [self resultWithDouble:pPlayer.player.volume];
            }
        }
    }
    return pDataRet;
}

/**
 设置播放属性
 */
- (void)Player_setStyles:(NSArray *)pMethod {
    if ( pMethod && [pMethod count] > 1)
    {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        NSDictionary *option = [pMethod objectAtIndex:1];
        PGPlayerContext *pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
        
        if (pPlayer && [option isKindOfClass:[NSDictionary class]]) {
            // 处理 src
            if (option[kPGAudioPlayerKey_src] && [option[kPGAudioPlayerKey_src] isKindOfClass:[NSString class]]) {
                pPlayer.playPath = option[kPGAudioPlayerKey_src];
                pPlayer.loadError = PGPluginOK;
                pPlayer.ready = NO;
                pPlayer.buffered = 0;
                pPlayer.startTime = 0;
                [pPlayer removePlayerObservers];
                
                // 处理PlayingCenter Info
                PGPlayerItemInfo *itemInfo = [[PGPlayerItemInfo alloc] initWithInfo:option];
                pPlayer.itemInfo = itemInfo;
                [pPlayer setPlayingCenterInfoWithRate:0 delay:NO newInfo:YES];
                
                // 处理 startTime
                if (option[kPGAudioPlayerKey_startTime]) {
                    pPlayer.startTime = [option[kPGAudioPlayerKey_startTime] integerValue];
                }
                
                __weak __typeof(self)weakSelf = self;
                [self getPlayURLWithPlayerContext:pPlayer handleBlock:^(NSURL *playURL) {
                    if (playURL) {
                        
                        // 处理 autoplay
                        if (option[kPGAudioPlayerKey_autoplay] && [option[kPGAudioPlayerKey_autoplay] isKindOfClass:[NSNumber class]]) {
                            pPlayer.autoplay = [option[kPGAudioPlayerKey_autoplay] boolValue];
                            pPlayer.isNeedPlay = pPlayer.autoplay;
                        }
                        
                        // replace playerItem 之前先移除旧item的监听事件，然后在添加新的item监听事件
                        AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithURL:playURL];
                        [pPlayer.player replaceCurrentItemWithPlayerItem:playItem];
                        [pPlayer addPlayerObservers];
                        
                        if (pPlayer.startTime > 0) {
                            [weakSelf player:pPlayer seekToTime:pPlayer.startTime onEvent:NO];
                        }
                    }
                }];
            }
            // 处理 loop
            if (option[kPGAudioPlayerKey_loop] && [option[kPGAudioPlayerKey_loop] isKindOfClass:[NSNumber class]]) {
                pPlayer.loop = [option[kPGAudioPlayerKey_loop] boolValue];
            }
            // 处理 volume
            if (option[kPGAudioPlayerKey_volume] && [option[kPGAudioPlayerKey_volume] isKindOfClass:[NSNumber class]]) {
                [pPlayer.player setVolume:[option[kPGAudioPlayerKey_volume] floatValue]];
            }
            // 处理 backgroundControl
            if (option[kPGAudioPlayerKey_backgroundControl]) {
                pPlayer.backgroundControl = [option[kPGAudioPlayerKey_backgroundControl] boolValue];
                if (pPlayer.backgroundControl) {
                    [self configRemoteCommandCenterWithPlayerContext:pPlayer];
                } else {
                    [self clearRemoteCommandCenter];
                    [pPlayer clearPlayingCenterInfo];
                }
            }
        }
    }
}

- (NSData *)Player_Sync_getStyles:(NSArray *)pMethod {
    NSData *ret = [self resultWithUndefined];
    if ([pMethod count]) {
        NSString *pPlayerUUID = [pMethod objectAtIndex:0];
        PGPlayerContext *pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
        if (pPlayer) {
            // 返回单个属性值
            if (pMethod.count > 1 && [pMethod[1] isKindOfClass:[NSString class]]) {
                //
                NSString *attribute = pMethod[1];
                // src
                if ([attribute isEqualToString:kPGAudioPlayerKey_src] && pPlayer.playPath) {
                    ret = [self resultWithString:pPlayer.playPath];
                }
                // startTime
                else if ([attribute isEqualToString:kPGAudioPlayerKey_startTime]) {
                    ret = [self resultWithInt:(int)pPlayer.startTime ?: 0];
                }
                // loop
                else if ([attribute isEqualToString:kPGAudioPlayerKey_loop]) {
                    ret = [self resultWithBool:pPlayer.loop ?: NO];
                }
                // autoplay
                else if ([attribute isEqualToString:kPGAudioPlayerKey_autoplay]) {
                    ret = [self resultWithBool:pPlayer.autoplay ?: NO];
                }
                // volume
                else if ([attribute isEqualToString:kPGAudioPlayerKey_volume]) {
                    ret = [self resultWithDouble:pPlayer.player.volume];
                }
                // backgroundControl
                else if ([attribute isEqualToString:kPGAudioPlayerKey_backgroundControl]) {
                    ret = [self resultWithBool:pPlayer.backgroundControl ?: NO];
                }
                // title
                else if ([attribute isEqualToString:kPGPlayerItemInfoKey_title] && pPlayer.itemInfo.title) {
                    ret = [self resultWithString:pPlayer.itemInfo.title];
                }
                // epname
                else if ([attribute isEqualToString:kPGPlayerItemInfoKey_epname] && pPlayer.itemInfo.epname) {
                    ret = [self resultWithString:pPlayer.itemInfo.epname];
                }
                // singer
                else if ([attribute isEqualToString:kPGPlayerItemInfoKey_singer] && pPlayer.itemInfo.singer) {
                    ret = [self resultWithString:pPlayer.itemInfo.singer];
                }
                // coverImgUrl
                else if ([attribute isEqualToString:kPGPlayerItemInfoKey_coverImgUrl] && pPlayer.itemInfo.coverImgUrl) {
                    ret = [self resultWithString:pPlayer.itemInfo.coverImgUrl];
                }
                
            }
            // 返回所有信息
            else {
                NSMutableDictionary *info = [NSMutableDictionary dictionary];
                if(pPlayer.playPath) [info setValue:pPlayer.playPath forKey:kPGAudioPlayerKey_src];
                [info setValue:[NSNumber numberWithInteger:pPlayer.startTime ?: 0] forKey:kPGAudioPlayerKey_startTime];
                [info setValue:[NSNumber numberWithBool:pPlayer.loop ?: NO] forKey:kPGAudioPlayerKey_loop];
                [info setValue:[NSNumber numberWithBool:pPlayer.autoplay ?: NO] forKey:kPGAudioPlayerKey_autoplay];
                [info setValue:[NSNumber numberWithDouble:pPlayer.player.volume ?: 1.0] forKey:kPGAudioPlayerKey_volume];
                [info setValue:[NSNumber numberWithBool:pPlayer.backgroundControl ?: NO] forKey:kPGAudioPlayerKey_backgroundControl];
                if(pPlayer.itemInfo.title) [info setValue:pPlayer.itemInfo.title forKey:kPGPlayerItemInfoKey_title];
                if(pPlayer.itemInfo.epname) [info setValue:pPlayer.itemInfo.epname forKey:kPGPlayerItemInfoKey_epname];
                if(pPlayer.itemInfo.singer) [info setValue:pPlayer.itemInfo.singer forKey:kPGPlayerItemInfoKey_singer];
                if(pPlayer.itemInfo.coverImgUrl) [info setValue:pPlayer.itemInfo.coverImgUrl forKey:kPGPlayerItemInfoKey_coverImgUrl];
                ret = [self resultWithJSON:info];
            }
        }
    }
    return ret;
}

/**
 获取当前播放时间
 */
- (NSData*)Player_Sync_getPosition:(NSArray*)pMethod
{
    NSData*   pDataRet = [self resultWithDouble:0.0f];
    NSString* pPlayerUUID = nil;
    if ( pMethod && [pMethod count] > 0)
    {
        pPlayerUUID = [pMethod objectAtIndex:0];
        if (pPlayerUUID) {
            PGPlayerContext* pPlayer = [m_pPlayerDic objectForKey:pPlayerUUID];
            
            if (pPlayer.ready){
                pDataRet = [self resultWithDouble:CMTimeGetSeconds(pPlayer.player.currentTime)];
            }
        }
    }
    return pDataRet;
}

- (void)dealloc {
    [self closeRecorder];
    [self closePlayer];
    //[super dealloc];
}

@end



