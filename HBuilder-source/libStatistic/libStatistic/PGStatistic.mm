#import "PGStatistic.h"
#import <UMAnalytics/MobClick.h>
#import <UMCommon/UMCommon.h>
#import <Foundation/Foundation.h>
#import "PDRCoreDefs.h"

@interface PGUmengStartUp : H5Server
@end

@implementation PGUmengStartUp

- (void)onCreate {
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *dict = [infoPlist objectForKey:@"umeng"];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        [MobClick setScenarioType:E_UM_NORMAL];
        NSString *appKey = [dict objectForKey:@"appkey"];
        if ( appKey ) {
//          UMConfigInstance.appKey = appKey;
            NSString *channel = [dict objectForKey:@"channel"];
            if ( [channel isKindOfClass:[NSString class]] ) {
//                UMConfigInstance.channelId = channel;
                [UMConfigure initWithAppkey:appKey channel:channel];
            }else{
                [UMConfigure initWithAppkey:appKey channel:nil];
            }
        } else {
//            UMConfigInstance.appKey = @"55b1b68ae0f55a9898002723";
//            UMConfigInstance.channelId = [NSBundle mainBundle].bundleIdentifier;
            [UMConfigure initWithAppkey:@"55b1b68ae0f55a9898002723" channel:[NSBundle mainBundle].bundleIdentifier];
        }
//        UMConfigInstance.ePolicy = BATCH;
        //[MobClick setBackgroundTaskEnabled:NO];
//        [MobClick startWithConfigure:UMConfigInstance];
    }
    
}

@end


@implementation PGStatistic

/**
 *------------------------------------------------------------------
 * @Summary:
 *    触发指定的统计事件，触发的事件必须要先在统计网站上注册事件ID
 * @Parameters:
 * 	 JS args [id, label]
 *   id：DOMString类型，必选参数，要触发的事件ID；
 *	label：DOMString类型，可选参数，要触发事件的标签；
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) eventTrig:(PGMethod*)command {
    if ( !command.arguments
        || ![command.arguments isKindOfClass:[NSArray class]] ) {
        return;
    }
    NSString *idArg = [command.arguments objectAtIndex:0];
    NSString *labelArg = [command.arguments objectAtIndex:1];
    NSString *evtID = nil;
    if ( [idArg isKindOfClass:[NSString class]] ) {
        evtID = idArg;
    }
    if ( evtID ) {
        if ( [labelArg isKindOfClass:[NSString class]] ) {
            [MobClick event:evtID label:labelArg];
        } else if ( [labelArg isKindOfClass:[NSDictionary class]] ) {
            [MobClick event:evtID attributes:(NSDictionary*)labelArg];
        } else {
            [MobClick event:evtID];
        }
    }
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *    开始指定的持续事件统计，当事件结束时调用eventEnd方法，，触发的事件必须要先在统计网站上注册事件ID
 * @Parameters:
 * 	 JS args [id, label]
 *   id：DOMString类型，必选参数，要触发的事件ID；
 *	label：DOMString类型，可选参数，要触发事件的标签；
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) eventStart:(PGMethod*)command {
    if ( !command.arguments
        || ![command.arguments isKindOfClass:[NSArray class]] ) {
        return;
    }
    NSString *idArg = [command.arguments objectAtIndex:0];
    NSString *labelArg = [command.arguments objectAtIndex:1];
    NSString *evtID = nil;
    NSString *evtLabel = nil;
    if ( [idArg isKindOfClass:[NSString class]] ) {
        evtID = idArg;
    }
    if ( [labelArg isKindOfClass:[NSString class]] ) {
        evtLabel = labelArg;
    }
    if ( evtID ) {
        [MobClick beginEvent:evtID label:evtLabel];
    }
   
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *    触发指定的统计事件，触发的事件必须要先在统计网站上注册事件ID
 * @Parameters:
 * 	 JS args [id, label]
 *   id：DOMString类型，必选参数，要触发的事件ID；
 *	label：DOMString类型，可选参数，要触发事件的标签；
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) eventEnd:(PGMethod*)command {
    if ( !command.arguments
        || ![command.arguments isKindOfClass:[NSArray class]] ) {
        return;
    }
    NSString *idArg = [command.arguments objectAtIndex:0];
    NSString *labelArg = [command.arguments objectAtIndex:1];
    NSString *evtID = nil;
    NSString *evtLabel = nil;
    if ( [idArg isKindOfClass:[NSString class]] ) {
        evtID = idArg;
    }
    if ( [labelArg isKindOfClass:[NSString class]] ) {
        evtLabel = labelArg;
    }
    if ( evtID ) {
        [MobClick endEvent:evtID label:evtLabel];
    }
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *   精确时长的持续事件统计，触发的事件必须要先在统计网站上注册事件ID。
 * @Parameters:
 * 	 JS args [id,duration,  label]
 *  id：DOMString类型，必选参数，要触发的事件ID；
 *	duration：Number类型，必选参数，要触发事件持续的时间，单位为ms
 *	label：DOMString类型，可选参数，要触发事件的标签；
 * @Returns:
 * @Remark:
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) eventDuration:(PGMethod*)command {
    NSString *idArg = [command.arguments objectAtIndex:0];
    NSNumber *durArg = [command.arguments objectAtIndex:1];
    NSString *labelArg = [command.arguments objectAtIndex:2];
    NSString *evtID = nil;
    int duration = 0;
    if ( [idArg isKindOfClass:[NSString class]] ) {
        evtID = idArg;
    }
    if ( [durArg isKindOfClass:[NSNumber class]] ) {
        duration = [durArg intValue];
    }

   // PDR_LOG_INFO(@"--umeng--eventDuration--evtiD--%@--duration=%d--label--evtlabel--%@--", evtID, duration, labelArg);
    if ( evtID ) {
        if ( [labelArg isKindOfClass:[NSString class]] ) {
            [MobClick event:evtID label:labelArg durations:duration];
        } else if ( [labelArg isKindOfClass:[NSDictionary class]] ) {
            [MobClick event:evtID attributes:(NSDictionary*)labelArg durations:duration];
        } else {
            [MobClick event:evtID durations:duration];
        }
    }
}

-(void)dealloc {
    [super dealloc];
}

@end
