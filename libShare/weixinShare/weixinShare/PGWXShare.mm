/*
 *------------------------------------------------------------------
 *  pandora/feature/PGShare
 *  Description:
 *    上传插件实现定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-22 创建文件
 *------------------------------------------------------------------
 */
#import "PGWXShare.h"
#import <GameKit/GameKit.h>
#import "PTPathUtil.h"

@implementation PGWXShare

- (id) init {
    if ( self = [super init] ) {
        NSString *appid = nil;
        NSArray *urlSchemes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
        for (NSDictionary *urlScheme in urlSchemes ) {
            NSString *urlName = [urlScheme objectForKey:@"CFBundleURLName"];
            if ( NSOrderedSame == [@"weixin" caseInsensitiveCompare:urlName] ) {
                NSArray *appids = [urlScheme objectForKey:@"CFBundleURLSchemes"];
                appid = [appids objectAtIndex:0];
                break;
            }
        }
        
        if ( appid ) {
            self.type = @"weixin";
            self.note = @"微信";
            self.sdkErrorURL = @"http://ask.dcloud.net.cn/article/287";
            _engine = [[WXEngine alloc] initWithAppid:appid];
            self.nativeClient = [WXEngine isAppInstalled];
            self.accessToken = nil;
            self.authenticated = TRUE;
            /*
            self.accessToken = nil;
            self.authenticated = FALSE;
            if (![_engine isAuthorizeExpired]) {
                self.accessToken = _engine.accessToken;
                self.authenticated = TRUE;
            } else {
                [_engine logOut];
            }*/
            return self;
        }
    }
    return self;
}

- (NSString*)getToken {
    return _engine.accessToken;
}

- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback{
    NSData *imageData = nil;
    NSData *thumbData = nil;
    if ( msg.sendPict ) {
        NSURL *url = [PTPathUtil urlWithPath:msg.sendPict];//[NSURL fileURLWithPath:msg.sendPict];
        imageData = [NSData dataWithContentsOfURL:url];
    }
    if ( msg.sendThumb ) {
        NSURL *url = [PTPathUtil urlWithPath:msg.sendThumb];//[NSURL fileURLWithPath:msg.sendPict];
        thumbData = [NSData dataWithContentsOfURL:url];
    }
    
    int shareScene = WXSceneTimeline;
    switch (msg.scene) {
        case PGShareMessageSceneSession:
            shareScene = WXSceneSession;
            break;
        case PGShareMessageSceneFavorite:
            shareScene = WXSceneFavorite;
        default:
            break;
    }
    
    [_engine postPictureTweetWithContent:msg.content
                                   title:msg.title
                                    href:msg.href
                                    pic:imageData
                                   thumb:thumbData
                                   media:msg.media
                              longitude:msg.longitude
                            andLatitude:msg.latitude
                                   scene:shareScene
                             miniProgram:msg.miniProgram
                                    type:msg.msgType
                                delegate:delegate
                              onSuccess:successCallback
                              onFailure:failureCallback];
    return TRUE;
}

- (BOOL)logOut {
    [_engine logOut];
    return TRUE;
}

- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback  {
    [_engine logInWithDelegate:delegate onSuccess:successCallback onFailure:failureCallback];
    return TRUE;
}

- (void)dealloc {
    [_engine release];
    [super dealloc];
}

@end
