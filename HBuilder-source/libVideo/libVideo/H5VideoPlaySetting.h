//
//  H5VideoPlaySetting.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,H5VideoObjectFit) {
    H5VideObjectFitContain,
    H5VideObjectFitFill,
    H5VideObjectFitCover
};
typedef NS_ENUM(NSInteger,H5VideoPlayDirection) {
    H5VideoPlayDirectionNormal,
    H5VideoPlayDirectionLeft,
    H5VideoPlayDirectionRight,
    H5VideoPlayDirectionAuto
};

extern NSString *kH5VideoPlaySettingKeyUrl;
extern NSString *kH5VideoPlaySettingKeyInitialTime;
extern NSString *kH5VideoPlaySettingKeyDuration;
extern NSString *kH5VideoPlaySettingKeyControls;
extern NSString *kH5VideoPlaySettingKeyEanableDanmu;
extern NSString *kH5VideoPlaySettingKeyDanutBtn;
extern NSString *kH5VideoPlaySettingKeyDanmuList;
extern NSString *kH5VideoPlaySettingKeyAutoPlay;
extern NSString *kH5VideoPlaySettingKeyLoop;
extern NSString *kH5VideoPlaySettingKeyMuted;
extern NSString *kH5VideoPlaySettingKeyPageGesture;
extern NSString *kH5VideoPlaySettingKeyDirection;
extern NSString *kH5VideoPlaySettingKeyShowProgress;

extern NSString *kH5VideoPlaySettingKeyShowFullScreenBtn;
extern NSString *kH5VideoPlaySettingKeyShowPlayBtn;
extern NSString *kH5VideoPlaySettingKeyShowCenterPlayBtn;

extern NSString *kH5VideoPlaySettingKeyShowProgressGresture;
extern NSString *kH5VideoPlaySettingKeyObjectFit;
extern NSString *kH5VideoPlaySettingKeyPoster;



@interface H5VideoPlaySetting : NSObject
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
@property(nonatomic, assign)H5VideoPlayDirection direction;
//若不设置，宽度大于240时才会显示
@property(nonatomic, assign)BOOL isShowProgress;
//是否显示全屏按钮 true
@property(nonatomic, assign)BOOL isShowFullscreenBtn;
//是否显示视频底部控制栏的播放按钮
@property(nonatomic, assign)BOOL isShowPlayBtn;
//true    是否显示视频中间的播放按钮
@property(nonatomic, assign)BOOL isShowCenterPlayBtn;
//true 是否开启控制进度的手势
@property(nonatomic, assign)BOOL isEnableProgressGesture;
//当视频大小与 video 容器大小不一致时，视频的表现形式。contain：包含，fill：填充，cover：覆盖
@property(nonatomic, assign)H5VideoObjectFit objectFit;
//视频封面的图片网络资源地址，如果 controls 属性值为 false 则设置 poster 无效
@property(nonatomic, strong)NSString *poster;
@end
