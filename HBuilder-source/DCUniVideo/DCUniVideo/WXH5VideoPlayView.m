//
//  H5VideoPlayView.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/21.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "WXH5VideoPlayView.h"
#import "WXH5DirectionGestureRecognizer.h"
#import "WXH5VideoPlayOverlayView.h"
#import "Masonry.h"
#import "WXH5VideoBrightnessView.h"
#import "WXH5VideoVolumeView.h"
#import "WXH5DanmuSwitchView.h"
#import "WXH5DanmakuManager.h"
#import "PDRCore.h"
#import "PGPlugin.h"
#import "UIImageView+WXVideo.h"
#import "SVProgressHUD.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "WXConvert.h"

#define wxkH5VidelPlayViewAutoHideBarTimerinterval 8
#define wxkH5VidelPlayViewBottomButtonSpace 5

@interface WXH5SwitchButton(PlayOnPause)
- (BOOL)isNeedPlay;
@end

@implementation WXH5SwitchButton(PlayOnPause)
- (BOOL)isNeedPlay {
    return self.isOn;
}
@end

@interface WXH5VideoPlayView()< UIGestureRecognizerDelegate>
@property(nonatomic,strong) IJKFFMoviePlayerController * videoPlayer;
@property(nonatomic,assign) BOOL isStreamVideo;
@property(nonatomic,assign) BOOL isPlayError;
@property(nonatomic,retain) NSTimer * timer;

@property(nonatomic, strong)WXH5SwitchButton *playAndPauseButton;
@property(nonatomic, strong)WXH5SwitchButton *showMuteButton;
@property(nonatomic, strong)WXH5SwitchButton *fullScreenSwitchButton;
@property(nonatomic, strong)UISlider *slider;
@property(nonatomic, strong)UILabel *playTimeLabel;
@property(nonatomic, strong)UILabel *durationLabel;
@property(nonatomic, strong)WXH5DanmuSwitchView *danmuSwitchView;
@property(nonatomic, strong)UIView *bottomBarView;
@property(nonatomic, strong)UIView *bottomBarBackView;
@property(nonatomic, strong)WXH5DanmakuManager *danmakuManager;

@property(nonatomic, strong)UIImageView *thumbImageView;
@property (nonatomic, strong) UIButton *centerPlayButton;

@property (nonatomic, assign) UIInterfaceOrientation afterInterfaceOrientation;
@property (nonatomic, assign) UIInterfaceOrientation oldinterfaceOrientation;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) WXH5UIDirectionGestureRecognizer *directionGesture;
@property (nonatomic, strong) WXH5VideoPlayOverlayView *videoPlayOverlayView;
@property (nonatomic, assign) BOOL lockAutoUpdateSlider;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) BOOL restorePlay;
@property (nonatomic, strong)WXH5VideoPlaySetting *setting;
@property (nonatomic, strong)NSMutableArray<NSDictionary*> *dumaLists;
@property (nonatomic, assign)float lastSlideProgress;
@property(nonatomic, assign)BOOL isShowBuffingView;
//@property(nonatomic, assign)BOOL isShowBuffingView2;
@property(nonatomic, assign)BOOL isPlayLoopRun;
@property(nonatomic, assign)BOOL isPlayAfterShow;

@end

