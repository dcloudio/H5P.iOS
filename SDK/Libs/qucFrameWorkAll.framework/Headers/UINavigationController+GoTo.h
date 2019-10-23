//
//  UINavigationController+GoTo.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-11.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (GOTO)

-(void)goToViewController:(UIViewController *)viewController animated:(BOOL)animated Dict:(NSDictionary *)dict;

-(void)setNavTitle:(NSString *)title;
@end