//
//  UPAVPlayerLogger.h
//  UPAVPlayerDemo
//
//  Created by DING FENG on 2/23/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UPLiveSDKConfig.h"




#define  logActiveTags           (UP_Tag_stream + UP_Tag_video + UP_Tag_audio + UP_Tag_default + UP_Tag_event + UP_Tag_verbose)


typedef NS_ENUM(NSInteger, UPLiveSDKLogger_tag) {
    UP_Tag_stream = 1 << 0,
    UP_Tag_video  = 1 << 1,
    UP_Tag_audio  = 1 << 2,
    UP_Tag_default  = 1 << 3,
    UP_Tag_event  = 1 << 4,
    UP_Tag_verbose = 1 << 5
};

@interface UPLiveSDKLogger : NSObject

@property (nonatomic)UPLiveSDKLogger_level UP_LOG_LEVEL_LIMIT;

+ (UPLiveSDKLogger *)sharedInstance;

+ (void)log:(NSString *)message level:(UPLiveSDKLogger_level)level tag:(UPLiveSDKLogger_tag)tag;
+ (void)setLogLevel:(UPLiveSDKLogger_level)level;

@end
