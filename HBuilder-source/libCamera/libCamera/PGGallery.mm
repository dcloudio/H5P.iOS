/*
 *------------------------------------------------------------------
 *  pandora/feature/cache/pg_gallery.mm
 *  Description:
 *    打开相册实现文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *    number    author    modify date modify record
 *   0       xty     2013-02-17 创建文件
 *------------------------------------------------------------------
 */
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import "PGGallery.h"
#import "PDRToolSystemEx.h"
#import "PDRCoreWindowManager.h"
#import "PTPathUtil.h"
#import "PDRCoreAppInfo.h"
#import "PDRCore.h"
#import "PDRCoreAppWindow.h"
#import "PDRCommonString.h"
#import "PGGalleryProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>
#define PGGALLERY_PHOTO_PREFIX @"photo_"
#define PGGALLERY_PHOTO_SUFFIX @"png"
#define PGGALLERY_VIDEO_PREFIX @"video_"
#define PGGALLERY_VIDEO_SUFFIX @"mov"

#define PGGALLERY_DATA_READLEN 1024000

@implementation PGBaseOption

@synthesize savePath;
@synthesize rect;
@synthesize rectValid, animation;

-(id)init {
    if ( self = [super init] ) {
        self.savePath = nil;
        self.rect = CGRectZero;
        self.rectValid = FALSE;
        self.animation = true;
    }
    return self;
}

- (void)parse:(NSDictionary*)params withStaffRect:(CGRect)aStaffRect{
    
    //获取保存位置
    NSString *dstPath = [params objectForKey:g_pdr_string_filename];
    if ( [dstPath isKindOfClass:[NSString class]] ){
        self.savePath = dstPath ;
    }
    
    //获取弹出位置
    CGRect retRect = CGRectZero;
    if (params && [params isKindOfClass:[NSDictionary class]]) {
        
        NSNumber *leftArgs = [params objectForKey:g_pdr_string_left];
        if ( [leftArgs isKindOfClass:[NSNumber class]] ) {
            retRect.origin.x = [leftArgs intValue];
        } else if ( [leftArgs isKindOfClass:[NSString class]] ) {
            CGFloat tmp = 0.0f;
            if ( 0 == [(NSString*)leftArgs getMeasure:&tmp withStaff:aStaffRect.size.width] ) {
                retRect.origin.x = tmp;
            } else {
                self.rectValid = false;
            }
        }
        
        NSString *topArgs = [params objectForKey:g_pdr_string_top];
        if ( [topArgs isKindOfClass:[NSNumber class]] ) {
            retRect.origin.y = [topArgs intValue];
        } else if ( [topArgs isKindOfClass:[NSString class]] ) {
            CGFloat tmp = 0.0f;
            if ( 0 == [(NSString*)topArgs getMeasure:&tmp withStaff:aStaffRect.size.height] ) {
                retRect.origin.y = tmp;
            } else {
                self.rectValid = false;
            }
        }
        
        NSNumber *widthArgs = [params objectForKey:g_pdr_string_width];
        if ( [widthArgs isKindOfClass:[NSNumber class]] ) {
            retRect.size.width = [widthArgs intValue];
        } else if ( [widthArgs isKindOfClass:[NSString class]] ) {
            CGFloat tmp = 0.0f;
            if ( 0 == [(NSString*)widthArgs getMeasure:&tmp withStaff:aStaffRect.size.width] ) {
                retRect.size.width = tmp;
            } else {
                self.rectValid = false;
            }
        }
        
        NSNumber *heigthArgs = [params objectForKey:g_pdr_string_height];
        if ( [heigthArgs isKindOfClass:[NSNumber class]] ) {
            retRect.size.width = [heigthArgs intValue];
        } else if ( [topArgs isKindOfClass:[NSString class]] ) {
            CGFloat tmp = 0.0f;
            if ( 0 == [(NSString*)heigthArgs getMeasure:&tmp withStaff:aStaffRect.size.height] ) {
                retRect.size.height = tmp;
            } else {
                self.rectValid = false;
            }
        }
    }
    
    if ( !CGRectIsNull(retRect) && self.rectValid) {
        self.rect = retRect;
    }
}

- (void)dealloc {
    self.savePath = nil;
    self.callbackId = nil;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}
@end

@implementation PGGalleryOption

@synthesize multiple;
@synthesize filters;
@synthesize onmaxedCBId;

-(id)init {
    if ( self = [super init] ) {
        self.filters = PGGalleryFiltersPhoto;
        self.animation = YES;
        self.multiple = false;
    }
    return self;
}

+(PGGalleryOption*)optionWithJSON:(NSDictionary*)json
                    withStaffRect:(CGRect)staffRect {
    PGGalleryOption *option = H5_AUTORELEASE([[PGGalleryOption alloc] init]);
    [option parse:json withStaffRect:staffRect];
    return option;
}

