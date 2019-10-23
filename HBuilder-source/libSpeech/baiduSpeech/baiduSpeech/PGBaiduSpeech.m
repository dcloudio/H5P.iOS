//
//  baiduSpeech.m
//  baiduSpeech
//
//  Created by EICAPITAN on 17/11/20.
//  Copyright © 2017年 EICAPITAN. All rights reserved.
//

#import "PGBaiduSpeech.h"
#import "DC_JSON.h"
#import "PGBaiduSplash.h"
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"
#import "BDSEventManager.h"

@interface PGBaiduSpeech ()<BDSClientASRDelegate>
@property(nonatomic, strong) BDSEventManager *asrEventManager;
@end

@implementation PGBaiduSpeech

- (void)startRecognize:(PGMethod*)commands{
    [super startRecognize:commands];
    [self resetOptions];
    NSArray *args = [commands arguments];
    NSString *cID = [args objectAtIndex:0];
    [self parseOptions:[args objectAtIndex:1]];
    
    NSString *API_KEY = nil;
    NSString *SECRET_KEY = nil;
    NSString *APP_ID = nil;
    NSDictionary *dict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"baiduspeech"];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        API_KEY = [dict objectForKey:@"API_KEY"];
        SECRET_KEY = [dict objectForKey:@"SECRET_KEY"];
        APP_ID = [dict objectForKey:@"APP_ID"];
    }
    
    if ( !API_KEY || ![API_KEY isKindOfClass:[NSString class]] ||
        !SECRET_KEY || ![SECRET_KEY isKindOfClass:[NSString class]] ||
        !APP_ID || ![APP_ID isKindOfClass:[NSString class]] ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:PGSpeechErrorNotAppid
                                                        withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorNotAppid]];
        [self.bridge toCallback:cID withReslut:[result toJSONString]];
        return;
    }
    NSRange rangeZH = [self.lang rangeOfString:@"zh-"];
    NSRange rangeEN = [self.lang rangeOfString:@"en-us"];
    [self.asrEventManager setParameter:@(EVoiceRecognitionRecordSampleRateAuto) forKey:BDS_ASR_SAMPLE_RATE];
    if (rangeZH.length) {
        [self.asrEventManager setParameter:@(EVoiceRecognitionLanguageChinese) forKey:BDS_ASR_LANGUAGE];
        if ([self.lang isEqualToString:@"zh-cantonese"]) {
            [self.asrEventManager setParameter:@(EVoiceRecognitionLanguageCantonese) forKey:BDS_ASR_LANGUAGE];
        }
    } else if(rangeEN.length) {
        [self.asrEventManager setParameter:@(EVoiceRecognitionLanguageEnglish) forKey:BDS_ASR_LANGUAGE];
    }
    if (self.recognizeContinue) {
        [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
    }
    if (self.punctuation) {
        // -- 开启标点输出 -----
        [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_DISABLE_PUNCTUATION];
        if (rangeZH.length) {
            // 普通话标点
            [self.asrEventManager setParameter:@"15372" forKey:BDS_ASR_PRODUCT_ID];
            if ([self.lang isEqualToString:@"zh-cantonese"]) {
                [self.asrEventManager setParameter:@"16372" forKey:BDS_ASR_PRODUCT_ID];
            }
        }else if(rangeEN.length) {
            // 英文标点
            [self.asrEventManager setParameter:@"1737" forKey:BDS_ASR_PRODUCT_ID];
        }
    }else {
        // -- 关闭标点输出 -----
        [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_DISABLE_PUNCTUATION];
    }
    
    [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
    [self.bridge sendEvent:@"start" withParams:nil];
    self.callBackID = [NSString stringWithString:cID];
    if (self.userInterface) {
        [PGBaiduSplash showWithBlock:^{
            [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
        }];
    }
    if (self.bridge.frameWillCloseBlock) {
        self.bridge.frameWillCloseBlock = nil;
    }
    __weak typeof(self) weakSelf = self;
    self.bridge.frameWillCloseBlock = ^(PDRCoreAppFrame *frame) {
        if (weakSelf) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf stop];
        }
    };
}

- (void)stopRecognize:(PGMethod*)commands {
    [super stopRecognize:commands];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                           messageToErrorObject:PGSpeechErrorUserStop withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorUserStop]];
    [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)]) {
        [self.delegate toError:[result toJSONString]];
    }
    [self stop];
}

