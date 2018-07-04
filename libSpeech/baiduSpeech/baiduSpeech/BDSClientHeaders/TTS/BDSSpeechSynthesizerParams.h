//
//  BDSSpeechSynthesizerParams.h
//  BDSSpeechSynthesizer
//
//  Created by lappi on 7/31/15.
//  Copyright (c) 2015 百度. All rights reserved.
//

#ifndef BDSSpeechSynthesizer_BDSSpeechSynthesizerParams_h
#define BDSSpeechSynthesizer_BDSSpeechSynthesizerParams_h

#pragma mark - param definitions

typedef enum BDSSynthesizerParamKey
{
    BDS_SYNTHESIZER_PARAM_SPEED = 0,                /* NSNumber([0...9]) */
    BDS_SYNTHESIZER_PARAM_PITCH,                    /* NSNumber([0...9]) */
    BDS_SYNTHESIZER_PARAM_VOLUME,                   /* NSNumber([0...9]) */
    /*
     * BDS_SYNTHESIZER_PARAM_ENABLE_AVSESSION_MGMT
     * If enabled (default) SDK will manage AVAudioSession internally:
     *  - Activate session when it's needed, disable when no longer needed.
     *  - Handle audio session interruptions.
     *  - Manage audio session category.
     */
    BDS_SYNTHESIZER_PARAM_ENABLE_AVSESSION_MGMT,    /* NSNumber(BOOL), default YES*/
    
    /*
     * You may use this to adjust the withOptions parameter SDK passes to AVAudioSession when it calls
     * [[AVAudioSession sharedInstance] setCategory:withOptions:error:];
     * Effective only when BDS_SYNTHESIZER_PARAM_ENABLE_AVSESSION_MGMT is set to YES
     */
    BDS_SYNTHESIZER_PARAM_AUDIO_SESSION_CATEGORY_OPTIONS, /* NSNumber(AVAudioSessionCategoryOptions),
                                                           default (AVAudioSessionCategoryOptionMixWithOthers|
                                                           AVAudioSessionCategoryOptionDuckOthers)
                                                           */
    BDS_SYNTHESIZER_PARAM_ONLINE_OPEN_XML,          /* NSNumber([0,1]) default 0*/
    BDS_SYNTHESIZER_PARAM_PID,                      /* NSNumber(PID number) */
#pragma mark - deprecated
    BDS_SYNTHESIZER_PARAM_LANGUAGE,                 /* NSNumber(enum BDSSynthesizerLanguages) */
    BDS_SYNTHESIZER_PARAM_TEXT_ENCODE,              /* NSNumber(enum BDSSynthesizerTextEncodings) */
    
#pragma mark - end deprecated
    BDS_SYNTHESIZER_PARAM_AUDIO_ENCODING,           /* NSNumber(enum BDSSynthesizerAudioEncoding) */
    BDS_SYNTHESIZER_PARAM_SPEAKER,                  /* NSNumber(enum BDSSynthesizerSpeaker) */
    BDS_SYNTHESIZER_PARAM_USER_AGENT,               /* NSString */
    
    /* 如果与百度语音技术部有直接合作关系，才需要考虑此方法，否则请勿随意设置服务器地址 */
    /* tts合成服务器地址 NSString */
    BDS_SYNTHESIZER_PARAM_SERVER_URL,
    
    /*
     * 设置tts超时时间 NSNumber([timeout in seconds, float]) must be at least 0.8
     * any smaller values will be set to 0.8
     *
     * Effective only when synthesizing without speak using following interface:
     * -(NSInteger) synthesizeSentence:(NSString*)sentence withError:(NSError**)err
     *
     * If using following speak interface, this value is ignored and timeout is determined internally by SDK.
     * -(NSInteger) speakSentence:( NSString* _Nonnull )sentence withError:(NSError**)err
     */

    BDS_SYNTHESIZER_PARAM_ONLINE_REQUEST_TIMEOUT,
    
    BDS_SYNTHESIZER_PARAM_ETTS_OPEN_XML,            /* NSNumber([0,1]) */
    BDS_SYNTHESIZER_PARAM_ETTS_DOMAIN_SYNTH,        /* NSNumber([0,1]) */
    BDS_SYNTHESIZER_PARAM_ETTS_AUDIO_FORMAT,        /* NSNumber(enum ETTS_AUDIO_TYPE) */
    BDS_SYNTHESIZER_PARAM_ETTS_VOCODER_OPTIM_LEVEL, /* NSNumber(enum ETTS_VOCODER_OPTIM_LEVEL) */
    BDS_SYNTHESIZER_PARAM_ONLINE_TTS_THRESHOLD,      /* NSNumber(enum ONLINE_TTS_TRESSHOLD) */
    /*
     * BDS_SYNTHESIZER_PARAM_ENABLE_TIMEOUT_OPTIMIZATION
     * If this is enabled, strategy is set to TTS_MODE_ONLINE_PRI, offline engine is
     * succesfully loaded and you are using speakSentence interface to synthesise and play,
     * SDK will set a shorter timeout (about 1.5 seconds) for first request of first sentence
     * to make sure the playback begins in a reasonable time even in bad networks.
     *
     * Disabled by default.
     */
    BDS_SYNTHESIZER_PARAM_ENABLE_TIMEOUT_OPTIMIZATION,  /* NSNumber([0,1]) */
    BDS_SYNTHESIZER_PARAM_SYNTH_STRATEGY,           /* NSNumber(enum TTS_MODE) */
}BDSSynthesizerParamKey;

/* PARAM VALUES */

