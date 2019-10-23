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

#import "PGSpeech.h"
#import <Foundation/Foundation.h>
#import "PDRCoreFeature.h"
#import "PDRCoreApp.h"

@implementation PGSpeechImp

@synthesize bridge;
@synthesize hasPendingOperation;
@synthesize callBackID;
@synthesize engine;
//字符串类型，可选参数，语音识别引擎服务器地址，
//可使用url地址或ip地址，如service:192.168.1.99指定定制的语音识别引擎服务器。
//默认值为浏览器内置服务器地址。
@synthesize service;
//数字类型，可选参数，语音识别超时时间，单位为ms，
//如timeout:60000。默认值为10s。
@synthesize timeout;
//字符串类型，可选用于定义语音识别引擎的语言，
//其取值需符合W3C的HYPERLINK "http://www.w3.org/TR/html401/struct/dirlang.html" \l "
//h-8.1.1" Language codes规范。默认值为浏览器的默认语言。
@synthesize lang;
//布尔类型，可选参数，指定语音识别是否采用持续模式，
//设置为true表示语音引擎不会根据语音输入自动结束，
//识别到文本内容将多次调用successCallback函数返回
//，如果需要结束语音识别则必须调用stopRecognize接口。默认值为false。
@synthesize recognizeContinue;
//布尔类型，可选参数，用于指定识别结果识别包括多候选结果。
//如nbest:3，识别返回3个候选结果。默认值为1。
@synthesize nbest;
//布尔类型，可选弄参数，用于指定识别时是否显示用户界面，
//设置为true表示显示浏览器内置语音识别界面；
//设置为false表示不显示浏览器内置语音识别界面。默认值为true。
@synthesize userInterface;
//布尔类型，可选弄参数，用于指定识别结果中是否包含标点符号，
//设置为true识别结果中包含标点符号
//设置为false识别结果中不包含标点符号
@synthesize punctuation;

- (void)startRecognize:(PGMethod*)commands {
}

- (void)stopRecognize:(PGMethod*)commands {
}

- (void)startRecognizeWithOutWindow{
}
- (void)stopRecognizeWithoutWindow{
}
- (void)cancelRecognizeWithOutWindow{
}



- (void)parseOptions:(NSDictionary*)dict {
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        NSString *value = [dict objectForKey:@"engine"];
        if ([value isKindOfClass:[NSString class]] ) {
            self.engine = value;
        }
        value = nil;
        
        value = [dict objectForKey:@"service"];
        if ( [value isKindOfClass:[NSString class]] ) {
            self.service = value;
        }
        value = nil;
        
        value = [dict objectForKey:@"timeout"];
        if ( [value isKindOfClass:[NSString class]]
            || [value isKindOfClass:[NSNumber class]]) {
            self.timeout = [value integerValue];
        }
        value = nil;
        
        value = [dict objectForKey:@"lang"];
        if ( [value isKindOfClass:[NSString class]] ) {
            self.lang = value;
        }
        value = nil;
        
        value = [dict objectForKey:@"continue"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            self.recognizeContinue = [value boolValue];
        }
        value = nil;
        
        value = [dict objectForKey:@"nbest"];
        if ( [value isKindOfClass:[NSString class]]
            || [value isKindOfClass:[NSNumber class]]) {
            self.nbest = [value integerValue];
        }
        value = nil;
        
        value = [dict objectForKey:@"userInterface"];
        if ( [value isKindOfClass:[NSString class]]
            || [value isKindOfClass:[NSNumber class]]) {
            self.userInterface = [value boolValue];
        }
        
        value = nil;
        value = [dict objectForKey:@"punctuation"];
        if ([value isKindOfClass:[NSString class]]
            || [value isKindOfClass:[NSNumber class]]) {
            self.punctuation = [value boolValue];
        }
    }
}

- (void)resetOptions {
    self.userInterface = TRUE;
    self.nbest = 1;
    self.recognizeContinue = FALSE;
    self.lang = @"zh-cn";
    self.timeout = 10*1000;
    self.service = nil;
    self.engine = @"iFly";
    self.punctuation = YES;
}

- (void)dealloc {
    self.service = nil;
    self.engine = @"iFly";
    self.callBackID = nil;
}

@end

@interface PGSpeech ()
@property (nonatomic, strong) PGSpeechImp *speechEngine;
@property (nonatomic, strong) NSMutableDictionary *recognizerEvtObservers;
@end

@implementation PGSpeech

- (NSDictionary*)getSupportEngines {
    return [self.appContext.featureList getPuginExtend:@"Speech"];
}

