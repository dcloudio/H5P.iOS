/*
 *------------------------------------------------------------------
 *  pandora/feature/map/pg_map.m
 *  Description:
 *      地图插件实现文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *    number    author    modify date modify record
 *   0       xty     2012-12-07 创建文件
 *   Reviewed @ 20130105 by Lin Xinzheng
 *------------------------------------------------------------------
 */

#import "PGMap.h"
#import "PGObject.h"
#import "PGMapView.h"
#import "PDRCoreAppFrame.h"


@implementation PGMapGeoReq
@synthesize reqType;
@synthesize city;
@synthesize address;
@synthesize coordinate2D;
@synthesize callbackId;

- (void)dealloc {
    self.callbackId = nil;
    self.address = nil;
    self.city = nil;
    [super dealloc];
}

@end


@implementation PGMapPlugin
@synthesize nativeOjbectDict = _nativeObjectDict;
- (void)dealloc
{
    NSArray *allViews = [_nativeObjectDict allValues];
    for ( PGMapView *target in allViews ) {
        if ( [target isKindOfClass:[PGMapView class]] ) {
            [self.JSFrameContext removedNView:target];
            [target close];
        }
    }
    [_nativeObjectDict release];
    [super dealloc];
}
- (NSData*)getMapById:(PGMethod*)command {
    NSString *viewName = [command.arguments objectAtIndex:0];
    __block PGMapView *mapview = nil;
    [_nativeObjectDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, PGMapView * _Nonnull view, BOOL * _Nonnull stop) {
        if ( [view isKindOfClass:[PGMapView class]] ) {
            if ( NSOrderedSame == [viewName caseInsensitiveCompare:view.viewName] ) {
                mapview = view;
                [mapview addEvtCallbackId:[self JSFrameContextID]];
                *stop = YES;
            }
        }
    }];
    NSMutableDictionary *newOptions = [NSMutableDictionary dictionary];
    if ( [mapview.options isKindOfClass:[NSDictionary class]] ) {
        [newOptions addEntriesFromDictionary:mapview.options];
    }
    [newOptions setObject:@(mapview.zoomLevel) forKey:@"zoom"];
    return [self resultWithJSON:@{@"uuid":mapview.UUID?:@"",@"options":newOptions}];
}

- (void)onAppFrameWillClose:(PDRCoreAppFrame *)theAppframe {
    NSMutableArray *removeMapKeys = [NSMutableArray array];
    [_nativeObjectDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, PGMapView * _Nonnull mapView, BOOL * _Nonnull stop) {
        if ( [mapView isKindOfClass:[PGMapView class]] ) {
            if ( [mapView.webviewId isEqualToString:theAppframe.frameID]
                ||(mapView.parent  && [mapView.parent isEqualToString:theAppframe.frameID])) {
                [self.JSFrameContext removedNView:mapView];
                NSArray *ids = [mapView close];
                [removeMapKeys addObject:key];
                [removeMapKeys addObjectsFromArray:ids];
            }
        }
    }];
    [_nativeObjectDict removeObjectsForKeys:removeMapKeys];
}

- (PDRNView*)__getNativeViewById:(NSString*)uid {
    PGMapView *mapView = [_nativeObjectDict objectForKey:uid];
    return mapView;
}

-(PGMapView*)createMapViewWithArgs:(id)args {
    return nil;
}

- (id)createOverlayWithUUID:(NSString*)UUID withType:(NSString*)type args:(id)args inWebview:(NSString*)webviewId{
    return nil;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      js执行native对象方法
 * @Parameters:
 *       [1] command, js传入格式应该为 [uuid, [args]]
 * @Returns:
 *      BOOL 是否执行成功
 * @Remark:
 *    该方法会自动调用各自对象的updateobject
 * @Changelog:
 *------------------------------------------------------------------
 */
- (BOOL)updateObject:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return NO; }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        NSObject *object = [_nativeObjectDict objectForKey:UUID];
        if ( [object respondsToSelector:@selector(updateObject:) ] )
        {
            [object updateObject:(NSArray*)[command.arguments objectAtIndex:1]];
        }
    }
    return YES;
}