- (void)parse:(NSDictionary*)params withStaffRect:(CGRect)aStaffRect{
    if ( [params isKindOfClass:[NSDictionary class]] ) {
        [super parse:params withStaffRect:aStaffRect];
        
        NSNumber *animationArgs = [params objectForKey:g_pdr_string_animation];
        if ( [animationArgs isKindOfClass:[NSNumber class]]
            ||[animationArgs isKindOfClass:[NSString class]]) {
            self.animation = [animationArgs boolValue];
        }
        NSString *multipleValue = [params objectForKey:@"multiple"];
        if ( [multipleValue isKindOfClass:[NSNumber class]] ) {
            if ( [multipleValue boolValue] ) {
                self.multiple = true;
            }
        }
        
        if ( self.multiple && [PTPathUtil isFile:self.savePath] ) {
            self.savePath = [self.savePath stringByDeletingLastPathComponent];
        }
        self.maximum = 9;
        NSString *maximumValue = [params objectForKey:@"maximum"];
        if ( [maximumValue isKindOfClass:[NSNumber class]] ) {
            self.maximum = [maximumValue integerValue];
        }
        
        NSArray *selectedJSValue = [params objectForKey:@"selected"];
        if ( [selectedJSValue isKindOfClass:[NSArray class]] ) {
            NSMutableArray *s = [NSMutableArray array];
            for ( NSString *item in selectedJSValue ) {
                if ( [item isKindOfClass:[NSString class]] ) {
                    [s addObject:item];
                }
            }
            self.selected = s;
        }
        
        NSString *fTValue = [params objectForKey:g_pdr_string_filter];
        if ( [fTValue isKindOfClass:[NSString class]] ) {
            if ( NSOrderedSame == [g_pdr_string_none caseInsensitiveCompare:fTValue] ) {
                self.filters = PGGalleryFiltersNone;
                //  filters = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*)kUTTypeImage, nil];
            } else if ( NSOrderedSame == [g_pdr_string_video caseInsensitiveCompare:fTValue] ) {
                //  filters = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, nil];
                self.filters = PGGalleryFiltersVideo;
            } else {
            }
        }
    }
}

