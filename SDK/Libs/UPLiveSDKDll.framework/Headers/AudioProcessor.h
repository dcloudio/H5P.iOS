//
//  AudioProcessor.h
//  UPLiveSDKDemo
//
//  Created by DING FENG on 8/22/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioProcessor : NSObject


/*
 PCM sample 格式需要是 s16
 噪音分贝设置负值。 默认是 -8
 PCM samplerate。 默认 44100
*/



- (id)initWithNoiseSuppress:(int)level samplerate:(int)rate;
- (NSData *)noiseSuppression:(NSData *)pcmInput;

@end