//- (PGSpeechImp*)getEngine:(NSString*)aEngine {
//    if (!self.speechEngine) {
//        NSDictionary *dict = [self getSupportEngines];
//        NSString *className = [dict objectForKey:aEngine];
//        if ( className ) {
//            id imp = [[NSClassFromString(className) alloc] init];
//            self.speechEngine = imp;
//        }
//    }
//    return self.speechEngine;
//}
- (PGSpeechImp*)getEngine:(NSString*)aEngine {
    NSDictionary *dict = [self getSupportEngines];
    NSString *className = [dict objectForKey:aEngine];
    if ( className ) {
        id imp = [[NSClassFromString(className) alloc] init];
        return imp;
    }
    return nil;
}

- (void)startRecognize:(PGMethod*)command {
    NSArray *args = [command arguments];
    NSString *cID = [args objectAtIndex:0];
    NSString *curEngine = nil;
   
    NSDictionary *dict = [args objectAtIndex:1];
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        NSString *value = [dict objectForKey:@"engine"];
        if (value && [value isKindOfClass:[NSString class]]) {
            curEngine = [value lowercaseString];
        }else {
            curEngine = @"ifly";
        }
    }
    if ( curEngine ) {
        PGSpeechImp *speechImp = [self getEngine:curEngine];
        if (speechImp) {
            _speechEngine = speechImp;
        }else {
            _speechEngine = [self getEngine:@"ifly"];
        }
        _speechEngine.bridge = self;
        [_speechEngine startRecognize:command];
        return;
    }
    
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:PGSpeechErrorEngineNotSupport];
    [self toCallback:cID withReslut:[result toJSONString]];
}

- (void)stopRecognize:(PGMethod*)command {
    [_speechEngine stopRecognize:command];
}

- (void)addEventListener:(PGMethod *)commands {
    NSString *type = [commands getArgumentAtIndex:0];
    NSString *cbId = [commands getArgumentAtIndex:1];
    NSString *adFrameId = [commands getArgumentAtIndex:2];
    if ( [type isKindOfClass:[NSString class]] && [type length] ) {
        type = [type lowercaseString];
        [self addEvtType:type onCallBackId:cbId onRecognition:adFrameId];
    }
}

- (void)addEvtType:(NSString*)typeName onCallBackId:(NSString *)cbId onRecognition:(NSString*)adFrameId {
    
    NSMutableDictionary *reconizerCBInfo = [self.recognizerEvtObservers objectForKey:adFrameId];
    if ( !reconizerCBInfo ) {
        reconizerCBInfo = [NSMutableDictionary dictionary];
        [self.recognizerEvtObservers setObject:reconizerCBInfo forKey:adFrameId];
    }
    NSMutableArray *evtType = [reconizerCBInfo objectForKey:typeName];
    if ( !evtType ) {
        evtType = [NSMutableArray array];
        [reconizerCBInfo setObject:evtType forKey:typeName];
    }
    [evtType addObject:cbId];
}

- (void)sendEvent:(NSString*)type withParams:(NSDictionary *)params {
    for (NSString *adFrameId in _recognizerEvtObservers) {
        NSMutableDictionary *cbInfos = [_recognizerEvtObservers objectForKey:adFrameId];
        if ( cbInfos ) {
            type = [type lowercaseString];
            NSMutableArray *evtCbIds = [cbInfos objectForKey:type];
            for ( NSString *cbId in evtCbIds ) {
                [self toSucessCallback:cbId inWebview:adFrameId withJSON:params keepCallback:YES];
            }
        }
    }
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    [super onAppFrameWillClose:theAppframe];
    if (self.frameWillCloseBlock) {
        self.frameWillCloseBlock(theAppframe);
    }
    if ([self.recognizerEvtObservers objectForKey:theAppframe.viewUUID]) {
        [self.recognizerEvtObservers removeObjectForKey:theAppframe.viewUUID];
    }
}

- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGSpeechErrorNotAppid: return @"未配置appid";
        case PGSpeechErrorMicOpenFail: return @"重复打开语音";
        case PGSpeechErrorUserStop: return @"用户关闭语音";
        case PGSpeechErrorNet: return @"网络连接错误";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}

- (void)dealloc {
    _speechEngine = nil;
}

- (NSMutableDictionary *)recognizerEvtObservers {
    if (!_recognizerEvtObservers) {
        _recognizerEvtObservers = [NSMutableDictionary dictionary];
    }
    return _recognizerEvtObservers;
}

@end    
