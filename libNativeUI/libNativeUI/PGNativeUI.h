

#import "PGPlugin.h"
#import "PGMethod.h"
#import "PDRUIDateTimePickerController.h"
#import "PDRUIWaitingView.h"
#import "PDRCoreAnimation.h"
#import "H5CoreAlertViewController.h"
#import "PGNativeImageSliderView.h"
typedef NS_ENUM(NSInteger, PGPopTraceType) {
    PGPopTraceTypeAlert,
    PGPopTraceTypeConfirm,
    PGPopTraceTypeConfirmCustrom,
    PGPopTraceTypePrompt,
    PGPopTraceTypeActionSheet
};

typedef NS_ENUM(NSInteger, PGActionSheetButtonType) {
    PGActionSheetButtonTypeDefault,
    PGActionSheetButtonTypeDestructive
};

@interface PGPopTraceInfo : NSObject
@property(nonatomic, assign)PGPopTraceType type;
@property(nonatomic, copy)NSString *JSCbID;
@property(nonatomic, assign)UIAlertView *alertView;
@property(nonatomic, assign)UIActionSheet *actionSheet;
@property(nonatomic, retain)NSArray *buttonIndexs;
+ (PGPopTraceInfo*)infoWithType:(PGPopTraceType)aType cb:(NSString*)aCB;
@end


@interface  PGNativeUI : PGPlugin
<PDRUIDateTimePickerViewControllerDelegate,H5CoreAlertViewControllerDelegate,
PDRUIWaitingViewDelegate,DCSlidrImageItemDelegate,
UIActionSheetDelegate> {
    NSMutableDictionary* m_pDatePickDic;
    NSMutableDictionary *m_pPopTrace;
    PDRUIWaitingView *m_pWaitingView;
    NSMutableDictionary* m_NativeObjArray;
    NSMutableDictionary * m_previewImgDic;
}
- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe;
@end
