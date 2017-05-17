
#import <Foundation/Foundation.h>
#import "WXApi.h"
#import "WXApiObject.h"

typedef enum {
    WXEngineErrorInvaildAppid = -99,
    WXEngineErrorNotInstall,
    WXEngineErrorLargeThumb,
    WXEngineErrorLargeImage,
    WXEngineErrorUnknow
} WXEngineError;

@interface WXEngine : NSObject <WXApiDelegate>{
    NSString            *accessToken;
    NSString            *name;
    
    id                  temp_send_delegate;
	SEL                 onSendSuccessCallback;
	SEL                 onSendFailureCallback;
    
    id                  temp_delegate;
	SEL                 onSuccessCallback;
	SEL                 onFailureCallback;
}
@property (nonatomic, assign) BOOL isAppidValid;
@property (nonatomic, retain) NSString          *accessToken;
@property (nonatomic, retain) NSString          *name;
@property (nonatomic, assign) NSTimeInterval    expireTime;

- (id)initWithAppid:(NSString*)appid;
+ (BOOL)isAppInstalled;
- (BOOL)isAuthorizeExpired;
- (BOOL)logOut;
- (void)logInWithDelegate:(id)requestDelegate
                onSuccess:(SEL)successCallback
                onFailure:(SEL)failureCallback;

- (void)postPictureTweetWithContent:(NSString *)content
                              title:(NSString *)title
                               href:(NSString*)href
                                pic:(NSData *)picture
                              thumb:(NSData*)thumb
                         longitude:(NSString *)longitude
                        andLatitude:(NSString *)latitude
                              scene:(int)sence
                          delegate:(id)requestDelegate
                         onSuccess:(SEL)successCallback
                         onFailure:(SEL)failuerCallback;
- (void)dealloc;

@end