/*
 *------------------------------------------------------------------
 *  pandora/feature/PGAccelerometer.h
 *  Description:
 *      加速器API实现
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-13 创建文件 该文件改自Phonegap源码
 *------------------------------------------------------------------
 */

#import "PGPlugin.h"
#import "PGMethod.h"
#import <UIKit/UIKit.h>

@interface PGAccelerometer : PGPlugin <UIAccelerometerDelegate>
{
    double x;
    double y;
    double z;
    NSTimeInterval timestamp;
}

@property (readonly, assign) BOOL isRunning;
@property (nonatomic, strong) NSString* callbackId;

- (PGAccelerometer*)init;

- (void)start:(PGMethod*)command;
- (void)stop:(PGMethod*)command;

@end
