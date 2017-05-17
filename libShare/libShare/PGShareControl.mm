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
#import "PGShareControl.h"
#import "PGMethod.h"
#import "PGShare.h"

@implementation PGAuthorizeView
@synthesize authViewDeleagte;
- (void)loadAuthPage {
}
- (void)postOnloadedEvt{
    if ( [self.authViewDeleagte respondsToSelector:@selector(onloaded)] ) {
        [self.authViewDeleagte performSelector:@selector(onloaded)];
    }
}

- (void)postOnauthenticatedEvt {
    if ( [self.authViewDeleagte respondsToSelector:@selector(onauthenticated)] ) {
        [self.authViewDeleagte performSelector:@selector(onauthenticated)];
    }
}

- (void)postOnErrorEvt:(NSError*)error {
    if ( [self.authViewDeleagte respondsToSelector:@selector(onerror:)] ) {
        [self.authViewDeleagte performSelector:@selector(onerror:)withObject:error];
    }
}
@end

@implementation PGShareControl
@synthesize JSFrameContext;
@synthesize appContext;
@synthesize authUrl;
@synthesize callBackID;
@synthesize engineType;
@synthesize bridge;

- (void)loadAuthPage {
    [_authView loadAuthPage];
}

- (void)setAuthorizeView:(PGAuthorizeView*)authView {
    [self closeAuthView];
    _authView = [authView retain];
    _authView.authViewDeleagte = self;
    [self addSubview:_authView];
    [_authView loadAuthPage];
}

- (void)layoutSubviews {
    _authView.frame = self.bounds;
}

- (void)onloaded {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"load", @"evt",  nil];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    [result setKeepCallback:TRUE];
    [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
}

- (void)onauthenticated {
    bridge.authenticated = TRUE;
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"auth", @"evt",
                          self.engineType, @"type",
                          [NSNumber numberWithBool:bridge.authenticated], @"authenticated",
                          bridge.accessToken, @"accessToken",
                          nil];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    [result setKeepCallback:TRUE];
    [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
}

- (void)onerror:(NSError*)error {
    bridge.authenticated = FALSE;
    bridge.accessToken = nil;
    [self.bridge toErrorCallback:self.callBackID
                   withInnerCode:(int)error.code
                     withMessage:[error localizedDescription]
                    keepCallback:YES];
}

- (void)closeAuthView {
    if ( _authView ) {
        [_authView removeFromSuperview];
        _authView.authViewDeleagte = nil;
        [_authView release];
        _authView = nil;
    }
}

- (void)dealloc {
    [self closeAuthView];
    self.engineType = nil;
    self.callBackID = nil;
    self.authUrl = nil;
    [super dealloc];
}

@end