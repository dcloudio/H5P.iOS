#ifndef BDSSpeechSynthesizer_BDSSpeechSynthesizerErrors_h
#define BDSSpeechSynthesizer_BDSSpeechSynthesizerErrors_h

#import <Foundation/Foundation.h>


#pragma mark - Error domains

FOUNDATION_EXPORT NSString * const BDTTS_ERROR_DOMAIN_TTS;          /* Synthesis issues */
FOUNDATION_EXPORT NSString * const BDTTS_ERROR_DOMAIN_AUTH;         /* Client authentication issues */
FOUNDATION_EXPORT NSString * const BDTTS_ERROR_DOMAIN_NET;          /* Network issues */
FOUNDATION_EXPORT NSString * const BDTTS_ERROR_DOMAIN_SERVER;       /* Online TTS service returned issues */
FOUNDATION_EXPORT NSString * const BDTTS_ERROR_DOMAIN_EMBEDDED_TTS; /* Offline TTS issues */
FOUNDATION_EXPORT NSString * const BDTTS_ERROR_DOMAIN_INTERNAL;     /* SDK Internal problems */

#pragma mark - Error codes

/*
 * Error code definitions for most common issues, all errors returned as NSError objects.
 * Check the NSError's localized description to get error details.
 */
typedef enum BDTTSError
{
    OK = 0,
    // BDTTS_ERROR_DOMAIN_TTS
    ERR_TEXT_TOO_SHORT = ((200 << 16)|(0x0000FFFF&-1)),
    ERR_TEXT_TOO_LONG = ((200 << 16)|(0x0000FFFF&-2)),
    ERR_ENGINE_BUSY = ((200 << 16)|(0x0000FFFF&-3)),
    ERR_INVALID_PARAM = ((200 << 16)|(0x0000FFFF&-8000)),
    ERR_SDK_UNINIT = ((200 << 16)|(0x0000FFFF&-8001)),
    
    // BDTTS_ERROR_DOMAIN_AUTH
    ERR_ONLINE_TTS_AUTH_CREDENTIALS_NOT_SET = ((200 << 16)|(0x0000FFFF&-6)),
    ERR_ONLINE_TTS_FAILED_GET_ACCESS_TOKEN = ((222 << 16)|(0x0000FFFF&-1)),
    ERR_OFFLINE_TTS_FAILED_GET_LICENSE = ((212 << 16)|(0x0000FFFF&-1)),
    ERR_OFFLINE_TTS_LICENSE_EXPIRED = ((212 << 16)|(0x0000FFFF&-10)),
    
    // BDTTS_ERROR_DOMAIN_NET
    ERR_NO_INTERNET = ((200 << 16)|(0x0000FFFF&-4)),
    ERR_DNS_FAILED = ((223 << 16)|(0x0000FFFF&-1)),
    ERR_ONLINE_TTS_REQUEST = ((223 << 16)|(0x0000FFFF&-2)),
    ERR_ONLINE_TTS_RESPONSE = ((223 << 16)|(0x0000FFFF&-3)),
    
    // BDTTS_ERROR_DOMAIN_EMBEDDED_TTS
    ERR_OFFLINE_ENGINE_LOAD_FAILED = ((210 << 16)|(0x0000FFFF&-1)),
    ERR_OFFLINE_ENGINE_NOT_LOADED = ((210 << 16)|(0x0000FFFF&-2)),
    ERR_OFFLINE_ENGINE_MISSING_PARAM = ((210 << 16)|(0x0000FFFF&-3)),
    ERR_OFFLINE_SYNTHESIS_FAILED = ((210 << 16)|(0x0000FFFF&-4)),
    ERR_OFFLINE_DATA_FILE_NOT_EXIST = ((210 << 16)|(0x0000FFFF&-8000)),
    ERR_OFFLINE_DATA_FILE_VERIFY_FAIL = ((210 << 16)|(0x0000FFFF&-8001)),
    ERR_OFFLINE_PARAM = ((210 << 16)|(0x0000FFFF&-8002)),
    ERR_OFFLINE_DATA_FILE_DETAIL_NOT_FOUND = ((210 << 16)|(0x0000FFFF&-8003)),
}BDTTSError;

#pragma mark - Synthesizer states

typedef enum BDSSynthesizerStatus {
    /*
     * Failed to initialize SDK
     */
    BDS_SYNTHESIZER_STATUS_NONE = 0,
    
    /*
     * SDK ready for use
     */
    BDS_SYNTHESIZER_STATUS_IDLE,
    
    /*
     * SDK is synthesizing/speaking
     */
    BDS_SYNTHESIZER_STATUS_WORKING,
    
    /*
     * Synthesis (and speech) is paused
     */
    BDS_SYNTHESIZER_STATUS_PAUSED,
    
    /*
     * SDK has encountered error during previous synthesis.
     * SDK is ready for start new synthesis
     */
    BDS_SYNTHESIZER_STATUS_ERROR,
    
    /*
     * SDK was cancelled by user during previous synthesis.
     * SDK is ready for start new synthesis
     */
    BDS_SYNTHESIZER_STATUS_CANCELLED
}BDSSynthesizerStatus;


#pragma mark - Definitions for deprecated legacy interfaces

