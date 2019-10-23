//
//  DCPolyline.h
//  AMapImp
//
//  Created by XHY on 2019/4/22.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCPolyline : MAPolyline

@property (nonatomic, copy) NSString *color;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) BOOL dottedLine;
@property (nonatomic, assign) BOOL arrowLine;
@property (nonatomic, copy) NSString *arrowIconPath;
@property (nonatomic, copy) NSString *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;

@end

NS_ASSUME_NONNULL_END
