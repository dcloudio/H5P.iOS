//
//  H5VideoPlayView.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/21.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXH5VideoPlaySetting.h"
#import "PDRNView.h"

@class WXH5VideoPlayView;
@protocol WXH5VideoPlayViewDelegate <NSObject>
@required
- (void)playerViewEnterFullScreen:(WXH5VideoPlayView *)playerView interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)playerViewEnterFullScreenNoDelay:(WXH5VideoPlayView *)playerView interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)playerViewExitFullScreen:(WXH5VideoPlayView *)playerView;
- (void)playerViewExitFullScreenNoDelay:(WXH5VideoPlayView *)playerView;
- (void)onLayout_:(WXH5VideoPlayView *)playerView;
@optional
- (void)playerViewPlay:(WXH5VideoPlayView *)playerView;
- (void)playerViewPause:(WXH5VideoPlayView *)playerView;
- (void)playerViewEnded:(WXH5VideoPlayView *)playerView;
- (void)playerView:(WXH5VideoPlayView *)playerView playerError:(NSError *)error;
- (void)playerView:(WXH5VideoPlayView *)playerView timeUpdate:(float)curDuration total:(float)total;
- (void)playerViewBuffering:(WXH5VideoPlayView *)playerView;
@end

@interface WXH5VideoPlayView : UIView
@property (nonatomic, weak) id<WXH5VideoPlayViewDelegate> delegate;
- (void)creatWithFrame:(CGRect)frame withSetting:(WXH5VideoPlaySetting*)setting withStyles:(NSDictionary*)styles;
- (void)play;
- (void)pause;
- (void)stop;
- (void)seek:(float)positon;
- (void)playbackReate:(int)rate;
- (void)requestFullScreen:(WXH5VideoPlayDirection)rate;
- (void)exitFullScreen;
- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color;
- (void)sendDanmaku:(NSDictionary*)danmaku ;
- (void)clearDanmaku;
- (void)setControlValue:(id)value forKey:(NSString*)key;
- (void)destroy;
- (void)updateLayout;
- (void)dc_setHidden:(BOOL)isHidden;
@end
