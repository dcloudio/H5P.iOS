/*
 *------------------------------------------------------------------
 *  pandora/feature/camera/pg_camera.mm
 *  Description:
 *    摄像头实现文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *    number    author    modify date modify record
 *   0       xty     2013-1-9 创建文件
 *------------------------------------------------------------------
 */
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "PGCamera.h"
#import "PDRToolSystemEx.h"
#import "PTPathUtil.h"
#import "PDRCoreWindowManager.h"
#import "PDRCoreAppWindow.h"
#import "PDRCommonString.h"
#import "PDRCoreDefs.h"
#import "PGGalleryProgressHUD.h"
@implementation PGCameraOption

@synthesize savePath;
@synthesize resolution;
@synthesize cameraDevice;
@synthesize captureMode;
@synthesize encodingType;
@synthesize rect, rectValid;
@synthesize callbackId;

-(id)init {
    if ( self = [super init] ) {
        self.encodingType = PGCameraEncodingTypeJPEG;
        self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.resolution = UIImagePickerControllerQualityType640x480;
        self.rect = CGRectZero;
        self.rectValid = FALSE;
    }
    return self;
}

+(PGCameraOption*)optionWithJSON:(NSDictionary*)json
{
    PGCameraOption *option = [[PGCameraOption alloc] init];
    if ( [json isKindOfClass:[NSDictionary class]] ){
        NSString *resolutionV = [json objectForKey:@"resolution"];
        option.resolution = UIImagePickerControllerQualityType640x480;
        if ( [resolutionV isKindOfClass:[NSString class]] ) {
            if ( [@"640*480" isEqualToString:resolutionV] ) {
                option.resolution = UIImagePickerControllerQualityType640x480;
            } else if ([@"1280*720" isEqualToString:resolutionV]) {
                option.resolution = UIImagePickerControllerQualityTypeIFrame1280x720;
            } else if ([@"960*540" isEqualToString:resolutionV]) {
                option.resolution = UIImagePickerControllerQualityTypeIFrame960x540;
            } else if ( [@"high" isEqualToString:resolutionV] ) {
                option.resolution = UIImagePickerControllerQualityTypeHigh;
            } else if ([@"medium" isEqualToString:resolutionV]) {
                option.resolution = UIImagePickerControllerQualityTypeMedium;
            } else if ([@"low" isEqualToString:resolutionV]) {
                option.resolution = UIImagePickerControllerQualityTypeLow;
            }
        }
        //设置图片的保存格式
        NSString *format = [json objectForKey:@"format"];
        if ( [format isKindOfClass:[NSString class]] ){
            if ( [format isEqualToString:g_pdr_string_png] ){
                option.encodingType = PGCameraEncodingTypePNG;
            }
        }
        //获取保存位置
        NSString *dstPath = [json objectForKey:g_pdr_string_filename];
        if ( [dstPath isKindOfClass:[NSString class]] ){
            option.savePath = dstPath ;
        }
        
        //获取使用的摄像头
        NSString *deviceIndex = [json objectForKey:@"index"];
        if ( [deviceIndex isKindOfClass:[NSString class]]
            || [deviceIndex isKindOfClass:[NSNumber class]]){
            if ( 2 == [deviceIndex integerValue] ){
                option.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
        }
        
        option.videoMaximumDuration = [PGPluginParamHelper getFloatValueInDict:json forKey:@"videoMaximumDuration" defalut:0];
        
        //获取弹出位置
        CGRect rect = CGRectZero;
        NSDictionary *popover = [json objectForKey:g_pdr_string_popover];
        if ( [popover isKindOfClass:[NSDictionary class]] ) {
            option.rectValid = true;
            NSNumber *topArgs = [popover objectForKey:g_pdr_string_top];
            if ( [topArgs isKindOfClass:[NSNumber class]] ) {
                rect.origin.x = [topArgs intValue];
            } else {
                option.rectValid = false;
            }
            
            NSNumber *leftArgs = [popover objectForKey:g_pdr_string_left];
            if ( [leftArgs isKindOfClass:[NSNumber class]] ) {
                rect.origin.y = [leftArgs intValue];
            } else {
                option.rectValid = false;
            }
            
            NSNumber *widthArgs = [popover objectForKey:g_pdr_string_width];
            if ( [widthArgs isKindOfClass:[NSNumber class]] ) {
                rect.size.width = [widthArgs intValue];
            } else {
                option.rectValid = false;
            }
            
            NSNumber *heigthArgs = [popover objectForKey:g_pdr_string_height];
            if ( [heigthArgs isKindOfClass:[NSNumber class]] ) {
                rect.size.height = [heigthArgs intValue];
            } else {
                option.rectValid = false;
            }
            option.rect = rect;
        }
    }
    return H5_AUTORELEASE(option);
}

-(void)dealloc {
    self.callbackId = nil;
    self.savePath = nil;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

@end

@implementation PGImagePickerController

@synthesize callbackId;
@synthesize popoverController;
@synthesize popoverSupported;
@synthesize saveFileName;
@synthesize  animated;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return false;
}
- (void)viewDidLayoutSubviews NS_AVAILABLE_IOS(5_0){
    //   [self.view setNeedsLayout];
}

- (void)didReceiveMemoryWarning {}

// New Autorotation support.
- (BOOL)shouldAutorotate {
    return FALSE;
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [callbackId release];
    [popoverController release];
    [saveFileName release];
    [super dealloc];
#endif
}

@end

@implementation PGCamera
@synthesize pickerController;
@synthesize mOptions;
@synthesize hasPendingOperation;

-(void)dealloc
{
    self.tempImage = nil;
    self.mOptions = nil;
    if ( UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM() ) {
        //  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (PGPlugin*) initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp*)app {
    if ( self = [super initWithWebView:theWebView withAppContxt:app] ){
        //        if ( UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM() ) {
        //            [[NSNotificationCenter defaultCenter] addObserver:self
        //                                                     selector:@selector(onDeviceOrientationDidChange:)
        //                                                         name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        //        }
        
    }
    return self;
}

-(NSData*)getCamera:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return nil;
        
    }
    
    //  NSString *uuid = [command.arguments objectAtIndex:0];
    return nil;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      拍摄照片
 * @Parameters:
 *    [1] command, js调用格式应该为 {}
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)captureImage:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return;
    }
    
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSDictionary *dict = (NSDictionary*)[command.arguments objectAtIndex:1];
    PGCameraOption *option = [PGCameraOption optionWithJSON:dict];
    option.captureMode = PGCameraOptionTypePhoto;
    option.callbackId = callbackId;
    self.mOptions = option;

    if ([self authorizeStatus]==PGPluginAuthorizeStatusDenied) {
        [self result:PDRCommandStatusError message:@"No filming permission" callBackId:option.callbackId];
        return;
    }
    
    [self startWithOption:option];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      开始拍摄视频
 * @Parameters:
 *    [1] command, js调用格式应该为 {}
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)startVideoCapture:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return;
    }
    
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSDictionary *dict = (NSDictionary*)[command.arguments objectAtIndex:1];
    PGCameraOption *option = [PGCameraOption optionWithJSON:dict];
    option.captureMode = PGCameraOptionTypeVideo;
    option.callbackId = callbackId;
    self.mOptions = option;
    
    AVAudioSession* sharedSession = [AVAudioSession sharedInstance];
    if ([sharedSession respondsToSelector:@selector(recordPermission)]) {
        AVAudioSessionRecordPermission permission = [sharedSession recordPermission];
        if (permission==AVAudioSessionRecordPermissionDenied) {
            [self result:PDRCommandStatusError message:@"No microphone permissions" callBackId:option.callbackId];
            return;
        }
    }

    if ([self authorizeStatus]==PGPluginAuthorizeStatusDenied) {
        [self result:PDRCommandStatusError message:@"No filming permission" callBackId:option.callbackId];
        return;
    }
    
    [self startWithOption:option];
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      拍摄视频
 * @Parameters:
 *    [1] command, js调用格式应该为 {}
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)stopVideoCapture:(PGMethod*)commands
{
    if ( self.hasPendingOperation  ) {
        PGImagePickerController* photoPicker = (PGImagePickerController*)self.pickerController;
        [photoPicker stopVideoCapture];
    }
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      测试指定的设备是否存在
 * @Parameters:
 *    [1] command, js调用格式应该为 {}
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(BOOL)isCameraDeviceAvailable:(UIImagePickerControllerCameraDevice)cameraDevice
{
    if ( [UIImagePickerController instancesRespondToSelector:@selector (isCameraDeviceAvailable:)] )
    {
        return [UIImagePickerController isCameraDeviceAvailable:cameraDevice];
    }
    else
    {
        return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    }
    return FALSE;
}
/*
 *------------------------------------------------------------------
 * @Summary:
 *      测试是否支持指定的模式
 * @Parameters:
 *    [1] command, js调用格式应该为 {}
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(BOOL)isCameraDevice:(UIImagePickerControllerCameraDevice)cameraDevice support:(PGCameraOptionType)type
{
    // for ios 4.0 later
    if ( [UIImagePickerController instancesRespondToSelector:@selector (availableCaptureModesForCameraDevice:)] ){
        NSArray *captureModes = [UIImagePickerController availableCaptureModesForCameraDevice:cameraDevice];
        for ( NSNumber *mode in captureModes ){
            if ( UIImagePickerControllerCameraCaptureModeVideo == [mode intValue]
                && PGCameraOptionTypeVideo == type ) {
                return TRUE;
            }
            if ( UIImagePickerControllerCameraCaptureModePhoto == [mode intValue]
                && PGCameraOptionTypePhoto == type ) {
                return TRUE;
            }
        }
    }
    else{
        NSArray *mediaTypes =  [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ( [mediaTypes containsObject:(NSString*)kUTTypeImage]
            && PGCameraOptionTypePhoto == type ) {
            return TRUE;
        }
        if ( [mediaTypes containsObject:(NSString*)kUTTypeMovie]
            && PGCameraOptionTypeVideo == type ) {
            return TRUE;
        }
    }
    
    return FALSE;
}
/*
 *------------------------------------------------------------------
 * @Summary:
 *      开始拍摄视频
 * @Parameters:
 *    [1] command, js调用格式应该为 {}
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)startWithOption:(PGCameraOption*)option
{
    if ( self.hasPendingOperation ) {
        [self result:PDRCommandStatusError message:@"device busy" callBackId:option.callbackId];
        return;
    }
#if !(TARGET_IPHONE_SIMULATOR)
    UIImagePickerControllerCameraDevice cameraDevice = option.cameraDevice;
    //测试camra是否有效
    if ( ![self isCameraDeviceAvailable:cameraDevice] ) {
        [self result:PDRCommandStatusError message:@"device invalid" callBackId:option.callbackId];
        return;
    }
    
    //如果是录像测试是否支持
    if ( ![self isCameraDevice:cameraDevice support:option.captureMode] ) {
        [self result:PDRCommandStatusError message:@"no support" callBackId:option.callbackId];
        return;
    }
#endif
    self.pickerController = H5_AUTORELEASE([[PGImagePickerController alloc] init]);
    self.pickerController.delegate = self;
    self.pickerController.callbackId = option.callbackId;
    self.pickerController.animated = YES;
    //for debugy
#if TARGET_IPHONE_SIMULATOR
    self.pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
    self.pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.pickerController.cameraDevice = cameraDevice;
    self.pickerController.videoQuality = option.resolution;
    if (@available(iOS 11.0, *)) {
        self.pickerController.imageExportPreset = UIImagePickerControllerImageURLExportPresetCurrent;
    } else {
        // Fallback on earlier versions
    }
    
    
    //   if ( [self.pickerController respondsToSelector:@selector(setCameraCaptureMode:)] )
    {
        if ( PGCameraOptionTypeVideo == option.captureMode )
        {
            //self.pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        }
        else
        {
            // self.pickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        }
    }
    // else
    {
        NSMutableArray* pMutableArray = nil;
        if ( PGCameraOptionTypeVideo == option.captureMode )
        {
            pMutableArray = [NSMutableArray arrayWithObject:(NSString*)kUTTypeMovie];
        }
        else
        {
            pMutableArray = [NSMutableArray arrayWithObject:(NSString*)kUTTypeImage];
        }
        self.pickerController.mediaTypes = pMutableArray;
    }
#endif
    
    
    if ( PGCameraOptionTypeVideo == option.captureMode ){
        self.pickerController.saveFileName = [PTPathUtil absolutePath:option.savePath
                                                               prefix:@"video_"
                                                               suffix:@"mp4"
                                                              context:self.appContext];
        self.pickerController.videoMaximumDuration = option.videoMaximumDuration;
    } else {
        if ( PGCameraEncodingTypeJPEG ==  option.encodingType ) {
            self.pickerController.saveFileName = [PTPathUtil absolutePath:option.savePath
                                                                   prefix:@"photo_"
                                                                   suffix:g_pdr_string_jpg
                                                                  context:self.appContext];
        } else {
            self.pickerController.saveFileName = [PTPathUtil absolutePath:option.savePath
                                                                   prefix:@"photo_"
                                                                   suffix:g_pdr_string_png
                                                                  context:self.appContext];
        }
    }
#if !TARGET_IPHONE_SIMULATOR
    // [self setTransform];
#endif
    [self popImgaeControllerWithOptions:self.mOptions];
}

- (BOOL)popoverSupported
{
    if ( [PTDeviceOSInfo systemVersion]  >= PTSystemVersion8Series) {
        return FALSE;
    }
    return (NSClassFromString(@"UIPopoverController") != nil) &&
    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}


- (void)popImgaeControllerWithOptions:(PGBaseOption*)popOptions {
    //self.pickerController.cameraViewTransform = transform;
    if ([self popoverSupported] ) {
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        if (pickerController.popoverController == nil) {
            pickerController.popoverController = H5_AUTORELEASE([[NSClassFromString (@"UIPopoverController")alloc] initWithContentViewController:pickerController]);
        }
        pickerController.popoverSupported = YES;
        
        CGRect popoverRect = CGRectMake(0, 0, 1, 1);
        UIPopoverArrowDirection arrowDirection = UIPopoverArrowDirectionUp;
        if ( popOptions.rectValid )  {
            popoverRect = popOptions.rect;
            arrowDirection = UIPopoverArrowDirectionAny;
        } else {
            popoverRect = [self getDefaultPopRect];
        }
        
        pickerController.popoverController.delegate = self;
        [pickerController.popoverController presentPopoverFromRect:popoverRect
                                                            inView:self.JSFrameContext
                                          permittedArrowDirections:arrowDirection
                                                          animated:popOptions.animation];
    }
    else {
        [self presentViewController:pickerController animated:popOptions.animation completion:nil];
    }
    self.hasPendingOperation = YES;
}

-(void)onDeviceOrientationDidChange:(NSNotification*)notification {
#if !TARGET_IPHONE_SIMULATOR
    [self setTransform];
#endif
    return;
    CGRect popoverRect = CGRectMake(0, 0, 1, 1);
    if ( self.mOptions.rectValid )  {
        popoverRect = self.mOptions.rect;
    } else {
        popoverRect = [self getDefaultPopRect];
    }
    
    [self.pickerController.popoverController dismissPopoverAnimated:NO];
    [self.pickerController.popoverController setContentViewController:self.pickerController];
    [self.pickerController.popoverController presentPopoverFromRect:popoverRect
                                                             inView:self.JSFrameContext
                                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                                           animated:NO];
}

- (CGRect)getDefaultPopRect {
    CGRect popRect = CGRectMake(0, 0, 1, 1);
    popRect.origin.x = self.JSFrameContext.center.x;
    popRect.origin.y = self.JSFrameContext.center.y - 240;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            popRect.origin.y = self.JSFrameContext.center.y - 160;
            break;
        default:
            break;
    }
    return popRect;
}

- (void)setTransform {
    //  return;
    CGAffineTransform transform = CGAffineTransformIdentity;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            transform = CGAffineTransformIdentity;
            break;
        case UIInterfaceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(M_PI/2*3);
            // transform = CGAffineTransformTranslate(transform, 80, 80);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI/2);
            // transform = CGAffineTransformTranslate(transform, -80, -80);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            transform = CGAffineTransformIdentity;
            break;
    }
    /*
     switch ([UIDevice currentDevice].orientation) {
     case UIDeviceOrientationPortrait:
     transform = CGAffineTransformIdentity;
     break;
     case UIDeviceOrientationLandscapeLeft:
     transform = CGAffineTransformMakeRotation(M_PI/2*3);
     transform = CGAffineTransformTranslate(transform, 80, 80);
     break;
     case UIDeviceOrientationLandscapeRight:
     transform = CGAffineTransformMakeRotation(M_PI/2);
     transform = CGAffineTransformTranslate(transform, -80, -80);
     break;
     case UIDeviceOrientationPortraitUpsideDown:
     transform = CGAffineTransformMakeRotation(M_PI);
     break;
     default:
     transform = CGAffineTransformIdentity;
     break;
     }*/
    self.pickerController.cameraViewTransform = transform;
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    if ( self.pickerController ) {
        [self dismissImagePickerController];
    }
    self.JSFrameContext = nil;
}

