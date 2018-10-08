
#import <Foundation/Foundation.h>
#import "WeiboSDK.h"
#import "WBHttpRequest.h"
#import "PGSinaAuthView.h"

@interface SWBEngine : NSObject <WeiboSDKDelegate,PGSINAAuthorizeViewDelegate,WBMediaTransferProtocol>{
    
    id                  temp_delegate;
	SEL                 onSuccessCallback;
	SEL                 onFailureCallback;
    
    id  _temp_send_delegate;
    SEL _onSendSuccessCallback;
    SEL _onSendFailureCallback;
}

@property (nonatomic, retain) NSString          *appKey;
@property (nonatomic, retain) NSString          *appSecret;
@property (nonatomic, retain) NSString          *accessToken;
@property (nonatomic, retain) NSString          *name;
@property (nonatomic, retain) NSString          *redirectURI;
@property (nonatomic, assign) NSTimeInterval    expireTime;
@property (nonatomic, retain) NSString          *saveRootpath;
@property(nonatomic, assign)BOOL isMeSend;
- (id)initWithAppKey:(NSString *)theAppKey
           andSecret:(NSString *)theAppSecret
      andRedirectUrl:(NSString *)theRedirectUrl
            savePath:(NSString*)path;
- (BOOL)isAuthorizeExpired;
/**
 检查用户是否安装了微博客户端程序
 @return 已安装返回YES，未安装返回NO
 */
+ (BOOL)isWeiboAppInstalled;
- (NSString*)authorizeURL;
- (BOOL)logOut;
- (void)canclePrevLogin;
- (void)logInWithDelegate:(id)requestDelegate
                onSuccess:(SEL)successCallback
                onFailure:(SEL)failureCallback;

- (void)postPictureTweetWithFormat:(NSString *)format
                              href:(NSString*)href
                             title:(NSString*)title
                           content:(NSString *)content
                               pic:(NSData *)picture
                             thumb:(NSData *)thumb
                         longitude:(NSString *)longitude
                       andLatitude:(NSString *)latitudez
                       messageType:(NSString*)msgType
                         interface:(PGShareMessageInterface)i
                             media:(NSString*)media
                          delegate:(id)requestDelegate
                         onSuccess:(SEL)successCallback
                         onFailure:(SEL)failuerCallback;
- (void)dealloc;

@end
