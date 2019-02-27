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
 *	number	author	modify date  modify record
 *   0       xty     2013-01-11  创建文件
 *------------------------------------------------------------------
 */
#import <MobileCoreServices/MobileCoreServices.h>
#include <sys/stat.h>
#include <dirent.h>

#import "PGIO.h"
#import "NSData+Base64.h"
#import "PTPathUtil.h"
#import "PDRCoreAppInfo.h"
#import "PDRCoreAppWindow.h"
#import "PDRCoreWindowManager.h"
#import "PDRCommonString.h"

@implementation PGFile

@synthesize privateWWW;
@synthesize privateDocuments;
@synthesize publicDocuments;
@synthesize publicDownloads;

- (PGPlugin*) initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp*)app
{
    if ( self = [super initWithWebView:theWebView withAppContxt:app] ){
        // get the documents directory path
        PDRCoreApp *application = self.appContext;
        //DIR_PRIVATE_WWW
        self.privateWWW = application.appInfo.wwwPath;
        //DIR_PRIVATE_DOCUMENTS
        self.privateDocuments = application.appInfo.documentPath;
        //DIR_PUBLIC_DOCUMENTS
        self.publicDocuments = [PTPathUtil runtimeDocumentPath];
        //DIR_PUBLIC_DOWNLOADS
        self.publicDownloads = [PTPathUtil runtimeDownloadPath];
    }
    return self;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      请求文件系统
 * @Parameters:
 *      command 
 *       [callbackid,[type]] 
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) requestFileSystem:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] )
    {
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    // arguments
    NSArray *args = [command.arguments objectAtIndex:1];
    NSNumber *typeJS = [args objectAtIndex:0];
    int type = 1;
    if ( [typeJS isKindOfClass:[NSNumber class]] ) {
        type = [typeJS intValue];
    }

    PDRPluginResult *result = nil;
	
    NSString *fullPath = nil;
    if ( 1 == type  ){ //privateWWW
        fullPath = self.privateWWW;
    } else if( 2 == type ){ //privateDocument
        fullPath = self.privateDocuments;
    } else if( 3 == type ){ //publicDocument
        fullPath = self.publicDocuments;
    } else if( 4 == type ){ //publicDownloads
        fullPath = self.publicDownloads;
    }
    
    //如果未找到语法错误
    if ( !fullPath ) {
        result = [PDRPluginResult resultWithStatus: PDRCommandStatusError
                              messageToErrorObject:PGFileErrorSyntax
                                       withMessage:[self getErrorMeassge:PGFileErrorSyntax] ];
        [self toCallback:callbackId withReslut:[result toJSONString]];
    } else {
        NSMutableDictionary* fileSystem = [NSMutableDictionary dictionaryWithCapacity:2];
        if ( 1 == type  ){ //privateWWW
            [fileSystem setObject:kPDRFileSystemPrivateWWW forKey:@"name"];
        } else if( 2 == type ){ //privateDocument
            [fileSystem setObject:kPDRFileSystemPrivateDocumnets forKey:@"name"];
        } else if( 3 == type ){ //publicDocument
            [fileSystem setObject:kPDRFileSystemPublicDocumnets forKey:@"name"];
        } else if( 4 == type ){ //publicDownloads
            [fileSystem setObject:kPDRFileSystemPublicDownloads forKey:@"name"];
        }
        NSDictionary* dirEntry = [self getDirectoryEntry: fullPath isDirectory: YES];
        [fileSystem setObject:dirEntry forKey:@"root"];
        result = [PDRPluginResult resultWithStatus: PDRCommandStatusOK messageAsDictionary: fileSystem];
        [self toCallback:callbackId withReslut:[result toJSONString]];
        return;
    }
}

- (int)getFSTypeWithRPath:(NSString*)path {
    if ( [path hasPrefix:g_pdr_string__www] ) {
        return 1;
    } else if ( [path hasPrefix:g_pdr_string__doc] ) {
        return 2;
    } else if ( [path hasPrefix:g_pdr_string__documents] ) {
        return 3;
    } else if ( [path hasPrefix:g_pdr_string__downloads] ) {
        return 4;
    }
    return 0;
}

- (int)getFSTypeWithAPath:(NSString*)path {
    if ( [path hasPrefix:self.privateWWW] ) {
        return 1;
    } else if ( [path hasPrefix:self.privateDocuments] ) {
        return 2;
    } else if ( [path hasPrefix:self.publicDocuments] ) {
        return 3;
    } else if ( [path hasPrefix:self.publicDownloads] ) {
        return 4;
    }
    return 0;
}

- (NSString*)getFSTypeRoot:(int)type {
    switch (type) {
        case 1:
            return self.privateWWW;
            break;
        case 2:
            return self.privateDocuments;
            break;
        case 3:
            return self.publicDocuments;
            break;
        case 4:
            return self.publicDownloads;
            break;
        default:
            break;
    }
    return nil;
}


