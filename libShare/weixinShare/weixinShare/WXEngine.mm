
#import "WXEngine.h"
#import "PDRCore.h"
#import "PDRCommonString.h"
#import "PDRToolSystemEx.h"

#define kWXURLSchemePrefix              @"WX_"

#define kWXKeychainServiceNameSuffix    @"_WeiXinServiceName"
#define kWXKeychainAccessToken          @"WeiBoAccessToken"
#define kWXKeychainExpireTime           @"WeiBoExpireTime"
#define kWXKeychainName                 @"WeiBoName"

@implementation WXEngine

@synthesize accessToken;
@synthesize name;
@synthesize expireTime;


- (id)initWithAppid:(NSString*)appid {
    if (self = [super init]){
       // [self readAuthorizeDataFromKeychain];
        self.isAppidValid = [WXApi registerApp:appid];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleOpenURL:)
                                                     name:PDRCoreOpenUrlNotification
                                                   object:nil];
    }
    return self;
}

+ (BOOL)isAppInstalled {
    return [WXApi isWXAppInstalled];
}

- (void)logInWithDelegate:(id)requestDelegate
                onSuccess:(SEL)successCallback
                onFailure:(SEL)failureCallback {
//    temp_delegate = requestDelegate;
//    onSuccessCallback = successCallback;
//    onFailureCallback = failureCallback;
    //SendAuthReq* req = [[[SendAuthReq alloc] init] autorelease];
   // req.scope = @"post_timeline";
    //[WXApi sendReq:req];
    if ( !self.isAppidValid ) {
        NSError *error = [self getErrorWithCode:WXEngineErrorInvaildAppid withMessage:nil];
        [requestDelegate performSelector:failureCallback withObject:error];
        return;
    }
    if ( [requestDelegate respondsToSelector:successCallback] ) {
        [requestDelegate performSelector:successCallback withObject:nil];
    }
}

- (BOOL)logOut {
    //[self deleteAuthorizeDataInKeychain];
    return TRUE;
}

//发表一条带图片的微博
- (void)postPictureTweetWithFormat:(NSString *)format
                              href:(NSString*)href
                           content:(NSString *)content
                               pic:(NSData *)picture 
                         longitude:(NSString *)longitude
                       andLatitude:(NSString *)latitude
                          delegate:(id)requestDelegate
                         onSuccess:(SEL)successCallback
                         onFailure:(SEL)failuerCallback {
}

- (NSString *)urlSchemeString{
    return [NSString stringWithFormat:@"%@%@", kWXURLSchemePrefix, @""];
}
/*
- (BOOL)saveAuthorizeDataToKeychain{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWXKeychainServiceNameSuffix];
	BOOL accessTokenSaveOK = [SFHFKeychainUtilsEx storeUsername:kWXKeychainAccessToken andPassword:accessToken forServiceName:serviceName updateExisting:YES error:nil];
    BOOL expireTimeSaveOK = [SFHFKeychainUtilsEx storeUsername:kWXKeychainExpireTime andPassword:[NSString stringWithFormat:@"%lf", expireTime] forServiceName:serviceName updateExisting:YES error:nil];
    BOOL nameSaveOK = [SFHFKeychainUtilsEx storeUsername:kWXKeychainName andPassword:name forServiceName:serviceName updateExisting:YES error:nil];
    return accessTokenSaveOK && expireTimeSaveOK && nameSaveOK;
}

- (void)readAuthorizeDataFromKeychain{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWXKeychainServiceNameSuffix];
    self.accessToken = [SFHFKeychainUtilsEx getPasswordForUsername:kWXKeychainAccessToken andServiceName:serviceName error:nil];
    self.expireTime = [[SFHFKeychainUtilsEx getPasswordForUsername:kWXKeychainExpireTime andServiceName:serviceName error:nil] doubleValue];
    self.name = [SFHFKeychainUtilsEx getPasswordForUsername:kWXKeychainName andServiceName:serviceName error:nil];
}

- (BOOL)deleteAuthorizeDataInKeychain{
    self.accessToken = nil;
    self.expireTime = 0;
    self.name = nil;
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWXKeychainServiceNameSuffix];
	BOOL accessTokenDeleteOK = [SFHFKeychainUtilsEx deleteItemForUsername:kWXKeychainAccessToken andServiceName:serviceName error:nil];
	BOOL expireTimeDeleteOK = [SFHFKeychainUtilsEx deleteItemForUsername:kWXKeychainExpireTime andServiceName:serviceName error:nil];
    BOOL nameDeleteOK = [SFHFKeychainUtilsEx deleteItemForUsername:kWXKeychainName andServiceName:serviceName error:nil];
    return accessTokenDeleteOK && expireTimeDeleteOK && nameDeleteOK;
}
*/
//判断授权是否过期
//比如 你换token的时间是 A， 返回的过期时间是expire_in，当前时间是B
//A+expire_in < B 就是过期了
//A+expire_in > B就是没有过期
- (BOOL)isAuthorizeExpired{
    if ([[NSDate date] timeIntervalSince1970] > expireTime){
       // [self deleteAuthorizeDataInKeychain];
        return YES;
    }
    return NO;
}