@implementation WXH5VideoPlayView
- (void)creatWithFrame:(CGRect)frame withSetting:(WXH5VideoPlaySetting*)setting withStyles:(NSDictionary*)styles{
//    if (  [super initWithFrame:frame withOptions:styles withJsContext:nil] ) {
        self.clipsToBounds = YES;
        self.frame = frame;
        [self appendDuma:setting.danmuList];
        self.setting = setting;
    
        [self initBottomBar];
        [self createPlayView];
    
        [self setUpBottomBar];
        [self doBottomBarConstraint];
        
        [self initOtherView];

        self.afterInterfaceOrientation = UIInterfaceOrientationUnknown;
        self.oldinterfaceOrientation = UIInterfaceOrientationLandscapeRight;
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        self.tapGesture.delegate = self;
        [self addGestureRecognizer:self.tapGesture];
        [self addGestrueControl];
        [self addSystemNotify];
//        [self addOrientationChangeNotify];
        self.isFirst = YES;
        self.isPlayLoopRun = NO;
//    }
    return ;
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

    IJKFFOptions * options = [IJKFFOptions optionsByDefault];
//    self.setting.url = @"rtsp://admin:123456789a@222.185.24.2:1554/h264/ch40/sub/av_stream";//[[NSBundle mainBundle]pathForResource:@"testqqq" ofType:@"mp4"];
//    @"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov"
//    self.setting.url = @"rtmp://58.200.131.2:1935/livetv/hunantv";
//    self.setting.url =@"https://img.cdn.aliyun.dcloud.net.cn/guide/uniapp/%E7%AC%AC1%E8%AE%B2%EF%BC%88uni-app%E4%BA%A7%E5%93%81%E4%BB%8B%E7%BB%8D%EF%BC%89-%20DCloud%E5%AE%98%E6%96%B9%E8%A7%86%E9%A2%91%E6%95%99%E7%A8%8B@20181126.mp4";
//    IJKMediaUrlOpenData * data = [[IJKMediaUrlOpenData alloc]initWithUrl:self.setting.url event:IJKMediaEvent_WillHttpOpen segmentIndex:0 retryCounter:3];
    NSURL *testURL = [NSURL URLWithString:self.setting.url];
    if ( testURL && testURL.scheme &&([testURL.scheme isEqualToString:@"rtmp"]||[testURL.scheme isEqualToString:@"rtsp"])) {
        self.isStreamVideo = YES;
        if ([testURL.scheme isEqualToString:@"rtsp"]) {
            [options setFormatOptionValue:@"tcp" forKey:@"rtsp_transport"];
        }
    }
    self.videoPlayer = [[IJKFFMoviePlayerController alloc]initWithContentURL:[NSURL URLWithString:self.setting.url]withOptions:options];
    if (self.setting.objectFit == WXH5VideObjectFitContain) {
        self.videoPlayer.scalingMode = IJKMPMovieScalingModeAspectFit;
    }else if(self.setting.objectFit == WXH5VideObjectFitFill){
        self.videoPlayer.scalingMode = IJKMPMovieScalingModeAspectFill;
    }else if(self.setting.objectFit == WXH5VideObjectFitCover){
        self.videoPlayer.scalingMode = IJKMPMovieScalingModeFill;
    }else{
        self.videoPlayer.scalingMode = IJKMPMovieScalingModeAspectFit;
    }
    
    if (self.setting.isMuted) {
        self.showMuteButton.on = YES;
        self.videoPlayer.playbackVolume = 0;
    }
    self.videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleHeight
        | UIViewAutoresizingFlexibleBottomMargin;
    self.videoPlayer.view.backgroundColor = [UIColor blackColor];
    [self.videoPlayer.view setFrame:self.bounds];
    [self insertSubview:self.videoPlayer.view atIndex:0];

    [self installMovieNotificationObservers];
}
-(void)installMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:self.videoPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:self.videoPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:self.videoPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.videoPlayer];
}
-(void)removeMovieNotificationObservers{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_videoPlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_videoPlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_videoPlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayer];
}
- (void)setFrame:(CGRect)frame {
    
    if (CGRectEqualToRect(self.frame, frame)) {
        return;
    }
    
    [super setFrame:frame];
    [self.videoPlayer.view setFrame:self.bounds];
    if (self.isShowBuffingView) {
        [self dismissBuffuingView];
        [self showBuffuingView];
    }
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
    if ([self isFullScreen]) {
    }
    [self doConstraintAnimation];
   // [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:nil];
    [self cancelHideBar];
    [self hideBarDelay];
}

- (void)hideBarDelay {
    [self performSelector:@selector(hideBar) withObject:nil afterDelay:wxkH5VidelPlayViewAutoHideBarTimerinterval];
}

- (void)cancelHideBar {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBar) object:nil];
}

- (void)hideBar {
    [self hideBottomBar];
    [self doConstraintAnimation];
}

- (void)doConstraintAnimation {
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    [UIView animateWithDuration:.3 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)activeUI {
    self.tapGesture.enabled = YES;
    self.directionGesture.enabled = YES;
}


- (void)turnOnPlayPauseButton:(BOOL)isPlaying {
    self.playAndPauseButton.on = isPlaying;
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
    [self removeMovieNotificationObservers];
}

- (void)appDidEnterBackground {
    if (_videoPlayer.playbackState == IJKMPMoviePlaybackStatePlaying) {
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

//-(void)addOrientationChangeNotify {
//    [self removeFullStreenNotify];
//     [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(onStatusBarOrientationChange)
//                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(onDeviceOrientationChange)
//                                                 name:UIDeviceOrientationDidChangeNotification
//                                               object:nil];
//}

//-(void)removeOrientationChangeNotify{
  //  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
//}

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
            if ( IJKMPMoviePlaybackStatePlaying == _videoPlayer.playbackState ) {
                [self __sendDanmaku:danmu];
            }else {
                [self appendDuma:@[danmu]];
            }
        }
    }
}