typedef enum BDSStartSynthesisError
{
    // Shared errors
    BDS_START_SYNTHESIS_OK = 0,                     /* No errors */
    BDS_START_SYNTHESIS_SYNTHESIZER_UNINITIALIZED,  /* Engine is not initialized */
    BDS_START_SYNTHESIS_TEXT_EMPTY,                 /* Synthesis text is empty */
    BDS_START_SYNTHESIS_TEXT_TOO_LONG,              /* Synthesis text is too long */
    BDS_START_SYNTHESIS_ENGINE_BUSY,               /* Already synthesising, cancel first or wait */
    BDS_START_SYNTHESIS_MALLOC_ERROR,                /* failed to allocate resources */
    BDS_START_SYNTHESIS_NO_NETWORK,                 /* No internet connectivity */
    BDS_START_SYNTHESIS_NO_VERIFY_INFO,             /* No product id or api keys set */
    /* Offline TTS engine wasn't loaded */
    BDS_START_SYNTHESIS_OFFLINE_ENGINE_NOT_LOADED,
    BDS_START_SYNTHESIS_ERROR_UNKNOWN               /* Error code is unknown to legacy interface, must use new interfaces */
}BDSStartSynthesisError __attribute__((deprecated("This interface has been deprecated, all new interfaces work with NSError to report errors.")));

typedef enum BDSSynthesisError
{
    /* General usage */
    BDS_UNKNOWN_ERROR = 30001,  /* Unhandled error, see error description for details */
    /* Playback errors */
    BDS_PLAYER_FAILED_GET_STREAM_PROPERTIES = 25001,
    BDS_PLAYER_FAILED_OPEN_DEVICE,
    BDS_PLAYER_FAILED_OPEN_STREAM,
    BDS_PLAYER_ALLOC_FAIL,
    BDS_PLAYER_BAD_STREAM,
    BDS_PLAYER_START_PLAYBACK_FAILED,
    // Online TTS Errors
    /* Online TTS errors */
    BDS_ONLINE_TTS_CONNECT_ERROR = 2001,
    BDS_ONLINE_TTS_RESPONSE_PARSE_ERROR = 2002,
    BDS_ONLINE_TTS_PARAM_ERROR = 4501,
    /** 文本编码不支持 */
    BDS_ONLINE_TTS_TEXT_ENCODE_NOT_SUPPORTED = 4502,
    /** 认证错误 */
    BDS_ONLINE_TTS_VERIFY_ERROR = 4503,
    /** 获取access token失败 */
    BDS_ONLINE_TTS_GET_ACCESS_TOKEN_FAILED = 4001,
    
    // Oflfine TTS errors
    BDS_ETTS_ERR_PARTIAL_SYNTH = 10001,
    BDS_ETTS_ERR_CONFIG,
    BDS_ETTS_ERR_RESOURCE,
    BDS_ETTS_ERR_HANDLE,
    BDS_ETTS_ERR_PARMAM,
    BDS_ETTS_ERR_MEMORY,
    BDS_ETTS_ERR_TOO_MANY_TEXT,
    BDS_ETTS_ERR_RUN_TIME,
    BDS_ETTS_ERR_NO_TEXT,
    BDS_ETTS_ERR_LICENSE,
    
}BDSSynthesisError __attribute__((deprecated("This interface has been deprecated, all new interfaces work with NSError to report errors.")));

typedef enum BDSErrEngine{
    BDS_ERR_ENGINE_OK = 0,
    BDS_ERR_ENGINE_PARTIAL_SYNTH = 10001,
    BDS_ERR_ENGINE_CONFIG,
    BDS_ERR_ENGINE_RESOURCE,
    BDS_ERR_ENGINE_HANDLE,
    BDS_ERR_ENGINE_PARMAM,
    BDS_ERR_ENGINE_MEMORY,
    BDS_ERR_ENGINE_MANY_TEXT,
    BDS_ERR_ENGINE_RUN_TIME,
    BDS_ERR_ENGINE_NO_TEXT,
    BDS_ERR_ENGINE_LICENSE,
    BDS_ERR_ENGINE_MALLOC,
    BDS_ERR_ENGINE_ENGINE_NOT_INIT,
    BDS_ERR_ENGINE_SESSION_NOT_INIT,
    BDS_ERR_ENGINE_GET_LICENSE,
    BDS_ERR_ENGINE_LICENSE_EXPIRED,
    BDS_ERR_ENGINE_VERIFY_LICENSE,
    BDS_ERR_ENGINE_INVALID_PARAM,
    BDS_ERR_ENGINE_DATA_FILE_NOT_EXIST,
    BDS_ERR_ENGINE_VERIFY_DATA_FILE,
    BDS_ERR_ENGINE_GET_DATA_FILE_PARAM,
    BDS_ERR_ENGINE_ENCODE_TEXT,
    BDS_ERR_ENGINE_INIT_FAIL,
    BDS_ERR_ENGINE_IN_USE,
    BDS_ERR_ENGINE_BAD_INIT_STATE,
    BDS_ERR_ENGINE_UNKNOWN_ERROR
}BDSErrEngine __attribute__((deprecated("This interface has been deprecated, all new interfaces work with NSError to report errors.")));
#endif
