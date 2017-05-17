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
#import <AMapSearchKit/AMapSearchObj.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    PGMapReqTypeGeocode,
    PGMapReqTypeReverseGeocode
}PGMapGeoReqType;

@interface PGMapGeoReq : NSObject
@property(nonatomic, assign)PGMapGeoReqType reqType;
@property(nonatomic, copy)NSString *city;
@property(nonatomic, copy)NSString *address;
@property(nonatomic, assign)CLLocationCoordinate2D coordinate2D;
@property(nonatomic, copy)NSString *callbackId;
@end


@interface PGMap : PGPlugin<AMapSearchDelegate>
{
    //js中创建的地图字典
    NSMutableDictionary *_nativeObjectDict;
    AMapSearchAPI *_codeSearch;
    NSMutableArray *_geocodeReqs;
    BOOL _codeSearchRuning;
}

@property(nonatomic, readonly)NSDictionary *nativeOjbectDict;

//创建js native层对象
- (void)createObject:(PGMethod*)command;
// js属性更改同步更新native对象
- (void)updateObject:(PGMethod*)command;
- (void)execMethod:(PGMethod*)command;
//native
- (void)insertGisOverlay:(id)object withKey:(NSString*)key;

- (void)calculateDistance:(PGMethod*)command;
- (void)calculateArea:(PGMethod*)command;
- (void)convertCoordinates:(PGMethod*)command;
- (void)geocode:(PGMethod*)command;
- (void)reverseGeocode:(PGMethod*)command;
@end
