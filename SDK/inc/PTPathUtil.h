/*
 *------------------------------------------------------------------
 *  pandora/tools/PTPathUtil.h
 *  Description:
 *     文件功能头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-02-19 创建文件
 *------------------------------------------------------------------
 */
@class PDRCoreApp;
@class PDRCoreAppInfo;

@interface PTPathUtil : NSObject
/// @brief指定的路径是否h5+允许访问
+ (BOOL)allowsWritePath:(NSString*)path;
+ (BOOL)allowsWritePath:(NSString*)path
            withContext:(PDRCoreApp*)context;
/// @brief获取一个文件的MIME类型
+ (NSString*) getMimeTypeFromPath: (NSString*) fullPath;
/* @brief 转化H5+路径到系统路径如果路径是目录
 会根据suggestedFilename(为空prefix[%3d].suffix)形式生成唯一文件返回
 如果目录转化失败会在suggestedPath(为空取app->doc)目录下生成*/
+ (NSString*) absolutePath:(NSString*)srcPath
             suggestedPath:(NSString*)dPath
         suggestedFilename:(NSString*)suggestedFilename
                    prefix:(NSString*)prefix
                    suffix:(NSString*)suffix;
+ (NSString*) absolutePath:(NSString*)srcPath
             suggestedPath:(NSString*)dPath
         suggestedFilename:(NSString*)suggestedFilename
                    prefix:(NSString*)prefix
                    suffix:(NSString*)suffix
                   context:(PDRCoreApp*)context;
+ (NSString*) absolutePath:(NSString*)path
         suggestedFilename:(NSString*)suggestedFilename
                    prefix:(NSString*)prefix
                    suffix:(NSString*)suffix
                   context:(PDRCoreApp*)context;
+ (NSString*) absolutePath:(NSString*)path
         suggestedFilename:(NSString*)suggestedFilename
                    prefix:(NSString*)prefix
                    suffix:(NSString*)suffix
             allowSameName:(BOOL)allowSameName
                   context:(PDRCoreApp*)context;
/* @brief转化H5+路径到系统路径如果路径是目录
 会根据prefix[%3d].suffix形式生成唯一文件返回
 如果目录转化失败会在app->doc目录下生成*/
+ (NSString*) absolutePath:(NSString*)relativePath
                    prefix:(NSString*)prefix
                    suffix:(NSString*)suffix
                   context:(PDRCoreApp*)context;
+ (NSString*) absolutePath:(NSString*)path
                    prefix:(NSString*)prefix
                    suffix:(NSString*)suffix
             allowSameName:(BOOL)allowSameName
                   context:(PDRCoreApp*)context;
+ (NSURL*)urlWithPath:(NSString*)path;
+ (NSString*) wrapFileScheme:(NSString*)path;
/// @brief转化H5+路径到系统路径如果是相对路径根据basePath生成全路径
+ (NSString*) h5Path2SysPath:(NSString*)path basePath:(NSString*)basePath;
+ (NSString*) h5Path2SysPath:(NSString*)path
                    basePath:(NSString*)basePath
                     context:(PDRCoreApp*)context;
+ (NSString*) h5Path2SysPath:(NSString*)path
                    basePath:(NSString*)basePath
                     appInfo:(PDRCoreAppInfo*)context;
+ (NSString*) sysPath2H5path:(NSString*)path withContext:(PDRCoreApp*)context;
/// @brief转化H5+路径到系统路径
+ (NSString*) absolutePath:(NSString*)relativePath;
+ (NSString*) absolutePath:(NSString*)relativePath
                   withContext:(PDRCoreApp*)context;
+ (NSString*) absolutePath:(NSString*)relativePath
               withContext:(PDRCoreApp*)context
                   default:(NSString*)defaultPath;
/// @brief根据系统绝对路径获取H5+路径
+ (NSString*) relativePath:(NSString*)absolutePath
               withContext:(PDRCoreApp*)context;
/// @brief判断给定路径是文件还是目录不进行文件测试 /结尾为目录反之为文件
+ (BOOL) isFile:(NSString*)path;
+ (NSString*)uniquePath:(NSString*)parentPath
             withPrefix:(NSString*)prefix
                 suffix:(NSString*)suffix;
