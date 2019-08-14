//
//  LivePusher.m
//  libLivePush
//
//  Created by nearwmy on 2018/7/12.
//  Copyright © 2018年 EICAPITAN. All rights reserved.
//

#import "DCLivePusher.h"
#import "UpYunLivePusher.h"
#import "PDRCommonString.h"
#import "NWindowOptionsParse.h"
#import "PDRCoreAppFramePrivate.h"

NSString* const EVENT_TEMPLATE = @"{var target = (typeof window === 'object' && window) || (new WeexPlus(weex)); target.__Media_Live__Push__.execCallback_LivePush('%@', %@);}";
NSString* const EVENT_RESULT_TEMPLATE = @"{code:'%d',message:'%@'}";
NSString* const EventType = @"statechange";



@implementation DCLivePusher

+(DCLivePusher*)getPusherInstance:(NSString*)pusherIdentify{
    return [[UpYunLivePusher alloc] init];
}

- (id)initWithOption:(NSArray*)options{
    return self;
}

- (void)start:(DCLivePushHandle)callBackhandle{
}

- (void)pause{
}

- (void)resume{
}

- (void)stop{
}

- (void)stop:(BOOL)stopPrview {
    
}

- (void)close{
}

- (void)resize:(NSArray*)sizeArg{
}

- (void)prepareLiveOptions{
}

- (void)addEventListener:(PDRCoreAppFrame*)pFrame{
}

- (void)switchCamera{
}

- (void)setVideoOption:(NSDictionary*)options{
    if (options && [options isKindOfClass:[NSDictionary class]]) {
        
        if ([options objectForKey:@"url"]) {
            if (self.pushStreamURL) {
                self.pushStreamURL = nil;
            }
            self.pushStreamURL =[[NSString alloc] initWithString:[options objectForKey:@"url"]];
        }
                
        if ([options objectForKey:@"muted"]) {
            self.bSilence = [[options objectForKey:@"muted"] boolValue];
        }
        if ([options objectForKey:@"enable-camera"]) {
            self.bCameraEnable = [[options objectForKey:@"enable-camera"] boolValue];
        }
        if ([options objectForKey:@"auto-focus"]) {
            self.bAutoFocus = [[options objectForKey:@"auto-focus"] boolValue];
        }
        if ([options objectForKey:@"orientation"]) {
            NSString* strOrientaion = [options objectForKey:@"orientation"];
            if ([[strOrientaion lowercaseString] compare:@"vertical"]) {
                self.liveOri = VERTIAL;
            }else{
                self.liveOri = HORIZONTAL;
            }
        }
        if ([options objectForKey:@"beauty"]) {
            self.bBeauty = [[options objectForKey:@"beauty"] boolValue];
        }
        
        if ([options objectForKey:@"whiteness"]) {
            self.bWhiteCat = [[options objectForKey:@"whiteness"] boolValue];
        }
        
        if ([options objectForKey:@"aspect"]) {
        }
        
        if ([options objectForKey:@"min-bitrate"]){
            self.minbitrate = [[options objectForKey:@"min-bitrate"] intValue];
        }
        
        if ([options objectForKey:@"max-bitrate"]){
            self.maxbitrate = [[options objectForKey:@"max-bitrate"] intValue];
        }
        
        if ([options objectForKey:@"waiting-image"]){
        }
        
        if ([options objectForKey:@"waiting-image-hash"]){
        }
        
        if ([options objectForKey:@"background-mute"]){
            // unsupport
        }
        
        self.isDivLayout = true;
        
        // 位置属性
        if ([options objectForKey:g_pdr_string_left] ||
            [options objectForKey:g_pdr_string_top] ||
            [options objectForKey:g_pdr_string_width] ||
            [options objectForKey:g_pdr_string_height]) {
            self.isDivLayout = NO;
        }

        if ([options objectForKey:@"position"]) {
            self.lpPosition = [options objectForKey:@"position"];
        }
    }
}

- (void)orientChange:(AVCaptureVideoOrientation)captureOri{
}

- (void)snapshot:(void(^)(UIImage *photo))completion{
}


- (BOOL)urlMatch:(NSString*)prtmpURL{
    NSString* rtmpRegex = @"^rtmp://([^/:]+)(:(\\d+))*/([^/]+)(/(.*))*$";
    NSPredicate* rtmpTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",rtmpRegex];
    return [rtmpTest evaluateWithObject:prtmpURL];
}

- (void)layoutSubviews{
    NSArray* subViews = [self subviews];
    for (UIView* pusherView in subViews) {
        pusherView.frame = self.bounds;
    }
}

@end
