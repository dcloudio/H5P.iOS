/*
 *------------------------------------------------------------------
 *  pandora/feature/PGSpeech.h
 *  Description:
 *      JS log Native对象抽象
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date  modify record
 *   0       xty     2013-01-11  创建文件
 *------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>
#import "PGMethod.h"
#import "PGPlugin.h"

typedef NS_ENUM(NSInteger, PGSpeechError) {
    PGSpeechErrorNO = 0, //
    PGSpeechErrorEngineNotSupport = 61000, //此设备不支持语音识别
    PGSpeechErrorUserStop = 61001, //用户停止，在调用stopRecognize接口时触发
	PGSpeechErrorNotSupport = 61002, //此设备不支持语音识别
    PGSpeechErrorMicOpenFail = 61003, //调用麦克风设备错误，如设备被其它程序占用
    PGSpeechErrorEngineBadParam = 61004, //语音识别引擎参数错误
    PGSpeechErrorEngineSyntax = 61005, //语音识别引擎语法错误
    PGSpeechErrorEngine = 61006, //语音识别引擎内部错误
    PGSpeechErrorNotRecognize = 61007, //语音识别引擎无法识别
    PGSpeechErrorNet = 61008, //网络问题引起的错误
    PGSpeechErrorNotAppid = 61009, //网络问题引起的错误
    PGSpeechErrorOther = 61010, //其它未定义的错误
};

@class PGSpeech;

@interface PGSpeechImp : NSObject {
    
}

@property(nonatomic, assign)PGSpeech *bridge;

@property (readwrite, assign) BOOL hasPendingOperation;
@property(nonatomic, copy)NSString *callBackID;
//字符串类型，可选参数，语音识别引擎标识，用于兼容多语音识别引擎的浏览器
//，建议使用语音识别厂商的产品名称，如未设置或设置不正确则使用浏览器默认的语音识别引擎；
@property(nonatomic, copy)NSString *engine;
//字符串类型，可选参数，语音识别引擎服务器地址，
//可使用url地址或ip地址，如service:192.168.1.99指定定制的语音识别引擎服务器。
//默认值为浏览器内置服务器地址。
@property(nonatomic, copy)NSString *service;
//数字类型，可选参数，语音识别超时时间，单位为ms，
//如timeout:60000。默认值为10s。
@property(nonatomic, assign)NSInteger timeout;
//字符串类型，可选用于定义语音识别引擎的语言，
//其取值需符合W3C的HYPERLINK "http://www.w3.org/TR/html401/struct/dirlang.html" \l "
//h-8.1.1" Language codes规范。默认值为浏览器的默认语言。
@property(nonatomic, copy)NSString *lang;
//布尔类型，可选参数，指定语音识别是否采用持续模式，
//设置为true表示语音引擎不会根据语音输入自动结束，
//识别到文本内容将多次调用successCallback函数返回
//，如果需要结束语音识别则必须调用stopRecognize接口。默认值为false。
@property(nonatomic, assign)BOOL recognizeContinue;
//布尔类型，可选参数，用于指定识别结果识别包括多候选结果。
//如nbest:3，识别返回3个候选结果。默认值为1。
@property(nonatomic, assign)NSInteger nbest;
//布尔类型，可选弄参数，用于指定识别时是否显示用户界面，
//设置为true表示显示浏览器内置语音识别界面；
//设置为false表示不显示浏览器内置语音识别界面。默认值为true。
@property(nonatomic, assign)BOOL userInterface;
//布尔类型，可选弄参数，用于指定识别结果中是否包含标点符号，
//设置为true识别结果中包含标点符号
//设置为false识别结果中不包含标点符号
@property(nonatomic, assign)BOOL punctuation;

- (void)startRecognize:(PGMethod*)commands;
- (void)stopRecognize:(PGMethod*)commands;

- (void)parseOptions:(NSDictionary*)dict;
- (void)resetOptions;

@end

@interface PGSpeech : PGPlugin {
    PGSpeechImp *_speechEngine;
}
- (void)startRecognize:(PGMethod*)commands;
- (void)stopRecognize:(PGMethod*)commands;
@end