- (void)dismissImagePickerController
{
    if (self.popoverSupported && (self.pickerController.popoverController != nil)) {
        [self.pickerController.popoverController dismissPopoverAnimated:self.mOptions.animation];
        self.pickerController.popoverController.delegate = nil;
        //self.popoverController = nil;
    } else {
        [self dismissViewControllerAnimated:self.mOptions.animation completion:nil];
        //  self.pickerController = nil;
    }
    self.JSFrameContext = nil;
    self.hasPendingOperation = NO;
    self.pickerController = nil;
}

- (PGPluginAuthorizeStatus)authorizeStatus {
    if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion7Series) {
        AVAuthorizationStatus authstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authstatus ==AVAuthorizationStatusRestricted
            || authstatus ==AVAuthorizationStatusDenied ){
            return PGPluginAuthorizeStatusDenied;
        } else if (authstatus ==AVAuthorizationStatusNotDetermined) {
            return PGPluginAuthorizeStatusNotDetermined;
        } else if (authstatus ==AVAuthorizationStatusAuthorized) {
            return PGPluginAuthorizeStatusAuthorized;
        }
        return PGPluginAuthorizeStatusAuthorized;
    }
    return PGPluginAuthorizeStatusAuthorized;
}

#pragma mark --------------
#pragma mark delegate
- (void)popoverControllerDidDismissPopover:(id)popoverController
{
    // [ self imagePickerControllerDidCancel:self.pickerController ];    '
    UIPopoverController* pc = (UIPopoverController*)popoverController;
    
    [pc dismissPopoverAnimated:YES];
    pc.delegate = nil;
    
    if (self.pickerController && self.pickerController.callbackId && self.pickerController.popoverController) {
        self.pickerController.popoverController = nil;
        [self result:PDRCommandStatusError message:@"cancel" callBackId:self.pickerController.callbackId];
    }
    self.hasPendingOperation = NO;
    self.pickerController = nil;
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

- (UIImage*)fixPNGCaptureOrientation:(UIImage*)anImage
{
    float rotation_radians = 0;
    bool perpendicular = false;
    
    switch ([anImage imageOrientation]) {
        case UIImageOrientationUp :
            rotation_radians = 0.0;
            break;
            
        case UIImageOrientationDown :
            rotation_radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
            break;
            
        case UIImageOrientationRight:
            rotation_radians = M_PI_2;
            perpendicular = true;
            break;
            
        case UIImageOrientationLeft:
            rotation_radians = -M_PI_2;
            perpendicular = true;
            break;
            
        default:
            break;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Rotate around the center point
    CGContextTranslateCTM(context, anImage.size.width / 2, anImage.size.height / 2);
    CGContextRotateCTM(context, rotation_radians);
    
    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? anImage.size.height : anImage.size.width;
    float height = perpendicular ? anImage.size.width : anImage.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);
    
    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -anImage.size.height / 2, -anImage.size.width / 2);
    }
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)processImage:(UIImage *)image {
    PGCameraOption *cameraOptions = (PGCameraOption*)self.mOptions;
    CGFloat imageSize = MAX(image.size.width, image.size.height);
    CGFloat afterSize = 1024;
    if ( UIImagePickerControllerQualityTypeIFrame1280x720 == cameraOptions.resolution ) {
        afterSize = 1280;
    } else if( UIImagePickerControllerQualityTypeIFrame960x540 == cameraOptions.resolution ) {
        afterSize = 960;
    } else if ( UIImagePickerControllerQualityType640x480 == cameraOptions.resolution ){
        afterSize = 640;
    } else  {
        if (image.imageOrientation == UIImageOrientationUp) return image;
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:(CGRect){0, 0, image.size}];
        UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
    
    CGFloat factor = afterSize/imageSize;
    CGFloat newW = image.size.width * factor;
    CGFloat newH = image.size.height * factor;
    CGSize newSize = CGSizeMake(newW, newH);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newW, newH)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    PGImagePickerController* photoPicker = (PGImagePickerController*)picker;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    PGGalleryProgressHUD *hud = nil;
    if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
         hud = [self showWaiting];
    }
    
    if (photoPicker.popoverSupported && (photoPicker.popoverController != nil)) {
        [photoPicker.popoverController dismissPopoverAnimated:YES];
        photoPicker.popoverController.delegate = nil;
        photoPicker.popoverController = nil;
    } else {
        if ([photoPicker respondsToSelector:@selector(presentingViewController)]) {
            [[photoPicker presentingViewController] dismissModalViewControllerAnimated:YES];
        } else {
            [[photoPicker parentViewController] dismissModalViewControllerAnimated:YES];
        }
    }
    
    UIImage  *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *mediaURL = [info objectForKey: UIImagePickerControllerMediaURL];
    // NSDictionary *imageMetadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
    [PDRCore runInBackgroud:^{
        if ( [mediaType isEqualToString:(NSString*)kUTTypeImage] ) {
            // imageMetadata = NULL;
            @autoreleasepool {
                self.tempImage = [self processImage:originalImage];
            }
            
            if ( UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM() ) {
                // originalImage = [UIImage imageWithCGImage:originalImage.CGImage scale:1.0 orientation:UIImageOrientationRight];
            }
            //originalImage = [originalImage imageRotatedByDegrees:90 supportRetina:NO scale:1.0];
            //  UIImage  *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
            //  NSValue *cropRect = [info objectForKey:UIImagePickerControllerCropRect];
            //  NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];
            //   NSDictionary *metaData = [info objectForKey:UIImagePickerControllerMediaMetadata];
            //   NSData *data = [UIImage lubanCompressImage:originalImage];
            //     [data writeToFile:photoPicker.saveFileName options:NSAtomicWrite error:nil];
            PGCameraOption *cameraOptions = (PGCameraOption*)self.mOptions;
            [self saveImage:self.tempImage encodingType:cameraOptions.encodingType properties:/*(CFDictionaryRef)imageMetadata*/NULL toFile:photoPicker.saveFileName];
            // originalImage = [self fixPNGCaptureOrientation:originalImage];
            //                            if (cameraOptions.encodingType == PGCameraEncodingTypePNG ){
            //                                data = UIImagePNGRepresentation(originalImage);
            //                            } else {
            //                                data = UIImageJPEGRepresentation(originalImage, 0.5f);
            //                            }
            //                            [data writeToFile:photoPicker.saveFileName options:NSAtomicWrite error:nil];
            self.tempImage = nil;
            [PDRCore runInMainThread:^{
                [self.appContext.appWindow recoveryCrashWebview];
                [self result:PDRCommandStatusOK
                     message:[PTPathUtil relativePath:photoPicker.saveFileName withContext:self.appContext] //[[NSURL fileURLWithPath:photoPicker.saveFileName] absoluteString]
                  callBackId:self.pickerController.callbackId];
                self.hasPendingOperation = NO;
                self.pickerController = nil;
            }];
        } else if ( [mediaType isEqualToString:(NSString*)kUTTypeMovie] ) {
//            NSData *data = [NSData dataWithContentsOfURL:mediaURL];
//            [data writeToFile:photoPicker.saveFileName options:NSAtomicWrite error:nil];
            
            NSURL *saveFileNameURL = [NSURL fileURLWithPath:photoPicker.saveFileName];
            [self lowQuailtyWithInputURL:mediaURL :saveFileNameURL blockHandler:^(AVAssetExportSession *session, NSURL *compressionVideoURL) {
                [hud hide:NO];

                self.tempImage = nil;
                [PDRCore runInMainThread:^{
                    [self.appContext.appWindow recoveryCrashWebview];
                    [self result:PDRCommandStatusOK
                         message:[PTPathUtil relativePath:photoPicker.saveFileName withContext:self.appContext] //[[NSURL fileURLWithPath:photoPicker.saveFileName] absoluteString]
                      callBackId:self.pickerController.callbackId];
                    self.hasPendingOperation = NO;
                    self.pickerController = nil;
                }];
            }];
        }
       
    }];
}
- (PGGalleryProgressHUD*)showWaiting {
    PGGalleryProgressHUD *hud = [PGGalleryProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    return hud;
}
- (void)lowQuailtyWithInputURL:(NSURL *)inputURL :(NSURL*)compressionVideoURL blockHandler:(void (^)(AVAssetExportSession *session, NSURL *compressionVideoURL))handler {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *session = nil;
        if ( self.pickerController.videoQuality == UIImagePickerControllerQualityType640x480) {
            session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset640x480];
        } else if ( self.pickerController.videoQuality == UIImagePickerControllerQualityTypeIFrame1280x720) {
            session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset1280x720];
        } else if ( self.pickerController.videoQuality == UIImagePickerControllerQualityTypeIFrame960x540) {
            session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset960x540];
        } else if ( self.pickerController.videoQuality == UIImagePickerControllerQualityTypeHigh) {
            session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
        } else if ( self.pickerController.videoQuality == UIImagePickerControllerQualityTypeMedium) {
            session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
        } else if ( self.pickerController.videoQuality == UIImagePickerControllerQualityTypeLow) {
            session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetLowQuality];
        }
    session.outputURL = compressionVideoURL;
    session.outputFileType = AVFileTypeMPEG4;
    session.shouldOptimizeForNetworkUse = YES;
    session.videoComposition = [self getVideoComposition:asset];
    [session exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(),^{
            switch ([session status]) {
                case AVAssetExportSessionStatusFailed:{
                    NSLog(@"Export failed: %@ : %@", [[session error] localizedDescription], [session error]);
                    handler(session, nil);
                    break;
                }case AVAssetExportSessionStatusCancelled:{
                    NSLog(@"Export canceled");
                    handler(session, nil);
                    break;
                }default:
                    handler(session,compressionVideoURL);
                    break;
            }
        });
    }];
}
- (AVMutableVideoComposition *)getVideoComposition:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) ||
           (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)){
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
    }
    composition.naturalSize    = videoSize;
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMakeWithSeconds( 1 / videoTrack.nominalFrameRate, 600);
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}

