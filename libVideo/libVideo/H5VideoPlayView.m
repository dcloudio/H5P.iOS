//
//  H5VideoPlayView.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/21.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "H5VideoPlayView.h"
#import <UPLiveSDK/UPAVPlayer.h>
#import "H5DirectionGestureRecognizer.h"
#import "H5VideoPlayOverlayView.h"
#import "Masonry.h"
#import "H5VideoBrightnessView.h"
#import "H5DanmuSwitchView.h"
#import "H5DanmakuManager.h"
#import "PDRCorePrivate.h"
#import "UIImageView+Video.h"
#import "SVProgressHUD.h"

#define kH5VidelPlayViewAutoHideBarTimerinterval 8
#define kH5VidelPlayViewBottomButtonSpace 5

@interface H5SwitchButton(PlayOnPause)
- (BOOL)isNeedPlay;
@end

@implementation H5SwitchButton(PlayOnPause)
- (BOOL)isNeedPlay {
    return self.isOn;
}
@end

@interface H5VideoPlayView()<UPAVPlayerDelegate, UIGestureRecognizerDelegate>
@property(nonatomic, strong)UPAVPlayer *videoPlayer;
@property(nonatomic, strong)H5SwitchButton *playAndPauseButton;
@property(nonatomic, strong)H5SwitchButton *fullScreenSwitchButton;
@property(nonatomic, strong)UISlider *slider;
@property(nonatomic, strong)UILabel *playTimeLabel;
@property(nonatomic, strong)UILabel *durationLabel;
@property(nonatomic, strong)H5DanmuSwitchView *danmuSwitchView;
@property(nonatomic, strong)UIView *bottomBarView;
@property(nonatomic, strong)UIView *bottomBarBackView;
@property(nonatomic, strong)H5DanmakuManager *danmakuManager;

@property(nonatomic, strong)UIImageView *thumbImageView;
@property (nonatomic, strong) UIButton *centerPlayButton;

@property (nonatomic, assign) UIInterfaceOrientation afterInterfaceOrientation;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) H5UIDirectionGestureRecognizer *directionGesture;
@property (nonatomic, strong) H5VideoPlayOverlayView *videoPlayOverlayView;
@property (nonatomic, assign) BOOL lockAutoUpdateSlider;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) BOOL restorePlay;
@property (nonatomic, strong)H5VideoPlaySetting *setting;
@property (nonatomic, strong)NSMutableArray<NSDictionary*> *dumaLists;
@property (nonatomic, assign)float lastSlideProgress;
@property(nonatomic, assign)BOOL isShowBuffingView;
@property(nonatomic, assign)BOOL isPlayLoopRun;
@property(nonatomic, assign)BOOL isPlayAfterShow;
//Todo.. 又拍云SDK 在seek之后会触发idle 导致区分不开stop，加个标记来区分
@property(nonatomic, assign)BOOL ingoreIdleAfterSeek;
@end

@implementation H5VideoPlayView
- (instancetype)initWithFrame:(CGRect)frame withSetting:(H5VideoPlaySetting*)setting withStyles:(NSDictionary*)styles{
    if ( self = [super initWithFrame:frame withOptions:styles withJsContext:nil] ) {
        self.clipsToBounds = YES;
        [self appendDuma:setting.danmuList];
       // self.backgroundColor = [UIColor blackColor];
        self.setting = setting;
        [self createPlayView];
        [self initBottomBar];
        [self setUpBottomBar];
        [self doBottomBarConstraint];
        
        [self initOtherView];

        self.afterInterfaceOrientation = UIInterfaceOrientationUnknown;
       // [self transformWithOrientation:UIDeviceOrientationPortrait];
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        self.tapGesture.delegate = self;
        [self addGestureRecognizer:self.tapGesture];
        [self addGestrueControl];
        [self addSystemNotify];
        self.isFirst = YES;
        self.isPlayLoopRun = NO;
    }
    return self;
}

- (void)appendDuma:(NSArray<NSDictionary*>*)duma {
    if ( !self.dumaLists ) {
        self.dumaLists = [NSMutableArray array];
    }
    [self.dumaLists addObjectsFromArray:duma];
}

- (void)clearDanmaku {
    [self.dumaLists removeAllObjects];
}

- (void)createPlayView {
    self.videoPlayer = [[UPAVPlayer alloc] initWithURL:self.setting.url];
    [self.videoPlayer.playView setFrame:self.bounds];
    self.videoPlayer.mute = self.setting.isMuted;
    self.videoPlayer.bufferingTime = 5;
    //[self.videoPlayer connect];
    //self.videoPlayer.playView.contentMode = UIViewContentModeScaleToFill;
    self.videoPlayer.playView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    | UIViewAutoresizingFlexibleTopMargin
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleHeight
    | UIViewAutoresizingFlexibleBottomMargin;
    
    self.videoPlayer.delegate = self;
    self.videoPlayer.lipSynchOn = NO;
    [self insertSubview:self.videoPlayer.playView atIndex:0];
}

- (void)onLayout_{
    [self.videoPlayer.playView setFrame:self.bounds];
   // [self.videoPlayer setFrame:self.bounds];
    [self.delegate onLayout_:self];
}

- (void)destroyPlayView {
    [self.videoPlayer stop];
    self.videoPlayer.delegate = nil;
    [self.videoPlayer.playView removeFromSuperview];
    self.videoPlayer = nil;
}

- (void)didMoveToSuperview {
    [self prepareAutoPlay];
}

- (void)prepareAutoPlay {
    if ( self.isFirst ) {
        if ( self.setting.isAutoplay ) {
            [self play];
        }
    }
}

- (void)showBar {
    [self showBottomBar];
    // self.centerPauseButton.hidden = NO;
    if ([self isFullScreen]) {
    }
    [self doConstraintAnimation];
    
   // [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:nil];
    [self cancelHideBar];
    [self hideBarDelay];
}

- (void)hideBarDelay {
    [self performSelector:@selector(hideBar) withObject:nil afterDelay:kH5VidelPlayViewAutoHideBarTimerinterval];
   // [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:nil];
}

- (void)cancelHideBar {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:nil];
}

- (void)hideBar {
    
   // if (UPAVPlayerStatusPlaying != self.videoPlayer.playerStatus) return;
    [self hideBottomBar];
    //    self.centerPauseButton.hidden = YES;
    [self doConstraintAnimation];
}

