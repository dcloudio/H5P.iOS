
#include <objc/message.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PGNativeUI.h"
#import "PDRCore.h"
#import "PTPathUtil.h"
#import "PDRCoreAppPrivate.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppFrame.h"
#import "PDRCoreAppFramePrivate.h"
#import "PDRCoreAppWindow.h"
#import "PDRCoreAppWindowPrivate.h"
#import "PDRCoreWindowManager.h"
#import "PDRCoreFeature.h"
#import "PGMethod.h"
#import "PDRCoreAppWindow.h"
#import "PDRToolSystem.h"
#import "PDRToolSystemEx.h"
#import "PDRUIDateTimePickerController.h"
#import "DC_JSON.h"
#import "PDRNView.h"
#import "PTLog.h"
#import "PDRCommonString.h"
#import "PTUserAgentUtil.h"
#import "H5PUIToast.h"


NSString *const PGUICloseWaitingNotificationKey = @"PGUICloseWaitingNotificationKey";

//static int Parse_GetMeasurement( NSString* aMeasure,
//                                CGFloat aStaff,
//                                CGFloat * aOutMeasureValue ) {
//    NSString *trueMeasure = aMeasure;
//    if ( [aMeasure isKindOfClass:[NSNumber class]] ) {
//        trueMeasure = [(NSNumber*) aMeasure stringValue];
//    }
//    if ( [trueMeasure isKindOfClass:[NSString class]] ) {
//        return [trueMeasure getMeasure:aOutMeasureValue withStaff:aStaff];
//    }
//    return -1;
//}

NSString* g_PDR_Localization_Sure   = @"确定";
NSString* g_PDR_Localization_Cancel = @"取消";

@implementation PGPopTraceInfo

@synthesize type;
@synthesize JSCbID;
@synthesize alertView;
@synthesize actionSheet;
@synthesize buttonIndexs;

+ (PGPopTraceInfo*)infoWithType:(PGPopTraceType)aType
                             cb:(NSString*)aCB {
    PGPopTraceInfo *info = [[[PGPopTraceInfo alloc] init] autorelease];
    info.type = aType;
    info.JSCbID = aCB;
    return info;
}

+ (id)getObjectKey:(id)alertView {
    return [NSString stringWithFormat:@"%p", (void*)alertView];
}

- (void)dealloc {
    self.buttonIndexs = nil;
    self.JSCbID = nil;
    [super dealloc];
}

@end

@implementation PGNativeUI

- (PGPlugin*) initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp*)app {
    self = [super initWithWebView:theWebView withAppContxt:app];
    if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlCloseWaiting:) name:PGUICloseWaitingNotificationKey object:nil];
	}
    return self;
}
/*
 ========================================================================
 * @Summary:
 * @Parameters:
 *  [htmlid, [callbackid, title, ishours]]
 * @Returns:
 * @Remark:
 * @Changelog:
 ========================================================================
 */
- (void)pickDate:(PGMethod*)args;
{
    NSString *htmlID = nil;
    NSString *callBackId = nil;
    NSString *title = nil;
    
    NSInteger startYear = 1900, startMonth = 1, startDay= 1;
    NSInteger endYear = 9999, endMonth = 12, endDay= 31;
    NSInteger setYear = 0, setMonth = 0, setDay = 0;
    CGRect rect = CGRectMake(0, 0, 1, 1);
    rect.origin = self.JSFrameContext.center;
    
    NSString *htmlIDValue = [args.arguments objectAtIndex:0];
    if ( [htmlIDValue isKindOfClass:[NSString class]] ) {
        htmlID = htmlIDValue;
    }
    NSArray *subArgs = [args.arguments objectAtIndex:1];
    callBackId = [subArgs objectAtIndex:0];
    NSDictionary *options = [subArgs objectAtIndex:1];
    if ( [options isKindOfClass:[NSDictionary class]] ) {
        NSString *titleValue = [options objectForKey:@"title"];
        if ( [titleValue isKindOfClass:[NSString class]] ) {
            title = titleValue;
        }
        
        NSNumber *value = [options objectForKey:@"startYear"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            startYear = [value integerValue];
        }
        value = [options objectForKey:@"startMonth"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            startMonth = [value integerValue]+1;
        }
        value = [options objectForKey:@"startDay"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            startDay = [value integerValue];
        }
        value = [options objectForKey:@"endYear"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            endYear = [value integerValue];
        }
        value = [options objectForKey:@"endMonth"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            endMonth = [value integerValue]+1;
        }
        value = [options objectForKey:@"endDay"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            endDay = [value integerValue];
        }
        value = [options objectForKey:@"setYear"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            setYear = [value integerValue];
        }
        value = [options objectForKey:@"setMonth"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            setMonth = [value integerValue]+1;
        }
        value = [options objectForKey:@"setDay"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            setDay = [value integerValue];
        }
        
        //获取弹出位置
        
        NSDictionary *popover = [options objectForKey:g_pdr_string_popover];
        if ( [popover isKindOfClass:[NSDictionary class]] ) {
            NSNumber *topArgs = [popover objectForKey:g_pdr_string_top];
            if ( [topArgs isKindOfClass:[NSNumber class]] ) {
                rect.origin.x = [topArgs intValue];
            }
            NSNumber *leftArgs = [popover objectForKey:g_pdr_string_top];
            if ( [leftArgs isKindOfClass:[NSNumber class]] ) {
                rect.origin.y = [leftArgs intValue];
            }
            NSNumber *widthArgs = [popover objectForKey:g_pdr_string_top];
            if ( [widthArgs isKindOfClass:[NSNumber class]] ) {
                rect.size.width = [widthArgs intValue];
            }
            NSNumber *heigthArgs = [popover objectForKey:g_pdr_string_height];
            if ( [heigthArgs isKindOfClass:[NSNumber class]] ) {
                rect.size.height = [heigthArgs intValue];
            }
        }
        
    }
    
    NSDate *startDate = [PTDate dateWithYear:startYear month:startMonth day:startDay];
    NSDate *endDate = [PTDate dateWithYear:endYear month:endMonth day:endDay];
    NSDate *setDate = [PTDate dateWithYear:setYear month:setMonth day:setDay];

    if (m_pDatePickDic == nil) {
        m_pDatePickDic = [[NSMutableDictionary alloc] init];
    }
    
    [m_pDatePickDic setObject:callBackId forKey:htmlID];
    
    PDRUIDateTimePickerViewController *viewController = [[[PDRUIDateTimePickerViewController alloc] init] autorelease];
    viewController.pickDelegate = self;
    viewController.title = title;
    viewController.minimumDate = startDate;
    viewController.maximumDate = endDate;
    if ( 0 == setYear && 0 == setMonth && 0 == setDay ) {
        viewController.date = [NSDate date];
    } else {
        viewController.date = setDate;
    }
    viewController.datePickerMode = UIDatePickerModeDate;
    [viewController showFormRect:rect inView:self.JSFrameContext ];
    return;
}

