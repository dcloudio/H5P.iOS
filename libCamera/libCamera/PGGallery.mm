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
 *	number	author	modify date modify record
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
#import "PDRCoreAppWindow.h"
#import "PDRCommonString.h"
#import "PGGalleryProgressHUD.h"
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
        self.maximum = NSIntegerMax;
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

    if ( !_defalutSelectImages ) {
        if ( !self.mapTableFlushPath ) {
            self.mapTableFlushPath = [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"__yrellag__s_map"];
        }
        if ( [[NSFileManager defaultManager] fileExistsAtPath:self.mapTableFlushPath] ) {
            _defalutSelectImages = [NSMutableDictionary dictionaryWithContentsOfFile:self.mapTableFlushPath];
        }
    }
    
    NSString *callbackId = [command.arguments objectAtIndex:0];
    // arguments
    PGGalleryOption *pickOptions = [PGGalleryOption optionWithJSON:[command.arguments objectAtIndex:1] withStaffRect:self.JSFrameContext.bounds];
    pickOptions.onmaxedCBId = [command.arguments objectAtIndex:2];
    pickOptions.callbackId = callbackId;
    self.mOptions = pickOptions;
    
    PDRPluginResult *result = nil;
    int retCode = PGPluginOK;
    if ( self.hasPendingOperation ) {
        retCode = PGPluginErrorBusy;
    }

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
        QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsMultipleSelection = self.mOptions.multiple;
        imagePickerController.minimumNumberOfSelection = 1;
        imagePickerController.maximumNumberOfSelection = self.mOptions.maximum;
        if ( NSIntegerMax == self.mOptions.maximum ) {
            imagePickerController.allowsAllSelection = YES;
        } else {
            imagePickerController.allowsAllSelection = NO;
        }
        
        if ( PGGalleryFiltersPhoto == self.mOptions.filters ) {
            imagePickerController.filterType = QBImagePickerControllerFilterTypePhotos;
        } else if (PGGalleryFiltersVideo == self.mOptions.filters){
            imagePickerController.filterType = QBImagePickerControllerFilterTypeVideos;
        } else  {
            imagePickerController.filterType = QBImagePickerControllerFilterTypeNone;
        }
        [imagePickerController setDefalutSelectedAssetURLs:[self getDefalutSelectedAssetURLs:self.mOptions.selected]];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
        if ( [PTDeviceOSInfo systemVersion] < PTSystemVersion7Series) {
            _statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
            navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        }
        self.pickerController = navigationController;
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

- (NSArray*)getDefalutSelectedAssetURLs:(NSArray*)h5URL {
    if ( [_defalutSelectImages count]&& [h5URL count] ) {
        NSMutableArray *ret = [NSMutableArray array];
        for ( NSString *path in h5URL  ) {
            if ( _defalutSelectImages ) {
                NSString* ghostPath = [self shortPath:path];
                if ( ghostPath ) {
                    NSString *assetPath = [_defalutSelectImages objectForKey:ghostPath];
                    if ( assetPath ) {
                        NSURL *assetUrl = [NSURL URLWithString:assetPath];
                        if ( assetUrl ) {
                            [ret addObject:assetUrl];
                        }
                    }
                }
            }
        }
        return ret;
    }
    return nil;
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
        PDRCoreApp *application = self.appContext;
        NSURL *url = [NSURL URLWithString:arg0];
        if ( url ) {
            imgFullPath = [url relativePath];
        } else {
            imgFullPath = arg0;
        }
        
        if ( ![imgFullPath isAbsolutePath] ) {
            imgFullPath = [PTPathUtil absolutePath:arg0 withContext:application];
        }
        if ( UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(imgFullPath) ) {
            UISaveVideoAtPathToSavedPhotosAlbum(imgFullPath, self, @selector(video:didFinishSavingWithError:contextInfo:), (__bridge_retained void*)callBackID );
        } else {
            UIImage *saveImg = [[UIImage alloc] initWithContentsOfFile:imgFullPath];
            if ( saveImg ) {
                UIImageWriteToSavedPhotosAlbum( saveImg, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge_retained void*)callBackID);
#if !__has_feature(objc_arc)
                [saveImg release];
#endif
            } else {
                errorCode = PGPluginErrorNotSupport;
            }
        }
    }
    if ( PGPluginOK != errorCode ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                               messageToErrorObject:errorCode
                                                        withMessage:[self errorMsgWithCode:errorCode]];
        [self toCallback:callBackID  withReslut:[result toJSONString]];
    }
}