- (void)doConstraintAnimation {
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    [UIView animateWithDuration:.3 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)resetUI {
    self.slider.enabled = NO;
    self.isPlayLoopRun = NO;
    self.slider.value = 0.0f;
    self.playTimeLabel.text = @"00:00";
    [self turnOnPlayPauseButton:NO];
    //2self.tapGesture.enabled = NO;
    self.directionGesture.enabled = NO;
    [self dismissBuffuingView];
    [self hideBar];
    self.isFirst = YES;
}

- (void)activeUI {
    self.tapGesture.enabled = YES;
    self.directionGesture.enabled = YES;
}


- (void)turnOnPlayPauseButton:(BOOL)isPlaying {
  //  self.playAndPauseButton .hidden = isPlaying;
    //self.pauseButton.hidden = !isPlaying;
    self.playAndPauseButton.on = isPlaying;
  //
    //    if (isPlaying) {
    //        self.centerPauseButton.hidden = NO;
    //        self.centerPlayButton.hidden  = YES;
    //    } else {
    //        self.centerPauseButton.hidden = YES;
    //        [self.centerPlayButton show];
    //    }
}
-(void)addSystemNotify {
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeSystemNotify {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appDidEnterBackground {
    if ( UPAVPlayerStatusPlaying == _videoPlayer.playerStatus  ) {
        self.restorePlay = YES;
        [_videoPlayer pause];
    }
}


- (void)appDidEnterPlayground {
    if ( self.restorePlay ) {
        self.restorePlay = NO;
        [_videoPlayer play];
    }
}

-(void)addFullStreenNotify {
    [self removeFullStreenNotify];
     [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStatusBarOrientationChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

-(void)removeFullStreenNotify{
  //  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color {
    if ( self.setting.enableDanmu ) {
        if ( self.danmuSwitchView.selected ) {
            [self.danmakuManager sendDanmaku:sender withColor:color];
        }
    }
}

- (void)__sendDanmaku:(NSDictionary*)danmu  {
    NSString *text = [PGPluginParamHelper getStringValueInDict:danmu forKey:@"text" defalut:nil];
    UIColor *color = [PGPluginParamHelper getCssColor:[danmu objectForKey:@"color"] defalut:[UIColor whiteColor]];
    float time = [PGPluginParamHelper getFloatValueInDict:danmu forKey:@"time" defalut:0];
    if ( text ) {
        [self.danmakuManager sendDanmaku:text withColor:color time:time];
    }
}

- (void)sendDanmaku:(NSDictionary*)danmu {
    if ( self.setting.enableDanmu ) {
        if ( self.danmuSwitchView.selected ) {
            if ( UPAVPlayerStatusPlaying == _videoPlayer.playerStatus ) {
                [self __sendDanmaku:danmu];
            }else {
                [self appendDuma:@[danmu]];
            }
        }
    }
}

- (void)setControlValue:(id)value forKey:(NSString*)key {
    if ( [key isEqualToString:kH5VideoPlaySettingKeyUrl] ) {
        NSString *newUrl = (NSString*)value;
        if ( [newUrl isKindOfClass:[NSString class]] && ![newUrl isEqualToString:self.setting.url]) {
            UPAVPlayerStatus oldStatus = _videoPlayer.playerStatus;
            if (UPAVPlayerStatusIdle != _videoPlayer.playerStatus ) {
                [_videoPlayer stop];
                self.ingoreIdleAfterSeek = YES;
            }
            _videoPlayer.url = newUrl;
            if ( UPAVPlayerStatusPlaying == oldStatus ) {
                 [_videoPlayer play];
            } else if ( UPAVPlayerStatusIdle == oldStatus ){
                if ( self.setting.isAutoplay ) {
                    [self play];
                }
            }
            self.setting.url = newUrl;
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyPoster] ) {
        NSString *newPoster = (NSString*)value;
        if ( [newPoster isKindOfClass:[NSString class]] && NSOrderedSame != [newPoster caseInsensitiveCompare:self.setting.poster]) {
            if ( [newPoster length] > 0 ) {
                self.setting.poster = newPoster;
                [self createThumbImageView];
                if ( self.thumbImageView ) {
                    [self.thumbImageView h5Video_setImageUrl:self.setting.poster];
                }
            }
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyShowProgressGresture] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.isEnableProgressGesture = [newValue boolValue];
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyShowCenterPlayBtn] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.isShowCenterPlayBtn = [newValue boolValue];
            if ( self.videoPlayer.displayPosition == 0 ){
                self.centerPlayButton.hidden = !self.setting.isShowCenterPlayBtn;
            }
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyShowPlayBtn] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            if ( self.setting.isShowPlayBtn != [newValue boolValue]) {
                self.setting.isShowPlayBtn = [newValue boolValue];
                self.playAndPauseButton.hidden = !self.setting.isShowPlayBtn;
                [self doBottomBarConstraint];
            }
        }
    }  else if ( [key isEqualToString:kH5VideoPlaySettingKeyShowFullScreenBtn] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            if ( self.setting.isShowFullscreenBtn != [newValue boolValue]) {
                self.setting.isShowFullscreenBtn = [newValue boolValue];
                self.fullScreenSwitchButton.hidden = !self.setting.isShowFullscreenBtn;
                [self doBottomBarConstraint];
            }
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyShowProgress] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            if ( self.setting.isShowProgress != [newValue boolValue]) {
                self.setting.isShowProgress = [newValue boolValue];
                self.slider.hidden = !self.setting.isShowProgress;
                self.durationLabel.hidden = self.slider.hidden;
                self.playTimeLabel.hidden = self.slider.hidden;
                [self doBottomBarConstraint];
            }
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyControls] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            if ( self.setting.isShowControls != [newValue boolValue]) {
                self.setting.isShowControls = [newValue boolValue];
                self.bottomBarBackView.hidden = !self.setting.isShowControls;
                [self doBottomBarConstraint];
            }
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyPageGesture] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.isEnablePageGesture = [newValue boolValue];
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyLoop] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.isLoop = [newValue boolValue];
        }
    }  else if ( [key isEqualToString:kH5VideoPlaySettingKeyAutoPlay] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.isAutoplay = [newValue boolValue];
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyMuted] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.isMuted = [newValue boolValue];
            _videoPlayer.mute = [newValue boolValue];
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyDirection] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.direction = [newValue integerValue];
        }
    } else if ( [key isEqualToString:kH5VideoPlaySettingKeyDuration] ) {
        NSNumber *newValue = (NSNumber*)value;
        if ( [newValue isKindOfClass:[NSNumber class]] ) {
            self.setting.duration = [newValue integerValue];
            self.durationLabel.text = [self foramtStringByPosition:self.setting.duration ];
        }
    }
}