- (void)dealloc {
    self.onmaxedCBId = nil;
    //  self.filters = nil;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}
@end

@interface PGGallery()<H5CoreImageLoaderDelegate, UIAlertViewDelegate>
@property(nonatomic, retain)NSMutableDictionary * tempResultMap;
@property(nonatomic, retain)NSLock*     threadLock;
@property(nonatomic, retain)dispatch_semaphore_t dismissPickerSemaphore;
@property(nonatomic, retain)dispatch_semaphore_t icloudfailedsemaphore;
@property(nonatomic, assign)BOOL bReturyDownload;
@end

@implementation PGGallery

@synthesize hasPendingOperation, pickerController, mOptions;
- (PGPluginAuthorizeStatus)authorizeStatus {
    ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
    switch ( authStatus ) {
        case ALAuthorizationStatusNotDetermined:
            return PGPluginAuthorizeStatusNotDetermined;
        case ALAuthorizationStatusDenied:
            return PGPluginAuthorizeStatusDenied;
        case ALAuthorizationStatusRestricted:
            return PGPluginAuthorizeStatusRestriction;
        default:
            break;
    }
    return PGPluginAuthorizeStatusAuthorized;
}
/**
 *------------------------------------------------------------------
 * @Summary:
 *     调用系统相册
 * @Parameters:
 *  command [callbackId, option]
 *     option [filename, animation, popover]
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)pick:(PGMethod*)command {
    
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] )
    {
        return;
    }
    
    if (_defalutSelectImages == NULL) {
        _defalutSelectImages = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    
    NSString *callbackId = [command.arguments objectAtIndex:0];
    // arguments
    PGGalleryOption *pickOptions = [PGGalleryOption optionWithJSON:[command.arguments objectAtIndex:1] withStaffRect:self.JSFrameContext.bounds];
    pickOptions.onmaxedCBId = [command.arguments objectAtIndex:2];
    pickOptions.callbackId = callbackId;
    self.mOptions = pickOptions;
    
    PDRPluginResult *result = nil;
    int retCode = PGPluginOK;
    // 如果当前有任务没完成（icloud下载文件耗时较长）则返回错误码通知页面
    if ( self.hasPendingOperation ) {
        retCode = PGPluginErrorBusy;
    }
    
    // 返回未授权错误
    if (![self isAuthorizationStatusAuthorized]) {
        retCode = PGPluginErrorNotPermission;
    }
    
    if ( ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] ){
        retCode = PGPluginErrorNotSupport;
    }
    
    if ( PGPluginOK != retCode ) {
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:retCode
                                       withMessage:[self errorMsgWithCode:retCode]];
        [self toCallback:callbackId  withReslut:[result toJSONString]];
        return;
    }
    
    if ( [self userSystemPickController] ) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        self.systemPickerController = imagePickerController;
        self.systemPickerController.delegate = self;
        self.systemPickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        if ( PGGalleryFiltersVideo == self.mOptions.filters ) {
            self.systemPickerController.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, nil];
        } else if (PGGalleryFiltersPhoto == self.mOptions.filters) {
            self.systemPickerController.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeImage, nil];
        } else {
            self.systemPickerController.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*)kUTTypeImage, nil];
        }
        [self popImgaeControllerWithOptions:pickOptions];
    } else {
        
        DCTZImagePickerController* imagePickerController = [[DCTZImagePickerController alloc]
                                                            initWithMaxImagesCount:self.mOptions.maximum
                                                            columnNumber:4
                                                            delegate:self];
        
        if ( PGGalleryFiltersPhoto == self.mOptions.filters ) {
            // 只读取图片
            imagePickerController.allowPickingVideo = NO;
            imagePickerController.allowPickingImage = YES;
        } else if (PGGalleryFiltersVideo == self.mOptions.filters){
            // 只读取视频
            imagePickerController.allowPickingVideo = YES;
            imagePickerController.allowPickingImage = NO;
        } else  {
            // 图片和视频都支持读取
            imagePickerController.allowPickingVideo = YES;
            imagePickerController.allowPickingImage = YES;
        }
        
        // 允许预览，点击图片后可打开一个新的VC预览图片或视频
        imagePickerController.allowPreview = YES;
        // 自动显示关闭按钮
        imagePickerController.autoDismiss = NO;
        // 打开相机拍摄视频按钮
        imagePickerController.allowTakeVideo = NO;
        // 打开相机拍摄图片按钮
        imagePickerController.allowTakePicture = NO;
        
        if (self.mOptions.multiple) {
            imagePickerController.maxImagesCount = self.mOptions.maximum;
        }else{
            imagePickerController.maxImagesCount = 1;
        }
        
        if (self.mOptions.multiple && self.mOptions.maximum > 1 && (PGGalleryFiltersPhoto != self.mOptions.filters)) {
            imagePickerController.allowPickingMultipleVideo = YES;
        }
        
        if (_selectedAssets && [_selectedAssets count]) {
            [_selectedAssets removeAllObjects];
        }
        
        _selectedAssets = [self getDefalutSelectedAssetURLs:self.mOptions.selected];
        
        // 设置是否显示图片序号
        imagePickerController.showSelectedIndex = YES;
        
        // 设置首选语言 / Set preferred language
        //imagePickerController.preferredLanguage = @"zh-Hans";
        
        if (_selectedAssets && [_selectedAssets count]) {
            imagePickerController.selectedAssets = _selectedAssets;
        }
        self.pickerController = imagePickerController;
        [self popImgaeControllerWithOptions:pickOptions];
    }
}


- (BOOL)isAuthorizationStatusAuthorized{
    if ( [PTDeviceOSInfo systemVersion] >=  PTSystemVersion6Series) {
        ALAuthorizationStatus authorizationStaus = [ALAssetsLibrary authorizationStatus];
        if ( ALAuthorizationStatusDenied == authorizationStaus ) {
            return NO;
        }
    }
    return YES;
}

- (NSString*)shortPath:(NSString*)path {
    NSRange range = [path rangeOfString:self.appContext.appInfo.appID];
    if ( range.length ) {
        return [path substringFromIndex:range.location];
    }
    return nil;
}

- (NSMutableArray*)getDefalutSelectedAssetURLs:(NSArray*)h5URL {
    NSMutableArray *ret = [NSMutableArray array];
    if ( [_defalutSelectImages count]&& [h5URL count] ) {
        for ( NSString *path in h5URL  ) {
            if ( _defalutSelectImages ) {
                NSString* ghostPath = [self shortPath:path];
                if ( ghostPath ) {
                    PHAsset *assetObj = [_defalutSelectImages objectForKey:ghostPath];
                    if ( assetObj ) {
                        if(ret == NULL){
                            ret = [[NSMutableArray alloc] initWithCapacity:0];
                        }
                        [ret addObject:assetObj];
                    }
                }
            }
        }
        return ret;
    }
    return ret;
}


- (BOOL)userSystemPickController {
    if ([PTDeviceOSInfo systemVersion] >=  PTSystemVersion6Series) {
        return NO;
    }
    return YES;
}

- (void)popImgaeControllerWithOptions:(PGBaseOption*)popOptions {
    if ([self popoverSupported] ) {
        if (self.popoverController == nil) {
            if ([self userSystemPickController]) {
                self.popoverController = H5_AUTORELEASE([[NSClassFromString (@"UIPopoverController")alloc] initWithContentViewController:self.systemPickerController]);
            } else {
                self.popoverController = H5_AUTORELEASE([[NSClassFromString (@"UIPopoverController")alloc] initWithContentViewController:pickerController]);
            }
        }
        
        CGRect popoverRect = CGRectMake(0, 0, 1, 1);
        UIPopoverArrowDirection arrowDirection = UIPopoverArrowDirectionUp;
        if ( popOptions.rectValid )  {
            popoverRect = popOptions.rect;
            arrowDirection = UIPopoverArrowDirectionAny;
        } else {
            popoverRect = [self getDefaultPopRect];
        }
        
        self.popoverController.delegate = self;
        [self.popoverController presentPopoverFromRect:popoverRect
                                                inView:self.JSFrameContext
                              permittedArrowDirections:arrowDirection
                                              animated:popOptions.animation];
    }
    else {
        if ([self userSystemPickController]) {
            [self presentViewController:self.systemPickerController animated:popOptions.animation completion:nil];
        } else {
            [self presentViewController:self.pickerController animated:popOptions.animation completion:nil];
        }
    }
    self.hasPendingOperation = YES;
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *    获取当前缓存数据大小
 * @Parameters:
 *  command [callbackId]
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */

- (BOOL)isValidUrl:(NSString*)filePath
{
    NSString *regex =@"[a-zA-z]+://[^\\s]*";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [urlTest evaluateWithObject:filePath];
}


-(void)imageLoaded:(id)image userInfo:(id)userInfo
{
    if(userInfo)
    {
        ALAssetsLibrary* assertLibrary = [userInfo objectForKey:@"alasslib"];
        NSString* cbid = [userInfo objectForKey:@"cbid"];
        UIImage* imgSave = (UIImage*)image;
        [assertLibrary writeImageToSavedPhotosAlbum:imgSave.CGImage
                                           metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                                               if ( error || !assetURL) {
                                                   [self toErrorCallback:cbid withNSError:error];
                                               } else {
                                                   [self toSucessCallback:cbid withJSON:@{@"path":[assetURL absoluteString]}];
                                               }
#if !__has_feature(objc_arc)
                                               [assertLibrary release];
#endif
                                           }];
    }
}

