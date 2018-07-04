//
//  QQShare.m
//  QQShare
//
//  Created by X on 15/3/17.
//  Copyright (c) 2015年 io.dcloud.QQShare. All rights reserved.
//

#import "PGTencentQQShare.h"
#import "PTPathUtil.h"
#import "PDRCore.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import "PDRCoreAppPrivate.h"

@implementation PGTencentQQShare
- (id) init {
    if ( self = [super init] ) {
        NSString *appid = nil;
        NSArray *urlSchemes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
        for (NSDictionary *urlScheme in urlSchemes ) {
            NSString *urlName = [urlScheme objectForKey:@"CFBundleURLName"];
            if ( NSOrderedSame == [@"tencentopenapi" caseInsensitiveCompare:urlName] ) {
                NSArray *appids = [urlScheme objectForKey:@"CFBundleURLSchemes"];
                appid = [appids objectAtIndex:0];
                NSRange range = [appid rangeOfString:@"tencent"];
                if ( 0 == range.location ) {
                    appid = [appid substringFromIndex:range.length];
                }
                break;
            }
        }
        onSendSuccessCallback = nil;
        onSendFailureCallback = nil;
        temp_send_delegate = nil;
        self.type = @"qq";
        self.note = @"QQ";
        self.sdkErrorURL = @"http://ask.dcloud.net.cn/article/287";
        if ( appid ) {
            self.accessToken = nil;
            self.authenticated = TRUE;
            _tencentOAuth = [[TencentOAuth alloc] initWithAppId:appid
                                                    andDelegate:nil];
            self.nativeClient = [TencentOAuth iphoneQQInstalled];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleOpenURL:)
                                                         name:PDRCoreOpenUrlNotification
                                                       object:nil];
            return self;
        }
    }
    return self;
}

- (NSString*)getToken {
    return @"";
}

- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback{
    
    NSData *imageData = nil;
    NSData *thumbData = nil;
    
    temp_send_delegate = delegate;
    onSendSuccessCallback = successCallback;
    onSendFailureCallback = failureCallback;
    
    if ( msg.sendPict ) {
        NSURL *url = [PTPathUtil urlWithPath:msg.sendPict];//[NSURL fileURLWithPath:msg.sendPict];
        imageData = [NSData dataWithContentsOfURL:url];
    }
    if ( msg.sendThumb ) {
        NSURL *url = [PTPathUtil urlWithPath:msg.sendThumb];//[NSURL fileURLWithPath:msg.sendPict];
        thumbData = [NSData dataWithContentsOfURL:url];
    }
    
    SendMessageToQQReq *req = nil;
    if ( msg.href ) {
        if ( !thumbData ) {
            if ( self.appContext.isStreamApp
                && self.appContext.iconPath ) {
                thumbData = [NSData dataWithContentsOfFile:self.appContext.iconPath];
            }
        }
        QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:[NSURL URLWithString:msg.href]
                                                            title:msg.title?msg.title:@" "
                                                      description:msg.content
                                                 previewImageData:thumbData];
        req = [SendMessageToQQReq reqWithContent:newsObj];
    } else if ( msg.sendPict ) {
        QQApiImageObject *imageObject = [[QQApiImageObject alloc] initWithData:imageData
                                                              previewImageData:thumbData
                                                                         title:msg.title?msg.title:@" "
                                                                   description:msg.content];
        req = [SendMessageToQQReq reqWithContent:imageObject];
    } else {
        NSMutableString *textContent = [NSMutableString string];
        if ( msg.title ) {
            [textContent appendFormat:@"[%@]", msg.title];
        }
        [textContent appendString:msg.content? msg.content:@""];
        QQApiTextObject *txtObj = [QQApiTextObject objectWithText:textContent];
        req = [SendMessageToQQReq reqWithContent:txtObj];
    }
    //将内容分享到qq
    QQApiSendResultCode sent = [QQApiInterface sendReq:req];
    if ( EQQAPISENDSUCESS != sent ) {
        if ( [temp_send_delegate respondsToSelector:onSendFailureCallback] ) {
            [temp_send_delegate performSelector:onSendFailureCallback withObject:[self genErrorWithCode:sent description:nil]];
        }
    }
    return TRUE;
}

- (BOOL)logOut {
    return TRUE;
}

- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id<NSObject>)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback  {
    self.nativeClient = [TencentOAuth iphoneQQInstalled];
    self.authenticated = TRUE;
    if ( self.nativeClient ) {
        if ( [delegate respondsToSelector:successCallback] ) {
            [delegate performSelector:successCallback withObject:nil];
        }
        return TRUE;
    }
    if ( [delegate respondsToSelector:failureCallback] ) {
        [delegate performSelector:failureCallback withObject:[self genErrorWithCode:EQQAPIQQNOTINSTALLED description:nil]];
    }
    return TRUE;
}

- (NSError*)genErrorWithCode:(NSInteger)errorCode description:(NSString*)message {
    if ( nil == message ) {
        switch (errorCode) {
            case EQQAPIQQNOTINSTALLED:
                message = @"未安装QQ";
                break;
            case EQQAPISENDFAILD:
                message = @"发送失败";
                break;
            case EQQAPIAPPNOTREGISTED:
                message = @"app未注册";
                break;
            case EQQAPIQZONENOTSUPPORTTEXT:
                message = @"qzone分享不支持text类型分享";
                break;
            case EQQAPIQZONENOTSUPPORTIMAGE:
                message = @"qzone分享不支持image类型分享";
                break;
            default:
                message = @"未知错误";
                break;
        }
    }
     NSError *error = [NSError errorWithDomain:@"QQ分享" code:errorCode
                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil]];
    return error;
}

- (void)handleOpenURL:(NSNotification*)notification {
    [QQApiInterface handleOpenURL:[notification object] delegate:self];
}
/**
    处理来至QQ的响应
    */
-(void)onResp:(QQBaseResp *)resp {
    if ( [resp isKindOfClass:[SendMessageToQQResp class]] ) {
        SendMessageToQQResp *sendMessageResp = (SendMessageToQQResp*)resp;
        if ( sendMessageResp && [sendMessageResp.result intValue] == 0 ) {
            if ( [temp_send_delegate respondsToSelector:onSendSuccessCallback] ) {
                [temp_send_delegate performSelector:onSendSuccessCallback withObject:nil];
            }
        } else {
            if ( [temp_send_delegate respondsToSelector:onSendFailureCallback] ) {
                [temp_send_delegate performSelector:onSendFailureCallback
                                         withObject:[self genErrorWithCode:[sendMessageResp.result intValue]
                                                               description:sendMessageResp.errorDescription]];
            }
        }
    }
}

/**
 处理来至QQ的请求
 */
- (void)onReq:(QQBaseReq *)req{}

/**
 处理QQ在线状态的回调
 */
- (void)isOnlineResponse:(NSDictionary *)response {}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PDRCoreOpenUrlNotification object:nil];
    [_tencentOAuth release];
    [super dealloc];
}

@end
