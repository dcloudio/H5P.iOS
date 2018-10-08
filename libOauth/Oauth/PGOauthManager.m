/*
 *------------------------------------------------------------------
 *  pandora/feature/PGOauth
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
#import "PGOauthManager.h"
#import "PDRCoreAppPrivate.h"
#import "PDRCoreFeature.h"
#import  "PDRCoreAppFrame.h"
#import  "PDRCommonString.h"
#import "PGOauth.h"

@implementation PGOauthManager

- (void)loadServices {
    if ( nil == _oauthServices ) {
        _oauthServices = [[NSMutableArray alloc] initWithCapacity:3];
        NSDictionary *dict = [self supportOauth];
        NSArray *allValues = [dict allValues];
        for ( NSString *className in allValues ) {
            if ( [className isKindOfClass:[NSString class]] ) {
                PGOauth *oauth = [[NSClassFromString(className) alloc] init];
                if ( [oauth isKindOfClass:[PGOauth class]] ) {
                    oauth.JSFrameContext = self.JSFrameContext;
                    oauth.appContext = self.appContext;
                    [oauth initalize];
                    [_oauthServices addObject:oauth];
                    [oauth release];
                }
            }
        }
    }
}

- (void)getServices:(PGMethod*)command
{
    NSString *cbID = [command.arguments objectAtIndex:0];
    [self loadServices];
    NSMutableArray *retServices = [NSMutableArray array];
    for ( PGOauth *oatuh in _oauthServices ) {
        [retServices addObject:[oatuh JSDict]];
        oatuh.JSFrameContext = self.JSFrameContext;
    }
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                 messageAsArray:retServices];
    [self toCallback:cbID withReslut:[result toJSONString]];
}

#pragma mark -- authorize
- (void)login:(PGMethod *)command
{
    NSString *type = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    NSDictionary *params = [command.arguments objectAtIndex:2];
    
    PGOauth *Oauth = [self getOauthObjectByType:type];
    if ( Oauth ) {
        if ( ![params isKindOfClass:[NSDictionary class]] ) {
            params = nil;
        }
        Oauth.JSFrameContext = self.JSFrameContext;
        [Oauth login:cbID withParams:params];
        return;
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
}

#pragma mark -- authorize
- (void)authorize:(PGMethod *)command
{
    NSString *type = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    NSDictionary *params = [command.arguments objectAtIndex:2];
    
    PGOauth *Oauth = [self getOauthObjectByType:type];
    if ( Oauth ) {
        if ( ![params isKindOfClass:[NSDictionary class]] ) {
            params = nil;
        }
        Oauth.JSFrameContext = self.JSFrameContext;
        if ( [Oauth authorize:cbID withParams:params] ) {
            return;
        }
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
}


#pragma mark -- forbid
- (void)logout:(PGMethod *)command
{
    NSString *type = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    
    if ( ![type isKindOfClass:[NSString class]] ) {
        type = nil;
    }
    
    if ( type ) {
        PGOauth *share = [self getOauthObjectByType:type];
        if ( share ) {
            share.JSFrameContext = self.JSFrameContext;
            [share logout:cbID];
        }
    }
}

#pragma mark -- send
- (void)getUserInfo:(PGMethod*)command
{
    NSString *type = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    if ( type ) {
        PGOauth *oauth = [self getOauthObjectByType:type];
        if ( oauth ) {
            oauth.JSFrameContext = self.JSFrameContext;
            [oauth getUserInfo:cbID];
            return;
        }
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
}

// 显示一个登陆页面，添加电话号码到已经登陆的用户
- (void)addPhoneNumber:(PGMethod*)command
{
    NSString *type = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    if ( type ) {
        PGOauth *oauth = [self getOauthObjectByType:type];
        if ( oauth ) {
            oauth.JSFrameContext = self.JSFrameContext;
            [oauth addPhoneNumber:cbID];
            return;
        }
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
}

- (PGOauth*)getOauthObjectByType:(NSString*)aType {
    if ( aType ) {
        for ( PGOauth *oauth in _oauthServices ) {
            if ( NSOrderedSame == [aType caseInsensitiveCompare:oauth.identify] ) {
                return oauth;
            }
        }
    }
    return nil;
}

- (NSDictionary*)supportOauth {
    return [self.appContext.featureList getPuginExtend:@"OAuth"];
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    if ( theAppframe == self.JSFrameContext ) {
        for ( PGOauth *oauth in _oauthServices ) {
            if ( theAppframe == oauth.JSFrameContext ) {
                oauth.JSFrameContext = nil;
            }
        }
        self.JSFrameContext = nil;
    }
}

- (PGPluginAuthorizeStatus)authorizeStatus {
    return PGPluginAuthorizeStatusAuthorized;
}

- (void)dealloc {
    [_oauthServices removeAllObjects];
    [_oauthServices release];
    [super dealloc];
}

@end