- (void)updateWithSetting:(H5VideoPlaySetting*)setting {
    //Todo..
    if ( setting.url && ![setting.url isEqualToString:self.setting.url] ) {
        [_videoPlayer stop];
        _videoPlayer.url = setting.url;
        [_videoPlayer play];
        self.setting.url = setting.url;
    }
}

#pragma mark - life cycle
- (void)dc_setHidden:(BOOL)isHidden {
    self.hidden = isHidden;
    if ( self.hidden ) {
        if ( UPAVPlayerStatusPlaying == self.videoPlayer.playerStatus ) {
            [self pause];
            self.isPlayAfterShow = YES;
        }
    } else {
        if ( self.isPlayAfterShow ) {
            [self play];
        }
        self.isPlayAfterShow = NO;
    }
}
- (void)destroy {
    [self removeSystemNotify];
    [self removeGestureRecognizer:self.tapGesture];
    [self removeGestureRecognizer:self.directionGesture];
    [_danmakuManager destroy];
    [self removeFullStreenNotify];
    [self removeFromSuperview];
    [self destroyPlayView];
}

- (void)updateLayout {
    [self doBottomBarConstraint];
}

- (void)dealloc {
    
}

- (void)seek:(float)positon {
    //TODO... pause seek play???
    BOOL pauseAfterSeek = (UPAVPlayerStatusPause == self.videoPlayer.playerStatus)?YES:NO;
    /*Todo.. 又拍云 seek到结尾的情况下不会触发idle 判断不出stop 这个强制终止
     ask 链接 http://ask.dcloud.net.cn/question/62236 */
    if ( self.videoPlayer.streamInfo.canSeek && positon >= self.videoPlayer.streamInfo.duration ) {
        [self.videoPlayer stop];
        return;
    }
    [self.videoPlayer seekToTime:positon];
    self.ingoreIdleAfterSeek = YES;
    if ( pauseAfterSeek ) {
      //  [self.videoPlayer pause];
        //Todo..
        /*又拍云SDK调用seek 后会自动播放会导致之前如果是暂停播放按钮显示不对，
         此时调用pause也无效，该问题需要又拍云修改SDK，目前暂时修改为继续播放修复播 放按钮不对的问题
          ask 链接 http://ask.dcloud.net.cn/question/61332 */
        [self turnOnPlayPauseButton:YES];
        [self __play];
        //end
    }
}

- (void)playbackReate:(int)rate {
    // Not suppot
}
//- (void)resume {
//    // [self.delegate playerViewWillPlay:self];
//    [self turnOnPlayPauseButton:YES];
//    //[self.videoPlayer performSelector:@selector(play) withObject:nil afterDelay:1.1];
//    [self.videoPlayer play];
//
//    if ( [self.delegate respondsToSelector:@selector(playerViewPlay:)] ) {
//        [self.delegate playerViewPlay:self];
//    }
//}

- (void)pause {
    [self turnOnPlayPauseButton:NO];
    [self __pause];
    self.isPlayAfterShow = NO;
}

- (void)stop {
    [self resetUI];
    [self destroyPlayView];
    [self createPlayView];
    self.isPlayAfterShow = NO;
}

- (void)play {
    if ([self __play]) {
        [self.videoPlayOverlayView hideRepeatView];
        [self turnOnPlayPauseButton:YES];
    }
    self.isPlayAfterShow = NO;
}

- (void)__pause {
    // [self turnOnPlayPauseButton:NO];
    [self dismissBuffuingView];
    if ( self.videoPlayer.streamInfo.canSeek ) {
        [self.videoPlayer pause];
    } else {
        [self.videoPlayer stop];
    }
    if ( [self.delegate respondsToSelector:@selector(playerViewPause:)] ) {
        [self.delegate playerViewPause:self];
    }
}

- (BOOL)__play {
    //[self.delegate playerViewWillPlay:self];
    // [self addFullStreenNotify];
    //[self addTimer];
    if ( !self.videoPlayer.url ) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"file not found"}];
        [self.delegate playerView:self playerError:error];
        return NO;
    }
    [self.videoPlayOverlayView hideRepeatView];
    self.centerPlayButton.hidden = YES;
    //[self turnOnPlayPauseButton:YES];
    if (!(UPAVPlayerStatusPlaying == self.videoPlayer.playerStatus)) {
       // NSDate *date = [NSDate date];
        [self.videoPlayer play];
        if ( self.isFirst ) {
            self.isFirst = NO;
          //  [self.videoPlayer seekToTime:self.setting.initialTime];
        }
       // NSLog(@"play 耗时： %f s",[[NSDate date] timeIntervalSinceDate:date]);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( [self.dumaLists count] ) {
            for ( NSDictionary*danmu in self.dumaLists ) {
                [self __sendDanmaku:danmu];
            }
            [self.dumaLists removeAllObjects];
        }
    });
    
    if ( [self.delegate respondsToSelector:@selector(playerViewPlay:)] ) {
        [self.delegate playerViewPlay:self];
    }
    return YES;
}

#pragma mark - gesture
- (void)addGestrueControl {
   // if ( self.setting.isEnablePageGesture || self.setting.isEnableProgressGesture  ) {
        if ( !self.directionGesture ) {
            self.directionGesture = [[H5UIDirectionGestureRecognizer alloc] initWithTarget:self action:@selector(directionGesture:)];
            self.directionGesture.delegate = self;
            [self addGestureRecognizer:self.directionGesture];
        }
  //  }
}

