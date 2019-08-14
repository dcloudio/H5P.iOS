//
//  UPAudioGraph.h
//  UPLiveSDKDemo
//
//  Created by DING FENG on 9/10/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class UPAudioGraph;

@protocol UPAudioGraphProtocol <NSObject>
- (void)audioGraph:(UPAudioGraph *)audioGraph
   didOutputBuffer:(AudioBuffer)audioBuffer
              info:(AudioStreamBasicDescription)asbd;
@end

@interface UPAudioGraph : NSObject
@property (nonatomic, weak) id<UPAudioGraphProtocol> delegate;


- (void)setMixerInputCallbackStruct:(AURenderCallbackStruct)callbackStruct;
- (void)start;
- (void)stop;
- (void)setMixerInputPcmInfo:(AudioStreamBasicDescription)asbd forBusIndex:(int)bus;
- (void)needRenderFramesNum:(UInt32)framesNum
                  timeStamp:(const AudioTimeStamp *)inTimeStamp
                       flag:(AudioUnitRenderActionFlags *)ioActionFlags;

// volume ＝ 1.0  是原声音量
@property (nonatomic, assign) Float32 volumeOfInputBus0;
@property (nonatomic, assign) Float32 volumeOfInputBus1;
@property (nonatomic, assign) Float32 volumeOfOutput;

@end
