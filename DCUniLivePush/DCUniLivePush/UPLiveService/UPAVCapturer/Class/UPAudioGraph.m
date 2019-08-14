//
//  UPAudioGraph.m
//  UPLiveSDKDemo
//
//  Created by DING FENG on 9/10/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import "UPAudioGraph.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <UPLiveSDKDll/AudioProcessor.h>

//https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/AudioUnitHostingFundamentals/AudioUnitHostingFundamentals.html#//apple_ref/doc/uid/TP40009492-CH3-SW43
#define kAUBus_0    0
#define kAUBus_1    1
#define kAUChannelsNum 1

@interface UPAudioGraph()
{
    AUGraph _audioGraph;
    AudioUnit _mixerUnit;
    AudioUnit _ioUnit;
    AudioUnit _outputUnit;
    AudioStreamBasicDescription _audioFormat0;
    AudioStreamBasicDescription _audioFormat1;
    AURenderCallbackStruct _mixerInputCallbackStruct;
    dispatch_queue_t _audioOutPutQueue;
    BOOL _audioGraphIsRunning;
}

@end


@implementation UPAudioGraph


- (id)init {
    self = [super init];
    if (self) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionDefaultToSpeaker
                       error:&error];
        _audioOutPutQueue = dispatch_queue_create("UPAudioGraph_audioOutPutQueue", DISPATCH_QUEUE_SERIAL);
        
        _audioFormat0.mSampleRate		= 44100.00;
        _audioFormat0.mFormatID			= kAudioFormatLinearPCM;
        _audioFormat0.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        _audioFormat0.mFramesPerPacket	= 1;
        _audioFormat0.mChannelsPerFrame	= kAUChannelsNum;
        _audioFormat0.mBitsPerChannel		= 16;
        _audioFormat0.mBytesPerPacket		= 2 * kAUChannelsNum;
        _audioFormat0.mBytesPerFrame		= 2 * kAUChannelsNum;
        _audioFormat1 = _audioFormat0;
        
        
        _volumeOfOutput = 1;
        _volumeOfInputBus0 = 1;
        _volumeOfInputBus1 = 1;
    }
    return self;
}


- (void)setMixerInputCallbackStruct:(AURenderCallbackStruct)callbackStruct {
    _mixerInputCallbackStruct = callbackStruct;
}


- (void)setVolumeOfOutput:(Float32)volumeOfOutput {
    _volumeOfOutput = volumeOfOutput;
    if (!_audioGraphIsRunning) {
        return;
    }
    AudioUnitParameterValue newGain = volumeOfOutput;
    OSStatus result = AudioUnitSetParameter (
                                             _mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Output,
                                             0,
                                             newGain,
                                             0
                                             );
    NSAssert(result == noErr, @"setVolumeOfOutput  failed %d",  (int)result);
}

- (void)setVolumeOfInputBus0:(Float32)volumeOfInputBus0 {
    _volumeOfInputBus0 = volumeOfInputBus0;
    if (!_audioGraphIsRunning) {
        return;
    }

    AudioUnitParameterValue newGain = volumeOfInputBus0;
    OSStatus result = AudioUnitSetParameter (_mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Input,
                                             0,
                                             newGain,
                                             0
                                             );
    
    NSAssert(result == noErr, @"setVolumeOfInputBus0  failed %d",  (int)result);
}

- (void)setVolumeOfInputBus1:(Float32)volumeOfInputBus1 {
    _volumeOfInputBus1 = volumeOfInputBus1;
    if (!_audioGraphIsRunning) {
        return;
    }
    AudioUnitParameterValue newGain = volumeOfInputBus1;
    OSStatus result = AudioUnitSetParameter (_mixerUnit,
                                             kMultiChannelMixerParam_Volume,
                                             kAudioUnitScope_Input,
                                             1,
                                             newGain,
                                             0
                                             );
    NSAssert(result == noErr, @"setVolumeOfInputBus1  failed %d",  (int)result);
}

- (void)start {
    dispatch_sync(_audioOutPutQueue, ^{
        [self setup];
        OSStatus startStatus = AUGraphStart(_audioGraph);
        NSAssert(startStatus == noErr, @"AUGraphStart _audioGraph failed %d",  (int)startStatus);
        _audioGraphIsRunning = YES;
        [self setVolumeOfOutput:_volumeOfOutput];
        [self setVolumeOfInputBus0:_volumeOfInputBus0];
        [self setVolumeOfInputBus1:_volumeOfInputBus1];
    });
}

