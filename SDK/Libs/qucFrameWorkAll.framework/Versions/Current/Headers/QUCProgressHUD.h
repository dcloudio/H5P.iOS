//
//  QUCProgressHUD.h
//
//  Copyright 2011-2014 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/QUCProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * const QUCProgressHudDidReceiveTouchEventNotification;
extern NSString * const QUCProgressHudDidTouchDownInsideNotification;
extern NSString * const QUCProgressHudWillDisappearNotification;
extern NSString * const QUCProgressHudDidDisappearNotification;
extern NSString * const QUCProgressHudWillAppearNotification;
extern NSString * const QUCProgressHudDidAppearNotification;

extern NSString * const QUCProgressHudStatusUserInfoKey;

typedef NS_ENUM(NSUInteger, QUCProgressHudMaskType) {
    QUCProgressHudMaskTypeNone = 1,  // allow user interactions while HUD is displayed
    QUCProgressHudMaskTypeClear,     // don't allow user interactions
    QUCProgressHudMaskTypeBlack,     // don't allow user interactions and dim the UI in the back of the HUD
    QUCProgressHudMaskTypeGradient   // don't allow user interactions and dim the UI with a a-la-alert-view background gradient
};

@interface QUCProgressHUD : UIView

#pragma mark - Customization

+ (void)setBackgroundColor:(UIColor*)color;                 // default is [UIColor whiteColor]
+ (void)setForegroundColor:(UIColor*)color;                 // default is [UIColor blackColor]
+ (void)setRingThickness:(CGFloat)width;                    // default is 4 pt
+ (void)setFont:(UIFont*)font;                              // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
+ (void)setInfoImage:(UIImage*)image;                       // default is the bundled info image provided by Freepik
+ (void)setSuccessImage:(UIImage*)image;                    // default is the bundled success image provided by Freepik
+ (void)setErrorImage:(UIImage*)image;                      // default is the bundled error image provided by Freepik
+ (void)setDefaultMaskType:(QUCProgressHudMaskType)maskType; // default is QUCProgressHudMaskTypeNone

#pragma mark - Show Methods

+ (void)show;
+ (void)showWithMaskType:(QUCProgressHudMaskType)maskType;
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString*)status maskType:(QUCProgressHudMaskType)maskType;
+ (void)showWithStatus:(NSString *)status durationAutoDismiss:(NSTimeInterval)duration;

+ (void)showProgress:(float)progress;
+ (void)showProgress:(float)progress maskType:(QUCProgressHudMaskType)maskType;
+ (void)showProgress:(float)progress status:(NSString*)status;
+ (void)showProgress:(float)progress status:(NSString*)status maskType:(QUCProgressHudMaskType)maskType;

+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

// stops the activity indicator, shows a glyph + status, and dismisses HUD a little bit later
+ (void)showInfoWithStatus:(NSString *)string;
+ (void)showInfoWithStatus:(NSString *)string maskType:(QUCProgressHudMaskType)maskType;

+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showSuccessWithStatus:(NSString*)string maskType:(QUCProgressHudMaskType)maskType;

+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showErrorWithStatus:(NSString *)string maskType:(QUCProgressHudMaskType)maskType;

// use 28x28 white pngs
+ (void)showImage:(UIImage*)image status:(NSString*)status;
+ (void)showImage:(UIImage*)image status:(NSString*)status maskType:(QUCProgressHudMaskType)maskType;

+ (void)setOffsetFromCenter:(UIOffset)offset;
+ (void)resetOffsetFromCenter;

+ (void)popActivity; // decrease activity count, if activity count == 0 the HUD is dismissed
+ (void)dismiss;

+ (BOOL)isVisible;

@end

