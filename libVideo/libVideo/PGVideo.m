//
//  PGVideo.m
//  libVideo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "PGVideo.h"
#import "PGMethod.h"
#import "H5VideoContext.h"
#import "PDRCoreAppFramePrivate.h"
#import "PDRNView.h"
#import "PDRCommonString.h"
#import "PDRCoreAppFramePrivate.h"
#import "PDRCoreAppWindowPrivate.h"

@interface H5VideoPlaySetting(VidePlugin)
-(instancetype)initWithOptions:(NSDictionary*)options;
+ (H5VideoPlayDirection)directionFromObject:(id)value;
@end

@interface PGVideo()<H5VideoContextDelegate>{
    NSMutableDictionary *_allVideoPlayer;
}
@end

@implementation PGVideo
- (void)VideoPlayer:(PGMethod*)method {
    if ( !_allVideoPlayer ) {
        _allVideoPlayer = [[NSMutableDictionary alloc] init];
    }
    //uid
    NSString *uid = [method getArgumentAtIndex:0];
    //size 
    NSArray *frame = [method getArgumentAtIndex:1];
    CGFloat left = 0.f, top = 0.f, width = 0.f, height = .0f;
    if ( [frame count] ) {
        left   = [[frame objectAtIndex:0] floatValue];
        top    = [[frame objectAtIndex:1] floatValue];
        width  = [[frame objectAtIndex:2] floatValue];
        height = [[frame objectAtIndex:3] floatValue];
    }
    
    //styles
    NSDictionary *styles = [method getArgumentAtIndex:2];
    NSString *userId = [PGPluginParamHelper getStringValue:[method getArgumentAtIndex:3]];
    if ( ![styles isKindOfClass:[NSDictionary class]] ) {
        styles = nil;
    }
    NSMutableDictionary *newStyles = [NSMutableDictionary dictionaryWithDictionary:styles];
    if ( ![newStyles objectForKey:g_pdr_string_position] ) {
        [newStyles setObject:g_pdr_string_static forKey:g_pdr_string_position];
    }
    
    H5VideoPlaySetting *setting = [[H5VideoPlaySetting alloc] initWithOptions:newStyles];
    setting.url = [self h5Path2SysPath:setting.url];
    setting.poster = [self h5Path2SysPath:setting.poster];
    H5VideoContext *videoContext = [[H5VideoContext alloc] initWithFrame:CGRectMake(left, top, width, height) withSetting:setting withStyles:newStyles];
    videoContext.uid = uid;
    videoContext.userId = userId;
    [_allVideoPlayer setObject:videoContext forKey:uid];
    videoContext.delegate = self;
    videoContext.webviewId = [self JSFrameContextID];
    if ( !userId ) {
        [videoContext setHostedView:[self webviewScrollView]];
    }
}
#pragma mark - export
-(PDRNView*)__getNativeViewById:(NSString*)uuid {
    H5VideoContext *videoContext = [_allVideoPlayer objectForKey:uuid];
    return videoContext.videoPlayView;
}

-(H5VideoContext*)__getVideoContextByName:(NSString*)userId {
    __block H5VideoContext *retContext = nil;
    [_allVideoPlayer  enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, H5VideoContext* _Nonnull context, BOOL * _Nonnull stop) {
        if ( NSOrderedSame ==  [context.userId caseInsensitiveCompare:userId] ) {
            retContext = context;
            *stop = YES;
        }
    }];
    return retContext;
}

- (NSData*)getVideoPlayerById:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [self __getVideoContextByName:uid];
    return [self resultWithJSON:@{@"uid":videoPlayer.uid?:@"",@"name":videoPlayer.userId?:@""}];
}

- (void)resize:(PGMethod*)method {
    //uid
    NSString *uid = [method getArgumentAtIndex:0];
    NSArray *frame = [method getArgumentAtIndex:1];
    CGFloat left   = [[frame objectAtIndex:0] floatValue];
    CGFloat top    = [[frame objectAtIndex:1] floatValue];
    CGFloat width  = [[frame objectAtIndex:2] floatValue];
    CGFloat height = [[frame objectAtIndex:3] floatValue];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    [videoPlayer setFrame:CGRectMake(left, top, width, height)];
}