-(void)save:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return;
    }
    
    NSString *imgFullPath = nil;
    NSArray *nameArgs = command.arguments;
    NSString *arg0 = [nameArgs objectAtIndex:0];
    NSString *callBackID = [nameArgs objectAtIndex:1];
    int errorCode = PGPluginOK;
    
    if ( [arg0 isKindOfClass:[NSString class]] ) {
        NSURL *url = nil;
        
        
        if ( ![arg0 isAbsolutePath] ) {
            if([self isValidUrl:arg0]){
                imgFullPath = arg0;
                url = [NSURL URLWithString:imgFullPath];
            }else{
                imgFullPath = [PTPathUtil h5Path2SysPath:arg0 basePath:self.JSFrameContext.baseURL context:self.appContext];
                //imgFullPath = [PTPathUtil absolutePath:arg0 withContext:application];
                url = [NSURL fileURLWithPath:imgFullPath];
            }
        }else{
            imgFullPath = arg0;
            url = [NSURL fileURLWithPath:imgFullPath];
        }
        
        if ( !url ) {
            url = [NSURL URLWithString:imgFullPath];
        }
        
        if ( url ) {
            
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            switch (status) {
                    // 未授权
                case PHAuthorizationStatusNotDetermined:
                {
                    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                        switch (status) {
                            case PHAuthorizationStatusDenied:
                                [self toErrorCallback:callBackID withCode:2 withMessage:@"无访问权限：PHAuthorizationStatusDenied"];
                                break;
                            case PHAuthorizationStatusAuthorized:
                                [self saveImageToPhotosAlbum:url sysPath:arg0 callbackId:callBackID];
                                break;
                            default:
                                break;
                        }
                    }];
                    break;
                }
                    // 受限制
                case PHAuthorizationStatusRestricted:
                {
                    [self toErrorCallback:callBackID withCode:1 withMessage:@"无访问权限：PHAuthorizationStatusRestricted"];
                    break;
                }
                    // 拒绝访问
                case PHAuthorizationStatusDenied:
                {
                    [self toErrorCallback:callBackID withCode:2 withMessage:@"无访问权限：PHAuthorizationStatusDenied"];
                    break;
                }
                    // 允许访问
                case PHAuthorizationStatusAuthorized:
                {
                    [self saveImageToPhotosAlbum:url sysPath:arg0 callbackId:callBackID];
                }
                default:
                    break;
            }
            
        } else {
            errorCode = PGPluginErrorNotSupport;
        }
    }
    if ( PGPluginOK != errorCode ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:errorCode
                                                        withMessage:[self errorMsgWithCode:errorCode]];
        [self toCallback:callBackID  withReslut:[result toJSONString]];
    }
}

- (void)saveImageToPhotosAlbum:(NSURL *)url sysPath:(NSString *)arg0 callbackId:(NSString *)callBackID {
    ALAssetsLibrary *assertLibrary = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryWriteVideoCompletionBlock result = ^(NSURL *assetURL, NSError *error) {
                    if ( error || !assetURL) {
                        [self toErrorCallback:callBackID withNSError:error];
                    } else {
                        [self toSucessCallback:callBackID withJSON:@{@"path":[assetURL absoluteString]}];
                    }
#if !__has_feature(objc_arc)
                    [assertLibrary release];
#endif
                };
                if ( [assertLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:url] ){
                    [assertLibrary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:result];
                } else {
                    if( !url.isFileURL && [self isValidUrl:arg0]){
                        [[[PDRCore Instance] imageLoader] loadImage:[url absoluteString]
                                                       withDelegate:self
                                                        withContext:@{@"cbid":[NSString stringWithString:callBackID],@"alasslib":assertLibrary}];
                    } else {
                        NSError *error = nil;
                        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                            [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:url];
                        } error:&error];

                        if (error) {
                            [self toErrorCallback:callBackID withNSError:error];
                        } else {
                            [self toSucessCallback:callBackID withJSON:@{@"path":[url absoluteString]}];
                        }
                    }
                }
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *    判断是否支持popover
 * @Parameters:
 *
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (BOOL)popoverSupported
{
    if ( [PTDeviceOSInfo systemVersion]  >= PTSystemVersion8Series) {
        return FALSE;
    }
    return (NSClassFromString(@"UIPopoverController") != nil) &&
    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    if ( self.pickerController ) {
        [self dismissImagePickerController];
    }
    [self closePickerController];
}