/// @brief在doc目录下生成唯一的文件格式prefix%3d.suffix
+ (NSString*)uniqueNameInAppDocHasPrefix:(NSString*)prefix
                                   suffix:(NSString*)suffix;
+ (NSString*)uniqueNameInAppDocHasPrefix:(NSString*)prefix
                                  suffix:(NSString*)suffix
                                 context:(PDRCoreApp*)context;
+ (void)ensureDirExist:(NSString*)path;
+ (NSString*)sysLibrayPath;
+ (NSString*)sysTmpPath;

+ (NSString*)runtimeRootPathB;
+ (NSString*)appPathWithAppidL:(NSString*)appid;
+ (NSString*)appPathWithAppidB:(NSString*)appid;
+ (NSString*)appWWWPathWithAppidB:(NSString*)appid;

+ (NSString*)appRootPathWithAppidL_Constant:(NSString*)appid;
+ (NSString*)appRootPathWithAppidL:(NSString*)appid;
+ (NSString*)appDataPathWithAppidL:(NSString*)appid;
+ (NSString*)appWWWPathWithAppidL:(NSString*)appid;
+ (NSString*)appDocPathWithAppidL:(NSString*)appid;
+ (NSString*)appTempPathWithAppid:(NSString*)appid;
+ (NSString*)appDebugPathWithAppidL:(NSString*)appid;
+ (NSString*)manifestPathWithAppidL:(NSString*)appid;
+ (NSString*)manifestPathWithAppidB:(NSString*)appid;
//设置接口
+ (void)setRuntimeRootPathL:(NSString*)rootPathL;
+ (void)setRuntimeRootPathB:(NSString*)rootPathB;
+ (void)setRuntimeDocumentPath:(NSString*)doucumentPath;
+ (void)setRuntimeDownloadPath:(NSString*)downloadPath;

//pdr libray root path
+ (NSString*)runtimeRootPathL;
//获取设置pdr apps目录libray/Pandora/apps
+ (NSString*)runtimeAppsPathL;
+ (void)setRuntimeAppsPathL:(NSString*)appPathL;
//获取pdr apps目录MainBudle/Pandora/apps
+ (NSString*)runtimeAppsPathB;
+ (void)setRuntimeAppsPathB:(NSString*)appPathB;

//获取pdr Doc目录libray/Pandora/document
+ (NSString*)runtimeDocumentPath;
//获取pdr下载目录libray/Pandora/download
+ (NSString*)runtimeDownloadPath;
//获取pdr日志目录libray/Pandora/log
+ (NSString*)runtimeLogPath;
//获取pdr data目录libray/Pandora/data
+ (NSString*)runtimeDataPath;
//获取pdr临时目录/temp
+ (NSString*)runtimeTmpPath;
+ (void)clearRuntimeTmpPath;
+ (NSString*)standardizingPath:(NSString*)path;
//释放path相关内存
+ (void)free;
//在指定的目录下生成一个唯一的目录
+ (NSString*)uniquePathInPath:(NSString*)path;
/// 在inPath目录下生成唯一的文件
+ (NSString*)uniqueFileNameWithPrefix:(NSString*)prefix
                                  ext:(NSString*)ext
                               inPath:(NSString*)path
                               create:(BOOL)create;
//生成唯一的文件名
+ (NSString*)uniqueFileName:(NSString*)ext;
+ (NSString*)getUpOneLevelUrl:(NSString*)currentHref;
+ (NSString*)getRetainPath:(NSString*)filePath;
+ (NSString*)getRetainPath:(NSString*)path scale:(int)scale;
+ (BOOL)isGifFile:(NSString*)filePath;
+ (BOOL)isNetPath:(NSString*)path;
@end

@interface PTFSUtil : NSObject
//获取文件的大小
+ (long long) fileSizeAtPath:(NSString*) filePath;
+ (long long) folderSizeAtPath:(NSString*) folderPath;
/**
 * @Summay :获取目录大小目录中元素数目
 * @Param folderPath 目录全路径
 * @Param deep 是否深度遍历
 * @Param outDirCount 含有目录数目
 * @Param outFileCount 含有的文件数目
 * @Return long long 目录下所有文件大小之和
 * @Descript
 * @Modify
 **/
+ (long long) folderSizeAtPath:(NSString*) folderPath
                          deep:(BOOL)deep
                      dirCount:(long long*)outDirCount
                     fileCount:(long long*)outFileCount;
@end