- (void)VideoPlayer_show:(PGMethod*)method {
    //uid
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    [videoPlayer.videoPlayView setHidden:NO];
}

- (void)VideoPlayer_hide:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    [videoPlayer.videoPlayView setHidden:YES];
}

- (void)VideoPlayer_play:(PGMethod*)method {
    //uid
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    [videoPlayer.videoPlayView play];
}

- (void)VideoPlayer_pause:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    [videoPlayer.videoPlayView pause];
}

- (void)VideoPlayer_close:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    if ( videoPlayer ) {
        [self.appContext.appWindow removeNView:videoPlayer.videoPlayView];
        [videoPlayer destroy];
        [_allVideoPlayer removeObjectForKey:uid];
    }
}

- (void)VideoPlayer_stop:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    if ( videoPlayer ) {
        [videoPlayer.videoPlayView stop];
    }
}

- (void)VideoPlayer_seek:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    float postion = [PGPluginParamHelper getFloatValue:[method getArgumentAtIndex:1] defalut:-1];
    if ( postion >=0 ) {
        H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
        [videoPlayer.videoPlayView seek:postion];
    }
}

- (void)VideoPlayer_sendDanmu:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    NSDictionary *danmu = [method getArgumentAtIndex:1];
    [self __sendDanmu:danmu toUid:uid];
}

- (void)__sendDanmu:(NSDictionary*)danmu toUid:(NSString*)uid {
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    if ( videoPlayer ) {
        [videoPlayer.videoPlayView sendDanmaku:danmu];
    }
}

- (void)VideoPlayer_playbackRate:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    int rate = [PGPluginParamHelper getFloatValue:[method getArgumentAtIndex:1] defalut:-1];
    if ( rate >=0 ) {
        H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
        [videoPlayer.videoPlayView playbackReate:rate];
    }
}

- (void)VideoPlayer_requestFullScreen:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoPlayDirection direction =  [H5VideoPlaySetting directionFromObject:[method getArgumentAtIndex:1]];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    
    [videoPlayer.videoPlayView requestFullScreen:direction];
}

- (void)VideoPlayer_exitFullScreen:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    [videoPlayer.videoPlayView exitFullScreen];
}

- (void)VideoPlayer_setOptions:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
    NSMutableDictionary *options = [method getArgumentAtIndex:1];
    if ( [options isKindOfClass:[NSMutableDictionary class]] && [options count] ) {
        [options enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ( [key isKindOfClass:[NSString class]] ) {
                key = [key lowercaseString];
                if ( [key isEqualToString:kH5VideoPlaySettingKeyDirection]) {
                    obj = @([H5VideoPlaySetting directionFromObject:obj]);
                    [videoPlayer.videoPlayView setControlValue:obj forKey:key];
                } else if ( [key isEqualToString:kH5VideoPlaySettingKeyDanmuList] ){
                    if ( [obj isKindOfClass:[NSArray class]] ) {
                        for ( NSDictionary *item in obj ) {
                            [self __sendDanmu:item toUid:uid];
                        }
                    }
                } else {
                    [videoPlayer.videoPlayView setControlValue:obj forKey:key];
                }
            }
        }];
    }
}

- (void)VideoPlayer_addEventListener:(PGMethod*)method {
    NSString *uid = [method getArgumentAtIndex:0];
    NSString *type = [method getArgumentAtIndex:1];
    if ( [type isKindOfClass:[NSString class]] && [type length] ) {
        type = [type lowercaseString];
        NSString *cbId = [method getArgumentAtIndex:2];
        H5VideoContext *videoPlayer = [_allVideoPlayer objectForKey:uid];
        [videoPlayer setListener:cbId forEvt:type forWebviewId:method.htmlID];
    }
}

