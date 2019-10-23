//
//  DCSAPPShareManager.m
//  StreamApp
//
//  Created by EICAPITAN on 16/2/1.
//  Copyright © 2016年 EICAPITAN. All rights reserved.
//

#import "PGMethod.h"
#import "PTPathUtil.h"
#import "DCSAPPShareManager.h"


@implementation DCSAPPShareManager

- (void)loadServices
{
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
                    share.commonPath = [PTPathUtil runtimeDataPath];
                    [share doInit];
                    share.name = self.name;
                    share.content = share.note;
                    // 如果没有原生客户端就不添加分享，新浪微博除外
                    if (share.nativeClient || [share.type compare:@"sinaweibo"] == NSOrderedSame) {
                        [_shareServices addObject:share];
                    }
                }
            }
        }
    }
}


- (void)send:(PGMethod*)command
{
    if (command) {
        NSString *type = [command.arguments objectAtIndex:1];
        if ( type ) {
            PGShare *share = [self getShareObjectByType:type];
            if ( share ) {
                share.JSFrameContext = self.JSFrameContext;
                [share send:command];
                return;
            }
        }
    }
}

- (NSDictionary*)supportShare {
    NSDictionary* pDictionAry = nil;
    NSDictionary* pShareDic = nil;
    NSString* pBundlePath = [[NSBundle mainBundle] pathForResource:@"feature" ofType:@"plist" inDirectory:@"PandoraApi.bundle"];
    if (pBundlePath) {
        pDictionAry = [NSDictionary dictionaryWithContentsOfFile:pBundlePath];
        pShareDic = [[pDictionAry objectForKey:@"Share"] objectForKey:@"extend"];
    }
    return pShareDic;
}


- (NSArray*)getServices
{
    if (_shareServices) {
        return _shareServices;
    }
    [self loadServices];
    
    return _shareServices;
}

@end
