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
#import "PGShare.h"
#import "PDRCoreWindowManager.h"
#import "PTPathUtil.h"
#import  "PDRCommonString.h"

static NSString *kString_accesstoken = @"accessToken";
@interface PGJSRequest : NSObject {
    id _delegate;
    NSString *_onSuccessCallback;
    NSString *_onFailureCallback;
}

@property(nonatomic, assign)BOOL sendHasPendingOperation;
@property(nonatomic, copy)NSString *callBackID;
@property(nonatomic, retain)id payload;
@property(nonatomic, copy)NSString *type;

+ (PGJSRequest*)reqWithDelegate:(id)delegate
                      onSuccess:(SEL)successCallback
                      onFailure:(SEL)failureCallback;

- (void)onSuccess:(id)args;
- (void)onFailure:(id)args;

@end

@implementation PGShareMessage

@synthesize content;
@synthesize pictures;
@synthesize thumbs;
@synthesize sendPict;
@synthesize sendThumb;
@synthesize latitude;
@synthesize longitude;
@synthesize title;
@synthesize media;
@synthesize miniProgram;
@synthesize msgType;

- (id)initWithDict:(NSDictionary*)dict
{
    if ( self = [super init] ) {
        NSString *contentV = [dict objectForKey:g_pdr_string_content];
        if ( [contentV isKindOfClass:NSString.class ] ) {
            self.content = contentV;
        }
        NSString *titleV = [dict objectForKey:g_pdr_string_title];
        if ( [titleV isKindOfClass:NSString.class ] ) {
            self.title = titleV;
        }
        NSString *hrefV = [dict objectForKey:g_pdr_string_href];
        if ( [hrefV isKindOfClass:NSString.class ] ) {
            self.href = hrefV;
        }
        NSArray *picV = [dict objectForKey:@"pictures"];
        if ( [picV isKindOfClass:NSArray.class] && [picV count] ) {
            self.pictures = [NSArray arrayWithArray:picV];
        }
        NSArray *thumbsV = [dict objectForKey:@"thumbs"];
        if ( [thumbsV isKindOfClass:NSArray.class]  && [thumbsV count]) {
            self.thumbs = [NSArray arrayWithArray:thumbsV];
        }
        NSString* mediaHref = [dict objectForKey:@"media"];
        if ([mediaHref isKindOfClass:[NSString class]]) {
            self.media = mediaHref;
        }
        NSString* msgType = [dict objectForKey:g_pdr_string_type];
        if ([msgType isKindOfClass:NSString.class]) {
            self.msgType = msgType;
        }else{
            self.msgType =@"none";
        }
        
        NSDictionary* miniProgram = [dict objectForKey:@"miniProgram"];
        if ([miniProgram isKindOfClass:NSDictionary.class]) {
            self.miniProgram = [NSDictionary dictionaryWithDictionary:miniProgram];
        }
        
        NSDictionary *geo = [dict objectForKey:@"geo"];
        if ( [geo isKindOfClass:NSDictionary.class] ) {
            NSString *lat = [geo objectForKey:@"latitude"];
            if ( [lat isKindOfClass:NSString.class] ) {
                self.latitude = lat;
            } else if([lat isKindOfClass:NSNumber.class]){
                self.latitude = [(NSNumber*)lat stringValue];
            }
            NSString *lon = [geo objectForKey:@"longitude"];
            if ( [lon isKindOfClass:NSString.class] ) {
                self.longitude = lon;
            } else if([lon isKindOfClass:NSNumber.class]){
                self.longitude = [(NSNumber*)lon stringValue];
            }
        }
        NSDictionary *extra = [dict objectForKey:@"extra"];
        self.scene = PGShareMessageSceneTimeline;
        if ( [extra isKindOfClass:[NSDictionary class]] ) {
            NSString *scenceV = [extra objectForKey:@"scene"];
            if ( [scenceV isKindOfClass:[NSString class]] ) {
                if ( NSOrderedSame == [@"WXSceneSession" caseInsensitiveCompare:scenceV] ) {
                    self.scene = PGShareMessageSceneSession;
                } else if (NSOrderedSame == [@"WXSceneFavorite" caseInsensitiveCompare:scenceV]){
                    self.scene = PGShareMessageSceneFavorite;
                }
            }
        }
        NSString *jsInterface = [dict objectForKey:@"interface"];
        self.interface = PGShareMessageInterfaceAuto;
        if ( [jsInterface isKindOfClass:[NSString class]] ) {
            if ( NSOrderedSame == [@"slient" caseInsensitiveCompare:jsInterface] ) {
                self.interface = PGShareMessageInterfaceSlient;
            } else if (NSOrderedSame == [@"editable" caseInsensitiveCompare:jsInterface]){
                self.interface = PGShareMessageInterfaceEditable;
            }
        }
    }
    return self;
}

