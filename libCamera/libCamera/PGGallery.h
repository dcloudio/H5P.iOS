/*
 *------------------------------------------------------------------
 *  pandora/feature/cache/pg_gallery.h
 *  Description:
 *      打开相册文件
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

#import "PGPlugin.h"
#import "PGMethod.h"
#import "QBImagePickerController.h"

typedef NS_ENUM(NSInteger, PGGalleryStatus) {
    PGGalleryStatusReady,
    PGGalleryStatusBusy
};

typedef NS_ENUM(NSInteger, PGGalleryFilters) {
    PGGalleryFiltersNone,
    PGGalleryFiltersPhoto,
    PGGalleryFiltersVideo
};

typedef NS_ENUM(NSInteger, PGGalleryError) {
    PGGalleryErrorCancel = PGPluginErrorNext
};

@interface PGBaseOption : NSObject
@property(nonatomic, retain)NSString *savePath;
@property(nonatomic, assign)CGRect rect;
@property(nonatomic, assign)BOOL rectValid;
@property(nonatomic, copy)NSString *callbackId;
@property(nonatomic, assign)BOOL animation;
- (void)parse:(NSDictionary*)params withStaffRect:(CGRect)staffRect;
@end

@interface PGGalleryOption : PGBaseOption

@property(nonatomic, assign)PGGalleryFilters filters;
@property(nonatomic, assign)BOOL multiple;
@property(nonatomic, assign)NSInteger maximum;
@property(nonatomic, copy)NSString *onmaxedCBId;
@property(nonatomic, copy)NSArray<NSURL*> *selected;
- (void)parse:(NSDictionary*)params withStaffRect:(CGRect)staffRect;
+(PGGalleryOption*)optionWithJSON:(NSDictionary*)json
                    withStaffRect:(CGRect)staffRect;
@end
/*
 **@缓存插件
 */
@interface PGGallery :PGPlugin
                    <UIImagePickerControllerDelegate,
                    UINavigationControllerDelegate,
                    UIPopoverControllerDelegate,QBImagePickerControllerDelegate>
{
    UIStatusBarStyle _statusBarStyle;
    NSMutableDictionary *_defalutSelectImages;
}
@property (readwrite, assign) BOOL hasPendingOperation;
@property(nonatomic, retain)PGGalleryOption *mOptions;
@property (strong) UINavigationController* pickerController;
@property (strong) UIPopoverController* popoverController;
@property (nonatomic, strong) NSString *mapTableFlushPath;
@property (assign) BOOL flushMaptabel;
// for iOS5
@property(nonatomic, strong)UIImagePickerController *systemPickerController;
#pragma mark js invoke method
//调用系统相册
-(void)pick:(PGMethod*)commands;
//保存图片到系统相册
-(void)save:(PGMethod*)commands;
- (void)popImgaeControllerWithOptions:(PGGalleryOption*)popOptions;
//tool
- (CGRect)getDefaultPopRect;
//-(void)result:(PDRCommandStatus)resultCode message:(NSString*)message callBackId:(NSString*)callbackId;
- (BOOL)popoverSupported;
#pragma mark local method

@end