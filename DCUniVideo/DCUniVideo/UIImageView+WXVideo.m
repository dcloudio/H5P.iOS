//
//  UIImageView+Video.m
//  libVideo
//
//  Created by DCloud on 2018/5/29.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "UIImageView+WXVideo.h"
#import "H5CoreImageLoader.h"
#import "PDRCorePrivate.h"

@implementation UIImageView(WXH5Video)

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)imageLoaded:(id)image userInfo:(id)userInfo {
    self.image = image;
}

-(void)h5Video_setImageUrl:(NSString*)url {
//    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:self.setting.poster] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        UIImage *image = [UIImage imageWithData:data];
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            self.thumbImageView.image = image;
//        }];
//    }] resume];
    [[PDRCore Instance].imageLoader loadImage:url withDelegate:self withContext:nil];
}
@end
