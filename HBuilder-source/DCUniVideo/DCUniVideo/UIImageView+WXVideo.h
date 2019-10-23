//
//  UIImageView+Video.h
//  libVideo
//
//  Created by DCloud on 2018/5/29.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "H5CoreImageLoader.h"
@interface UIImageView(WXH5Video)<H5CoreImageLoaderDelegate>
-(void)wxh5Video_setImageUrl:(NSString*)url;
@end
