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
#import "PGShareManager.h"
#import "PDRCoreAppPrivate.h"
#import "PDRCoreFeature.h"
#import "PGShareControl.h"
#import "PDRCoreAppFramePrivate.h"
#import "PDRCommonString.h"
#import "PTPathUtil.h"

@implementation PGShareManager

- (void)loadServices {
    if ( nil == _shareServices ) {
        _shareServices = [[NSMutableArray alloc] initWithCapacity:3];
        NSDictionary *dict = [self supportShare];
        NSArray *allValues = [dict allValues];
        for ( NSString *className in allValues ) {
            if ( [className isKindOfClass:[NSString class]] ) {
                PGShare *share = [[NSClassFromString(className) alloc] init];
                if ( [share isKindOfClass:[PGShare class]] ) {
                    share.JSFrameContext = self.JSFrameContext;
                    share.appContext = self.appContext;
                    share.errorURL = self.errorURL;
                    [share doInit];
                    share.name = self.name;
                    share.content = share.note;
                    [_shareServices addObject:share];
                    [share release];
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
    for ( PGShare *share in _shareServices ) {
        [retServices addObject:[share JSDict]];
        share.JSFrameContext = self.JSFrameContext;
    }
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                 messageAsArray:retServices];
    [self toCallback:cbID withReslut:[result toJSONString]];
}

#pragma mark -- authorize
- (void)authorize:(PGMethod*)command
{
    NSString *cbID = [command.arguments objectAtIndex:0];
    NSString *type = [command.arguments objectAtIndex:1];
    
    PDRPluginResult *result = nil;
    PGShare *share = [self getShareObjectByType:type];
    if ( share ) {
        share.JSFrameContext = self.JSFrameContext;
        [share authorize:command];
        return;
    }
    result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                          messageToErrorObject:PGShareErrorShareNotSupport];
    [self toCallback:cbID withReslut:[result toJSONString]];
}

#pragma mark -- forbid
- (void)forbid:(PGMethod*)command
{
    NSString *type = [command.arguments objectAtIndex:0];
    
    if ( ![type isKindOfClass:[NSString class]] ) {
        type = nil;
    }
    
    if ( type ) {
        PGShare *share = [self getShareObjectByType:type];
        if ( share ) {
            share.JSFrameContext = self.JSFrameContext;
            [share forbid:command];
        }
    }
}

#pragma mark -- send
- (void)send:(PGMethod*)command
{
    NSString *cbID = [command.arguments objectAtIndex:0];
    NSString *type = [command.arguments objectAtIndex:1];
    PDRPluginResult *result = nil;
    if ( type ) {
        PGShare *share = [self getShareObjectByType:type];
        if ( share ) {
            share.JSFrameContext = self.JSFrameContext;
            [share send:command];
            return;
        }
    }
    result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                          messageToErrorObject:PGShareErrorShareNotSupport];
    [self toCallback:cbID withReslut:[result toJSONString]];
}

- (PGShare*)getShareObjectByType:(NSString*)aType {
    if ( aType ) {
        for ( PGShare *share in _shareServices ) {
            if ( NSOrderedSame == [aType caseInsensitiveCompare:share.type] ) {
                return share;
            }
        }
    }
    return nil;
}

- (NSDictionary*)supportShare {
    return [self.appContext.featureList getPuginExtend:@"Share"];
}

#pragma mark -- share control
- (void)create:(PGMethod*)command {
    NSArray *args = command.arguments;
    NSString *UUID = [args objectAtIndex:0];
    NSString *callBackID = [args objectAtIndex:1];
    BOOL    display = [[args objectAtIndex:2] boolValue];
    CGFloat left = [[args objectAtIndex:3] floatValue];
    CGFloat top = [[args objectAtIndex:4] floatValue];
    CGFloat width = [[args objectAtIndex:5] floatValue];
    CGFloat height = [[args objectAtIndex:6] floatValue];
    
    if ( nil == _shareControlServices ) {
        _shareControlServices = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    PGShareControl *authControl = [_shareControlServices objectForKey:UUID];
    if ( nil == authControl ) {
        authControl = [[PGShareControl alloc] initWithFrame:CGRectMake(left, top, width, height)];
        authControl.callBackID = callBackID;
        authControl.JSFrameContext = self.JSFrameContext;
        authControl.appContext = self.appContext;
        [_shareControlServices setObject:authControl forKey:UUID];
        [self.JSFrameContext.webEngine.scrollView addSubview:authControl];
        [authControl autorelease];
    }
    authControl.hidden = !display;
}

- (void)load:(PGMethod*)command {
    NSArray *args = command.arguments;
    NSString *UUID = [args objectAtIndex:0];
    NSString *typeV = [args objectAtIndex:1];
    
    NSString *shareType = nil;
    if ( [typeV isKindOfClass:NSString.class] ) {
        shareType = typeV;
    }

    PGShareControl *authControl = [_shareControlServices objectForKey:UUID];
    if ( authControl ) {
        [self loadServices];
        PGShare *share = [self getShareObjectByType:shareType];
        PGAuthorizeView *impView = nil;
        if ( share ) {
            impView = [share getAuthorizeControl];
        }
        if ( authControl ) {
            authControl.bridge = share;
            authControl.engineType = shareType;
            [authControl setAuthorizeView:impView];
        } else {
            return;
        }
    }
}

- (void)setVisible:(PGMethod*)command {
    NSArray *args = command.arguments;
    NSString *UUID = [args objectAtIndex:0];
    NSString *displayV = [args objectAtIndex:1];
    if ( [displayV isKindOfClass:[NSString class]]
        || [displayV isKindOfClass:NSNumber.class]) {
        PGShareControl *control = [_shareControlServices objectForKey:UUID];
        if ( control ) {
            control.hidden = ![displayV boolValue];
        }
    }
}

- (void)sendWithSystem:(PGMethod*)command
{
    NSString* cbid = [command.arguments objectAtIndex:0];
    NSDictionary *dict = [command.arguments objectAtIndex:1];
    if(dict)
    {
        PGShareMessage *msg = [PGShareMessage msgWithDict:dict];
        if(msg)
        {
            NSMutableArray* arguments = [[NSMutableArray alloc] initWithCapacity:0];
            if(arguments)
            {
                if(msg.content)
                    [arguments addObject:msg.content];
                
                if(msg.pictures)
                {
                    for (NSString* imgPath in msg.pictures) {
                        NSString* path = [PTPathUtil absolutePath:imgPath withContext:self.appContext];
                        if(path)
                        {
                            UIImage* pImage = [UIImage imageWithContentsOfFile:path];
                            if(pImage){
                                [arguments addObject:pImage];
                            }
                            
                        }
                    }
                }
                if(msg.href) {
                    [arguments addObject:[NSURL URLWithString:msg.href]];
                }
                
                UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:arguments applicationActivities:nil];
                if(nil == avc)
                {
                    [self toErrorCallback:cbid withCode:-3 withMessage:@"share error"];
                }

                if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
                    && [avc respondsToSelector:@selector(popoverPresentationController)] ) {
                    UIPopoverPresentationController *popover = avc.popoverPresentationController;
                    if ( popover ) {
                        popover.sourceView = self.JSFrameContext;
                        popover.sourceRect = CGRectMake(self.JSFrameContext.bounds.size.width/2, self.JSFrameContext.bounds.size.height, 1, 1);
                        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
                    }
                }
                [self.rootViewController presentViewController:avc animated:YES completion:nil];
                
                if ( kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0 )
                {
                    //分享结果回调方法
                    UIActivityViewControllerCompletionHandler myblock = ^(NSString *type,BOOL completed){
                        if(completed)
                            [self toSucessCallback:cbid withInt:0];
                        else
                            [self toErrorCallback:cbid withCode:-2 withMessage:@"user cancelled"];
                    };
                    
                    avc.completionHandler = myblock;
                    
                }else{
                    [self toSucessCallback:cbid withInt:0];
                }
            }
            else{
                [self toErrorCallback:cbid withCode: -1 withMessage:@"Parameter error"];
            }
        }
    }
}


- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    if ( theAppframe == self.JSFrameContext ) {
        for ( PGShare *share in _shareServices ) {
            if ( theAppframe == share.JSFrameContext ) {
                share.JSFrameContext = nil;
            }
        }
        self.JSFrameContext = nil;
    }
}

- (void)dealloc {
    [_shareControlServices removeAllObjects];
    [_shareControlServices release];
    [_shareServices removeAllObjects];
    [_shareServices release];
    [super dealloc];
}

@end