- (NSString*)getFSTypeName:(int)type {
    switch (type) {
        case 1:
            return kPDRFileSystemPrivateWWW;
            break;
        case 2:
            return kPDRFileSystemPrivateDocumnets;
            break;
        case 3:
            return kPDRFileSystemPublicDocumnets;
            break;
        case 4:
            return kPDRFileSystemPublicDownloads;
            break;
        default:
            break;
    }
    return @"Unkown File System";
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *     根据给定的URL获取关联的fileentry对象
 * @Parameters:
 *      command
 *       [callbackid,[fileURL]]
 *       NSString* fileURI  - currently requires full file URI
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */

- (void)resolveLocalFileSystemURL:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSArray *args = [command.arguments objectAtIndex:1];
    NSString* inputUri = [args objectAtIndex:0];
    NSString *path = nil;
    PDRPluginResult* result = nil;
    
    if ( [inputUri length] == 0) {
        // issue ENCODING_ERR
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:PGFileErrorEncoding
                                       withMessage:[self getErrorMeassge:PGFileErrorEncoding]];
        [self toCallback:callbackId withReslut:[result toJSONString]];
        return;
    }
    
    if ('_' == [inputUri characterAtIndex:0] ) {
        path = [PTPathUtil absolutePath:inputUri withContext:self.appContext];
    } else {
        NSString* cleanUri = [inputUri stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* strUri = [cleanUri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL* testUri = [NSURL URLWithString:strUri];
        
        if ( testUri ) {
            NSString *relativeString = [testUri relativePath];
            if ( [relativeString length] > 1 ) {
                if ( ![testUri isFileURL] ) {
                    path = [relativeString substringFromIndex:1];
                    path = [PTPathUtil absolutePath:path withContext:self.appContext];
                } else {
                    if ( ![self allowRead:relativeString] ) {
                        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                              messageToErrorObject:PGFileErrorNotReadable
                                                       withMessage:[self getErrorMeassge:PGFileErrorNotReadable]];
                        [self toCallback:callbackId withReslut:[result toJSONString]];
                        return;
                    }
                    path = relativeString;
                }
            }
        }
    }
    
   // if (!testUri || ![testUri isFileURL]) {
    if (!path ) {
        // issue ENCODING_ERR
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:PGFileErrorEncoding
                                       withMessage:[self getErrorMeassge:PGFileErrorEncoding]];
        [self toCallback:callbackId withReslut:[result toJSONString]];
        return;
    } else {
        NSFileManager* fileMgr = [NSFileManager defaultManager];
       // NSString* path = [testUri path];
        // NSLog(@"url path: %@", path);
        BOOL isDir = NO;
        if ( ![self allowRead:path] ) {
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK
                                  messageToErrorObject:PGFileErrorNotReadable
                                           withMessage:[self getErrorMeassge:PGFileErrorNotReadable]];
            [self toCallback:callbackId withReslut:[result toJSONString]];
        }
        // see if exists and is file or dir
        BOOL bExists = [fileMgr fileExistsAtPath:path isDirectory:&isDir];
        if (bExists) {
            int type = [self getFSTypeWithAPath:path];
            NSString *fsName = [self getFSTypeName:type];
            NSString *fsRootPath = [self getFSTypeRoot:type];
            NSDictionary* fileSystem = [self getDirectoryEntry:path isDirectory:isDir];
            NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:fileSystem];
            [entry setObject:[NSNumber numberWithInt:type] forKey:@"type"];
            [entry setObject:fsName forKey:@"fsName"];
            if ( fsRootPath ) {
                NSDictionary* fsEntry = [self getDirectoryEntry:fsRootPath?fsRootPath:@"" isDirectory: YES];
                [entry setObject:fsEntry?fsEntry:@{} forKey:@"fsRoot"];
            }
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:entry];
            [self toCallback:callbackId withReslut:[result toJSONString]];
        } else {
            // return NOT_FOUND_ERR
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                  messageToErrorObject:PGFileErrorNotFound
                                           withMessage:[self getErrorMeassge:PGFileErrorNotFound]];
            [self toCallback:callbackId withReslut:[result toJSONString]];
        }
    }
}

- (NSData*) convertLocalFileSystemURL:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return [self resultWithString:@""];
    }
    NSString *localUrl = [command.arguments objectAtIndex:0];
    
    if ( [localUrl isKindOfClass:[NSString class]] ) {
        NSString *systemUrl = [PTPathUtil h5Path2SysPath:localUrl
                                                basePath:self.JSFrameContext.baseURL
                                                 context:self.appContext];
        if ( systemUrl ) {
            return [self resultWithString:systemUrl];
        }
    }
    return [self resultWithNull];
}

- (NSData*) convertAbsoluteFileSystem:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return [self resultWithString:@""];
    }
    NSString *systemUrl = [command.arguments objectAtIndex:0];
    
    if ( [systemUrl isKindOfClass:[NSString class]] ) {
        NSString *localUrl = [PTPathUtil relativePath:systemUrl withContext:self.appContext];
        if ( localUrl ) {
            return [self resultWithString:localUrl];
        }
    }
    return [self resultWithNull];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *    测试是否移动或copy到自身
 * @Parameters:
 *  [1] command 命令参数
 *  [2] bCopy true 拷贝 false 删除
 * @Returns:
 *    无
 * @Remark:
 * Copy /Documents/myDir to /Documents/myDir-backup is OK but
 * Copy /Documents/myDir to /Documents/myDir/backup not OK
 * @Changelog:
 *------------------------------------------------------------------
 */
