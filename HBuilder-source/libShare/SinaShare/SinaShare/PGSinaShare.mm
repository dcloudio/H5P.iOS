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
#import "PTPathUtil.h"
#import "PGSinaShare.h"
//#import "PGSinaAuthView.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"

@implementation PGSinaShare

- (void)doInit {
    NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"sinaweibo"];
    if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
        NSString *appKey = [dhDict objectForKey:@"appkey"];
        NSString *appSecret = [dhDict objectForKey:@"appSecret"];
        NSString *redirectURI = [dhDict objectForKey:@"redirectURI"];
        if ( appKey && redirectURI ) {
            self.type = @"sinaweibo";
            self.note = @"新浪微博";
            self.sdkErrorURL = @"http://open.weibo.com/wiki/Error_code";
            self.nativeClient = [SWBEngine isWeiboAppInstalled];
            NSString* pSavepath = self.appContext.appInfo.dataPath?self.appContext.appInfo.dataPath:self.commonPath;
            _sinaEngine = [[SWBEngine alloc] initWithAppKey:appKey
                                                  andSecret:appSecret
                                             andRedirectUrl:redirectURI
                                                   savePath:pSavepath];
            if ( ![_sinaEngine isAuthorizeExpired] ) {
                self.accessToken = _sinaEngine.accessToken;
                self.authenticated = YES;
            }
        }
    }
}

- (NSString*)getToken {
    return _sinaEngine.accessToken;
}

- (BOOL)logOut {
    [_sinaEngine logOut];
    return TRUE;
}

// 使用新浪微博的web页面登录，在发送分享时还需再授权一次
- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback {
    [_sinaEngine logInWithDelegate:delegate onSuccess:successCallback onFailure:failureCallback];
    return YES;
}

- (BOOL)cancelPrevAuthorize{
    [_sinaEngine canclePrevLogin];
    return YES;
}

- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback{
    NSURL *url = nil;//

    
    if ( msg.sendPict ) {
        url = [PTPathUtil urlWithPath:msg.sendPict];//[NSURL fileURLWithPath:msg.sendPict];
    }
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    NSData *thumbData = nil;
    if ( msg.sendThumb ) {
        NSURL *url = nil;//
        if ( msg.sendThumb ) {
            url = [PTPathUtil urlWithPath:msg.sendThumb];//[NSURL fileURLWithPath:msg.sendPict];
        }
        thumbData = [NSData dataWithContentsOfURL:url];
    }
    
    if ( imageData || msg.content || msg.title ) {
        [_sinaEngine postPictureTweetWithFormat:@"json"
                                           href:msg.href
                                          title:msg.title
                                        content:msg.content
                                            pic:imageData
                                          thumb:thumbData
                                      longitude:msg.longitude
                                    andLatitude:msg.latitude
                                    messageType:msg.msgType
                                      interface:msg.interface
                                          media:msg.media
                                       delegate:delegate
                                      onSuccess:successCallback
                                      onFailure:failureCallback];
    } else {
        if ( [delegate respondsToSelector:failureCallback] ) {
            [delegate performSelector:failureCallback withObject:nil];
        }
    }
    
    return TRUE;
}

#pragma mark ShareControl

- (PGAuthorizeView*)getAuthorizeControl {
//    PGSINAAuthorizeView *authorView = [[PGSINAAuthorizeView alloc] initWithFrame:CGRectZero];
//    authorView.authorizeViewDeleagte = _sinaEngine;
//    authorView.requestURLString = [_sinaEngine authorizeURL];
//    authorView.appKey = _sinaEngine.appKey;
//    authorView.appSecret = _sinaEngine.appSecret;
//    authorView.redirectURI = _sinaEngine.redirectURI;
//    [authorView autorelease];
//    return authorView;
    return nil;
}

- (void)dealloc {
    [_sinaEngine release];
    [super dealloc];
}

@end
