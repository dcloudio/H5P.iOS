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
#import "PDRCoreFeature.h"
#import "PGPayManager.h"
#import "PDRCoreAppPrivate.h"
#import "PDRCoreAppFramePrivate.h"

@implementation PGPayManager

- (void)loadServices {
    if ( nil == _payServices ) {
        _payServices = [[NSMutableArray alloc] initWithCapacity:3];
        NSDictionary *dict = [self supportShare];
        NSArray *allValues = [dict allValues];
        for ( NSString *className in allValues ) {
            if ( [className isKindOfClass:[NSString class]] ) {
                PGPlatby *payImp = [[NSClassFromString(className) alloc] init];
                if ( [payImp isKindOfClass:[PGPlatby class]] ) {
                    payImp.JSFrameContext = self.JSFrameContext;
                    payImp.appContext = self.appContext;
                    payImp.name = self.name;
                    payImp.errorURL = self.errorURL;
                    payImp.content = payImp.description;
                    [_payServices addObject:payImp];
                    [payImp release];
                }
            }
        }
    }
}

- (void)getChannels:(PGMethod*)command
{
    NSString *cbID = [command.arguments objectAtIndex:0];
    [self loadServices];
    NSMutableArray *retServices = [NSMutableArray array];
    for ( PGPlatby *payImp in _payServices ) {
        [retServices addObject:[payImp JSDict]];
        payImp.JSFrameContext = self.JSFrameContext;
    }
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                 messageAsArray:retServices];
    [self toCallback:cbID withReslut:[result toJSONString]];
}

#pragma mark -- authorize

- (void)addRequestListener:(PGMethod*)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    
    NSString *engineType = nil;
    if ( [arg0 isKindOfClass:NSString.class] ) {
        engineType = arg0;
    }
    
    PGPlatby *payImp = [self getShareObjectByType:engineType];
    if ( payImp ) {
        payImp.JSFrameContext = self.JSFrameContext;
        [payImp addRequestListener:command];
        return;
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];

}

- (void)removeRequestListener:(PGMethod*)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    
    NSString *engineType = nil;
    if ( [arg0 isKindOfClass:NSString.class] ) {
        engineType = arg0;
    }
    
    PGPlatby *payImp = [self getShareObjectByType:engineType];
    if ( payImp ) {
        payImp.JSFrameContext = self.JSFrameContext;
        [payImp removeRequestListener:command];
        return;
    }
}

- (void)requestOrder:(PGMethod *)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:1];
    
    NSString *engineType = nil;
    if ( [arg0 isKindOfClass:NSString.class] ) {
        engineType = arg0;
    }
    
    PGPlatby *payImp = [self getShareObjectByType:engineType];
    if ( payImp ) {
        payImp.JSFrameContext = self.JSFrameContext;
        [payImp requestOrder:command];
        return;
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
}

- (void)request:(PGMethod*)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    NSString *cbID = [command.arguments objectAtIndex:2];

    NSString *engineType = nil;
    if ( [arg0 isKindOfClass:NSString.class] ) {
        engineType = arg0;
    }
    
    PGPlatby *payImp = [self getShareObjectByType:engineType];
    if ( payImp ) {
        payImp.JSFrameContext = self.JSFrameContext;
        [payImp request:command];
        return;
    }
    [self toErrorCallback:cbID withCode:PGPluginErrorNotSupport];
}

- (void)restoreComplateRequest:(PGMethod*)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    
    NSString *engineType = nil;
    if ( [arg0 isKindOfClass:NSString.class] )
        engineType = arg0;
    
    
    PGPlatby *payImp = [self getShareObjectByType:engineType];
    if ( payImp ) {
        [payImp restoreComplateRequest:command];
        return;
    }
}

- (NSData*)appStoreReceipt:(PGMethod*)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    if (arg0) {
        NSString *engineType = nil;
        if ( [arg0 isKindOfClass:NSString.class] )
            engineType = arg0;
        
        PGPlatby *payImp = [self getShareObjectByType:engineType];
        if ( payImp ) {
            return [payImp appStoreReceipt];
        }        
    }
    return nil;
}

- (void)installService:(PGMethod*)command
{
    NSString *arg0 = [command.arguments objectAtIndex:0];
    
    NSString *engineType = nil;
    if ( [arg0 isKindOfClass:NSString.class] ) {
        engineType = arg0;
    }
    
    PGPlatby *payImp = [self getShareObjectByType:engineType];
    if ( payImp ) {
        [payImp installService];
        return;
    }
}

- (PGPlatby*)getShareObjectByType:(NSString*)aType {
    if ( aType ) {
        for ( PGPlatby *payImp in _payServices ) {
            if ( NSOrderedSame == [aType caseInsensitiveCompare:payImp.type] ) {
                return payImp;
            }
        }
    }
    return nil;
}

- (NSDictionary*)supportShare {
    return [self.appContext.featureList getPuginExtend:@"Payment"];
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    if ( theAppframe == self.JSFrameContext ) {
        for ( PGPlatby *payImp in _payServices ) {
            if ( theAppframe == self.JSFrameContext ) {
                payImp.JSFrameContext = nil;
            }
        }
        self.JSFrameContext = nil;
    }
}

- (void)dealloc {
    [_payServices removeAllObjects];
    [_payServices release];
    [super dealloc];
}

@end
