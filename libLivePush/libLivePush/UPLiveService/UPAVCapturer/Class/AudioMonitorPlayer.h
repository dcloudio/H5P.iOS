//
//  AudioMonitorPlayer.h
//  UPLiveSDKDemo
//
//  Created by DING FENG on 12/06/2017.
//  Copyright © 2017 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioMonitorPlayer : NSObject
@property (nonatomic, assign) BOOL mute;

- (void)start;
- (void)renderAudioBuffer:(AudioBuffer)audioBuffer info:(AudioStreamBasicDescription)asbd;
- (void)stop;

@end
