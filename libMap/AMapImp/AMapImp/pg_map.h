/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map.h
 *  Description:
 *      地图插件头文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2012-12-07 创建文件
 *------------------------------------------------------------------
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PGPlugin.h"
#import "PGMethod.h"
#import "PGMap.h"
#import <AMapSearchKit/AMapSearchObj.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import <CoreLocation/CoreLocation.h>

@interface PGMap : PGMapPlugin<AMapSearchDelegate>
{
    AMapSearchAPI *_codeSearch;
    NSMutableArray *_geocodeReqs;
    BOOL _codeSearchRuning;
}

- (void)calculateDistance:(PGMethod*)command;
- (void)calculateArea:(PGMethod*)command;
- (void)convertCoordinates:(PGMethod*)command;
- (void)geocode:(PGMethod*)command;
- (void)reverseGeocode:(PGMethod*)command;
@end
