//
//  PGNativeNavigationbar.h
//  libNativeObj
//
//  Created by EICAPITAN on 17/1/20.
//  Copyright © 2017年 DCloud. All rights reserved.
//

#import "PGNativeView.h"
#import "PGNativeInputSearchView.h"
typedef enum {
    PGNativeNavigationbarStyleNormal,
    PGNativeNavigationbarStyleTransparent,
    PGNativeNavigationbarStyleFloat
}PGNativeNavigationbarStyle;

@protocol PDRCoreAppFrameLoadDelegate;

@interface PGNativeNavigationbar : PGNativeView<PDRCoreAppFrameLoadDelegate,PGNativeInputSearchViewProtocol>

@property(nonatomic, assign)PGNativeNavigationbarStyle barStyle;
@property(nonatomic, assign)CGFloat coverage;

//- (void)updateParentStatusBarColor;
- (void)setTitle:(NSString*)title;
- (NSString*)getTitle;
- (void)setAbsoluteStyleTransformation:(CGFloat)progress;
- (void)updateCoverage:(CGFloat)straff;
-(void)setTitleNViewButtonBadge:(NSArray*)arr;
-(void)removeTitleNViewButtonBadge:(NSArray*)arr;
-(void)showTitleNViewButtonRedDot:(NSArray*)arr;
-(void)hideTitleNViewButtonRedDot:(NSArray*)arr;
-(void)setTitleNViewButtonStyle:(NSArray*)arr;

-(void)setTitleNViewSearchInputFocus:(NSArray*)arr;
-(void)setTitleNViewSearchInputText:(NSArray*)arr;
-(NSString*)getTitleNViewSearchInputText:(NSArray*)arr;
@end
