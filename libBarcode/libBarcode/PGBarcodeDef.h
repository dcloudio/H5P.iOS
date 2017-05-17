//
//  PGBarcodeDef.h
//  libBarcode
//
//  Created by DCloud on 15/12/9.
//  Copyright © 2015年 DCloud. All rights reserved.
//

typedef NS_ENUM(NSInteger, PGBarcodeFormat) {
    //二维QR码，1994年由日本Denso-Wave公司发明，
    //QR来自英文Quick Response的缩写，即快速反应的意思，源自发明者希望QR码可让其内容快速被解码
    PGBarcodeFormatQR = 0,
    //EAN码标准版，由国际物品编码协会在全球推广应用的商品条码，是由13位数字组成
    PGBarcodeFormatENA13 = 1,
    //EAN缩短版，由国际物品编码协会在全球推广应用的商品条码，是由8位数字组成
    PGBarcodeFormatENA8 = 2,
    PGBarcodeFormatAZTEC,
    PGBarcodeFormatDATAMATRIX,
    PGBarcodeFormatUPCA,
    PGBarcodeFormatUPCE,
    PGBarcodeFormatCODABAR,
    PGBarcodeFormatCODE39,
    PGBarcodeFormatCODE93,
    PGBarcodeFormatCODE128,
    PGBarcodeFormatITF,
    PGBarcodeFormatMAXICODE,
    PGBarcodeFormatPDF417,
    PGBarcodeFormatRSS14,
    PGBarcodeFormatRSSEXPANDED,
    PGBarcodeFormatOther
};

typedef NS_ENUM(NSInteger, PGBarcodeError) {
    PGBarcodeErrorDecodeError = 3
};

