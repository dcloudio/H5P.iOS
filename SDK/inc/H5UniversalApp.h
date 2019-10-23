//
//  H5UniversalApp.h
//  libPDRCore
//
//  Created by DCloud on 2018/1/9.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PDRCoreDefs.h"
#import "H5CoreScreenEdgePan.h"

@class DC5PAppStartParams;
@class H5MultiDelegate;

typedef NS_ENUM(NSInteger, PDRCoreAppStatus) {
    PDRCoreAppStatusNoStarted = 0,
    PDRCoreAppStatusLoaded,
    PDRCoreAppStatusActive,
    PDRCoreAppStatusDeActive,
    PDRCoreAppStatusStop,
    PDRCoreAppStatusEnd
};

@protocol H5UniversalApp <NSObject>
@property (nonatomic, readonly)H5MultiDelegate *appDelegate;
@property (nonatomic, readonly)DC5PAppStartParams *appSetting;
@property (nonatomic, readonly)NSString *scheme;
@property (nonatomic, readonly)PDRCoreAppStatus appStatus;
@property (nonatomic, readonly)UIView *rootView;

@property(nonatomic, assign)NSInteger lastOrientation;
@property(nonatomic, assign)NSInteger orientationMask;

- (id)initWithSetting:(DC5PAppStartParams*)appSetting;
- (void)updateStartParams:(DC5PAppStartParams*)startParams;
- (void)restart;
- (void)restartWithOptions:(NSDictionary*)options;


- (void)stop;
- (void)resume;

- (int)start;
- (void)end;
- (void)activeWithType:(NSString*)actType;
- (void)deActive;
- (id)handleSysEvent:(PDRCoreSysEvent)evt withObject:(id)object;
- (void)handleCommand:(int)evtCode withParamer:(NSObject *)inP withResult:(NSObject **)result;

- (BOOL)isSupportTrimMemory;
- (BOOL)isAutoTerminateByRuntime;
- (BOOL)isSupportEndAnimation;

- (NSString*)getAppid;
- (NSString*)getAppName;
@end

@interface H5UniversalApp :NSObject<H5UniversalApp,H5CoreScreenEdgePanDelegate> {
    @protected
    PDRCoreAppStatus _appStatus;
}
+ (void)registerAppHandle:(Class)universalAppImp withScheme:(NSString*)scheme;
- (UIView*)rootView;
- (void)sendDelegateAppLoaded;
- (void)sendDelegateAppWillStartLoad;
- (void)sendDelegateAppStartFailed:(NSError*)error;
@end

@protocol H5UniversalAppDelegate <NSObject>
- (void)appWillStartLoad:(H5UniversalApp*)coreApp;
- (void)appDidFinishLoad:(H5UniversalApp*)coreApp;
- (void)app:(H5UniversalApp*)coreApp didStartFailed:(NSError*)error;
@end
