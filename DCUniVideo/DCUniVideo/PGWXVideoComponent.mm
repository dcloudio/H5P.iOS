//
//  PGWXVideoComponent.m
//  DCUniVideo
//
//  Created by 4Ndf on 2019/4/15.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#import "PGWXVideoComponent.h"
#import "WXConvert.h"
#import "WXComponent+Layout.h"

#import "PDRToolSystemEx.h"
#import "PGPlugin.h"
#import "PDRCommonString.h"
#import "PTPathUtil.h"
#import "PDRCore.h"
#import "PDRCoreAppManager.h"

#import "WXH5VideoContext.h"
#import "WXH5VideoPlaySetting.h"

@interface WXH5VideoPlaySetting(WXVidePlugin)
-(instancetype)initWithOptions:(NSDictionary*)options;
+ (WXH5VideoPlayDirection)directionFromObject:(id)value;
@end

@interface PGWXVideoComponent()<WXH5VideoContextDelegate>{
    WXH5VideoPlaySetting * _setting;
    BOOL _isplay;
    BOOL _ispause;
    BOOL _isended;
    BOOL _istimeupdate;
    BOOL _isfullscreenchange;
    BOOL _iswaiting;
    BOOL _iserror;
    
    CGSize _initViewSize;
}
@property(nonatomic,retain)NSDictionary * pattributes;
@property(nonatomic,retain)WXH5VideoContext* videoContext;
@property (nonatomic, weak) WXComponent *subCoverView;

@end

@implementation PGWXVideoComponent

WX_EXPORT_METHOD(@selector(play))
WX_EXPORT_METHOD(@selector(pause))
WX_EXPORT_METHOD(@selector(stop))
//WX_EXPORT_METHOD(@selector(hide))
//WX_EXPORT_METHOD(@selector(show))
WX_EXPORT_METHOD(@selector(playbackRate:))
WX_EXPORT_METHOD(@selector(seek:))
WX_EXPORT_METHOD(@selector(sendDanmu:))
WX_EXPORT_METHOD(@selector(requestFullScreen:))
WX_EXPORT_METHOD(@selector(exitFullScreen))
//WX_EXPORT_METHOD(@selector(close))
//WX_EXPORT_METHOD(@selector(setOptions:))
//WX_EXPORT_METHOD(@selector(setStyles:))


- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance {
    if(self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance]) {
        _pattributes  = attributes;
    }
    
    return self;
}
-(UIView *)loadView{
    if (!_videoContext) {
        _videoContext = [self VideoPlayer];
    }    
    return _videoContext.videoPlayView;
}
- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    // 设置默认宽高
    [self dc_setDefaultWidthPixel:300 defaultHeightPixel:225];
    
    [_videoContext creatFrame:self.view.frame withSetting:_setting withStyles:nil];
    if (self.weexInstance.rootView.subviews.count>0) {
        [_videoContext setHostedView:self.weexInstance.rootView.subviews[0]];
    }
}

// 全屏切换的时候动态调整 u-scalable 子标签以适应新的布局
- (void)fullscreenchange:(BOOL)isFullScreen {
    
    if (!self.subCoverView) {
        return;
    }
    
    if (isFullScreen) {
        [self.subCoverView dc_updateStyles:@{
                                @"width" : @([UIScreen mainScreen].bounds.size.width),
                                @"height" : @([UIScreen mainScreen].bounds.size.height)
                                }];
    } else {
        [self.subCoverView dc_updateStyles:@{
                                @"width" : @(_initViewSize.width),
                                @"height" : @(_initViewSize.height)
                                }];
    }
}

- (void)insertSubview:(WXComponent *)subcomponent atIndex:(NSInteger)index {
    
    // u-scalable 对用户不可见，只是为了方便调整布局，顾不响应手势例：video 中添加cover-view 子标签会自动包一层 u-scalable
    if (![subcomponent.type isEqualToString:@"u-scalable"]) {
        return;
    }
    
    // 记录 u-scalable
    [super insertSubview:subcomponent atIndex:index];
    self.subCoverView = subcomponent;
    _initViewSize = self.calculatedFrame.size;
    [self fullscreenchange:NO];
    [self.view bringSubviewToFront:subcomponent.view];
}

