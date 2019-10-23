//
//  H5VideoPlaySetting.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger,WXH5VideoObjectFit){
    WXH5VideObjectFitContain,
    WXH5VideObjectFitFill,
    WXH5VideObjectFitCover
};

typedef NS_ENUM(NSInteger,WXH5VideoPlayDirection) {
    H5VideoPlayDirectionNormal,
    H5VideoPlayDirectionLeft,
    H5VideoPlayDirectionRight,
    H5VideoPlayDirectionAuto
};

extern NSString *wxkH5VideoPlaySettingKeyUrl;
extern NSString *wxkH5VideoPlaySettingKeyInitialTime;
extern NSString *wxkH5VideoPlaySettingKeyDuration;
extern NSString *wxkH5VideoPlaySettingKeyControls;
extern NSString *wxkH5VideoPlaySettingKeyEanableDanmu;
extern NSString *wxkH5VideoPlaySettingKeyDanutBtn;
extern NSString *wxkH5VideoPlaySettingKeyDanmuList;
extern NSString *wxkH5VideoPlaySettingKeyAutoPlay;
extern NSString *wxkH5VideoPlaySettingKeyLoop;
extern NSString *wxkH5VideoPlaySettingKeyMuted;
extern NSString *wxkH5VideoPlaySettingKeyPageGesture;
extern NSString *wxkH5VideoPlaySettingKeyDirection;
extern NSString *wxkH5VideoPlaySettingKeyShowProgress;

extern NSString *wxkH5VideoPlaySettingKeyShowFullScreenBtn;
extern NSString *wxkH5VideoPlaySettingKeyShowPlayBtn;
extern NSString *wxkH5VideoPlaySettingKeyShowMuteBtn;
extern NSString *wxkH5VideoPlaySettingKeyShowCenterPlayBtn;

extern NSString *wxkH5VideoPlaySettingKeyShowProgressGresture;
extern NSString *wxkH5VideoPlaySettingKeyObjectFit;
extern NSString *wxkH5VideoPlaySettingKeyPoster;



@interface WXH5VideoPlaySetting : NSObject
//要播放视频的资源地址
@property(nonatomic, strong)NSString *url;
//指定视频初始播放位置
@property(nonatomic, assign)float initialTime;
//指定视频时长
@property(nonatomic, assign)float duration;
//是否显示默认播放控件（播放/暂停按钮、播放进度、时间
@property(nonatomic, assign)BOOL isShowControls;
//弹幕列表
@property(nonatomic, strong)NSArray<NSDictionary*>* danmuList;
//是否显示弹幕按钮，只在初始化时有效，不能动态变更
@property(nonatomic, assign)BOOL isShowDanmuBtn;
//是否展示弹幕，只在初始化时有效，不能动态变更
@property(nonatomic, assign)BOOL enableDanmu;
//是否自动播放
@property(nonatomic, assign)BOOL isAutoplay;
//是否循环播放
@property(nonatomic, assign)BOOL isLoop;
//是否静音播放
@property(nonatomic, assign)BOOL isMuted;
//在非全屏模式下，是否开启亮度与音量调节手势
@property(nonatomic, assign)BOOL isEnablePageGesture;
//设置全屏时视频的方向，不指定则根据宽高比自动判断。有效值为 0（正常竖向）, 90（屏幕逆时针90度）, -90（屏幕顺时针90度）
@property(nonatomic, assign)WXH5VideoPlayDirection direction;
//若不设置，宽度大于240时才会显示
@property(nonatomic, assign)BOOL isShowProgress;
//是否显示全屏按钮 true
@property(nonatomic, assign)BOOL isShowFullscreenBtn;
//是否显示视频底部控制栏的播放按钮
@property(nonatomic, assign)BOOL isShowPlayBtn;
//是否显示视频底部控制栏的静音按钮
@property(nonatomic, assign)BOOL isShowMuteBtn;
//true    是否显示视频中间的播放按钮
@property(nonatomic, assign)BOOL isShowCenterPlayBtn;
//true 是否开启控制进度的手势
@property(nonatomic, assign)BOOL isEnableProgressGesture;
//当视频大小与 video 容器大小不一致时，视频的表现形式。contain：包含，fill：填充，cover：覆盖
@property(nonatomic, assign) WXH5VideoObjectFit objectFit;
//视频封面的图片网络资源地址，如果 controls 属性值为 false 则设置 poster 无效
@property(nonatomic, strong)NSString *poster;
@end