/*
 ========================================================================
 * @Summary:
 * @Parameters:
 *  [htmlid, [callbackid, title, ishours]]
 * @Returns:
 * @Remark:
 * @Changelog:
 ========================================================================
 */
- (void)pickTime:(PGMethod*)args;
{
    NSString *htmlID = nil;
    NSString *callBackId = nil;
    NSString *title = nil;
    BOOL is24Hour = TRUE;
    CGRect rect = CGRectMake(0, 0, 1, 1);
    rect.origin = self.JSFrameContext.center;
    NSDate *setDate = nil;
    NSInteger hours = 0;
    NSInteger minutes = 0;
    
    NSString *htmlIDValue = [args getArgumentAtIndex:0];
    if ( [htmlIDValue isKindOfClass:[NSString class]] ) {
        htmlID = htmlIDValue;
    }
    NSArray *subArgs = [args getArgumentAtIndex:1];
    callBackId = [subArgs objectAtIndex:0];
    
    NSDictionary *options = [subArgs objectAtIndex:1];
    if ( [options isKindOfClass:[NSDictionary class]] ) {
        NSString *titleValue = [options objectForKey:@"title"];
        if ( [titleValue isKindOfClass:[NSString class]] ) {
            title = titleValue;
        }
        
        NSNumber *value = [options objectForKey:@"is24Hour"];
        if ( [value isKindOfClass:[NSNumber class]] ) {
            is24Hour = [value boolValue];
        }
        NSNumber *hoursV = [options objectForKey:@"__hours"];
        NSNumber *minutesV = [options objectForKey:@"__minutes"];
        if ( [hoursV isKindOfClass:[NSNumber class]]
            && [minutesV isKindOfClass:[NSNumber class]]) {
            hours = [hoursV intValue];
            minutes = [minutesV intValue];
            setDate = [PTDate dateWithHour:hours minute:minutes sencond:0];
        }
        
        //获取弹出位置
        NSDictionary *popover = [options objectForKey:g_pdr_string_popover];
        if ( [popover isKindOfClass:[NSDictionary class]] ) {
            NSNumber *topArgs = [popover objectForKey:g_pdr_string_top];
            if ( [topArgs isKindOfClass:[NSNumber class]] ) {
                rect.origin.x = [topArgs intValue];
            }
            NSNumber *leftArgs = [popover objectForKey:g_pdr_string_top];
            if ( [leftArgs isKindOfClass:[NSNumber class]] ) {
                rect.origin.y = [leftArgs intValue];
            }
            NSNumber *widthArgs = [popover objectForKey:g_pdr_string_top];
            if ( [widthArgs isKindOfClass:[NSNumber class]] ) {
                rect.size.width = [widthArgs intValue];
            }
            NSNumber *heigthArgs = [popover objectForKey:g_pdr_string_height];
            if ( [heigthArgs isKindOfClass:[NSNumber class]] ) {
                rect.size.height = [heigthArgs intValue];
            }
        }
    }
    
    if (m_pDatePickDic == nil) {
        m_pDatePickDic = [[NSMutableDictionary alloc] init];
    }
    
    [m_pDatePickDic setObject:callBackId forKey:htmlID];
    
    PDRUIDateTimePickerViewController *viewController = [[[PDRUIDateTimePickerViewController alloc] init] autorelease];
    viewController.pickDelegate = self;
    viewController.title = title;
    if ( is24Hour ) {
        viewController.datePickerMode = UIDatePickerModeCountDownTimer;
        if ( setDate ) {
            viewController.countDownDuration = hours*3600 + minutes*60;
        }
    } else {
        viewController.datePickerMode = UIDatePickerModeTime;
    }
    if ( setDate) {
        viewController.date = setDate;
    }
    
    [viewController showFormRect:rect inView:self.JSFrameContext ];
    return;
}

- (void)didCancleSelect {
    NSArray *keys = [m_pDatePickDic allKeys];
    NSString *htmlID = [keys objectAtIndex:0];
    NSString *callBackID = [m_pDatePickDic objectForKey:htmlID];
    [self toErrorCallback:callBackID withCode:PGPluginErrorUserCancel];
    [m_pDatePickDic removeAllObjects];
}

- (void)didSelectDate:(NSDate*)date {
    NSArray *keys = [m_pDatePickDic allKeys];
    NSString *htmlID = [keys objectAtIndex:0];
    NSString *callBackID = [m_pDatePickDic objectForKey:htmlID];
    
    // 直接返回时间戳在 iOS 的浏览器中时区会有问题，返回 yyyy/MM/dd HH:mm:ss 时间格式可以兼容
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *time = [formatter stringFromDate:date];
    [formatter release];
    
    PDRPluginResult *reuslt = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:time];
    [self toCallback:callBackID withReslut:[reuslt toJSONString]];
    [m_pDatePickDic removeAllObjects];
}
#pragma mark - 图片预览

