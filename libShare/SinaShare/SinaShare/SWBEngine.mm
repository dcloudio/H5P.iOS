
#import "SWBEngine.h"
#import "PDRCore.h"
#import "PDRToolSystemEx.h"
#import "WeiboSDK.h"
static NSString *kWBAuthorizeURL = @"https://api.weibo.com/oauth2/authorize";
static NSString *kPGWBApiKeyAccessToken = @"access_token";
static NSString *kPGWBApiKeyRrefreshToken = @"refresh_token";
static NSString *kPGWBApiKeyExpriesin = @"expires_in";
#define kRedirectURI    @"https://www.sina.com"

@interface SWBEngine()
@property(nonatomic, retain) WBSendMessageToWeiboRequest* sendMsgRequest;
@end

@implementation SWBEngine

@synthesize appKey;
@synthesize appSecret;
@synthesize accessToken;
@synthesize expireTime;
@synthesize redirectURI;
@synthesize saveRootpath;
@synthesize isMeSend;

- (id)initWithAppKey:(NSString *)theAppKey
           andSecret:(NSString *)theAppSecret
      andRedirectUrl:(NSString *)theRedirectUrl
            savePath:(NSString *)path {
    
    if (self = [super init]){
        self.appKey = theAppKey;
        self.appSecret = theAppSecret;
        self.redirectURI = theRedirectUrl;
        self.saveRootpath = path;
        [self decodeOauthInfo];
        [WeiboSDK registerApp:theAppKey];
        [WeiboSDK enableDebugMode:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleOpenURL:)
                                                     name:PDRCoreOpenUrlNotification
                                                   object:nil];
    }
    return self;
}
- (void)decodeOauthInfo {
    NSDictionary *dict = [self decodeSaveDict];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        self.accessToken = [dict objectForKey:kPGWBApiKeyAccessToken];
        self.expireTime = [[dict objectForKey:kPGWBApiKeyExpriesin] doubleValue];
    }
}

-(NSDictionary*)getSaveDict {
    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    if ( self.accessToken ) {
        [output setObject:self.accessToken forKey:kPGWBApiKeyAccessToken];
    }
    [output setObject:[NSNumber numberWithDouble:self.expireTime] forKey:kPGWBApiKeyExpriesin];
    return output;
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

- (void)saveOauthInfo{
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
}

- (NSString*)getSaveFilePath {
    return [self.saveRootpath stringByAppendingPathComponent:@"bwanis"];
}

- (NSString*)getAesKey {
    return @"htuaob_wanis";
}

- (BOOL)logOut{
    [WeiboSDK logOutWithToken:self.accessToken delegate:nil withTag:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[self getSaveFilePath] error:nil];
    self.accessToken = nil;
    self.expireTime = 0;
    return true;
}

//判断授权是否过期
//比如 你换token的时间是 A， 返回的过期时间是expire_in，当前时间是B
//A+expire_in < B 就是过期了
//A+expire_in > B就是没有过期
- (BOOL)isAuthorizeExpired{
    if ([[NSDate date] timeIntervalSince1970] > expireTime){
        return YES;
    }
    return NO;
}

/**
 检查用户是否安装了微博客户端程序
 @return 已安装返回YES，未安装返回NO
 */
+ (BOOL)isWeiboAppInstalled {
    return [WeiboSDK isWeiboAppInstalled];
}

- (void)canclePrevLogin {
    temp_delegate = nil;
    onSuccessCallback = nil;
    onFailureCallback = nil;
}

- (void)logInWithDelegate:(id)requestDelegate
                onSuccess:(SEL)successCallback
                onFailure:(SEL)failureCallback {
    temp_delegate = requestDelegate;
    onSuccessCallback = successCallback;
    onFailureCallback = failureCallback;
    
    if ( self.accessToken ) {
        if (![self isAuthorizeExpired]) {
            if ([temp_delegate respondsToSelector:successCallback]) {
                [temp_delegate performSelector:successCallback withObject:nil];
            }
            [self clearAuthCallback];
            return;
        } else {
           
        }
    }
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController ;
    if ( nil == viewController ) {
        [UIApplication sharedApplication].keyWindow.rootViewController = [PDRCore Instance].persentViewController;
    }

    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = self.redirectURI;
    request.scope = @"email,direct_messages_write";
    [WeiboSDK sendRequest:request];
    self.isMeSend = true;
}

+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod{
    if (![httpMethod isEqualToString:@"GET"]){
        return baseURL;
    }
    NSURL *parsedURL = [NSURL URLWithString:baseURL];
    NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
    NSString *query = [SWBEngine stringFromDictionary:params];
    
    return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
}

//生成url链接
+ (NSString *)stringFromDictionary:(NSDictionary *)dict{
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in [dict keyEnumerator]){
        if (!([[dict valueForKey:key] isKindOfClass:[NSString class]])){
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [dict objectForKey:key]]];
        }
        else{
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [[dict objectForKey:key] URLEncodedStringEx]]];
        }
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