- (void) onAppEnterBackground {
    [self saveMapTable];
}

- (NSString*)saveImageAsset:(NSData*)imagedata Asset:(PHAsset*)asset{
    NSString* outFilePath = nil;
    NSString *UTI = [asset valueForKey:@"uniformTypeIdentifier"];
    BOOL isHEIF = [UTI isEqualToString:@"public.heif"] || [UTI isEqualToString:@"public.heic"];
    double createTime = [asset.creationDate timeIntervalSince1970];
    NSString *suggestedFileName = [NSString stringWithFormat:@"%.0f-%@",createTime,[asset valueForKey:@"filename"]];
    if ( isHEIF ) {
        CIImage *ciImage = [CIImage imageWithData:imagedata];
        CIContext *context = [CIContext context];
        imagedata = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
        if ( [suggestedFileName length] ) {
            suggestedFileName = [[suggestedFileName stringByDeletingPathExtension] stringByAppendingString:@".jpg"];
        }
    }
    outFilePath =  [PTPathUtil absolutePath:self.mOptions.savePath
                          suggestedFilename:suggestedFileName
                                     prefix:PGGALLERY_PHOTO_PREFIX
                                     suffix:PGGALLERY_PHOTO_SUFFIX
                              allowSameName:YES
                                    context:self.appContext];
    
    if (imagedata) {
        if (outFilePath && ![[NSFileManager defaultManager] fileExistsAtPath:outFilePath]) {
            [imagedata writeToFile:outFilePath atomically:NO];
        }
        // 文件名保存到配置中，供下次选择使用
        [self saveShortPath:outFilePath withAsset:asset];
    }
    
    return outFilePath;
}

- (NSString*)saveVideoAsset:(NSString*)videoPath Asset:(PHAsset*)asset{
    NSString* outFilePath = nil;
    if (videoPath) {
        if (self.mOptions.savePath) {
            outFilePath =  [PTPathUtil absolutePath:self.mOptions.savePath
                                  suggestedFilename:[asset valueForKey:@"filename"]
                                             prefix:PGGALLERY_VIDEO_PREFIX
                                             suffix:PGGALLERY_VIDEO_SUFFIX
                                      allowSameName:YES
                                            context:self.appContext];
        }else{
            outFilePath = [[videoPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[asset valueForKey:@"filename"]];
        }
        
        [[NSFileManager defaultManager] moveItemAtPath:videoPath toPath:outFilePath error:nil];
        [self saveShortPath:outFilePath withAsset:asset];
    }
    return outFilePath;
}


- (void)saveShortPath:(NSString*)fullPath withAsset:(PHAsset*)asset{
    @synchronized(_defalutSelectImages){
        NSString *shortPath = [self shortPath:fullPath];
        if (shortPath) {
            [_defalutSelectImages setObject:asset forKey:shortPath];
        }
    }
}


- (void)saveMapTable {
    if ( self.flushMaptabel ) {
        if ( _defalutSelectImages && self.mapTableFlushPath) {
            NSFileManager *defalutFileManager = [NSFileManager defaultManager];
            if ( ![defalutFileManager fileExistsAtPath:self.mapTableFlushPath] ) {
                [defalutFileManager createFileAtPath:self.mapTableFlushPath contents:nil attributes:nil];
            }
            [_defalutSelectImages writeToFile:self.mapTableFlushPath atomically:YES];
        }
        self.flushMaptabel = false;
    }
}


#pragma mark
#pragma mark delegate
- (void)closePickerController
{
    self.hasPendingOperation = NO;
    self.pickerController.delegate = nil;
    self.systemPickerController.delegate = nil;
    self.popoverController.delegate = nil;
    
    self.pickerController = nil;
    self.popoverController = nil;
    self.systemPickerController = nil;
    self.mOptions = nil;
}

- (void)dismissImagePickerController
{
    if (self.popoverSupported && (self.popoverController != nil)) {
        [self.popoverController dismissPopoverAnimated:self.mOptions.animation];
        self.popoverController.delegate = nil;
        //self.popoverController = nil;
    } else {
        [self dismissViewControllerAnimated:self.mOptions.animation completion:nil];
        //  self.pickerController = nil;
    }
    if ( [PTDeviceOSInfo systemVersion] < PTSystemVersion7Series) {
        [[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle];
    }
}

- (PGGalleryProgressHUD*)showWaiting {
    PGGalleryProgressHUD *hud = [PGGalleryProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    return hud;
}
#pragma mark - iOS5
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    PGGalleryProgressHUD *hud = [self showWaiting];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *outFilePath = nil;
        
        NSData *mediaData = nil;
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if ( [mediaType isEqualToString:(NSString*)kUTTypeImage] )
        {
            UIImage  *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            originalImage = [originalImage adjustOrientation ];
            mediaData = UIImagePNGRepresentation(originalImage);
            outFilePath =  [PTPathUtil absolutePath:self.mOptions.savePath
                                             prefix:PGGALLERY_PHOTO_PREFIX
                                             suffix:PGGALLERY_PHOTO_SUFFIX
                                            context:self.appContext];
        } else if ( [mediaType isEqualToString:(NSString*)kUTTypeMovie] ) {
            NSURL *mediaURL = [info objectForKey: UIImagePickerControllerMediaURL];
            mediaData = [NSData dataWithContentsOfURL:mediaURL];
            outFilePath = [PTPathUtil absolutePath:self.mOptions.savePath
                                            prefix:PGGALLERY_VIDEO_PREFIX
                                            suffix:PGGALLERY_VIDEO_SUFFIX
                                           context:self.appContext];
        }
        NSError* err = nil;
        int retCode = PGPluginOK;
        if ( mediaData && outFilePath && ![mediaData writeToFile:outFilePath options:NSAtomicWrite error:&err]) {
            retCode = PGPluginErrorIO;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:NO];
            [hud removeFromSuperview];
            [self dismissImagePickerController];
            PDRPluginResult *result = nil;
            if ( PGPluginOK != retCode ) {
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:retCode];
                [self toCallback:self.mOptions.callbackId withReslut:[result toJSONString]];
            } else {
                NSMutableDictionary *retObject = [NSMutableDictionary dictionary];
                [retObject setObject:[NSNumber numberWithBool:NO] forKey:@"multiple"];
                NSMutableArray *fileS = [NSMutableArray array];
                [retObject setObject:fileS forKey:@"files"];
                NSString *newOutFilePath = [[NSURL fileURLWithPath:outFilePath] absoluteString];
                [fileS addObject:newOutFilePath];
                
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:retObject];//[[NSURL fileURLWithPath:filePath] absoluteString]];
                [self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
                //[self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
            }
            [self closePickerController];
        });
    });
}