- (void)previewImage:(PGMethod*)pMethod
{
    NSArray* pTmpImages = nil;
    NSDictionary* pOptions = nil;
    NSString *callBackId = nil;
    NSString *htmlID = nil;
    NSArray* pArgus = [pMethod getArgumentAtIndex:1];
    if(pArgus && [pArgus isKindOfClass:[NSArray class]]){
        pTmpImages = [pArgus firstObject];
        if(pArgus.count > 1){
            pOptions = [pArgus objectAtIndex:1];
        }
        callBackId = [pArgus objectAtIndex:2];
    }
    
    NSString *htmlIDValue = pMethod.htmlID;
    if ( [htmlIDValue isKindOfClass:[NSString class]] ) {
        htmlID = htmlIDValue;
    }
    if (m_previewImgDic == nil) {
        m_previewImgDic = [[NSMutableDictionary alloc] init];
    }
    [m_previewImgDic setObject:callBackId forKey:htmlID];
    
    NSMutableArray* pImages = [NSMutableArray arrayWithCapacity:0];
    int current = 0;
    EImageSliderIndicator indType = EImageSliderIndicator_default;
    NSString* pBgColor = @"#000000";
    BOOL bLoop = false;
    
    if(pTmpImages && [pTmpImages isKindOfClass:[NSString class]]){
        [pImages addObject:@{@"src":pTmpImages}];
    }
    else if(pTmpImages && [pTmpImages isKindOfClass:[NSArray class]] && [pTmpImages count]){
        for (NSString* pImgPath in pTmpImages) {
            [pImages addObject:@{@"src":pImgPath}];
        }
    }
    
    if(pOptions && [pOptions isKindOfClass:[NSDictionary class]]){
        current = [[pOptions objectForKey:@"current"] intValue];
        pBgColor = [pOptions objectForKey:@"background"];
        bLoop = [[pOptions objectForKey:@"loop"] boolValue];
        NSString* pindTypeStr = [pOptions objectForKey:@"indicator"];
        if(pindTypeStr && [pindTypeStr isKindOfClass:[NSString class]]){
            if([pindTypeStr isEqualToString:@"number"]){
                indType = EImageSliderIndicator_number;
            }else if([pindTypeStr isEqualToString:@"none"]){
                indType = EImageSliderIndicator_none;
            }
        }
    }
    
    PGNativeImageSliderView* pImageSlider = [[PGNativeImageSliderView alloc] initWithOptions:@{@"loop":@(bLoop),
                                                                                               @"fullscreen":@(true),
                                                                                               g_pdr_string_baseURL:self.JSFrameContext.baseURL?self.JSFrameContext.baseURL:@"",
                                                                                               @"images":pImages,
                                                                                               @"current":@(current),
                                                                                               @"indicator":@(indType)
                                                                                               }];
    pImageSlider.delegate = self;
    pImageSlider.context = self;
    if(pImageSlider){
        pImageSlider.belongTo = PDRNViewInWindow;
        if(pBgColor && [pBgColor isKindOfClass:[NSString class]]){
            [pImageSlider setSliderBgColor:[UIColor colorWithCSS:pBgColor]];
        }
        else{
            [pImageSlider setSliderBgColor:[UIColor blackColor]];
        }
        
        pImageSlider.isPreviewImage = YES;
        [pImageSlider setItemsCanZooming:YES];
        pImageSlider.frame = self.appContext.appWindow.bounds;
        [self.appContext.appWindow  addSubview:pImageSlider];
        [pImageSlider release];
    }
    
    if (m_pDatePickDic == nil) {
        m_pDatePickDic = [[NSMutableDictionary alloc] init];
    }
    
}
-(void)longPressForIndex:(NSNumber *)index url:(NSString *)url path:(NSString *)path{
    NSArray *keys = [m_previewImgDic allKeys];
    NSString *htmlID = [keys objectAtIndex:0];
    NSString *callBackID = [m_previewImgDic objectForKey:htmlID];
    NSMutableDictionary * dic = [NSMutableDictionary new];
    [dic setObject:index forKey:@"index"];
    [dic setObject:url forKey:@"url"];
    [dic setObject:path forKey:@"path"];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dic];
    [result setKeepCallback:YES];
    [self toCallback:callBackID withReslut:[result toJSONString]];
}
#pragma mark --
#pragma mark 系统提示框
- (void)toast:(PGMethod*)pMethod {
    NSString *tips = nil;
    NSDictionary *options = nil;

    NSArray *args = [pMethod getArgumentAtIndex:1];
    
    NSString *arg0 = [args objectAtIndex:0];
    if ( [arg0 isKindOfClass:[NSString class]] ) {
        tips = arg0;
    }
    NSDictionary *arg1 = [args objectAtIndex:1];
    if ( [arg1 isKindOfClass:[NSDictionary class]] ) {
        options = arg1;
    }
    
    H5PUIToastType toastType = H5PUIToastTypeText;
    NSString *jsToastType = [PGPluginParamHelper getStringValue:[options objectForKey:g_pdr_string_type]];
    if ( jsToastType && NSOrderedSame == [@"richtext" caseInsensitiveCompare:jsToastType] ) {
        toastType = H5PUIToastTypeRichText;
    }
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    H5PUIToast *toast = nil;
    UIView *superView = keyWindow? keyWindow: self.appContext.appWindow;
    if ( NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_8_0 ) {
        superView = self.appContext.appWindow;
        toast = [[H5PUIToastWindow alloc] initWithSuperView:superView withType:toastType];
    } else {
        toast = [[H5PUIToast alloc] initWithSuperView:superView withType:toastType];
    }

    [toast setBaseURL:self.JSFrameContext.baseURL];
    if ( H5PUIToastTypeRichText == toastType ) {
        NSDictionary *styleV = [PGPluginParamHelper getJSONValueInDict:options forKey:@"richTextStyle"];
        toast.richTextStyle = styleV;
    }
    
    toast.jsContextWebviewId = pMethod.htmlID;
    toast.labelText = tips;
    
    CGFloat iconWidth = .0f;
    CGFloat iconHeight = .0f;
    PT_Parse_GetMeasurement([options objectForKey:@"iconWidth"], 0, &iconWidth );
    PT_Parse_GetMeasurement([options objectForKey:@"iconHeight"], 0, &iconHeight );
    toast.imageSize = CGSizeMake(iconWidth, iconHeight);
    
    NSString *iconPath = [options objectForKey:g_pdr_string_icon];
    if ( [iconPath isKindOfClass:NSString.class] ) {
       // iconPath = [PTPathUtil absolutePath:iconPath];
        iconPath = [PTPathUtil h5Path2SysPath:iconPath basePath:self.JSFrameContext.baseURL context:self.appContext];
        toast.iconImage = [UIImage imageWithContentsOfFile:iconPath];
    }
    
    NSString *iconStyle = [PGPluginParamHelper getStringValue:[options objectForKey:g_pdr_string_style] defalut:@"block"];// [options objectForKey:g_pdr_string_icon];
    if ( NSOrderedSame == [@"inline" caseInsensitiveCompare:iconStyle] ) {
        toast.layoutMode = H5PUIToastLayoutModeInline;
    }

    NSString *duration = [options objectForKey:g_pdr_string_duration];
    if ( [duration isKindOfClass:NSString.class]
        && NSOrderedSame == [g_pdr_string_long caseInsensitiveCompare:duration]) {
        toast.autoHideTime = 3.5f;
    }
    
    NSString *align = [options objectForKey:g_pdr_string_align];
    if ( [align isKindOfClass:NSString.class] ) {
        if ( NSOrderedSame == [g_pdr_string_left caseInsensitiveCompare:align] ) {
            toast.alignment = H5PUIToastPopStyleLeft;
        } else if (NSOrderedSame == [g_pdr_string_right caseInsensitiveCompare:align]){
            toast.alignment = H5PUIToastPopStyleRight;
        }
    }
    
    NSString *verticalAlign = [options objectForKey:@"verticalAlign"];
    if ( [verticalAlign isKindOfClass:NSString.class] ) {
        if ( NSOrderedSame == [g_pdr_string_top caseInsensitiveCompare:verticalAlign] ) {
            toast.verticalAlignment = H5PUIToastPopStyleTop;
        } else if (NSOrderedSame == [g_pdr_string_center caseInsensitiveCompare:verticalAlign]){
            toast.verticalAlignment = H5PUIToastPopStyleCenter;
        }
    }
    NSString *bkColor = [PGPluginParamHelper getStringValueInDict:options forKey:g_pdr_string_background defalut:nil];
    if ( bkColor ) {
        toast.color = [UIColor colorWithCSS:bkColor];
    }
    
    if ( NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0 ) {
        [superView addSubview:toast];
    }
    [toast show:TRUE];
    [toast autorelease];
}