- (void)stop {
    dispatch_sync(_audioOutPutQueue, ^{
        _audioGraphIsRunning = NO;
        Boolean isRunning = false;
        OSStatus result = AUGraphIsRunning(_audioGraph, &isRunning);
        
        if (result == noErr) {
            isRunning = YES;
        } else {
            return;
            
        }
        if (isRunning) {
            result = AUGraphStop(_audioGraph);
            NSAssert(result == noErr, @"AUGraphStop %d",  (int)result);
        }
    });
}


- (void)setMixerInputPcmInfo:(AudioStreamBasicDescription)asbd forBusIndex:(int)bus {
    switch (bus) {
        case 0:
            _audioFormat0 = asbd;
            break;
        case 1:
            _audioFormat1 = asbd;
            break;
            
        default:
            break;
    }
}

- (void)setup {
    OSStatus setupStatus;
    
    //创建和打开 _audioGraph
    setupStatus = NewAUGraph(&_audioGraph);
    NSAssert(setupStatus == noErr, @"NewAUGraph failed %d",  (int)setupStatus);
    
    AUNode ioNode;
    AUNode mixerNode;
    AUNode outputNode;
    
    AudioComponentDescription ioUnitDescription;
    AudioComponentDescription mixerUnitDescription;
    AudioComponentDescription outputUnitDescription;

    int ioNodeFlag = 0;
    int mixerNodeFlag = 0;
    int outputNodeFlag = 0;

    //创建 mixerNode，获取_mixerUnit 用于混音
    mixerUnitDescription.componentType= kAudioUnitType_Mixer;
    mixerUnitDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerUnitDescription.componentFlags = 0;
    mixerUnitDescription.componentFlagsMask = 0;
    mixerNodeFlag = 1;
    setupStatus = AUGraphAddNode(_audioGraph, &mixerUnitDescription, &mixerNode);
    NSAssert(setupStatus == noErr, @"AUGraphAddNode mixerNode failed %d",  (int)setupStatus);
    
    //创建 outputNode
    outputUnitDescription.componentType = kAudioUnitType_Output;
    outputUnitDescription.componentSubType = kAudioUnitSubType_GenericOutput;
    outputUnitDescription.componentFlags = 0;
    outputUnitDescription.componentFlagsMask = 0;
    outputUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputNodeFlag = 1;
    setupStatus = AUGraphAddNode(_audioGraph, &outputUnitDescription, &outputNode);
    NSAssert(setupStatus == noErr, @"AUGraphAddNode outputNode failed %d",  (int)setupStatus);
    
    
    
    setupStatus = AUGraphConnectNodeInput(_audioGraph, mixerNode, 0, outputNode, 0);
    NSAssert(setupStatus == noErr, @"AUGraphConnectNodeInput ioNode-mixerNode failed %d",  (int)setupStatus);

    setupStatus = AUGraphOpen(_audioGraph);
    NSAssert(setupStatus == noErr, @"AUGraphOpen failed %d",  (int)setupStatus);
    
    if (mixerNodeFlag) {
        setupStatus = AUGraphNodeInfo(_audioGraph, mixerNode, &mixerUnitDescription, &_mixerUnit);
        NSAssert(setupStatus == noErr, @"AUGraphNodeInfo get mixerUnit failed %d",  (int)setupStatus);
    }
    
    if (ioNodeFlag) {
        setupStatus = AUGraphNodeInfo(_audioGraph, ioNode, &ioUnitDescription, &_ioUnit);
        NSAssert(setupStatus == noErr, @"AUGraphNodeInfo get ioUnit failed %d",  (int)setupStatus);
    }

    if (outputNodeFlag) {
        setupStatus = AUGraphNodeInfo(_audioGraph, outputNode, &outputUnitDescription, &_outputUnit);
        NSAssert(setupStatus == noErr, @"AUGraphNodeInfo get ioUnit failed %d",  (int)setupStatus);
    }
    
    
    if (_mixerUnit) {
        //为 mixerNode 设置两条输入通道
        UInt32 numbuses = 2;
        setupStatus = AudioUnitSetProperty(_mixerUnit,
                                           kAudioUnitProperty_ElementCount,
                                           kAudioUnitScope_Input,
                                           0,
                                           &numbuses,
                                           sizeof(numbuses));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_ElementCount _mixerUnit set numbuses failed %d",  (int)setupStatus);
        
        setupStatus = AudioUnitSetProperty(_mixerUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           kAUBus_1,
                                           &_audioFormat1,
                                           sizeof(_audioFormat1));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat _mixerUnit kAudioUnitScope_Input kAUBus_1 failed %d",  (int)setupStatus);
        
        setupStatus = AudioUnitSetProperty(_mixerUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           kAUBus_0,
                                           &_audioFormat0,
                                           sizeof(_audioFormat0));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat _mixerUnit kAudioUnitScope_Input kAUBus_0 failed %d",  (int)setupStatus);
        
        setupStatus = AudioUnitSetProperty(_mixerUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kAUBus_0,
                                           &_audioFormat0,
                                           sizeof(_audioFormat0));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat kAudioUnitScope_Output _mixerUnit  kAUBus_0 failed %d",  (int)setupStatus);
        
        
        // 混音器的输入回调
        AURenderCallbackStruct mixerInputCallbackStruct;
        mixerInputCallbackStruct = _mixerInputCallbackStruct;
        setupStatus = AUGraphSetNodeInputCallback(_audioGraph, mixerNode, 0, &mixerInputCallbackStruct);
        setupStatus = AUGraphSetNodeInputCallback(_audioGraph, mixerNode, 1, &mixerInputCallbackStruct);
        NSAssert(setupStatus == noErr, @"AUGraphSetNodeInputCallback _mixerUnit  failed %d",  (int)setupStatus);
    }
    
    
    if (_outputUnit) {
        setupStatus = AudioUnitSetProperty(_outputUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           kAUBus_0,
                                           &_audioFormat0,
                                           sizeof(_audioFormat0));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat _outputUnit kAudioUnitScope_Input kAUBus_0 failed %d",  (int)setupStatus);
        
        
        setupStatus = AudioUnitSetProperty(_outputUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kAUBus_0,
                                           &_audioFormat0,
                                           sizeof(_audioFormat0));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat  _outputUnit kAudioUnitScope_Output  kAUBus_0 failed %d",  (int)setupStatus);
        
    }

    
    if (_ioUnit) {
        //录音和播放功能 开关
        UInt32 flag_recording = 1;
        UInt32 flag_playback = 1;
        //设置麦克风启动
        setupStatus = AudioUnitSetProperty(_ioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           kAUBus_1,
                                           &flag_recording,
                                           sizeof(flag_recording));
        NSAssert(setupStatus == noErr, @"kAudioOutputUnitProperty_EnableIO _ioUnit  kAUBus_1 failed %d",  (int)setupStatus);
        
        
        //设置扬声器启动
        setupStatus = AudioUnitSetProperty(_ioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Output,
                                           kAUBus_0,
                                           &flag_playback,
                                           sizeof(flag_playback));
        NSAssert(setupStatus == noErr, @"kAudioOutputUnitProperty_EnableIO _ioUnit  kAUBus_0 failed %d",  (int)setupStatus);
        
        
        setupStatus = AudioUnitSetProperty(_ioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kAUBus_1,
                                           &_audioFormat0,
                                           sizeof(_audioFormat0));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat _ioUnit  kAUBus_1 failed %d",  (int)setupStatus);
        
        
        setupStatus = AudioUnitSetProperty(_ioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           kAUBus_0,
                                           &_audioFormat0,
                                           sizeof(_audioFormat0));
        NSAssert(setupStatus == noErr, @"kAudioUnitProperty_StreamFormat _ioUnit  kAUBus_0 failed %d",  (int)setupStatus);
    }
    
    setupStatus = AUGraphInitialize(_audioGraph);
    NSAssert(setupStatus == noErr, @"AUGraphInitialize _audioGraph  failed %d",  (int)setupStatus);
    //CAShow(_audioGraph);
}

- (void)needRenderFramesNum:(UInt32)framesNum
                  timeStamp:(const AudioTimeStamp *)inTimeStamp
                       flag:(AudioUnitRenderActionFlags *)ioActionFlags {

    dispatch_async(_audioOutPutQueue, ^{
        if (!_audioGraphIsRunning) {
            return ;
        }
        AudioBuffer buffer;
        buffer.mNumberChannels = 1;
        buffer.mDataByteSize = framesNum * 2 * 1;
        buffer.mData = malloc( framesNum * 2 * 1);
        
        // Put buffer in a AudioBufferList
        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0] = buffer;
        
        OSStatus error = AudioUnitRender(_outputUnit,
                                         ioActionFlags,
                                         inTimeStamp,
                                         0,
                                         framesNum,
                                         &bufferList);
        
        NSAssert(error == noErr, @"UPAudioGraph AudioUnitRender failed %d",  (int)error);
        if (self.delegate) {
            [self.delegate audioGraph:self didOutputBuffer:buffer info:_audioFormat0];
        }
        free(buffer.mData);
    });
}

- (void)dealloc {
//    NSLog(@"dealloc %@", self);
}

@end