- (NSString*)authorizeURL {
    NSDictionary *params = [[[NSDictionary alloc]initWithObjectsAndKeys:appKey,@"client_id",
                            redirectURI,@"redirect_uri",
                            @"mobile",@"display",
                            @"",@"scope",
                            nil] autorelease];
    NSString *urlString = [SWBEngine serializeURL:kWBAuthorizeURL
                                            params:params
                                        httpMethod:@"GET"];
    return urlString;
}

//发表一条带图片的微博
- (void)postPictureTweetWithFormat:(NSString *)format
                              href:(NSString*)href
                             title:(NSString*)title
                           content:(NSString *)content
                               pic:(NSData *)picture
                             thumb:(NSData *)thumb
                         longitude:(NSString *)longitude
                       andLatitude:(NSString *)latitude
                       messageType:(NSString*)msgType
                         interface:(PGShareMessageInterface)interface
                             media:(NSString*)media
                          delegate:(id)requestDelegate
                         onSuccess:(SEL)successCallback
                         onFailure:(SEL)failuerCallback {
    _temp_send_delegate = requestDelegate;
    _onSendSuccessCallback = successCallback;
    _onSendFailureCallback = failuerCallback;
    if (  PGShareMessageInterfaceSlient != interface
        && [WeiboSDK isWeiboAppInstalled] ) {
        WBMessageObject *message = [WBMessageObject message];
        
        if (msgType && [msgType isKindOfClass:[NSString class]] && [msgType isEqualToString:@"none"]) {
            if (picture != nil) {
                msgType = @"image";
            }else{
                msgType = @"text";
            }
        }
        
        
        if (msgType && [msgType isKindOfClass:[NSString class]]) {
            
            if (href == nil) {
                message.text = content;
            }else{
                message.text = [NSString stringWithFormat:@"%@ %@", content, href];
            }
            
            if([msgType isEqualToString:@"image"]){
                WBImageObject *imagObejct = [WBImageObject object];
                imagObejct.imageData = picture;
                message.imageObject = imagObejct;
            }else if([msgType isEqualToString:@"music"]){
                
            }else if([msgType isEqualToString:@"video"]){
                WBNewVideoObject* videoObject = [WBNewVideoObject object];
                videoObject.delegate = self;
                videoObject.isShareToStory = YES;
                [videoObject addVideo:[NSURL URLWithString:media]];
                message.videoObject = videoObject;
            }
        }
        
        WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
        authRequest.redirectURI = kRedirectURI;
        authRequest.scope = @"all";
        _sendMsgRequest = [[WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:self.accessToken] retain];

        if (![msgType isEqualToString:@"video"]) {
            [WeiboSDK sendRequest:_sendMsgRequest];
        }
        
//        WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message];
//        request.shouldOpenWeiboAppInstallPageIfNotInstalled = NO;
//        [WeiboSDK sendRequest:request];
        self.isMeSend = true;
    } else {
        if ( PGShareMessageInterfaceEditable == interface ) {
            if ([_temp_send_delegate respondsToSelector:_onSendFailureCallback]) {
                [_temp_send_delegate performSelector:_onSendFailureCallback
                                          withObject:[self getErrorWithCode:-101]];
            }
            return;
        }
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithCapacity:5];
        NSMutableString *sendContent = [NSMutableString string];
        if ( title ) {
            [sendContent appendString:title];
            [sendContent appendString:@", "];
        }
        if ( content ) {
            [sendContent appendString:content];
            [WeiboSDK shareToWeibo:content];
            if ([_temp_send_delegate respondsToSelector:_onSendSuccessCallback]) {
                    [_temp_send_delegate performSelector:_onSendSuccessCallback withObject:nil];
            }
        }else{
            if ([_temp_send_delegate respondsToSelector:_onSendFailureCallback]) {
                // 用户未安装微博客户端时只能发送文字，如果文字不存在则提示用户安装微博客户端
                [_temp_send_delegate performSelector:_onSendFailureCallback withObject:[self getErrorWithCode:-102]];
            }
        }
               
        [dic release];
    }
}