#pragma mark - TZImagePickerControllerDelegate
// 单选图片时触发这个方法回调，如果当前图片是在icloud上则暂时不关闭选择图片的VC，同时显示一个waitting框，
- (void)imagePickerController:(DCTZImagePickerController *)picker
       didFinishPickingPhotos:(NSArray<UIImage *> *)photos
                 sourceAssets:(NSArray *)assets
        isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto
                        infos:(NSArray<NSDictionary *> *)infos
{
    self.hasPendingOperation = NO;
    _selectedPhotos = [NSMutableArray arrayWithArray:photos];
    _selectedAssets = [NSMutableArray arrayWithArray:assets];
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    
    if(_defalutSelectImages == nil){
        _defalutSelectImages = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    
    int retCode = PGPluginOK;
    if (_selectedPhotos.count == 0) {
        retCode = PGPluginErrorFileNotFound;
        PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:retCode];
        [self toCallback:self.mOptions.callbackId withReslut:[result toJSONString]];
    }
    
    
    
    PHAsset* asset = [_selectedAssets firstObject];
    if (asset) {
        [self scheduleDownLoadAssets:asset atIndex:0];
    }
    
    // 当用户选择的图片下载完成之后关闭当前的pickerController
    _dismissPickerSemaphore = dispatch_semaphore_create(0);
    __block typeof (self)weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // 同步等待下载完成的信号，否则一直显示waitting框和选择图片VC
        dispatch_semaphore_wait(weakself.dismissPickerSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            //semaphore
            [picker hideProgressHUD];
            if (picker.navigationController) {
                [picker.navigationController dismissViewControllerAnimated:YES completion:nil];
            }else{
                [picker dismissViewControllerAnimated:YES completion:nil];
            }
            [weakself closePickerController];
            weakself.dismissPickerSemaphore = nil;
        });
    });
}

// 处理GIF图片和livePhoto图片
- (void)scheduleDownLoadAssets:(PHAsset*)assets atIndex:(int)index{
    TZAssetModelMediaType type = [[TZImageManager manager] getAssetType:assets];
    if (type == TZAssetModelMediaTypeVideo || type == TZAssetCellTypeAudio || type == TZAssetCellTypeLivePhoto) {
        [self downloadVideo:assets AtIndex:index];
    }else if(type == TZAssetCellTypePhoto || type == TZAssetCellTypePhotoGif ){
        [self downloadImage:assets AtIndex:index];
    }
}