-(BOOL)saveImage:(UIImage *)image encodingType:(PGCameraEncodingType)encodingType
      properties:(CFDictionaryRef)properties toFile:(NSString *)filePath
{
    if (!image.CGImage) {
        return NO;
    }
    @autoreleasepool {
        float  quality = 0.0;
        //CGFloat maxPixelSize = MIN(image.size.width, 1024);
        
        CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue( attrs, kCGImageDestinationLossyCompressionQuality, CFNumberCreate(kCFAllocatorDefault,kCFNumberFloatType, &quality));
        //CFDictionarySetValue( attrs, kCGImageDestinationImageMaxPixelSize, CFNumberCreate(kCFAllocatorDefault,kCFNumberFloatType, &maxPixelSize));
        
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, (PGCameraEncodingTypePNG == encodingType)? kUTTypePNG:kUTTypeJPEG , 1, attrs);
        CFRelease(attrs);
        if (!destination) {
            return NO;
        }
        CGImageDestinationAddImage(destination, image.CGImage, properties);
        // CGImageDestinationAddImageAndMetadata(destination, image.CGImage, NULL,NULL );
        CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    
    return YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self imagePickerControllerDidClose:picker];
    self.hasPendingOperation = NO;
    [self result:PDRCommandStatusError message:@"cancel" callBackId:self.mOptions.callbackId];
    self.mOptions = nil;
}

