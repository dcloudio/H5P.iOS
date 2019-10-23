//
//  H5VideoContext.m
//  libVideo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "H5VideoContext.h"
#import "Masonry.h"
#import "PDRCore.h"

@interface H5VideoContext()<H5VideoPlayViewDelegate> {
    NSMutableDictionary *_listeners;
}
@property(nonatomic, strong)H5VideoPlayView *videoPlayView;
@property(nonatomic, weak)UIView *hostedView;
@property(nonatomic, assign)CGRect hostedFrame;
@property(nonatomic, assign)float curretTime;
@property(nonatomic, assign)BOOL fullScreen;
@end

@implementation H5VideoContext
- (id)initWithFrame:(CGRect)frame withSetting:(H5VideoPlaySetting*)setting withStyles:(NSDictionary*)styles {
    if ( self = [super init] ) {
        _videoPlayView = [[H5VideoPlayView alloc] initWithFrame:frame withSetting:setting withStyles:styles];
        _videoPlayView.delegate = self;
        self.hostedFrame = frame;
    }
    return self;
}

- (void)setHostedView:(UIView*)hostedView {
    if ( self.videoPlayView.superview ) {
        [self.videoPlayView removeFromSuperview];
    }
    _hostedView = hostedView;
    [_hostedView addSubview:self.videoPlayView];
}

- (void)onLayout_:(H5VideoPlayView *)playerView {
     _hostedView = playerView.superview;
    self.hostedFrame = playerView.frame;
}

- (void)setFrame:(CGRect)frame {
    self.hostedFrame = frame;
    [_videoPlayView setFrame:frame];
    [_videoPlayView updateLayout];
}

- (void)playerViewExitFullScreen:(H5VideoPlayView*)playerView{
    [playerView removeFromSuperview];
    [self.hostedView addSubview:playerView];
    if ( self.fullScreen ) {
        [PDRCore setFullScreen:NO];
        self.fullScreen = NO;
    }
    [playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.hostedFrame.origin.x);
        make.top.equalTo(self.hostedFrame.origin.y);
        make.size.equalTo(self.hostedFrame.size);
    }];
    
    [self.hostedView setNeedsUpdateConstraints];
    [self.hostedView updateConstraintsIfNeeded];
    
    [UIView animateWithDuration:.3 animations:^{
        [self.hostedView layoutIfNeeded];
    }];
    [self sendFullscreenchangeEvtWithStatus:NO withDirection:UIInterfaceOrientationPortrait];
}

- (void)setHidden:(BOOL)isHidden {
    [self.videoPlayView dc_setHidden:isHidden];
}

- (void)destroy {
    [self.videoPlayView destroy];
}

- (void)playerViewEnterFullScreen:(H5VideoPlayView *)playerView
             interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if ( ![PDRCore isFullScreen] ) {
        [PDRCore setFullScreen:YES];
        self.fullScreen = YES;
    }
    
    [self sendFullscreenchangeEvtWithStatus:YES withDirection:interfaceOrientation];
}

- (void)setListener:(NSString*)cbId forEvt:(NSString*)evt forWebviewId:(NSString*)webviewId{
    if ( !_listeners ) {
        _listeners = [[NSMutableDictionary alloc] init];
    }
    
    [_listeners setObject:@[cbId, webviewId] forKey:evt];
}
#pragma mark - delegate
- (void)playerViewPlay:(H5VideoPlayView *)playerView {
    [self sendPlayEvt];
}

- (void)playerViewPause:(H5VideoPlayView *)playerView {
    [self sendPauseEvt];
}

- (void)playerViewEnded:(H5VideoPlayView *)playerView {
    self.curretTime = 0;
    [self sendEndedEvt];
}

- (void)playerView:(H5VideoPlayView *)playerView playerError:(NSError *)error {
    [self sendErrorEvt];
}

- (void)playerView:(H5VideoPlayView *)playerView timeUpdate:(float)curDuration total:(float)total{
    [self sendTimeupdateEvtWithCurrentTime:curDuration withTotal:total];
}

- (void)playerViewBuffering:(H5VideoPlayView *)playerView {
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
    NSArray *payload = [_listeners objectForKey:name];
    NSString *cbId = [payload objectAtIndex:0];
    NSString *webviewId = [payload objectAtIndex:1];
    if ( cbId ) {
        [self.delegate sendEvent:name toJsCallback:cbId withParams:params inWebview:webviewId?:self.webviewId];
    }
}
@end