- (NSData*)updateObjectSYNC:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return nil; }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        NSObject *object = [_nativeObjectDict objectForKey:UUID];
        if ( [object respondsToSelector:@selector(updateObjectSync:) ] )
        {
            return [object updateObjectSync:(NSArray*)[command.arguments objectAtIndex:1]];
        }
    }
    return nil;
}

/**
 动态更新地图属性
 API: http://www.dcloud.io/docs/api/zh_cn/maps.html#plus.maps.Map.setStyles
 */
- (void)setStyles:(PGMethod *)command {
    if (!command || !command.arguments) {
        return;
    }
    
    NSString *UUID = [command.arguments objectAtIndex:0];
    if (UUID && [UUID isKindOfClass:[NSString class]]) {
        PGMapView *obj = [_nativeObjectDict objectForKey:UUID];
        if ([obj respondsToSelector:@selector(setStyles:)]) {
            [obj setStyles:command.arguments[1]];
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      js执行native类方法
 * @Parameters:
 *       [1] command, js传入格式应该为 [uuid, [args]]
 * @Returns:
 *      BOOL 是否执行成功
 * @Remark:
 *    该方法会自动调用各自对象的execMethod
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)execMethod:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return; }
    NSString *UUID = [command.arguments objectAtIndex:0];
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        if ( [UUID isEqualToString:@"map"] )
        {
            NSArray *args = [command.arguments objectAtIndex:1];
            if ( args )
            {
                NSString *cmd =  [args objectAtIndex:0];
                if ( [cmd isKindOfClass:[NSString class]] ) {
                    if ( [@"close" isEqualToString:cmd] ) {
                        NSString *UUID =  [args objectAtIndex:1];
                        PGMapView *map = [_nativeObjectDict objectForKey:UUID];
                        if ( [map isKindOfClass:[PGMapView class]] ) {
                            [self.JSFrameContext removedNView:map];
                            [map close];
                            [_nativeObjectDict removeObjectForKey:UUID];
                        }
                        return;
                    }
                }
                [PGMapView openSysMap:[args objectAtIndex:1]];
            }
        }
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      创建js native对象
 * @Parameters:
 *    [1] command, js调用格式应该为 [uuid, type, [args]]
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)createObject:(PGMethod*)command
{
    if ( !command || !command.arguments )
    { return; }
    
    NSString *UUID = [command.arguments objectAtIndex:0];
    
    if ( UUID && [UUID isKindOfClass:[NSString class]] )
    {
        if ( !_nativeObjectDict )
        { _nativeObjectDict = [[NSMutableDictionary alloc] initWithCapacity:10]; }
        NSString *type = [command.arguments objectAtIndex:1];
        if ( type && [type isKindOfClass:[NSString class]] )
        {
            //如果创建过就不在创建
            if ( [_nativeObjectDict objectForKey:UUID] )
            { return; }
            if ( [type isEqualToString:@"mapview"] )
            {
                PGMapView *mapView = [self createMapViewWithArgs:[command.arguments objectAtIndex:2]];
                if ( mapView )
                {
                    mapView.jsBridge = self;
                    mapView.UUID = UUID;
                    mapView.viewUUID = mapView.UUID;
                    mapView.webviewId = [self JSFrameContextID];
                    mapView.viewName = [PGPluginParamHelper getStringValue:[command.arguments objectAtIndex:3]];
                    [mapView addEvtCallbackId:[self JSFrameContextID]];
                    if ( !mapView.viewName ) {
                        [self.JSFrameContext appendNView:mapView forKey:mapView.viewUUID];
                    }
                    [_nativeObjectDict setObject:mapView forKey:UUID];
                }
            } else {
                id obj = [self createOverlayWithUUID:UUID withType:type args:[command.arguments objectAtIndex:2] inWebview:command.htmlID];
                if ( obj ) {
                    [_nativeObjectDict setObject:obj forKey:UUID];
                }
            }
            
        }
    }
}
/**
 *invake js marker object
 *@param command PGMethod*
 *@return 无
 */
- (void)insertGisOverlay:(id)object withKey:(NSString*)key
{
    if( !key || !object )
        return;
    
    if ( !_nativeObjectDict )
    {
        _nativeObjectDict = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    [_nativeObjectDict setObject:object forKey:key];
}


@end

