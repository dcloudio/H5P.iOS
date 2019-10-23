
//
//  PDRCore.h
//  Pandora
//
//  Created by Mac Pro on 12-12-22.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PDRCoreDefs.h"

@interface PDRCoreAppDefalutLoadView : UIImageView {
    UIImage *_iPadLandscapeImg;
    UIImage *_iPadPortraitImg;
    UIImageView *_appIconImg;
    UILabel *_appNameLable;
}
- (void)setLoadingPage;
- (void)setStoryBoardLaunchScreen;
@end

@class PDRCoreAppWindow;
@class DCUAppBarView;
@class H5CoreAppSafearea;

@interface PDRCoreWindowManager : UIView
@property(nonatomic, readonly)UIGestureRecognizer *edgeGestureRecognizer;
@property(nonatomic, readonly)UIGestureRecognizer *touchEventRecognizer;
@property(nonatomic, readonly)DCUAppBarView *appBarView;
@property(nonatomic, retain)DCUAppBarView* appOutBarView;
@property(nonatomic, readonly)UIView *contentView;
- (void)bringAppWindowToFont:(PDRCoreAppWindow*)window;
- (void)addAppWindow:(PDRCoreAppWindow*)window;
- (void)removeAppWindow:(PDRCoreAppWindow*)window;
- (void)setBarVisble:(BOOL)visable;
- (BOOL)getBarVisble;

- (void)showLoadingPage:(UIView*)view forKey:(NSString*)key;
- (void)endLoadingPageForKey:(NSString*)key;

- (void)startLoadingPage;
- (void)endLoadingPage;
- (void)showIndicatorView;
- (void)hiddenIndicatorView;
- (void)showView:(UIView*)view;
- (void)closeView:(UIView*)view;
- (void)setParentView:(UIView*)pView;
- (void)makeHiddenNavBar;
- (void)tiggerDelayLayout;
//- (void)SetDebugRunMode:(BOOL)bDebug;

@end
