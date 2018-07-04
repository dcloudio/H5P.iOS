//
//  BDRecognizerViewDelegate.h
//  BDVoiceRecognitionClient
//
//  Created by baidu on 13-9-23.
//  Copyright (c) 2013年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDRecognizerViewController;

/**
 * @brief - 语音弹窗UI的委托接口
 */
@protocol BDRecognizerViewDelegate <NSObject>

/**
 * @brief 语音识别结果返回，搜索和输入模式结果返回的结构不相同
 *
 * @param aBDRecognizerView 弹窗UI
 * @param aResults 返回结果，原始Json结果
 */
- (void)onEndWithViews:(BDRecognizerViewController *)aBDRecognizerViewController withResult:(id)aResult;

@optional
/**
 * @brief 录音数据返回
 *
 * @param recordData 录音数据
 * @param sampleRate 采样率
 */
- (void)onRecordDataArrived:(NSData *)recordData sampleRate:(int)sampleRate;

/**
 * @brief 录音结束
 */
- (void)onRecordEnded;

/**
 * @brief 返回中间识别结果
 *
 * @param results: 原始Json结果
 */
- (void)onPartialResult:(id)result;

/**
 * @brief 发生错误
 *
 * @param errorClass: 错误类别 (TVoiceRecognitionClientErrorStatusClass)
 * @param errorCode: 错误码 (TVoiceRecognitionClientErrorStatus)
 * @param errDescription: 错误描述
 */
- (void)onError:(int)errClass errCode:(int)errCode errDescription:(NSString *)errDescription;

/**
 * @brief 提示语出现
 */
- (void)onTipsShow;

/**
 * @brief 开始录音
 */
- (void)onRecordStart;

/**
 * @brief 检测到用户开始说话
 */
- (void)onSpeakStart;

/**
 * @brief 检测到用户说话结束
 */
- (void)onSpeakFinish;

/**
 * @brief 识别结束
 */
- (void)onRecogFinish;

/**
 * @brief 用户点击重试
 */
- (void)onClickRetry;

/**
 * @brief 弹窗关闭
 */
- (void)onDialogClose;

@end

/**
 * @brief 语音输入弹窗按钮的委托接口，开发者不需要关心
 */
@protocol BDRecognizerDialogDelegate <NSObject>

@required
- (void)voiceRecognitionDialogHelp; // 出现帮助界面
- (void)voiceRecognitionDialogClosed; // 对话框关闭
- (void)voiceRecognitionDialogRetry; // 用户重试
- (void)voiceRecognitionDialogSpeekFinish; // 说完了
- (NSInteger)currentMeterLevel; // 得到当前音量

@end // BDRecognizerDialogDelegate