-(BOOL) canCopyMoveSrc: (NSString*) src ToDestination: (NSString*) dest
{
    BOOL copyOK = YES;
    NSRange range = [dest rangeOfString:src];
    
    if (range.location != NSNotFound) {
        NSRange testRange = {range.length-1, ([dest length] - range.length)};
        NSRange resultRange = [dest rangeOfString: @"/" options: 0 range: testRange];
        if (resultRange.location != NSNotFound){
            copyOK = NO;
        }
    }
    return copyOK;
}
/*
 *------------------------------------------------------------------
 * @Summary:
 *     执行实际的拷贝和移动操作
 * @Parameters:
 *  [1] command 命令参数
 *  [2] bCopy true 拷贝 false 删除
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) doCopyMove:(PGMethod*)command isCopy:(BOOL)bCopy
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    
    NSString  *callbackId = [command.arguments objectAtIndex:0];
    NSArray   *args = [command.arguments objectAtIndex:1];
    
    NSString *srcFullPath = [args objectAtIndex:0];
    NSString *destRootPath = [args objectAtIndex:1];
    NSString *newName = [args objectAtIndex:2];
    PGFileError errCode = PGFileErrorNO;
    PDRPluginResult *result = nil;
    
    if ( ![destRootPath isKindOfClass:[NSString class]]
        || ![srcFullPath isKindOfClass:[NSString class]]
        || ![newName isKindOfClass:[NSString class]]){
		errCode = PGFileErrorNotFound;
	} else {
		NSString* newFullPath = [destRootPath stringByAppendingPathComponent: newName];
        
        if ( ! [self allowWrite:newFullPath]
            || (!bCopy && ![self allowWrite:srcFullPath])) {
            errCode = PGFileErrorNoModificationAllowed;
        }
        if ( ![self allowRead:srcFullPath]) {
            errCode = PGFileErrorNotReadable;
        }
        if ( PGFileErrorNO == errCode ) {
            // source and destination can not be the same
            if ( [newFullPath isEqualToString:srcFullPath] ){
                errCode = PGFileErrorInvalidModification;
            }
            else{
                NSFileManager* fileMgr = [NSFileManager defaultManager];
                
                BOOL bSrcIsDir = NO;
                BOOL bDestIsDir = NO;
                BOOL bNewIsDir = NO;
                BOOL bSrcExists = [fileMgr fileExistsAtPath: srcFullPath isDirectory: &bSrcIsDir];
                BOOL bDestExists= [fileMgr fileExistsAtPath: destRootPath isDirectory: &bDestIsDir];
                BOOL bNewExists = [fileMgr fileExistsAtPath:newFullPath isDirectory: &bNewIsDir];
                if (!bSrcExists || !bDestExists){// 源或目标不存在
                    errCode = PGFileErrorNotFound;
                } else if (bSrcIsDir && (bNewExists && !bNewIsDir)){//目录文件不能互考
                    errCode = PGFileErrorInvalidModification;
                } else { // no errors yet
                    NSError* __autoreleasing error = nil;
                    BOOL bSuccess = NO;
                    if ( bCopy ){
                        if ( bSrcIsDir && ![self canCopyMoveSrc: srcFullPath ToDestination: newFullPath]){
                            errCode = PGFileErrorInvalidModification;
                        } else if ( bNewExists ){
                            errCode = PGFileErrorPathExists;
                        } else {
                            bSuccess = [fileMgr copyItemAtPath: srcFullPath toPath: newFullPath error: &error];
                        }
                    }
                    else
                    { // move
                        if (!bSrcIsDir && (bNewExists && bNewIsDir)){ //如何目标存在并且有内容
                            errCode = PGFileErrorInvalidModification;
                        } else if (bSrcIsDir && ![self canCopyMoveSrc: srcFullPath ToDestination: newFullPath] ) {//源和目标不能相同
                            errCode = PGFileErrorInvalidModification;
                        } else if (bNewExists) {
                            if (bNewIsDir && 0 != [[fileMgr contentsOfDirectoryAtPath:newFullPath error: NULL] count]){
                                errCode = PGFileErrorInvalidModification;
                                newFullPath = nil;
                            } else {
                                bSuccess = [fileMgr removeItemAtPath:newFullPath error: NULL];
                                if (!bSuccess){
                                    errCode = PGFileErrorInvalidModification;
                                    newFullPath = nil;
                                }
                            }
                        } else if (bNewIsDir && [newFullPath hasPrefix:srcFullPath]){
                            //不能把一个目录移动到他的子目录或者
                            errCode = PGFileErrorInvalidModification;
                            newFullPath = nil;
                        }
                        
                        if (newFullPath != nil) {
                            bSuccess = [fileMgr moveItemAtPath: srcFullPath toPath: newFullPath error: &error];
                        }
                    }
                    if (bSuccess) {
                        //返回entry
                        NSDictionary* newEntry = [self getDirectoryEntry: newFullPath isDirectory:bSrcIsDir];
                        result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary: newEntry];
                        [self toCallback:callbackId withReslut:[result toJSONString]];
                        return;
                    } else { //不成功获取错误码
                        errCode = PGFileErrorInvalidModification;
                        if (error){
                            if ([error code] == NSFileReadUnknownError || [error code] == NSFileReadTooLargeError){
                                errCode = PGFileErrorNotReadable;
                            } else if ([error code] == NSFileWriteOutOfSpaceError) {
                                errCode = PGFileErrorQuotaExeeded;
                            } else if ([error code] == NSFileWriteNoPermissionError) {
                                errCode = PGFileErrorNoModificationAllowed;;
                            }
                        }
                    }
                }
            }
        }
	}
    //如果错误
	if (errCode > 0)
    {
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:errCode
                                       withMessage:[self getErrorMeassge:errCode]];
        [self toCallback:callbackId withReslut:[result toJSONString]];
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      删除文件或目录
 * @Parameters:
 *  [1] fullPath 要删除的目标路径
 *  [2] callbackId 回调的ID
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) doRemove:(NSString*)fullPath callback: (NSString*)callbackId
{
	BOOL bSuccess = NO;
	NSError* __autoreleasing pError = nil;
	NSFileManager* fileMgr = [NSFileManager defaultManager];
    PDRPluginResult *result = nil;
	@try {
		bSuccess = [ fileMgr removeItemAtPath:fullPath error:&pError];
		if (bSuccess) {
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK];
            [self toCallback:callbackId withReslut:[result toJSONString]];
		} else {
			// see if we can give a useful error
			PGFileError errorCode = PGFileErrorAbort;
			//NSLog(@"error getting metadata: %@", [pError localizedDescription]);
			if ([pError code] == NSFileNoSuchFileError) {
				errorCode = PGFileErrorNotFound;
			} else if ([pError code] == NSFileWriteNoPermissionError) {
				errorCode = PGFileErrorNoModificationAllowed;
			}
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                  messageToErrorObject:errorCode
                                           withMessage:[self getErrorMeassge:errorCode]];
            [self toCallback:callbackId withReslut:[result toJSONString]];
		}
	} @catch (NSException* e) {
        //在这里认为路径写错
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:PGFileErrorSyntax
                                       withMessage:[self getErrorMeassge:PGFileErrorSyntax]];
		[self toCallback:callbackId withReslut:[result toJSONString]];
	}
	@finally {
	}
}

#pragma mark Tool
#pragma mark------------------------

-(NSString*)getErrorMeassge:(PGFileError)errorCode {
    switch (errorCode) {
        case PGFileErrorNotFound:
            return @"文件没有发现";
            break;
        case PGFileErrorSecurity:
            return @"没有获得授权";
            break;
        case PGFileErrorAbort:
            return @"取消";
            break;
        case PGFileErrorNotReadable:
            return @"不允许读";
            break;
        case PGFileErrorEncoding:
            return @"编码错误";
            break;
        case PGFileErrorNoModificationAllowed:
            return @"不允许修改";
            break;
        case PGFileErrorInvalidState:
            return @"无效的状态";
            break;
        case PGFileErrorSyntax:
            return @"语法错误";
            break;
        case PGFileErrorInvalidModification:
            return @"无效的修改";
            break;
        case PGFileErrorQuotaExeeded:
            return @"执行出错";
            break;
        case PGFileErrorTypeMismatch:
            return @"类型不匹配";
            break;
        case PGFileErrorPathExists:
            return @"路径存在";
            break;
        case PGFileErrorDirNotEmpty:
            return @"目录不为空";
        default:
            break;
    }
    return @"未知错误";
}

- (BOOL)allowRead:(NSString*)path {
    NSString *standPath = [PTPathUtil standardizingPath:path];
    if ( [standPath hasPrefix:self.privateWWW]
        || [standPath hasPrefix:self.privateDocuments]
        || [standPath hasPrefix:self.publicDocuments]
        || [standPath hasPrefix:self.publicDownloads]) {
        return TRUE;
    }
    return FALSE;
}

- (BOOL)allowWrite:(NSString*)path {
    NSString *standPath = [PTPathUtil standardizingPath:path];
    if (([standPath hasPrefix:self.privateDocuments]
         && NSOrderedSame != [standPath compare:self.privateDocuments])
        || ([standPath hasPrefix:self.publicDocuments]
            && NSOrderedSame != [standPath compare:self.publicDocuments])
        || ([standPath hasPrefix:self.publicDownloads]
            && NSOrderedSame != [standPath compare:self.publicDownloads])) {
        return TRUE;
    }
    return FALSE;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      封装Entry对象的JSON数据
 * @Parameters:
 *  [1] fullPath 全路径
 *  [2] isDir 是否是目录
 *  [3] callbackId 回调的ID
 * @Returns:
 *    NSDictionary *dict JSON对象化表示
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(NSDictionary*) getDirectoryEntry: (NSString*) fullPath  isDirectory: (BOOL) isDir
{
	NSMutableDictionary* dirEntry = [NSMutableDictionary dictionaryWithCapacity:4];
	NSString* lastPart = [fullPath lastPathComponent];
	[dirEntry setObject:[NSNumber numberWithBool: !isDir]  forKey:@"isFile"];
	[dirEntry setObject:[NSNumber numberWithBool: isDir]  forKey:@"isDirectory"];
	//NSURL* fileUrl = [NSURL fileURLWithPath:fullPath];
	//[dirEntry setObject: [fileUrl absoluteString] forKey: @"fullPath"];
    [dirEntry setObject: isDir?[NSString stringWithFormat:@"%@/", fullPath]:fullPath forKey: @"fullPath"];
    NSString *relative = [PTPathUtil relativePath:fullPath withContext:self.appContext];
    [dirEntry setObject:relative?relative:@"" forKey: @"remoteURL"];
	[dirEntry setObject: lastPart forKey:@"name"];
	return dirEntry;
}

- (void) onAppUpgradesNoClose {
    PDRCoreApp *application = self.appContext;
    //DIR_PRIVATE_WWW
    self.privateWWW = application.appInfo.wwwPath;
    //DIR_PRIVATE_DOCUMENTS
    self.privateDocuments = application.appInfo.documentPath;
    //DIR_PUBLIC_DOCUMENTS
    self.publicDocuments = [PTPathUtil runtimeDocumentPath];
    //DIR_PUBLIC_DOWNLOADS
    self.publicDownloads = [PTPathUtil runtimeDownloadPath];
    
}

-(void)dealloc
{
    self.privateWWW = nil;
    self.publicDocuments = nil;
    self.privateDocuments = nil;
    self.publicDownloads = nil;
    [super dealloc];
}

@end

#pragma mark Entry
#pragma mark------------------------
@implementation PGFile(Entry)

/**
 *------------------------------------------------------------------
 * @Summary:
 *      获取的相关详细
 * @Parameters:
 *  command [callbackId, [this.path]]
 *  0 - NSString* file path to get metadata
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) getMetadata:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSArray *arguments = [command.arguments objectAtIndex:1];
    // arguments
	NSString* argPath = [arguments objectAtIndex:0];
    NSNumber *recursiveV = [arguments objectAtIndex:1];
    BOOL recursive = FALSE;
    if ( [recursiveV isKindOfClass:[NSNumber class]] ) {
        recursive = [recursiveV boolValue];
    }
    
	NSString* testPath = argPath; //[self getFullPath: argPath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        long long dirCount = 0;
        long long fileCount = 0;
        long long size = [PTFSUtil folderSizeAtPath:testPath deep:recursive dirCount:&dirCount fileCount:&fileCount];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSFileManager* fileMgr = [NSFileManager defaultManager];
            NSError* __autoreleasing error = nil;
            PDRPluginResult * result = nil;
            
            NSDictionary* fileAttribs = [fileMgr attributesOfItemAtPath:testPath error:&error];
            
            if (fileAttribs){
                NSDate* modDate = [fileAttribs fileModificationDate];
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                [dict setObject:[NSNumber numberWithDouble:[modDate timeIntervalSince1970]*1000] forKey:@"lastModifiedDate"];
                [dict setObject:[NSNumber numberWithLongLong:size]  forKey:@"size"];
                [dict setObject:[NSNumber numberWithLongLong:dirCount] forKey:@"directoryCount"];
                [dict setObject:[NSNumber numberWithLongLong:fileCount] forKey:@"fileCount"];
                
                if (modDate){
                    result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
                    [self toCallback:callbackId withReslut:[result toJSONString]];
                    return;
                }
            } else {
                PGFileError errorCode = PGFileErrorAbort;
                if ([error code] == NSFileNoSuchFileError) {
                    errorCode = PGFileErrorNotFound;
                }
                // log [NSNumber numberWithDouble: theMessage] objCtype to see what it returns
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                      messageToErrorObject: errorCode
                                               withMessage:[self getErrorMeassge:errorCode]];
                [self toCallback:callbackId withReslut:[result toJSONString]];
            }
        });
    });
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *      移动文件或目录
 * @Parameters:
 *  command [callbackId, [this.path]]
 *  0 - NSString* file path to get metadata
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)moveTo:(PGMethod*)command
{
    [self doCopyMove:command isCopy:NO];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      拷贝文件或目录
 * @Parameters:
 *      command
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)copyTo:(PGMethod*)command
{
    [self doCopyMove:command isCopy:YES];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      删除文件或目录
 * @Parameters:
 *      command
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)remove:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString  *callbackId = [command.arguments objectAtIndex:0];
    NSArray   *args = [command.arguments objectAtIndex:1];
    NSString *fullPath = [args objectAtIndex:0];
    PDRPluginResult *result = nil;
	PGFileError errorCode = PGFileErrorNO;
    
    //顶层目录不准许删除
    //WWW目录不允许删除
	if (![self allowWrite:fullPath]) {
		errorCode = PGFileErrorNoModificationAllowed;
	} else {
		NSFileManager* fileMgr = [ NSFileManager defaultManager];
		BOOL bIsDir = NO;
		BOOL bExists = [fileMgr fileExistsAtPath:fullPath isDirectory: &bIsDir];
		if (!bExists){
			errorCode = PGFileErrorNotFound;
		}
        if (bIsDir &&  [[fileMgr contentsOfDirectoryAtPath:fullPath error: nil] count] != 0){
			// dir is not empty
			errorCode = PGFileErrorDirNotEmpty;
		}
	}
	if (errorCode > 0){
		result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject: errorCode withMessage:[self getErrorMeassge:errorCode]];
        [self toCallback:callbackId withReslut:[result toJSONString]];
	}
    else{
		// perform actual remove
		[self doRemove: fullPath callback: callbackId];
	}
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      删除文件或目录
 * @Parameters:
 *      command
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) getParent:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString  *callbackId = [command.arguments objectAtIndex:0];
    NSArray   *args = [command.arguments objectAtIndex:1];
    NSString *fullPath = [args objectAtIndex:0];
    PDRPluginResult *result = nil;
    
	NSString* newPath = nil;
	
	if ([fullPath isEqualToString:self.privateDocuments]
        || [fullPath isEqualToString:self.privateWWW]
        || [fullPath isEqualToString:self.publicDocuments]
        || [fullPath isEqualToString:self.publicDownloads]){
		result = [PDRPluginResult resultWithStatus: PDRCommandStatusError
                              messageToErrorObject:PGFileErrorNotReadable withMessage:[self getErrorMeassge:PGFileErrorNotReadable]
                  ];
        [self toCallback:callbackId withReslut:[result toJSONString]];
        return;
	} else {
		NSRange range = [fullPath rangeOfString:@"/" options: NSBackwardsSearch];
		newPath = [fullPath substringToIndex:range.location];
	}
    
	if(newPath){
		NSFileManager* fileMgr = [NSFileManager defaultManager];
		BOOL bIsDir;
		BOOL bExists = [fileMgr fileExistsAtPath: newPath isDirectory: &bIsDir];
		if (bExists) {
			result = [PDRPluginResult resultWithStatus: PDRCommandStatusOK messageAsDictionary: [self getDirectoryEntry:newPath isDirectory:bIsDir]];
            [self toCallback:callbackId withReslut:[result toJSONString]];
            return;
		}
	}
	
    //到这里认为无效吧
    result = [PDRPluginResult resultWithStatus: PDRCommandStatusError
                          messageToErrorObject:PGFileErrorNotFound
                                   withMessage:[self getErrorMeassge:PGFileErrorNotFound]];
	[self toCallback:callbackId withReslut:[result toJSONString]];
}
@end

#pragma mark FileEntry
#pragma mark------------------------
@implementation PGFile(FileEntry)

/**
 *------------------------------------------------------------------
 * @Summary:
 *      获取文件的相关详细
 * @Parameters:
 *  command [callbackId, [this.path]]
 *  0 - NSString* file path to get metadata
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) getFileMetadata:(PGMethod*)command
{
	if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSArray *arguments = [command.arguments objectAtIndex:1];
    // arguments
	NSString* argPath = [arguments objectAtIndex:0];
    
	PDRPluginResult* result = nil;
	
	NSString* fullPath = argPath;
	if (fullPath) {
		NSFileManager* fileMgr = [NSFileManager defaultManager];
		BOOL bIsDir = NO;
		// make sure it exists and is not a directory
		BOOL bExists = [fileMgr fileExistsAtPath:fullPath isDirectory: &bIsDir];
		if(!bExists || bIsDir){
			result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                  messageToErrorObject:PGFileErrorNotFound
                                           withMessage:[self getErrorMeassge:PGFileErrorNotFound]];
            [self toCallback:callbackId withReslut:[result toJSONString]];
		} else {
			// create dictionary of file info
			NSError* error = nil;
			NSDictionary* fileAttrs = [fileMgr attributesOfItemAtPath:fullPath error:&error];
			NSMutableDictionary* fileInfo = [NSMutableDictionary dictionaryWithCapacity:5];
			[fileInfo setObject: [NSNumber numberWithUnsignedLongLong:[fileAttrs fileSize]] forKey:@"size"];
			[fileInfo setObject:argPath forKey:@"fullPath"];
            NSString *mimeType = [PTPathUtil getMimeTypeFromPath:argPath];
			[fileInfo setObject: mimeType? mimeType:@"" forKey:@"type"];
            [fileInfo setObject: [argPath lastPathComponent] forKey:@"name"];
			NSDate* modDate = [fileAttrs fileModificationDate];
			NSNumber* msDate = [NSNumber numberWithDouble:[modDate timeIntervalSince1970]*1000];
			[fileInfo setObject:msDate forKey:@"lastModifiedDate"];
			result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary: fileInfo];
            [self toCallback:callbackId withReslut:[result toJSONString]];
		}
	}
}

@end

#pragma mark DirectoryEntry
#pragma mark------------------------
@implementation PGFile(DirectoryEntry)

/*
 *------------------------------------------------------------------
 * @Summary:
 *      创建或返回指定的文件
 * @Parameters:
 *      command [callbackId, [fullPath, path, option]]
 *      [1] callbackId 回调id
 *      [2] fullPath, 文件的全路径
 *      [3] path 文件返回的路径
 *      [4]NSDictionary* option Flags object
 *            create == true && file not exist -> create file and return File entry
 *            create == true && file does not exist -> create file and return File entry
 *            create == true && exclusive true && file does exist -> return error
 *            create == false && file does not exist -> return error
 *
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) getDirectory:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    [self getCommon:command.arguments isDir:YES];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      创建或返回指定的文件
 * @Parameters:
 *      command [callbackId, [fullPath, path, option]]
 *      [1] callbackId 回调id
 *      [2] fullPath, 文件的全路径
 *      [3] path 文件返回的路径
 *      [4]NSDictionary* option Flags object
 *            create == true && file not exist -> create file and return File entry
 *            create == true && file does not exist -> create file and return File entry
 *            create == true && exclusive true && file does exist -> return error
 *            create == false && file does not exist -> return error
 *
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)getCommon:(NSArray*)command isDir:(BOOL)bDir
{
    NSString  *callbackId = [command objectAtIndex:0];
    NSArray   *arguments = [command objectAtIndex:1];
    
	NSString* fullPath = [arguments objectAtIndex:0];
	NSString* requestedPath = [arguments objectAtIndex:1];
    NSDictionary* options = [arguments objectAtIndex:2 ];
    
	PDRPluginResult* result = nil;
	BOOL bDirRequest = NO;
	BOOL create = NO;
	BOOL exclusive = NO;
	PGFileError errorCode = PGFileErrorNO;
	
    // 可选参数
    if ( [options isKindOfClass:[NSDictionary class]] ) {
        if ([[options valueForKey:@"create"] isKindOfClass:[NSNumber class]]) {
            create = [(NSNumber*)[options valueForKey: @"create"] boolValue];
        }
        if ([[options valueForKey:@"exclusive"] isKindOfClass:[NSNumber class]]) {
            exclusive = [(NSNumber*)[options valueForKey: @"exclusive"] boolValue];
        }
        //该标记为代码中添加为了代码复用不在规范中
        bDirRequest = bDir;
    }
    
    NSRange range = [requestedPath rangeOfString:fullPath];
    BOOL bIsFullPath = range.location != NSNotFound;
    
    NSString* reqFullPath = nil;
    
    if (!bIsFullPath) {
        reqFullPath = [fullPath stringByAppendingPathComponent:requestedPath];
    } else {
        reqFullPath = requestedPath;
    }
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    BOOL bIsDir;
    BOOL bExists = [fileMgr fileExistsAtPath: reqFullPath isDirectory: &bIsDir];
    if (bExists && create == NO && bIsDir == !bDirRequest) {
        errorCode = PGFileErrorTypeMismatch;
    } else if (!bExists && create == NO) {
        errorCode = PGFileErrorNotFound;
    } else if (bExists && create == YES && exclusive == YES) {
        errorCode = PGFileErrorPathExists;
    } else {
        // if bExists and create == YES - just return data
        // if bExists and create == NO  - just return data
        // if !bExists and create == YES - create and return data
        BOOL bSuccess = YES;
        NSError __autoreleasing *pError = nil;
        
        if ( ![self allowRead:reqFullPath] ) {
            errorCode = PGFileErrorNotReadable;
        } else {
            if(!bExists && create == YES){
                if ( ![self allowWrite:reqFullPath] ) {
                    errorCode = PGFileErrorNoModificationAllowed;
                    bSuccess = NO;
                } else {
                    if(bDirRequest) {
                        // create the dir
                        bSuccess = [ fileMgr createDirectoryAtPath:reqFullPath withIntermediateDirectories:YES attributes:nil error:&pError];
                        if ( !bSuccess ) {
                            errorCode = PGFileErrorAbort;
                        }
                    } else {
                        // create the empty file
                        NSString *fatherPath = [reqFullPath stringByDeletingLastPathComponent];
                        if ( ![fileMgr fileExistsAtPath:fatherPath isDirectory:nil] ) {
                            [ fileMgr createDirectoryAtPath:fatherPath withIntermediateDirectories:YES attributes:nil error:&pError];
                        }
                        bSuccess = [ fileMgr createFileAtPath:reqFullPath contents: nil attributes:nil];
                        if ( !bSuccess ) {
                            errorCode = PGFileErrorAbort;
                        }
                    }
                }
            }
            if(!bSuccess){
                if (pError) {
                    NSLog(@"error creating directory: %@", [pError localizedDescription]);
                }
            } else {
                // file or dict existed or was created
                result = [PDRPluginResult resultWithStatus: PDRCommandStatusOK messageAsDictionary: [self getDirectoryEntry: reqFullPath isDirectory: bDirRequest]];
                [self toCallback:callbackId withReslut:[result toJSONString]];
                return;
            }
        }
    }
	
	if (errorCode > 0) {
		// create error callback
		result = [PDRPluginResult resultWithStatus: PDRCommandStatusError
                              messageToErrorObject:errorCode
                                       withMessage:[self getErrorMeassge:errorCode]];
        [self toCallback:callbackId withReslut:[result toJSONString]];
	}
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      创建或返回指定的文件
 * @Parameters:
 *      command [callbackId, [fullPath, path, option]]
 *      [1] callbackId 回调id
 *      [2] fullPath, 文件的全路径 
 *      [3] path 文件返回的路径
 *      [4]NSDictionary* option Flags object
 *            create == true && file not exist -> create file and return File entry
 *            create == true && file does not exist -> create file and return File entry
 *            create == true && exclusive true && file does exist -> return error
 *            create == false && file does not exist -> return error
 *
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) getFile:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    [self getCommon:command.arguments isDir:NO];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      移走自定的目录
 * @Parameters:
 *      command [callbackId, [fullPath]]
 *      [1] callbackId 回调id
 *      [2] fullPath, 文件的全路径
 *
 * @Returns:
 *    NO_MODIFICATION_ALLOWED_ERR  if is top level directory or no permission to delete dir
 *    NOT_FOUND_ERR if file or dir is not found
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) removeRecursively:(PGMethod*)command
{
    if ( !command.arguments
       && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSArray *arguments = [command.arguments objectAtIndex:1];
	NSString* fullPath = [arguments objectAtIndex:0];

	
	PDRPluginResult* result = nil;
    NSString *standPath = [fullPath stringByStandardizingPath];
    if ( NSOrderedSame == [standPath caseInsensitiveCompare:self.publicDocuments]
        || NSOrderedSame == [standPath caseInsensitiveCompare:self.publicDownloads]
        || NSOrderedSame == [standPath caseInsensitiveCompare:self.privateDocuments] ) {
        [self doRemove: fullPath callback: callbackId];
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        return;
    }
	// error if try to remove top level (documents or tmp) dir
	if ( ![self allowWrite:fullPath] ) {
		result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                      messageToErrorObject: PGFileErrorNoModificationAllowed
                                       withMessage:[self getErrorMeassge:PGFileErrorNoModificationAllowed]];
		[self toCallback:callbackId withReslut:[result toJSONString]];
	} else {
		[self doRemove: fullPath callback: callbackId];
	}
}

@end

#pragma mark FileReader
#pragma mark------------------------
@implementation PGFile(FileReader)

/*
 *------------------------------------------------------------------
 * @Summary:
 *      写入文件数据
 * @Parameters:
 *  command [callbackId, [fullpath, encoding]]
 *  0 - NSString* fullPath
 *	1 - NSString* encoding - NOT USED,  iOS reads and writes using UTF8!
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) readAsText:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSArray *arguments = [command.arguments objectAtIndex:1];
	NSString* argPath = [arguments objectAtIndex:0];
    NSNumber* start  = [arguments objectAtIndex:2];
    NSNumber* end = [arguments objectAtIndex:3];
   // NSString* encoding = [arguments objectAtIndex:1];
    
    PGFileError errCode =  PGFileErrorNotReadable;
	PDRPluginResult* result = nil;
    
	NSFileHandle* file = [ NSFileHandle fileHandleForReadingAtPath:argPath];
	if(!file){
		// invalid path entry
        errCode = PGFileErrorNotFound;
	} else {
        NSData* readData = nil;
        if ( [start isKindOfClass:[NSNumber class]]
            && [end isKindOfClass:[NSNumber class]] ) {
            NSInteger s = [start integerValue];
            NSInteger e = [end integerValue];
            NSInteger l = e-s;
            [file seekToFileOffset:s];
            readData = [ file readDataOfLength:l==0?1:l+1];
        } else {
            readData = [file readDataToEndOfFile];
        }
        
		[file closeFile];
        NSString* pNStrBuff = nil;
		if (readData) {
            pNStrBuff = [[[NSString alloc] initWithBytes: [readData bytes] length: [readData length] encoding: NSUTF8StringEncoding] autorelease];
        } else {
            // return empty string if no data
            pNStrBuff = @"";
        }
        
        if ( pNStrBuff ) {
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:pNStrBuff ];
            [self toCallback:callbackId withReslut:[result toJSONString]];
            return;
        } else {
            errCode = PGFileErrorEncoding;
        }
	}
	result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:errCode
                                   withMessage:[self getErrorMeassge:errCode]];
    [self toCallback:callbackId withReslut:[result toJSONString]];
    return;
}

- (void) readAsDataURL:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSArray *arguments = [command.arguments objectAtIndex:1];
	NSString* argPath = [arguments objectAtIndex:0];
    NSNumber* start  = [arguments objectAtIndex:1];
    NSNumber* end = [arguments objectAtIndex:2];
    
	PGFileError errCode = PGFileErrorAbort;
	PDRPluginResult* result = nil;

	if(!argPath){
		errCode = PGFileErrorSyntax;
	} else {
		NSString* mimeType = [PTPathUtil getMimeTypeFromPath:argPath];
		if (!mimeType) {
			// can't return as data URL if can't figure out the mimeType
			errCode = PGFileErrorEncoding;
		} else {
			NSFileHandle* file = [ NSFileHandle fileHandleForReadingAtPath:argPath];
            NSData* readData = nil;
            if ( [start isKindOfClass:[NSNumber class]]
                && [end isKindOfClass:[NSNumber class]] ) {
                NSInteger s = [start integerValue];
                NSInteger e = [end integerValue];
                NSInteger l = e-s;
                [file seekToFileOffset:s];
                readData = [ file readDataOfLength:l==0?1:l+1];
            } else {
                readData = [file readDataToEndOfFile];
            }
			[file closeFile];
			if (readData) {
				NSString* output = [NSString stringWithFormat:@"data:%@;base64,%@", mimeType, [readData base64EncodedString]];
				result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString: output];
                [self toCallback:callbackId withReslut:[result toJSONString]];
                return;
			} else {
				errCode = PGFileErrorNotFound;
			}
		}
	}
    result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:errCode
                                   withMessage:[self getErrorMeassge:errCode]];
    [self toCallback:callbackId withReslut:[result toJSONString]];
}

@end

#pragma mark FileWirter
#pragma mark------------------------
@implementation PGFile(FileWirte)
/*
 *------------------------------------------------------------------
 * @Summary:
 *      写入文件数据
 * @Parameters:
 *  command [callbackId, [this.path]]
 *  0 - NSString* file path to write to
 *  1 - NSString* data to write
 *  2 - NSNumber* position to begin writing
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) write:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    // arguments
    NSArray *arguments = [command.arguments objectAtIndex:1];
    // arguments
	NSString* argPath = [arguments objectAtIndex:0];
	NSString* argData = [arguments objectAtIndex:1];
    if ( ![argData isKindOfClass:[NSString class]] ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject: PGFileErrorTypeMismatch
                                                        withMessage:[self getErrorMeassge:PGFileErrorTypeMismatch]];
        [self toCallback:callbackId withReslut:[result toJSONString]];
        return;
    }
    
	unsigned long long pos = (unsigned long long)[[ arguments objectAtIndex:2] longLongValue];
    
	NSString* fullPath = argPath; //[self getFullPath:argPath];
	//[self truncateFile:fullPath atPosition:pos];
	//[self writeToFile: fullPath withData:argData append:YES callback: callbackId];
    
    if ( ![self allowWrite:fullPath] ) {
		PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject: PGFileErrorNoModificationAllowed
                                       withMessage:[self getErrorMeassge:PGFileErrorNoModificationAllowed]];
		[self toCallback:callbackId withReslut:[result toJSONString]];
	} else {
        [self writeToFile: fullPath withData:argData pos:pos callback: callbackId];

    }
}

- (void) truncate:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    // arguments
    NSArray *arguments = [command.arguments objectAtIndex:1];
	NSString* argPath = [arguments objectAtIndex:0];
	unsigned long long  size = (unsigned long long)[[arguments objectAtIndex:1] longLongValue];
	unsigned long long  pos = (unsigned long long)[[arguments objectAtIndex:2] longLongValue];
	NSString *appFile = argPath; //[self getFullPath:argPath];
	
    if ( ![self allowWrite:appFile] ) {
		PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject: PGFileErrorNoModificationAllowed
                                                        withMessage:[self getErrorMeassge:PGFileErrorNoModificationAllowed]];
		[self toCallback:callbackId withReslut:[result toJSONString]];
	} else {
        unsigned long long newPos = [ self truncateFile:appFile atPosition:pos truncateSize:size];
        PDRPluginResult* result = [PDRPluginResult resultWithStatus: PDRCommandStatusOK messageAsInt:(int)newPos];
        [self toCallback:callbackId withReslut:[result toJSONString]];
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      截断或者扩展文件
 * @Parameters:
 *  [1] filePath 文件全路径
 *  [2] pos 截断的位置
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (unsigned long long) truncateFile:(NSString*)filePath atPosition:(unsigned long long)pos truncateSize:(unsigned long long)size
{
	unsigned long long newPos = 0UL;
	NSFileHandle* file = [ NSFileHandle fileHandleForUpdatingAtPath:filePath];
	if(file)
	{
        [file seekToFileOffset:pos];
        NSData *data =  [file readDataOfLength:size];
        [file truncateFileAtOffset:0];
        [file seekToFileOffset:0];
        [file writeData:data];
        [file truncateFileAtOffset:size];
//
//        [file truncateFileAtOffset:pos+size];
//		[file truncateFileAtOffset:(unsigned long long)pos];
		newPos = [ file offsetInFile];
		[ file synchronizeFile];
		[ file closeFile];
	}
	return newPos;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      向一个文件中写入数据
 * @Parameters:
 *  [1] filePath 文件全路径
 *  [2] data  写入的数据
 *  [3] shouldAppend  是否追加
 *  [4] callbackId  回调id
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) writeToFile:(NSString*)filePath withData:(NSString*)data pos:(unsigned long long)pos callback: (NSString*) callbackId
//- (void) writeToFile:(NSString*)filePath withData:(NSString*)data append:(BOOL)shouldAppend callback: (NSString*) callbackId
{
	PDRPluginResult* result = nil;
	PGFileError errCode =  PGFileErrorInvalidModification;
//	int bytesWritten = 0;
	NSData* encData = [ data dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	if (filePath) {
        NSFileHandle* file = [ NSFileHandle fileHandleForWritingAtPath:filePath];
        if(file) {
            NSUInteger len = [ encData length ];
            [file seekToFileOffset:(unsigned long long)pos];
            [file truncateFileAtOffset:(unsigned long long)pos];
            [file writeData:encData];
            [file synchronizeFile];
            [file closeFile];
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt: (int)len];
            [self toCallback:callbackId withReslut:[result toJSONString]];
            return;
        }
        /*
		NSOutputStream* fileStream = [NSOutputStream outputStreamToFileAtPath:filePath append:shouldAppend ];
		if (fileStream) {
			NSUInteger len = [ encData length ];
			[ fileStream open ];
			bytesWritten = [ fileStream write:(const uint8_t *)[encData bytes] maxLength:len];
			[ fileStream close ];
			if (bytesWritten > 0) {
				result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt: bytesWritten];
                [self toCallback:callbackId withReslut:[result toJSONString]];
                return;
			}
		} // else fileStream not created return INVALID_MODIFICATION_ERR*/
	} else {
		// invalid filePath
		errCode = PGFileErrorNotFound;
	}
    //错误处理
	result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:errCode
                                   withMessage:[self getErrorMeassge:errCode]];
    [self toCallback:callbackId withReslut:[result toJSONString]];
}
@end

