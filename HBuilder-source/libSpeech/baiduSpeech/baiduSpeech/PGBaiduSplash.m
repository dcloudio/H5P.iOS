//
//  PGBaiduSplash.m
//  baiduSpeech
//
//  Created by 秦旭力 on 2018/9/21.
//  Copyright © 2018年 EICAPITAN. All rights reserved.
//

#import "PGBaiduSplash.h"
#import "PDRToolSystemEx.h"

#define BaiduSplashW 240
#define BaiduSplashH 160
#define TitleH 20
#define TitleFont 18
#define defaultTitle @"正在聆听"
#define voiceViewH 100

NSInteger _VoliState;
void (^_dismissBlock)(void);

@interface PGBaiduSplash ()
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation PGBaiduSplash

+ (void)showWithBlock:(void (^)(void))block {
    if (block) {
        _dismissBlock = block;
    }
    UIView *hazyView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    hazyView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    hazyView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [hazyView addGestureRecognizer:tapGes];
    PGBaiduSplash *splash = [self sharedView];
    [hazyView addSubview:splash];
    UIView *topView = [UIApplication sharedApplication].keyWindow;
    [topView addSubview:hazyView];
}

+ (void)dismiss {
    PGBaiduSplash *splash = [self sharedView];
    if (splash) {
        splash.titleLabel.text = defaultTitle;
        [splash.superview removeFromSuperview];
    }
    if (_dismissBlock) {
        _dismissBlock();
    }
    _dismissBlock = NULL;
}

+ (void)resultVoiceText:(NSString *)text {
    PGBaiduSplash *splash = [self sharedView];
    splash.titleLabel.text = text;
}

+ (void)resultVoiceVolume:(NSInteger)volume {
    if(volume < 10) {
        _VoliState = 2;
    } else if (volume > 80) {
        _VoliState = 7;
    } else {
        _VoliState = volume / 10;
    }
    [[PGBaiduSplash sharedView] setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(ctx) {
        CGContextSaveGState(ctx);
        UIImage* pImageMicroPhone = [UIImage imageNamed:@"PandoraApi.bundle/listening_microphone"];
        int xPos = (self.frame.size.width - (pImageMicroPhone.size.width))/2;
        int yPos = 50 + (100 - pImageMicroPhone.size.height) / 2;
        CGRect stImageRect = CGRectMake(xPos, yPos, pImageMicroPhone.size.width, pImageMicroPhone.size.height);
        [pImageMicroPhone drawInRect:stImageRect];
        
        xPos = CGRectGetMaxX(stImageRect) + 5;
        int voiWidth = pImageMicroPhone.size.width / 8;
        int stateBoY = CGRectGetMaxY(stImageRect);
        
        stateBoY -= voiWidth;
        
        for (int index = 1 ; index <= _VoliState ; index++) {
            [[UIColor colorWithCSS:@"#bfbfbf"] setFill];
            CGContextFillRect(ctx, CGRectMake(xPos, stateBoY, voiWidth * index, voiWidth));
            stateBoY -= (voiWidth * 2);
        }
    }
    CGContextRestoreGState(ctx);
}

#pragma mark - <单例实现>

+ (instancetype)sharedView {
    static dispatch_once_t onceToken;
    static PGBaiduSplash *_sharedView;
    dispatch_once(&onceToken, ^{
        _sharedView = [[PGBaiduSplash alloc] init];
        _sharedView.center = [UIApplication sharedApplication].keyWindow.center;
        _sharedView.bounds = CGRectMake(0, 0, BaiduSplashW, BaiduSplashH);
        _sharedView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        _sharedView.layer.cornerRadius = 10;
        _sharedView.layer.masksToBounds = YES;
    });
    return _sharedView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.titleLabel];
    }
    return self;
}

#pragma mark - <懒加载>

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        CGFloat LR_Margin = 20;
        CGFloat T_Margin = 30;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(LR_Margin, T_Margin, BaiduSplashW - (2 * LR_Margin), TitleH)];
        _titleLabel.font = [UIFont systemFontOfSize:TitleFont];
        _titleLabel.text = defaultTitle;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    }
    return _titleLabel;
}

@end
