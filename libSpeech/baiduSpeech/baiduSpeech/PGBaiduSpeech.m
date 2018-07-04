//
//  baiduSpeech.m
//  baiduSpeech
//
//  Created by EICAPITAN on 17/11/20.
//  Copyright © 2017年 EICAPITAN. All rights reserved.
//

#import "PGBaiduSpeech.h"
#import "BDRecognizerViewController.h"
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"


@interface PGBaiduSpeech ()<BDRecognizerViewDelegate>
{
    NSString* voiceResult;
}
#if !TARGET_IPHONE_SIMULATOR
@property(nonatomic, retain)BDRecognizerViewController* controller;
@property(nonatomic, retain)BDSEventManager* asrEventManager;
#endif

@end


@implementation PGBaiduSpeech

- (void)startRecognize:(PGMethod*)commands{
    NSArray *args = [commands arguments];
    NSString *cID = [args objectAtIndex:0];
    [self parseOptions:[args objectAtIndex:1]];
    
#if !TARGET_IPHONE_SIMULATOR
    if(self.asrEventManager == nil){
        if ( self.hasPendingOperation ) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                   messageToErrorObject:PGSpeechErrorMicOpenFail
                                                            withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorMicOpenFail]];
            [self.bridge toCallback:cID withReslut:[result toJSONString]];
            return;
        }
        if(!_asrEventManager){
            NSString *appid = nil;
            NSString *appkey = nil;
            NSString *appSert = nil;
            NSDictionary *dict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"baiduspeech"];
            if ( [dict isKindOfClass:[NSDictionary class]] ) {
                appid = [dict objectForKey:@"appid"];
                appkey = [dict objectForKey:@"appkey"];
                appSert = [dict objectForKey:@"secretkey"];
            }
            
            if ( !appid || ![appid isKindOfClass:[NSString class]]) {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                       messageToErrorObject:PGSpeechErrorNotAppid
                                                                withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorNotAppid]];
                [self.bridge toCallback:cID withReslut:[result toJSONString]];
                return;
            }
            
            self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
            // 设置语音识别代理
            [self.asrEventManager setDelegate:self];
            // 参数配置：在线身份验证
            [self.asrEventManager setParameter:@[appkey, appSert] forKey:BDS_ASR_API_SECRET_KEYS];
            //设置 APPID
            [self.asrEventManager setParameter:appid forKey:BDS_ASR_OFFLINE_APP_CODE];
            
            NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
            [self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
            [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
            
        }
        
        NSRange rangeZH = [self.lang rangeOfString:@"zh-"];
        NSRange rangeEN = [self.lang rangeOfString:@"en-us"];
        if (rangeZH.length) {
            [self.asrEventManager setParameter:@(EVoiceRecognitionLanguageChinese) forKey:BDS_ASR_LANGUAGE];
            if ([self.lang isEqualToString:@"zh-cantonese"]) {
                [self.asrEventManager setParameter:@(EVoiceRecognitionLanguageCantonese) forKey:BDS_ASR_LANGUAGE];
            }
        }
        else if(rangeEN.length){
            [self.asrEventManager setParameter:@(EVoiceRecognitionLanguageEnglish) forKey:BDS_ASR_LANGUAGE];
        }
    }
    
    if(!_controller && _asrEventManager){
        BDRecognizerViewParamsObject *paramsObject = [[BDRecognizerViewParamsObject alloc] init];
        paramsObject.isShowTipAfterSilence = YES;
        paramsObject.isShowHelpButtonWhenSilence = NO;
        paramsObject.isHidePleaseSpeakSection = YES;
        paramsObject.disableCarousel = YES;
        
        _controller = [[BDRecognizerViewController alloc]
                       initRecognizerViewControllerWithOrigin:CGPointMake(9, 128)
                       theme:[BDTheme darkGreenTheme]
                       enableFullScreen:YES paramsObject:paramsObject
                       delegate:self];
        
    }
    
    if(_controller){
        self.callBackID = [NSString stringWithString:cID];
        [_controller startVoiceRecognition];
    }
    
#endif
}



- (void)stopRecognize:(PGMethod*)commands {
    
#if !TARGET_IPHONE_SIMULATOR
    if(self.hasPendingOperation){
        if ( _controller ) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                   messageToErrorObject:PGSpeechErrorUserStop withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorUserStop]];
            [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                [self.delegate toError:[result toJSONString]];
        }
        
        [_controller cancelVoiceRecognition];
        self.hasPendingOperation = FALSE;
    }
#endif
}

/*
 * 语音识别结束
 */
- (void)onRecogFinish{
#if !TARGET_IPHONE_SIMULATOR
    if(_controller)
        [_controller cancelVoiceRecognition];
    
    if(voiceResult && self.callBackID){
        if(self.callBackID){
            dispatch_async(dispatch_get_main_queue(), ^{
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                            messageAsString:voiceResult];
                [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
            });
        }
    }
#endif
}

/*
 接收到中间结果
 */
- (void)onPartialResult:(id)result{
    if(result && [result isKindOfClass:[NSString class]]){
        if(voiceResult)
            [voiceResult release];
        
        voiceResult = [[NSString alloc] initWithString:result];
    }
}

/*
 * 语音识别出错
 */
- (void)onError:(int)errClass errCode:(int)errCode errDescription:(NSString *)errDescription{
    
    {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:errCode withMessage:errDescription];
        
        [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
        if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
            [self.delegate toError:[result toJSONString]];
    }
    
    [self stop];
    self.hasPendingOperation = FALSE;
}


/**
 * @brief 弹窗关闭
 */
- (void)onDialogClose{
#if !TARGET_IPHONE_SIMULATOR
    if(_controller){
        [_controller release];
    }
#endif
}

// 识别结束回调函数
- (void)resetOptions {
    [super resetOptions];
    self.engine = @"baidu";
    self.lang = @"zh-cn";
    self.punctuation = TRUE;
}

/**
 * @brief 弹窗关闭
 */
- (void)stop {
#if !TARGET_IPHONE_SIMULATOR
    if ( self.hasPendingOperation ) {
        [_controller cancelVoiceRecognition];
    }
    
    [self resetOptions];
    self.callBackID = nil;
    self.hasPendingOperation = FALSE;
    if (_controller) {
        [_controller cancelVoiceRecognition];
    }
#endif
}

- (void)dealloc{
    
    [super dealloc];
}



@end
