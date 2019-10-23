/*
 *------------------------------------------------------------------
 *  pandora/tools/PDRToolSystemEx.h.h
 *  Description:
 *      获取设备信息头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-1-10 创建文件
 *------------------------------------------------------------------
 */
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreText/CoreText.h>

#define PT_IsAtLeastiOSVersion(X) ([[[UIDevice currentDevice] systemVersion] compare:X options:NSNumericSearch] != NSOrderedAscending)

#define PT_IsIPad() ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad))

/*
 **@获取系统时间
 */
@interface PTDate : NSObject

+(PTDate*)date;

@property(nonatomic, readonly)NSInteger year;
@property(nonatomic, readonly)SInt8 month;
@property(nonatomic, readonly)SInt8 day;
@property(nonatomic, readonly)SInt8 hour;
@property(nonatomic, readonly)SInt8 minute;
@property(nonatomic, readonly)double sencond;
@property(nonatomic, readonly)double milliseconds;
+(NSDate*)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+(NSDate*)dateWithHour:(NSInteger)hour minute:(NSInteger)minute sencond:(NSInteger)sencond;
@end

/*
 **@采集网络的相关信息，域名为plus.device
 */
typedef NS_ENUM(NSInteger, PTNetType) {
    PTNetTypeUnknow = 0,
    PTNetTypeNone,     // none
    PTNetTypeEthernet, // none
    PTNetTypeWIFI,   // wifi
    PTNetTypeCell2G, // 2G
    PTNetTypeCell3G, // 3G
    PTNetTypeCell4G, // 4G
    PTNetTypeWWAN    // 2g/3g
};

typedef void (^PTNetInfoNetChangeCallback)(PTNetType newNetType, PTNetType oldNetType);

@interface PTNetInfo : NSObject
@property(nonatomic, readonly)PTNetType netType;
+ (instancetype)info;
- (BOOL)startNotifierWithCallback:(SCNetworkReachabilityCallBack)reachabilityCallback;
- (BOOL)startNotifierWithBlock:(PTNetInfoNetChangeCallback)reachabilityCallback;
- (void)stopNotifier;
+ (instancetype)reachabilityForInternetConnection;
@end

/*
 **@采集手机硬件的相关信息，域名为plus.device
 */
@interface PTDeviceInfo : NSObject

//国际移动设备身份码
@property(nonatomic, retain)NSString *IMEI;
//国际移动用户识别码
@property(nonatomic, retain)NSString *IMSI;
//设备型号
@property(nonatomic, retain)NSString *model;
//生产厂商
@property(nonatomic, retain)NSString *vendor;
@property(nonatomic, retain)NSString *UUID;
//移动网络国家类型，Mobile Country Code
@property(nonatomic, retain)NSString *mcc;
//"运营商代号，Mobile Country Code"
@property(nonatomic, retain)NSString *mnc;
@property(nonatomic, retain)NSString *mac;
+(PTDeviceInfo*)deviceInfo;
+ (NSString*)openUUID;
+ (NSString*)uniqueAppInstanceIdentifier;
@end

typedef NS_ENUM(NSInteger, PTSystemVersion) {
    PTSystemVersion5Series = 0,
    PTSystemVersion6Series,
    PTSystemVersion7Series,
    PTSystemVersion8Series,
    PTSystemVersion9Series,
    PTSystemVersion10Series,
    PTSystemVersion11Series,
    PTSystemVersion12Series,
    PTSystemVersion13Series,
    PTSystemVersionUnknown
};