#pragma mark --
#pragma mark 系统弹出框
- (void)showMenu:(PGMethod*)pMethod {
    NSArray *args = [pMethod getArgumentAtIndex:1];
    NSDictionary *menuStyles = [args objectAtIndex:0];
    NSArray *menuItemStyles = [args objectAtIndex:1];
    NSString *callbackId = [args objectAtIndex:2];
    NSString* onClickcbid = [PGPluginParamHelper getStringValueInDict:menuStyles forKey:@"__plus__onclickCallbackId" defalut:@""];

    __block typeof(self) weakself = self;
    [self.appContext.appWindow showMenu:[self menuStoreWithStyle:menuStyles withMenuItemStyles:menuItemStyles]
                           clickBlock:^()
     {
         [weakself toSucessCallback:onClickcbid withJSON:@{} keepCallback:YES];
     }
                              doneBlock:^(NSInteger selectedIndex) {
                                  [weakself toSucessCallback:callbackId
                                                withJSON:@{g_pdr_string_index:@(selectedIndex)} keepCallback:YES];
                              }
                           dismissBlock:^{
                               
                           }];
}

- (DCSANavMenuStore*)menuStoreWithStyle:(NSDictionary*)menuStyles
                     withMenuItemStyles:(NSArray*)menuItemStyles {
    DCSANavMenuStore *store = [[[DCSANavMenuStore alloc] init] autorelease];
    
    store.title = [PGPluginParamHelper getStringValueInDict:menuStyles forKey:g_pdr_string_title defalut:@""];
    store.badge = [PGPluginParamHelper getBoolValueInDict:menuStyles forKey:@"badge" defalut:false];
    
    
    NSMutableArray *menuItems = [NSMutableArray array];
    for ( NSDictionary *Query in menuItemStyles ) {
        DCSANavMenuItem *menuItem = [[[DCSANavMenuItem alloc] init] autorelease];
        menuItem.title = [PGPluginParamHelper getStringValueInDict:Query forKey:g_pdr_string_title defalut:@""];
        menuItem.iconPath = [PGPluginParamHelper getStringValueInDict:Query forKey:g_pdr_string_icon defalut:@""];
        menuItem.iconPath = [PTPathUtil h5Path2SysPath:menuItem.iconPath basePath:self.JSFrameContext.baseURL context:self.appContext];
        menuItem.iconPath = menuItem.iconPath ?menuItem.iconPath:@"";
        menuItem.checked = [PGPluginParamHelper getBoolValueInDict:Query forKey:@"checked" defalut:false];
        if ( menuItem.checked && [menuItem.iconPath length] == 0 ) {
            menuItem.iconPath = @"PandoraApi.bundle/selected_barbutton";
        }
        [menuItems addObject:menuItem];
    }
    store.menuItemArray = menuItems;
    return store;
}

- (void)hideMenu:(PGMethod*)pMethod {
    [self.appContext.appWindow dismissMenu];
    self.appContext.appWindow.showMenuStore = nil;
}

- (NSData*)isTitlebarVisible:(PGMethod*)pMethod {
    BOOL hidden = [self.appContext.appWindow isBarHidden];
    return [self resultWithBool:!hidden];
}

- (void)setTitlebarVisible:(PGMethod*)pMethod {
    NSArray *arg1 = [pMethod getArgumentAtIndex:1];
    BOOL show = [PGPluginParamHelper getBoolValue:[arg1 objectAtIndex:0] defalut:YES];
    
    [self.appContext.appWindow setBarVisble:show];
}

- (NSData*)getTitlebarHeight:(PGMethod*)pMethod {
    return [self resultWithInt:[self.appContext.appWindow getBarRect].size.height];
}

#pragma mark --
#pragma mark 系统弹出框

- (void)_NativeObj_close:(PGMethod*)pMethod
{
    NSString* pUUID = [pMethod.arguments firstObject];
    if(pUUID && m_NativeObjArray)
    {
        NSDictionary* NativDic = [m_NativeObjArray objectForKey:pUUID];
        if(NativDic && [NativDic isKindOfClass:[NSDictionary class]])
        {
            id obje = [NativDic objectForKey:@"natObj"];
            NSString* cbid = [NativDic objectForKey:@"cbid"];
            NSString* pType = [NativDic objectForKey:@"type"];

            if(obje)
            {
                if([obje isKindOfClass:[UIActionSheet class]])
                {
                    UIActionSheet* actSheet = (UIActionSheet*)obje;
                    [actSheet dismissWithClickedButtonIndex:-1 animated:YES];
                }
                else if([obje isKindOfClass:[UIAlertController class]])
                {
                    UIAlertController* alertCon = (UIAlertController*)obje;
                    [alertCon dismissModalViewControllerAnimated:YES];
                }

                if(pType && [pType isEqualToString:@"actionsheet"])
                {
                    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:(int)-1];
                    [self toCallback:cbid withReslut:[result toJSONString]];
                }

                [m_NativeObjArray removeObjectForKey:pUUID];
            }
            
        }
        
        if([m_NativeObjArray count] == 0)
        {
            [m_NativeObjArray release];
            m_NativeObjArray = nil;
        }
    }
}


- (void)addNativeObject:(id)Obj  UUID:(NSString*)pUUID
             callBackid:(NSString*)callbackid
                   type:(NSString*)type
{
    if(pUUID)
    {
        if(m_NativeObjArray == nil)
            m_NativeObjArray = [[NSMutableDictionary alloc] init];
        
        if(m_NativeObjArray)
            [m_NativeObjArray setObject:@{@"natObj":Obj, @"cbid":callbackid, @"type":type} forKey:pUUID];
    }
}



