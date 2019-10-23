//
//  H5DanmuSwitchView.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WXH5DanmuSwitchView : UIControl
@property(nonatomic, strong)UILabel *textLabel;
@end

@interface WXH5SwitchButton : UIControl
@property(nonatomic, strong)UIImageView *imageview;
@property(nonatomic, strong)UILabel *textLabel;
@property(nonatomic,getter=isOn) BOOL on;
- (void)setOnImage:(UIImage*)onImage;
- (void)setOffImage:(UIImage*)onImage;
@end
