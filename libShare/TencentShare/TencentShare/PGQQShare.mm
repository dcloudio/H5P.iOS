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
#import "PGQQShare.h"
#import "PDRToolSystemEx.h"
#import "PTPathUtil.h"
#import "PDRCore.h"

@implementation PGQQShare

- (id) init {
    if ( self = [super init] ) {
        if ( [PTDeviceOSInfo systemVersion] < PTSystemVersion6Series  ) {
            return nil;
        }
        NSDictionary *dhDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"tencentweibo"];
        if ( [dhDict isKindOfClass:[NSDictionary class]] ) {
            _appKey = [[dhDict objectForKey:@"appkey"] copy];
            _appSecret = [[dhDict objectForKey:@"appSecret"] copy];
            _redirectURI = [[dhDict objectForKey:@"redirectURI"] copy];
            if ( _appKey && _appSecret && _redirectURI ) {
                self.type = @"tencentweibo";
                self.note = @"腾讯微博";
                self.sdkErrorURL = @"http://ask.dcloud.net.cn/article/287";
                _weiboApi = [[WeiboApi alloc]initWithAppKey:_appKey
                                                  andSecret:_appSecret
                                             andRedirectUri:_redirectURI andAuthModeFlag:TCWBModelWebviewAuth andCachePolicy:0] ;
                
                WeiboApiObject *apiObject = [_weiboApi getToken];
                if ( apiObject.accessToken ) {
                    if ( [self isAuthorizeExpired:apiObject.expires] ) {
                        [_weiboApi cancelAuth];
                    } else {
                        self.authenticated = YES;
                        self.accessToken = apiObject.accessToken;
                    }
                }
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(handleOpenURL:)
                                                             name:PDRCoreOpenUrlNotification
                                                           object:nil];
                return self;
            }
        }
    }
    return self;
}
- (BOOL)isAuthorizeExpired:(NSTimeInterval)expireTime{
    if ([[NSDate date] timeIntervalSince1970] > expireTime){
        return YES;
    }
    return NO;
}

- (NSString*)getToken {
    WeiboApiObject *apiObject = [_weiboApi getToken];
    return apiObject.accessToken;
}

- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback{

    _send_delegate = delegate;
    _onSendSuccessCallback = successCallback;
    _onSendFailureCallback = failureCallback;
    
    NSData *imageData = nil;
    if ( msg.sendPict ) {
        NSURL *url = [PTPathUtil urlWithPath:msg.sendPict];//[NSURL fileURLWithPath:msg.sendPict];
        imageData = [NSData dataWithContentsOfURL:url];
        //imageData = [UIImage imageWithContentsOfFile:msg.sendPict];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"json" forKey:@"format"];
    if ( msg.content || msg.href) {
        NSMutableString *sendContent = [NSMutableString string];
        if ( msg.content ) {
            [sendContent appendString:msg.content];
        }
        
        if ( [msg.href length] ) {
            [sendContent appendFormat:@" %@", msg.href];
        }
        [params setObject:sendContent forKey:@"content"];
    }
    if ( msg.longitude ) {
        [params setObject:msg.longitude forKey:@"longitude"];
    }
    if ( msg.latitude ) {
        [params setObject:msg.latitude forKey:@"latitude"];
    }
    if ( imageData ) {
        [params setObject:imageData forKey:@"pic"];
    }

    [_weiboApi requestWithParams:params apiName:@"t/add_pic" httpMethod:@"POST" delegate:self];
    return TRUE;
}

- (BOOL)logOut {
    [_weiboApi cancelAuth];
    return TRUE;
}

- (void)handleOpenURL:(NSNotification*)notification {
    [_weiboApi handleOpenURL:[notification object]];
}

- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback  {
    
    _auth_delegate = delegate;
    _onAuthSuccessCallback = successCallback;
	_onAuthFailureCallback = failureCallback;
    UIViewController *rootViewController = [self rootViewController];//[UIApplication sharedApplication].keyWindow.rootViewController;
    [_weiboApi loginWithDelegate:self andRootController:rootViewController];
    return TRUE;
}

- (BOOL)cancelPrevAuthorize{
    _auth_delegate = nil;
    _onAuthSuccessCallback = nil;
    _onAuthFailureCallback = nil;
    return YES;
}

- (void)clearAuthCallback {
    _auth_delegate = nil;
    _onAuthFailureCallback = nil;
    _onAuthSuccessCallback = nil;
}

- (void)clearSendCallback {
    _send_delegate = nil;
    _onSendSuccessCallback = nil;
    _onSendFailureCallback = nil;
}

#pragma mark WeiboAuthDelegate
- (void)didReceiveRawData:(NSData *)data reqNo:(int)reqno
{
    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_send_delegate respondsToSelector:_onSendSuccessCallback]) {
            [_send_delegate performSelector:_onSendSuccessCallback withObject:nil];
            [self clearSendCallback];
        }
    });
}

