//
//  WXDCLivePusher.m
//  DCUniLivePush
//
//  Created by 4Ndf on 2019/5/13.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "WXDCLivePusher.h"
#import "WXUpYunLivePusher.h"
#import "PDRCommonString.h"
#import "NWindowOptionsParse.h"
#import "PDRCoreAppFramePrivate.h"
#import "WXConvert.h"

@implementation WXDCLivePusher


+(WXDCLivePusher*)getPusherInstance:(NSString*)pusherIdentify{
    return [[WXUpYunLivePusher alloc] init];
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

//- (void)stop:(BOOL)stopPrview {
//    
//}

- (void)close{
}

- (void)resize:(NSArray*)sizeArg{
}

- (void)prepareLiveOptions{
}

//- (void)addEventListener:(PDRCoreAppFrame*)pFrame{
//}

- (void)switchCamera{
}

- (void)setVideoOption:(NSDictionary*)options{
    if (options && [options isKindOfClass:[NSDictionary class]]) {
        
        if ([options objectForKey:@"url"]) {
            if (self.pushStreamURL) {
                self.pushStreamURL = nil;
            }
            self.pushStreamURL = [[NSString alloc] initWithString:[options objectForKey:@"url"]];
        }
        
        if ([options objectForKey:@"muted"]) {
//            self.bSilence = [[options objectForKey:@"muted"] boolValue];
            self.bSilence = [WXConvert BOOL:options[@"muted"]];
        }
        if ([options objectForKey:@"enableCamera"]) {
//            self.bCameraEnable = [[options objectForKey:@"enableCamera"] boolValue];
            self.bCameraEnable = [WXConvert BOOL:options[@"enableCamera"]];
        }
        if ([options objectForKey:@"autoFocus"]) {
//            self.bAutoFocus = [[options objectForKey:@"autoFocus"] boolValue];
            self.bAutoFocus = [WXConvert BOOL:options[@"autoFocus"]];
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
//            self.bBeauty = [[options objectForKey:@"beauty"] boolValue];
            self.bBeauty =  [WXConvert BOOL:options[@"beauty"]];
        }
        
        if ([options objectForKey:@"whiteness"]) {
//            self.bWhiteCat = [[options objectForKey:@"whiteness"] boolValue];
            self.bWhiteCat = [WXConvert BOOL:options[@"whiteness"]];
        }
        
        if ([options objectForKey:@"aspect"]) {
        }
        
        if ([options objectForKey:@"minBitrate"]){
            self.minbitrate = [[options objectForKey:@"minBitrate"] intValue];
        }
        
        if ([options objectForKey:@"maxBitrate"]){
            self.maxbitrate = [[options objectForKey:@"maxBitrate"] intValue];
        }
        
        if ([options objectForKey:@"waiting-image"]){
        }
        
        if ([options objectForKey:@"waiting-image-hash"]){
        }
        
        if ([options objectForKey:@"background-mute"]){
            // unsupport
        }
        
//        self.isDivLayout = true;
        
        // 位置属性
//        if ([options objectForKey:g_pdr_string_left] ||
//            [options objectForKey:g_pdr_string_top] ||
//            [options objectForKey:g_pdr_string_width] ||
//            [options objectForKey:g_pdr_string_height]) {
////            self.isDivLayout = NO;
//        }
        
//        if ([options objectForKey:@"position"]) {
//            self.lpPosition = [options objectForKey:@"position"];
//        }
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
