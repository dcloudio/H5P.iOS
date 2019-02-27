//
//  wxBeacon.h
//  HBuilder
//
//  Created by apple on 2018/9/17.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#include "PGPlugin.h"
#include "PGMethod.h"

@interface PGBeacon : PGPlugin


/**
 开始iBeacon扫描
 
 @param command iBeacon设备广播的 uuids
 */
- (void)startBeaconDiscovery:(PGMethod *)command;

/**
 停止搜索附近的iBeacon设备
 */
- (void)stopBeaconDiscovery:(PGMethod *)command;

/**
 获取所有已搜索到的iBeacon设备,返回beacons数组
 */
- (NSData *)getBeacons:(PGMethod *)command;

/**
 监听 iBeacon 设备的更新事件
 
 return 当前搜寻到的所有 iBeacon 设备列表
 */
- (void)onBeaconUpdate:(PGMethod *)command;

/**
 监听 iBeacon 服务的状态变化
 */
- (void)onBeaconServiceChange:(PGMethod *)command;

@end

