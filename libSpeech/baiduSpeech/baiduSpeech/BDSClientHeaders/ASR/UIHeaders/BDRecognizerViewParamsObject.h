//
//  BDRecognizerViewParamsObject.h
//  BDVoiceRecognitionClient
//
//  Created by Baidu on 13-9-25.
//  Copyright (c) 2013年 Baidu, Inc. All rights reserved.
//

// 头文件
#import <Foundation/Foundation.h>

// 枚举 - 弹窗中连续上屏效果开关
typedef enum
{
    BDRecognizerResultShowModeNotShow = 0,          // 不显示结果
    BDRecognizerResultShowModeWholeShow,            // 仅显示最终结果
    BDRecognizerResultShowModeContinuousShow,       // 提供连续上屏效果（默认）
} TBDRecognizerResultShowMode;

// @brief - 语音识别弹窗参数配置类
@interface BDRecognizerViewParamsObject : NSObject

@property (nonatomic, copy) NSString *tipsTitle; // 提示语标题
@property (nonatomic, copy) NSArray *tipsList; // 提示语列表
@property (nonatomic, assign) NSTimeInterval waitTime2ShowTip; // 等待显示提示语的时间
@property (nonatomic, assign) TBDRecognizerResultShowMode resultShowMode;   // 显示效果
@property (nonatomic, assign) BOOL isShowTipsOnStart; // 是否在对话框启动后展示引导提示，而不启动识别，默认关闭，若开启，请确认设置提示语列表
@property (nonatomic, assign) BOOL isShowTipAfterSilence; // 引擎启动后一段时间(waitTime2ShowTip)没检测到语音，是否在动效下方随机出现一条提示语。如果配置了提示语列表，则默认开启
@property (nonatomic, assign) BOOL isShowHelpButtonWhenSilence; // 未检测到语音异常时，将“取消”按钮替换成帮助按钮。在配置了提示语列表后，默认开启
@property (nonatomic, assign) BOOL isHidePleaseSpeakSection; // 隐藏“请说话”页
@property (nonatomic, assign) BOOL disableCarousel; // 停用提示语轮播

@end