//发表一条带图片的微博
- (void)postPictureTweetWithContent:(NSString *)content
                              title:(NSString *)title
                               href:(NSString*)href
                                pic:(NSData *)picture
                              thumb:(NSData*)thumb
                              media:(NSString*)mediaURL
                          longitude:(NSString *)longitude
                        andLatitude:(NSString *)latitude
                              scene:(int)sence
                        miniProgram:(NSDictionary*)programContent
                               type:(NSString*)messageType
                           delegate:(id)requestDelegate
                          onSuccess:(SEL)successCallback
                          onFailure:(SEL)failuerCallback {
    BOOL ret = FALSE;
    
    if ( !self.isAppidValid ) {
        NSError *error = [self getErrorWithCode:WXEngineErrorInvaildAppid withMessage:nil];
        [requestDelegate performSelector:failuerCallback withObject:error];
        return;
    }
    
    if ( ![WXApi isWXAppInstalled] ) {
        if ( [requestDelegate respondsToSelector:failuerCallback] ) {
            NSError *error = [self getErrorWithCode:WXEngineErrorNotInstall withMessage:nil];
            
            [requestDelegate performSelector:failuerCallback withObject:error];
        }
        return;
    }
    
    if ( ![WXApi isWXAppSupportApi] ) {
        if ( [requestDelegate respondsToSelector:failuerCallback] ) {
            NSError *error = [self getErrorWithCode:WXErrCodeUnsupport withMessage:nil];
            [requestDelegate performSelector:failuerCallback withObject:error];
        }
        return;
    }
    
    if (messageType && [messageType isKindOfClass:[NSString class]]) {
        SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
        req.bText = NO;
        req.scene = sence;
        req.text = title?title:content;
        
        // 如果没设置默认的分享类型，
        // 如果有URL则默认为web
        // 如果有图片默认为image
        // 否则默认为text
        if ([messageType isEqualToString:@"none"]) {
            if (href != nil) {
                messageType = @"web";
            }else if(picture != nil){
                messageType = @"image";
            }else{
                messageType = @"text";
            }
        }
        
        if ([messageType isEqualToString:@"text"]) {
            req.bText = YES;
            
        }else{
            WXMediaMessage* message = [WXMediaMessage message];
            message.title = title?title:@"";
            message.description = content?content:@"";
            
            if ( thumb ){
                if ( [thumb length] > 32*1024 ) {
                    if (![messageType isEqualToString:@"miniProgram"]) {
                        thumb = [UIImage compressImageData:thumb toMaxSize:32*1024];
                    }
                }else{
                    message.thumbData = thumb;
                }
            }
            
            if ([messageType isEqualToString:@"image"]) {
                WXImageObject* imageObj = [WXImageObject object];
                imageObj.imageData = picture;
                message.mediaObject = imageObj;
                message.description = content;
            }else if ([messageType isEqualToString:@"music"]) {
                WXMusicObject* music = [WXMusicObject object];
                music.musicUrl = mediaURL;
                music.musicLowBandUrl = mediaURL;
                music.musicDataUrl = mediaURL;
                music.musicLowBandDataUrl = mediaURL;
                message.mediaObject = music;
            }else if ([messageType isEqualToString:@"video"]) {
                WXVideoObject* video = [WXVideoObject object];
                video.videoUrl = mediaURL;
                video.videoLowBandUrl = mediaURL;
                message.mediaObject = video;
            }else if ([messageType isEqualToString:@"web"]) {
                WXWebpageObject* webpage = [WXWebpageObject object];
                webpage.webpageUrl = href;
                message.mediaObject = webpage;
            }else if ([messageType isEqualToString:@"miniProgram"]) {
                // 微信小程序不能分享到微信的朋友圈，用户分享小程序是ShareMessageExtra必须设置。
                NSString* userID  = [programContent objectForKey:g_pdr_string_id];
                NSString* path = [programContent objectForKey:@"path"];
                int type = [[programContent objectForKey:@"type"] intValue];
                NSString* webURL = [programContent objectForKey:@"webUrl"];
                if (webURL && userID) {
                    WXMiniProgramObject* program = [WXMiniProgramObject object];
                    program.userName = userID;
                    program.path = path;
                    program.webpageUrl = webURL;
                    program.miniProgramType = (WXMiniProgramType)type;
                    if (thumb.length >= 128*1024) {
                        thumb = [UIImage compressImageData:thumb toMaxSize:128*1024];;
                    }
                    program.hdImageData = thumb;
                    message.mediaObject = program;
                }
            }
            req.message = message;
        }
        ret = [WXApi sendReq:req];
    }

    if ( !ret ) {
        if ( [requestDelegate respondsToSelector:failuerCallback] ) {
            NSError *error = [self getErrorWithCode:WXEngineErrorUnknow withMessage:@"未知错误"];
            [requestDelegate performSelector:failuerCallback withObject:error];
        }
    } else {
        temp_send_delegate = requestDelegate;
        onSendSuccessCallback = successCallback;
        onSendFailureCallback = failuerCallback;
    }
}


