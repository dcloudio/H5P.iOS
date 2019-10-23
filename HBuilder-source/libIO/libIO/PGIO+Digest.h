//
//  PGIO+Digest.h
//  libIO
//
//  Created by dcloud on 2019/6/1.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGIO.h"
NS_ASSUME_NONNULL_BEGIN

@interface PGFile(Digest)
- (NSString*) fileMD5HashWithPath:(CFStringRef)filePath;
- (NSString*) fileSha1HashWithPath:(CFStringRef)filePath;
@end

NS_ASSUME_NONNULL_END
