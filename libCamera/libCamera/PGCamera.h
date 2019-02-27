/*
 *------------------------------------------------------------------
 *  pandora/feature/camera/pg_camera.h
 *  Description:
 *      摄像头头文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-1-9 创建文件
 *------------------------------------------------------------------
 */

#import "PGPlugin.h"
#import "PGMethod.h"
#import "PGGallery.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PGCameraOptionType) {
    PGCameraOptionTypeVideo, // video
    PGCameraOptionTypePhoto // image
};

typedef NS_ENUM(NSInteger, PGCameraEncodingType) {
    PGCameraEncodingTypePNG, // png
    PGCameraEncodingTypeJPEG, // image
    PGCameraEncodingTypeMOV // mov
};

@interface PGCameraOption : PGBaseOption

+(PGCameraOption*)optionWithJSON:(NSDictionary*)json;

@property(nonatomic, retain)NSString *savePath;
@property(nonatomic, assign)UIImagePickerControllerQualityType resolution;
@property(nonatomic, assign)UIImagePickerControllerCameraDevice cameraDevice;
@property(nonatomic, assign)PGCameraOptionType captureMode;
@property(nonatomic, assign)PGCameraEncodingType encodingType;
@property(nonatomic, assign)CGRect rect;
@property(nonatomic, assign)BOOL rectValid;
@property(nonatomic, assign)float videoMaximumDuration;
@property(nonatomic, copy)NSString *callbackId;

@end

@interface PGImagePickerController : UIImagePickerController
{}

@property (copy)   NSString* callbackId;
@property (strong) UIPopoverController* popoverController;
@property (assign) BOOL popoverSupported;
@property (copy) NSString *saveFileName;
@property (assign) BOOL animated;

@end

/*
 **@摄像头插件
 */
@interface PGCamera : PGPlugin<UIImagePickerControllerDelegate,
UINavigationControllerDelegate,UIPopoverControllerDelegate>
{
    @private
}
@property(nonatomic, retain)UIImage *tempImage;
@property(nonatomic, retain)PGBaseOption *mOptions;
@property (readwrite, assign) BOOL hasPendingOperation;
@property (strong) PGImagePickerController* pickerController;
-(NSData*)getCamera:(PGMethod*)commands;
-(void)captureImage:(PGMethod*)commands;
-(void)startVideoCapture:(PGMethod*)commands;
-(void)stopVideoCapture:(PGMethod*)commands;
//tools
@end
