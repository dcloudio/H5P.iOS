//
//  H5VideoPlaySetting.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "H5VideoPlaySetting.h"

@implementation H5VideoPlaySetting
-(id)init {
    if ( self = [super init] ) {
        self.isShowControls = YES;
        self.isShowProgress = YES;
        self.isShowFullscreenBtn = YES;
        self.isShowPlayBtn = YES;
        self.isShowCenterPlayBtn = YES;
        self.isEnableProgressGesture = YES;
        self.objectFit = H5VideObjectFitContain;
    }
    return self;
}
@end

NSString *kH5VideoPlaySettingKeyUrl  = @"src";
NSString *kH5VideoPlaySettingKeyInitialTime  = @"initial-time";
NSString *kH5VideoPlaySettingKeyDuration  = @"duration";
NSString *kH5VideoPlaySettingKeyControls  = @"controls";
NSString *kH5VideoPlaySettingKeyEanableDanmu  = @"enable-danmu";
NSString *kH5VideoPlaySettingKeyDanmuList  = @"danmu-list";
NSString *kH5VideoPlaySettingKeyDanutBtn  = @"danmu-btn";
NSString *kH5VideoPlaySettingKeyAutoPlay  = @"autoplay";
NSString *kH5VideoPlaySettingKeyLoop  = @"loop";
NSString *kH5VideoPlaySettingKeyMuted  = @"muted";
NSString *kH5VideoPlaySettingKeyPageGesture  = @"page-gesture";
NSString *kH5VideoPlaySettingKeyDirection  = @"direction";
NSString *kH5VideoPlaySettingKeyShowProgress  = @"show-progress";

NSString *kH5VideoPlaySettingKeyShowFullScreenBtn  = @"show-fullscreen-btn";
NSString *kH5VideoPlaySettingKeyShowPlayBtn  = @"show-play-btn";
NSString *kH5VideoPlaySettingKeyShowCenterPlayBtn  = @"show-center-play-btn";

NSString *kH5VideoPlaySettingKeyShowProgressGresture  = @"enable-progress-gesture";
NSString *kH5VideoPlaySettingKeyObjectFit = @"objectFit";
NSString *kH5VideoPlaySettingKeyPoster = @"poster";
