//
//  H5VideoPlayView.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/21.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "H5VideoPlaySetting.h"
#import "PDRNView.h"

@class H5VideoPlayView;
@protocol H5VideoPlayViewDelegate <NSObject>
@required
- (void)playerViewEnterFullScreen:(H5VideoPlayView *)playerView interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)playerViewExitFullScreen:(H5VideoPlayView *)playerView;
- (void)onLayout_:(H5VideoPlayView *)playerView;
@optional
- (void)playerViewPlay:(H5VideoPlayView *)playerView;
- (void)playerViewPause:(H5VideoPlayView *)playerView;
- (void)playerViewEnded:(H5VideoPlayView *)playerView;
- (void)playerView:(H5VideoPlayView *)playerView playerError:(NSError *)error;
- (void)playerView:(H5VideoPlayView *)playerView timeUpdate:(float)curDuration total:(float)total;
- (void)playerViewBuffering:(H5VideoPlayView *)playerView;
@end

@interface H5VideoPlayView : PDRNView
@property (nonatomic, weak) id<H5VideoPlayViewDelegate> delegate;
- (instancetype)initWithFrame:(CGRect)frame withSetting:(H5VideoPlaySetting*)setting withStyles:(NSDictionary*)styles;
- (void)play;
- (void)pause;
- (void)stop;
- (void)seek:(float)positon;
- (void)playbackReate:(int)rate;
- (void)requestFullScreen:(H5VideoPlayDirection)rate;
- (void)exitFullScreen;
- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color;
- (void)sendDanmaku:(NSDictionary*)danmaku ;
- (void)setControlValue:(id)value forKey:(NSString*)key;
- (void)destroy;
@end
