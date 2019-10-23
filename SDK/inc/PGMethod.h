//
//  PGMethod.h
//  Pandora
//
//  Created by Pro_C Mac on 12-12-24.
//
//

#ifndef _PANDORA_PGMETHOD_H_
#define _PANDORA_PGMETHOD_H_
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PGMethodStatus) {
    PGMethodStatusNormal,
    PGMethodStatusAfterAuth
};

/** JavaScript 调用参数
 */
@interface PGMethod : NSObject

+ (PGMethod*)commandFromJson:(NSArray*)pJsonEntry;
+ (PGMethod*)commandWithHtmlID:(NSString*)htmlID
               withFeatureName:(NSString*)featureName
              withfunctionName:(NSString*)functionName
                 withArguments:(id)arguments;
- (void) legacyArguments:(NSMutableArray**)legacyArguments andDict:(NSMutableDictionary**)legacyDict ;

@property (nonatomic, retain)NSString*   htmlID;
@property (nonatomic, retain)NSString*   featureName;
@property (nonatomic, retain)NSString*   functionName;
@property (nonatomic, retain)NSString*   callBackID;
@property (nonatomic, retain)NSString*   sid;
@property (nonatomic, retain)NSString*   locationHerf;
@property (nonatomic, assign)PGMethodStatus status;

/// @brief JavaScirpt调用参数数组
@property (nonatomic, retain)NSArray*    arguments;
-(id)getArgumentAtIndex:(NSUInteger)index;
@end

#endif