- (void)imagePickerControllerDidClose:(UIImagePickerController*)picker {
    PGImagePickerController* photoPicker = (PGImagePickerController*)picker;
    if (photoPicker.popoverSupported && (photoPicker.popoverController != nil)) {
        [photoPicker.popoverController dismissPopoverAnimated:photoPicker.animated];
        photoPicker.popoverController.delegate = nil;
        photoPicker.popoverController = nil;
    } else {
        if ([photoPicker respondsToSelector:@selector(presentingViewController)]) {
            [[photoPicker presentingViewController] dismissModalViewControllerAnimated:photoPicker.animated];
        } else {
            [[photoPicker parentViewController] dismissModalViewControllerAnimated:photoPicker.animated];
        }
    }
    self.pickerController.delegate = nil;
    self.pickerController = nil;
}

-(void)result:(PDRCommandStatus)resultCode message:(NSString*)message callBackId:(NSString*)callbackId
{
    PDRPluginResult *result = nil;
    if ( PDRCommandStatusOK == resultCode ) {
        result = [PDRPluginResult resultWithStatus:resultCode messageAsString:message];
    } else {
        result = [PDRPluginResult resultWithStatus:resultCode messageToErrorObject:resultCode withMessage:message];
    }
    
    [self toCallback:callbackId  withReslut:[result toJSONString]];
}

@end

