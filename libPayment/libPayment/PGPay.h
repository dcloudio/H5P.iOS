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

@interface  PGPlatby : PGPlugin {
}
@property(nonatomic, copy)NSString* type;
@property(nonatomic, copy)NSString *description;
@property(nonatomic, assign)BOOL serviceReady;
- (NSDictionary*)JSDict;
- (void)request:(PGMethod*)command;
- (void)requestOrder:(PGMethod *)command;
- (void)restoreComplateRequest:(PGMethod*)command;
- (void)addRequestListener:(PGMethod*)command;
- (void)removeRequestListener:(PGMethod*)command;
- (void)installService;
- (NSData*)appStoreReceipt;
@end
