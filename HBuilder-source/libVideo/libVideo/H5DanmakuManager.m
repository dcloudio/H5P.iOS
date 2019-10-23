//
//  H5DanmakuManager.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "H5DanmakuManager.h"
#import "HJDanmakuView.h"
#import <UIKit/UIKit.h>

@interface DemoDanmakuCell : HJDanmakuCell

@end

@implementation DemoDanmakuCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.layer.borderWidth = 0;
}

@end


@interface DemoDanmakuModel : HJDanmakuModel

@property (nonatomic, assign) BOOL selfFlag;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor  *textColor;
@property (nonatomic, strong) UIFont   *textFont;
@end

@implementation DemoDanmakuModel

@end


@interface H5DanmakuManager() <HJDanmakuViewDateSource, HJDanmakuViewDelegate>
@property(nonatomic, weak)UIView *hostedView;
@property(nonatomic, strong)HJDanmakuView *danmakuView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat progressValue;
@end;




@implementation H5DanmakuManager

-(instancetype)initWithView:(UIView*)view {
    if ( self = [super init] ) {
        self.hostedView = view;
    }
    return self;
}

- (void)prepareDanmakus {
    HJDanmakuConfiguration *config = [[HJDanmakuConfiguration alloc] initWithDanmakuMode:HJDanmakuModeVideo];
    self.danmakuView = [[HJDanmakuView alloc] initWithFrame:self.hostedView.bounds configuration:config];
    self.danmakuView.dataSource = self;
    self.danmakuView.delegate = self;
    self.danmakuView.userInteractionEnabled = NO;
    [self.danmakuView registerClass:[DemoDanmakuCell class] forCellReuseIdentifier:@"cell"];
    self.danmakuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.hostedView addSubview:self.danmakuView];
    [self.danmakuView prepareDanmakus:nil];
}

- (void)play {
    if (self.danmakuView.isPrepared) {
        [self.danmakuView play];
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimeCount) userInfo:nil repeats:YES];
        }
    }
}

- (void)onTimeCount {
    self.progressValue += 0.1 / 120;
    if (self.progressValue > 120.0) {
        self.progressValue = 0;
    }
}

- (void)pause {
    [self.danmakuView stop];
}

- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color time:(float)time {
    DemoDanmakuModel *danmakuModel = [[DemoDanmakuModel alloc] initWithType:HJDanmakuTypeLR];
    danmakuModel.selfFlag = YES;
    danmakuModel.time = [self playTimeWithDanmakuView:self.danmakuView] + 0.5 +time;
    danmakuModel.text = sender;
    danmakuModel.textFont = [UIFont systemFontOfSize:20];
    danmakuModel.textColor = color;
    [self.danmakuView sendDanmaku:danmakuModel forceRender:YES];
}

- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color {
    [self sendDanmaku:sender withColor:color time:0];
}

- (void)destroy {
    [self.danmakuView stop];
}

#pragma mark - delegate

- (void)prepareCompletedWithDanmakuView:(HJDanmakuView *)danmakuView {
    [self.danmakuView play];
}
- (float)playTimeWithDanmakuView:(HJDanmakuView *)danmakuView {
    return self.progressValue * 120.0;
}
#pragma mark - dataSource
- (CGFloat)danmakuView:(HJDanmakuView *)danmakuView widthForDanmaku:(HJDanmakuModel *)danmaku {
    DemoDanmakuModel *model = (DemoDanmakuModel *)danmaku;
    return [model.text sizeWithAttributes:@{NSFontAttributeName: model.textFont}].width + 1.0f;
}

- (HJDanmakuCell *)danmakuView:(HJDanmakuView *)danmakuView cellForDanmaku:(HJDanmakuModel *)danmaku {
    DemoDanmakuModel *model = (DemoDanmakuModel *)danmaku;
    DemoDanmakuCell *cell = [danmakuView dequeueReusableCellWithIdentifier:@"cell"];
    if (model.selfFlag) {
        cell.zIndex = 30;
        cell.layer.borderColor = [UIColor redColor].CGColor;
    }
    cell.textLabel.font = model.textFont;
    cell.textLabel.textColor = model.textColor;
    cell.textLabel.text = model.text;
    return cell;
}

@end