- (void)updateAttributes:(NSDictionary *)attributes{
    [self setOptions:attributes];
}
- (void)addEvent:(NSString *)eventName {
    if ([eventName isEqualToString:@"play"]) {
        _isplay = YES;
    }
    if ([eventName isEqualToString:@"pause"]) {
        _ispause = YES;
    }
    if ([eventName isEqualToString:@"ended"]) {
        _isended = YES;
    }
    if ([eventName isEqualToString:@"timeupdate"]) {
        _istimeupdate = YES;
    }
    if ([eventName isEqualToString:@"fullscreenchange"]) {
        _isfullscreenchange = YES;
    }
    if ([eventName isEqualToString:@"waiting"]) {
        _iswaiting = YES;
    } if ([eventName isEqualToString:@"error"]) {
        _iserror = YES;
    }
}
- (void)removeEvent:(NSString *)eventName{
    if ([eventName isEqualToString:@"play"]) {
        _isplay = NO;
    }
    if ([eventName isEqualToString:@"pause"]) {
        _ispause = NO;
    }
    if ([eventName isEqualToString:@"ended"]) {
        _isended = NO;
    }
    if ([eventName isEqualToString:@"timeupdate"]) {
        _istimeupdate = NO;
    }
    if ([eventName isEqualToString:@"fullscreenchange"]) {
        _isfullscreenchange = NO;
    }
    if ([eventName isEqualToString:@"waiting"]) {
        _iswaiting = NO;
    } if ([eventName isEqualToString:@"error"]) {
        _iserror = NO;
    }
}

#pragma mark -
- (WXH5VideoContext*)VideoPlayer{
    _setting = [[WXH5VideoPlaySetting alloc] initWithOptions:_pattributes];

    PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
    
//    NSString * relFilePath = [PTPathUtil relativePath:url withContext:coreApp];//
//    NSString * frrr =  [PTPathUtil absolutePath:url withContext:coreApp];
//    NSString * aa = [PTPathUtil h5Path2SysPath:url basePath:self.weexInstance.scriptURL.absoluteString context:coreApp];
    
    NSString * urlPath = [PTPathUtil h5Path2SysPath:_setting.url basePath:coreApp.workRootPath context:coreApp];
    NSString * posterPath = [PTPathUtil h5Path2SysPath:_setting.poster basePath:coreApp.workRootPath context:coreApp];
    _setting.url = urlPath;//[self h5Path2SysPath:setting.url];
    _setting.poster = posterPath;//[self h5Path2SysPath:setting.poster];
    
    _videoContext = [[WXH5VideoContext alloc] initWithFrame:CGRectZero];
    _videoContext.delegate = self;
    
    return _videoContext;
}

#pragma mark - export
- (void)show{
    [_videoContext setHidden:NO];
}

- (void)hide{
      [_videoContext.videoPlayView pause];
    [_videoContext setHidden:YES];
}

- (void)play{
    [_videoContext.videoPlayView play];
}

- (void)pause {
    [_videoContext.videoPlayView pause];
}

- (void)close {
    if ( _videoContext ) {
        [_videoContext destroy];
    }
}

- (void)stop {
    if ( _videoContext ) {
        [_videoContext.videoPlayView stop];
    }
}

- (void)seek:(NSNumber *)method {
    float postion = [PGPluginParamHelper getFloatValue:method defalut:-1];
    if ( postion >=0 ) {
        [_videoContext.videoPlayView seek:postion];
    }
}

- (void)sendDanmu:(NSDictionary*)method {
    [self __sendDanmu:method];
}

- (void)__sendDanmu:(NSDictionary*)danmu{
    if ( _videoContext ) {
        [_videoContext.videoPlayView sendDanmaku:danmu];
    }
}

- (void)clearDanmuForUid{
    if ( _videoContext ) {
        [_videoContext.videoPlayView clearDanmaku];
    }
}

- (void)playbackRate:(NSNumber*)method {
    int rate = [PGPluginParamHelper getFloatValue:method defalut:-1];
    if ( rate >=0 ) {
        [_videoContext.videoPlayView playbackReate:rate];
    }
}

- (void)requestFullScreen:(NSDictionary *)method {
    NSNumber * direction = [method objectForKey:@"direction"];
    WXH5VideoPlayDirection pdirection =  [WXH5VideoPlaySetting directionFromObject:direction];
    [_videoContext.videoPlayView requestFullScreen:pdirection];
}

- (void)exitFullScreen {
    [_videoContext.videoPlayView exitFullScreen];
}

- (void)setOptions:(NSDictionary*)method {
    NSMutableDictionary * options = [NSMutableDictionary dictionaryWithDictionary:method];
    if ( [options isKindOfClass:[NSMutableDictionary class]] && [options count] ) {
        [options enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ( [key isKindOfClass:[NSString class]] ) {
                key = [key lowercaseString];
                if ( [key isEqualToString:wxkH5VideoPlaySettingKeyDirection]) {
                    obj = @([WXH5VideoPlaySetting directionFromObject:obj]);
                    [self.videoContext.videoPlayView setControlValue:obj forKey:key];
                } else if ( [key isEqualToString:wxkH5VideoPlaySettingKeyDanmuList] ){
                    [self clearDanmuForUid];
                    if ( [obj isKindOfClass:[NSArray class]] ) {
                        for ( NSDictionary *item in obj ) {
                            [self __sendDanmu:item];
                        }
                    }
                } else {
                    [self.videoContext.videoPlayView setControlValue:obj forKey:key];
                }
            }
        }];
    }
}