/* Use with BDS_SYNTHESIZER_PARAM_AUDIO_ENCODING */
enum BDSSynthesizerAudioEncoding
{
    BDS_SYNTHESIZER_AUDIO_ENCODE_BV_16K = 0,    /** bv 16k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_6K6,       /** amr 6.6k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_8K85,      /** amr 8.85k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_12K65,     /** amr 12.65k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_14K25,     /** amr 14.25k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_15K85,     /** amr 15.85k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_18K25,     /** amr 18.25k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_19K85,     /** amr 19.85k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_23K05,     /** amr 23.05k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_AMR_23K85,     /** amr 23.85k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_OPUS_8K,       /** opus 8k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_OPUS_16K,      /** opus 16k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_OPUS_18K,      /** opus 18k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_OPUS_20K,      /** opus 20k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_OPUS_24K,      /** opus 24k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_OPUS_32K,      /** opus 32k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_MP3_8K,        /** mp3 8k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_MP3_11K,       /** mp3 11k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_MP3_16K,       /** mp3 16k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_MP3_24K,       /** mp3 24k比特率 */
    BDS_SYNTHESIZER_AUDIO_ENCODE_MP3_32K,       /** mp3 32k比特率 */
};
/* Use with BDS_SYNTHESIZER_PARAM_SPEAKER */
enum BDSSynthesizerSpeaker
{
    BDS_SYNTHESIZER_SPEAKER_FEMALE = 0,     /* 女声 (f7) */
    BDS_SYNTHESIZER_SPEAKER_MALE = 1,       /* 男声 (macs) */
    BDS_SYNTHESIZER_SPEAKER_MALE_2 = 2,     /* 男声 (m15) */
    BDS_SYNTHESIZER_SPEAKER_MALE_3 = 3      /* 男声 (yyjw) */
};

// 输出的pcm音频数据类型: 16K（默认）/ 8K
// Use with BDS_SYNTHESIZER_PARAM_ETTS_AUDIO_FORMAT
typedef enum ETTS_AUDIO_TYPE
{
    ETTS_AUDIO_TYPE_PCM_16K, // 默认
    ETTS_AUDIO_TYPE_PCM_8K
}ETTS_AUDIO_TYPE;

// VOCODER优化等级：// 0级表示没有优化，音质效果最好，数值越大速度越快，但音质效果会降低
// Use with BDS_SYNTHESIZER_PARAM_ETTS_VOCODER_OPTIM_LEVEL
enum ETTS_VOCODER_OPTIM_LEVEL
{
    ETTS_VOCODER_OPTIM_LEVEL_0,
    ETTS_VOCODER_OPTIM_LEVEL_1,
    ETTS_VOCODER_OPTIM_LEVEL_2,
};

/* Use with BDS_SYNTHESIZER_PARAM_SYNTH_STRATEGY */
typedef enum TTS_MODE
{
    TTS_MODE_ONLINE,
    TTS_MODE_OFFLINE,
    TTS_MODE_ONLINE_PRI,
    TTS_MODE_OFFLINE_PRI,
}TTS_MODE;

typedef enum ONLINE_TTS_TRESHOLD
{
    /* Use online TTS when there is internet connectivity */
    REQ_CONNECTIVITY_ANY = 0,
    /* Use online TTS when have at least 3G Connectivity */
    REQ_CONNECTIVITY_3G,
    /* Use online TTS when have at least 4G Connectivity */
    REQ_CONNECTIVITY_4G,
    /* Use online TTS only when connected to wifi (Default) */
    REQ_CONNECTIVITY_WIFI
}ONLINE_TTS_TRESHOLD;

// 音库文件相关参数
typedef enum TTSDataParam{
    TTS_DATA_PARAM_DATE,
    TTS_DATA_PARAM_SPEAKER,
    TTS_DATA_PARAM_GENDER,
    TTS_DATA_PARAM_CATEGORY,
    TTS_DATA_PARAM_LANGUAGE,
    TTS_DATA_PARAM_VERSION,
    TTS_DATA_PARAM_DOMAIN,
    TTS_DATA_PARAM_TYPE,
    TTS_DATA_PARAM_QUALITY
}TTSDataParam;

#pragma mark - deprecated legacy param definitions
typedef enum BDSSynthesizerParamError
{
    BDS_SYNTHESIZER_PARAM_ERR_OK = 0,
    BDS_SYNTHESIZER_PARAM_ERR_NOT_SUPPORT = 6000,
    BDS_SYNTHESIZER_PARAM_ERR_INVALID_VALUE,
    BDS_SYNTHESIZER_PARAM_ERR_SDK_UNINIT,
    BDS_SYNTHESIZER_PARAM_ERR_SDK_BUSY,
    BDS_SYNTHESIZER_PARAM_SET_FAILED,
    BDS_SYNTHESIZER_PARAM_ERR_UNKNOWN   /* Error unknown to legacy interface, use new interfaces */
}BDSSynthesizerParamError __attribute__((deprecated("This interface has been deprecated, all new interfaces work with NSError to report errors.")));

/* PARAM VALUES */
/* Use with BDS_SYNTHESIZER_PARAM_LANGUAGE */
enum BDSSynthesizerLanguages
{
    BDS_SYNTHESIZER_LANGUAGE_ZH = 0,
    BDS_SYNTHESIZER_LANGUAGE_EN
};
/* Use with BDS_SYNTHESIZER_PARAM_TEXT_ENCODE */
enum BDSSynthesizerTextEncodings
{
    BDS_SYNTHESIZER_TEXT_ENCODE_UTF8 = 2
};

#endif
