/*
 *------------------------------------------------------------------
 *  pandora/feature/PGSpeech.mm
 *  Description:
 *      JS log Native对象基类实现
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2013-01-11  创建文件
 *------------------------------------------------------------------
 */
#import "PGIFLYSpeech.h"
#import "PDRCore.h"
#import "PDRCorePrivate.h"
#import <iflyMSC/IFlySpeechRecognizer.h>

// 控件的位置
#define H_CONTROL_ORIGIN CGPointMake(20, 70)
// 此 appid 为您所申请,请勿随意修改
#define APPID @"5199ecad"
// 此 appid 为您所申请,请勿随意修改
#define ENGINE_URL @"http://dev.voicecloud.cn:1028/index.htm"

@implementation PGIFLYSpeech
static dispatch_once_t onceToken;
//1.属性不支持
//2.错误吗
- (void)startRecognize:(PGMethod*)commands {
    NSArray *args = [commands arguments];
    NSString *cID = [args objectAtIndex:0];
    [self resetOptions];
    [self parseOptions:[args objectAtIndex:1]];

    if ( self.hasPendingOperation ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:PGSpeechErrorMicOpenFail
                                                        withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorMicOpenFail]];
        [self.bridge toCallback:cID withReslut:[result toJSONString]];
        return;
    }
    
    if ( !_iFlyRecognizeControl ) {
        NSString *appid = nil;
        NSDictionary *dict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"iFly"];
        if ( [dict isKindOfClass:[NSDictionary class]] ) {
            appid = [dict objectForKey:@"appid"];
        }
        if ( !appid || ![appid isKindOfClass:[NSString class]]) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                   messageToErrorObject:PGSpeechErrorNotAppid
                                                            withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorNotAppid]];
            [self.bridge toCallback:cID withReslut:[result toJSONString]];
            return;
        }

        dispatch_once(&onceToken, ^{
            NSMutableString* initParam = [NSMutableString stringWithFormat:@"appid=%@", appid];
            [IFlySpeechUtility createUtility:initParam];
        });
        
        _iFlyRecognizeControl = [[IFlyRecognizerView alloc] initWithCenter:[self controlPosition]];
        [_iFlyRecognizeControl setParameter: @"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        [_iFlyRecognizeControl setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        [_iFlyRecognizeControl setParameter:self.punctuation?@"1":@"0" forKey:[IFlySpeechConstant ASR_PTT]];
        if ([self.lang containsString:@"zh-"]) {
            [_iFlyRecognizeControl setParameter:@"zh_cn" forKey:[IFlySpeechConstant LANGUAGE]];
            if ([self.lang isEqualToString:@"zh-cantonese"]) {
                [_iFlyRecognizeControl setParameter:@"cantonese" forKey:[IFlySpeechConstant ACCENT]];
            }else if ([self.lang isEqualToString:@"zh-henanese" ]){
                [_iFlyRecognizeControl setParameter:@"henanese" forKey:[IFlySpeechConstant ACCENT]];
            }
        }
        else if([self.lang containsString:@"en-us"]){
            [_iFlyRecognizeControl setParameter:@"en_us" forKey:[IFlySpeechConstant LANGUAGE]];
        }
    }
    
    
    self.callBackID = cID;
    _iFlyRecognizeControl.delegate = self;
    if ( [PDRCore Instance].settings.debug ) {
        //[_iFlyRecognizeControl setShowLog:YES];
    }
    [_iFlyRecognizeControl start];
    self.hasPendingOperation = TRUE;
}

- (void)stopRecognize:(PGMethod*)commands {
    if ( self.hasPendingOperation ) {
        if ( _iFlyRecognizeControl ) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                   messageToErrorObject:PGSpeechErrorUserStop withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorUserStop]];
            [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                [self.delegate toError:[result toJSONString]];

        }
        [_iFlyRecognizeControl cancel];
        [_iFlyRecognizeControl setDelegate:nil];
        self.hasPendingOperation = FALSE;
    }
}

