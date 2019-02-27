//
//  libBlueTooth.m
//  libBlueTooth
//
//  Created by ankai on 2018/11/19.
//  Copyright © 2018 LinXinzheng. All rights reserved.
//

#import "libBlueTooth.h"
#import "HLBLEManager.h"
#import <CoreBluetooth/CoreBluetooth.h>


@interface libBlueTooth()

@property (nonatomic, assign)int  mBlueToothState;
@property (nonatomic, strong)DCHLBLEManager * mBleManager;
@property (nonatomic, strong)NSMutableDictionary* connectDeviceArray;
@property (strong, nonatomic)NSMutableDictionary* deviceArray;
@property (strong, nonatomic)NSMutableDictionary* rssiArray;
@property (strong, nonatomic)PDRCoreAppFrame* m_evalFrame;

@property (strong, nonatomic)NSString* onBluetoothAdapterStateChangeCbid;
@property (strong, nonatomic)NSString* onBluetoothDeviceFoundCbid;
@property (strong, nonatomic)NSString* onBLECharacteristicValueChangeCbid;
@property (strong, nonatomic)NSString* onBLEConnectionStateChangeCbid;

@end

@implementation libBlueTooth

- (PGPlugin*) initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp*)app{
    if (self = [super initWithWebView:theWebView withAppContxt:app]) {
        if (_connectDeviceArray == nil)
            _connectDeviceArray = [NSMutableDictionary dictionaryWithCapacity:0];
        
        if (_deviceArray == nil)
            _deviceArray = [NSMutableDictionary dictionaryWithCapacity:0];
        
        if (_rssiArray == nil) {
            _rssiArray = [NSMutableDictionary dictionaryWithCapacity:0];
        }

        _mBleManager = NULL;
    }
    return self;
    
}
-(void)openBluetoothAdapter:(PGMethod*)pMethod{
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    __weak typeof(self) weakSelf = self;
    if (_mBleManager == NULL) {
        _mBleManager = [DCHLBLEManager sharedInstance];
        _mBleManager.stateUpdateBlock = ^(CBCentralManager *central) {
            NSString *info = nil;
            switch (central.state) {
                case CBCentralManagerStatePoweredOn:{
                    info = @"蓝牙已打开，并且可用";
                    weakSelf.mBlueToothState = 0;
                    _m_evalFrame = self.JSFrameContext;
                    [weakSelf toSucessCallback:weakSelf.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:YES],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
                }
                    break;
                case CBCentralManagerStatePoweredOff:
                case CBCentralManagerStateUnsupported:
                case CBCentralManagerStateResetting:
                case CBCentralManagerStateUnknown:{
                    weakSelf.mBlueToothState = 10001;
                    [weakSelf toSucessCallback:weakSelf.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:false],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
                }
                    break;
                case CBCentralManagerStateUnauthorized:{
                    weakSelf.mBlueToothState = 10000;
                    [weakSelf toSucessCallback:weakSelf.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:false],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
                }
                    break;
            }
        };
        [weakSelf toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
    }else{
        if (_mBlueToothState == 0) {
            [weakSelf toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
        }else if(_mBlueToothState == 10000){
            [weakSelf toErrorCallback:cbid withCode:weakSelf.mBlueToothState withMessage:@"not init"];
        }else {
            [weakSelf toErrorCallback:cbid withCode:weakSelf.mBlueToothState withMessage:@"not available"];
        }
    }
}

- (void)closeBluetoothAdapter:(PGMethod*)pMethod{
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    if (_mBleManager) {
        NSArray* allKeys = [_connectDeviceArray allKeys];
        for (NSString* sKey in allKeys) {
            CBPeripheral* peripheral = [_connectDeviceArray objectForKey:sKey];
            [_mBleManager cancelPeripheralConnection:peripheral];
        }
        [_connectDeviceArray removeAllObjects];
        [_deviceArray removeAllObjects];
        [_mBleManager stopScan];
        _mBleManager = nil;

        [self toSucessCallback:self.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:false],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
    }else{
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
    }
    [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
    
}

-(void)getBluetoothAdapterState:(PGMethod*)pMethod{
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    __weak typeof(self) weakSelf = self;
    if (_mBleManager == NULL) {
        _mBleManager = [DCHLBLEManager sharedInstance];
        _mBleManager.getRSSIBlock = ^(CBPeripheral *peripheral, NSNumber *RSSI, NSError *error) {
            [weakSelf.rssiArray setObject:RSSI forKey:peripheral.identifier.UUIDString];
        };
        
        _mBleManager.stateUpdateBlock = ^(CBCentralManager *central) {
            NSString *info = nil;
            switch (central.state) {
                case CBManagerStatePoweredOn:{
                    info = @"蓝牙已打开，并且可用";
                    weakSelf.mBlueToothState = 0;
                    [weakSelf toSucessCallback:weakSelf.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:YES],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
                }
                    break;
                case CBManagerStatePoweredOff:
                case CBManagerStateUnsupported:
                case CBManagerStateResetting:
                case CBManagerStateUnknown:
                {
                    weakSelf.mBlueToothState = 10001;
                    [weakSelf toSucessCallback:weakSelf.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:false],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
                }
                    break;
                case CBManagerStateUnauthorized:
                {
                    weakSelf.mBlueToothState = 10000;
                    [weakSelf toSucessCallback:weakSelf.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:false],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];
                }
                    break;
            }
        };
    }else{
        if (_mBlueToothState == 0) {
            [weakSelf toSucessCallback:cbid withJSON:@{@"available":[NSNumber numberWithBool:YES],@"discovering":[NSNumber numberWithBool: [_mBleManager isScaning]]}];
        }
        else{
            [weakSelf toSucessCallback:cbid withJSON:@{@"available":[NSNumber numberWithBool:false],@"discovering":[NSNumber numberWithBool:false]} keepCallback:NO];
        }
    }
}

-(void)getBluetoothDevices:(PGMethod*)pMethod{
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSMutableArray* results = [NSMutableArray arrayWithCapacity:0];
    __weak typeof(self) weakself = self;
    if (_mBleManager) {
        NSArray* allKeys = [weakself.deviceArray allKeys];
        for (NSString* uuid in allKeys) {
            NSMutableDictionary* resultItem = [NSMutableDictionary dictionaryWithCapacity:0];
            NSDictionary* itemInfo = [[weakself deviceArray] objectForKey:uuid];
            if (itemInfo) {
                CBPeripheral* serv =[itemInfo objectForKey:@"CBPeripheral"];
                NSDictionary* advNode = [itemInfo objectForKey:@"advNode"];
                if (serv && advNode) {
                    [serv readRSSI];
                    [resultItem setValue:uuid forKey:@"deviceId"];
                    [resultItem setValue:serv.name?serv.name:@"" forKey:@"name"];
                    [resultItem setValue:[_rssiArray objectForKey:uuid] forKey:@"RSSI"];
                    NSData *advertisData = [advNode objectForKey:@"kCBAdvDataManufacturerData"];
                    if (advertisData) {
                        NSMutableArray* result = [NSMutableArray arrayWithCapacity:0];
                        size_t bufSize = sizeof(char)*(advertisData.length + 1);
                        Byte* buffer = (Byte*)malloc(bufSize);
                        if (buffer) {
                            memset(buffer, 0, bufSize);
                            [advertisData getBytes:buffer length:advertisData.length];
                            for (int index = 0; index < advertisData.length; index++) {
                                [result addObject: [NSNumber numberWithInt:(int)buffer[index]]];
                            }
                            [resultItem setValue:result forKey:@"advertisData"];
                        }
                    }

                    NSArray *kCBAdvDataServiceUUIDs = advNode[@"kCBAdvDataServiceUUIDs"];
                    if (kCBAdvDataServiceUUIDs) {
                        [resultItem setValue:kCBAdvDataServiceUUIDs forKey:@"advertisServiceUUIDs"];
                    }
                    
                    NSString* kCBAdvDataLocalName = [advNode objectForKey:@"kCBAdvDataLocalName"];
                    if (kCBAdvDataLocalName) {
                        [resultItem setValue:kCBAdvDataLocalName forKey:@"localName"];
                    }
                }
            }
            [results addObject:resultItem];
        }
        [self toSucessCallback:cbid withJSON:@{@"devices":results}];
    }else{
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
    }
}

-(void)getConnectedBluetoothDevices:(PGMethod*)pMethod{
    NSArray* uuids = nil;
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];
    
    if (argus && [argus isKindOfClass:[NSDictionary class]]) {
        uuids = [argus objectForKey:@"services"];
    }
    
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:0];
    if (_mBleManager) {
        if (uuids && [uuids isKindOfClass:[NSArray class]] && uuids.count > 0) {
            for (NSString* uuid in uuids) {
                if ([uuids isKindOfClass:[NSString class]]) {
                    CBPeripheral* peritem = [_connectDeviceArray objectForKey:uuids];
                    if (peritem) {
                        NSDictionary* dic = @{@"deviceId":uuid, @"name":peritem.name?peritem.name:@""};
                        [result addObject:dic];
                    }
                }
            }
            if ([result count] > 0) {
                [self toSucessCallback:cbid withArray:result];
            }else{
                [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
            }
        }else{
            NSArray* allkeys = [_connectDeviceArray allKeys];
            for (NSString* key in allkeys) {
                CBPeripheral* item = [_connectDeviceArray objectForKey:key];
                if (item) {
                    NSDictionary* dic = @{@"deviceId": key, @"name":item.name?item.name:@""};
                    [result addObject:dic];
                }
            }
            [self toSucessCallback:cbid withJSON:@{@"devices":result}];
        }
    }else{
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
    }
}

-(void)startBluetoothDevicesDiscovery:(PGMethod*)pMethod{
    int interval = 0;
    NSArray* serviceID = NULL;
    bool allowDuplicatesKey = false;
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* infoDic = [pMethod.arguments objectAtIndex:1];
    
    if (infoDic && [infoDic isKindOfClass:[NSDictionary class]]) {
        NSArray* pallKeys = [infoDic allKeys];
        if ([pallKeys containsObject:@"services"]) {
            serviceID = [infoDic objectForKey:@"services"];
        }
        if ([pallKeys containsObject:@"allowDuplicatesKey"]) {
            allowDuplicatesKey = [[infoDic objectForKey:@"allowDuplicatesKey"] boolValue];
        }
        if ([pallKeys containsObject:@"interval"]) {
            interval = [[infoDic objectForKey:@"interval"] intValue];
        }
    }
    
    __weak typeof(self) weakself = self;
    
    NSMutableArray* cbuuids = [NSMutableArray arrayWithCapacity:0];
    if (serviceID  && [serviceID isKindOfClass:[NSArray class]] && serviceID.count) {
        for (NSString* item in serviceID ) {
            CBUUID* cbuuid = [CBUUID UUIDWithString:item];
            [cbuuids addObject:cbuuid];
        }
    }
    
    if (_mBleManager && ![_mBleManager isScaning]) {
        _mBleManager.discoverPeripheralBlcok = ^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
            
            BOOL bHasNewObj = false;
            if (weakself.deviceArray.allKeys.count == 0) {
                NSDictionary* itemObj = @{@"CBPeripheral":peripheral,@"advNode":advertisementData};
                [weakself.deviceArray setObject:itemObj forKey:peripheral.identifier.UUIDString];
                bHasNewObj = true;
            } else {
                BOOL isExist = NO;
                for (int i = 0; i < weakself.deviceArray.count; i++) {
                    NSArray* allKeys = [weakself.deviceArray allKeys];
                    if([allKeys containsObject:peripheral.identifier.UUIDString]){
                        isExist = YES;
                    }
                }
                
                if (!isExist) {
                    NSDictionary* itemObj = @{@"CBPeripheral":peripheral,@"advNode":advertisementData};
                    [weakself.deviceArray setObject:itemObj forKey:peripheral.identifier.UUIDString];
                    bHasNewObj = true;
                }
            }
            
            if (bHasNewObj) {
                NSMutableArray* results = [NSMutableArray arrayWithCapacity:0];
                if (allowDuplicatesKey) {
                    NSArray* allKeys = [weakself.deviceArray allKeys];
                    for (NSString* uuid in allKeys) {
                        NSDictionary* itemInfo = [[weakself deviceArray] objectForKey:uuid];
                        if (itemInfo) {
                            CBPeripheral* serv =[itemInfo objectForKey:@"CBPeripheral"];
                            NSDictionary* advNode = [itemInfo objectForKey:@"advNode"];
                            NSNumber* nrssi = [weakself.rssiArray objectForKey:uuid];
                            //[itemInfo objectForKey:@"RSSI"];
                            NSDictionary* resultItem = [weakself getPeripherInfo:serv AndAdvInfo:advNode RSSI:nrssi];
                            [results addObject:resultItem];
                        }
                    }
                }else{
                    NSDictionary* resultItem = [weakself getPeripherInfo:peripheral AndAdvInfo:advertisementData RSSI:RSSI];
                    [results addObject:resultItem];
                }
                
                if (weakself.onBluetoothDeviceFoundCbid) {
                    [weakself toSucessCallback:weakself.onBluetoothDeviceFoundCbid withJSON:@{@"devices":results} keepCallback:YES];
                }
            }
        };

        [_mBleManager scanForPeripheralsWithServiceUUIDs:[cbuuids count]?cbuuids:nil options:@{CBCentralManagerRestoredStateScanOptionsKey:@(YES)}];
        [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
    }else{
        if (_mBleManager == nil) {
            [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        }else{
            [self toErrorCallback:cbid withCode:10009 withMessage:@"inScanning"];
        }
    }
}

- (NSDictionary*)getPeripherInfo:(CBPeripheral*)serv AndAdvInfo:(NSDictionary*)advNode RSSI:(NSNumber*)rssi{
    NSMutableDictionary* resultItem = [NSMutableDictionary dictionaryWithCapacity:0];
    if (serv && advNode) {
        [serv readRSSI];
        [resultItem setValue:serv.identifier.UUIDString forKey:@"deviceId"];
        [resultItem setValue:serv.name?serv.name:@"" forKey:@"name"];
        [resultItem setValue:rssi forKey:@"RSSI"];
        NSData *advertisData = [advNode objectForKey:@"kCBAdvDataManufacturerData"];
        if (advertisData) {
            NSMutableArray* result = [NSMutableArray arrayWithCapacity:0];
            size_t bufSize = sizeof(char)*(advertisData.length + 1);
            Byte* buffer = (Byte*)malloc(bufSize);
            if (buffer) {
                memset(buffer, 0, bufSize);
                [advertisData getBytes:buffer length:advertisData.length];
                for (int index = 0; index < advertisData.length; index++) {
                    [result addObject: [NSNumber numberWithInt:(int)buffer[index]]];
                }
                [resultItem setValue:result forKey:@"advertisData"];
            }
        }
        
        NSArray *kCBAdvDataServiceUUIDs = advNode[@"kCBAdvDataServiceUUIDs"];
        if (kCBAdvDataServiceUUIDs) {
            NSMutableArray* serUUids = [NSMutableArray arrayWithCapacity:0];
            for (CBUUID* item in kCBAdvDataServiceUUIDs) {
                [serUUids addObject:item.UUIDString];
            }
            [resultItem setValue:serUUids forKey:@"advertisServiceUUIDs"];
        }
        
        NSString* kCBAdvDataLocalName = [advNode objectForKey:@"kCBAdvDataLocalName"];
        if (kCBAdvDataLocalName) {
            [resultItem setValue:kCBAdvDataLocalName forKey:@"localName"];
        }

        NSDictionary* kServiceData = [advNode objectForKey:@"kCBAdvDataServiceData"];
        if (kServiceData) {
            [resultItem setValue:kServiceData forKey:@"serviceData"];
        }
    }
    return resultItem;
}



-(void)stopBluetoothDevicesDiscovery:(PGMethod*)pMethod{
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    if (_mBleManager) {
        if([_mBleManager isScaning]){
            NSLog(@"stopScan");
            [_mBleManager stopScan];
            [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
            [self toSucessCallback:self.onBluetoothAdapterStateChangeCbid withJSON:@{@"available":[NSNumber numberWithBool:true],@"discovering":[NSNumber numberWithBool:false]} keepCallback:YES];        }
    }else{
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
    }
}


- (void)onBluetoothAdapterStateChange:(PGMethod*)pMethod{
    NSString* pCbid = [pMethod.arguments objectAtIndex:0];
    self.onBluetoothAdapterStateChangeCbid = [[NSString alloc] initWithString:pCbid];
}

- (void)onBluetoothDeviceFound:(PGMethod*)pMethod{
    NSString* pCbid = [pMethod.arguments objectAtIndex:0];
    self.onBluetoothDeviceFoundCbid = [[NSString alloc] initWithString:pCbid];
}


////////////////////////////////////////////////////////////
-(void)createBLEConnection:(PGMethod*)pMethod{
    NSString* deviceID = nil;
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    
    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }
    
    NSDictionary* paramInfo = [pMethod.arguments objectAtIndex:1];
    if (paramInfo && [paramInfo isKindOfClass:[NSDictionary class]]) {
        deviceID = [paramInfo objectForKey:@"deviceId"];
    }
    
    if (deviceID && [deviceID isKindOfClass:[NSString class]]) {
        
        NSDictionary* perInfoDic = [self.deviceArray objectForKey:deviceID];
        if (perInfoDic == nil || ![perInfoDic isKindOfClass:[NSDictionary class]]){
            [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
            return;
        }
        
        CBPeripheral* peripheral = [perInfoDic objectForKey:@"CBPeripheral"];
        if (peripheral) {
            
            __weak typeof (self) weakself = self;

            [_mBleManager setDisconnectBlock:^(CBPeripheral *peripheral, NSError *error) {
                [weakself.connectDeviceArray removeObjectForKey:peripheral.identifier.UUIDString];

                if (weakself.onBLEConnectionStateChangeCbid) {
                    [weakself toSucessCallback:weakself.onBLEConnectionStateChangeCbid
                                      withJSON:@{@"deviceId":peripheral.identifier.UUIDString,
                                                 @"connected":[NSNumber numberWithBool:peripheral.state == CBPeripheralStateConnected]}
                                  keepCallback:YES];
                }
            }];

            [_mBleManager connectPeripheral:peripheral
                             connectOptions:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}
                     stopScanAfterConnected:NO
                            servicesOptions:nil
                     characteristicsOptions:nil
                              completeBlock:^(HLOptionStage stage,
                                              CBPeripheral *fperipheral,
                                              CBService *service,
                                              CBCharacteristic *character,
                                              NSError *error) {
                                  if (error == nil && stage == HLOptionStageConnection && peripheral.state == CBPeripheralStateConnected) {
                                      [weakself.connectDeviceArray setObject:peripheral forKey:deviceID];
                                      if (weakself.onBLEConnectionStateChangeCbid) {
                                          [weakself toSucessCallback:weakself.onBLEConnectionStateChangeCbid
                                                            withJSON:@{@"deviceId":peripheral.identifier.UUIDString,
                                                                       @"connected":[NSNumber numberWithBool:peripheral.state == CBPeripheralStateConnected]}
                                                        keepCallback:YES];
                                      }
                                  }
                                  
                              }];
            [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
        }
        else{
            [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        }
    }
    else{
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
    }
    
}

-(void)closeBLEConnection:(PGMethod*)pMethod{
    NSString* deviceID = nil;
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];
    
    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }
    
    if (argus != nil && [argus isKindOfClass:[NSDictionary class]]) {
        deviceID = [argus objectForKey:@"deviceId"];
    }
    
    if (deviceID == nil || ![deviceID isKindOfClass:[NSString class]]) {
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }
    
    CBPeripheral* peripheral = [self.connectDeviceArray objectForKey:deviceID];
    if (peripheral) {
        [_mBleManager cancelPeripheralConnection:peripheral];
        [self.connectDeviceArray removeObjectForKey:deviceID];
        [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
        if (self.onBLEConnectionStateChangeCbid) {
            [self toSucessCallback:self.onBLEConnectionStateChangeCbid withJSON:@{@"deviceId":peripheral.identifier.UUIDString,
                                                                                  @"connected":[NSNumber numberWithBool:false]} keepCallback:YES];
        }
    }
    else{
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
    }
}

-(void)getBLEDeviceCharacteristics:(PGMethod*)pMethod{
    
    NSString* deviceID = nil;
    NSString* serviceId = nil;
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];
    
    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }
    
    if (argus != nil && [argus isKindOfClass:[NSDictionary class]]) {
        deviceID = [argus objectForKey:@"deviceId"];
        serviceId = [argus objectForKey:@"serviceId"];
    }
    
    if (nil == serviceId || ![serviceId isKindOfClass:[NSString class]]) {
        [self toErrorCallback:cbid withCode:10005 withMessage:@"no service"];
        return;
    }
    
    if (nil ==  deviceID || ![deviceID isKindOfClass:[NSString class]]) {
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }

    NSMutableArray* resultArray = [NSMutableArray arrayWithCapacity:0];
    CBPeripheral* deviceInfo = [_connectDeviceArray   objectForKey:deviceID];
    if (deviceInfo) {
        bool bFindService = false;
        for (CBService* item in deviceInfo.services){
            if ([item.UUID.UUIDString isEqualToString:serviceId]) {
                bFindService = true;
                for (CBCharacteristic* charactItem in item.characteristics) {
                    [resultArray addObject:@{@"uuid":charactItem.UUID.UUIDString,@"properties":@{
                                                     @"read":[NSNumber numberWithBool:charactItem.properties & CBCharacteristicPropertyRead],
                                                     @"write":[NSNumber numberWithBool:charactItem.properties & CBCharacteristicPropertyWrite],
                                                     @"notify":[NSNumber numberWithBool:charactItem.properties & CBCharacteristicPropertyNotify],
                                                     @"indicate":[NSNumber numberWithBool:charactItem.properties & CBCharacteristicPropertyIndicate]}}];

                }
            }
        }
        if (!bFindService) {
            [self toErrorCallback:cbid withCode:10005 withMessage:@"no service"];return;
        }
    }else{
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];return;
    }


    if (resultArray.count > 0) {
        [self toSucessCallback:cbid withJSON:@{@"characteristics":resultArray}];
    }else{
        [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
    }
}

-(void)getBLEDeviceServices:(PGMethod*)pMethod{
    NSString* deviceID = nil;
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];
    
    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }
    
    if (argus && [argus isKindOfClass:[NSDictionary class]]) {
        deviceID = [argus objectForKey:@"deviceId"];
    }
    if (deviceID == nil || ![deviceID isKindOfClass:[NSString class]]) {
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
    }
    
    CBPeripheral* device = [self.connectDeviceArray objectForKey:deviceID];
    if (nil == device) {
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }

    NSMutableArray* resultArray = [NSMutableArray arrayWithCapacity:0];
    for (CBService* serItem in device.services) {
        [resultArray addObject:@{@"uuid":serItem.UUID.UUIDString, @"isPrimary":[NSNumber numberWithBool:serItem.isPrimary]}];
    }

    if (resultArray.count > 0) {
        [self toSucessCallback:cbid withJSON:@{@"services":resultArray}];
    }else{
        [self toErrorCallback:cbid withCode:10005 withMessage:@"no service"];
    }
}


