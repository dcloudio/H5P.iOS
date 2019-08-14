//
//  libUpYunLivePush.m
//  libUpYunLivePush
//
//  Created by nearwmy on 2018/6/1.
//  Copyright © 2018年 nearwmy. All rights reserved.
//

#import "PGLivePush.h"
#import "PGMethod.h"
#import "DCLivePusher.h"
#import "PDRCoreApp.h"
#import "PTPathUtil.h"
#import "PDRCoreAppInfo.h"
#import "PDRCoreAppFrame.h"
#import "PDRCoreAppPrivate.h"
#import "PDRCoreAppFramePrivate.h"
#import "UpYunLivePusher.h"


@interface PGLivePush(){
}
@property (nonatomic, retain) NSMutableDictionary* pusherDict;
@property (nonatomic, retain) NSMutableDictionary* puserUUIDDic;
@property (nonatomic, assign) DCLivePusher*   activePusher;
@end

@implementation PGLivePush

- (void)LivePusher:(PGMethod*)pMethod{
    
    if (_pusherDict == nil) {
        _pusherDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    
    if (_puserUUIDDic == nil) {
        _puserUUIDDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    
    NSString* pusherUUID = [pMethod.arguments objectAtIndex:0];
    NSString* pPusherID = [pMethod.arguments objectAtIndex:1];
    NSDictionary* pPusherOptions = [pMethod.arguments objectAtIndex:3];
    
    if (pPusherID) {
        DCLivePusher* pusher = [_pusherDict objectForKey:pusherUUID];
        if (nil == pusher) {
            int left = 0, top = 0, width = [UIScreen mainScreen].bounds.size.width, height = [UIScreen mainScreen].bounds.size.height;
            CGRect destFrameRect = CGRectMake(left, top, width, height);
            pusher = [[UpYunLivePusher alloc] initWithFrame:destFrameRect withOptions:pPusherOptions withJsContext:self];
            
            if (pusher) {
                [pusher initWithOption:pMethod.arguments];
                
                NSArray* rectArray = [pMethod.arguments objectAtIndex:2];
                
                if(rectArray && [rectArray isKindOfClass:[NSArray class]]){
                    left = [[rectArray firstObject] intValue];
                    top = [[rectArray objectAtIndex:1] intValue];
                    width = [[rectArray objectAtIndex:2] intValue];
                    height = [[rectArray objectAtIndex:3] intValue];
                    destFrameRect = CGRectMake(left, top, width, height);
                    
                    pusher.frame = destFrameRect;
                    
                    if(pusher.isDivLayout){
                        [self.JSFrameContext.webEngine.scrollView addSubview:pusher];
                    }
                    
                    pusher.belongFrameID = self.JSFrameContext.frameID;
                }
                [_puserUUIDDic setObject:pusherUUID forKey:pPusherID];
                [_pusherDict setObject:pusher forKey:pusherUUID];
            }
        }
    }
}

- (void)resize:(PGMethod*)pMethod
{
    if (pMethod.arguments.count > 1) {
        NSString* pusherUUID = [pMethod.arguments objectAtIndex:0];
        NSArray* rectArray = [pMethod.arguments objectAtIndex:1];
        
        int left = [[rectArray firstObject] intValue];
        int top = [[rectArray objectAtIndex:1] intValue];
        int width = [[rectArray objectAtIndex:2] intValue];
        int height = [[rectArray objectAtIndex:3] intValue];
        
        DCLivePusher* pusher = [_pusherDict objectForKey:pusherUUID];
        if (pusher) {
            CGRect destFrameRect = CGRectMake(left, top, width, height);
            pusher.frame = destFrameRect;
        }
    }
}

- (void)preview:(PGMethod*)pMethod{
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    DCLivePusher* pusher = [_pusherDict objectForKey:pusherID];
    if (pusher) {
        [pusher preview];
    }
}

- (void)start:(PGMethod*)pMethod{
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    NSString* cbid = [pMethod.arguments objectAtIndex:1];
    
    DCLivePusher* pusher = [_pusherDict objectForKey:pusherID];
    if (pusher) {
        pusher.startCallbackID = cbid;
        [pusher start:^(NSString *result, NSString* callbackID) {
            [self toCallback:callbackID withReslut:result];
        }];
        _activePusher = pusher;
        [self registSystemNotification];
    }
}

- (void)stop:(PGMethod*)pMethod{
    
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    NSDictionary *options  = [pMethod.arguments objectAtIndex:1];
    if (pusherID) {
        DCLivePusher* pusher = [_pusherDict objectForKey:pusherID];
        if (pusher) {
            BOOL preview = [PGPluginParamHelper getBoolValueInDict:options forKey:@"preview" defalut:NO];
            [pusher stop:!preview];
            _activePusher = nil;
            [self unRegisitSystemNotificaton];
        }
    }
    [self unRegisitSystemNotificaton];
}

- (void)resume:(PGMethod*)pMethod{
    
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    if (pusherID) {
        DCLivePusher* pusher = [_pusherDict objectForKey:pusherID];
        if (pusher) {
            [pusher resume];
            _activePusher = pusher;
            [self unRegisitSystemNotificaton];
        }
    }
    [self registSystemNotification];
}

- (void)pause:(PGMethod*)pMethod{
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    if (pusherID) {
        DCLivePusher* pusher = [_pusherDict objectForKey:pusherID];
        if (pusher) {
            [pusher pause];
            _activePusher = nil;
            [self unRegisitSystemNotificaton];
        }
    }
    [self unRegisitSystemNotificaton];
}

- (void)close:(PGMethod*)pMethod{
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    if (pusherID) {
        DCLivePusher* pusher = [_pusherDict objectForKey:pusherID];
        if (pusher) {
            [pusher close];
            [pusher removeFromSuperview];
            [self unRegisitSystemNotificaton];
        }
    }
}

- (void)setOptions:(PGMethod*)pMethod{
    NSString* pusherUUID = [pMethod.arguments objectAtIndex:0];
    NSDictionary* pOptions = [pMethod.arguments objectAtIndex:1];
    
    if (nil != pusherUUID ) {
        DCLivePusher* pusher = [_pusherDict objectForKey: pusherUUID];
        if (pusher) {
            [pusher setVideoOption:pOptions];
        }
    }
}

- (void)addEventListener:(PGMethod*)pMethod{
    
    NSString* pusherUUID = [pMethod.arguments objectAtIndex:0];
    NSString* pHtmlID = [pMethod.arguments objectAtIndex:1];
    
    if (nil != pusherUUID ) {
        DCLivePusher* pusher = [_pusherDict objectForKey: pusherUUID];
        if (pusher) {
            [pusher addEventListener:[[self.appContext appWindow] getFrameByID:pHtmlID]];
        }
    }
}

- (NSData*)getLivePusherById:(PGMethod*)pMethod{
    NSString* pusherID = [pMethod.arguments objectAtIndex:0];
    if (pusherID) {
        NSString* pusherUUID = [_puserUUIDDic objectForKey:pusherID];
        if (pusherUUID) {
            if (_puserUUIDDic) {
                DCLivePusher* pusher = [_pusherDict objectForKey:pusherUUID];
                if (pusher) {
                    NSDictionary* resultDic = @{@"uuid":pusherUUID};
                    return [self resultWithJSON:resultDic];
                }
            }
        }
    }
    return [self resultWithNull];
}

- (void)switchCamera:(PGMethod*)pMethod{
    NSString* pusherUUID = [pMethod.arguments objectAtIndex:0];
    if (nil != pusherUUID ) {
        DCLivePusher* pusher = [_pusherDict objectForKey: pusherUUID];
        if (pusher) {
            [pusher switchCamera];
        }
    }
}

- (void)snapshot:(PGMethod*)pMethod{
    
    NSString* pusherUUID = [pMethod.arguments objectAtIndex:0];
    NSString* cbid = [pMethod.arguments objectAtIndex:1];
    NSString* filePath = [self.appContext.appInfo.documentPath stringByAppendingPathComponent:[self imageFileName]];
    if (nil != pusherUUID ) {
        DCLivePusher* pusher = [_pusherDict objectForKey: pusherUUID];
        if (pusher) {
            [pusher snapshot:^(UIImage *photo) {
                if (photo && [photo isKindOfClass:[UIImage class]]) {
                    // 保存文件。。并回调路径
                    NSData *imageData = UIImagePNGRepresentation(photo);
                    if (imageData && filePath) {
                        int imgWidth = photo.size.width;
                        int imgHeight = photo.size.height;
                        NSDictionary* resulDic = @{@"width":@(imgWidth),@"height":@(imgHeight), @"tempImagePath": filePath};
                        [imageData writeToFile:filePath atomically:NO];
                        [self toSucessCallback:cbid withJSON:resulDic keepCallback:NO];
                    }
                }
            }];
        }
    }
}

- (void)onAppFrameWillClose:(PDRCoreAppFrame *)theAppframe{
    if (_puserUUIDDic) {
        NSEnumerator *enumerator = [_puserUUIDDic keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            DCLivePusher* pusher = [_pusherDict objectForKey:key];
            if (pusher && pusher.belongFrameID && [pusher.belongFrameID isEqualToString:theAppframe.frameID]) {
                [pusher close];
                [pusher removeFromSuperview];
                [_puserUUIDDic removeObjectForKey:key];
            }
        }
    }
}


- (void)orientChange:(NSNotification*)noti{
    UIInterfaceOrientation curOri = [UIApplication sharedApplication].statusBarOrientation;
    switch (curOri) {
        case UIInterfaceOrientationPortrait:
            [_activePusher orientChange:AVCaptureVideoOrientationPortrait];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [_activePusher orientChange:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            [_activePusher orientChange:AVCaptureVideoOrientationLandscapeLeft];

            break;
        case UIInterfaceOrientationLandscapeRight:
            [_activePusher orientChange:AVCaptureVideoOrientationLandscapeRight];
            break;
        default:
            break;
    }
}

- (DCLivePusher*)__getNativeViewById:(NSString*)pusherUUID{
    if (_pusherDict) {
        return [_pusherDict objectForKey:pusherUUID];
    }
    return nil;
}


#pragma mark

- (NSString*)imageFileName{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDateString = [dateFormatter stringFromDate:currentDate];
    return [currentDateString stringByAppendingString:@".jpg"];
}

- (void)registSystemNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)unRegisitSystemNotificaton{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)onWillResignActive:(NSNotification*)noti{
    if (_activePusher){
        [_activePusher pause];
    }
}

- (void)onDidBecomeActive:(NSNotification*)noti{
    if(_activePusher){
        [_activePusher resume];
    }
}


@end