- (CGPoint)controlPosition {
    CGRect rect = [[UIScreen mainScreen] applicationFrame];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( UIInterfaceOrientationLandscapeLeft == orientation
        || UIInterfaceOrientationLandscapeRight == orientation )
    {
       // return CGPointMake(CGRectGetMidY(rect), CGRectGetMidX(rect));
    }
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

// 识别结束回调函数
- (void)resetOptions {
    [super resetOptions];
    self.service = ENGINE_URL;
    self.engine = @"iFly";
    self.lang = @"zh-cn";
    self.punctuation = TRUE;
}


- (void)stop {
    _iFlyRecognizeControl.delegate = nil;
    if ( self.hasPendingOperation ) {
        if ( _iFlyRecognizeControl ) {
            [_iFlyRecognizeControl cancel];
        }
    }
    [self resetOptions];
    self.callBackID = nil;
    self.hasPendingOperation = FALSE;
    if (_iFlyRecognizeControl) {
        [_iFlyRecognizeControl release];
        _iFlyRecognizeControl = nil;        
    }
}

- (void)toResult:(NSArray*)resultArray {
    NSMutableArray *recognizeResult = [NSMutableArray array];
    NSInteger count = [resultArray count];
    for ( int index = 0; index < self.nbest && index < count; index++) {
        NSDictionary *dic = [resultArray objectAtIndex:index];
        NSMutableString *result = [[NSMutableString alloc] init];
        for (NSString *key in dic) {
            [result appendFormat:@"%@",key];
        }
        if ( result ) {
            [recognizeResult addObject:result];
        }
    }
    
    if ( [recognizeResult count] ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                     messageAsArray:recognizeResult];
        [result setKeepCallback:YES];
        [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
        if(self.delegate && [self.delegate respondsToSelector:@selector(toResult::)])
            [self.delegate toResult:recognizeResult];

    } else  {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                              messageToErrorObject:PGSpeechErrorOther withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorOther]];
        [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
        if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
            [self.delegate toError:[result toJSONString]];
    }
}

// 识别结果回调函数
- (void)onError: (IFlySpeechError *) error {
    PGSpeechError speechError = PGSpeechErrorNO;
    switch (error.errorCode) {
        case 0:
            speechError = PGSpeechErrorNO;
            break;
        case 10108:
            speechError = PGSpeechErrorEngineBadParam;
            break;
        case 10214:
        case 101:
            speechError = PGSpeechErrorNet;
            break;
        default:
            speechError = PGSpeechErrorOther;
            break;
    }
    if ( speechError > PGSpeechErrorNO ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:speechError withMessage:[self.bridge errorMsgWithCode:speechError]];
        [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
        if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
            [self.delegate toError:[result toJSONString]];
    }
    [self stop];
    self.hasPendingOperation = FALSE;
}

- (void)onResult:(NSArray *)resultArray isLast:(BOOL) isLast {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *recognizeResult = [NSMutableArray array];
        NSInteger count = [resultArray count];
        for ( int index = 0; index < self.nbest && index < count; index++) {
            NSDictionary *dic = [resultArray objectAtIndex:index];
            NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
            for (NSString *key in dic) {
                [result appendFormat:@"%@",key];
            }
            if ( result ) {
                [recognizeResult addObject:result];
            }
        }
        
        if ( [recognizeResult count] ) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                                         messageAsArray:recognizeResult];
            [result setKeepCallback:!isLast];
            [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
            if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                [self.delegate toResult:recognizeResult];

        } else  {
            if (!isLast) {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                       messageToErrorObject:PGSpeechErrorOther withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorOther]];
                [self.bridge toCallback:self.callBackID withReslut:[result toJSONString]];
                if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                    [self.delegate toError:[result toJSONString]];
            }
        }
    });
   // [self performSelectorOnMainThread:@selector(toResult:) withObject:resultArray waitUntilDone:NO];
}