- (void)setControlValue:(id)value forKey:(NSString*)key {
   if ( [key isEqualToString:wxkH5VideoPlaySettingKeyPoster] ) {
        NSString *newPoster = (NSString*)value;
        if ( [newPoster isKindOfClass:[NSString class]] && NSOrderedSame != [newPoster caseInsensitiveCompare:self.setting.poster]) {
            if ( [newPoster length] > 0 ) {
                self.setting.poster = newPoster;
                [self createThumbImageView];
                if ( self.thumbImageView ) {
                    [self.thumbImageView wxh5Video_setImageUrl:self.setting.poster];
                }
            }
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyShowProgressGresture] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.isEnableProgressGesture = [WXConvert BOOL:value];
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyShowCenterPlayBtn] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.isShowCenterPlayBtn = [WXConvert BOOL:value];
            if ( self.videoPlayer.playableDuration == 0 ){
                self.centerPlayButton.hidden = !self.setting.isShowCenterPlayBtn;
            }
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyShowPlayBtn] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            if ( self.setting.isShowPlayBtn != [WXConvert BOOL:value]) {
                self.setting.isShowPlayBtn = [WXConvert BOOL:value];
                self.playAndPauseButton.hidden = !self.setting.isShowPlayBtn;
                [self doBottomBarConstraint];
            }
        }
    }else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyShowMuteBtn] ) {

        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            if ( self.setting.isShowMuteBtn != [WXConvert BOOL:value]) {
                self.setting.isShowMuteBtn = [WXConvert BOOL:value];
                self.showMuteButton.hidden = !self.setting.isShowMuteBtn;
                [self doBottomBarConstraint];
            }
        }
    }else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyShowFullScreenBtn] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            if ( self.setting.isShowFullscreenBtn != [WXConvert BOOL:value]) {
                self.setting.isShowFullscreenBtn = [WXConvert BOOL:value];
                self.fullScreenSwitchButton.hidden = !self.setting.isShowFullscreenBtn;
                [self doBottomBarConstraint];
            }
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyShowProgress] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            if ( self.setting.isShowProgress != [WXConvert BOOL:value]) {
                self.setting.isShowProgress = [WXConvert BOOL:value];
                self.slider.hidden = !self.setting.isShowProgress;
                self.durationLabel.hidden = self.slider.hidden;
                self.playTimeLabel.hidden = self.slider.hidden;
                [self doBottomBarConstraint];
            }
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyControls] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            if ( self.setting.isShowControls != [WXConvert BOOL:value]) {
                self.setting.isShowControls = [WXConvert BOOL:value];
                self.bottomBarBackView.hidden = !self.setting.isShowControls;
                [self doBottomBarConstraint];
            }
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyPageGesture] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.isEnablePageGesture = [WXConvert BOOL:value];
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyLoop] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.isLoop = [WXConvert BOOL:value];
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyInitialTime] ) {

        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.initialTime = [value floatValue];
        }
    }else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyAutoPlay] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.isAutoplay = [WXConvert BOOL:value];
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyMuted] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.isMuted = [WXConvert BOOL:value];
            if (self.setting.isMuted == YES) {
                _videoPlayer.playbackVolume = 0;
            }
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyDirection] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.direction = [value integerValue];
        }
    } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyDuration] ) {
        if ( [value isKindOfClass:[NSNumber class]] ||[value isKindOfClass:[NSString class]]) {
            self.setting.duration = [value floatValue];
            self.durationLabel.text = [self foramtStringByPosition:self.setting.duration ];
        }
    } else  if ( [key isEqualToString:wxkH5VideoPlaySettingKeyUrl] ) {
            NSString *newUrl = (NSString*)value;
            if ( [newUrl isKindOfClass:[NSString class]] && ![newUrl isEqualToString:self.setting.url]) {
                self.setting.url = newUrl;
                [self stop];
                if ( !self.setting.isAutoplay ) {
                    if ( self.setting.poster && !self.thumbImageView ) {
                        [self createThumbImageView];
                        [self.thumbImageView wxh5Video_setImageUrl:self.setting.poster];
                    }
                }
                if ( self.setting.isAutoplay ) {
                    [self play];
                }
            }
        }
}


#pragma mark - life cycle
//- (void)dc_setHidden:(BOOL)isHidden {
//    self.hidden = isHidden;
//    if ( self.hidden ) {
//        if ( IJKMPMoviePlaybackStatePlaying == self.videoPlayer.playbackState ) {
//            [self pause];
//            self.isPlayAfterShow = YES;
//        }
//    } else {
//        if ( self.isPlayAfterShow ) {
//            [self play];
//        }
//        self.isPlayAfterShow = NO;
//    }
//}

//- (void)updateLayout {
//    [self doBottomBarConstraint];
//}

- (void)resetUI {
    self.slider.enabled = NO;
    self.isPlayLoopRun = NO;
    self.slider.value = 0.0f;
    self.playTimeLabel.text = @"0:00:00";
    //    if (self.setting.isShowCenterPlayBtn == NO) {
    //        self.centerPlayButton.hidden = !self.setting.isShowCenterPlayBtn;
    //    }
    [self turnOnPlayPauseButton:NO];
    [self dismissBuffuingView];
    [self hideBar];
    self.isFirst = YES;
}
- (void)dealloc {
    
}

- (void)stop {
    [self resetUI];
    [self destroyPlayView];
    [self createPlayView];
    self.isPlayAfterShow = NO;
}
- (void)destroy {
    [self removeSystemNotify];
    //    [self removeOrientationChangeNotify];
    [self removeGestureRecognizer:self.tapGesture];
    [self removeGestureRecognizer:self.directionGesture];
    [_danmakuManager destroy];
    [self destroyPlayView];
    [self removeFromSuperview];
}

- (void)destroyPlayView {
    if (self.timer !=nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self.videoPlayer shutdown];
    [self.videoPlayer.view removeFromSuperview];
    self.videoPlayer = nil;
    self.isStreamVideo = NO;
    [self removeMovieNotificationObservers];
}
- (void)seek:(float)positon {
    [self showBuffuingView];
    self.videoPlayer.currentPlaybackTime = positon;
}

