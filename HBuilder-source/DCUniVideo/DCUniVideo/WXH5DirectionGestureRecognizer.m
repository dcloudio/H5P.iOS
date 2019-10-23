//
//  H5VideoDirectionGestureRecognizer.m
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/21.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import "WXH5DirectionGestureRecognizer.h"

#define kH5UIDirectionGestureMinTrackDistance 5

@interface WXH5UIDirectionGestureRecognizer()
@property(nonatomic, weak)id<NSObject> directionTarget;
@property(nonatomic, copy)NSString* directionSelectorString;
@property(nonatomic, assign)WXH5UIDirectionGestureRecognizerDirection direction;
@property(nonatomic, assign)CGPoint beginPressPoint;
@property(nonatomic, assign)CGPoint lastMovePoint;
@property(nonatomic, assign)CGPoint delta;
@end

@implementation WXH5UIDirectionGestureRecognizer

- (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action {
    if ( self = [super initWithTarget:self action:@selector(panGesture:)] ) {
        self.directionTarget = target;
        self.directionSelectorString = NSStringFromSelector(action);
    }
    return self;
}

-(void)panGesture:(UIPanGestureRecognizer*)panGesture {
    CGPoint location  = [panGesture locationInView:panGesture.view];
    CGPoint translation = [panGesture translationInView:panGesture.view];
    
    if ( UIGestureRecognizerStateBegan ==  panGesture.state ) {
        self.beginPressPoint = location;
        [self doTargetSelector];
    } else if ( UIGestureRecognizerStateChanged == panGesture.state ) {
        if ( H5UIDirectionGestureRecognizerDirectionUnknown == self.direction ) {
            CGFloat fabsX = fabs(translation.x);
            CGFloat fabsY = fabs(translation.y);
            if ( ( fabsX > kH5UIDirectionGestureMinTrackDistance||
                 fabsY > kH5UIDirectionGestureMinTrackDistance )) {
                if ( fabsX > fabsY ) {
                    if ( translation.x > 0 ) {
                        self.direction = H5UIDirectionGestureRecognizerDirectionRight;
                    } else {
                        self.direction = H5UIDirectionGestureRecognizerDirectionLeft;
                    }
                } else {
                    if ( translation.y > 0 ) {
                        self.direction = H5UIDirectionGestureRecognizerDirectionDown;
                    } else {
                        self.direction = H5UIDirectionGestureRecognizerDirectionUp;
                    }
                }
                self.lastMovePoint = location;
            }
        }
        self.delta = CGPointMake(location.x - self.lastMovePoint.x, location.y - self.lastMovePoint.y);
        self.lastMovePoint = location;
        [self doTargetSelector];
       
    } else {
        self.delta = CGPointMake(location.x - self.lastMovePoint.x, location.y - self.lastMovePoint.y);
        [self doTargetSelector];
        self.direction = H5UIDirectionGestureRecognizerDirectionUnknown;
    }
}

- (void)doTargetSelector {
    SEL selector = NSSelectorFromString(self.directionSelectorString);
    if ( selector && [self.directionTarget respondsToSelector:selector]) {
        [self.directionTarget performSelector:selector withObject:self];
    }
}

-(BOOL)isHorizontal {
    return (H5UIDirectionGestureRecognizerDirectionRight == self.direction
            || H5UIDirectionGestureRecognizerDirectionLeft == self.direction);
}

-(BOOL)isVertical {
    return (H5UIDirectionGestureRecognizerDirectionUp == self.direction
            || H5UIDirectionGestureRecognizerDirectionDown == self.direction);
}

@end
