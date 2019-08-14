//
//  FWInkwellFilter.h
//  FWMeituApp
//
//  Created by hzkmn on 16/1/11.
//  Copyright © 2016年 ForrestWoo co,.ltd. All rights reserved.
//

#import "GPUImage.h"

@interface FWFilter10 : GPUImageTwoInputFilter

@end

@interface FWInkwellFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource;
}

@end
