//
//  PGBarcode.h
//  libBarcode
//
//  Created by DCloud on 15/12/9.
//  Copyright © 2015年 DCloud. All rights reserved.
//
#import "PGPlugin.h"
#import "PGMethod.h"
#import "PGBarcodeDef.h"
#import "PGBarcodeScanView.h"

@interface  PGBarcode : PGPlugin{
    PGBarcodeScanView *_widget;
}

@property(nonatomic, strong)NSString *callBackID;
@property(nonatomic, assign)BOOL scaning;
@property(nonatomic, assign)BOOL decodeImgWToFile;
@property(nonatomic, strong)NSString *decodeImgPath;
- (void)Barcode:(PGMethod*)command;
- (void)start:(PGMethod*)command;
- (void)cancel:(PGMethod*)command;
- (void)setFlash:(PGMethod*)command;
- (void)scan:(PGMethod*)command;
@end