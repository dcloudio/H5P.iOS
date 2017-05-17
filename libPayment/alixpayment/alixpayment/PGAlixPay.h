
#import "PGPay.h"
//#import "AlixLibService.h"
//#import "AlixPayResult.h"
//#import "DataVerifier.h"

@interface  PGAlixPay : PGPlatby {
}
@property(nonatomic, copy)NSString *callBackID;
- (void)request:(PGMethod*)command;
@end