typedef NS_ENUM(NSInteger, PTDeviceType) {
    PTDeviceTypeiPhoneSimulator,
    PTDeviceTypeiPhone3G,
    PTDeviceTypeiPhone3GS,
    PTDeviceTypeiPhone4,
    PTDeviceTypeiPhone4s,
    PTDeviceTypeiPhone5,
    PTDeviceTypeiPhone5c,
    PTDeviceTypeiPhone5s,
    PTDeviceTypeiPhone6,
    PTDeviceTypeiPhone6Plus,
    PTDeviceTypeiPhone6s,
    PTDeviceTypeiPhone6sPlus,
    PTDeviceTypeiPhone7,
    PTDeviceTypeiPhone7Plus,
    PTDeviceTypeiPhone8,
    PTDeviceTypeiPhone8Plus,
    PTDeviceTypeiPhoneX,
    PTDeviceTypeiPhoneXR,
    PTDeviceTypeiPhoneXS,
    PTDeviceTypeiPhoneXSMax,
    PTDeviceTypeiPhone11,
    PTDeviceTypeiPhone11Pro,
    PTDeviceTypeiPhone11ProMax,
    PTDeviceTypeiPhoneSE,
    PTDeviceTypeiPod3G,
    PTDeviceTypeiPod4G,
    PTDeviceTypeiPod5G,
    PTDeviceTypeiPad5,
    PTDeviceTypeiPad6,
    PTDeviceTypeiPadPro,
    PTDeviceTypeiPadAir2,
    PTDeviceTypeiPadAir,
    PTDeviceTypeNewiPad,
    PTDeviceTypeiPad3,
    PTDeviceTypeiPad2,
    PTDeviceTypeiPad1,
    PTDeviceTypeiPadMini4,
    PTDeviceTypeiPadMini3,
    PTDeviceTypeiPadMini2,
    PTDeviceTypeiPadMini1,
    PTDeviceTypeiAppleTV,
    PTDeviceTypeiUnknown
};

/*
 **@采集手机操作系统的相关信息，域名为plus.os
 */
@interface PTDeviceOSInfo : NSObject

//操作系统语言
@property(nonatomic, retain)NSString *language;
//操作系统版本号
@property(nonatomic, retain)NSString *version;
//操作系统名称
@property(nonatomic, retain)NSString *name;
//操作系统提供商
@property(nonatomic, retain)NSString *vendor;

+(NSString*)deviceUtsname;
+ (NSString*)getPreferredLanguage;
+ (PTDeviceOSInfo*)osInfo;
+ (PTSystemVersion)systemVersion;
+ (PTDeviceType)deviceType;
+ (NSString*)deviceTypeInString;
+ (NSString*)cuntryCode;
+ (BOOL)is7Series;
+ (BOOL)is6Series;
+ (BOOL)is5Series;
+ (BOOL)isIpad;
@end

/*
 **@采集手机自身屏幕的相关分辨率等信息，域名为plus.screen
 */
@interface PTDeviceScreenInfo : NSObject

//屏幕高度
@property(nonatomic, assign)CGFloat resolutionHeight;
//屏幕宽度
@property(nonatomic, assign)CGFloat resolutionWidth;
//屏幕物理高度
@property(nonatomic, assign)CGFloat height;
//屏幕物理宽度
@property(nonatomic, assign)CGFloat width;

//X方向上的密度
@property(nonatomic, assign)CGFloat dpiX;
//Y方向上的密度
@property(nonatomic, assign)CGFloat dpiY;
@property(nonatomic, assign)CGFloat scale;
+(PTDeviceScreenInfo*)screenInfo;

@end

/*
 **@采集手机自身屏幕的相关分辨率等信息，域名为plus.screen
 */
@interface PTDeviceDisplayInfo : NSObject

//应用可用区域
@property (nonatomic, assign)CGRect displayRect;
//应用可用高度
@property(nonatomic, assign)CGFloat resolutionHeight;
//应用可用宽度
@property(nonatomic, assign)CGFloat resolutionWidth;

- (CGRect)displayRect;

+(PTDeviceDisplayInfo*)displayInfo;
+(PTDeviceDisplayInfo*)displayInfoWith:(UIInterfaceOrientation)orientation;
@end


@interface PTDevice : NSObject
{
    PTDeviceInfo *_deviceInfo;
    PTDeviceOSInfo *_osInfo;
    PTDeviceScreenInfo *_screenInfo;
    PTDeviceDisplayInfo *_displayInfo;
    PTNetInfo *_netInfo;
}