- (void)playbackReate:(int)rate {
    [self.videoPlayer setPlaybackRate:rate];
}

- (void)pause {
    [self turnOnPlayPauseButton:NO];
    [self __pause];
    self.isPlayAfterShow = NO;
}

- (void)__pause {
    // [self turnOnPlayPauseButton:NO];
    [self dismissBuffuingView];
    [self.videoPlayer pause];
    if ( [self.delegate respondsToSelector:@selector(playerViewPause:)] ) {
        [self.delegate playerViewPause:self];
    }
}
- (void)play {
    if ([self __play]) {
        self.directionGesture.enabled = YES;
        [self.videoPlayOverlayView hideRepeatView];
        [self turnOnPlayPauseButton:YES];
    }
    self.isPlayAfterShow = NO;
}
- (BOOL)__play {
    if ( !self.videoPlayer ) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"file not found"}];
        [self.delegate playerView:self playerError:error];
        return NO;
    }
    [self.videoPlayOverlayView hideRepeatView];
    self.centerPlayButton.hidden = YES;
    
    if (!(IJKMPMoviePlaybackStatePlaying == self.videoPlayer.playbackState)) {
        if (self.isPlayError == YES) {
            self.isPlayError= NO;
            [self stop];
        }else {//if(IJKMPMoviePlaybackStateStopped == self.videoPlayer.playbackRate)

        }
        if (self.videoPlayer.isPreparedToPlay == NO) {
            [self showBuffuingView];
            [self.videoPlayer prepareToPlay];
        }

        [self.videoPlayer play];
        
        if ( self.isFirst ) {
            self.isFirst = NO;
        }
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
            self.directionGesture = [[WXH5UIDirectionGestureRecognizer alloc] initWithTarget:self action:@selector(directionGesture:)];
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
    if (self.bottomBarBackView.frame.origin.y >= self.bounds.size.height) {
        [self showBar];
    } else {
        [self hideBar];
    }
}

