//
//  UPVideoSource.h
//  UPLiveSDKDemo
//
//  Created by 林港 on 16/8/15.
//  Copyright © 2016年 upyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"


typedef void(^WatermarkBlock)();


typedef NS_ENUM(NSInteger, UPCustomFilter) {
    /// 用途:素描. 效果:素描结果
    UPCustomFilterSketch,
    /// 用途:优雅. 效果:优雅  这个滤镜和 美颜, 水印冲突
    UPCustomFilterSoftElegance,
    /// 用途:. 效果:
    UPCustomFilterMissEtikate,
    /// 用途:怀旧复古. 效果:照片锐化，有品红和紫红融合的色调，边框是照片齿孔的形状
    UPCustomFilterNashville,
    /// 用途:真 复古. 效果:超级过度饱和， 超级复古的照片
    UPCustomFilterLordKelvin,
    /// 用途: . 效果:
    UPCustomFilterAmatorka,
    /// 用途: . 效果:
    UPCustomFilterRise,
    /// 用途: . 效果:
    UPCustomFilterHudson,
    /// 用途:海滩. 效果:暖色，过度饱和色调，特别强调绿色和浅绿
    UPCustomFilterXproII,
    /// 用途:唤起怀旧情绪. 效果:仿佛音乐人Gloria Gaynor 那种70年代的风貌
    UPCustomFilter1977,
    /// 用途:狗狗. 效果:接近现实的反差，有一点点灰色和棕色过度饱和
    UPCustomFilterValencia,
    /// 用途:聚会. 效果:褪色且呈现浅蓝色调
    UPCustomFilterWalden,
    /// 用途:食物. 效果:梦幻色彩，带着一点虚化，黄色和绿色有些过饱和
    UPCustomFilterLomofi,
    /// 用途:黑白怀旧. 效果:黑白色调，高反差
    UPCustomFilterInkwell,
    /// 用途: . 效果:
    UPCustomFilterSierra,
    /// 用途:早午餐. 效果:褪色的、模糊的颜色，特别突出黄色和米黄色
    UPCustomFilterEarlybird,
    /// 用途:产生艺术感. 效果:旧照片的色调，特别突出紫红和棕色
    UPCustomFilterSutro,
    /// 用途:BBQ. 效果:过度曝光，边缘有暗角
    UPCustomFilterToaster,
    /// 用途:动物,如:狗狗. 效果:暗色调，凸显灰色和绿色
    UPCustomFilterBrannan,
    /// 用途:复古 . 效果:模糊不清，黄色和金色色调
    UPCustomFilterHefe
};

typedef NS_ENUM(NSInteger, UPAVCapturerPresetLevel) {
    UPAVCapturerPreset_480x360,
    UPAVCapturerPreset_640x480,
    UPAVCapturerPreset_960x540,
    UPAVCapturerPreset_1280x720
};

@protocol UPVideoCaptureProtocol <NSObject>
- (void)didCapturePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end


@interface UPVideoCapture : NSObject
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, weak) id<UPVideoCaptureProtocol> delegate;

@property (nonatomic, strong) NSString *outStreamPath;
@property (nonatomic) AVCaptureDevicePosition camaraPosition;
@property (nonatomic) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic) UPAVCapturerPresetLevel capturerPresetLevel;
@property (nonatomic) CGSize capturerPresetLevelFrameCropSize;
@property (nonatomic) int32_t fps;//设置采集帧频
@property (nonatomic) BOOL streamingOn;//默认为 YES，即 UPAVCapturer start 之后会立即推流直播;
@property (nonatomic) BOOL camaraTorchOn;
@property (nonatomic) BOOL beautifyOn;//美颜滤镜开
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;//美颜参数调整

/**The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0*/
@property (nonatomic, assign) CGFloat viewZoomScale;
@property (nonatomic, strong) UIView *watermarkView;

- (void)start;
- (void)stop;
- (void)restart;
- (void)switchCamera;
- (void)setCamaraPosition:(AVCaptureDevicePosition)camaraPosition;
- (void)setWatermarkView:(UIView *)watermarkView Block:(WatermarkBlock) block;

- (UIView *)previewWithFrame:(CGRect)frame contentMode:(UIViewContentMode)mode;
- (void)resetCapturerPresetLevelFrameSizeWithCropRect:(CGSize)cropRect;

- (void)setCamaraTorchOn:(BOOL)camaraTorchOn;

/// 单个滤镜 用户可以使用自定义滤镜
- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter;
/// 单个滤镜 用户可以使用已定义好的滤镜名字
- (void)setFilterName:(UPCustomFilter)filterName;

/// 多个滤镜 用户可以使用自定义滤镜 filters : 自定义滤镜数组
- (void)setFilters:(NSArray *)filters;
/// 多个滤镜 用户可以使用已定义好的滤镜 filterNames: 已定义滤镜的数组
- (void)setFilterNames:(NSArray *)filterNames;

@end
