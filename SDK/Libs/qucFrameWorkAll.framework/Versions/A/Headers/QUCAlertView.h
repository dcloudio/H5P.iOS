//
//  UCAlertView.h
//  UserCenterFramework
//
//  Created by Zhao Jiang on 12-9-4.
//  Copyright (c) 2012年 Zhao Jiang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class QUCTTTAttributedLabel;

typedef enum {
	QUCAlertViewPresentationStyleNone = 0,
	QUCAlertViewPresentationStylePop,
	QUCAlertViewPresentationStyleFade,
	
	QUCAlertViewPresentationStyleDefault = QUCAlertViewPresentationStylePop
} QUCAlertViewPresentationStyle;

typedef enum {
	QUCAlertViewDismissalStyleNone = 0,
	QUCAlertViewDismissalStyleZoomDown,
	QUCAlertViewDismissalStyleZoomOut,
	QUCAlertViewDismissalStyleFade,
	QUCAlertViewDismissalStyleTumble,
    
	QUCAlertViewDismissalStyleDefault = QUCAlertViewDismissalStyleFade
} QUCAlertViewDismissalStyle;

typedef void (^QUCAlertViewButtonBlock)();

@interface QUCAlertView : UIView
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) QUCTTTAttributedLabel *message;
@property (nonatomic, strong) UIButton *otherButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *destructiveButton;
@property (nonatomic, assign) BOOL isShow;

@property(nonatomic, assign) QUCAlertViewPresentationStyle presentationStyle;
@property(nonatomic, assign) QUCAlertViewDismissalStyle dismissalStyle;

- (id)initWithTitle:(NSString *)title message:(NSMutableAttributedString *)message ohterButton:(NSString *)otherButtonTitle cancelButton:(NSString *)cancelButtonTitle;

-(void)show;
-(void)dismiss;
@end