// 消息事件，用来检查当前下载任务是否完成，如果完成则触发页面回调通知文件路径，如果下载未完成则调度下一个任务进行下载
- (void)postNotification:(id)obj
{
    if (nil == _threadLock) {
        _threadLock = [[NSLock alloc] init];
    }
    // 给线程上锁防止多个线程同时操作数据导致的数据混乱和异常
    // 这个锁是之前多个任务同时调度时加上的，现在任务改成顺序调度这个锁暂时用不上了，暂时保留
    [_threadLock lock];
    NSMutableArray *fileS = nil;
    if (_tempResultMap == nil) {
        _tempResultMap = [NSMutableDictionary dictionary];
        [_tempResultMap setObject:[NSNumber numberWithBool:self.mOptions.multiple] forKey:@"multiple"];
        fileS = [NSMutableArray array];
        [_tempResultMap setObject:fileS forKey:@"files"];
    }else{
        fileS = [_tempResultMap objectForKey:@"files"];
    }
    
    NSDictionary* ptaskInfo = obj;
    BOOL btaskState = [ptaskInfo[@"state"] boolValue];
    if (btaskState) {
        NSString* filePath = ptaskInfo[@"fileObj"];
        if (filePath && [filePath isKindOfClass:[NSString class]]) {
            NSString *newOutFilePath = [[NSURL fileURLWithPath:filePath] absoluteString];
            [fileS addObject:newOutFilePath];
        }
    }else{
        // TODO: 某个文件下载失败的处理
    }
    
    // 获取当前下载完成item的index，计数+1
    int Index = [ptaskInfo[@"index"] intValue];
    Index++;
    
    [_threadLock unlock];
    
    // 当前下载的item的index小于文件数量时开始下一次调度，下载后一张图片或者视频
    if (Index < _selectedAssets.count) {
        PHAsset* asset = [_selectedAssets objectAtIndex:Index];
        [self scheduleDownLoadAssets:asset atIndex:Index];
    }else{
        // 当前全部文件下载完成则回调通知页面当前选择已经完成。并将当前正在执行的标记置为false
        self.hasPendingOperation = NO;
        dispatch_semaphore_signal(self.dismissPickerSemaphore);
        if (fileS && fileS.count) {
            PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:_tempResultMap];
            [self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
        }else{
            PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:PGPluginErrorIO];
            [self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
        }
        _tempResultMap = nil;
        [fileS removeAllObjects];
    }
}

// 下载图片方法，下载完成后发送一个消息通知下载下一个或者触发页面回调事件，处理过程在消息回调里
- (void)downloadImage:(PHAsset*) assets AtIndex:(NSInteger)index{
    __block typeof(self) weakself = self;
    __block typeof (PHAsset*)weakassets = assets;
    
    [[TZImageManager manager] requestImageDataForAsset:assets completion:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        NSString* outFileName = [weakself saveImageAsset:imageData Asset:weakassets];
        if (outFileName) {
            NSDictionary* destDic = @{@"index":@(index),@"state":@(true),@"type":@"photo",@"fileObj":outFileName};
            [weakself performSelectorOnMainThread:@selector(postNotification:) withObject:destDic waitUntilDone:NO];
        }
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        
    }];
    
    
    //    [[TZImageManager manager] getPhotoWithAsset:assets completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
    //        if (!isDegraded && photo) {
    //            NSString* outFileName = [weakself saveImageAsset:photo Asset:weakassets];
    //            if (outFileName) {
    //                NSDictionary* destDic = @{@"index":@(index),@"state":@(true),@"type":@"photo",@"fileObj":outFileName};
    //                [weakself performSelectorOnMainThread:@selector(postNotification:) withObject:destDic waitUntilDone:NO];
    //            }
    //        }
    //    }];
}

// 视频文件默认下载到tmp目录下，防止用户因为不调用代码删除导致的应用使用空间越来越大的问题，放到tmp目录下系统会自动清理，
// 用户可通过指定filename属性的方式指定当前选择的视频下载到doc目录下，
- (void)downloadVideo:(PHAsset*)assets AtIndex:(NSInteger)index{
    __block typeof(self) weakself = self;
    __block typeof (PHAsset*)weakassets = assets;
    __block NSMutableDictionary* destDic = [NSMutableDictionary dictionaryWithDictionary: @{@"index":@(index),@"state":@(true),@"type":@"video"}];
    
    [[TZImageManager manager] getVideoOutputPathWithAsset:assets success:^(NSString *outputPath) {
        weakself.icloudfailedsemaphore = dispatch_semaphore_create(0);
        if (outputPath) {
            NSString* destputPath = [self saveVideoAsset:outputPath Asset:weakassets];
            if (destputPath) {
                [destDic setObject:destputPath forKey:@"fileObj"];
                [weakself performSelectorOnMainThread:@selector(postNotification:) withObject:destDic waitUntilDone:NO];
            }
        }
    } failure:^(NSString *errorMessage, NSError *error) {
        if (destDic) {
            weakself.icloudfailedsemaphore = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView* pFailedAlert = [[UIAlertView alloc] initWithTitle:@"下载失败" message:@"文件下载失败是否尝试重新下载？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重试", nil];
                [pFailedAlert show];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    // 等待icloudfailedsemaphore标记设置成1后可继续执行
                    dispatch_semaphore_wait(weakself.icloudfailedsemaphore, DISPATCH_TIME_FOREVER);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(weakself.bReturyDownload){
                            [weakself downloadVideo:weakassets AtIndex:index];
                            weakself.icloudfailedsemaphore = nil;
                        }else{
                            [destDic setObject:@(false) forKey:@"state"];
                            // 在这里处理下载失败的问题
                            [weakself performSelectorOnMainThread:@selector(postNotification:) withObject:destDic waitUntilDone:NO];
                        }
                    });
                });
            });
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            _bReturyDownload = false;
            break;
        case 1:
            _bReturyDownload = true;
            break;
        default:
            break;
    }
    
    dispatch_semaphore_signal(self.icloudfailedsemaphore);
}



// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
- (void)imagePickerController:(DCTZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[coverImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
    
    // 此处用来复制视频文件到本地
    __block NSMutableDictionary *retObject = [NSMutableDictionary dictionary];
    [retObject setObject:[NSNumber numberWithBool:self.mOptions.multiple] forKey:@"multiple"];
    __block NSMutableArray *fileS = [NSMutableArray array];
    [retObject setObject:fileS forKey:@"files"];
    self.hasPendingOperation = NO;
    [[TZImageManager manager] getVideoOutputPathWithAsset:asset
                                               presetName:AVAssetExportPreset640x480
                                                  success:^(NSString *outputPath) {
                                                      //NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
                                                      if (outputPath) {
                                                          NSString* destputPath = [self saveVideoAsset:outputPath Asset:asset];
                                                          if (destputPath) {
                                                              NSString *newOutFilePath = [[NSURL fileURLWithPath:destputPath] absoluteString];
                                                              [fileS addObject:newOutFilePath];
                                                              PDRPluginResult* reslult = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:retObject];
                                                              [picker hideProgressHUD];
                                                              if (picker.navigationController) {
                                                                  [picker.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                              }else{
                                                                  [picker dismissViewControllerAnimated:YES completion:nil];
                                                              }
                                                              [self toCallback:self.mOptions.callbackId withReslut:[reslult toJSONString]];
                                                          }
                                                      }
                                                  } failure:^(NSString *errorMessage, NSError *error) {
                                                      NSLog(@"视频导出失败:%@,error:%@",errorMessage, error);
                                                      [self toErrorCallback:self.mOptions.callbackId withCode:1];
                                                      if (picker.navigationController) {
                                                          [picker.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                      }else{
                                                          [picker dismissViewControllerAnimated:YES completion:nil];
                                                      }
                                                  }];
}

// 用户取消选择触发取消的错误回调
- (void)tz_imagePickerControllerDidCancel:(DCTZImagePickerController *)picker{
    self.hasPendingOperation = NO;
    if (picker.navigationController) {
        [picker.navigationController dismissViewControllerAnimated:YES completion:nil];
    }else{
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self toErrorCallback:self.mOptions.callbackId withCode:[self isAuthorizationStatusAuthorized]?PGPluginErrorUserCancel:PGPluginErrorNotPermission];
}

// 用户选择图片超过了最大数量限制，最大的数量限制在初始化时已经设置
- (void)tz_imagePickerControllerPickOverMaxCount:(DCTZImagePickerController*)picker{
    [self toSucessCallback:self.mOptions.onmaxedCBId withInt:0 keepCallback:YES];
}

// 决定相册显示与否
- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(id)result {
    return YES;
}

// 决定asset显示与否
- (BOOL)isAssetCanSelect:(id)asset {
    return YES;
}

/**
 *------------------------------------------------------------------
 * @Summary:
 *    popover回调
 * @Parameters:
 *
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)popoverControllerDidDismissPopover:(id)popoverController
{
    [self dismissImagePickerController];
    if ( self.mOptions.callbackId ) {
        self.popoverController = nil;
        [self toErrorCallback:self.mOptions.callbackId withCode:[self isAuthorizationStatusAuthorized]?PGPluginErrorUserCancel:PGPluginErrorNotPermission];
    }
    [self closePickerController];
}

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    CGRect popoverRect = CGRectMake(0, 0, 1, 1);
    if ( self.mOptions.rectValid )  {
        popoverRect = self.mOptions.rect;
    } else {
        popoverRect = [self getDefaultPopRect];
    }
    *rect = popoverRect;
}
#pragma mark
#pragma mark Tools

- (CGRect)getDefaultPopRect {
    CGRect popRect = CGRectMake(0, 0, 1, 1);
    popRect.origin.x = self.JSFrameContext.center.x;
    popRect.origin.y = self.JSFrameContext.center.y - 240;
    return popRect;
}

-(void)dealloc {
    [self saveMapTable];
    self.mOptions = nil;
#if !__has_feature(objc_arc)
    [_defalutSelectImages release];
    [pickerController release];
    [super dealloc];
#endif
}

@end

