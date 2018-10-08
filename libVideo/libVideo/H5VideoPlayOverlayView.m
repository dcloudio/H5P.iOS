//
//  H5VideoPlayOverlayView.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/22.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "H5VideoPlayOverlayView.h"
#import "Masonry.h"

#define kH5VideoPlayOverlayViewBGColor [UIColor black]

@interface H5VideoPlayOverlayView()
@property(nonatomic, strong)UILabel *infoLabel;
@property(nonatomic, strong)UIView *bgView;
@property(nonatomic, strong)UIButton *playButton;
@property(nonatomic, strong)UILabel *playDuration;
@property(nonatomic, assign)CGFloat cornerRadius;
@end

@implementation H5VideoPlayOverlayView

-(id)initWithFrame:(CGRect)frame {
    if ( self = [super initWithFrame:frame] ) {
        self.cornerRadius = 4.0f;
    }
    return self;
}

- (void)initProgressViewWithText:(NSString*)text {
    if ( !self.infoLabel ) {
        self.infoLabel = [UILabel new];
        self.infoLabel.textAlignment = NSTextAlignmentCenter;
        self.infoLabel.textColor = [UIColor whiteColor];
        self.infoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.infoLabel.layer.cornerRadius = self.cornerRadius;
        self.infoLabel.text = text;
        [self.infoLabel sizeToFit];
        [self addSubview:self.infoLabel];
        [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self.infoLabel.bounds.size.width+20);
            make.height.equalTo(self.infoLabel.bounds.size.height+20);
        }];
    }
    self.hidden = NO;
    self.infoLabel.hidden = NO;
    self.backgroundColor = [UIColor clearColor];
}

- (void)updateProgress:(NSString*)progress {
    self.infoLabel.text = progress;
}

- (void)hideProgressView {
    self.hidden = YES;
    self.infoLabel.hidden = YES;
}

- (void)initRepeatViewWithText:(NSString*)text {
    if ( !self.playButton ) {
        self.playButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
        [self.playButton setTintColor:[UIColor whiteColor]];
        [self.playButton setImage:[UIImage imageNamed:@"player_play"] forState:(UIControlStateNormal)];
        [self.playButton addTarget:self action:@selector(clickPlayButton) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:self.playButton];
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.height.equalTo(45);
        }];
    }
    if ( !self.playDuration ) {
        self.playDuration = [UILabel new];
        self.playDuration.textAlignment = NSTextAlignmentCenter;
        self.playDuration.textColor = [UIColor whiteColor];
        self.playDuration.backgroundColor = [UIColor clearColor];
        self.playDuration.font = [UIFont systemFontOfSize:12];
        self.playDuration.text = text;
        [self.playDuration sizeToFit];
        [self addSubview:self.playDuration];
        [self.playDuration mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.playButton);
            make.top.equalTo(self.playButton.mas_bottom).offset(-5);
        }];
    }
    self.hidden = NO;
    self.playButton.hidden = NO;
    self.playDuration.hidden = NO;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
}

- (void)hideRepeatView {
    self.hidden = YES;
    self.playButton.hidden = YES;
    self.playDuration.hidden = YES;
}

- (void)clickPlayButton {
    if ( self.delegate && [self.delegate respondsToSelector:@selector(onClickRepeatPlay)] ) {
        [self.delegate onClickRepeatPlay];
    }
}

@end
