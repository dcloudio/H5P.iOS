/*
 *------------------------------------------------------------------
 *  pandora/feature/PGXHR.mm
 *  Description:
 *    XmlHttpRequest实现定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-29 创建文件
 *------------------------------------------------------------------
*/
#import "PGXHR.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#import "PDRCoreWindowManager.h"
#import "PDRCommonString.h"

@implementation PGXHRConnection

@synthesize UUID;
@synthesize bridge;
@synthesize mCallbackid;
@synthesize contentLength;
@synthesize timeout;
@synthesize overrideMimeType;
@synthesize responseText;

-(id)init {
    if ( self = [super init] ) {
        self.delegate = self;
    }
    return self;
}

-(void)open {
    [_data setLength:0];
}

-(void)send {
    
//    NSString* cleanPath = [self.mUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSURL* httpUrl = [NSURL URLWithString:[cleanPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    
//  //  NSURL *httpUrl = [NSURL URLWithString:httpUrl];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:httpUrl];
//    if ( NSOrderedSame == [self.mMethod caseInsensitiveCompare:g_pdr_string_GET] ) {
//        [request setHTTPMethod:g_pdr_string_GET];
//    } else if (NSOrderedSame == [self.mMethod caseInsensitiveCompare:g_pdr_string_POST]) {
//        [request setHTTPMethod:g_pdr_string_POST];
//        if ( [self.mBody length] > 0 ) {
//            [request setHTTPBody:self.mBody];
//        }
//    } else if (self.mMethod){
//        [request setHTTPMethod:self.mMethod];
//    }
//    [self setValue:@"text/xml;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//    if ( _httpHeaderDict ) {
//        [request setAllHTTPHeaderFields:_httpHeaderDict];
//    }
//    
//    [self addValue:@"text/xml;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//    
//    request.timeoutInterval = self.timeout;
//    
//    self.request = request;
    [self start];
}

- (void) abort {
    self.responseText = nil;
    self.mCallbackid = nil;
    self.contentLength = 0;
    [_data setLength:0];
    [self reset];
}

- (void)netConnection:(PTNetConnection *)connection didReceiveResponse:(id)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSDictionary *responseHeader = [httpResponse allHeaderFields];
    self.statusCode = [httpResponse statusCode];
    long long expectedContentLength = [httpResponse expectedContentLength];
    NSString *textEncodingName = [httpResponse textEncodingName];
    NSString *statusText = [NSHTTPURLResponse localizedStringForStatusCode:self.statusCode];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:3] forKey:g_pdr_string_readyState];
    [dict setObject:[NSNumber numberWithInteger:self.statusCode] forKey:g_pdr_string_status];
    [dict setObject:responseHeader forKey:g_pdr_string_header];
    [dict setObject:statusText forKey:g_pdr_string_statusText];
    [dict setObject:[NSNumber numberWithBool:(expectedContentLength != -1)] forKey:@"lengthComputable"];
     self.contentLength = (-1 == expectedContentLength? 0:expectedContentLength);
    [dict setObject:[NSNumber numberWithLongLong:self.contentLength] forKey:g_pdr_string_totalSize];
    
    self.textEncoding = PGXHRTextEncodingUTF_8;
    BOOL userResponse = YES;
    if ( self.overrideMimeType ) {
        NSArray *chinaCharsets = @[@"gbk", @"gb2312"];
        for (NSString *charSet in chinaCharsets ) {
            NSRange range = [self.overrideMimeType rangeOfString:charSet];
            if ( range.length ) {
                self.textEncoding = PGXHRTextEncodingGBK;
                userResponse = NO;
                break;
            }
        }
    }
    if (userResponse && NSOrderedSame == [@"gbk" caseInsensitiveCompare:textEncodingName] ) {
        self.textEncoding = PGXHRTextEncodingGBK;
    }
    
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    result.keepCallback = TRUE;
    [self.bridge toCallback:self.mCallbackid withReslut:[result toJSONString]];
}

