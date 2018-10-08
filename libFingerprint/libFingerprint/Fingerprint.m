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
    return [self resultWithBool:[self judueIPhonePlatformSupportTouchID]];
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
    
    if (![self judueIPhonePlatformSupportTouchID]) {
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
                NSString* message = @"";
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
            
            [_context invalidate];
            _context = nil;
        });
    }];
}

- (BOOL)fingerprintDeviceSupport
{
    LAContext *context = [self getLAContext];
    if ( [context respondsToSelector:@selector(biometryType)] ) {
        LABiometryType biometryType = [self getLAContext].biometryType;
        if ( LABiometryTypeTouchID == biometryType ) {
            return true;
        }else{
            NSError *error = nil;
            return [[self getLAContext] canEvaluatePolicy:[self getLAPolicy] error:&error];
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


- (BOOL)judueIPhonePlatformSupportTouchID
{
    if ([[self platform] hasPrefix:@"iPhone"]) {
        if([self platform].length > 6 ){
            NSString * numberPlatformStr = [[self platform] substringWithRange:NSMakeRange(6, 1)];
            NSInteger numberPlatform = [numberPlatformStr integerValue];
            // 是否是5s以上的设备
            if(numberPlatform > 5){
                return YES;
            }
        }
    }else if([[self platform] hasPrefix:@"iPad"]){
        if([self platform].length > 4 ){
            NSString * numberPlatformStr = [[self platform] substringWithRange:NSMakeRange(4, 1)];
            NSInteger numberPlatform = [numberPlatformStr integerValue];
            // 是否是iPad3以上设备
            if(numberPlatform > 2){
                NSArray* mini2Array = @[@"iPad4,4",@"iPad4,5",@"iPad4,6"];
                for (NSString* item in mini2Array) {
                    if([[self platform] hasPrefix:item])
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
