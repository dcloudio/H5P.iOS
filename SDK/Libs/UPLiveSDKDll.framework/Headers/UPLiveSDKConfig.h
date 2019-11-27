//
//  UPLiveSDKConfig.h
//  UPLiveSDKLib
//
//  Created by DING FENG on 6/29/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UPLiveSDK_Version @"4.1.7"

typedef NS_ENUM(NSInteger, UPLiveSDKLogger_level) {
    UP_Level_debug,
    UP_Level_warn,
    UP_Level_error
};

@interface UPLiveSDKConfig : NSObject
/// log 打印模式
+ (void)setLogLevel:(UPLiveSDKLogger_level)level;
/// 播放质量统计功能，默认开
+ (void)setStatistcsOn:(BOOL)onOff;

@end


