//
//  libUpYunLivePush.h
//  libUpYunLivePush
//
//  Created by nearwmy on 2018/6/1.
//  Copyright © 2018年 nearwmy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGPlugin.h"

typedef enum {
    EDCLiveMode_SD,
    EDCLiveMode_HD,
    EDCLiveMode_FHD,
    EDCLiveMode_RTC
}EDCLiveMode;

typedef enum {
    VERTIAL,
    HORIZONTAL
}EDCLiveOrientation;

@interface PGLivePush : PGPlugin

@end
