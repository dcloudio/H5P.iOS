//
//  pg_nStorage.m
//  Pandora
//
//  Created by Pro_C Mac on 13-1-18.
//
//

#import "PGStorage.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppManager.h"
#import "PDRToolSystemEx.h"
#import "PDRCoreAppInfo.h"
#import <storage/storage.h>
#include <objc/message.h>

@interface PGNStorage()
@property(nonatomic, strong)NSString*domain;
- (NSData*)JSNStorage_getLength:(NSArray*)pArray;
- (NSData*)JSNStorage_getItem:(NSArray*)pArray;
- (NSData*)JSNStorage_setItem:(NSArray*)pArray;
- (NSData*)JSNStorage_removeItem:(NSArray*)pArray;
- (NSData*)JSNStorage_clear:(NSArray*)pArray;
- (NSData*)JSNStorage_key:(NSArray*)pArray;

@end

@implementation PGNStorage

- (NSString*)getStorageFilePath {
    return [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"egarotsn"];
}

- (NSString*)getAESKey {
    return @"iodcloudnstorage";
}

- (void)migrateStorage {
    NSDictionary *storage = nil;
    NSString *oldStorageFilePath = [self.appContext.appInfo.dataPath stringByAppendingPathComponent:@"storage.plist"];
    if ( [[NSFileManager defaultManager] fileExistsAtPath:oldStorageFilePath] ) {
        //初始化storage plist
        NSString * errorDesc = nil;
        NSPropertyListFormat format;
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:oldStorageFilePath];
        storage = (NSDictionary *)[NSPropertyListSerialization
                                                 propertyListFromData:plistXML
                                                 mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                 format:&format errorDescription:&errorDesc];
        [[NSFileManager defaultManager] removeItemAtPath:oldStorageFilePath error:nil];
    } else {
        NSData *inputData = [NSData dataWithContentsOfFile:[self getStorageFilePath]];
        if ( inputData ) {
            inputData = [inputData AESDecryptWithKey:[self getAESKey]];
            if ( inputData ) {
                storage = [NSKeyedUnarchiver unarchiveObjectWithData:inputData];
            }
        }
        [[NSFileManager defaultManager] removeItemAtPath:[self getStorageFilePath] error:nil];
    }
    if ( [storage isKindOfClass:[NSDictionary class]] && [storage count]) {
        [storage enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ( [key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]] ) {
                @try{
                    [[self getStorage] setItem:obj value:key callback:nil];
                }
                @catch(NSException* exc){
                    NSLog(@"%@",exc);
                }
            }
        }];
    }
}

- (void)onAppEnterBackground {
}

- (void) onAppStarted:(NSDictionary*)options {
    self.domain = self.appContext.appInfo.appID?self.appContext.appInfo.appID:@"";
    Storage *storage = [StorageManager activeStorageWithDomain:self.domain];
    [storage setRootPath:self.appContext.appInfo.dataPath];
    [self migrateStorage];
}

- (Storage *)getStorage {
    return [StorageManager storageWithDomain:self.domain];
}

- ( NSData* )SyncexecMethod:(PGMethod*)pArguments
{
    NSString* methodName = [pArguments.arguments objectAtIndex:0];
    NSString* methodNameWithArgs = [NSString stringWithFormat:@"JSNStorage_%@:", methodName];
    SEL normalSelector = NSSelectorFromString(methodNameWithArgs);
    if ([self respondsToSelector:normalSelector])
    {
        return ((id (*)(id, SEL, id))objc_msgSend)(self, normalSelector, [pArguments.arguments objectAtIndex:1]);
    }
    return nil;
}

- (NSData*)JSNStorage_getLength:(NSArray*)pArray
{
    NSUInteger count = [[self getStorage] length];
    return [self resultWithInt:(int)count];
}


- (NSData*)JSNStorage_getItem:(NSArray*)pArray
{
    NSString* pKey = nil;
    NSString* retValue = @"null:";
    pKey = [pArray objectAtIndex:0];
    if ( [pKey isKindOfClass:[NSString class]] ) {
        NSString *value = [[self getStorage] getItem:pKey callback:nil];
        if ( [value isKindOfClass:[NSString class]] ) {
            retValue = [NSString stringWithFormat:@"string:%@", value];
        }
    }
    return [retValue dataUsingEncoding:NSUTF8StringEncoding];
}


- (NSData*)JSNStorage_setItem:(NSArray*)pArray
{
    NSString*   pKey        = nil;
    NSString*   pValue      = nil;
    
    pKey = [pArray objectAtIndex:0];
    pValue = [pArray objectAtIndex:1];

    if ( [pKey isKindOfClass:[NSString class]]
        && [pValue isKindOfClass:[NSString class]] ) {
        [[self getStorage] setItemPersistent:pKey value:pValue callback:nil];
        return [self resultWithBool:TRUE];
    }
    return [self resultWithBool:FALSE];
}

- (NSData*)JSNStorage_removeItem:(NSArray*)pArray
{
    NSString*   pKey        = nil;
    
    pKey = [pArray objectAtIndex:0];
    if ( [pKey isKindOfClass:[NSString class]]) {
        [[self getStorage] removeItem:pKey callback:nil];
        return [self resultWithBool:TRUE];
    }
    return [self resultWithBool:FALSE];
}

- (NSData*)JSNStorage_clear:(NSArray*)pArray
{
    [[self getStorage] clear];
    return [self resultWithBool:TRUE];
}


- (NSData*)JSNStorage_key:(NSArray*)pArray
{
    int         nIndex      = 0;
    if ( pArray && [pArray count] >= 1) {
        nIndex = [[pArray objectAtIndex:0] intValue];
    }
    
    NSArray* pAllKey = [[self getStorage] getAllKeys];
    if ( pAllKey ) {
        if ( nIndex >= 0 && nIndex < [pAllKey count] ) {
            NSString* pString = [pAllKey objectAtIndex:nIndex];
            return [self resultWithString:pString];
        }
    }
    return [self resultWithNull];
}

- (NSData*)getAllKeys:(PGMethod*)command {
    NSArray* pAllKey = [[self getStorage] getAllKeys];
    if ( pAllKey ) {
       return [self resultWithArray:pAllKey];
    }
    return [self resultWithNull];
}

//js invoke method
- (NSData*)getLength:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return nil;
    }
    return [self JSNStorage_getLength:command.arguments];
}

- (NSData*)getItem:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return nil;
    }
    return [self JSNStorage_getItem:command.arguments];
}

- (NSData*)setItem:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return nil;
    }
    return [self JSNStorage_setItem:command.arguments];
}

- (NSData*)removeItem:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return nil;
    }
    return [self JSNStorage_removeItem:command.arguments];
}

- (NSData*)clear:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return nil;
    }
    return [self JSNStorage_clear:command.arguments];
}

- (NSData*)key:(PGMethod*)command {
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ){
        return nil;
    }
    return [self JSNStorage_key:command.arguments];
}

- (void)onAppClose {
    [StorageManager serializeStorageWithDomain:self.appContext.appInfo.appID];
}

- (void)dealloc {
    
}

@end
