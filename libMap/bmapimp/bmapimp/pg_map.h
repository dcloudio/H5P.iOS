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
#import <CoreLocation/CoreLocation.h>
#import <BaiduMapAPI_Base/BMKMapManager.h>
#import <BaiduMapAPI_Search/BMKGeocodeSearch.h>
#import "PGMap.h"
#import "PGPlugin.h"
#import "PGMethod.h"

@interface PGMap : PGMapPlugin<BMKGeoCodeSearchDelegate>
{
    //js中创建的地图字典
    BMKGeoCodeSearch *_codeSearch;
    NSMutableArray *_geocodeReqs;
    BOOL _codeSearchRuning;
}

- (void)insertGisOverlay:(id)object withKey:(NSString*)key;

- (void)calculateDistance:(PGMethod*)command;
- (void)calculateArea:(PGMethod*)command;
- (void)convertCoordinates:(PGMethod*)command;
- (void)geocode:(PGMethod*)command;
- (void)reverseGeocode:(PGMethod*)command;
@end