- (void)stop {
    [PGBaiduSplash dismiss];
    [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
    [self resetOptions];
    self.callBackID = nil;
    self.hasPendingOperation = FALSE;
    self.asrEventManager = nil;
}

// 识别结束回调函数
- (void)resetOptions {
    [super resetOptions];
    self.engine = @"baidu";
    self.punctuation = TRUE;
}

#pragma mark - <BDSClientASRDelegate>

- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusStart: {
//            [self.bridge sendEvent:@"start" withParams:nil];
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: {
//            [self.bridge sendEvent:@"end" withParams:nil];
//            [PGBaiduSplash dismiss];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            if (aObj) {
                NSMutableArray *recognizeResult = [NSMutableArray array];
                NSDictionary *resultDic = (NSDictionary *)aObj;
                NSArray *resultArray = [resultDic objectForKey:@"results_recognition"];
                NSInteger count = [resultArray count];
                for ( int index = 0; index < self.nbest && index < count; index++) {
                    NSString *result = [resultArray objectAtIndex:index];
                    if ( result ) {
                        [recognizeResult addObject:result];
                    }
                }
                if ( [recognizeResult count] ) {
                    NSDictionary *dict = @{
                                           @"partialResult" : recognizeResult.firstObject
                                           };
                    [self.bridge sendEvent:@"recognizing" withParams:dict];
                    
                    [PGBaiduSplash resultVoiceText:recognizeResult.firstObject];
                }
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            if (aObj) {
                NSMutableArray *recognizeResult = [NSMutableArray array];
                NSDictionary *resultDic = (NSDictionary *)aObj;
                NSArray *resultArray = [resultDic objectForKey:@"results_recognition"];
                NSInteger count = [resultArray count];
                for ( int index = 0; index < self.nbest && index < count; index++) {
                    NSString *result = [resultArray objectAtIndex:index];
                    if ( result ) {
                        [recognizeResult addObject:result];
                    }
                }
                if ( [recognizeResult count] ) {
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                                 messageAsString:recognizeResult.firstObject];
                    [result setKeepCallback:YES];
                    [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
                    if(self.delegate && [self.delegate respondsToSelector:@selector(toResult:)]) {
                        [self.delegate toResult:resultArray];
                    }
                    NSDictionary *dict = @{
                                           @"result" : resultArray.firstObject,
                                           @"results" : resultArray
                                           };
                    [self.bridge sendEvent:@"recognition" withParams:dict];
                    [self.bridge sendEvent:@"success" withParams:recognizeResult.firstObject];
                } else  {
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                           messageToErrorObject:PGSpeechErrorOther withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorOther]];
                    [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
                    if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)]) {
                        [self.delegate toError:[result toJSONString]];
                    }
                }
            }
            if (!self.recognizeContinue) {
                [self stop];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            CGFloat volume = ((NSNumber *)aObj).floatValue / 100.00;
            [PGBaiduSplash resultVoiceVolume:((NSNumber *)aObj).integerValue];
            NSDictionary *dict = @{
                                   @"volume" : @(volume)
                                   };
            [self.bridge sendEvent:@"volumeChange" withParams:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            NSError *error = (NSError *)aObj;
            PGSpeechError speechError = PGSpeechErrorNO;
            switch (error.code) {
                case EVRClientErrorDomainRecord: { // 录音设备出错
                    speechError = PGSpeechErrorEngineNotSupport;
                    break;
                }
                case EVRClientErrorDomainVAD: { // 语音数据处理过程出错
                    speechError = PGSpeechErrorEngine;
                    break;
                }
                case EVRClientErrorDomainOnline: { // 在线识别引擎出错
                    speechError = PGSpeechErrorNotRecognize;
                    break;
                }
                case EVRClientErrorDomainLocalNetwork: { // 本地网络联接出错
                    speechError = PGSpeechErrorNet;
                    break;
                }
                case EVRClientErrorDomainHTTP: { // HTTP协议错误
                    speechError = PGSpeechErrorNotAppid;
                    break;
                }
                case EVRClientErrorDomainServer: { // 服务器返回错误
                    speechError = PGSpeechErrorNet;
                    break;
                }
                case EVRClientErrorDomainOffline: { // 离线引擎返回错误
                    speechError = PGSpeechErrorEngine;
                    break;
                }
                case EVRClientErrorDomainCommom: { // 其他错误
                    speechError = PGSpeechErrorOther;
                    break;
                }
                default:
                    speechError = PGSpeechErrorNO;
                    break;
            }
            if ( speechError > PGSpeechErrorNO ) {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                       messageToErrorObject:speechError withMessage:[self.bridge errorMsgWithCode:speechError]];
                [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
                if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)]) {
                    [self.delegate toError:[result toJSONString]];
                }
                NSDictionary *dict = @{
                                       @"code" : @(error.code),
                                       @"message" : error.description
                                       };
                [self.bridge sendEvent:@"error" withParams:dict];
                [self stop];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
//            NSLog(@"识别过程结束");
            if (!self.recognizeContinue) {
                [self.bridge sendEvent:@"end" withParams:nil];
                [self stop];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
//            NSLog(@"长语音结束状态");
            if (self.recognizeContinue) {
                [self.bridge sendEvent:@"end" withParams:nil];
                [self stop];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
//            NSLog(@"录音机关闭...");
            break;
        }
//        case EVoiceRecognitionClientWorkStatusCancel: {
//            NSLog(@"用户取消...");
//            break;
//        }
        default:
            
            break;
    }
}

#pragma mark - <懒加载>

- (BDSEventManager *)asrEventManager {
    if (!_asrEventManager) {
        NSString *API_KEY = nil;
        NSString *SECRET_KEY = nil;
        NSString *APP_ID = nil;
        NSDictionary *dict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"baiduspeech"];
        if ( [dict isKindOfClass:[NSDictionary class]] ) {
            API_KEY = [dict objectForKey:@"API_KEY"];
            SECRET_KEY = [dict objectForKey:@"SECRET_KEY"];
            APP_ID = [dict objectForKey:@"APP_ID"];
        }
        
        BDSEventManager *eventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
        // 设置语音识别代理
        [eventManager setDelegate:self];
        // 参数配置：在线身份验证
        [eventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
        //设置 APPID
        [eventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
        
        NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
        [eventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
        [eventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
        // ---- 开启语义理解 -----
//        [eventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
//        [eventManager setParameter:@"1536" forKey:BDS_ASR_PRODUCT_ID];
        self.asrEventManager = eventManager;
    }
    return _asrEventManager;
}

- (void)dealloc {
    
    NSLog(@"语音识别-%s",__func__);
}

@end