- (void)removeGestrueControl {
    if ( self.directionGesture ) {
        self.directionGesture.delegate = nil;
        [self.directionGesture removeTarget:self action:@selector(directionGesture:)];
        [self removeGestureRecognizer:self.directionGesture];
        self.directionGesture = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    if ( self.directionGesture.isEnabled ) {
//        return NO;
//    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self];
    if (  CGRectContainsPoint(self.bottomBarBackView.frame, location)  ) {
        return NO;
    }
    return YES;
}

- (void)singleTap:(UIGestureRecognizer *)gesture {
    if ( self.centerPlayButton && !self.centerPlayButton.hidden ) {
      //  return;
    }
    if (self.bottomBarBackView.frame.origin.y >= self.bounds.size.height) {
        [self showBar];
    } else {
        [self hideBar];
    }
}

-(void)directionGesture:(H5UIDirectionGestureRecognizer*)panGesture {
    if ( self.centerPlayButton && !self.centerPlayButton.hidden ) {
        return;
    }
    
    if ( UIGestureRecognizerStateBegan ==  panGesture.state ) {
        self.lastSlideProgress = self.videoPlayer.displayPosition;
    } else if ( UIGestureRecognizerStateChanged == panGesture.state ) {
        if ( [panGesture isHorizontal] ) {
            if ( self.setting.isEnableProgressGesture ) {
                UPAVPlayerStreamInfo *streamInfo = self.videoPlayer.streamInfo;
                if ( streamInfo.canSeek ) {
                    [self manualSliderValueStart];
                    //NSLog(@"directionGesture---[%f]",self.videoPlayer.displayPosition);
                    CGFloat value = [self newValue:self.lastSlideProgress//self.slider.value
                                        deltaValue:panGesture.delta.x deltaReferenceValue:CGRectGetWidth(self.bounds)
                                          minValue:0.0 maxValue:streamInfo.duration];
                    self.slider.value = value;
                    self.lastSlideProgress = value;
                    NSString *seekInfo = [NSString stringWithFormat:@"%@/%@",[self foramtStringByPosition:value], [self foramtStringByPosition:streamInfo.duration]];
                    [self.videoPlayOverlayView initProgressViewWithText:seekInfo];
                    [self.videoPlayOverlayView updateProgress:seekInfo];
                }
            }
        } else if ( [panGesture isVertical] ) {
            if ( self.isFullScreen/*|| (self.setting.isEnablePageGesture && !self.isFullScreen)*/) {
                if ( panGesture.beginPressPoint.x < CGRectGetMidX(self.bounds) ) {//调整亮度
                    self.videoPlayer.bright = [self newValue:[self.videoPlayer bright]
                                                  deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                                                    minValue:0.01 maxValue:1.0];
                    [[H5VideoBrightnessView sharedView] updateLongView:self.videoPlayer.bright];
                } else {//调整音量
                    [self.videoPlayer setVolume:[self newValue:self.videoPlayer.volume
                                                    deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                                                      minValue:0.01 maxValue:1.0]];
                }
            }
        }
    } else if( UIGestureRecognizerStateEnded == panGesture.state
              || UIGestureRecognizerStateCancelled == panGesture.state ) {
        if ( [panGesture isHorizontal] ) {
            if ( self.setting.isEnableProgressGesture ) {
                UPAVPlayerStreamInfo *streamInfo = self.videoPlayer.streamInfo;
                if ( streamInfo.canSeek ) {
                    [self.videoPlayOverlayView hideProgressView];
                    [self manualSliderValueEnd];
                }
            }
        } else if ( [panGesture isVertical] ) {
            if ( self.isFullScreen /*|| (self.setting.isEnablePageGesture && !self.isFullScreen)*/) {
                if ( panGesture.beginPressPoint.x < CGRectGetMidX(self.bounds) ) {//调整亮度
                    self.videoPlayer.bright = [self newValue:[self.videoPlayer bright]
                                                  deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                                                    minValue:0.01 maxValue:1.0];
                } else {//调整音量
                    [self.videoPlayer setVolume:[self newValue:self.videoPlayer.volume
                                                    deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                                                      minValue:0.01 maxValue:1.0]];
                }
            }
        }
        self.lastSlideProgress = 0;
    }
}

- (CGAffineTransform)getTransformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

- (H5VideoBrightnessView*) brightnessView{
    return [H5VideoBrightnessView sharedView];
}

#pragma mark - fullScreen
- (void)requestFullScreen:(H5VideoPlayDirection)direction {
    if ( !self.isFullScreen ) {
        //  [self addFullStreenNotify];
        [PDRCore lockScreen];
        self.isFullScreen = YES;
        UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationLandscapeRight;
        if ( H5VideoPlayDirectionAuto == direction ) {
            if (UIDeviceOrientationLandscapeRight == [[UIDevice currentDevice]orientation]) {
                interfaceOrientation = UIInterfaceOrientationLandscapeRight;
                // [self transformWithOrientation:UIInterfaceOrientationLandscapeRight];
            } else {
                interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
                //  [self transformWithOrientation:UIInterfaceOrientationLandscapeLeft];
            }
        } else if ( H5VideoPlayDirectionLeft == direction ) {
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            //  [self transformWithOrientation:UIInterfaceOrientationLandscapeLeft];
        } else if (  H5VideoPlayDirectionRight == direction  ){
            interfaceOrientation = UIInterfaceOrientationLandscapeRight;
            // [self transformWithOrientation:UIInterfaceOrientationLandscapeRight];
        } else {
            interfaceOrientation = UIInterfaceOrientationPortrait;
            // [self transformWithOrientation:UIInterfaceOrientationPortrait];
        }
        self.afterInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self setFullScreenLayout:interfaceOrientation];
        [self transformWithOrientation:interfaceOrientation];
        [[PDRCore Instance] setHomeIndicatorAutoHidden:YES];
        [self.delegate playerViewEnterFullScreen:self interfaceOrientation:interfaceOrientation];
    } else {
        [[PDRCore Instance] setHomeIndicatorAutoHidden:NO];
        [self exitFullScreen];
        [PDRCore unlockScreen];
    }
    if ( self.isShowBuffingView ) {
        [self dismissBuffuingView];
        [self showBuffuingView];
    }
    
}

- (void)exitFullScreen {
    [self setExitFullScreenLayout];
    self.isFullScreen = NO;
    [self transformWithOrientationWithExitFullScreen:self.afterInterfaceOrientation];
    [self removeFullStreenNotify];
    [self.delegate playerViewExitFullScreen:self];
}

- (void)setFullScreenLayout:(UIInterfaceOrientation)orientation {
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self removeFromSuperview];
    UIWindow *hostWindow = [self hostWindow];
    [hostWindow addSubview:self];
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(hostWindow);
        if ( UIInterfaceOrientationIsPortrait(currentOrientation) != UIInterfaceOrientationIsPortrait(orientation) ) {
            make.width.equalTo(CGRectGetHeight(hostWindow.bounds));
            make.height.equalTo(CGRectGetWidth(hostWindow.bounds));
        }else {
            make.width.equalTo( CGRectGetWidth(hostWindow.bounds));
            make.height.equalTo(CGRectGetHeight(hostWindow.bounds));
        }
    }];
    
    [[self brightnessView] removeFromSuperview];
    [self addSubview:self.brightnessView];
    [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(155);
    }];
}

