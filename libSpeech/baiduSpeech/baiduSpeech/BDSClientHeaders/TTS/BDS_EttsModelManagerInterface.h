//
//  BDS_EttsModelManagerInterface.h
//  EttsModelDownloader
//
//  Created by lappi on 7/25/16.
//  Copyright © 2016 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Manager delegate

@protocol EttsModelDownloaderDelegate <NSObject>

-(void)modelDownloadQueuedForHandle:(NSString*)downloadHandle  /* Download handle used for identifying this task */
                         forModelID:(NSString*)modelID
                         userParams:(NSDictionary*)params
                              error:(NSError*)err;

-(void)modelDownloadStartedForHandle:(NSString*)downloadHandle;

-(void)modelDownloadProgressForHandle:(NSString*)downloadHandle
                           totalBytes:(NSInteger)total
                      downloadedBytes:(NSInteger)downloaded;

-(void)modelFinishedForHandle:(NSString*)downloadHandle
                    withError:(NSError*)err;

-(void)gotRemoteModels:(NSArray*)models error:(NSError*)err;
-(void)gotDefaultModels:(NSArray*)models error:(NSError*)err;
-(void)gotLocalModels:(NSArray*)models error:(NSError*)err;

@end

#pragma mark - Manager name
/*
 * Name for etts model manager,
 * use [BDSTTSEventManager createEventManagerWithName:BDS_ETTS_MODEL_MANAGER_NAME];
 * To get instance of etts model manager
 */
extern NSString* BDS_ETTS_MODEL_MANAGER_NAME;

#pragma mark - Manager commands