#pragma mark DirectoryReader
#pragma mark------------------------
@implementation PGFile(DirectoryReader)
/*
 *------------------------------------------------------------------
 * @Summary:
 *      读取目录下的文件和子文件夹
 * @Parameters:
 *  command [callbackId, [this.path]]
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void) readEntries:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    
    NSString *callbackId = [command.arguments objectAtIndex:0];
    // arguments
    NSArray *args = [command.arguments objectAtIndex:1];
    //文件路径
    NSString* fullPath = [args objectAtIndex:0];
	PDRPluginResult* result = nil;
    
    if (![self allowRead:fullPath]){
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:PGFileErrorNotReadable
                                       withMessage:[self getErrorMeassge:PGFileErrorNotReadable]];
		[self toCallback:callbackId withReslut:[result toJSONString]];
    } else {
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        NSError* __autoreleasing error = nil;
        NSArray* contents = [fileMgr contentsOfDirectoryAtPath:fullPath error: &error];
        if (contents) {
            NSMutableArray* entries = [NSMutableArray arrayWithCapacity:1];
            if ([contents count] > 0){
                for (NSString* name in contents) {
                    NSString* entryPath = [fullPath stringByAppendingPathComponent:name];
                    BOOL bIsDir = NO;
                    [fileMgr fileExistsAtPath:entryPath isDirectory: &bIsDir];
                    NSDictionary* entryDict = [self getDirectoryEntry:entryPath isDirectory:bIsDir];
                    [entries addObject:entryDict];
                }
            }
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray: entries];
            [self toCallback:callbackId withReslut:[result toJSONString]];
        } else {
            //错误处理
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageToErrorObject:PGFileErrorNotFound
                                           withMessage:[self getErrorMeassge:PGFileErrorNotFound]];
            [self toCallback:callbackId withReslut:[result toJSONString]];
        }
    }
}
@end