- (void)setExitFullScreenLayout {
    [self removeFromSuperview];
    [[self brightnessView].layer removeAllAnimations];
    [[self brightnessView] removeFromSuperview];
    [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessView];
    CGSize size =  [[UIScreen mainScreen] bounds].size;
    [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(155);
        make.leading.mas_equalTo((size.width -155)/2);
        make.top.mas_equalTo((size.height-155)/2);
    }];
}

- (void)transformWithOrientation:(UIInterfaceOrientation)newOrientation {
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if ( newOrientation == currentOrientation ) return;
    if ( newOrientation == UIInterfaceOrientationLandscapeLeft
        || newOrientation == UIInterfaceOrientationLandscapeRight ) {
        if ( currentOrientation == UIInterfaceOrientationPortrait) {
            [UIView animateWithDuration:0.3 animations:^{
                // self.transform = CGAffineTransformIdentity;
                //self.transform = [self getTransformRotationAngle];
                self.transform = UIInterfaceOrientationLandscapeLeft == newOrientation ? CGAffineTransformMakeRotation(-M_PI_2) : CGAffineTransformMakeRotation(M_PI_2);
            }];
        } else {
            [UIView animateWithDuration:0.3 animations:^{
                // self.transform = CGAffineTransformIdentity;
                //self.transform = [self getTransformRotationAngle];
                self.transform = UIInterfaceOrientationLandscapeLeft == newOrientation ? CGAffineTransformMakeRotation(-M_PI) : CGAffineTransformMakeRotation(M_PI);
            }];
        }
       // [self setNeedsUpdateConstraints];
       // [self doConstraintAnimation];
    } else {
        [UIView animateWithDuration:.3 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }
    [[UIApplication sharedApplication] setStatusBarOrientation:newOrientation animated:NO];
}

- (void)transformWithOrientationWithExitFullScreen:(UIInterfaceOrientation)newOrientation {
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if ( newOrientation == currentOrientation ) return;
    [UIView animateWithDuration:.3 animations:^{
        self.transform = CGAffineTransformIdentity;
    }];
    [[UIApplication sharedApplication] setStatusBarOrientation:newOrientation animated:NO];
}

// 状态条变化通知（在前台播放才去处理）
- (void)onDeviceOrientationChange {
    return;//weixin Not Suppot
#if 0
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    if (self.isFullScreen == YES) {
        switch ( interfaceOrientation ) {
            case UIInterfaceOrientationLandscapeRight:
            case UIInterfaceOrientationLandscapeLeft:
                [self transformWithOrientation:interfaceOrientation];
                break;
            default:
                break;
        }
    }
#endif
}

- (void)onStatusBarOrientationChange {
    return;
    if ( self.isFullScreen ) {
        UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self transformWithOrientation:currentOrientation];
    }
    //if (!self.didEnterBackground) {
    // 获取到当前状态条的方向
    
    
    // if (currentOrientation == UIInterfaceOrientationPortrait) {
    //            [self setOrientationPortraitConstraint];
    //            if (self.cellPlayerOnCenter) {
    //                if ([self.scrollView isKindOfClass:[UITableView class]]) {
    //                    UITableView *tableView = (UITableView *)self.scrollView;
    //                    [tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    //
    //                } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
    //                    UICollectionView *collectionView = (UICollectionView *)self.scrollView;
    //                    [collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    //                }
    //            }
    //            [self.brightnessView removeFromSuperview];
    //            [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessView];
    //            [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
    //                make.width.height.mas_equalTo(155);
    //                make.leading.mas_equalTo((ScreenWidth-155)/2);
    //                make.top.mas_equalTo((ScreenHeight-155)/2);
    //            }];
    // } else {
    //            if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
    //                [self toOrientation:UIInterfaceOrientationLandscapeRight];
    //            } else if (currentOrientation == UIDeviceOrientationLandscapeLeft){
    //                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
    //            }
    //            [self.brightnessView removeFromSuperview];
    //            [self addSubview:self.brightnessView];
    //            [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
    //                make.center.mas_equalTo(self);
    //                make.width.height.mas_equalTo(155);
    //            }];
    //  }
    // }
}


- (UIWindow*)hostWindow {
    return [UIApplication sharedApplication].keyWindow;
}

//- (void)playerViewEnterFullScreen {
//    UIView *superView = [UIApplication sharedApplication].delegate.window.rootViewController.view;
//    [self removeFromSuperview];
//    [superView addSubview:self];
//    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.width.equalTo(superView.mas_height);
//        make.height.equalTo(superView.mas_width);
//        make.center.equalTo(superView);
//    }];
//    [superView setNeedsUpdateConstraints];
//    [superView updateConstraintsIfNeeded];
//
//    [UIView animateWithDuration:.3 animations:^{
//        [superView layoutIfNeeded];
//    }];
//}

#pragma mark - otherView
- (void)createThumbImageView {
    if ( !self.setting.isAutoplay ) {
        if ( !self.thumbImageView ) {
            self.thumbImageView = [[UIImageView alloc] init];
            self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.clipsToBounds = YES;
            [self.videoPlayer.playView addSubview:self.thumbImageView];
            [self.thumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.videoPlayer.playView);
            }];
        }
    }
}

