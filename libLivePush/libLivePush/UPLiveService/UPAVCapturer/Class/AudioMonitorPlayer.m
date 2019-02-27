//
//  AudioMonitorPlayer.m
//  UPLiveSDKDemo
//
//  Created by DING FENG on 12/06/2017.
//  Copyright © 2017 upyun.com. All rights reserved.
//



#import "AudioMonitorPlayer.h"
#import <Accelerate/Accelerate.h>


#define K_MAX_FRAME_SIZE 4096
#define K_MAX_CHAN       6


static BOOL checkError(OSStatus error, const char *operation);
static OSStatus renderCallback (void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inOutputBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList* ioData);

@interface AudioMonitorPlayer()
{
    BOOL _initialized;
    BOOL _activated;
    float *_outData;
    float *_inData;
    AudioUnit _audioUnit;
    int _preferredSampleRate;
    int _preferredChannels;
    dispatch_queue_t _auQueue;
    NSMutableArray *_audioBuffers;
    BOOL _mute;
    AudioStreamBasicDescription _asbd;
    BOOL _started;
}

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;
@property (readwrite) BOOL              playAfterSessionEndInterruption;
@property (nonatomic) AudioStreamBasicDescription outputFormat;

- (BOOL)setupAudioSession;
- (BOOL)renderFrames:(UInt32)numFrames ioData:(AudioBufferList *)ioData;
- (BOOL)logAudioSessionRoute;
- (BOOL)logAudioSessionProperties;

@end

@implementation AudioMonitorPlayer

- (id)init {
    self = [super init];
    if (self) {
        _outData = (float *)calloc(K_MAX_FRAME_SIZE * K_MAX_CHAN, sizeof(float));
        _inData = (float *)calloc(K_MAX_FRAME_SIZE * K_MAX_CHAN, sizeof(float));

        _preferredSampleRate = -1;
        _preferredChannels = 1;
        _preferredChannels = K_MAX_CHAN;
        _numBytesPerSample = 2;
        _auQueue = dispatch_queue_create("AudioMonitorPlayer_run_queue", DISPATCH_QUEUE_SERIAL);
        _audioBuffers = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return self;
}

- (void)renderAudioBuffer:(AudioBuffer)audioBuffer info:(AudioStreamBasicDescription)asbd {
    if (!_started) {
        return;
    }
    
    if (_asbd.mChannelsPerFrame <= 0) {
        _asbd = asbd;
    }
    NSData *bufferD = [[NSData alloc] initWithBytes:audioBuffer.mData
                                             length:audioBuffer.mDataByteSize];
    NSDictionary *info = @{@"sample_rate": [NSString stringWithFormat:@"%f", asbd.mSampleRate],
                           @"channels": [NSString stringWithFormat:@"%d", (unsigned int)asbd.mChannelsPerFrame],
                           @"mBytesPerFrame": [NSString stringWithFormat:@"%d", (unsigned int)asbd.mBytesPerFrame]};
    
    [self setupAudioInfo:info];
    @synchronized (_audioBuffers) {
        //暂存的数据，影响反听的延时
        //NSLog(@"_audioBuffers.count %lu", (unsigned long)_audioBuffers.count);
        if (_audioBuffers.count > 20) {
            [_audioBuffers removeAllObjects];
        }
        [_audioBuffers addObject:bufferD];
    }
}

- (void)setupAudioInfo:(NSDictionary *)info {
    dispatch_async(_auQueue, ^{
        
        int sampleR = [[info objectForKey:@"sample_rate"] intValue];
        if (sampleR > 0) {
            _preferredSampleRate = sampleR;
        }
        int channels = [[info objectForKey:@"channels"] intValue];
        if (channels > 0 && channels <= K_MAX_CHAN) {
            _preferredChannels = channels;
        }
        
        int mBytesPerFrame = [[info objectForKey:@"mBytesPerFrame"] intValue];
        if (mBytesPerFrame > 0) {
            _numBytesPerSample = mBytesPerFrame;
        }
        if (!_playing && _started) {
            [self play];
        }
    });
}

#pragma mark - private

- (BOOL)setupAudioSession {
    // Setup AudioSession
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:&error];
    if (error) {
        NSLog(@"error: %@", error);

        
        return NO;
    }
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"error: %@", error);

        return NO;
    }
    
    [self logAudioSessionProperties];
    
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    if (checkError(AudioComponentInstanceNew(component, &_audioUnit),
                   "Couldn't create the output audio unit")) {
        return NO;
    }
    
    UInt32 size;
    // Check the output stream format
    size = sizeof(AudioStreamBasicDescription);

    /* 删除默认初始化
     if (checkError(AudioUnitGetProperty(_audioUnit,
     kAudioUnitProperty_StreamFormat,
     kAudioUnitScope_Input,
     0,
     &_outputFormat,
     &size),
     "Couldn't get the hardware output stream format")) {
     return NO;
     }
     _outputFormat.mSampleRate = _samplingRate;
     _outputFormat.mChannelsPerFrame = _preferredChannels;
     _outputFormat.mBytesPerFrame = 2;
     */
    _outputFormat = _asbd;

    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        size),
                   "Couldn't set the hardware output stream format")) {
        return NO;
    }
    
    
    _numBytesPerSample = _outputFormat.mBitsPerChannel / 8;
    _numOutputChannels = _outputFormat.mChannelsPerFrame;
    
    AudioStreamBasicDescription streamFormat = _outputFormat;
    NSArray *streamFormat_d = @[[NSString stringWithFormat:@"streamFormat.mSampleRate %f", streamFormat.mSampleRate],
                                [NSString stringWithFormat:@"streamFormat.mFormatID %d", (unsigned int)streamFormat.mFormatID],
                                [NSString stringWithFormat:@"streamFormat.mFormatFlags %d", (unsigned int)streamFormat.mFormatFlags],
                                [NSString stringWithFormat:@"streamFormat.mBytesPerPacket %d", (unsigned int)streamFormat.mBytesPerPacket],
                                [NSString stringWithFormat:@"streamFormat.mFramesPerPacket %d", (unsigned int)streamFormat.mFramesPerPacket],
                                [NSString stringWithFormat:@"streamFormat.mBytesPerFrame  %d", (unsigned int)streamFormat.mBytesPerFrame],
                                [NSString stringWithFormat:@"streamFormat.mChannelsPerFrame  %d", (unsigned int)streamFormat.mChannelsPerFrame],
                                [NSString stringWithFormat:@"streamFormat.mBitsPerChannel  %d", (unsigned int)streamFormat.mBitsPerChannel]];
    

    
    NSLog(@"streamFormat_d: %@", streamFormat_d);

    
    // Slap a render callback on the unit
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        0,
                                        &callbackStruct,
                                        sizeof(callbackStruct)),
                   "Couldn't set the render callback on the audio unit")) {
        return NO;
    }
    
    if (checkError(AudioUnitInitialize(_audioUnit), "Couldn't initialize the audio unit")) {
        return NO;
    }
    
    return YES;
}