+(PTDevice*)sharedDevice;
-(void)update;
@property(nonatomic, retain)PTDeviceInfo *deviceInfo;
@property(nonatomic, retain)PTDeviceOSInfo *osInfo;
@property(nonatomic, retain)PTDeviceScreenInfo *screenInfo;
@property(nonatomic, retain)PTDeviceDisplayInfo *displayInfo;
/*@property(nonatomic, retain)PTNetInfo *netInfo;*/
+(long long)getAvailableMemorySize;
+(long long)getUseMemorySize;
+ (void)setDeviceInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

@interface NSString(Measure)
- (BOOL)isAlphaNumeric;
- (int)getMeasure:(CGFloat*)aOutValue withStaff:(CGFloat)aStaff;
@end

@interface UIColor(longColor)
-(NSString*)CSSColor:(BOOL)hasAlpha;
+(UIColor*)colorWithLong:(long)colorValue;
+(UIColor*)colorWithCSS:(NSString*)cssColor;
+(CGFloat)alphWithCSS:(NSString*)cssColor;
@end

@interface CAMediaTimingFunction(Util)
+(CAMediaTimingFunction*)curveEnum2Obj:(UIViewAnimationCurve)curve;
@end

@interface PTGIF :NSObject
@property(nonatomic, retain, readonly)NSArray *frames;
@property(nonatomic, retain, readonly)NSArray *delayTimes;
+ (instancetype)praseGIFData:(NSData *)data;
+ (instancetype)createGifWithFrames:(NSArray *)f withDelayTimes:(NSArray*)delayTimes;
@end

@interface NSDate (DateFormater)
+ (NSDate*)dateFromString:(NSString*)dateStr;
+ (NSString*)stringFrmeDate:(NSDate*)date;
//根据格式把时间转为字符串（默认使用本地所在时区）
- (NSString *)stringWithFormat:(NSString*)fmt;
@end

typedef NS_ENUM(NSInteger, UIImageCheckImageIsPureWhiteOption) {
    UIImageCIWTop22 = 0,//从顶部向下偏移22px横线截屏检测渲染是否完成
    UIImageCIWBottom22 = 1,//-从底部向上偏移25px横线检测渲染是否完成
    UIImageCIWCenter = 2,//-从中间横线检测渲染是否完成
    UIImageCIWAuto = 3,//为全屏检测（左、中、右三条竖线）
    UIImageCIWFull = 4     // 为全屏检测
};

//导航图标旋转接口
@interface UIImage(Util)
+ (UIImage*)createGrayCopy:(UIImage*)source;
- (UIImage *)adjustOrientation;
- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees
                    supportRetina:(BOOL)support
                            scale:(CGFloat)scale;
+ (UIImage*)screenshot:(UIView*)view clipRect:(CGRect)shotRect;
- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size;
+ (BOOL)checkImageIsPureWhite:(UIImage*)image;
+ (NSData*)compressImageData:(NSData*)srcData toMaxSize:(long)maxSize;
+ (UIImage*)dcloud_imageWithContentsOfFile:(NSString *)path;
+ (BOOL)checkImageIsPureWhite:(UIImage*)image option:(UIImageCheckImageIsPureWhiteOption)option;
@end

@interface NSString (WBRequest)
- (NSString*)urlEncode;
- (NSString *)URLDecodeStringEx;
- (NSString *)URLEncodedStringEx;
- (NSString *)URLDecodedStringWithCFStringEncodingEx:(CFStringEncoding)encoding;
- (NSString *)URLEncodedStringWithCFStringEncodingEx:(CFStringEncoding)encoding;
/**
 * 判断字符串中是否有中文，如果有则将中文转码
 */
- (NSString *)URLChineseEncode;
- (NSString *)convertToMD5;
- (BOOL)isWebUrlString;
@end

@interface PTTool : NSObject
+ (BOOL)setSkipBackupAttribute:(BOOL)skip toItemAtURL:(NSURL*)URL;
+ (NSDictionary*)merge:(NSDictionary*)merge to:(NSDictionary*)to;
@end