-(void)directionGesture:(WXH5UIDirectionGestureRecognizer*)panGesture {
    if ( self.centerPlayButton && !self.centerPlayButton.hidden ) {
        return;
    }
    
    if ( UIGestureRecognizerStateBegan ==  panGesture.state ) {
        self.lastSlideProgress = self.videoPlayer.playableDuration;
    } else if ( UIGestureRecognizerStateChanged == panGesture.state ) {
        if ( [panGesture isHorizontal] ) {
            if ( self.setting.isEnableProgressGesture ) {
                if ( self.isStreamVideo == NO ) {
                    [self manualSliderValueStart];
                    //NSLog(@"directionGesture---[%f]",self.videoPlayer.displayPosition);
                    CGFloat value = [self newValue:self.lastSlideProgress//self.slider.value
                                        deltaValue:panGesture.delta.x deltaReferenceValue:CGRectGetWidth(self.bounds)
                                          minValue:0.0 maxValue:self.videoPlayer.duration];
                    self.slider.value = value;
                    self.lastSlideProgress = value;
                    NSString *seekInfo = [NSString stringWithFormat:@"%@/%@",[self foramtStringByPosition:value], [self foramtStringByPosition:self.videoPlayer.duration]];
                    [self.videoPlayOverlayView initProgressViewWithText:seekInfo];
                    [self.videoPlayOverlayView updateProgress:seekInfo];
                }
            }
        } else if ( [panGesture isVertical] ) {
            if ( self.isFullScreen/*|| (self.setting.isEnablePageGesture && !self.isFullScreen)*/) {
                if ( panGesture.beginPressPoint.x < CGRectGetMidX(self.bounds) ) {//调整亮度
                    CGFloat brightness = [UIScreen mainScreen].brightness;
                    CGFloat cureBright = [self newValue:brightness
                                             deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                                               minValue:0.01 maxValue:1.0];
                    [UIScreen mainScreen].brightness = cureBright;
                } else {//调整音量
                    CGFloat volume = [self newValue:self.videoPlayer.playbackVolume
                        deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                          minValue:0.00 maxValue:1.0];
                    [self.videoPlayer setPlaybackVolume:volume];
                    if (volume>0 && volume<0.1) {
                        [WXH5VideoVolumeView sharedView].volume = 0.1;
                    }else{
                        [WXH5VideoVolumeView sharedView].volume = volume;
                    }
                    if (self.videoPlayer.playbackVolume>0.00&&self.showMuteButton.hidden==NO) {
                        self.showMuteButton.on = NO;
                    }else if(!(self.videoPlayer.playbackVolume>0.00)&&self.showMuteButton.hidden==NO){
                        self.showMuteButton.on = YES;
                    }
                }
            }
        }
    } else if( UIGestureRecognizerStateEnded == panGesture.state
              || UIGestureRecognizerStateCancelled == panGesture.state ) {
        if ( [panGesture isHorizontal] ) {
            if ( self.setting.isEnableProgressGesture ) {
                if ( self.isStreamVideo ==NO ) {
                    [self.videoPlayOverlayView hideProgressView];
                    [self manualSliderValueEnd];
                }
            }
        } else if ( [panGesture isVertical] ) {
            if ( self.isFullScreen /*|| (self.setting.isEnablePageGesture && !self.isFullScreen)*/) {
                if ( panGesture.beginPressPoint.x < CGRectGetMidX(self.bounds) ) {//调整亮度
                    CGFloat brightness = [UIScreen mainScreen].brightness;
                    CGFloat cureBright = [self newValue:brightness
                                             deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
                                               minValue:0.01 maxValue:1.0];
                    [UIScreen mainScreen].brightness = cureBright;
                } else {//调整音量
//                    CGFloat volume = [self newValue:self.videoPlayer.playbackVolume
//                                        deltaValue:-panGesture.delta.y deltaReferenceValue:CGRectGetHeight(self.bounds)
//                                           minValue:0.00 maxValue:1.0];
//                    [self.videoPlayer setPlaybackVolume:volume];
//                    if (volume>0 && volume<0.1) {
//                        [WXH5VideoVolumeView sharedView].volume = 0.1;
//                    }else{
//                        [WXH5VideoVolumeView sharedView].volume = volume;
//                    }
//                    if (self.videoPlayer.playbackVolume>0.00&&self.showMuteButton.hidden==NO) {
//                        self.showMuteButton.on = NO;
//                    }else if(!(self.videoPlayer.playbackVolume>0.00)&&self.showMuteButton.hidden==NO){
//                        self.showMuteButton.on = YES;
//                    }
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

- (WXH5VideoBrightnessView*) brightnessView{
    return [WXH5VideoBrightnessView sharedView];
}
- (WXH5VideoVolumeView*) volumeView{
    return [WXH5VideoVolumeView sharedView];
}
#pragma mark - fullScreen
- (void)requestFullScreen:(WXH5VideoPlayDirection)direction {
    if ( !self.isFullScreen ) {
        [PDRCore lockScreen];
        self.isFullScreen = YES;
//        UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationLandscapeRight;
        if ( H5VideoPlayDirectionAuto == direction ) {
            if (UIDeviceOrientationLandscapeRight == [[UIDevice currentDevice]orientation]) {
                _oldinterfaceOrientation = UIInterfaceOrientationLandscapeRight;
                // [self transformWithOrientation:UIInterfaceOrientationLandscapeRight];
            } else {
                _oldinterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
                //  [self transformWithOrientation:UIInterfaceOrientationLandscapeLeft];
            }
        } else if ( H5VideoPlayDirectionLeft == direction ) {
            _oldinterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            //  [self transformWithOrientation:UIInterfaceOrientationLandscapeLeft];
        } else if (  H5VideoPlayDirectionRight == direction  ){
            _oldinterfaceOrientation = UIInterfaceOrientationLandscapeRight;
            // [self transformWithOrientation:UIInterfaceOrientationLandscapeRight];
        } else {
            _oldinterfaceOrientation = UIInterfaceOrientationPortrait;
            // [self transformWithOrientation:UIInterfaceOrientationPortrait];
        }
        self.afterInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self setFullScreenLayout:_oldinterfaceOrientation];
        [self transformWithOrientation:_oldinterfaceOrientation];
        [[PDRCore Instance] setHomeIndicatorAutoHidden:YES];
        [self.delegate playerViewEnterFullScreenNoDelay:self interfaceOrientation:_oldinterfaceOrientation];
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
    NSInteger index = [self.delegate playerViewExitFullScreen:self];
    [self transformWithOrientationWithExitFullScreen:self.afterInterfaceOrientation index:index];
    
    [self.delegate playerViewExitFullScreenNoDelay:self interfaceOrientation:self.afterInterfaceOrientation];
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
    
//    [[self volumeView] removeFromSuperview];
    [self addSubview:self.volumeView];
    [self.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(155);
    }];
//    [[self brightnessView] removeFromSuperview];
    [self addSubview:self.brightnessView];
    [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(155);
    }];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setExitFullScreenLayout {
    [self removeFromSuperview];
    [[self brightnessView].layer removeAllAnimations];
    [[self brightnessView] removeFromSuperview];
//    [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessView];
//    [self addSubview:self.brightnessView];
   
//    CGSize size =  [[UIScreen mainScreen] bounds].size;
//    [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.width.height.mas_equalTo(155);
//        make.leading.mas_equalTo((size.width -155)/2);
//        make.top.mas_equalTo((size.height-155)/2);
//    }];
    
    [[self volumeView].layer removeAllAnimations];
    [[self volumeView] removeFromSuperview];
////    [[UIApplication sharedApplication].keyWindow addSubview:self.volumeView];
//    [self.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
//        make.width.height.mas_equalTo(155);
//        make.leading.mas_equalTo((size.width -155)/2);
//        make.top.mas_equalTo((size.height-155)/2);
//    }];
}

- (void)transformWithOrientation:(UIInterfaceOrientation)newOrientation {
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if ( newOrientation == currentOrientation ){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.delegate playerViewEnterFullScreen:self interfaceOrientation:newOrientation];
        });
        return;
    }
    if ( newOrientation == UIInterfaceOrientationLandscapeLeft
        || newOrientation == UIInterfaceOrientationLandscapeRight ) {
        if ( currentOrientation == UIInterfaceOrientationPortrait) {
                [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    self.transform = UIInterfaceOrientationLandscapeLeft == newOrientation ? CGAffineTransformMakeRotation(-M_PI_2) : CGAffineTransformMakeRotation(M_PI_2);
                } completion:^(BOOL finished) {
                    [self.delegate playerViewEnterFullScreen:self interfaceOrientation:newOrientation];
                }];
        } else {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.transform = UIInterfaceOrientationLandscapeLeft == newOrientation ? CGAffineTransformMakeRotation(-M_PI) : CGAffineTransformMakeRotation(M_PI);
            } completion:^(BOOL finished) {
                [self.delegate playerViewEnterFullScreen:self interfaceOrientation:newOrientation];
            }];
        }
       // [self setNeedsUpdateConstraints];
       // [self doConstraintAnimation];
    } else {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [self.delegate playerViewEnterFullScreen:self interfaceOrientation:newOrientation];
        }];
    }
    [[UIApplication sharedApplication] setStatusBarOrientation:newOrientation animated:NO];
}