- (void)fillOutDataWithLength:(NSInteger)len {
    NSUInteger offset = len;
    while (offset > 0) {
        @synchronized (_audioBuffers) {
            @autoreleasepool {
                NSData *data = [_audioBuffers firstObject];
                if (!data) {
                    return;
                }
                
                if (data.length <= offset) {
                    memcpy(_outData + (len - offset), data.bytes, data.length);
                    offset = offset - data.length;
                    [_audioBuffers removeObject:data];
                } else {
                    NSUInteger lenToCopy = offset;
                    NSUInteger lenLeft = data.length - offset;
                    NSData *leftData = [[NSData alloc] initWithBytes:(char *)(data.bytes + lenToCopy)  length:lenLeft];
                    memcpy(_outData + (len - offset), data.bytes, lenToCopy);
                    offset = offset - lenToCopy;
                    [_audioBuffers removeObject:data];
                    [_audioBuffers insertObject:leftData atIndex:0];
                }
            }
        }
    }
}

- (BOOL)renderFrames:(UInt32)numFrames ioData:(AudioBufferList *)ioData {
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    NSInteger len = numFrames * _preferredChannels * _numBytesPerSample;
    [self fillOutDataWithLength:len];
    
    
    if (_playing) {
        if (_mute) {
            //新 mute 逻辑：播放空的数据
            bzero(_outData, (K_MAX_FRAME_SIZE * K_MAX_CHAN * sizeof(float)));
        }
        
        UInt32 outData_offset = 0;
        for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
            UInt32 thisBufferDataSize = ioData->mBuffers[iBuffer].mDataByteSize;
            memcpy(ioData->mBuffers[iBuffer].mData, _outData + outData_offset, thisBufferDataSize);
            outData_offset = outData_offset + thisBufferDataSize;
            NSAssert(outData_offset <= len, @"AudioMonitorPlayer renderFrames 数据长度计算错误");
        }
    }

    return noErr;
}

- (BOOL)logAudioSessionRoute {
    NSLog(@" [AVAudioSession sharedInstance].currentRoute %@",  [AVAudioSession sharedInstance].currentRoute);
    return YES;
}

