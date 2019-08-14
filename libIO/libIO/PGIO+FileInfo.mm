/*
 *------------------------------------------------------------------
 *  pandora/feature/log/pg_log.mm
 *  Description:
 *      JS log Native对象基类实现
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *    number    author    modify date  modify record
 *   0       xty     2013-01-11  创建文件
 *------------------------------------------------------------------
 */
#import "PGIO+FileInfo.h"

#import <AVFoundation/AVFoundation.h>
#import "PGPlugin.h"
#import "PTPathUtil.h"
#import "PDRCore.h"
#import "PDRCoreAppFrame.h"
#import "PGIO+Digest.h"
#import "PDRCommonString.h"

typedef void (^GetFileInfoComplete)(NSDictionary*,NSError*);

@implementation PGFile(FileInfo)

- (void)getFileInfo:(PGMethod *)command{
    NSString * cbId = [command.arguments objectAtIndex:0];
    NSDictionary* options = [command.arguments objectAtIndex:1];
    NSString *filePath = [PGPluginParamHelper getStringValueInDict:options forKey:@"filePath" defalut:nil];
    BOOL md5 = YES;
    NSString *digestAlgorithm = [PGPluginParamHelper getStringValueInDict:options forKey:@"digestAlgorithm" defalut:nil];
    if ( digestAlgorithm && NSOrderedSame == [digestAlgorithm caseInsensitiveCompare:@"sha1"] ) {
        md5 = NO;
    }
    filePath = [PTPathUtil h5Path2SysPath:filePath basePath:self.JSFrameContext.baseURL context:self.appContext];
    
    NSError *error = nil;
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if ( attributes && !error ) {
        unsigned long long fileSize = [attributes fileSize];
        [PDRCore runInBackgroudConcurrent:^{
            NSString *result = nil;
            if ( md5 ) {
                result = [self fileMD5HashWithPath:(CFStringRef)filePath];
            } else {
                result = [self fileSha1HashWithPath:(CFStringRef)filePath];
            }
            [PDRCore runInMainThread:^{
                [self toSucessCallback:cbId withJSON:@{@"digest":result, @"size":@(fileSize)}];
            }];
        }];
    } else {
        [self toErrorCallback:cbId withNSError:error];
    }
}

- (void)getAudioInfo:(PGMethod *)command {
    NSString * cbId = [command.arguments objectAtIndex:0];
    NSDictionary* options = [command.arguments objectAtIndex:1];
    NSString *filePath = [PGPluginParamHelper getStringValueInDict:options forKey:@"filePath" defalut:nil];
    filePath = [PTPathUtil h5Path2SysPath:filePath basePath:self.JSFrameContext.baseURL context:self.appContext];
    
    [self getMeidaFileInfoWithPath:filePath complete:^(NSDictionary*info, NSError* error ){
        [PDRCore runInMainThread:^{
            if ( error ) {
                [self toErrorCallback:cbId withSDKNSError:error];
            } else {
                [self toSucessCallback:cbId withJSON:info?:@{}];
            }
        }];
    }];
}

- (void)getVideoInfo:(PGMethod *)command {
    [self getAudioInfo:command];
}


-(void)getMeidaFileInfoWithPath:(NSString*)filePath complete:(GetFileInfoComplete)block1{
    //取得音频数据
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    [asset loadValuesAsynchronouslyForKeys:@[@"availableMetadataFormats", @"duration",@"tracks"] completionHandler:^{
        NSMutableDictionary *mediaInfos = [NSMutableDictionary dictionary];
        NSError *error=nil;
        AVKeyValueStatus durationState = [asset statusOfValueForKey:@"duration" error:&error];
        if ( AVKeyValueStatusLoaded == durationState ) {
            Float64 duraiton = ceil(CMTimeGetSeconds(asset.duration));
            [mediaInfos setObject:@(duraiton) forKey:@"duration"];
            
            AVKeyValueStatus state=[asset statusOfValueForKey:@"availableMetadataFormats" error:&error];
            if ( AVKeyValueStatusLoaded == state ) {
                for (NSString *format in [asset availableMetadataFormats]) {
                    NSMutableDictionary *metadatas = [NSMutableDictionary dictionary];
                    for (AVMetadataItem *metadataItem in [asset metadataForFormat:format]) {
                        id value = metadataItem.value;
                        if ( [value isKindOfClass:[NSString class]] && metadataItem.commonKey ) {
                            [metadatas setObject:value forKey:metadataItem.commonKey];
                        }
                    }
                    if ( [metadatas count] ) {
                        [mediaInfos setObject:metadatas forKey:format];
                    }
                }
            }// end of if ( AVKeyValueStatusLoaded == state ) {
            
            NSInteger fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil].fileSize;
            [mediaInfos setObject:@(fileSize) forKey:@"size"];
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if([tracks count] > 0) {
                AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
                [mediaInfos setObject:@(videoTrack.naturalSize.width) forKey:g_pdr_string_width];
                [mediaInfos setObject:@(videoTrack.naturalSize.height) forKey:g_pdr_string_height];
                [mediaInfos setObject:[NSString stringWithFormat:@"%d*%d", (int)videoTrack.naturalSize.width, (int)videoTrack.naturalSize.height] forKey:@"resolution"];
            }
            block1(mediaInfos, nil);
        } else {
            block1(nil, error);
        }
    }];
}

@end