- (void)transformWithOrientationWithExitFullScreen:(UIInterfaceOrientation)newOrientation index:(NSInteger)index{
//    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( newOrientation == _oldinterfaceOrientation ){
        if(self.superview.superview.subviews.count>0){
            UIView * tsupview = self.superview.superview;
            for (UIView* view in self.superview.subviews) {
                if ([view isKindOfClass:[self.superview class]]) {
                    [self.superview removeFromSuperview];
                    [tsupview insertSubview:self.superview atIndex:index];
                }
            }
        }
      return;
    }
    
    [UIView animateWithDuration:.3 animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {        
        if(self.superview.superview.subviews.count>0){
            UIView * tsupview = self.superview.superview;
            for (UIView* view in self.superview.subviews) {
                if ([view isKindOfClass:[self.superview class]]) {
                    [self.superview removeFromSuperview];
                    [tsupview insertSubview:self.superview atIndex:index];
                }
            }
        }
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

//- (void)onStatusBarOrientationChange {
//    if (self.isShowBuffingView) {
//        [self dismissBuffuingView];        [
//        self.isShowBuffingView2 = YES;
//    }
//    return;
//}


- (UIWindow*)hostWindow {
    return [UIApplication sharedApplication].keyWindow;
}

#pragma mark - otherView
- (void)createThumbImageView {
    if ( !self.setting.isAutoplay ) {
        if ( !self.thumbImageView&&self.videoPlayer.view) {
            self.thumbImageView = [[UIImageView alloc] init];
            self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.clipsToBounds = YES;
            [self.videoPlayer.view addSubview:self.thumbImageView];
            [self.thumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.videoPlayer.view);
            }];
        }
    }
}