- (void)actionSheet:(PGMethod*)pMethod {
    NSString *title = nil;
    NSString *cancel = nil;
    NSString *callbackId = nil;
    NSString *destructiveButtonTitle = nil;
    NSMutableArray *buttons = nil;
    NSMutableArray *buttonIndexs = nil;
    
    NSArray *args = [pMethod getArgumentAtIndex:1];
    NSDictionary *styleArgs = [args objectAtIndex:0];
    NSString *tmpCallbackId = [args objectAtIndex:1];
    NSString* Objuuid = nil;
    if([args count] > 2)
        Objuuid = [args objectAtIndex:2];
    
    if ( [styleArgs isKindOfClass:[NSDictionary class]] ) {
        NSString *tmpTitle = [styleArgs objectForKey:g_pdr_string_title];
        if ( [tmpTitle isKindOfClass:[NSString class]] ) {
            title = tmpTitle;
        }
        NSString *tmpCancel = [styleArgs objectForKey:g_pdr_string_cancel];
        if ( [tmpCancel isKindOfClass:[NSString class]] ) {
            cancel = tmpCancel;
        }
        NSArray *tmpButtons = [styleArgs objectForKey:@"buttons"];
        if ( [tmpButtons isKindOfClass:[NSArray class]] ) {
            for ( NSDictionary *items in tmpButtons ) {
                if ( [items isKindOfClass:[NSDictionary class]] ) {
                    NSString *styleV = [items objectForKey:g_pdr_string_style];
                    NSString *titleV = [items objectForKey:g_pdr_string_title];
                    if ( [titleV isKindOfClass:[NSString class]] ) {
                        if ( nil == buttonIndexs ) {
                            buttonIndexs = [NSMutableArray array];
                        }
                        if ( nil == buttons ) {
                            buttons = [NSMutableArray array];
                        }
                        if ( [styleV isKindOfClass:[NSString class]]
                            && NSOrderedSame == [@"destructive" caseInsensitiveCompare:styleV] ) {
                            if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series ) {
                                [buttons addObject:titleV];
                                [buttonIndexs addObject:[NSNumber numberWithInt:PGActionSheetButtonTypeDestructive]];
                            } else {
                                if ( nil == destructiveButtonTitle ) {
                                    destructiveButtonTitle = titleV;
                                    [buttonIndexs addObject:[NSNumber numberWithInt:PGActionSheetButtonTypeDestructive]];
                                } else {
                                    [buttons addObject:titleV];
                                    [buttonIndexs addObject:[NSNumber numberWithInt:PGActionSheetButtonTypeDefault]];
                                }
                            }
                        } else {
                            [buttons addObject:titleV];
                            [buttonIndexs addObject:[NSNumber numberWithInt:PGActionSheetButtonTypeDefault]];
                        }
                    }
                }
            }
        }
    }
    
    if ( [tmpCallbackId isKindOfClass:[NSString class]] ) {
        callbackId = tmpCallbackId;
    }

    if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series ) {
        NSUInteger buttonCount = [buttons count];
        if ( (buttonCount == 0 && nil == cancel && nil == title) ) {
            return;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        if ( cancel ) {
            [alertController addAction:[UIAlertAction actionWithTitle:cancel
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction *action) {
                                                                  PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:(int)0];
                                                                  [self toCallback:callbackId withReslut:[result toJSONString]];
                                                              }]];
        }
        for ( NSUInteger index = 0; index < buttonCount; index++ )
        {
            NSString *buttonTitle = [buttons objectAtIndex:index];
            NSNumber *buttonType = [buttonIndexs objectAtIndex:index];
            [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                                style:PGActionSheetButtonTypeDestructive == [buttonType intValue]?UIAlertActionStyleDestructive:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:(int)index+1];
                                                                  [self toCallback:callbackId withReslut:[result toJSONString]];
                                                              }]];
        }
        UIPopoverPresentationController *popover = alertController.popoverPresentationController;
        if ( popover ) {
            popover.sourceView = self.JSFrameContext;
            popover.sourceRect = CGRectMake(self.JSFrameContext.bounds.size.width/2, self.JSFrameContext.bounds.size.height, 1, 1);
            popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        }
        [self presentViewController:alertController animated:YES completion:nil];
        
        [self addNativeObject:alertController UUID:Objuuid callBackid:callbackId type:@"actionsheet"];
        return;
    }
    UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:destructiveButtonTitle
                                                    otherButtonTitles:nil, nil] autorelease];
    actionSheet.delegate = self;
    
    for ( NSString *buttonTitle in buttons) {
        [actionSheet addButtonWithTitle:buttonTitle];
    }
    if ( cancel ) {
        [actionSheet addButtonWithTitle:cancel];
        actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;
    }
    
    [actionSheet showInView:self.JSFrameContext];
    {
        PGPopTraceInfo *traceInfo = [PGPopTraceInfo infoWithType:PGPopTraceTypeActionSheet cb:callbackId];
        if ( !m_pPopTrace ) {
            m_pPopTrace = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
        traceInfo.actionSheet = actionSheet;
        traceInfo.buttonIndexs = buttonIndexs;
        [m_pPopTrace setObject:traceInfo forKey:[PGPopTraceInfo getObjectKey:actionSheet]];
    }
    
    [self addNativeObject:actionSheet UUID:Objuuid callBackid: callbackId type:@"actionsheet"];

}
/*
 ========================================================================
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 ========================================================================
 */