- (void)netConnection:(PTNetConnection *)connection didReceiveData:(NSData *)data {
    if ( !_data ) {
        _data = [[NSMutableData data] retain];
    }
    [_data appendData:data];

   // NSString *responseText = nil;//@"not support encoding, use utf-8?";
    if ( PGXHRTextEncodingGBK == self.textEncoding ) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        self.responseText = [[[NSString alloc] initWithData:_data encoding:enc] autorelease];
    } else {
        self.responseText = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease];
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:3] forKey:g_pdr_string_readyState];
    if ( self.responseText ) {
        [dict setObject:self.responseText forKey:g_pdr_string_responseText];
    } else {
       // self.statusCode = 406;
       // [self netConnection:self didFailWithError:nil];
       // return;
        //[dict setObject:@"not support encoding, use utf-8?" forKey:g_pdr_string_responseText];
    }
    [dict setObject:[NSNumber numberWithUnsignedInteger:[_data length]] forKey:g_pdr_string_revSize];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    result.keepCallback = TRUE;
    [self.bridge toCallback:self.mCallbackid withReslut:[result toJSONString]];
}

- (void)netConnectionFinished:(PTNetConnection *)connection {
    if ( !self.responseText && [_data length] ) {
        self.statusCode = 406;
        [self netConnection:self didFailWithError:nil];
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:4] forKey:g_pdr_string_readyState];
    [dict setObject:[NSNumber numberWithUnsignedInteger:[_data length]] forKey:g_pdr_string_revSize];
    self.contentLength = [_data length];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    [self.bridge toCallback:self.mCallbackid withReslut:[result toJSONString]];
    [self abort];
    if ( [self.bridge respondsToSelector:@selector(connectionEnd:)] ) {
        [self.bridge performSelector:@selector(connectionEnd:) withObject:self];
    }
}

- (void)netConnection:(PTNetConnection *)connection didFailWithError:(NSError*)error {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:4] forKey:g_pdr_string_readyState];
    [dict setObject:[NSNumber numberWithInteger:self.statusCode] forKey:g_pdr_string_status];
    [dict setObject:[NSNumber numberWithBool:true] forKey:g_pdr_string_error];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    [self.bridge toCallback:self.mCallbackid withReslut:[result toJSONString]];
    [self abort];
    if ( [self.bridge respondsToSelector:@selector(connectionEnd:)] ) {
        [self.bridge performSelector:@selector(connectionEnd:) withObject:self];
    }
}

- (void)dealloc {
    self.overrideMimeType = nil;
    self.UUID = nil;
    self.bridge = nil;
    [self abort];
    [_data release];
    [super dealloc];
}

@end

