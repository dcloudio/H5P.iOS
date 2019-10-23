/*
 *------------------------------------------------------------------
 *  pandora/PGShare.h
 *  Description:
 *      上传插件头文件定义
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

#import "PGPlugin.h"
#import "PGMethod.h"
#import "PGPlatby.h"

@interface  PGPlatbyManager : PGPlugin {
    NSMutableArray *_payServices;
}

- (void)getChannels:(PGMethod*)command;
- (void)request:(PGMethod*)command;
- (void)installService:(PGMethod*)command;
- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe;
@end
