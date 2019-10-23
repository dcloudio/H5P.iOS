//
//  DCADManager.h
//  libPDRCore
//
//  Created by X on 2018/2/6.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^DCADClickCompletionHandler)(NSDictionary*result);

@class DCADLaunch;
@class DCADManager;

@protocol DCADManagerDelgate<NSObject>
- (void)adManager:(DCADManager*)adManager adIsShow:(DCADLaunch*)ad;
- (void)adManager:(DCADManager*)adManager dispalyADViewController:(UIViewController*)viewController;
- (void)adManager:(DCADManager*)adManager needCloseADViewController:(UIViewController*)viewController;
@end

@interface DCADManager : NSObject
@property(nonatomic, strong)NSDictionary *adsSetting;
@property(nonatomic, weak)id<DCADManagerDelgate> delegate;
+ (DCADManager*)adManager;
- (UIViewController*)getADViewController;
- (BOOL)interruptCloseSplash;
- (void)destroy;
@end