- (void)alert:(PGMethod*)pMethod
{
    NSString*   pHtmlID           = nil;
    NSString*   pMessage          = nil;
    NSString*   pAlertCBID        = nil;
    NSString*   pTitle            = nil;
    NSString*   pButtonCaption    = g_PDR_Localization_Sure;
    
    pHtmlID = [pMethod getArgumentAtIndex:0];
    NSArray *args = [pMethod getArgumentAtIndex:1];
    {
        //取消息内容
        NSString *arg1  = [args objectAtIndex:0];
        if ( [arg1 isKindOfClass:[NSString class]] ) {
            pMessage = arg1;
        }
        
        arg1 = [args objectAtIndex:1];
        if ( [arg1 isKindOfClass:[NSString class]] ) {
            pAlertCBID = arg1;
        }
        
        NSString *arg2  = [args objectAtIndex:2];
        //取标题
        if ( [arg2 isKindOfClass:[NSString class]] ) {
            pTitle = arg2;
        }
        
        NSString *v3  = [args objectAtIndex:3];
        if ( [v3 isKindOfClass:[NSString class]] ) {
            pButtonCaption = v3;
        }
    }
    
    if ( nil == pTitle
        && nil == pMessage
        && nil == pButtonCaption ) {
        return;
    }
    
    UIAlertView* pAlertView = [[[UIAlertView alloc] initWithTitle:pTitle?pTitle:@""
                                                         message:pMessage
                                                        delegate:self
                                               cancelButtonTitle:pButtonCaption
                                               otherButtonTitles:nil, nil] autorelease];
    [pAlertView show];
    
    {
        PGPopTraceInfo *traceInfo = [PGPopTraceInfo infoWithType:PGPopTraceTypeAlert cb:pAlertCBID];
        if ( !m_pPopTrace ) {
            m_pPopTrace = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
        traceInfo.alertView = pAlertView;
        [m_pPopTrace setObject:traceInfo forKey:[PGPopTraceInfo getObjectKey:pAlertView]];
    }
}

/*
 ========================================================================
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 ========================================================================
 */
- (void)confirm:(PGMethod*)pMethod
{
    NSString*   pHtmlID           = nil;
    NSString*   pMessage          = nil;
    NSString*   pAlertCBID        = nil;
    NSString*   pTitle            = nil;
    NSString*   pButtonCap        = g_PDR_Localization_Sure;
    NSString*   pButtonCancel     = g_PDR_Localization_Cancel;
    NSArray*    pButtonArray      = nil;
    H5CoreAlertVerticalAlign verticalAlign = H5CoreAlertVerticalAlignCenter;
    
    if (pMethod && [pMethod.arguments count] > 0) {
        pHtmlID = [pMethod.arguments objectAtIndex:0];
        NSArray *arguments = [pMethod getArgumentAtIndex:1];
        // get Message argument1
        pMessage = [PGPluginParamHelper getStringValue:[PGPluginParamHelper getObjectAtIndex:0 inArray:arguments]];
        // get callback argument 2
        pAlertCBID = [PGPluginParamHelper getStringValue:[PGPluginParamHelper getObjectAtIndex:1 inArray:arguments]];
        //get title
        id arg3 = [PGPluginParamHelper getObjectAtIndex:2 inArray:arguments];
        if ( [arg3 isKindOfClass:[NSString class]] ) {
            pTitle = [PGPluginParamHelper getStringValue:arg3];
            NSArray *value = [PGPluginParamHelper getObjectAtIndex:3 inArray:arguments];
            if ( [value isKindOfClass:[NSArray class]] ) {
                pButtonArray = value;
            }
        } else if([arg3 isKindOfClass:[NSDictionary class]]){
            pTitle = [PGPluginParamHelper getStringValueInDict:arg3 forKey:g_pdr_string_title defalut:nil];
            pButtonArray = [PGPluginParamHelper getArrayValueInDict:arg3 forKey:@"buttons" defalut:nil];
            verticalAlign = [PGPluginParamHelper getEnumValue:[arg3 objectForKey:@"verticalAlign"]
                                                        inMap:@{g_pdr_string_center:@(H5CoreAlertVerticalAlignCenter),
                                                                g_pdr_string_top:@(H5CoreAlertVerticalAlignTop),
                                                                g_pdr_string_bottom:@(H5CoreAlertVerticalAlignBottom)}
                                                  defautValue:H5CoreAlertVerticalAlignCenter];
        }
    }
    UIAlertView* pAlertView = nil;
    H5CoreAlertViewController *alertController = nil;
    if ( H5CoreAlertVerticalAlignBottom == verticalAlign
        ||H5CoreAlertVerticalAlignTop == verticalAlign) {
        if ( !pButtonArray || 0 == [pButtonArray count] ) {
            pButtonArray = @[pButtonCap,pButtonCancel];
        }
        
        alertController = [[H5CoreAlertViewController alloc] initWithTitle:pTitle
                                                               withContent:pMessage withButtons:pButtonArray
                                                         withVerticalAlign:verticalAlign];
        alertController.delegate = self;
        
        if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series) {
            alertController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            //alertController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        } else {
        //        rootView.modalPresentationStyle = UIModalPresentationCurrentContext;
        //        rootView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        }
        
        [self presentViewController:alertController animated:NO completion:nil];
        [alertController release];
    }else {
        pAlertView = [[[UIAlertView alloc] init] autorelease];
        if (pAlertView) {
            pAlertView.delegate = self;
            pAlertView.title = pTitle;
            pAlertView.message = pMessage;
            
            if (pButtonArray) {
                for (NSString* pTitleStr in pButtonArray ) {
                    [pAlertView addButtonWithTitle:pTitleStr];
                }
            }
            else {
                [pAlertView addButtonWithTitle:pButtonCap];
                [pAlertView addButtonWithTitle:pButtonCancel];
            }
            
            [pAlertView show];
        }
    }
    
    {
        PGPopTraceInfo *traceInfo = [PGPopTraceInfo infoWithType:pAlertView?PGPopTraceTypeConfirm:PGPopTraceTypeConfirmCustrom cb:pAlertCBID];
        if ( !m_pPopTrace ) {
            m_pPopTrace = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
        traceInfo.alertView = pAlertView?pAlertView:alertController;
        [m_pPopTrace setObject:traceInfo forKey:[PGPopTraceInfo getObjectKey:pAlertView?pAlertView:alertController]];
    }
}

/*
 ========================================================================
 * @Summary:
 * @Parameters:
 * @Returns:
 * @Remark:
 * @Changelog:
 ========================================================================
 */
- (void)prompt:(PGMethod*)pMethod
{
    NSString*   pHtmlID           = nil;
    NSString*   pMessage          = nil;
    NSString*   pAlertCBID        = nil;
    NSString*   pTitle            = nil;
    NSString*   pTip              = nil;
    NSString*   pButtonCap        = g_PDR_Localization_Sure;
    NSString*   pButtonCancel     = g_PDR_Localization_Cancel;
    NSArray*    pButtonArray      = nil;
    
    if (pMethod.arguments && [pMethod.arguments count] > 0)
    {
        pHtmlID = [pMethod.arguments objectAtIndex:0];
        if ([[pMethod.arguments objectAtIndex:1]count] > 0)
        {
            pMessage = [[pMethod.arguments objectAtIndex:1] objectAtIndex:0];
            if ([[pMethod.arguments objectAtIndex:1] count] > 1)
            {
                pAlertCBID = [[pMethod.arguments objectAtIndex:1] objectAtIndex:1];
                if ([[pMethod.arguments objectAtIndex:1]count] > 2)
                {
                    NSString *value = [[pMethod.arguments objectAtIndex:1] objectAtIndex:2];
                    if ( [value isKindOfClass:[NSString class]] ) {
                        pTitle = value;
                    }
                    if ([[pMethod.arguments objectAtIndex:1]count] > 3)
                    {
                        NSString *value = [[pMethod.arguments objectAtIndex:1] objectAtIndex:3];
                        if ( [value isKindOfClass:[NSString class]] ) {
                            pTip = value;
                        }
                        if ([[pMethod.arguments objectAtIndex:1]count] > 4)
                        {
                            NSArray *value = [[pMethod.arguments objectAtIndex:1] objectAtIndex:4];
                            if ( [value isKindOfClass:[NSArray class]] ) {
                                pButtonArray = value;
                            }
                        }
                    }
                }
            }
        }
    }

    if ( [PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series ) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:pTitle?pTitle:@""
                                                                                 message:pMessage?pMessage:@""
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (pTip) {
                textField.placeholder = pTip;
            }
        }];
        if ( pButtonArray ) {
            for (NSString* pTitleStr in pButtonArray )
            {
                [alertController addAction:[UIAlertAction actionWithTitle:pTitleStr
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      NSUInteger buttonIndex = [alertController.actions indexOfObject:action];
                                                                      UITextField* textFields = [[alertController textFields] objectAtIndex:0];
                                                                      [self promptCallbck:pAlertCBID withButtonIndex:buttonIndex withText:textFields.text];
                                                                  }]];
            }
        } else {
            [alertController addAction:[UIAlertAction actionWithTitle:pButtonCap
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  UITextField* textFields = [[alertController textFields] objectAtIndex:0];
                                                                  [self promptCallbck:pAlertCBID withButtonIndex:0 withText:textFields.text];
                                                              }]];
            [alertController addAction:[UIAlertAction actionWithTitle:pButtonCancel
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction *action) {
                                                                  UITextField* textFields = [[alertController textFields] objectAtIndex:0];
                                                                  [self promptCallbck:pAlertCBID withButtonIndex:1 withText:textFields.text];
                                                              }]];
        }
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    UIAlertView* pAlertView = [[[UIAlertView alloc] init] autorelease];
    if (pAlertView)
    {
        pAlertView.delegate = self;
        pAlertView.title = pTitle;
        pAlertView.message = pMessage;
        pAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        if (pTip)
        {
            UITextField* pTextFiled = [pAlertView textFieldAtIndex:0];
            pTextFiled.placeholder = pTip;
        }
        
        if (pButtonArray)
        {
            for (NSString* pTitleStr in pButtonArray )
            {
                [pAlertView addButtonWithTitle:pTitleStr];
            }
        }
        else
        {
            [pAlertView addButtonWithTitle:pButtonCap];
            [pAlertView addButtonWithTitle:pButtonCancel];
        }
        
        [pAlertView show];
    }
    {
        PGPopTraceInfo *traceInfo = [PGPopTraceInfo infoWithType:PGPopTraceTypePrompt cb:pAlertCBID];
        if ( !m_pPopTrace ) {
            m_pPopTrace = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
        traceInfo.alertView = pAlertView;
        [m_pPopTrace setObject:traceInfo forKey: [PGPopTraceInfo getObjectKey:pAlertView]];
    }
}

