/*
 *------------------------------------------------------------------
 *  pandora/feature/PGStatistic.h
 *  Description:
 *      统计头文件定义
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

#import "PGPlugin.h"
#import "PGMethod.h"

@interface PGStatistic : PGPlugin
{
    @private
}
- (void) eventTrig:(PGMethod*)command;
- (void) eventStart:(PGMethod*)command;
- (void) eventEnd:(PGMethod*)command;
- (void) eventDuration:(PGMethod*)command;

@end