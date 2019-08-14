//
//  H5VideoPlayOverlayView.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/22.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WXH5VideoPlayOverlayView<NSObject>
-(void)onClickRepeatPlay;
@end

@interface WXH5VideoPlayOverlayView : UIView
@property(nonatomic, weak)id<WXH5VideoPlayOverlayView> delegate;
- (void)initProgressViewWithText:(NSString*)text;
- (void)hideProgressView;
- (void)updateProgress:(NSString*)progress;

- (void)initRepeatViewWithText:(NSString*)text;
- (void)hideRepeatView;
@end

