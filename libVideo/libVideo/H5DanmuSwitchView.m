//
//  H5DanmuSwitchView.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/23.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "H5DanmuSwitchView.h"
#import "Masonry.h"
#import "PDRToolSystemEx.h"

@implementation H5DanmuSwitchView

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame] ) {
        self.textLabel = [UILabel new];
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.textLabel];
        self.textLabel.text = @"弹幕";
        self.textLabel.font = [UIFont systemFontOfSize:10];
        self.textLabel.layer.borderWidth = 1;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        [self.textLabel sizeToFit];
        self.textLabel.layer.cornerRadius = CGRectGetMidY(self.textLabel.bounds)+3;
        [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self.textLabel.bounds.size.width+20);
            make.height.equalTo(self.textLabel.bounds.size.height+6);
        }];
        [self addTarget:self action:@selector(clickSwitch) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if ( self.selected ) {
        self.textLabel.textColor = [UIColor colorWithRed:0.095 green:0.65 blue:0.043 alpha:1];
        self.textLabel.layer.borderColor = [UIColor colorWithRed:0.095 green:0.65 blue:0.043 alpha:1].CGColor;
    } else {
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    }
}

- (void)clickSwitch {
    self.selected = !self.selected;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end

@interface H5SwitchButton(){}
@property(nonatomic, strong)UIImageView *imageview;
@property(nonatomic, strong)UIImage *onImage;
@property(nonatomic, strong)UIImage *offImage;
@end

@implementation H5SwitchButton

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame] ) {
        self.on = NO;
        [self addTarget:self action:@selector(clickSwitch) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setOnImage:(UIImage *)onImage {
    _onImage = onImage;
    if ( self.isOn ) {
        self.imageview.image = onImage;
    }
}

- (void)setOffImage:(UIImage *)offImage {
    _offImage = offImage;
    if ( !self.isOn ) {
        self.imageview.image = offImage;
    }
}

- (UIImageView *)imageview {
    if ( !_imageview ) {
        _imageview = [UIImageView new];
        [self addSubview:_imageview];
        [_imageview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
    }
    return _imageview;
}

- (void)setOn:(BOOL)on {
    _on = on;
    if ( self.imageview ) {
        if ( self.isOn ) {
            self.imageview.image = self.onImage;
        } else {
            self.imageview.image = self.offImage;
        }
    }
}

- (void)clickSwitch {
    [self setOn:!self.on];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end
