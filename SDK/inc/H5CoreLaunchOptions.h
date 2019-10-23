//
//  H5CoreCmd.h
//  libPDRCore
//
//  Created by DCloud on 15/10/22.
//  Copyright © 2015年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, H5CoreLaunchType) {
    H5CoreLaunchTypeDefalut = 0,
    H5CoreLaunchTypeOpenUrl = 1,
    H5CoreLaunchTypeShortcut = 2,
    H5CoreLaunchTypeCustorm = 3,
    H5CoreLaunchTypeApplinks = 4
};

@interface H5CoreLaunchOptions : NSObject
@property(nonatomic, assign)H5CoreLaunchType argumentType;
@property(nonatomic, assign)NSString *custromType;
@property(nonatomic, retain)id argument;
- (void)setApplinks:(NSUserActivity*)userActivity;
- (void)setShortcut:(UIApplicationShortcutItem*)shortcut;
- (void)setOpenUrl:(NSURL*)url;
- (void)setCustrom:(id)custorm launchType:(NSString*)type;
- (BOOL)handleLaunchOptions:(NSDictionary*)options;
- (NSString*)argumentType2String;
@end