- (void)initOtherView {
    if ( !self.setting.isAutoplay ) {
        if ( self.setting.poster ) {
            [self createThumbImageView];
            [self.thumbImageView wxh5Video_setImageUrl:self.setting.poster];
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
    self.showMuteButton.hidden = !self.setting.isShowMuteBtn;
    self.slider.hidden = self.durationLabel.hidden = self.playTimeLabel.hidden = !self.setting.isShowProgress;
    self.slider.hidden = !self.setting.isShowProgress;
    self.fullScreenSwitchButton.hidden = !self.setting.isShowFullscreenBtn;
    self.danmuSwitchView.hidden = !(self.setting.enableDanmu && self.setting.isShowDanmuBtn);
}

- (void)initBottomBar {

    self.bottomBarView = [[UIView alloc] init];
    self.bottomBarView.backgroundColor = [UIColor clearColor];
    
    self.playAndPauseButton = [WXH5SwitchButton new];
    [self.playAndPauseButton setOffImage:[UIImage imageNamed:@"player_play"]];
    [self.playAndPauseButton setOnImage:[UIImage imageNamed:@"player_stop"]];
    [self.playAndPauseButton addTarget:self action:@selector(onClickPlayPauseSwitchButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.showMuteButton = [WXH5SwitchButton new];
    [self.showMuteButton setOffImage:[UIImage imageNamed:@"video_ic_muteon"]];
    [self.showMuteButton setOnImage:[UIImage imageNamed:@"video_ic_muteoff"]];
    [self.showMuteButton addTarget:self action:@selector(onClickisMuteSwitchButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.playTimeLabel = [[UILabel alloc] init];
    self.playTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.playTimeLabel.font = [UIFont systemFontOfSize:12];
    if (@available(iOS 9, *)) {
        self.playTimeLabel.font= [UIFont monospacedDigitSystemFontOfSize:12 weight:(UIFontWeightRegular)];
    }
    self.playTimeLabel.textColor = [UIColor whiteColor];
    self.playTimeLabel.text = @"0:00:00";
    [self.playTimeLabel sizeToFit];
    
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.textAlignment = NSTextAlignmentCenter;
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
    
    self.danmuSwitchView = [WXH5DanmuSwitchView new];
    [self.danmuSwitchView setSelected:YES];
    [self.danmuSwitchView addTarget:self action:@selector(onDanmuSwitchViewValueChanged) forControlEvents:(UIControlEventValueChanged)];
    
    self.fullScreenSwitchButton = [WXH5SwitchButton new];
    [self.fullScreenSwitchButton setOffImage:[UIImage imageNamed:@"full-screen"]];
    [self.fullScreenSwitchButton setOnImage:[UIImage imageNamed:@"exitfullscreen"]];
    [self.fullScreenSwitchButton addTarget:self action:@selector(onClickEnterFullScreenButton) forControlEvents:(UIControlEventValueChanged)];
    
    [self.bottomBarView addSubview:self.playAndPauseButton];
    [self.bottomBarView addSubview:self.showMuteButton];
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
}

- (void)showBottomBar {
    [self doBottomBarBackViewConstraint:YES];
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
        edgeInsets.left -= wxkH5VidelPlayViewBottomButtonSpace;
        edgeInsets.right -= wxkH5VidelPlayViewBottomButtonSpace;
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
            make.left.equalTo(self.bottomBarView).offset(wxkH5VidelPlayViewBottomButtonSpace);
//            make.width.equalTo(self.playAndPauseButton.mas_height);
            make.width.equalTo(40);
        }];
        [self.playAndPauseButton.imageview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(20);
        }];
    }
    
    if ( !self.slider.hidden ) {
        [self.playTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            if ( self.playAndPauseButton.hidden ) {
                make.left.equalTo(wxkH5VidelPlayViewBottomButtonSpace);
            } else {
                make.left.equalTo(self.playAndPauseButton.mas_right);
            }
            
            make.width.equalTo(self.playTimeLabel.bounds.size.width);//self.playTimeLabel.bounds.size.width
            make.centerY.equalTo(self.bottomBarView);
        }];
        
        [self.slider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.bottomBarView);
            make.left.equalTo(self.playTimeLabel.mas_right).offset(wxkH5VidelPlayViewBottomButtonSpace);
            make.right.equalTo(self.durationLabel.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
        }];
        
        [self.durationLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            if ( self.fullScreenSwitchButton.hidden && self.danmuSwitchView.hidden && self.showMuteButton.hidden) {
                make.right.top.bottom.equalTo(self.bottomBarView).offset(-10);
            }else if ( self.showMuteButton.hidden && self.danmuSwitchView.hidden) {
                make.right.equalTo(self.fullScreenSwitchButton.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
            }else if (self.danmuSwitchView.hidden){
                make.right.equalTo(self.showMuteButton.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
            } else {
                make.right.equalTo(self.danmuSwitchView.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
            }
            make.centerY.equalTo(self.bottomBarView);
            make.width.equalTo(self.durationLabel.bounds.size.width);
        }];
    }
    
    if ( !self.danmuSwitchView.hidden ) {
        [self.danmuSwitchView mas_makeConstraints:^(MASConstraintMaker *make) {
            if ( self.showMuteButton.hidden && self.fullScreenSwitchButton.hidden) {
                make.right.top.bottom.equalTo(self.bottomBarView).offset(-10);
            }else if (self.showMuteButton.hidden ){
                make.right.equalTo(self.fullScreenSwitchButton.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
            }else {
                make.right.equalTo(self.showMuteButton.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
            }
            make.centerY.equalTo(self.bottomBarView);
            make.width.equalTo(50);
            make.height.equalTo(44);
        }];
    }
    if (!self.showMuteButton.hidden) {
        [self.showMuteButton mas_makeConstraints:^(MASConstraintMaker *make) {
            if (self.fullScreenSwitchButton.hidden) {
                make.right.equalTo(self.bottomBarView).offset(-10);
            }else{
                make.right.equalTo(self.fullScreenSwitchButton.mas_left).offset(-wxkH5VidelPlayViewBottomButtonSpace);
            }
            make.top.bottom.equalTo(self.bottomBarView);
            make.width.equalTo(32);
        }];
        [self.showMuteButton.imageview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(24);
            make.height.equalTo(24);
        }];
    }
    
    if ( !self.fullScreenSwitchButton.hidden ) {
        [self.fullScreenSwitchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.bottomBarView);
            make.right.equalTo(self.bottomBarView).offset(-15);
            make.width.equalTo(32);
        }];
        [self.fullScreenSwitchButton.imageview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(22);
            make.height.equalTo(22);
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
        [self turnOnPlayPauseButton:YES];
    } else {
        [self __pause];
    }
}
-(void)onClickisMuteSwitchButton{
    if (self.showMuteButton.on) {
        self.showMuteButton.on = YES;
        self.videoPlayer.playbackVolume = 0;
    }else{
        self.showMuteButton.on = NO;
        self.videoPlayer.playbackVolume = 1;
    }
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
        [SVProgressHUD setContainerView:self.videoPlayer.view];
        [SVProgressHUD setMinimumSize:CGSizeMake(20, 20)];
        [SVProgressHUD setRingThickness:4];
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
        [SVProgressHUD show];
    }
    self.isShowBuffingView = YES;
}
#pragma mark - 通知
- (void)loadStateDidChange:(NSNotification*)notification
{
    IJKMPMovieLoadState loadState = self.videoPlayer.loadState;
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        [self dismissBuffuingView];
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        [self showBuffuingView];
        [self.delegate playerViewBuffering:self];
//        NSInteger n =  self.videoPlayer.bufferingProgress;
    } else {
//        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason){
        case IJKMPMovieFinishReasonPlaybackEnded:
            [self dismissBuffuingView];
            [self turnOnPlayPauseButton:NO];
            if ( self.isStreamVideo==NO ) {
                [self doVideoPlayStop];
            }
            break;
            
        case IJKMPMovieFinishReasonUserExited:
//            [self dismissBuffuingView];
//            [self turnOnPlayPauseButton:NO];
//            if ( self.isStreamVideo==NO ) {
//                if ( [self.delegate respondsToSelector:@selector(playerViewEnded:)] ) {
//                    [self.delegate playerViewEnded:self];
//                }
//            }
//            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
                [self.timer setFireDate:[NSDate distantFuture]];
                [self dismissBuffuingView];
                [self turnOnPlayPauseButton:NO];
                if ( [self.delegate respondsToSelector:@selector(playerView:playerError:)] ) {
                    [self.delegate playerView:self playerError:nil];
                }
            self.isPlayError = YES;
            break;
            
        default:
//            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    if (self.isStreamVideo == NO) {
        //判别为点播
        self.slider.enabled = YES;
        CGFloat fduration = self.videoPlayer.duration;
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
    } else {//判别为直播流
        self.durationLabel.hidden = YES;
        self.slider.hidden = YES;
        self.playTimeLabel.hidden = YES;
        //self.durationLabel.text = [self foramtStringByPosition:0];
        self.slider.enabled = NO;
    }
    
}
-(void)videoPlayerisPlaying{
    if ( !self.lockAutoUpdateSlider ) {
        if ( self.videoPlayer.duration > 0 ){
            self.slider.value = self.videoPlayer.currentPlaybackTime;
        }
        self.playTimeLabel.text = [self foramtStringByPosition:self.videoPlayer.currentPlaybackTime];

        if ( [self.delegate respondsToSelector:@selector(playerView:timeUpdate:total:)] ) {
            [self.delegate playerView:self timeUpdate:self.videoPlayer.currentPlaybackTime total:self.videoPlayer.duration];
        }
    }
}
- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    switch (self.videoPlayer.playbackState){
        case IJKMPMoviePlaybackStateStopped: {
            [self.timer setFireDate:[NSDate distantFuture]];
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            if (self.videoPlayer.isPlaying && self.timer ==nil) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(videoPlayerisPlaying) userInfo:nil repeats:YES];
            }else{
                [self.timer setFireDate:[NSDate distantPast]];
            }
            if ( !self.isPlayLoopRun ) {
                self.isPlayLoopRun = YES;
                if ( self.setting.initialTime > 0 ) {
                    [self seek:self.setting.initialTime];
                }
                self.slider.enabled = YES;
            }
            [self dismissBuffuingView];
            self.thumbImageView.hidden = YES;
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            [self.timer setFireDate:[NSDate distantFuture]];
            [self dismissBuffuingView];
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            [self.timer setFireDate:[NSDate distantFuture]];
            [self dismissBuffuingView];
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:{
            break;
        }
        case IJKMPMoviePlaybackStateSeekingBackward: {
            break;
        }
        default: {
//            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)(self.videoPlayer.playbackState));
            break;
        }
    }
}


