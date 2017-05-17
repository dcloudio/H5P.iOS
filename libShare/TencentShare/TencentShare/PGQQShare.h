/*
 *------------------------------------------------------------------
 *  pandora/PGShare.h
 *  Description:
 *      上传插件头文件定义
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
#import "PGShare.h"
#import "PGQQAuthView.h"
#import "WeiboApi.h"

@interface PGQQShare : PGShare<PGShare,WeiboRequestDelegate,WeiboAuthDelegate> {
    WeiboApi *_weiboApi;
    
    NSString *_appKey;
    NSString *_appSecret;
    NSString *_redirectURI;
    
    id _auth_delegate;
    SEL _onAuthSuccessCallback;
	SEL _onAuthFailureCallback;
    
    id _send_delegate;
    SEL _onSendSuccessCallback;
	SEL _onSendFailureCallback;
}

- (NSString*)getToken;
- (void)clearAuthCallback;
- (void)clearSendCallback;

- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback;
- (BOOL)logOut;
- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback;
- (PGAuthorizeView*)getAuthorizeControl;
@end