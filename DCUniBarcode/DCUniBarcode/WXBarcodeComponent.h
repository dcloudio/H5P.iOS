//
//  libWXBarcodeComponent.h
//  DCUniBarcode
//
//  Created by 4Ndf on 2019/4/9.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXComponent.h"
#import "WXModuleProtocol.h"
#import "PGWXBarcodeDef.h"
#import "PGWXBarcodeScanView.h"
@interface WXBarcodeComponent : WXComponent<WXModuleProtocol>

@property(nonatomic,retain)PGWXBarcodeScanView * barcodeView;
@property(nonatomic, assign)BOOL decodeImgWToFile;
@property(nonatomic, strong)NSString *decodeImgPath;

@property(nonatomic,copy)NSString * frameColor;
@property(nonatomic,copy)NSString * scanbarColor;
@property(nonatomic,retain)NSArray * filters;
-(PGWXBarcodeScanView*)BarcodeWithPattributes:(NSDictionary*)pattributes;
- (void)close;
- (NSDictionary*)decodeResutWithText:(NSString*)text format:(PGWXBarcodeFormat)barcodeFormat file:(NSString*)filePath;
-(NSDictionary *)errorWithid:(NSNumber*)Errorid errorMes:(NSString*)mes;
@end
