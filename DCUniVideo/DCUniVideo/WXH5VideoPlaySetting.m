//
//  H5VideoPlaySetting.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "WXH5VideoPlaySetting.h"

@implementation WXH5VideoPlaySetting
-(id)init {
    if ( self = [super init] ) {
        self.isShowControls = YES;
        self.isShowProgress = YES;
        self.isShowFullscreenBtn = YES;
        self.isShowPlayBtn = YES;
        self.isShowMuteBtn = NO;
        self.isShowCenterPlayBtn = YES;
        self.isEnableProgressGesture = YES;
        self.objectFit = WXH5VideObjectFitContain;
    }
    return self;
}
@end

NSString *wxkH5VideoPlaySettingKeyUrl  = @"src";
NSString *wxkH5VideoPlaySettingKeyInitialTime  = @"initialTime";
NSString *wxkH5VideoPlaySettingKeyDuration  = @"duration";
NSString *wxkH5VideoPlaySettingKeyControls  = @"controls";
NSString *wxkH5VideoPlaySettingKeyEanableDanmu  = @"enableDanmu";
NSString *wxkH5VideoPlaySettingKeyDanmuList  = @"danmuList";
NSString *wxkH5VideoPlaySettingKeyDanutBtn  = @"danmuBtn";
NSString *wxkH5VideoPlaySettingKeyAutoPlay  = @"autoplay";
NSString *wxkH5VideoPlaySettingKeyLoop  = @"loop";
NSString *wxkH5VideoPlaySettingKeyMuted  = @"muted";
NSString *wxkH5VideoPlaySettingKeyPageGesture  = @"pageGesture";
NSString *wxkH5VideoPlaySettingKeyDirection  = @"direction";
NSString *wxkH5VideoPlaySettingKeyShowProgress  = @"showProgress";

NSString *wxkH5VideoPlaySettingKeyShowFullScreenBtn  = @"showFullscreenBtn";
NSString *wxkH5VideoPlaySettingKeyShowPlayBtn  = @"showPlayBtn";
NSString *wxkH5VideoPlaySettingKeyShowMuteBtn = @"showMuteBtn";
NSString *wxkH5VideoPlaySettingKeyShowCenterPlayBtn  = @"showCenterPlayBtn";

NSString *wxkH5VideoPlaySettingKeyShowProgressGresture  = @"enableProgressGesture";
NSString *wxkH5VideoPlaySettingKeyObjectFit = @"objectFit";
NSString *wxkH5VideoPlaySettingKeyPoster = @"poster";