- (void)initOtherView {
    if ( !self.setting.isAutoplay ) {
        if ( self.setting.poster ) {
            [self createThumbImageView];
            [self.thumbImageView h5Video_setImageUrl:self.setting.poster];
        }
        
        self.centerPlayButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
        [self.centerPlayButton setTintColor:[UIColor whiteColor]];
        [self.centerPlayButton setImage:[UIImage imageNamed:@"player_play"] forState:(UIControlStateNormal)];
        [self.centerPlayButton addTarget:self action:@selector(onClickCenterPlayPauseSwitchButton) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:self.centerPlayButton];
        
        [self.centerPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.equalTo(CGSizeMake(64, 64));
        }];
        self.centerPlayButton.hidden = !self.setting.isShowCenterPlayBtn;
    }
}

#pragma mark - bottomBar
- (void)setUpBottomBar {
    BOOL showContols = self.setting.isShowControls;
    if ( !showContols ) {
        //showContols = self.setting.isShowProgress|| self.setting.isShowPlayBtn||self.setting.isShowFullscreenBtn ||self.setting.isShowDanmuBtn;
    }
    self.bottomBarBackView.hidden = !showContols;
    self.playAndPauseButton.hidden = !self.setting.isShowPlayBtn;
    self.slider.hidden = self.durationLabel.hidden = self.playTimeLabel.hidden = !self.setting.isShowProgress;
    self.slider.hidden = !self.setting.isShowProgress;
    self.fullScreenSwitchButton.hidden = !self.setting.isShowFullscreenBtn;
    self.danmuSwitchView.hidden = !(self.setting.enableDanmu && self.setting.isShowDanmuBtn);
}

- (void)initBottomBar {

    self.bottomBarView = [[UIView alloc] init];
    self.bottomBarView.backgroundColor = [UIColor clearColor];
    
    self.playAndPauseButton = [H5SwitchButton new];
    [self.playAndPauseButton setOffImage:[UIImage imageNamed:@"player_play"]];
    [self.playAndPauseButton setOnImage:[UIImage imageNamed:@"player_stop"]];
    [self.playAndPauseButton addTarget:self action:@selector(onClickPlayPauseSwitchButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.playTimeLabel = [[UILabel alloc] init];
    self.playTimeLabel.font = [UIFont systemFontOfSize:12];
    if (@available(iOS 9, *)) {
        self.playTimeLabel.font= [UIFont monospacedDigitSystemFontOfSize:12 weight:(UIFontWeightRegular)];
    }
    self.playTimeLabel.textColor = [UIColor whiteColor];
    self.playTimeLabel.text = @"0:00:00";
    [self.playTimeLabel sizeToFit];
    
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.font = [UIFont systemFontOfSize:12];
    if (@available(iOS 9.0, *)) {
        self.durationLabel.font= [UIFont monospacedDigitSystemFontOfSize:12 weight:(UIFontWeightRegular)];
    }
    self.durationLabel.textColor = [UIColor whiteColor];
    self.durationLabel.text = @"0:00:00";
    [self.durationLabel sizeToFit];
    
    self.slider = [[UISlider alloc] init];
    [self.slider setThumbImage:[UIImage imageNamed:@"slider_thumb"] forState:(UIControlStateNormal)];
    self.slider.maximumTrackTintColor = [UIColor lightGrayColor];
    self.slider.minimumTrackTintColor = [UIColor colorWithRed:.2 green:.2 blue:.8 alpha:1];
    [self.slider addTarget:self action:@selector(onSliderValueChange) forControlEvents:(UIControlEventValueChanged)];
    [self.slider addTarget:self action:@selector(onSliderTouchDown) forControlEvents:(UIControlEventTouchDown)];
    [self.slider addTarget:self action:@selector(onSliderTouchUp) forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel)];
    self.slider.enabled = NO;
    
    self.danmuSwitchView = [H5DanmuSwitchView new];
    [self.danmuSwitchView setSelected:YES];
    [self.danmuSwitchView addTarget:self action:@selector(onDanmuSwitchViewValueChanged) forControlEvents:(UIControlEventValueChanged)];
    
    self.fullScreenSwitchButton = [H5SwitchButton new];
    [self.fullScreenSwitchButton setOffImage:[UIImage imageNamed:@"full-screen"]];
    [self.fullScreenSwitchButton setOnImage:[UIImage imageNamed:@"exitfullscreen"]];
    [self.fullScreenSwitchButton addTarget:self action:@selector(onClickEnterFullScreenButton) forControlEvents:(UIControlEventValueChanged)];
    
    [self.bottomBarView addSubview:self.playAndPauseButton];
    [self.bottomBarView addSubview:self.playTimeLabel];
    [self.bottomBarView addSubview:self.durationLabel];
    [self.bottomBarView addSubview:self.slider];
    [self.bottomBarView addSubview:self.danmuSwitchView];
    [self.bottomBarView addSubview:self.fullScreenSwitchButton];
    
    self.bottomBarBackView = [[UIView alloc] init];
    self.bottomBarBackView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:.2];
    [self.bottomBarBackView addSubview:self.bottomBarView];
    [self addSubview:self.bottomBarBackView];
}

- (void)hideBottomBar {
    [self doBottomBarBackViewConstraint:NO];
//    [self.bottomBarBackView mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.equalTo(self);
//        make.top.equalTo(self.mas_bottom);
//        make.height.equalTo(44);
//    }];
    
    //    self.snapshotButton.hidden = YES;
    //
    //    if (PLPlayerStatusPlaying == self.player.status ||
    //        PLPlayerStatusPaused == self.player.status ||
    //        PLPlayerStatusCaching == self.player.status) {
    //        [self showBottomProgressView];
    //    }
}

- (void)showBottomBar {
    [self doBottomBarBackViewConstraint:YES];
//    [self.bottomBarBackView mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.left.bottom.right.equalTo(self);
//        make.height.equalTo(44+ self.safeAreaInsets.bottom);
//    }];
    
    //  [self hideBottomProgressView];
}

-(void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    BOOL show = YES;
    if ( CGRectGetMinY(self.bottomBarBackView.frame) >= CGRectGetHeight(self.bounds)) {
        show = NO;
    }
    [self doBottomBarBackViewConstraint:show];
//
//    [self.bottomBarBackView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.equalTo(self);
//        make.left.equalTo(self);
//        make.top.equalTo(self.mas_bottom);
//        make.height.equalTo(44 + self.safeAreaInsets.bottom);
//    }];
}

