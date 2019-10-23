//
//  NWindowOptionsParse.h
//  Pandora
//
//  Created by XTY on 12-12-22.
//  Copyright 2012 io.dcloud All rights reserved.
//
#import <Foundation/Foundation.h>

@interface PGNWindowOptionsParse : NSObject

@property(nonatomic, assign)CGRect NWindowRect;
@property(nonatomic, assign)CGRect WebViewRect;
@property(nonatomic, retain)UIColor *backgroundColor;
@property(nonatomic, assign)BOOL isOpaqueUse;
@property(nonatomic, assign)CGFloat opaque;
@property(nonatomic, assign)NSTimeInterval duration;
@property(nonatomic, assign)UIViewAnimationCurve timingFuntion;
//产生变换效果的属性
@property(nonatomic, retain)NSString *property;

+(PGNWindowOptionsParse*)parse:(NSDictionary*)dict;
+(PGNWindowOptionsParse*)parse:(NSDictionary*)dict destLayoutRect:(CGRect)layoutRect;
+(CGRect)parseRect:(NSDictionary*)dict destLayoutRect:(CGRect)layoutRect;

+(int)getNumber:(CGFloat*)aOutMeasureValue formJSObject:(id)aMeasure withStaff:(CGFloat)aStaff;
@end
