//
//  libWXLivePusherComponent.m
//  DCUniLivePush
//
//  Created by 4Ndf on 2019/5/13.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "PGWXLivePusherComponent.h"
#import "WXConvert.h"
#import "WXComponent+Layout.h"

#import "PDRCoreApp.h"
#import "PDRCommonString.h"
#import "PTPathUtil.h"
#import "PDRCore.h"
#import "PDRCoreAppManager.h"
#import "PTPathUtil.h"
#import "PDRCoreAppInfo.h"
#import "PDRCoreAppFrame.h"
#import "PDRCoreAppPrivate.h"
#import "PDRCoreAppFramePrivate.h"
#import "WXUpYunLivePusher.h"
#import "WXDCLivePusher.h"
@interface PGWXLivePusherComponent()<WXUpYunLivePusherProtocol>{
    BOOL _statechange;
    BOOL _netstatus;
    BOOL _error;
    WXUpYunLivePusher* upYunPusher;
}
@property (nonatomic, assign) WXDCLivePusher*   activePusher;
@property(nonatomic,retain)NSDictionary * pattributes;
@end

@implementation PGWXLivePusherComponent

WX_EXPORT_METHOD(@selector(start:))
WX_EXPORT_METHOD(@selector(pause:))
WX_EXPORT_METHOD(@selector(resume:))
WX_EXPORT_METHOD(@selector(stop:))
WX_EXPORT_METHOD(@selector(switchCamera:))
WX_EXPORT_METHOD(@selector(snapshot:))
WX_EXPORT_METHOD(@selector(startPreview:))
WX_EXPORT_METHOD(@selector(stopPreview:))

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance {
    if(self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance]) {
        _pattributes  = attributes;
    }
    return self;
}
-(UIView *)loadView{
    [self LivePusher:_pattributes];
    return upYunPusher;
}
- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    // 设置默认宽高
    [self dc_setDefaultWidthPixel:300 defaultHeightPixel:225];
    
    [upYunPusher setWithOption:_pattributes];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self close];
}
- (void)updateStyles:(NSDictionary *)styles{
    
}
- (void)updateAttributes:(NSDictionary *)attributes {
    _pattributes = attributes;
    if ( _pattributes && [_pattributes isKindOfClass:[NSDictionary class]]) {
        [upYunPusher setWithOption:_pattributes];
    }
}
- (void)addEvent:(NSString *)eventName {
    if ([eventName isEqualToString:@"statechange"]) {
        _statechange = YES;
    }
    if ([eventName isEqualToString:@"netstatus"]) {
        _netstatus = YES;
    }
    if ([eventName isEqualToString:@"error"]) {
        _error = YES;
    }
}
- (void)removeEvent:(NSString *)eventName{
    if ([eventName isEqualToString:@"statechange"]) {
        _statechange = NO;
    }
    if ([eventName isEqualToString:@"netstatus"]) {
        _netstatus = NO;
    }
    if ([eventName isEqualToString:@"error"]) {
        _error = NO;
    }
}
#pragma mark -  js方法
- (void)LivePusher:(NSDictionary*)pMethod{
        if (nil == upYunPusher) {
            upYunPusher = [[WXUpYunLivePusher alloc]initWithOption];
            upYunPusher.delegate = self;
        }
}
-(void)listenerEvent:(NSDictionary *)resuest EventType:(NSString *)EventType{
    if (resuest !=nil) {
        if (_error==YES && [EventType isEqualToString:@"error"]) {
            [self fireEvent:@"error" params: resuest?:@{}];
            return;
        }
        if (_statechange==YES && [EventType isEqualToString:@"statechange"]) {
            [self fireEvent:@"statechange" params:resuest?:@{}];
            return;
        }
        if (_netstatus==YES && [EventType isEqualToString:@"netstatus"]) {
            [self fireEvent:@"netstatus" params:resuest?:@{}];
            return;
        }
    }   
}


- (void)start:(WXModuleKeepAliveCallback)callback{
    if (upYunPusher) {
        [upYunPusher start:^(NSDictionary *result) {            
            if (callback) {
                callback(result,NO);
            }
        }];
        _activePusher = upYunPusher;
        [self registSystemNotification];
    }
}

- (void)stop:(WXModuleKeepAliveCallback)callback{
        if (upYunPusher) {
            [upYunPusher stop];
            _activePusher = nil;
            [self unRegisitSystemNotificaton];
            NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"success",@"type",
                                   nil];
            if (callback) {
                callback(dic,NO);
            }
        }
}

- (void)resume:(WXModuleKeepAliveCallback)callback{
        if (upYunPusher) {
            [upYunPusher resume];
            _activePusher = upYunPusher;
        }
    [self registSystemNotification];
    NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:
                           @"success",@"type",
                           nil];
    if (callback) {
        callback(dic,NO);
    }
}

- (void)pause:(WXModuleKeepAliveCallback)callback{
        if (upYunPusher) {
            [upYunPusher pause];
            _activePusher = nil;
            [self unRegisitSystemNotificaton];
            NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"success",@"type",
                                   nil];
            if (callback) {
                callback(dic,NO);
            }
        }
}

- (void)close{
        if (upYunPusher) {
            [upYunPusher close];
            [self unRegisitSystemNotificaton];
        }
}

- (void)switchCamera:(WXModuleKeepAliveCallback)callback{
        if (upYunPusher) {
            [upYunPusher switchCamera];
            NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"success",@"type",
                                   nil];
            if (callback) {
                callback(dic,NO);
            }
        }
}
- (void)startPreview:(WXModuleKeepAliveCallback)callback{
    if (upYunPusher) {
        [upYunPusher preview:YES];
        NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:
                               @"success",@"type",
                               nil];
        if (callback) {
            callback(dic,NO);
        }
    }
}
-(void)stopPreview:(WXModuleKeepAliveCallback)callback{
    if (upYunPusher) {
        [upYunPusher preview:NO];
        NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:
                               @"success",@"type",
                               nil];
        if (callback) {
            callback(dic,NO);
        }
    }
}
- (void)snapshot:(WXModuleKeepAliveCallback)callback{
    PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
    NSString* filePath = [coreApp.appInfo.documentPath stringByAppendingPathComponent:[self imageFileName]];
        if (upYunPusher) {
            [upYunPusher snapshot:^(UIImage *photo) {
                if (photo && [photo isKindOfClass:[UIImage class]]) {
                    // 保存文件。。并回调路径
                    NSData *imageData = UIImagePNGRepresentation(photo);
                    if (imageData && filePath) {
                        int imgWidth = photo.size.width;
                        int imgHeight = photo.size.height;
                        NSDictionary* resulDic = @{@"width":@(imgWidth),@"height":@(imgHeight), @"tempImagePath": filePath};
                        [imageData writeToFile:filePath atomically:NO];
                       NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:resulDic, @"message",
                         [NSNumber numberWithInt:0], @"code",
                         @"success",@"type",
                         nil];
                        if (callback) {
                            callback(dic,NO);
                        }
                    }
                }else{
                    NSDictionary * dic =  [NSDictionary dictionaryWithObjectsAndKeys:@"fail", @"message",
                                           [NSNumber numberWithInt:-99], @"code",
                                           @"fail",@"type",
                                           nil];
                    if (callback) {
                        callback(dic,NO);
                    }
                }
            }];
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
