//
//  GPUImageBeautifyFilter.h
//  UPLiveSDKDemo
//
//  Created by 林港 on 16/8/17.
//  Copyright © 2016年 upyun.com. All rights reserved.
//

//
//  GPUImageBeautifyFilter.h
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/28.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "GPUImage.h"

@class GPUImageCombinationFilter;
@class GPUImageSobelEdgeDetectionFilter;

@interface GPUImageBeautifyFilter : GPUImageFilterGroup {
    // 修改参考 http://www.jianshu.com/p/dde412cab8db

}





/// 美颜效果。值越大效果越强。可适当调整
@property (nonatomic, assign)CGFloat level;//默认值 0.6

/// 磨皮, 双边模糊，平滑处理。值越小效果越强。建议保持默认值。
@property (nonatomic, assign)CGFloat bilateralLevel;//默认值 4.0

/// 饱和度。值越小画面越灰白，值越大色彩越强烈。可适当调整。
@property (nonatomic, assign)CGFloat saturationLevel;//默认值 1.1

/// 亮度。值越小画面越暗，值越大越明亮。可适当调整。
@property (nonatomic, assign)CGFloat brightnessLevel;//默认值 1.1


@property (nonatomic, strong) GPUImageHSBFilter *hsbFilter;
@property (nonatomic, strong) GPUImageBilateralFilter *bilateralFilter;
@property (nonatomic, strong) GPUImageSobelEdgeDetectionFilter *sobelEdgeFilter;
@property (nonatomic, strong) GPUImageCombinationFilter *combinationFilter;



@end