/*
 * COMMAND: BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE
 * Get list of available models for current etts engine from server
 * REQUIRED PARAMETERS:
 *      BDS_ETTS_MODEL_MANAGER_CALLBACK_DELEGATE (passed delegate must conform to @protocol EttsModelDownloaderDelegate)
 * CALLBACKS:
 *      -(void)gotRemoteModels:(NSArray*)models error:(NSError*)err
 *          models: NSArray conatining NSDictionaries, one NSDictionary for each model info.
 *          Content of returned dictionaries:
 *              BDS_ETTS_MODEL_MANAGER_MODEL_ID : NSString([model id])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_NAME : NSString([model name])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_SPEAKER: NSString([name of the speaker in the model])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_GENDER : NSString([model gender])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_LANGUAGE : NSString([model language])
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE;

/*
 * COMMAND: BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT
 * Get list of default models for current etts engine from server
 * REQUIRED PARAMETERS:
 *      BDS_ETTS_MODEL_MANAGER_CALLBACK_DELEGATE (passed delegate must conform to @protocol EttsModelDownloaderDelegate)
 * CALLBACKS:
 *      -(void)gotDefaultModels:(NSArray*)models error:(NSError*)err
 *          models: NSArray conatining NSDictionaries, one NSDictionary for each model info.
 *          Content of returned dictionaries:
 *              BDS_ETTS_MODEL_MANAGER_MODEL_ID : NSString([model id])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_NAME : NSString([model name])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_GENDER : NSString([model gender])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_LANGUAGE : NSString([model language])
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT;

/*
 * COMMAND: BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 * Get list of local models (complete and partially downloaded)
 * REQUIRED PARAMETERS:
 *      BDS_ETTS_MODEL_MANAGER_CALLBACK_DELEGATE (passed delegate must conform to @protocol EttsModelDownloaderDelegate)
 * CALLBACKS:
 *      -(void)gotLocalModels:(NSArray*)models error:(NSError*)err
 *          models: NSArray conatining NSDictionaries, one NSDictionary for each model info.
 *          Content of returned dictionaries:
 *              BDS_ETTS_MODEL_MANAGER_MODEL_ID : NSString([model id])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_NAME : NSString([model name])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_GENDER : NSString([model gender])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_LANGUAGE : NSString([model language])
 *              BDS_ETTS_MODEL_MANAGER_MODEL_DOWNLOADED : NSNumber(NSINteger(byte count))
 *              BDS_ETTS_MODEL_MANAGER_MODEL_SIZE : NSNumber(NSINteger(byte count))  -1 if unknown
 *              BDS_ETTS_MODEL_MANAGER_MODEL_USABLE : NSNumber(BOOL(YES/NO)) NO if model is partially
 *                  downloaded, send BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD to finish download.
 *              BDS_ETTS_MODEL_MANAGER_MODEL_SPEECH_DATA : Full path to speech data file, key is not available for partially downloaded models.
 *              BDS_ETTS_MODEL_MANAGER_MODEL_TEXT_DATA : Full path to text data file, key is not available for partially downloaded models.
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL;

/*
 * COMMAND: BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD
 * Start/continue downloading a model
 * REQUIRED PARAMETERS:
 *      BDS_ETTS_MODEL_MANAGER_CALLBACK_DELEGATE    (passed delegate must conform to @protocol EttsModelDownloaderDelegate)
 *      BDS_ETTS_MODEL_MANAGER_MODEL_ID             (Model id of the model you wish to download)
 * CALLBACKS:
 *          -(void)modelDownloadQueuedForModelID:(NSString*)downloadHandle
 *                                    forModelID:(NSString*)modelID
 *                                    userParams:(NSDictionary*)params
 *                                         error:(NSError*)err;
 *          downloadHandle: Random string that can be used for identifying events related to this
 *                          download (you may use same delegate for multiple downloads) and for stopping the download.
 *          modelID:        Requested model ID.
 *          params:         The parameters you passed to
 *                          - (void)sendCommand:(NSString *)command withParameters:(NSDictionary*)params
 *                          while sending BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD
 *          err:            nil if no errors happened.
 *
 *      -(void)modelDownloadStartedForHandle:(NSString*)downloadHandle;
 *          Called when download actually starts. The manager has limited simultaneous downloads to 3,
 *          any requests after that will get queued and are started later as previous downloads end.
 *
 *      -(void)modelDownloadProgressForHandle:(NSString*)downloadHandle
 *                                 totalBytes:(NSInteger)total
 *                            downloadedBytes:(NSInteger)downloaded;
 *          Multiple calls during download to indicate download progress.
 *
 *      -(void)modelFinishedForHandle:(NSString*)downloadHandle withError:(NSError*)err;
 *          Called when download is finished or fails due to an error. If err is nil, download was a success.
 *          Will not get called if user stops the download by sending BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD_STOP
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD;

/*
 * COMMAND: BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD_STOP
 * Stop downloading a model
 * REQUIRED PARAMETERS:
 *      BDS_ETTS_MODEL_MANAGER_MODEL_DOWNLOAD_HANDLE
 *          Handle you received from
 *          -(void)modelDownloadQueuedForModelID:(NSString*)downloadHandle
 *                                    forModelID:(NSString*)modelID
 *                                    userParams:(NSDictionary*)params
 *                                         error:(NSError*)err;
 *          while starting the download
 * CALLBACKS:
 *      -
 *
 * NOTES:  You can discard the handle after sending stop, there may still be a few more callbacks related to this download after the request returns.
 *         Just ignore the callbacks in this case.
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD_STOP;

#pragma mark - parameter keys
/*
 * BDS_ETTS_MODEL_MANAGER_CALLBACK_DELEGATE
 * callback delegate for commands. Object should respond to @protocol EttsModelDownloaderDelegate <NSObject> methods.
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_CALLBACK_DELEGATE;

/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_ID
 * Model id of audio model, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 *
 * and as input parameter for following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_ID;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_NAME
 * Name of audio model, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_NAME;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_SPEAKER
 * Name of the speaker in audio model, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_SPEAKER;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_GENDER
 * Speaker gender of audio model, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_GENDER;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_LANGUAGE
 * Audio model supported language, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_AVAILABLE
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_DEFAULT
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_LANGUAGE;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_DOWNLOADED
 * Currently downloaded byte count of audio model, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_DOWNLOADED;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_SIZE
 * Total byte size of audio model, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_SIZE;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_USABLE
 * Indicates if model is ready for use locally, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_USABLE;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_SPEECH_DATA
 * Full path to model's speech data file, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_SPEECH_DATA;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_TEXT_DATA
 * Full path to model's text data file, key used in Dictionaries given as responses to following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_GET_LOCAL
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_TEXT_DATA;
/*
 * BDS_ETTS_MODEL_MANAGER_MODEL_DOWNLOAD_HANDLE
 * Download handle for model ownload task, usable value is obtained via -(void)modelDownloadQueuedWithHandle:(NSString*)downloadHandle error:(NSError*)err;
 * while starting download.
 *
 * key is used as input parameter with following commands:
 *  BDS_ETTS_MODEL_MANAGER_COMMAND_DOWNLOAD_STOP
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_MODEL_DOWNLOAD_HANDLE;

#pragma mark - optional configurations
/*
 * BDS_ETTS_MODEL_MANAGER_CALLBACK_QUEUE
 * Dispatch queue in which the callbacks should be made, by default the application's main queue will be used.
 */
extern const NSString* BDS_ETTS_MODEL_MANAGER_CALLBACK_QUEUE;