+ (PGShareMessage*)msgWithDict:(NSDictionary*)dict {
    PGShareMessage *msg = nil;
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        msg = [[[PGShareMessage alloc] initWithDict:dict] autorelease];
    }
    return msg;
}

- (void)dealloc {
    self.sendPict = nil;
    self.pictures = nil;
    self.thumbs = nil;
    self.longitude = nil;
    self.latitude = nil;
    self.content = nil;
    self.href =nil;
    self.sendThumb = nil;
    self.title = nil;
    self.msgType = nil;
    self.media = nil;
    self.miniProgram = nil;
    [super dealloc];
}

@end

@implementation PGJSRequest

@synthesize callBackID;
@synthesize payload;
@synthesize type;
@synthesize sendHasPendingOperation;

- (id)initWithDelegate:(id)delegate
             onSuccess:(SEL)successCallback
             onFailure:(SEL)failureCallback
{
    if ( self = [super init] ) {
        if ( delegate ) {
            _delegate = delegate;
            if (successCallback != nil) {
                _onSuccessCallback = NSStringFromSelector(successCallback);
                [_onSuccessCallback retain];
            }
            if (failureCallback != nil) {
                _onFailureCallback = NSStringFromSelector(failureCallback);
                [_onFailureCallback retain];
            }
        }
    }
    return self;
}

+ (PGJSRequest*)reqWithDelegate:(id)delegate
                      onSuccess:(SEL)successCallback
                      onFailure:(SEL)failureCallback
{
    
    PGJSRequest *request = [[PGJSRequest alloc] initWithDelegate:delegate
                                                       onSuccess:successCallback
                                                       onFailure:failureCallback];
    [request autorelease];
    return request;
}

- (void)onSuccess:(id)args
{
    id delegates = _delegate;
    SEL successCallback = NSSelectorFromString(_onSuccessCallback);
    if ([delegates respondsToSelector:successCallback]) {
        [delegates performSelector:successCallback withObject:self withObject:args];
    }
}

- (void)onFailure:(id)args
{
    id delegates = _delegate;
    SEL failCallback = NSSelectorFromString(_onFailureCallback);
    if ([delegates respondsToSelector:failCallback]) {
        [delegates performSelector:failCallback withObject:self withObject:args];
    }
}

- (void)dealloc {
    self.callBackID = nil;
    self.payload = nil;
    [_onSuccessCallback release];
    [_onFailureCallback release];
    [super dealloc];
}
@end

@implementation PGShare
@synthesize type;
@synthesize authenticated;
@synthesize accessToken;
@synthesize note;
@synthesize nativeClient;
@synthesize commonPath;

- (id)init {
    if ( self = [super init] ) {
        self.type = @"";
        self.accessToken = @"";
        self.note = @"";
    }
    return self;
}

