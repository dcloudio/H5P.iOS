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
#import "PGShare.h"

@interface  PGShareManager : PGPlugin {
    //控件数组
    NSMutableDictionary *_shareControlServices;
    NSMutableArray *_shareServices;
}

- (void)getServices:(PGMethod*)command;
- (void)authorize:(PGMethod*)command;
- (void)forbid:(PGMethod*)command;
- (void)send:(PGMethod*)command;
// share control
- (void)create:(PGMethod*)command;
- (void)load:(PGMethod*)command;
- (void)setVisible:(PGMethod*)command;
- (PGShare*)getShareObjectByType:(NSString*)aType;
- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe;

@end
