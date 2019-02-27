/*
 *------------------------------------------------------------------
 *  pandora/feature/log/pg_log.h
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

typedef NS_ENUM(NSInteger, PGFileError) {
    PGFileErrorNO = 0, //ok
	PGFileErrorNotFound = 1, //未发现
    PGFileErrorSecurity = 2,
    PGFileErrorAbort = 3,
    PGFileErrorNotReadable = 4,
    PGFileErrorEncoding = 5,
    PGFileErrorNoModificationAllowed = 6, //源目标相同
    PGFileErrorInvalidState = 7,
    PGFileErrorSyntax = 8,
    PGFileErrorInvalidModification = 9,
    PGFileErrorQuotaExeeded = 10,
    PGFileErrorTypeMismatch = 11,
    PGFileErrorPathExists = 12, //目标存在
    PGFileErrorDirNotEmpty = 13,
};

#define kPDRFileSystemPrivateWWW @"PRIVATE_WWW"
#define kPDRFileSystemPrivateDocumnets @"PRIVATE_DOCUMENTS"
#define kPDRFileSystemPublicDocumnets @"PUBLIC_DOCUMENTS"
#define kPDRFileSystemPublicDownloads @"PUBLIC_DOWNLOADS"

@interface PGFile : PGPlugin
{
}

@property(nonatomic, retain)NSString *privateWWW;
@property(nonatomic, retain)NSString *privateDocuments;
@property(nonatomic, retain)NSString *publicDocuments;
@property(nonatomic, retain)NSString *publicDownloads;

- (PGPlugin*) initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp*)app;
- (void) requestFileSystem:(PGMethod*)command;
- (void) resolveLocalFileSystemURL:(PGMethod*)command;
- (NSData*) convertLocalFileSystemURL:(PGMethod*)command;
- (NSData*) convertAbsoluteFileSystem:(PGMethod*)command;
@end

#pragma mark -------------------------
/*
 *@Entry相关方法
 */
@interface PGFile(Entry)

//移动文件或目录
- (void)moveTo:(PGMethod*)command;
//拷贝文件或目录
- (void)copyTo:(PGMethod*)command;
//删除文件或目录
- (void)remove:(PGMethod*)command;
- (void) getParent:(PGMethod*)command;
@end

#pragma mark -------------------------
/*
 *@FileEntry相关方法
 */
@interface PGFile(FileEntry)
- (void) getFileMetadata:(PGMethod*)command;
@end


#pragma mark -------------------------
/*
 *@DirectoryEntry相关方法
 */
@interface PGFile(DirectoryEntry)
@end

#pragma mark -------------------------
/*
 *@DirectoryReader相关方法
 */
@interface PGFile(DirectoryReader)
- (void) readEntries:(PGMethod*)command;
@end

#pragma mark -------------------------
/*
 *@FileReader相关方法
 */
@interface PGFile(FileReader)
- (void) readAsText:(PGMethod*)command;
@end

#pragma mark -------------------------
/*
 *@FileWrite相关方法
 */
@interface PGFile(FileWirte)
- (void) write:(PGMethod*)command;
- (void) truncate:(PGMethod*)command;
- (unsigned long long) truncateFile:(NSString*)filePath atPosition:(unsigned long long)pos truncateSize:(unsigned long long)size;
@end