- (void)doBottomBarBackViewConstraint:(BOOL)show {
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        edgeInsets = self.safeAreaInsets;
        NSLog(@"%@", NSStringFromUIEdgeInsets(edgeInsets));
        edgeInsets.left -= kH5VidelPlayViewBottomButtonSpace;
        edgeInsets.right -= kH5VidelPlayViewBottomButtonSpace;
        edgeInsets.left = MAX(edgeInsets.left, 0);
        edgeInsets.right = MAX(edgeInsets.right, 0);
    } else {
        // Fallback on earlier versions
    }
   
    [self.bottomBarBackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(0);
        if ( show ) {
            make.bottom.equalTo(self);
        } else {
            make.top.equalTo(self.mas_bottom);
        }
        make.height.equalTo(44);
    }];
    [self.bottomBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
        //make.left.equalTo(self.bottomBarBackView).offset(edgeInsets.left);
        make.right.equalTo(self.bottomBarBackView).offset(-edgeInsets.right);
        make.left.equalTo(edgeInsets.left);
       // make.right.equalTo(-edgeInsets.right);
        make.top.bottom.equalTo(0);
    }];
}

- (void)doBottomBarConstraint {
    
//    [self.bottomBarBackView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.equalTo(self);
//        make.top.equalTo(self.mas_bottom);
//       // make.height.equalTo(44 + self.safeAreaInsets.bottom);
//    }];
    
//    [self.bottomBarBackView mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.top.equalTo(0);
//        make.height.equalTo(44);
//    }];
    [self doBottomBarBackViewConstraint:NO];
    if ( !(self.playAndPauseButton.hidden) ) {
        [self.playAndPauseButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.bottomBarView);
            make.left.equalTo(self.bottomBarView).offset(kH5VidelPlayViewBottomButtonSpace);
            make.width.equalTo(self.playAndPauseButton.mas_height);
        }];
    }
    
    if ( !self.slider.hidden ) {
        [self.playTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            if ( self.playAndPauseButton.hidden ) {
                make.left.equalTo(kH5VidelPlayViewBottomButtonSpace);
            } else {
                make.left.equalTo(self.playAndPauseButton.mas_right);
            }
            make.width.equalTo(self.playTimeLabel.bounds.size.width);
            make.centerY.equalTo(self.bottomBarView);
        }];
        
        [self.slider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.bottomBarView);
            make.left.equalTo(self.playTimeLabel.mas_right).offset(5);
            make.right.equalTo(self.durationLabel.mas_left).offset(-5);
        }];
        
        [self.durationLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            if ( self.fullScreenSwitchButton.hidden && self.danmuSwitchView.hidden ) {
                make.right.top.bottom.equalTo(self.bottomBarView);
            } else if ( self.danmuSwitchView.hidden ) {
                make.right.equalTo(self.fullScreenSwitchButton.mas_left);
            } else {
                make.right.equalTo(self.danmuSwitchView.mas_left);
            }
            //make.right.equalTo(self.enterFullScreenButton.mas_left);
            make.centerY.equalTo(self.bottomBarView);
            make.size.equalTo(self.durationLabel.bounds.size);
        }];
    }
    
    if ( !self.danmuSwitchView.hidden ) {
        [self.danmuSwitchView mas_remakeConstraints:^(MASConstraintMaker *make) {
            if ( self.fullScreenSwitchButton.hidden ) {
                make.right.top.bottom.equalTo(self.bottomBarView);
            } else {
                make.right.equalTo(self.fullScreenSwitchButton.mas_left);
            }
            make.centerY.equalTo(self.bottomBarView);
            make.width.height.equalTo(44);
        }];
    }
    
    if ( !self.fullScreenSwitchButton.hidden ) {
        [self.fullScreenSwitchButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.equalTo(self.bottomBarView);
            make.width.equalTo(self.fullScreenSwitchButton.mas_height);
        }];
    }
    
}
#pragma mark - progress
- (void)manualSliderValueStart {
    self.lockAutoUpdateSlider = YES;
}

- (void)manualSliderValueEnd {
    self.lockAutoUpdateSlider = NO;
    float seekValue = MAX(self.slider.value, self.lastSlideProgress);
    [self seek:seekValue];
    dispatch_async(dispatch_get_main_queue(), ^{
       // [self doVideoPlayStop:seekValue];
    });
}

#pragma mark - event
- (void)onSliderTouchUp {
    [self manualSliderValueEnd];
    [self hideBarDelay];
}

- (void)onSliderTouchDown {
    [self manualSliderValueStart];
    [self cancelHideBar];
}

- (void)onSliderValueChange {
    self.playTimeLabel.text = [self foramtStringByPosition:self.slider.value];
}

- (void)onClickEnterFullScreenButton {
    [self requestFullScreen:self.setting.direction];
}

- (void)onClickPlayPauseSwitchButton {
    if ( [self.playAndPauseButton isNeedPlay] ) {
        [self __play];
    } else {
        [self __pause];
    }
   // if (UPAVPlayerStatusPause == self.videoPlayer.playerStatus) {
        //[self resume];
   // } else {
    
//    }
}

- (void)onClickCenterPlayPauseSwitchButton {
    [self turnOnPlayPauseButton:YES];
    [self onClickPlayPauseSwitchButton];
}

-(void)onClickRepeatPlay {
    [self.videoPlayOverlayView hideRepeatView];
    [self play];
    [self activeUI];
}

- (void)onDanmuSwitchViewValueChanged {
    if ( self.danmuSwitchView.selected ) {
        [self.danmakuManager play];
    } else {
        [self.danmakuManager pause];
    }
}

- (void)dismissBuffuingView {
    if ( self.isShowBuffingView ) {
        [SVProgressHUD dismiss];
    }
    self.isShowBuffingView = NO;
}

- (void)showBuffuingView {
    if ( !self.isShowBuffingView ) {
        [SVProgressHUD setContainerView:self.videoPlayer.playView];
        [SVProgressHUD setMinimumSize:CGSizeMake(20, 20)];
        [SVProgressHUD setRingThickness:4];
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
        [SVProgressHUD show];
    }
    self.isShowBuffingView = YES;
}

