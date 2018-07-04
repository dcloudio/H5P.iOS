//
//  BDSBuiltInPlayer.h
//  BDSSpeechSynthesizer
//
//  Created by  段弘 on 14-7-14.
//  Copyright (c) 2014年 百度. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BDSBuiltInPlayer;

@protocol BDSBuiltInPlayerDelegate <NSObject>

/**
 * @brief 播放已结束
 *
 * @param player 播放器对象
 */
- (void)playerDidFinished:(BDSBuiltInPlayer *)player;

/**
 * @brief 播放被暂停（被其他应用程序中断）
 *
 * @param player 播放器对象
 */
- (void)playerDidPaused:(BDSBuiltInPlayer *)player;

/**
 * @brief 播放器发生错误，请重新建立播放器对象
 *
 * @param player
 *            播放器对象
 * @param error
 *            错误信息
 */
- (void)playerErrorOccured:(BDSBuiltInPlayer *)player error:(NSError*)error;

@end

@interface BDSBuiltInPlayer : NSObject

/** 播放器状态代理 */
@property (nonatomic, weak) id<BDSBuiltInPlayerDelegate> delegate;

/** AudioSessionCategory类型，取值参见AVAudioSession Class Reference */
@property (nonatomic, copy) NSString *audioSessionCategory;

/**
 * @brief 播放音频数据，仅支持播放由合成器返回的pcm数据
 *
 * @param data
 *            pcm数据
 * @param outError
 *            如果播放失败，该对象将用于返回错误信息
 */
- (BOOL)playPcmData:(NSData *)data error:(NSError **)outError;

/**
 * @brief 播放URL所指向的内容
 *
 * @param url
 *            用于指定需要播放的音频文件
 * @param outError
 *            如果播放失败，该对象将用于返回错误信息
 */
- (BOOL)playContentsOfURL:(NSURL *)url error:(NSError **)outError;

/**
 * @brief 暂停播放
 */
- (void)pause;

/**
 * @brief 继续播放
 */
- (void)resume;

/**
 * @brief 停止播放
 */
- (void)stop;

@end
