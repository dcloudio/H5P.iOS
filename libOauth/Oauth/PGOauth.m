//
//  PGOauth.m
//  Oauth
//
//  Created by X on 15/3/3.
//  Copyright (c) 2015年 io.dcloud. Oauth. All rights reserved.
//

#import "PGOauth.h"
#import  "PDRCommonString.h"
#import "PDRToolSystemEx.h"
#import "PDRCore.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"

@implementation PGOauth
@synthesize identify,note;
- (NSDictionary*)JSDict {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.identify, g_pdr_string_id,
            self.note, g_pdr_string_description,
            nil];
}

-(void)initalize {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOpenURL:)
                                                 name:PDRCoreOpenUrlNotification
                                               object:nil];
}

- (void)login:(NSString*)cbId withParams:(NSDictionary*)params {

}
- (void)logout:(NSString*)cbId {

}
- (void)getUserInfo:(NSString*)cbId {

}
- (void)addPhoneNumber:(NSString*)cbId
{
}

- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGOauthErrorNeedLogin:
            return @"未登录或登录已注销";
        case PGOauthErrorNotInstall:
            return @"未安装客户端";
        case PGOauthErrorNotSupportSSOLogin:
            return @"你安装的客户端不支持授权登录";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}

- (NSDictionary*)decodeSaveDict {
    NSData *inputData = [NSData dataWithContentsOfFile:[self getSaveFilePath]];
    if ( inputData ) {
        inputData = [inputData AESDecryptWithKey:[self getAesKey]];
        if ( inputData ) {
            NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:inputData];
            if ( [dict isKindOfClass:[NSDictionary class]] ) {
                return dict;
            }
        }
    }
    return nil;
}

- (void)handleEnterBackground:(NSNotification*)notification {
    if ( self.needToSaveFile ) {
        NSDictionary *output = [self getSaveDict];
        if ( output ) {
            NSData *outputData = [NSKeyedArchiver archivedDataWithRootObject:output];
            if ( outputData ) {
                NSString *aesKey = [self getAesKey];
                if ( aesKey ) {
                    outputData = [outputData AESEncryptWithKey:aesKey];
                    if ( outputData ) {
                        [outputData writeToFile:[self getSaveFilePath] atomically:NO];
                    }
                }
            }
        }
        self.needToSaveFile = FALSE;
    }
}

- (void)handleOpenURL:(NSNotification*)notification {

}

-(NSString*)getAesKey {
    return nil;
}

-(NSString*)getSaveFilePath {
    return nil;
}

-(NSDictionary*)getSaveDict {
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRCoreOpenUrlNotification object:nil];
    [super dealloc];
}

@end