#pragma mark - UPAVPlayer delegate
- (void)player:(UPAVPlayer *)player playerError:(NSError *)error {
    [self dismissBuffuingView];
    [self turnOnPlayPauseButton:NO];
    if ( [self.delegate respondsToSelector:@selector(playerView:playerError:)] ) {
        [self.delegate playerView:self playerError:error];
    }
}

- (void)player:(id)player streamInfoDidReceive:(UPAVPlayerStreamInfo *)streamInfo {
    if (streamInfo.canPause && streamInfo.canSeek) {
        //判别为点播
        self.slider.enabled = YES;
        
        CGFloat fduration = streamInfo.duration;
        if ( self.setting.duration > 0) {
            fduration = self.setting.duration;
        }
        self.slider.maximumValue = fduration;
        self.durationLabel.text = [self foramtStringByPosition:fduration];// [NSString stringWithFormat:@"%d:%02d:%02d", hour, min, sec];
        if ( self.setting.isShowProgress ) {
            self.durationLabel.hidden = NO;
            self.slider.hidden = NO;
            self.playTimeLabel.hidden = NO;
        }
        //self.thumbImageView.hidden = YES;
    } else {
        //判别为直播流
        self.durationLabel.hidden = YES;
        self.slider.hidden = YES;
        self.playTimeLabel.hidden = YES;
        //self.durationLabel.text = [self foramtStringByPosition:0];
        self.slider.enabled = NO;
    }
//
//    NSArray *video = [streamInfo.descriptionInfo objectForKey:@"video"];
//    if (video.count > 0) {
//        NSLog(@"视频流: %@", video);
//    }
//    NSArray *audio = [streamInfo.descriptionInfo objectForKey:@"audio"];
//    if (audio.count > 0) {
//        NSLog(@"音频流: %@", audio);
//    }
//    NSArray *subtitles = [streamInfo.descriptionInfo objectForKey:@"subtitles"];
//    if (subtitles.count > 0) {
//        NSLog(@"字幕流: %@", subtitles);
//    }
}

- (void)player:(id)player displayPositionDidChange:(float)position {
    if ( !self.lockAutoUpdateSlider ) {
        if ( self.videoPlayer.streamInfo.duration > 0 ){
            self.slider.value = position;
        }
        self.playTimeLabel.text = [self foramtStringByPosition:position];
        if ( [self.delegate respondsToSelector:@selector(playerView:timeUpdate:total:)] ) {
            [self.delegate playerView:self timeUpdate:position total:self.videoPlayer.streamInfo.duration];
        }
    }
}

- (void)player:(UPAVPlayer *)player streamStatusDidChange:(UPAVStreamStatus)streamStatus {
    if ( UPAVStreamStatusReady == streamStatus ) {
        //self.thumbImageView.hidden = YES;
    }
}

- (void)player:(UPAVPlayer *)player playerStatusDidChange:(UPAVPlayerStatus)playerStatus {
    if ( UPAVPlayerStatusPlaying == playerStatus  ) {
        if ( !self.isPlayLoopRun ) {
            self.isPlayLoopRun = YES;
            if ( self.setting.initialTime > 0 ) {
                [self seek:self.setting.initialTime];
                //[self.videoPlayer seekToTime:self.setting.initialTime];
            }
            self.slider.enabled = YES;
        }
        [self dismissBuffuingView];
        self.thumbImageView.hidden = YES;
    } else if (UPAVPlayerStatusPlaying_buffering == playerStatus){
        [self.delegate playerViewBuffering:self];
        [self showBuffuingView];
    } else if ( UPAVPlayerStatusIdle == playerStatus ){
        if ( self.ingoreIdleAfterSeek) {
            self.ingoreIdleAfterSeek = NO;
            return;
        }
        if ( self.videoPlayer.streamInfo.canSeek ) {
             [self doVideoPlayStop];
        }
    } else if ( UPAVPlayerStatusFailed == playerStatus ){
        [self dismissBuffuingView];
    }
}

- (void)doVideoPlayStop {
   // if (self.videoPlayer.streamInfo.duration > 0 && self.videoPlayer.streamInfo.canSeek ) {
    //if (  floor(self.videoPlayer.streamInfo.duration - position) <= 1 ||self.videoPlayer.streamInfo.duration < position) {
            [self resetUI];
            if ( self.setting.isLoop ) {
                [self performSelector:@selector(onClickRepeatPlay) withObject:nil afterDelay:1];
            } else {
                [self.videoPlayOverlayView initRepeatViewWithText:[self foramtStringByPosition:self.videoPlayer.streamInfo.duration]];
                [self bringSubviewToFront:self.bottomBarBackView];
            }
            if ( [self.delegate respondsToSelector:@selector(playerViewEnded:)] ) {
                [self.delegate playerViewEnded:self];
            }
       // }
   // }
}

#pragma mark - tools
- (float)newValue:(float)curValue deltaValue:(float)deltaVlaue deltaReferenceValue:(float)deltaReferenceValue minValue:(float)minValue maxValue:(float)maxValue {
    CGFloat progressDelta = (deltaVlaue / deltaReferenceValue)*maxValue;
    curValue += (progressDelta)*1.5;
    curValue = MIN(maxValue, MAX(minValue, curValue));
    return curValue;
}

- (NSString*)foramtStringByPosition:(int)position {
    int hour = (int)position / 3600;
    int min  = ((int)position % 3600) / 60;
    int sec  = (int)position % 60;
    NSString *hourInString = hour?([NSString stringWithFormat:@"%d:", hour]):@"";
    return [NSString stringWithFormat:@"%@%02d:%02d", hourInString, min, sec];
}

- (H5VideoPlayOverlayView*)videoPlayOverlayView {
    if ( !_videoPlayOverlayView ) {
        _videoPlayOverlayView = [H5VideoPlayOverlayView new];
        _videoPlayOverlayView.delegate = self;
        [self addSubview:_videoPlayOverlayView];
        [_videoPlayOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return _videoPlayOverlayView;
}

- (H5DanmakuManager *)danmakuManager {
    if ( !_danmakuManager ) {
        _danmakuManager = [[H5DanmakuManager alloc] initWithView:self];
        [_danmakuManager prepareDanmakus];
        [_danmakuManager play];
    }
    return _danmakuManager;
}


@end
