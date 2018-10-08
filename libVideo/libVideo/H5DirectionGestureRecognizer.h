//
//  H5VideoDirectionGestureRecognizer.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/21.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, H5UIDirectionGestureRecognizerDirection) {
    H5UIDirectionGestureRecognizerDirectionUnknown,
    H5UIDirectionGestureRecognizerDirectionRight,
    H5UIDirectionGestureRecognizerDirectionLeft,
    H5UIDirectionGestureRecognizerDirectionUp,
    H5UIDirectionGestureRecognizerDirectionDown
};

@interface H5UIDirectionGestureRecognizer : UIPanGestureRecognizer
@property(nonatomic, readonly)H5UIDirectionGestureRecognizerDirection direction;
@property(nonatomic, readonly)CGPoint beginPressPoint;
@property(nonatomic, readonly)CGPoint delta;

-(BOOL)isHorizontal;
-(BOOL)isVertical;
@end
