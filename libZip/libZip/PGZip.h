//
//  PGZip.h
//  Pandora
//
//  Created by Pro_C Mac on 13-2-26.
//
//
#import "PGMethod.h"
#import "PGPlugin.h"
enum {
    PGZipErrorCompressImgClip = PGPluginErrorNext
};
@interface PGZip : PGPlugin
- (void)compress:(PGMethod*)commands;
- (void)decompress:(PGMethod*)commands;
@end
