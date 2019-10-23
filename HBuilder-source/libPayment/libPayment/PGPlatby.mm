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
#import "PGPlatby.h"

@implementation PGPlatby

@synthesize type;
@synthesize description;
@synthesize serviceReady;


- (id)init {
    if ( self = [super init] ) {
        //self.sdkErrorURL = @"http://ask.dcloud.net.cn/article/286";
        self.serviceReady = TRUE;
    }
    return self;
}

- (NSDictionary*)JSDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ( self.description ) {
        [dict setObject:self.description forKey:@"description"];
    } else {
        [dict setObject:@"" forKey:@"description"];
    }
    if ( self.type ) {
        [dict setObject:self.type forKey:@"id"];
    } else {
        [dict setObject:@"" forKey:@"id"];
    }
    [dict setObject:[NSNumber numberWithBool:self.serviceReady] forKey:@"serviceReady"];
    return dict;
}

- (void)request:(PGMethod*)command {
   
}
- (void)requestOrder:(PGMethod *)command
{
}
- (void)installService {

}
- (void)restoreComplateRequest:(PGMethod*)command
{}
- (void)addRequestListener:(PGMethod*)command
{}
- (void)removeRequestListener:(PGMethod*)command
{}
- (NSData*)appStoreReceipt
{return nil;}

- (void)dealloc {
    self.type = nil;
    self.description = nil;
    [super dealloc];
}

@end
