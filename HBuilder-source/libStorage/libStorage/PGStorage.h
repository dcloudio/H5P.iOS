//
//  pg_nStorage.h
//  Pandora
//
//  Created by Pro_C Mac on 13-1-18.
//
//
#import "PGPlugin.h"
#import "PGMethod.h"

@interface PGNStorage : PGPlugin
- (NSData*)SyncexecMethod:(PGMethod*)pArguments;
//js invoke method
- (NSData*)getLength:(PGMethod*)command;
- (NSData*)getItem:(PGMethod*)command;
- (NSData*)setItem:(PGMethod*)command;
- (NSData*)removeItem:(PGMethod*)command;
- (NSData*)clear:(PGMethod*)command;
- (NSData*)key:(PGMethod*)command;
- (NSData*)getAllKeys:(PGMethod*)command;
@end
