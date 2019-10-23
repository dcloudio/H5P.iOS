//
//  PGProximity.m
//  PGProximity
//
//  Created by X on 13-8-6.
//  Copyright (c) 2013年 io.dcloud. All rights reserved.
//

#import "PGProximity.h"

@implementation PGProximity

@synthesize started;
@synthesize callBackID;

- (void)getCurrentProximity:(PGMethod*)command {
    NSString *cbID = [command.arguments objectAtIndex:0];
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
    if ( device.proximityMonitoringEnabled == YES ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:device.proximityState?0:-1];
        [self toCallback:cbID withReslut:[result toJSONString]];
        device.proximityMonitoringEnabled = NO;
    } else {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:PGPluginErrorNotSupport
                                                        withMessage:[self errorMsgWithCode:PGPluginErrorNotSupport]];
        [self toCallback:cbID withReslut:[result toJSONString]];
    }
}

- (void)__start {
    if ( !self.started ) {
        UIDevice *device = [UIDevice currentDevice];
        device.proximityMonitoringEnabled = YES;
        if ( device.proximityMonitoringEnabled ) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(proximityChanged:)
                                                         name:UIDeviceProximityStateDidChangeNotification
                                                       object:nil];
            self.started = TRUE;
        } else {
            device.proximityMonitoringEnabled = NO;
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                   messageToErrorObject:PGPluginErrorNotSupport
                                                            withMessage:[self errorMsgWithCode:PGPluginErrorNotSupport]];
            [self toCallback:self.callBackID withReslut:[result toJSONString]];
            self.callBackID = nil;
        }
    }
}

- (void)__stop {
    if ( self.started ) {
        self.started = FALSE;
        self.callBackID = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceProximityStateDidChangeNotification
                                                      object:nil];
        
        UIDevice *device = [UIDevice currentDevice];
        device.proximityMonitoringEnabled = NO;
    }
}

- (void)start:(PGMethod*)command {
    NSString *cbID = [command.arguments objectAtIndex:0];
    self.callBackID = cbID;
    [self __start];
}

- (void)stop:(PGMethod*)command {
    [self __stop];
}

- (void)proximityChanged:(NSNotification*)notification {
   // if ( [UIDevice currentDevice].proximityState ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:[UIDevice currentDevice].proximityState?0:-1];
        [result setKeepCallback:YES];
        [self toCallback:self.callBackID withReslut:[result toJSONString]];
   // }
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    [self __stop];
}

- (void)dealloc {
    self.callBackID = nil;
    [self __stop];
    [super dealloc];
}

@end