-(void)notifyBLECharacteristicValueChange:(PGMethod*)pMethod{
    NSString* deviceID = nil;
    NSString* serviceId = nil;
    NSString* characteristicId = nil;

    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];

    if (argus && [argus isKindOfClass:[NSDictionary class]]) {
        deviceID = [argus objectForKey:@"deviceId"];
        serviceId = [argus objectForKey:@"serviceId"];
        characteristicId = [argus objectForKey:@"characteristicId"];
    }

    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }

    if (deviceID == nil || ![deviceID isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }

    if(serviceId == nil || ![serviceId isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10004 withMessage:@"no service"];
        return;
    }

    if(characteristicId == nil || ![characteristicId isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
        return;
    }
    __weak typeof (self) weakself = self;
    CBPeripheral* device = [self.connectDeviceArray objectForKey:deviceID];
    if (device) {
        bool bFindService = false;
        for (CBService* seritem in device.services) {
            bool bFindCharact = false;
            if ([seritem.UUID.UUIDString isEqualToString:serviceId]) {
                bFindService = true;
                for (CBCharacteristic* charactItem in seritem.characteristics) {
                    if ([charactItem.UUID.UUIDString isEqualToString:characteristicId])
                    {
                        bFindCharact = true;
                        _mBleManager.notifyCharacteristicBlock = ^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
                            if (nil == error && charactItem.isNotifying){
                                NSData* value = characteristic.value;
                                if (value) {
                                    NSMutableArray* result = [NSMutableArray arrayWithCapacity:0];
                                    size_t bufSize = sizeof(char)*(value.length + 1);
                                    Byte* buffer = (Byte*)malloc(bufSize);
                                    if (buffer) {
                                        memset(buffer, 0, bufSize);
                                        [value getBytes:buffer length:value.length];
                                        for (int index = 0; index < value.length; index++) {
                                            [result addObject: [NSNumber numberWithInt:(int)buffer[index]]];
                                        }

                                        if (weakself.onBLECharacteristicValueChangeCbid) {
                                            [weakself toSucessCallback:weakself.onBLECharacteristicValueChangeCbid withJSON:@{@"deviceId":deviceID,@"serviceId":serviceId,@"characteristicId":characteristicId,@"value":result}
                                                          keepCallback:true];
                                        }
                                    }
                                    free(buffer);
                                }
                            }
                        };

                        [_mBleManager NotifyValueforCharacteristic:charactItem Peripheral:device];
                        [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
                        return;
                    }
                }
                if(!bFindCharact){
                    [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
                    return;
                }
            }
        }
        if (!bFindService) {
            [self toErrorCallback:cbid withCode:10004 withMessage:@"no service"];
            return;
        }
    }else{
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }
}

-(void)onBLECharacteristicValueChange:(PGMethod*)pMethod{
    NSString* pCbid = [pMethod.arguments objectAtIndex:0];
    self.onBLECharacteristicValueChangeCbid = [[NSString alloc] initWithString:pCbid];
    
}

-(void)onBLEConnectionStateChange:(PGMethod*)pMethod{
    NSString* pCbid = [pMethod.arguments objectAtIndex:0];
    self.onBLEConnectionStateChangeCbid = [[NSString alloc] initWithString:pCbid];
}

-(void)readBLECharacteristicValue:(PGMethod*)pMethod{
    NSString* deviceID = nil;
    NSString* serviceId = nil;
    NSString* characteristicId = nil;
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];
    
    if (argus && [argus isKindOfClass:[NSDictionary class]]) {
        deviceID = [argus objectForKey:@"deviceId"];
        serviceId = [argus objectForKey:@"serviceId"];
        characteristicId = [argus objectForKey:@"characteristicId"];
    }
    
    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }
    
    if (deviceID == nil || ![deviceID isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }
    
    if(serviceId == nil || ![serviceId isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10004 withMessage:@"no service"];
        return;
    }
    
    if(characteristicId == nil || ![characteristicId isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
        return;
    }
    __weak typeof (self) weakself = self;
    CBPeripheral* device = [self.connectDeviceArray objectForKey:deviceID];
    if (device) {
        bool bFindService = false;
        for (CBService* seritem in device.services) {
            bool bFindCharact = false;
            if ([seritem.UUID.UUIDString isEqualToString:serviceId]) {
                bFindService = true;
                for (CBCharacteristic* charactItem in seritem.characteristics) {
                    if ([charactItem.UUID.UUIDString isEqualToString:characteristicId]) {
                        bFindCharact = true;
                        _mBleManager.valueForCharacteristicBlock = ^(CBCharacteristic *characteristic, NSData *value, NSError *error) {
                            if (value && error == nil) {
                                NSMutableArray* result = [NSMutableArray arrayWithCapacity:0];
                                size_t bufSize = sizeof(char)*(value.length + 1);
                                Byte* buffer = (Byte*)malloc(bufSize);
                                if (buffer) {
                                    memset(buffer, 0, bufSize);
                                    [value getBytes:buffer length:value.length];
                                    for (int index = 0; index < value.length; index++) {
                                        [result addObject: [NSNumber numberWithInt:(int)buffer[index]]];
                                    }
                                    
                                    if (weakself.onBLECharacteristicValueChangeCbid) {
                                        [weakself toSucessCallback:weakself.onBLECharacteristicValueChangeCbid withJSON:@{@"deviceId":deviceID,@"serviceId":serviceId,@"characteristicId":characteristicId,@"value":result}
                                                      keepCallback:true];
                                    }
                                }
                                free(buffer);
                            }
                        };
                        [_mBleManager readValueForCharacteristic:charactItem Peripheral:device];
                        [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
                        return;
                    }
                }
                if(!bFindCharact){
                    [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
                    return;
                }
            }
        }
        if (!bFindService) {
            [self toErrorCallback:cbid withCode:10004 withMessage:@"no service"];
            return;
        }
    }else{
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }
}

-(void)writeBLECharacteristicValue:(PGMethod*)pMethod{
    NSString* deviceID = nil;
    NSString* serviceId = nil;
    NSString* characteristicId = nil;
    NSString* valueAry = nil;
    
    NSString* cbid = [pMethod.arguments objectAtIndex:0];
    NSDictionary* argus = [pMethod.arguments objectAtIndex:1];

    if (argus && [argus isKindOfClass:[NSDictionary class]]) {
        deviceID = [argus objectForKey:@"deviceId"];
        serviceId = [argus objectForKey:@"serviceId"];
        characteristicId = [argus objectForKey:@"characteristicId"];
        valueAry = [argus objectForKey:@"value"];
    }
    
    if (_mBleManager == nil) {
        [self toErrorCallback:cbid withCode:10000 withMessage:@"not init"];
        return;
    }
    
    if (deviceID == nil || ![deviceID isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }
    
    if(serviceId == nil || ![serviceId isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10004 withMessage:@"no service"];
        return;
    }
    
    if(characteristicId == nil || ![characteristicId isKindOfClass:[NSString class]]){
        [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
        return;
    }
    
    NSArray* array = [valueAry componentsSeparatedByString:@","];
    Byte* buffer  = (Byte*)malloc(sizeof(char) * ([array count] + 5));
    for (int i = 0; i < [array count]; i++) {
        NSString* item = [array objectAtIndex:i];
        int val  = [item intValue];
        buffer[i] = val;
    }
    
    __weak typeof (self) weakself = self;
    CBPeripheral* device = [self.connectDeviceArray objectForKey:deviceID];
    if (device) {
        bool bFindService = false;
        for (CBService* seritem in device.services) {
            bool bFindCharact = false;
            if ([seritem.UUID.UUIDString isEqualToString:serviceId]) {
                bFindService = true;
                for (CBCharacteristic* charactItem in seritem.characteristics) {
                    if ([charactItem.UUID.UUIDString isEqualToString:characteristicId]) {
                        bFindService = true;
                        [weakself.mBleManager writeValue:[NSData dataWithBytes:buffer length:array.count]
                                       forCharacteristic:charactItem
                                              Peripheral:device
                                                    type:CBCharacteristicWriteWithResponse
                                         completionBlock:^(CBCharacteristic *characteristic, NSError *error) {
                                             if (nil == error){
                                                 [self toSucessCallback:cbid withJSON:@{@"code":@(0),@"message":@"ok"}];
                                             }else{
                                                 [self toErrorCallback:cbid withCode:10007 withMessage:@"property not support"];
                                             }
                                         }];

//                        weakself.mBleManager.notifyCharacteristicBlock = ^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
//                            if (nil == error && charactItem.isNotifying){
//                                NSData* value = characteristic.value;
//                                if (value) {
//                                    NSMutableArray* result = [NSMutableArray arrayWithCapacity:0];
//                                    size_t bufSize = sizeof(char)*(value.length + 1);
//                                    Byte* buffer = (Byte*)malloc(bufSize);
//                                    if (buffer) {
//                                        memset(buffer, 0, bufSize);
//                                        [value getBytes:buffer length:value.length];
//                                        for (int index = 0; index < value.length; index++) {
//                                            [result addObject: [NSNumber numberWithInt:(int)buffer[index]]];
//                                        }
//
//                                        if (weakself.onBLECharacteristicValueChangeCbid) {
//                                            [weakself toSucessCallback:weakself.onBLECharacteristicValueChangeCbid withJSON:@{@"deviceId":deviceID,@"serviceId":serviceId,@"characteristicId":characteristicId,@"value":result}
//                                                          keepCallback:true];
//                                        }
//                                    }
//                                    free(buffer);
//                                }
//                            }
//                        };
//                        [weakself.mBleManager NotifyValueforCharacteristic:charactItem Peripheral:device];
                    }
                }
                if(bFindCharact){
                    [self toErrorCallback:cbid withCode:10005 withMessage:@"no characteristic"];
                    return;
                }
            }
        }
        if (!bFindService) {
            [self toErrorCallback:cbid withCode:10004 withMessage:@"no service"];
            return;
        }
    }else{
        [self toErrorCallback:cbid withCode:10002 withMessage:@"no device"];
        return;
    }
}

#pragma mark delegates

@end
