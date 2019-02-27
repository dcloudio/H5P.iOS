//
//  UPAudioCapture.h
//  Test_audioUnitRecorderAndPlayer
//
//  Created by DING FENG on 7/20/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSInteger, UPAudioUnitCategory) {
    UPAudioUnitCategory_recorder,
    UPAudioUnitCategory_player,
    UPAudioUnitCategory_recorderAndplayer
};

@protocol UPAudioCaptureProtocol <NSObject>
- (void)didReceiveBuffer:(AudioBuffer)audioBuffer info:(AudioStreamBasicDescription)asbd;
@end

@interface UPAudioCapture : NSObject

@property (nonatomic, weak) id<UPAudioCaptureProtocol> delegate;
@property (nonatomic) int increaserRate;// 0静音 － 100原声 － 200两倍音量增益
@property (nonatomic) BOOL deNoise;
@property (nonatomic) int bgmPlayerType;




- (id)initWith:(UPAudioUnitCategory)category;
- (id)initWith:(UPAudioUnitCategory)category samplerate:(int)samplerate;
- (void)start;
- (void)stop;



@property (nonatomic, strong) NSString *backgroudMusicUrl;
@property (nonatomic) BOOL backgroudMusicOn;
@property (nonatomic, assign) Float32 backgroudMusicVolume;// 默认值为 1 即原声音量


@end