// 存储刷新accesstoken信息
- (void)clearAuthCallback {
    temp_delegate = nil;
    onSuccessCallback = nil;
    onFailureCallback = nil;
}

#pragma mark - SWBAuthorizeViewController delegate
- (void)authorizeView:(PGSINAAuthorizeView *)webView didSucceedWithAccessToken:(NSDictionary *)code {
    self.accessToken = [code objectForKey:@"access_token"];
    self.expireTime = [[NSDate date] timeIntervalSince1970]+ [[code objectForKey:@"expires_in"] intValue];
    [self saveOauthInfo];
}

- (void)authorizeView:(PGSINAAuthorizeView *)authorize didFailuredWithError:(NSError *)error {

}

#pragma mark - SDK Methods
- (void)handleWeiboResponse:(WBBaseResponse*)response {
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class]) {
        WBSendMessageToWeiboResponse *sendResponse = (WBSendMessageToWeiboResponse*)response;
        if ( WeiboSDKResponseStatusCodeSuccess == sendResponse.statusCode ) {
            if ([_temp_send_delegate respondsToSelector:_onSendSuccessCallback]) {
                [_temp_send_delegate performSelector:_onSendSuccessCallback withObject:nil];
            }
        } else {
            if ([_temp_send_delegate respondsToSelector:_onSendFailureCallback]) {
                [_temp_send_delegate performSelector:_onSendFailureCallback withObject:[self getErrorWithCode:sendResponse.statusCode]];
            }
        }
    } else if ([response isKindOfClass:WBAuthorizeResponse.class]) {
        WBAuthorizeResponse *authResponse = (WBAuthorizeResponse*)response;
        if ( WeiboSDKResponseStatusCodeSuccess == response.statusCode ) {
            self.accessToken = authResponse.accessToken;
            self.expireTime = [authResponse.expirationDate timeIntervalSince1970];
            [self saveOauthInfo];
            if ([temp_delegate respondsToSelector:onSuccessCallback]) {
                [temp_delegate performSelector:onSuccessCallback withObject:nil];
            }
        } else {
            // self.authenticated = NO;
            self.accessToken = nil;
            self.expireTime = 0;
            [self saveOauthInfo];
            if ([temp_delegate respondsToSelector:onFailureCallback]) {
                [temp_delegate performSelector:onFailureCallback withObject:[self getErrorWithCode:authResponse.statusCode]];
            }
        }
        [self clearAuthCallback];
    }
}

- (NSError*)getErrorWithCode:(int)statusCode {
    NSString *errorMessage =@"Unknown";
    switch (statusCode) {
        case WeiboSDKResponseStatusCodeUserCancel:
            errorMessage = @"用户取消发送";
            break;
        case WeiboSDKResponseStatusCodeSentFail:
            errorMessage = @"发送失败";
            break;
        case WeiboSDKResponseStatusCodeAuthDeny:
            errorMessage = @"授权失败";
            break;
        case WeiboSDKResponseStatusCodeUserCancelInstall:
            errorMessage = @"用户取消安装微博客户端";
            break;
        case -101:
            errorMessage = @"编辑需要安装微博客户端";
            break;
        case -102:
            errorMessage = @"发送失败，用户需要安装微博客户端";
            break;
        default:
            break;
    }
    
    NSError *error = [NSError errorWithDomain:@"新浪微博" code:statusCode userInfo:@{NSLocalizedDescriptionKey:errorMessage, @"url":@"http://open.weibo.com/wiki/Error_code"}];
    return error;
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {}
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    [self performSelector:@selector(handleWeiboResponse:) withObject:response afterDelay:0.1f];
}

- (void)handleOpenURL:(NSNotification*)notification {
    NSURL *url = [notification object];
    if ( self.isMeSend ) {
        [WeiboSDK handleOpenURL:url delegate:self];
        self.isMeSend = false;
    }
}

#pragma mark video delegate
/**
 数据准备成功回调
 */
-(void)wbsdk_TransferDidReceiveObject:(id)object{
    [WeiboSDK sendRequest:_sendMsgRequest];
}

/**
 数据准备失败回调
 */
-(void)wbsdk_TransferDidFailWithErrorCode:(WBSDKMediaTransferErrorCode)errorCode andError:(NSError*)error{
    
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PDRCoreOpenUrlNotification
                                                  object:nil];
    self.appKey = nil;
    self.appSecret = nil;
    self.redirectURI = nil;
    self.accessToken = nil;
    self.saveRootpath = nil;

    [super dealloc];
}

@end
