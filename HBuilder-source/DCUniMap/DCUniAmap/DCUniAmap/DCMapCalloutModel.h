//
//  DCMapCalloutModel.h
//  AMapImp
//
//  Created by XHY on 2019/4/13.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCMapCalloutModel : NSObject

@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CGFloat padding;
@property (nonatomic, copy) NSString *display;
@property (nonatomic, assign) NSTextAlignment textAlign;



@end

NS_ASSUME_NONNULL_END
