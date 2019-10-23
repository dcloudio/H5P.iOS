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
#import <iflyMSC/IFlyMSC.h>
#import "PGSpeech.h"

@interface PGIFLYSpeech : PGSpeechImp <IFlyRecognizerViewDelegate,IFlySpeechRecognizerDelegate> {
    IFlyRecognizerView *_iFlyRecognizeControl;
    IFlySpeechRecognizer *_iFlySpeechRecognizer;
}
@end
