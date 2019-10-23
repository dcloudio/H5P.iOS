//
//  Oauth.h
//  Oauth
//
//  Created by X on 15/3/3.
//  Copyright (c) 2015年 io.dcloud. Oauth. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PGPlugin.h"
#import "PGMethod.h"

@interface  PGOauthManager : PGPlugin {
    //控件数组
    NSMutableArray *_oauthServices;
}

- (void)getServices:(PGMethod*)command;
- (void)login:(PGMethod*)command;
- (void)logout:(PGMethod*)command;
- (void)getUserInfo:(PGMethod*)command;

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe;
@end