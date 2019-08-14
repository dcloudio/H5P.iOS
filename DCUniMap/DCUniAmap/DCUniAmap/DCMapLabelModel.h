//
//  DCMapLabel.h
//  DCUniAmap
//
//  Created by XHY on 2019/6/1.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCMapLabelModel : NSObject

@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat anchorX;
@property (nonatomic, assign) CGFloat anchorY;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CGFloat padding;
@property (nonatomic, assign) NSTextAlignment textAlign;

@end

NS_ASSUME_NONNULL_END

