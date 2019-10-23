//
//  H5CoreScreenEdgePan.h
//  libPDRCore
//
//  Created by DCloud on 15/10/27.
//  Copyright © 2015年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class H5CoreScreenEdgePan;
@protocol H5CoreScreenEdgePanDelegate <NSObject>
@required
- (BOOL)screenEdgePan:(H5CoreScreenEdgePan*)edgePan
shouldReceiveGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
                touch:(UITouch *__nullable)touch;
@optional
- (void)screenEdgePan:(H5CoreScreenEdgePan*)edgePan
            getParams:(void (^)(UIView * topView , NSArray * linkageViews, CGFloat duration))param;
- (BOOL)screenEdgePan:(H5CoreScreenEdgePan*)edgePan handleScreenEdgePan:(UIScreenEdgePanGestureRecognizer*)recoginzer;
- (void)screenEdgePan:(H5CoreScreenEdgePan*)edgePan recognizerEnd:(BOOL)cancel;
- (void)screenEdgePan:(H5CoreScreenEdgePan*)edgePan recognizerStart:(CGFloat)progress;
- (void)screenEdgePan:(H5CoreScreenEdgePan*)edgePan recognizerInProgress:(CGFloat)progress;
@end

typedef NS_ENUM(NSInteger, H5CoreScreenEdgePanType) {
    H5CoreScreenEdgePanTypeNo = 0,
    H5CoreScreenEdgePanTypeAppBack = 1,
    H5CoreScreenEdgePanTypeFreameBack,
    H5CoreScreenEdgePanTypeCustom
};

@interface H5CoreScreenEdgePan : NSObject<UIGestureRecognizerDelegate> {
    //UIGestureRecognizer *_gestrueRecongizer;
    UIView *_topView;
    UIImageView *_shadowImageView;
    //边缘滑动
    CGPoint _startTouch;
    CGPoint _lastTouch;
    CGFloat _topleftPosX;
    CGFloat _topViewSrcX;
    CGFloat _duration;
    NSMutableArray *_linkageViews;
    NSMutableDictionary *_presentViewsOriginLeft;
    BOOL _isMoving;
    UIView *_maskView;
    NSMutableDictionary *_userInfo;
}
@property(nonatomic, assign)UIView *gestureRecognizerView;
@property(nonatomic, assign)UIGestureRecognizer *gestrueRecongizer;
@property(nonatomic, assign)BOOL isRuning;
@property(nonatomic, readonly)UIView *topView;
@property(nonatomic, assign)H5CoreScreenEdgePanType panType;
@property(nonatomic, assign, nullable)id<H5CoreScreenEdgePanDelegate> edgeDeleagete;
- (void)setObject:(id)object forKey:(NSString*)aKey;
- (id)objectForKey:(NSString*)aKey;
- (void)removeObjectForKey:(NSString*)aKey;
- (id)initWithGestureRecognizerView:(UIView*)view;
- (void)resetGestureRecognizerView:(UIView*)view;
- (void)removeGestureRecognizer;
- (void)setEnable:(BOOL)enable;
@end
NS_ASSUME_NONNULL_END