- (void)didFailWithError:(NSError *)error reqNo:(int)reqno
{
    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_send_delegate respondsToSelector:_onSendSuccessCallback]) {
            [_send_delegate performSelector:_onSendSuccessCallback withObject:error];
            [self clearSendCallback];
        }
    });
}

- (void)didNeedRelogin:(NSError *)error reqNo:(int)reqno {
    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_send_delegate respondsToSelector:_onSendSuccessCallback]) {
            [_send_delegate performSelector:_onSendSuccessCallback withObject:error];
            [self clearSendCallback];
        }
    });
}

#pragma mark WeiboAuthDelegate
//- (void)DidAuthRefreshed:(WeiboApiObject *)wbobj
//{
//    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
//    dispatch_async(dispatch_get_main_queue(), ^{
//    });
//}
//
///**
// * @brief   重刷授权失败后的回调
// * @param   INPUT   error   标准出错信息
// * @return  无返回
// */
//- (void)DidAuthRefreshFail:(NSError *)error
//{
//    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
//    dispatch_async(dispatch_get_main_queue(), ^{
//    });
//}

/**
 * @brief   授权成功后的回调
 * @param   INPUT   wbapi 成功后返回的WeiboApi对象，accesstoken,openid,refreshtoken,expires 等授权信息都在此处返回
 * @return  无返回
 */
- (void)DidAuthFinished:(WeiboApiObject *)wbobj
{
    self.authenticated = YES;
    self.accessToken = wbobj.accessToken;
    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_auth_delegate respondsToSelector:_onAuthSuccessCallback]) {
            [_auth_delegate performSelector:_onAuthSuccessCallback withObject:nil];
            [self clearAuthCallback];
        }
    });
}

/**
 * @brief   授权成功后的回调
 * @param   INPUT   wbapi   weiboapi 对象，取消授权后，授权信息会被清空
 * @return  无返回
 */
- (void)DidAuthCanceled:(WeiboApi *)wbapi_
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_auth_delegate respondsToSelector:_onAuthFailureCallback]) {
            NSError *error = [NSError errorWithDomain:@"" code:PGPluginErrorUserCancel userInfo:nil];
            [_auth_delegate performSelector:_onAuthFailureCallback withObject:error];
            [self clearAuthCallback];
        }
    });
}

/**
 * @brief   授权成功后的回调
 * @param   INPUT   error   标准出错信息
 * @return  无返回
 */
- (void)DidAuthFailWithError:(NSError *)error
{
    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_auth_delegate respondsToSelector:_onAuthFailureCallback]) {
            NSString *codeKey = [error.userInfo objectForKey:@"TCSDKErrorCodeKey"];
            NSError *newError = [NSError errorWithDomain:@"" code:[codeKey intValue] userInfo:nil];
            [_auth_delegate performSelector:_onAuthFailureCallback withObject:newError];
            [self clearAuthCallback];
        }
    });
}

/**
 * @brief   授权成功后的回调
 * @param   INPUT   error   标准出错信息
 * @return  无返回
 */
-(void)didCheckAuthValid:(BOOL)bResult suggest:(NSString *)strSuggestion
{
    //注意回到主线程，有些回调并不在主线程中，所以这里必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
    });
}

- (PGAuthorizeView*)getAuthorizeControl {
    PGQQAuthorizeView *authorView = [[PGQQAuthorizeView alloc] initWithFrame:CGRectZero];
    authorView.appSecret = _appSecret;
    authorView.appKey = _appKey;
    authorView.redirectURI = _redirectURI;
    authorView.authImp.requestURLString = [authorView getAuthorizeURL];
    [authorView autorelease];
    return authorView;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PDRCoreOpenUrlNotification
                                                  object:nil];
    [_redirectURI release];
    [_appKey release];
    [_appSecret release];
    [_weiboApi release];
    //[_weiboEngine release];
    [super dealloc];
}

@end