- (BOOL)logAudioSessionProperties {
    [self logAudioSessionRoute];
    AVAudioSession* session = [AVAudioSession sharedInstance];
    // Check the number of output channels.

    NSLog(@"channels %@", [NSString stringWithFormat:@"We've got %d output channels",
                       (unsigned int)session.maximumOutputNumberOfChannels]);
    
    BOOL success;
    NSError* error = nil;
    double preferredSampleRate = _preferredSampleRate;
    success  = [session setPreferredSampleRate:preferredSampleRate error:&error];
    if (error) {
        
        NSLog(@"error %@", error);
        return NO;
    }
    _samplingRate = [AVAudioSession sharedInstance].preferredSampleRate;

    
    NSLog(@"_samplingRate %@", [NSString stringWithFormat:@"rate: %f volume:%f", _samplingRate, session.outputVolume]);

    return YES;
}

#pragma mark - public

- (BOOL)activateAudioSession {
    if (!_activated) {
        if (!_initialized) {
            NSError *error;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (error) {
                NSLog(@"error %@", error);

                return NO;
            }
            _initialized = YES;
        }
        
        if ([self setupAudioSession]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(audioSessionDidChangeInterruptionType:)
                                                         name:AVAudioSessionInterruptionNotification
                                                       object:[AVAudioSession sharedInstance]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(audioSessionRouteChangeNotification:)
                                                         name:AVAudioSessionRouteChangeNotification
                                                       object:[AVAudioSession sharedInstance]];
            _activated = YES;
        }
    }
    return _activated;
}

- (void)start {
    _started = YES;
}

- (void)stop {
    _started = NO;
    dispatch_async(_auQueue, ^{
        if (_playing) {
            _playing = checkError(AudioOutputUnitStop(_audioUnit), "Couldn't stop the output unit");
            checkError(AudioUnitUninitialize(_audioUnit), "Couldn't uninitialize the audio unit");
            checkError(AudioComponentInstanceDispose(_audioUnit), "Couldn't dispose the output audio unit");
            _activated = NO;
            _playing = NO;
        }
    });
}

- (void)play {
    if (_preferredSampleRate == -1) {
        return;
    }
    dispatch_async(_auQueue, ^{
        if (_playing) {
            return ;
        }
        if ([self activateAudioSession]) {
            _playing = !checkError(AudioOutputUnitStart(_audioUnit), "Couldn't start the output unit");
        }
    });
}


- (BOOL)mute {
    return  _mute;
}

- (void)setMute:(BOOL)mute {
    _mute = mute;
}

- (void)audioSessionDidChangeInterruptionType:(NSNotification *)notification {
    AVAudioSessionInterruptionType interruptionType = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey]
                                                       unsignedIntegerValue];

    NSLog(@"audioSessionDidChangeInterruption");
    if (AVAudioSessionInterruptionTypeBegan == interruptionType) {
        NSLog(@"Begin interuption");
        self.playAfterSessionEndInterruption = self.playing;
        [self stop];
    } else if (AVAudioSessionInterruptionTypeEnded == interruptionType) {
        NSLog(@"End interuption");
        if (self.playAfterSessionEndInterruption) {
            self.playAfterSessionEndInterruption = NO;
            [self play];
        }
    }
}

- (void)audioSessionRouteChangeNotification:(NSNotification *)notification {

    NSLog(@"audioSessionRouteChangeNotification");
    [self logAudioSessionRoute];
    
}

- (void)dealloc {
    if (_outData) {
        free(_outData);
        _outData = NULL;
    }
    
    NSLog(@"dealloc  %@", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end


#pragma mark - callbacks

static OSStatus renderCallback (void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inOutputBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData) {
    
    
    
//    if (ioData->mNumberBuffers >= 1) {
//        AudioBuffer ab = ioData->mBuffers[0];
//        NSLog(@"renderFrames %u  mNumberBuffers %u mNumberChannels %u mDataByteSize %u",
//              (unsigned int)inNumberFrames,
//              ioData->mNumberBuffers,
//              ab.mNumberChannels,
//              ab.mDataByteSize);
//        
//    } else {
//        NSLog(@"??????");
//    }
    
    
    AudioMonitorPlayer *obj = (__bridge AudioMonitorPlayer *)inRefCon;
    OSStatus ret = [obj renderFrames:inNumberFrames ioData:ioData];
    return ret;
}

static BOOL checkError(OSStatus error, const char *operation) {
    if (error == noErr)
        return NO;
    char str[20] = {0};
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    }
    NSLog(@"%@", [NSString stringWithFormat:@"Error: %s (%s)\n", operation, str]);
    return YES;
}

