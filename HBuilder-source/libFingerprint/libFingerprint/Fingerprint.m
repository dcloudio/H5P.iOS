//
//  libFingerprint.m
//  libFingerprint
//
//  Created by DCloud on 2018/4/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "Fingerprint.h"
#import "PDRToolSystemEx.h"
#import <sys/utsname.h>
#import <LocalAuthentication/LocalAuthentication.h>


@interface Fingerprint() {
    LAContext *_context;
}
@end

@implementation Fingerprint
- (NSData*)isSupport:(PGMethod*)method {
    
    BOOL isTouchID = [self fingerprintDeviceSupport];
    return [self resultWithBool:isTouchID];
}

- (NSData*)isKeyguardSecure:(PGMethod*)method {
    return [self isEnrolledFingerprints:method];
}

- (NSData*)isEnrolledFingerprints:(PGMethod*)method {
    NSError *error = nil;
    BOOL support = [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error];
    return [self resultWithBool:support];
}

- (void)authenticate:(PGMethod*)command {
    NSString* cbId = [command.arguments objectAtIndex:0];
    NSDictionary* options = [command.arguments objectAtIndex:1];
    NSString* pFingerTitle = @" ";
    if (options && [options isKindOfClass:[NSDictionary class]]) {
        NSString* pTmpString = [options objectForKey:@"message"];
        if (pTmpString && [pTmpString isKindOfClass:[NSString class]] && pTmpString.length > 0) {
            pFingerTitle = pTmpString;
        }
    }
    
    if (![self fingerprintDeviceSupport]) {
        [self toErrorCallback:cbId withCode:1 withMessage:@"No Touch ID Device"];
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
        [self toErrorCallback:cbId withCode:errorCode withMessage:error.localizedDescription];
        return;
    }
        
    [[self getLAContext] evaluatePolicy:[self getLAPolicy] localizedReason:pFingerTitle reply:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self toSucessCallback:cbId withString:@"suceess"];
            }else {
//                NSString* message = @"";
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
                [self toErrorCallback:cbId withCode:errorCode withMessage:error.localizedDescription ];
            }
            
            [self->_context invalidate];
            self->_context = nil;
        });
    }];
}

- (BOOL)fingerprintDeviceSupport
{
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
                return YES;
                break;
            case LABiometryTypeFaceID:
//                NSLog(@"-----------faceid支持");
                return NO;
                break;
            default:
                return NO;
                break;
        }
    } else {
        return [self judueIPhonePlatformSupportTouchID];
//        NSLog(@"-----------iOS11之前的版本，不做id判断");
    }
    return NO;
}


- (BOOL)judueIPhonePlatformSupportTouchID
{
    NSString *platform = [self platform];
    if ([platform hasPrefix:@"iPhone"]) {
        if(platform.length > 6 ){
            NSUInteger loc = [platform rangeOfString:@","].location;
            NSString * numberPlatformStr = [platform substringWithRange:NSMakeRange(6, loc-6)];
            NSInteger numberPlatform = [numberPlatformStr integerValue];
            // 是否是5s以上的设备
            if(numberPlatform > 5){
                return YES;
            }
        }
    }else if([platform hasPrefix:@"iPad"]){
        if(platform.length > 4 ){
            NSUInteger loc = [platform rangeOfString:@","].location;
            NSString * numberPlatformStr = [platform substringWithRange:NSMakeRange(4, loc-4)];
            NSInteger numberPlatform = [numberPlatformStr integerValue];
            // 是否是iPad3以上设备
            if(numberPlatform > 2){
                NSArray* mini2Array = @[@"iPad4,4",@"iPad4,5",@"iPad4,6"];
                for (NSString* item in mini2Array) {
                    if([platform hasPrefix:item])
                        return NO;
                }
                return YES;
            }
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

- (void)cancel:(PGMethod*)method {
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