- (NSDictionary*)JSDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithBool:self.authenticated] forKey:@"authenticated"];
    [dict setObject:[NSNumber numberWithBool:self.nativeClient] forKey:@"nativeClient"];
    if ( self.accessToken ) {
        [dict setObject:self.accessToken forKey:kString_accesstoken];
    }
    if ( self.note ) {
        [dict setObject:self.note forKey:g_pdr_string_description];
    }
    if ( self.type ) {
        [dict setObject:self.type forKey:g_pdr_string_id];
    }
    return dict;
}
- (PGShareMessage*)getMsgWithDict:(NSDictionary*)dict {
    PGShareMessage *msg = [PGShareMessage msgWithDict:dict];
    NSString *path = [msg.pictures objectAtIndex:0];
    if ([path isKindOfClass:[NSString class]]){
        msg.sendPict = path;//[PTPathUtil absolutePath:path];
    }
    NSString *thumbs = [msg.thumbs objectAtIndex:0];
    if ([thumbs isKindOfClass:[NSString class]]){
         msg.sendThumb = thumbs;
    }
    if ( !msg.sendPict && msg.sendThumb) {
        msg.sendPict = msg.sendThumb;
    }
    return msg;
}
#pragma mark-- @protocol
- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback {
    return FALSE;
}

- (BOOL)cancelPrevAuthorize{
    return FALSE;
}

- (BOOL)forbid {
    return FALSE;
}

- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback  {
    return FALSE;
}

- (void)doInit {

}
- (NSString*)getToken {
    return nil;
}

- (BOOL)logOut {
    return TRUE;
}
- (PGAuthorizeView*)getAuthorizeControl {
    return nil;
}
#pragma mark -- authorize

- (void)authorizeWithURL:(NSString*)url
             withCallBack:(NSString*)cbID {
    if ( _authorizeReq ) {
        [self cancelPrevAuthorize];
        [_authorizeReq release];
        _authorizeReq = nil;
    }
    if ( !_authorizeReq ) {
        _authorizeReq = [PGJSRequest reqWithDelegate:self
                                           onSuccess:@selector(authorizeSuccess:args:)
                                           onFailure:@selector(authorizeFailure:args:)];
        [_authorizeReq setCallBackID:cbID];
        [_authorizeReq retain];
        
        [self authorizeWithURL:url
                       delegate:_authorizeReq
                      onSuccess:@selector(onSuccess:)
                      onFailure:@selector(onFailure:)];
    } else {
        if ( cbID ) {
            _authorizeReq.callBackID = cbID;
        }
    }
}
//登录成功回调
- (void)authorizeSuccess:(PGJSRequest*)req args:(id)args
{
    self.authenticated = TRUE;
    self.accessToken = [self getToken];
    if ( [req isKindOfClass:PGJSRequest.class] ) {
        if ( req.callBackID ) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                    messageAsDictionary:[self JSDict]];
            [self toCallback:req.callBackID withReslut:[result toJSONString]];
        }
    }
    [_authorizeReq release];
    _authorizeReq = nil;
   // if ( !_sendHasPendingOperation ) {
        [self sendNext];
   // }
}
//登录失败回调
- (void)authorizeFailure:(PGJSRequest*)req args:(NSError*)error
{
    self.authenticated = FALSE;
    self.accessToken = nil;
    if ( [req isKindOfClass:PGJSRequest.class] ) {
        if ( req.callBackID ) {
            [self toErrorCallback:req.callBackID withNSError:error];
        }
    }
    [_authorizeReq release];
    _authorizeReq = nil;
    //清空分享列表
    [self clearSendPeer];
}
#pragma mark -- send 
- (void)clearSendPeer {
    [_sendPeer removeAllObjects];
}