- (void)promptCallbck:(NSString*)pCallBackID withButtonIndex:(NSUInteger)buttonIndex withText:(NSString*)text{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ( text ) {
        [dict setObject:text forKey:g_pdr_string_message];
    } else {
        [dict setObject:@"" forKey:g_pdr_string_message];
    }
    [dict setObject:[NSNumber numberWithInt:(int)buttonIndex] forKey:@"index"];
    PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
    [self toCallback:pCallBackID withReslut:[result toJSONString]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    /*可通过event的index属性（Number类型）获取用户关闭时点击按钮的索引值，索引值从0开始；
     0表示用户点击取消按钮，大于0值表示用户点击ActionSheetStyle中buttons属性定义的按钮，
     索引值从1开始（即1表示点击buttons中定义的第一个按钮） */
    actionSheet.delegate = nil;
    NSString *traceKey = [PGPopTraceInfo getObjectKey:actionSheet];
    PGPopTraceInfo* traceInfo = [m_pPopTrace objectForKey:traceKey];
    if ( traceInfo ) {
        NSString* pCallBackID  = traceInfo.JSCbID;
        if ( pCallBackID ) {
            if ( PGPopTraceTypeActionSheet == traceInfo.type )  {
                NSInteger postButtonIndex = buttonIndex;
                if ( buttonIndex == actionSheet.cancelButtonIndex ) {
                    postButtonIndex = 0;
                } else {
                    NSArray *buttonIndexs = traceInfo.buttonIndexs;
                    NSInteger buttonCount = [buttonIndexs count];
                    NSInteger destructivePos = 0;
                    for ( NSInteger i = 0; i < buttonCount; i++ ) {
                        NSNumber *index = [buttonIndexs objectAtIndex:i];
                        postButtonIndex = i;
                        if ( PGActionSheetButtonTypeDestructive == [index intValue] ) {
                            destructivePos = i;
                            break;
                        }
                    }
                    if ( buttonIndex == actionSheet.destructiveButtonIndex ) {
                        postButtonIndex = destructivePos+1;
                    } else {
                        NSInteger otherButtonIndex = buttonIndex;
                        otherButtonIndex = actionSheet.destructiveButtonIndex == -1 ? otherButtonIndex: otherButtonIndex-1;
                        otherButtonIndex = (actionSheet.cancelButtonIndex == actionSheet.numberOfButtons-1|| actionSheet.cancelButtonIndex == -1) ? otherButtonIndex: otherButtonIndex-1;
                        if ( otherButtonIndex >= destructivePos
                                && actionSheet.destructiveButtonIndex != -1) {
                            postButtonIndex = otherButtonIndex+2;
                        } else {
                            postButtonIndex = otherButtonIndex+1;
                        }
                    }
                }
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:(int)postButtonIndex];
                [self toCallback:pCallBackID withReslut:[result toJSONString]];
            }
        }
        [m_pPopTrace removeObjectForKey:traceKey];
    }
}