/////////////////////////////
- (void)doVideoPlayStop {
    [self resetUI];
    self.directionGesture.enabled = NO;
    [self.timer setFireDate:[NSDate distantFuture]];
    if ( self.setting.isLoop ) {
        [self performSelector:@selector(onClickRepeatPlay) withObject:nil afterDelay:1];
    } else {
        [self.videoPlayOverlayView initRepeatViewWithText:[self foramtStringByPosition:self.videoPlayer.duration]];
        [self bringSubviewToFront:self.bottomBarBackView];
    }
    if ( [self.delegate respondsToSelector:@selector(playerViewEnded:)] ) {
        [self.delegate playerViewEnded:self];
    }
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

- (WXH5VideoPlayOverlayView*)videoPlayOverlayView {
    if ( !_videoPlayOverlayView ) {
        _videoPlayOverlayView = [WXH5VideoPlayOverlayView new];
        _videoPlayOverlayView.delegate = self;
        [self addSubview:_videoPlayOverlayView];
        [_videoPlayOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return _videoPlayOverlayView;
}

- (WXH5DanmakuManager *)danmakuManager {
    if ( !_danmakuManager ) {
        _danmakuManager = [[WXH5DanmakuManager alloc] initWithView:self];
        [_danmakuManager prepareDanmakus];
        [_danmakuManager play];
    }
    return _danmakuManager;
}


@end