@implementation PGXHR
/**
 *------------------------------------------------------------------
 * @Summary:
 *     初始化 HTTP 请求参数，例如 URL 和 HTTP 方法，但是并不发送请求
 * @Parameters:
 *  method DOMString 必选，用于设置请求的 HTTP 的方法。值包括 GET、POST。
 *  url DOMString 必选，请求的网络地址。
 *  username DOMString 可选，为 URL 所需的授权提供认证资格。
 *  password DOMString 可选，为 URL 所需的授权提供认证资格。。
 * @Returns:
 * @Remark:
 *  这个方法初始化请求参数以供 send() 方法稍后使用。它把 readyState 设置为 1，
 *   删除之前指定的所有请求头部，以及之前接收的所有响应头部，并且把 responseText、
 *   responseXML、status 以及 statusText 参数设置为它们的默认值。
 *   当 readyState 为 0 的时候（当 XMLHttpRequest 对象刚创建或者 abort() 方法调用后）
 *   以及当 readyState 为 4 时（已经接收响应时），调用这个方法是安全的。
 *   当针对任何其他状态调用的时候，open() 方法的行为是为指定的。 
 *   除了保存供 send() 方法使用的请求参数，以及重置 XMLHttpRequest 对象以便复用，
 *   open() 方法没有其他的行为。要特别注意，当这个方法调用的时候，
 *  实现通常不会打开一个到 Web 服务器的网络连接
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)open:(PGMethod*)command {
    if ( !command.arguments
        || ![command.arguments isKindOfClass:[NSArray class]] ) {
        return;
    }
    NSString *UUID = [command.arguments objectAtIndex:0];
    NSString *method = [command.arguments objectAtIndex:1];
    NSString *url = [command.arguments objectAtIndex:2];
    NSString *username = [command.arguments objectAtIndex:3];
    NSString *password = [command.arguments objectAtIndex:4];
    NSTimeInterval timout = [PGPluginParamHelper getFloatValue:[command.arguments objectAtIndex:5] defalut:120000];
    timout /= 1000;
    if ( ![method isKindOfClass:[NSString class]] ) {
        method = @"GET";
    }
    
    if ( ![url isKindOfClass:[NSString class]] ) {
        url = nil;
    }
    
    if ( ![username isKindOfClass:[NSString class]] ) {
        username = nil;
    }
    
    if ( ![password isKindOfClass:[NSString class]] ) {
        password = nil;
    }
    
    if ( [UUID isKindOfClass:[NSString class]] ) {
        PGXHRConnection *connection = [self getXHR:UUID];
        connection.username = username;
        connection.password = password;
        connection.reqMethod = method;
        connection.reqUrl =  [url URLChineseEncode];
        connection.timeout = timout;
        [connection open];
    }
}

- (PGXHRConnection*)getXHR:(NSString*)UUID {
    if ( !_XHRConnections ) {
        _XHRConnections = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    PGXHRConnection *connection = [_XHRConnections objectForKey:UUID];
    if ( !connection ) {
        connection = [[[PGXHRConnection alloc] init] autorelease];
        connection.UUID = UUID;
        if(self.appContext && self.appContext.appInfo)
            connection.eSslActive = self.appContext.appInfo.defSSLActive;
        
        [_XHRConnections  setObject:connection forKey:UUID];
        connection.bridge = self;
    }
    return connection;
}

-(void)send:(PGMethod*)command {
    if ( !command.arguments
        || ![command.arguments isKindOfClass:[NSArray class]] ) {
        return;
    }
    NSString *UUID = [command.arguments objectAtIndex:0];
    NSString *callbackid = [command.arguments objectAtIndex:1];
    NSString *body = [command.arguments objectAtIndex:2];
    NSDictionary *header = [command.arguments objectAtIndex:3];
    
    if ( ![body isKindOfClass:NSString.class] ) {
        body = nil;
    }
    
    if ( [UUID isKindOfClass:[NSString class]] ) {
        PGXHRConnection *connection = [_XHRConnections objectForKey:UUID];
        if ( connection ) {
            connection.mCallbackid = callbackid;
            connection.reqBody = [body dataUsingEncoding:NSUTF8StringEncoding];
            [connection setAllHTTPHeaderFields:header];
            [connection send];
        }
    }
}

-(void)abort:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return;
    }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( [UUID isKindOfClass:[NSString class]] ) {
        PGXHRConnection *connection = [_XHRConnections objectForKey:UUID];
        if ( connection ) {
            [connection abort];
        }
    }
}

- (void)overrideMimeType:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return;
    }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( [UUID isKindOfClass:[NSString class]] ) {
        PGXHRConnection *connection = [self getXHR:UUID];
        if ( connection ) {
            NSString *overrideMimeType = [command.arguments objectAtIndex:1];
            if ( [overrideMimeType isKindOfClass:[NSString class]]) {
                connection.overrideMimeType = [overrideMimeType lowercaseString];
            }
        }
    }
}

- (void) connectionEnd:(PGXHRConnection*)connection {
    NSString *uuid = connection.UUID;
    if ( [_XHRConnections objectForKey:uuid] ) {
        [_XHRConnections removeObjectForKey:uuid];
    }
}

- (void)stopXhr {
    NSArray *allXhr = [_XHRConnections allValues];
    for ( PGXHRConnection *item in allXhr ) {
        [item abort];
    }
}

-(void)dealloc {
    [self stopXhr];
    [_XHRConnections removeAllObjects];
    [_XHRConnections release];
    [super dealloc];
}

@end