- (void)alertViewController:(H5CoreAlertViewController *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self alertView:(UIAlertView*)alertView didDismissWithButtonIndex:buttonIndex];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    NSString *traceKey = [PGPopTraceInfo getObjectKey:alertView];
    PGPopTraceInfo* traceInfo = [m_pPopTrace objectForKey:traceKey];
    if ( traceInfo ) {
        NSString* pCallBackID  = traceInfo.JSCbID;
        if ( pCallBackID ) {
            if ( PGPopTraceTypeAlert == traceInfo.type )  {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:@{@"index": @(0)}];
                [self toCallback:pCallBackID withReslut:[result toJSONString]];
            }
            else if ( PGPopTraceTypeConfirm == traceInfo.type
                     ||PGPopTraceTypeConfirmCustrom == traceInfo.type ) {
                PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:(int)buttonIndex];
                [self toCallback:pCallBackID withReslut:[result toJSONString]];
                if ( [alertView isKindOfClass:[H5CoreAlertViewController class]] ){
                    H5CoreAlertViewController *alertController = (H5CoreAlertViewController*)alertView;
                    if ( [alertController isKindOfClass:[H5CoreAlertViewController class]] ) {
                        [alertController dismissViewControllerAnimated:NO completion:nil];
                    }
                }
            }
            else if ( PGPopTraceTypePrompt == traceInfo.type )   {
                NSString* pString = [alertView textFieldAtIndex:0].text;
                [self promptCallbck:pCallBackID withButtonIndex:buttonIndex withText:pString];
            }
        }

        [m_pPopTrace removeObjectForKey:traceKey];
    }
    /*
    CGFloat* fValue = (CGFloat*)alertView;
    alertView.delegate = nil;
    [m_pAlertPeer removeObject:alertView];
    NSDictionary* pCallBackDic = [m_pAlertDelDic objectForKey:[NSString stringWithFormat:@"%f",*fValue]];
    if (pCallBackDic)
    {
        NSString* pCallBackID  = [pCallBackDic objectForKey:@"CBID"];
        NSString* pConfim      = [pCallBackDic objectForKey:@"Notification"];
        if ([pConfim isEqualToString:@"alert"])
        {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
        }
        else if ([pConfim isEqualToString:@"confirm"])
        {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:buttonIndex];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
        }
        else if ([pConfim isEqualToString:@"prompt"])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:[NSNumber numberWithInt:buttonIndex] forKey:@"index"];
            NSString* pString = [alertView textFieldAtIndex:0].text;
            if ( pString ) {
                [dict setObject:pString forKey:g_pdr_string_message];
            } else {
                [dict setObject:pString forKey:g_pdr_string_message];
            }
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
            [self toCallback:pCallBackID withReslut:[result toJSONString]];
        }
    }*/
}

- (void)onNeedLayout {
    PDRCoreApp *coreApp = self.appContext;
    if ( m_pWaitingView ) {
        m_pWaitingView.frame = coreApp.appWindow.bounds;
        [m_pWaitingView autoLayout:coreApp.appWindow.bounds];
    }
}

#pragma ---
- (void)WaitingView:(PGMethod*)command {
    
    if ( m_pWaitingView ) {
        return;
    }
    NSString *UUID = [command getArgumentAtIndex:0];
    NSArray  *args = [command getArgumentAtIndex:1];
    NSString *titile = [args objectAtIndex:0];
    NSDictionary *options = [args objectAtIndex:1];
    NSString *callbackID = [args objectAtIndex:2];
    
    PDRCoreApp *coreApp = self.appContext;
    
    if ( ![titile isKindOfClass:NSString.class] ) {
        titile = nil;
    }
    if ( ![options isKindOfClass:NSDictionary.class] ) {
        options = nil;
    }
    if (!coreApp.appWindow){return;}
    
    UIView *superView = coreApp.appWindow;
    
    if ( PDRCoreRunModeWebviewClient == [PDRCore Instance].runMode ) {
        superView = [UIApplication sharedApplication].keyWindow;
    }
    
    m_pWaitingView = [[PDRUIWaitingView alloc] initWithView:superView];
    m_pWaitingView.waitingViewDelegate = self;
    m_pWaitingView.JSFrameContext = self.JSFrameContext;
    m_pWaitingView.appContext = self.appContext;
    [m_pWaitingView setWaitingOptions:options];
    m_pWaitingView.detailsLabelText = titile;
    m_pWaitingView.UUID = UUID;
    m_pWaitingView.callBackID = callbackID;
    [superView addSubview:m_pWaitingView];
    [m_pWaitingView show:YES];
}

- (void)hudWasHidden:(PDRUIWaitingView *)hud {
    if ( [hud isKindOfClass:[PDRUIWaitingView class]] ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:0];
        [self toCallback:hud.callBackID withReslut:[result toJSONString]];
        [self __WaitingView_close];
    }
}

- (void)__WaitingView_close {
    if ( m_pWaitingView ) {
        m_pWaitingView.waitingViewDelegate = nil;
        [m_pWaitingView removeFromSuperview];
        [m_pWaitingView release];
        m_pWaitingView = nil;
    }
}

- (void)WaitingView_setTitle:(PGMethod*)command {
    if ( m_pWaitingView ) {
        //NSString *UUID = [command objectAtIndex:0];
        NSArray  *args = [command.arguments objectAtIndex:1];
        NSString *titile = [args objectAtIndex:0];
        if ( [titile isKindOfClass:[NSString class]] ) {
            m_pWaitingView.detailsLabelText = titile;
        }
    }
}

- (void)WaitingView_close:(PGMethod*)command {
  //  NSString *UUID = [command objectAtIndex:0];
    if ( m_pWaitingView ) {
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:0];
        [self toCallback:m_pWaitingView.callBackID withReslut:[result toJSONString]];
        [self __WaitingView_close];
    }
}

- (void)handlCloseWaiting:(NSNotification*)notification {
    [self WaitingView_close:nil];
}

- (void)closeWaiting:(PGMethod*)command {
    [[NSNotificationCenter defaultCenter] postNotificationName:PGUICloseWaitingNotificationKey object:nil];
}

- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe {
    self.JSFrameContext = nil;
    self.appContext = nil;
}

-(void)dealloc {
    [self __WaitingView_close];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PGUICloseWaitingNotificationKey object:nil];
    
   // [m_pDiedWebList removeAllObjects];
    [m_pDatePickDic removeAllObjects];
    [m_pDatePickDic release];
    
    NSArray *allTraceInfos = [m_pPopTrace allValues];
    for ( PGPopTraceInfo *trackInfo in allTraceInfos ) {
        if ( PGPopTraceTypeActionSheet == trackInfo.type  ) {
            trackInfo.actionSheet.delegate = nil;
            [trackInfo.actionSheet dismissWithClickedButtonIndex:0 animated:NO];
        } else if ( PGPopTraceTypeConfirmCustrom == trackInfo.type  ) {
            H5CoreAlertViewController *alertController = (H5CoreAlertViewController*)trackInfo.alertView;
            alertController.delegate = nil;
            [alertController dismissViewControllerAnimated:NO completion:nil];
        } else {
            trackInfo.alertView.delegate = nil;
        }
    }
    [m_pPopTrace removeAllObjects];
    [m_pPopTrace release];
    
    [m_previewImgDic removeAllObjects];
    [m_previewImgDic release];
    [super dealloc];
}

@end
