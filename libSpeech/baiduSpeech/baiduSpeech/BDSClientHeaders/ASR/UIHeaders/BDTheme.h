//  BDTheme.h
//  BDVoiceRecognitionClient
//
// Created by Baidu on 13-9-24.
// Copyright 2013 Baidu Inc. All rights reserved.
//

// 头文件
#import <Foundation/Foundation.h>

@interface BDTheme : NSObject <NSCoding>

@property (nonatomic, copy) NSString *name;

#pragma mark - 动画面板
@property (nonatomic) NSUInteger visualizerBackgroundColor;                 //背景颜色
@property (nonatomic) NSUInteger visualizerSquareBackgroundColor;           //方块默认颜色
@property (nonatomic) NSUInteger visualizerScanningLineGradientStartColor;  //扫描线渐变起始色
@property (nonatomic) NSUInteger visualizerScanningLineGradientEndColor;    //扫描线渐变结束色
@property (nonatomic) NSUInteger visualizerSquareGradientStartColor;        //方块渐变起始色
@property (nonatomic) NSUInteger visualizerSquareGradientEndColor;          //方块渐变结束色
@property (nonatomic) NSUInteger visualizerLogoLightColor;                  //logo默认颜色
@property (nonatomic) NSUInteger visualizerLogoDarkColor;                   //logo点亮颜色

#pragma mark - SDK UI
@property(nonatomic) NSUInteger recognizerViewBackgroundColor;  // 背景颜色
@property(nonatomic) NSUInteger dialogBackgroundColor;          // 弹窗背景色
@property(nonatomic) NSUInteger dialogErrorColor;               // 弹窗错误文案颜色
@property(nonatomic) NSUInteger dialogTitleAndResultColor;      // 提示文字和识别结果颜色
@property(nonatomic) NSUInteger dialogOtherButtonColor;         // 除重试按钮文字颜色
@property(nonatomic) NSUInteger dialogRetryButtonColor;         // 按钮文字颜色
@property(nonatomic) NSUInteger dialogRecognizingColor;         // 识别中按钮文字颜色
@property(nonatomic) NSUInteger dialogFinishButtonColor;        // 完成按钮文字颜色
@property(nonatomic) NSUInteger dialogBaiduFlagColor;           // 按钮文字颜色
@property(nonatomic) NSUInteger dialogConfirmedTitleColor;
@property(nonatomic) NSUInteger dialogInnerBorderColor;
@property(nonatomic) NSUInteger dialogOuterBorderColor;

+ (instancetype)defaultTheme;                   //默认主题
+ (instancetype)defaultFullScreenTheme;         //默认全屏主题
+ (instancetype)lightBlueTheme;                 //亮蓝主题
+ (instancetype)darkBlueTheme;                  //暗蓝主题
+ (instancetype)lightGreenTheme;                //亮绿主题
+ (instancetype)darkGreenTheme;                 //暗绿主题
+ (instancetype)lightOrangeTheme;               //亮橙主题
+ (instancetype)darkOrangeTheme;                //暗橙主题
+ (instancetype)lightRedTheme;                  //亮红主题
+ (instancetype)darkRedTheme;                   //暗红主题

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)type;

@end