- (void)onAppFrameWillClose:(PDRCoreAppFrame *)theAppframe {
    NSMutableArray *removeKeys = [NSMutableArray array];
    [_allVideoPlayer enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, H5VideoContext * _Nonnull videoContext, BOOL * _Nonnull stop) {
        if ( [videoContext.webviewId isEqualToString:theAppframe.frameID]
            ||(videoContext.videoPlayView.parent  && [videoContext.videoPlayView.parent isEqualToString:theAppframe.frameID])) {
            [videoContext destroy];
            [removeKeys addObject:key];
        }
    }];
    [_allVideoPlayer removeObjectsForKeys:removeKeys];
}

-(void)sendEvent:(NSString*)type toJsCallback:(NSString*)cbId withParams:(NSDictionary *)params inWebview:(NSString*)webId {
    [self toSucessCallback:cbId inWebview:webId withJSON:params?:@{} keepCallback:YES];
}

- (void)dealloc {
    [_allVideoPlayer enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, H5VideoContext * _Nonnull videoContext, BOOL * _Nonnull stop) {
        [videoContext destroy];
    }];
}
@end

@implementation H5VideoPlaySetting(VidePlugin)
-(instancetype)initWithOptions:(NSDictionary*)options {
    if ( self =[self init] ) {
        if ( [options isKindOfClass:[NSDictionary class]] && [options count] ) {
            self.url = [PGPluginParamHelper getStringValueInDict:options forKey:kH5VideoPlaySettingKeyUrl];
            self.initialTime = [PGPluginParamHelper getFloatValueInDict:options forKey:kH5VideoPlaySettingKeyInitialTime defalut:0];
            self.duration = [PGPluginParamHelper getFloatValueInDict:options forKey:kH5VideoPlaySettingKeyDuration defalut:0];
            self.isShowControls = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyControls defalut:self.isShowControls];
            self.enableDanmu = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyEanableDanmu defalut:self.enableDanmu];
            self.isAutoplay = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyAutoPlay defalut:self.isAutoplay];
            self.isShowDanmuBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyDanutBtn defalut:NO];
            
            //danmuku  Array<Danmu>, Danmu.text/Danmu.color，弹幕列表
            self.danmuList = [PGPluginParamHelper getArrayValueInDict:options forKey:kH5VideoPlaySettingKeyDanmuList defalut:nil];
            
            self.isLoop = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyLoop defalut:self.isLoop];
            self.isMuted = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyMuted defalut:self.isMuted];
            self.isEnablePageGesture = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyPageGesture defalut:self.isEnablePageGesture];
            
            self.direction = [H5VideoPlaySetting directionFromObject:[options objectForKey:kH5VideoPlaySettingKeyDirection]];
            self.isEnablePageGesture = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyShowProgress defalut:self.isEnablePageGesture];
            
            self.isShowFullscreenBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyShowFullScreenBtn defalut:self.isShowFullscreenBtn];
            self.isShowPlayBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyShowPlayBtn defalut:self.isShowPlayBtn];
            self.isShowCenterPlayBtn = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyShowCenterPlayBtn defalut:self.isShowCenterPlayBtn];
            self.isEnableProgressGesture = [PGPluginParamHelper getBoolValueInDict:options forKey:kH5VideoPlaySettingKeyShowProgressGresture defalut:self.isEnableProgressGesture];
            
            self.objectFit = [PGPluginParamHelper getEnumValue:[options objectForKey:kH5VideoPlaySettingKeyObjectFit] inMap:@{@"contain":@(H5VideObjectFitContain),
                                                                                                                              @"fill":@(H5VideObjectFitFill),
                                                                                                                              @"cover":@(H5VideObjectFitCover),
                                                                                                                              } defautValue:H5VideObjectFitContain];
            
            self.poster = [PGPluginParamHelper getStringValueInDict:options forKey:kH5VideoPlaySettingKeyPoster defalut:nil];
        }
    }
    return self;
}

+ (H5VideoPlayDirection)directionFromObject:(id)value {
    H5VideoPlayDirection direction = H5VideoPlayDirectionRight;
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
