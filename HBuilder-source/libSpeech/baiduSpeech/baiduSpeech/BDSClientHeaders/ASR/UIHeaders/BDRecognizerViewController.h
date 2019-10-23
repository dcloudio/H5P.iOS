//
//  BDRecognizerViewController.h
//  BDVoiceRecognitionClient
//
//  Created by Baidu on 13-9-25.
//  Copyright (c) 2013 Baidu Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BDRecognizerViewDelegate.h"
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDRecognizerViewParamsObject.h"
#import "BDTheme.h"

// 对话框的高度和宽度
extern const float VR_DIALOG_VIEW_WIDTH;
extern const float VR_DIALOG_VIEW_HEIGHT;

/**
 * @brief 语音识别弹窗视图控制类
 */
@interface BDRecognizerViewController : UIViewController<BDSClientASRDelegate, BDRecognizerDialogDelegate, AVAudioPlayerDelegate>

/**
 * @brief 创建弹窗实例
 * @param origin 控件左上角的坐标
 * @param theme 控件的主题，如果为nil，则为默认主题
 *
 * @return 弹窗实例
 */
- (id)initRecognizerViewControllerWithOrigin:(CGPoint)origin
                                       theme:(BDTheme *)theme
                            enableFullScreen:(BOOL)enableFullScreen
                                paramsObject:(BDRecognizerViewParamsObject *)paramsObject
                                    delegate:(id<BDRecognizerViewDelegate>)delegate;

/**
 * @brief 启动识别
 *
 */
- (void)startVoiceRecognition;

/**
 * @brief - 取消本次识别，并移除View
 */
- (void)cancelVoiceRecognition;

/**
 * @brief 屏幕旋转后调用设置识别弹出窗位置
 *
 */
- (void)changeFrameAfterOriented:(CGPoint)origin;

@end // BDRecognizerViewController
