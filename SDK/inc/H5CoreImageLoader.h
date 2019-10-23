//
//  H5CoreImageLoader.h
//  libNativeObj
//
//  Created by DCloud on 2017/3/29.
//  Copyright © 2017年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDRToolSystemEx.h"

@protocol H5CoreImageLoaderDelegate <NSObject>
@optional
-(void)imageloadError:(NSError*)error imagePath:(NSString*)imgPath;
-(void)imageloadError:(NSError*)error userInfo:(id)userInfo;
-(void)imageLoaded:(id)image userInfo:(id)userInfo;
-(void)imageLoaded:(id)image type:(PTImageType)type userInfo:(id)userInfo;
@end

@interface H5CoreImageLoader : NSObject
@property(nonatomic, retain)NSString *rootLoaderPath;
- (void)loadImage:(NSString*)imgPath
     withDelegate:(id<H5CoreImageLoaderDelegate>)delegate
      withContext:(id)userInfo;
- (void)cancelloadImage:(NSString*)imgPath
           withDelegate:(id<H5CoreImageLoaderDelegate>)delegate
            withContext:(id)userInfo;

- (void)releseImage:(NSString*)imgPath;
- (void)clearImageInMemory:(NSString*)imgPath;
- (void)removeOverCountCacheImage;
//- (void)removeDelegateWithContext:(id)userInfo;

/** 加载压缩后的图片 */
- (UIImage *)getThumbnailImageWithImageURL:(NSString *)newPath;
@end