typedef NS_ENUM(NSInteger, PTImageType) {
    PTImageTypeUnknow = 0,
    PTImageTypeJPEG,
    PTImageTypePNG,
    PTImageTypeGIF,
    PTImageTypeTIFF,
    PTImageTypeWebP,
    PTImageTypeHEIC
};
@interface NSData (DCExtend)
- (NSData *)AESEncryptWithKey:(NSString *)key;
- (NSData *)AESEncryptWithKey128:(NSString *)key;
- (NSData *)AESDecryptWithKey:(NSString *)key;
- (NSData *)AESDecryptWithKey128:(NSString *)key;
+ (NSData *)compressData:(NSData*)uncompressedData;
- (NSData *)compressData:(NSData*)uncompressedData;
+ (NSString*)dc_imageFormatStr:(PTImageType)type;
- (PTImageType)dc_imageFormat;
@end

typedef NS_ENUM(NSInteger, H5CoreToolDirection) {
    H5CoreToolDirectionDown,
    H5CoreToolDirectionUp,
    H5CoreToolDirectionLeft,
    H5CoreToolDirectionRight,
    H5CoreToolDirectionUnknown
};

extern NSString *kDCCoreToolFontMetaKeyName;
extern NSString *kDCCoreToolFontMetaKeyTraits;
@interface H5CoreTool : NSObject
+ (NSString*)dynamicLoadFont:(NSString*)fontFilePath;
+ (NSString*)dynamicLoadFontUseCache:(NSString*)newPath;
+ (NSDictionary*)dynamicLoadFontMeta:(NSString*)fontFilePath;
+ (NSDictionary*)dynamicLoadFontMetaUseCache:(NSString*)newPath;
+ (H5CoreToolDirection)determineDirection:(CGPoint)translation;
+ (void)getLocationTestAuthentication:(BOOL)testAuthentication withReslutBlock:(void(^)(NSDictionary*, NSError*))block;
@end

@interface H5TextCheck :NSObject
+ (BOOL)isTelephone:(NSString*)value;
+ (BOOL)isEmail:(NSString*)value;
@end

@interface UIFont(H5Tool)
+(CGFloat)piexl2Size:(CGFloat)piexl;
@end

@interface NSArray(DCAdd)
-(BOOL)dc_containsStringCaseInsensitive:(NSString*)testString;
@end


typedef NS_ENUM(NSInteger, PDRCoreAppSSLActive) {
    PDRCoreAppSSLActiveAllow = 0,
    PDRCoreAppSSLActiveWarning,
    PDRCoreAppSSLActiveRefuse
};

@interface NSObject(DCFlgs)
- (void)dc_destoryFlgs;
- (void)dc_mask_set:(int)flg;
- (BOOL)dc_mask_test:(int)flg;
- (void)dc_mask_clear:(int)flg;
- (void)dc_mask2_set:(int)flg;
- (BOOL)dc_mask2_test:(int)flg;
- (void)dc_mask2_clear:(int)flg;

+ (void)dc_mask:(NSUInteger)store clear:(int)flg;
+ (BOOL)dc_mask:(NSUInteger)store test:(int)flg;
+ (void)dc_mask:(NSUInteger)store set:(int)flg;
@end

@interface NSDictionary(DCExtend)
- (BOOL)boolValueForKey:(id)key;
- (int)intValueForKey:(id)key;
@end

#ifdef __cplusplus
extern "C" {
#endif
int PT_Parse_GetMeasurement( NSObject* aMeasure, CGFloat aStaff, CGFloat * aOutMeasureValue );
    CGSize DCT_CGSizeSwap(CGSize);
    CGRect DCT_CGRectEdgeInsets(CGRect, UIEdgeInsets);
    CGRect tDCT_CGRectEdgeInsets(CGRect, UIEdgeInsets,CGFloat);
    CGRect jDCT_CGRectEdgeInsets(CGRect, CGFloat,CGFloat);
#ifdef __cplusplus
}
#endif
