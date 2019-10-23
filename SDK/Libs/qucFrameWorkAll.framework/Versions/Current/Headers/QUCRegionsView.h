//
//  QUCRegionsView.h
//  qucsdk
//
//  Created by huangxianshuai on 15/5/25.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QUCLabel.h"

@interface QUCRegionsView : UIView

@property (nonatomic, strong) UIButton *backgroundButton;// to the action
@property (nonatomic, strong) QUCLabel *titleLabel;// left label
@property (nonatomic, strong) QUCLabel *regionLabel;// right label
@property (nonatomic, strong) UIImageView *arrowImageView;// right arrow

@end