#pragma mark - SDK Methods
-(void) onReq:(BaseReq*)req
{
    /*
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        [self onRequestAppMessage];
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
        [self onShowMediaMessage:temp.message];
    }*/
    
}

-(void) onResp:(BaseResp*)resp {
    if([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *authresp = (SendMessageToWXResp*)resp;
        if ( WXSuccess == authresp.errCode ) {
            if ( [temp_send_delegate respondsToSelector:onSendSuccessCallback] ) {
                [temp_send_delegate performSelector:onSendSuccessCallback withObject:nil];
            }
        } else {
            if ( [temp_send_delegate respondsToSelector:onSendFailureCallback] ) {
                NSError *error = [self getErrorWithCode:authresp.errCode withMessage:authresp.errStr];
                [temp_send_delegate performSelector:onSendFailureCallback withObject:error];
            }
        }
    }/* else if([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *authresp = (SendAuthResp*)resp;
        if ( WXSuccess == authresp.errCode ) {
            self.accessToken = authresp.token;
            self.expireTime = [authresp.expireDate timeIntervalSince1970];
            self.name = authresp.userName;
            [self saveAuthorizeDataToKeychain];
            if ( [temp_delegate respondsToSelector:onSuccessCallback] ) {
                [temp_delegate performSelector:onSuccessCallback withObject:nil];
            }
        } else {
            if ( [temp_delegate respondsToSelector:onFailureCallback] ) {
                NSError *error = [NSError errorWithDomain:@"WXEngine" code:authresp.errCode userInfo:nil];
                [temp_delegate performSelector:onFailureCallback withObject:error];
            }
        }
    }*/
}

- (void)handleOpenURL:(NSNotification*)notification {
    [WXApi handleOpenURL:[notification object] delegate:self];
}

- (NSError*)getErrorWithCode:(int)code withMessage:(NSString*)message {
#define SWITH_CASE(c,p) case c:\
    message = p; break;
    if ( !message ) {
        switch (code) {
            SWITH_CASE(WXErrCodeUserCancel, @"用户点击取消并返回")
            SWITH_CASE(WXErrCodeSentFail, @"发送失败")
            SWITH_CASE(WXErrCodeAuthDeny,  @"授权失败")
            SWITH_CASE(WXErrCodeUnsupport,  @"微信不支持")
            SWITH_CASE(WXEngineErrorInvaildAppid, @"appid无效或配置错误")
            SWITH_CASE(WXEngineErrorNotInstall, @"微信未安装")
            SWITH_CASE(WXEngineErrorLargeThumb, @"缩略图超过限制")
            SWITH_CASE(WXEngineErrorLargeImage,  @"图片超过限制")
            default:
                break;
        }
    }
    
    NSError *error = [NSError errorWithDomain:@"微信分享" code:code
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil]];
    return error;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PDRCoreOpenUrlNotification
                                                  object:nil];
    self.accessToken = nil;
    self.name = nil;
    [super dealloc];
}

@end