- (void)image:(UIImage *)image
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
    NSString *cbID = (__bridge_transfer NSString*)contextInfo;
    if ( [cbID isKindOfClass:[NSString class]] ) {
        [self doError:error withCallBack:(NSString*)cbID];
#if !__has_feature(objc_arc)
        [cbID release];
#endif
    }
}

- (void)video:(NSString *)videoPath
didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
    NSString *cbID = (__bridge NSString*)contextInfo;
    if ( [cbID isKindOfClass:[NSString class]] ) {
        [self doError:error withCallBack:(NSString*)cbID];
#if !__has_feature(objc_arc)
        [cbID release];
#endif
    }
}

- (void)doError:(NSError*)error withCallBack:(NSString*)callBackID {
    PDRPluginResult *result = nil;
    if ( error ) {
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:(int)[error code]
                                       withMessage:[error localizedDescription]];
        [self toCallback:callBackID  withReslut:[result toJSONString]];
    } else {
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:0];
        [self toCallback:callBackID  withReslut:[result toJSONString]];
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

- (BOOL)writeALAsset:(ALAsset*)asset toFile:(NSString*)filePath {
    BOOL ret = YES;
    ALAssetRepresentation *defaultRepresentation = [asset defaultRepresentation];
    NSUInteger totalSize = [defaultRepresentation size];
    NSUInteger bufSize = MIN(totalSize, PGGALLERY_DATA_READLEN);
    NSUInteger readSize = 0;
    NSUInteger canReadSize = MIN(totalSize - readSize, bufSize);
    
    if ( totalSize ) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ( [fileManager fileExistsAtPath:filePath] ) {
            return ret;
            [fileManager removeItemAtPath:filePath error:nil];
        }
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        NSOutputStream *fileOut = [[NSOutputStream  alloc] initToFileAtPath:filePath append:YES];
        if ( fileOut ) {
            [fileOut open];
            uint8_t *buff = (uint8_t*)malloc(bufSize);
            if ( buff ) {
                while ( canReadSize > 0 ) {
                    NSError *err = nil;
                    NSInteger byteCounts = [defaultRepresentation getBytes:buff fromOffset:readSize length:canReadSize error:&err];
                    if ( byteCounts <= 0 ) {
                        ret = NO;
                        break;
                    }
                    NSInteger w = [fileOut write:buff maxLength:canReadSize];
                    if ( w < 0 ) {
                        ret = NO;
                        break;
                    }
                    readSize += canReadSize;
                    canReadSize = MIN(totalSize - readSize, bufSize);
                }
                free( buff );
            }
            [fileOut close];
        }
    }
    return ret;
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
                [self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
            }
            [self closePickerController];
        });
    });
}

#pragma mark - QBImagePickerControllerDelegate
- (void)assetsCollectionViewControllerOnmaxed:(QBImagePickerController*)assetsCollectionViewController {
    [self performSelector:@selector(doMaxedOverflow) withObject:nil afterDelay:0];
}

- (void)doMaxedOverflow{
    [self toSucessCallback:self.mOptions.onmaxedCBId withInt:0 keepCallback:YES];
}

- (void)imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(ALAsset *)asset {
    [self imagePickerController:imagePickerController didSelectAssets:[NSArray arrayWithObject:asset]];
}

