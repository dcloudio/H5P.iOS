//
//  libWXLivePusherComponent.h
//  DCUniLivePush
//
//  Created by 4Ndf on 2019/5/13.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "WXComponent.h"
#import "PGPlugin.h"
#import "WXModuleProtocol.h"
typedef enum {
    EDCLiveMode_SD,
    EDCLiveMode_HD,
    EDCLiveMode_FHD,
    EDCLiveMode_RTC
}WXEDCLiveMode;

typedef enum {
    VERTIAL,
    HORIZONTAL
}WXEDCLiveOrientation;

@interface PGWXLivePusherComponent : WXComponent<WXModuleProtocol>

@end
