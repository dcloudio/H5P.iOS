//
//  DCUniFaceID.m
//  DCUniFaceID
//
//  Created by 4Ndf on 2019/8/23.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "DCUniFaceIDModule.h"
#import "PDRToolSystemEx.h"
#import <sys/utsname.h>
#import <LocalAuthentication/LocalAuthentication.h>
#define kDevice_Is_iPhoneX \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);})

@interface DCUniFaceIDModule() {
    LAContext *_context;
}
@end
@implementation DCUniFaceIDModule
WX_EXPORT_METHOD_SYNC(@selector(isSupport))
WX_EXPORT_METHOD_SYNC(@selector(isKeyguardSecure))
WX_EXPORT_METHOD_SYNC(@selector(isEnrolledFaceID))
WX_EXPORT_METHOD(@selector(authenticate:callback:))
WX_EXPORT_METHOD(@selector(cancel))
-(instancetype)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (BOOL)isSupport {
    return [self faceiDDeviceSupport];
}
- (BOOL)isKeyguardSecure {
    return [self isEnrolledFaceID];
}

- (BOOL)isEnrolledFaceID {
    NSError *error = nil;
    BOOL support = [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error];
    return support;
}

- (void)authenticate:(NSDictionary*)options callback:(WXModuleKeepAliveCallback)callback{
    NSString* pFingerTitle = @" ";
    if (options && [options isKindOfClass:[NSDictionary class]]) {
        NSString* pTmpString = [options objectForKey:@"message"];
        if (pTmpString && [pTmpString isKindOfClass:[NSString class]] && pTmpString.length > 0) {
            pFingerTitle = pTmpString;
        }
    }
    
    if (![self faceiDDeviceSupport]) {
        if (callback) {
            callback(@{@"type":@"fail",@"code":@1,@"message":@"No FaceID Device"},NO);
        }
        return;
    }
    NSError *error = nil;
    if(![[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error]){
        int errorCode = 1;
        switch (error.code) {
            case LAErrorUserCancel:
            case LAErrorSystemCancel:
            case LAErrorAppCancel:
                errorCode = 6;
                break;
            case LAErrorTouchIDNotEnrolled:
                errorCode = 3;
                break;
            case LAErrorPasscodeNotSet:
                errorCode = 2;
                break;
            case LAErrorTouchIDLockout:
                errorCode = 5;
                break;
            case LAErrorTouchIDNotAvailable:
                errorCode = 1;
                break;
            default:
                break;
        }
        if (callback) {
            callback(@{@"type":@"fail",@"code":[NSNumber numberWithInt:errorCode],@"message":error.localizedDescription},NO);
        }
        return;
    }
    
    [[self getLAContext] evaluatePolicy:[self getLAPolicy] localizedReason:pFingerTitle reply:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                if (callback) {
                    callback(@{@"type":@"success",@"code":@0,@"message":@"success"},NO);
                }
            }else {
                int errorCode = 4;
                switch (error.code) {
                    case LAErrorSystemCancel:
                    case LAErrorUserCancel:
                    case LAErrorAppCancel:
                        errorCode = 6;
                        break;
                    case LAErrorTouchIDNotAvailable:
                        errorCode = 1;
                        break;
                    case LAErrorTouchIDLockout:
                    case LAErrorAuthenticationFailed:
                        errorCode = 5;
                        break;
                    default:
                        break;
                }
                if (callback) {
                    callback(@{@"type":@"fail",@"code":[NSNumber numberWithInt:errorCode],@"message":error.localizedDescription},NO);
                }
            }
            
            [self->_context invalidate];
            self->_context = nil;
        });
    }];
}

- (BOOL)FaceRecognitionDeviceSupport
{
    LAContext *context = [self getLAContext];
    if ( [context respondsToSelector:@selector(biometryType)] ) {
        if (@available(iOS 11.0, *)) {
            LABiometryType biometryType = [self getLAContext].biometryType;
            if ( LABiometryTypeFaceID == biometryType ) {
                return true;
            }else{
                NSError *error = nil;
                return [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error];
            }
        } else {
            NSError *error = nil;
            BOOL support = [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error];
            return support;
        }
    }
    else{
        //TODO.. device list ??
        NSError *error = nil;
        BOOL support = [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error];
        return support;
    }
    return false;
}
- (BOOL)faceiDDeviceSupport{
     LAContext *context = [self getLAContext];
        [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:nil];
        //判断是支持touchid还是faceid
        if (@available(iOS 11.0, *)) {
            switch (context.biometryType) {
                case LABiometryNone:
    //                NSLog(@"-----------touchid，faceid都不支持");
                    return NO;
                    break;
                case LABiometryTypeTouchID:
    //                NSLog(@"-----------touchid支持");
                    return NO;
                    break;
                case LABiometryTypeFaceID:
    //                NSLog(@"-----------faceid支持");
                    return YES;
                    break;
                default:
                    return NO;
                    break;
            }
        } else {
            return [self judueIPhonePlatformSupportFaceID];
    //        NSLog(@"-----------iOS11之前的版本，不做id判断");
        }
        return NO;
}
- (BOOL)judueIPhonePlatformSupportFaceID{
    NSString *platform = [self platform];
    if ([platform hasPrefix:@"iPhone"]) {
        if (kDevice_Is_iPhoneX) {
            return YES;
        }
    }
    return NO;
}


- (NSString *)platform
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return platform;
}

- (void)cancel {
    [[self getLAContext] invalidate];
}

- (LAPolicy)getLAPolicy {
    if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion9Series ) {
        return LAPolicyDeviceOwnerAuthentication;
    }
    return LAPolicyDeviceOwnerAuthenticationWithBiometrics;
}

- (LAContext*)getLAContext {
    if ( !_context ) {
        _context = [[LAContext alloc] init];
    }
    return _context;
}
@end