- (void)sendNextAsync{
  //  NSInteger count = [_sendPeer count];
    
    PGJSRequest *req = nil;//[_sendPeer objectAtIndex:0];
    for ( PGJSRequest *targetReq in _sendPeer ) {
        if ( !targetReq.sendHasPendingOperation ) {
            req = targetReq;
            break;
        }
    }
    if ( req ) {
   // if ( count > 0 ) {
        if ( self.authenticated ) {
            req.sendHasPendingOperation = YES;
            [self send:req.payload
               delegate:req
             onSuccess:@selector(onSuccess:)
             onFailure:@selector(onFailure:)];
            //_sendHasPendingOperation = YES;
            return;
        } else {
            //如果为登陆先验证
            //[self authorizeWithURL:nil withCallBack:nil];
            [self toErrorCallback:req.callBackID withCode:PGShareErrorNotAuthorize];
            return;
        }
        return;
    }
    //_sendHasPendingOperation = NO;
}

- (void)sendNext {
    [self performSelector:@selector(sendNextAsync) withObject:nil afterDelay:0.1f];
}

- (void)sendSuccess:(PGJSRequest*)request args:(id)args {
    if ( [request isKindOfClass:PGJSRequest.class] ) {
        NSString *cbID = request.callBackID;
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                       messageAsInt:0];
        [self toCallback:cbID withReslut:[result toJSONString]];
        [_sendPeer removeObject:request];
        [self sendNext];
    }
}

- (void)sendFailure:(PGJSRequest*)request args:(id)args {
    if ( [request isKindOfClass:PGJSRequest.class] ) {
        NSError *error = (NSError*)args;
        NSString *cbID = request.callBackID;
        [self toErrorCallback:cbID withNSError:error];
        //[self toErrorCallback:cbID withMoudleName:error.domain withCode:(int)error.code
              ///    withMessage:[error localizedDescription] withURL:[[error userInfo] objectForKey:@"url"]];
        [_sendPeer removeObject:request];
        [self sendNext];
    }
}

#pragma mark -- JS
- (void)authorize:(PGMethod*)command
{
    NSString *cbID = [command.arguments objectAtIndex:0];
    NSString *url = nil;//[command.arguments objectAtIndex:2];
    
    PDRPluginResult *result = nil;
    
    if ( self.authenticated ) {
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                               messageAsDictionary:[self JSDict]];
        [self toCallback:cbID withReslut:[result toJSONString]];
        return;
    }
    if ( _authorizeReq ) {
//        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
//                              messageToErrorObject:PGShareErrorRepeateAuthReq withMessage:[self errorMsgWithCode:PGShareErrorRepeateAuthReq]];
//        [self toCallback:cbID withReslut:[result toJSONString]];
       // return;
    }
    [self authorizeWithURL:url withCallBack:cbID];
}

- (void) forbid:(PGMethod*)command {
    self.accessToken = nil;
    self.authenticated = FALSE;
    [self logOut];
}

- (void)send:(PGMethod*)command
{
    NSString *cbID = [command.arguments objectAtIndex:0];
    NSDictionary *dict = [command.arguments objectAtIndex:2];
    PGShareMessage *msg = [self getMsgWithDict:dict];
    
    if ( msg ) {
        if ( nil == _sendPeer ) {
            _sendPeer = [[NSMutableArray alloc] init];
        }
        PGJSRequest *request = [PGJSRequest reqWithDelegate:self
                                                  onSuccess:@selector(sendSuccess:args:)
                                                  onFailure:@selector(sendFailure:args:)];
        [request setCallBackID:cbID];
        [request setPayload:msg];
        [request setType:type];
        [_sendPeer addObject:request];
        //如果没有正在进行的发送任务发送
       // if ( !_sendHasPendingOperation ) {
            [self sendNext];
      //  }
    }
}

- (BOOL)launchMiniProgram:(PGMethod*)command {
    return NO;
}

- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGShareErrorRepeateAuthReq: return @"重复的验证请求";
        case PGShareErrorUserCancel: return @"用户取消分享";
        case PGShareErrorUserNotExists: return @"用户不存在";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}

- (void)dealloc {
    self.accessToken = nil;
    self.note = nil;
    self.type = nil;
    [super dealloc];
}

@end
