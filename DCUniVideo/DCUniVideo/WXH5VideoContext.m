//
//  H5VideoContext.m
//  libVideo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "WXH5VideoContext.h"
#import "Masonry.h"
#import "PDRCorePrivate.h"

@interface WXH5VideoContext()<WXH5VideoPlayViewDelegate>
@property(nonatomic, assign)float curretTime;
@property(nonatomic, assign)BOOL fullScreen;
@end

@implementation WXH5VideoContext
- (id)initWithFrame:(CGRect)frame{
    if ( self = [super init] ) {        
        _videoPlayView = [[WXH5VideoPlayView alloc] init];   
        _videoPlayView.delegate = self;
        _tVideoPlayView = [[UIView alloc]init];
    }
    return self;
}
- (void)creatFrame:(CGRect)frame withSetting:(WXH5VideoPlaySetting *)setting withStyles:(NSDictionary *)styles{
    _tVideoPlayView.frame = frame;
    [_videoPlayView  creatWithFrame:frame withSetting:setting withStyles:styles];
    [_tVideoPlayView addSubview:_videoPlayView];
}

-(void)dealloc{
    _tVideoPlayView = nil;
    _videoPlayView = nil;
}
- (NSInteger)playerViewExitFullScreen:(WXH5VideoPlayView*)playerView{
    [playerView removeFromSuperview];
    [self.tVideoPlayView addSubview:playerView];
    
    NSInteger index = 0;
    if(self.tVideoPlayView.superview.subviews.count>0){
        index = self.tVideoPlayView.superview.subviews.count-1;
        UIView * tsupview = self.tVideoPlayView.superview;
        for(int i=0; i<self.tVideoPlayView.subviews.count; i++) {
            UIView * view = self.tVideoPlayView.subviews[i];
            if ([view isKindOfClass:[self.tVideoPlayView class]]) {
                [self.tVideoPlayView removeFromSuperview];
                [tsupview addSubview:self.tVideoPlayView];
                index = i;
                break;
            }
        }
    }
    if ( self.fullScreen ) {
        [PDRCore setFullScreen:NO];
        self.fullScreen = NO;
    }
    
    [playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tVideoPlayView.frame.origin.x);
        make.top.equalTo(self.tVideoPlayView.frame.origin.y);
        make.size.equalTo(self.tVideoPlayView.frame.size);
    }];
    [self sendFullscreenchangeEvtWithStatus:NO withDirection:UIInterfaceOrientationPortrait];
    return index;
}

- (void)destroy {
    [self.videoPlayView destroy];
}

- (void)playerViewEnterFullScreen:(WXH5VideoPlayView *)playerView
             interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if ( ![PDRCore isFullScreen] ) {
        [PDRCore setFullScreen:YES];
        self.fullScreen = YES;
    }
    
    [self sendFullscreenchangeEvtWithStatus:YES withDirection:interfaceOrientation];
}

- (void)playerViewEnterFullScreenNoDelay:(WXH5VideoPlayView *)playerView
                    interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerEnterFullScreen:)]) {
        [self.delegate videoPlayerEnterFullScreen:interfaceOrientation];
    }
}

- (void)playerViewExitFullScreenNoDelay:(WXH5VideoPlayView *)playerView
                   interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerExitFullScreen:)]) {
        [self.delegate videoPlayerExitFullScreen:interfaceOrientation];
    }
}

#pragma mark - delegate
- (void)playerViewPlay:(WXH5VideoPlayView *)playerView {
    [self sendPlayEvt];
}

- (void)playerViewPause:(WXH5VideoPlayView *)playerView {
    [self sendPauseEvt];
}

- (void)playerViewEnded:(WXH5VideoPlayView *)playerView {
    self.curretTime = 0;
    [self sendEndedEvt];
}

- (void)playerView:(WXH5VideoPlayView *)playerView playerError:(NSError *)error {
    [self sendErrorEvt];
}

- (void)playerView:(WXH5VideoPlayView *)playerView timeUpdate:(float)curDuration total:(float)total{
    [self sendTimeupdateEvtWithCurrentTime:curDuration withTotal:total];
}

- (void)playerViewBuffering:(WXH5VideoPlayView *)playerView {
    [self sendWaitingEvt];
}

#pragma mark - js callback
- (void)sendPlayEvt{
    [self asyncSendEvt:@"play" withParams:nil];
}

- (void)sendPauseEvt{
    [self asyncSendEvt:@"pause" withParams:nil];
}

- (void)sendEndedEvt {
    [self asyncSendEvt:@"ended" withParams:nil];
}

- (void)sendTimeupdateEvtWithCurrentTime:(float)currentTime withTotal:(float)duration{
    if ( self.curretTime > currentTime ) {
        self.curretTime = 0;
    }
    if ( currentTime > duration ) {
        currentTime = duration;
    }
    if ( (currentTime - self.curretTime) > 0.25 ) {
        [self asyncSendEvt:@"timeupdate" withParams:@{@"detail":@{@"currentTime":@(currentTime),@"duration":@(duration)}}];
        self.curretTime = currentTime;
    }
}

- (void)sendFullscreenchangeEvtWithStatus:(BOOL)isFullScreen withDirection:(UIInterfaceOrientation)or{
    [self asyncSendEvt:@"fullscreenchange" withParams:@{@"detail":@{@"fullScreen":@(isFullScreen),@"direction":(UIInterfaceOrientationIsPortrait(or)?@"vertical":@"horizontal")}}];
}

- (void)sendWaitingEvt{
    [self asyncSendEvt:@"waiting" withParams:nil];
}

- (void)sendErrorEvt{
    [self asyncSendEvt:@"error" withParams:nil];
}

- (void)asyncSendEvt:(NSString*)name withParams:(NSDictionary*)params {
    NSMutableArray *payload = [NSMutableArray array];
    [payload addObject:name];
    if ( params ) {
        [payload addObject:params];
    }
    [self performSelector:@selector(sendWithPayload:) withObject:payload afterDelay:0];
}

- (void)sendWithPayload:(NSArray*)payload {
    NSString *evtName = [payload objectAtIndex:0];
    NSDictionary *params = nil;
    if ( [payload count] > 1 ) {
        params = [payload objectAtIndex:1];
    }
    [self sendEvt:evtName withParams:params];
}

- (void)sendEvt:(NSString*)name withParams:(NSDictionary*)params {
    [self.delegate sendEvent:name withParams:params];
}
@end
