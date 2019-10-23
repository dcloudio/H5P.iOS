//
//  QUCCheckBoxButton.h
//  App360Contacts
//
//  Created by Jiang Zhao on 12-7-9.
//  Copyright (c) 2012年 qihoo 360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QUCCheckBoxButton : UIControl {
}

@property (nonatomic, readonly, strong) UIImageView *imgvCheckBox;
@property (nonatomic, readonly, strong) UILabel *lblTitle;
@property (nonatomic, assign, setter = setCheck:) BOOL isChecked;

@end