- (void)imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets
{
    [_defalutSelectImages removeAllObjects];
    PGGalleryProgressHUD *hud = [self showWaiting];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *retObject = [NSMutableDictionary dictionary];
        [retObject setObject:[NSNumber numberWithBool:self.mOptions.multiple] forKey:@"multiple"];
        NSMutableArray *fileS = [NSMutableArray array];
        [retObject setObject:fileS forKey:@"files"];
        __block int retCode = PGPluginOK;
        [assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ALAsset *asset = (ALAsset*)obj;
            NSString *outFilePath = nil;
            NSString *mediaType = [asset valueForProperty:ALAssetPropertyType];
            
            if ( [mediaType isEqualToString:(NSString*)ALAssetTypePhoto] ) {
                
                outFilePath =  [PTPathUtil absolutePath:self.mOptions.savePath
                                      suggestedFilename:[[asset defaultRepresentation] filename]
                                                 prefix:PGGALLERY_PHOTO_PREFIX
                                                 suffix:PGGALLERY_PHOTO_SUFFIX
                                          allowSameName:YES
                                                context:self.appContext];
                [self writeALAsset:asset toFile:outFilePath];
//                CGImageRef assetImage = defaultRepresentation.fullResolutionImage;
//                if ( assetImage ) {
//                   // NSString *fileName = defaultRepresentation.filename;
//                    UIImage *originalImage = [UIImage imageWithCGImage:assetImage scale:1.0 orientation:(UIImageOrientation)defaultRepresentation.orientation];
//                    if ( originalImage ) {
//                        originalImage = [originalImage adjustOrientation ];
//                        mediaData = UIImageJPEGRepresentation(originalImage, 0.5f);
//                        outFilePath =  [PTPathUtil absolutePath:self.mOptions.savePath
//                                                         prefix:PGGALLERY_PHOTO_PREFIX
//                                                         suffix:PGGALLERY_PHOTO_SUFFIX
//                                                        context:self.appContext];
//                    }
//                }
            } else if ( [mediaType isEqualToString:(NSString*)ALAssetTypeVideo] ) {
                outFilePath =  [PTPathUtil absolutePath:self.mOptions.savePath
                                      suggestedFilename:[[asset defaultRepresentation] filename]
                                                 prefix:PGGALLERY_VIDEO_PREFIX
                                                 suffix:PGGALLERY_VIDEO_SUFFIX
                                          allowSameName:YES
                                                context:self.appContext];
               [self writeALAsset:asset toFile:outFilePath];
            } else {
                retCode = PGPluginErrorIO;
                *stop = true;
            }
            if ( PGPluginOK == retCode ) {
                if ( !_defalutSelectImages ) {
                    _defalutSelectImages = [NSMutableDictionary dictionary];
                }
                NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                if ( assetURL ) {
                    NSString *shortPath = [self shortPath:outFilePath];
                    if ( shortPath ) {
                        [_defalutSelectImages setObject:[assetURL absoluteString] forKey:shortPath];
                    }
                }
                outFilePath = [[NSURL fileURLWithPath:outFilePath] absoluteString];
                [fileS addObject:outFilePath];
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:NO];
            [hud removeFromSuperview];
            [self dismissImagePickerController];
            PDRPluginResult *result = nil;
            self.flushMaptabel = true;
            if ( PGPluginOK != retCode || [fileS count] == 0 ) {
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:retCode];
                [self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
            } else {
                //NSString *retPath = //[PTPathUtil relativePath:photoPicker.saveFileName];
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:retObject];//[[NSURL fileURLWithPath:filePath] absoluteString]];
                [self toCallback:self.mOptions.callbackId  withReslut:[result toJSONString]];
            }
            [self closePickerController];
        });
    });
}

- (void)imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    [self dismissImagePickerController];
    [self toErrorCallback:self.mOptions.callbackId withCode:[self isAuthorizationStatusAuthorized]?PGPluginErrorUserCancel:PGPluginErrorNotPermission];
    [self closePickerController];
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