- (void)onResult:(IFlyRecognizerView *)iFlyRecognizeControl theResult:(NSArray *)resultArray {
    [self performSelectorOnMainThread:@selector(toResult:) withObject:resultArray waitUntilDone:NO];
}

#pragma mark - listener without window
- (void)startRecognizeWithOutWindow{
    
    if(!_iFlySpeechRecognizer)
    {
        NSString *appid = nil;
        NSDictionary *dict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"iFly"];
        if ( [dict isKindOfClass:[NSDictionary class]] ) {
            appid = [dict objectForKey:@"appid"];
            
        }
        if ( !appid || ![appid isKindOfClass:[NSString class]]) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                   messageToErrorObject:PGSpeechErrorNotAppid
                                                            withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorNotAppid]];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                [self.delegate toError:[result toJSONString]];
            
        }
        
        dispatch_once(&onceToken, ^{
            NSMutableString* initParam = [NSMutableString stringWithFormat:@"appid=%@", appid];
            [IFlySpeechUtility createUtility:initParam];
        });
        
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        [_iFlySpeechRecognizer setParameter: @"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        [_iFlySpeechRecognizer setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        [_iFlySpeechRecognizer setParameter:self.punctuation?@"1":@"0" forKey:[IFlySpeechConstant ASR_PTT]];
        if ([self.lang containsString:@"zh-"]) {
            [_iFlySpeechRecognizer setParameter:@"zh_cn" forKey:[IFlySpeechConstant LANGUAGE]];
            if ([self.lang isEqualToString:@"zh-cantonese"]) {
                [_iFlySpeechRecognizer setParameter:@"cantonese" forKey:[IFlySpeechConstant ACCENT]];
            }else if ([self.lang isEqualToString:@"zh-henanese" ]){
                [_iFlySpeechRecognizer setParameter:@"henanese" forKey:[IFlySpeechConstant ACCENT]];
            }
        }
        else if([self.lang containsString:@"en-us"]){
            [_iFlySpeechRecognizer setParameter:@"en_us" forKey:[IFlySpeechConstant LANGUAGE]];
        }
        _iFlySpeechRecognizer.delegate = self;
        self.hasPendingOperation = YES;
        [_iFlySpeechRecognizer startListening];
    }
    
}

- (void)cancelRecognizeWithOutWindow
{
    if(self.hasPendingOperation)
    {
        [_iFlySpeechRecognizer stopListening];
        _iFlySpeechRecognizer.delegate = nil;
        _iFlySpeechRecognizer = nil;
        self.hasPendingOperation = NO;
    }
}

- (void)stopRecognizeWithoutWindow
{
    if(self.hasPendingOperation)
    {
        [_iFlySpeechRecognizer stopListening];
    }
}


- (void) onResults:(NSArray *) results isLast:(BOOL)isLast{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *recognizeResult = [NSMutableArray array];
        NSInteger count = [results count];
        for ( int index = 0; index < count; index++) {
            NSDictionary *dic = [results objectAtIndex:index];
            NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
            for (NSString *key in dic) {
                [result appendFormat:@"%@",key];
            }
            if ( result ) {
                [recognizeResult addObject:result];
            }
        }
        
        if ( [recognizeResult count] ) {
            if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                [self.delegate toResult:recognizeResult];
            
        } else  {
            if (!isLast) {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                       messageToErrorObject:PGSpeechErrorOther withMessage:[self.bridge errorMsgWithCode:PGSpeechErrorOther]];
                if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                    [self.delegate toError:[result toJSONString]];
            }
            else{
                if(self.delegate && [self.delegate respondsToSelector:@selector(toError:)])
                    [self.delegate toResult:recognizeResult];
            }
        }
    });
}




- (void)dealloc {
    [self stop];
    [_iFlyRecognizeControl removeFromSuperview];
    [_iFlyRecognizeControl release];
    _iFlyRecognizeControl = nil;
    [super dealloc];
}

@end