- (void)videoPlayerEnterFullScreen {
    [self fullscreenchange:YES];
}

- (void)videoPlayerExitFullScreen {
    [self fullscreenchange:NO];
}

-(void)sendEvent:(NSString*)type withParams:(NSDictionary *)params{
   
    if (_isplay && [type isEqualToString:@"play"]) {
        [self fireEvent:@"play" params:params?:@{}];
        return;
    }
    if (_ispause && [type isEqualToString:@"pause"]) {
        [self fireEvent:@"pause" params:params?:@{}];
        return;
    }
    if (_isended && [type isEqualToString:@"ended"]) {
        [self fireEvent:@"ended" params:params?:@{}];
        return;
    }
    if (_istimeupdate && [type isEqualToString:@"timeupdate"]) {
        [self fireEvent:@"timeupdate" params:params?:@{}];
        return;
    }
    if (_isfullscreenchange && [type isEqualToString:@"fullscreenchange"]) {
        [self fireEvent:@"fullscreenchange" params:params?:@{}];
        return;
    }
    if (_iswaiting && [type isEqualToString:@"waiting"]) {
        [self fireEvent:@"waiting" params:params?:@{}];
        return;
    }
    if (_iserror && [type isEqualToString:@"error"]) {
        [self fireEvent:@"error" params:params?:@{}];
        return;
    }
}

- (void)dealloc {
        [_videoContext destroy];
}
@end

@implementation WXH5VideoPlaySetting(WXVidePlugin)
-(instancetype)initWithOptions:(NSDictionary*)options {
    if ( self =[self init] ) {
        if ( [options isKindOfClass:[NSDictionary class]] && [options count] ) {
            self.url = [PGPluginParamHelper getStringValueInDict:options forKey:wxkH5VideoPlaySettingKeyUrl];
            self.initialTime = [PGPluginParamHelper getFloatValueInDict:options forKey:wxkH5VideoPlaySettingKeyInitialTime defalut:0];
            self.duration = [PGPluginParamHelper getFloatValueInDict:options forKey:wxkH5VideoPlaySettingKeyDuration defalut:0];
            self.isShowControls = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyControls defalut:self.isShowControls];
            self.enableDanmu = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyEanableDanmu defalut:self.enableDanmu];
            self.isAutoplay = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyAutoPlay defalut:self.isAutoplay];
            self.isShowDanmuBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyDanutBtn defalut:NO];
            
            //danmuku  Array<Danmu>, Danmu.text/Danmu.color，弹幕列表
            self.danmuList = [PGPluginParamHelper getArrayValueInDict:options forKey:wxkH5VideoPlaySettingKeyDanmuList defalut:nil];
            
            self.isLoop = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyLoop defalut:self.isLoop];
            self.isMuted = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyMuted defalut:self.isMuted];
            self.isEnablePageGesture = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyPageGesture defalut:self.isEnablePageGesture];
            
            self.direction = [WXH5VideoPlaySetting directionFromObject:[options objectForKey:wxkH5VideoPlaySettingKeyDirection]];
            self.isEnablePageGesture = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyShowProgress defalut:self.isEnablePageGesture];
            
            self.isShowFullscreenBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyShowFullScreenBtn defalut:self.isShowFullscreenBtn];
            self.isShowPlayBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyShowPlayBtn defalut:self.isShowPlayBtn];
            self.isShowMuteBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyShowMuteBtn defalut:self.isShowMuteBtn];
            self.isShowCenterPlayBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyShowCenterPlayBtn defalut:self.isShowCenterPlayBtn];
            self.isEnableProgressGesture = [PGPluginParamHelper getBoolValueInDict:options forKey:wxkH5VideoPlaySettingKeyShowProgressGresture defalut:self.isEnableProgressGesture];
            self.objectFit = [PGPluginParamHelper getEnumValue:[options objectForKey:wxkH5VideoPlaySettingKeyObjectFit] inMap:@{@"contain":@(WXH5VideObjectFitContain),@"fill":@(WXH5VideObjectFitFill),@"cover":@(WXH5VideObjectFitCover)} defautValue:WXH5VideObjectFitContain];
            
            self.poster = [PGPluginParamHelper getStringValueInDict:options forKey:wxkH5VideoPlaySettingKeyPoster defalut:nil];
        }
    }
    return self;
}

+ (WXH5VideoPlayDirection)directionFromObject:(id)value {
    WXH5VideoPlayDirection direction = H5VideoPlayDirectionRight;
    int dir = [PGPluginParamHelper getIntValue:value defalut:-1];
    switch (dir) {
        case 0:
            direction = H5VideoPlayDirectionNormal;
            break;
        case 90:
            direction = H5VideoPlayDirectionLeft;
            break;
        case -90:
            direction = H5VideoPlayDirectionRight;
            break;
        default:
            break;
    }
    return direction;
}
@end
