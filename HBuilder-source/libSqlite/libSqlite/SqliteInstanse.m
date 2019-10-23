//
//  SqliteInstanse.m
//  libSqlite
//
//  Created by 4Ndf on 2019/6/1.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "SqliteInstanse.h"

@implementation SqliteInstanse
+ (instancetype)sharedInstance{
    static SqliteInstanse  *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SqliteInstanse alloc]init];
        sharedInstance.map = CFDictionaryCreateMutable(kCFAllocatorSystemDefault, 0, NULL, NULL);
        sharedInstance.nameDic = [NSMutableDictionary new];
        sharedInstance.keys=[[NSMutableArray alloc] init];
        sharedInstance.iswwwDB = NO;
        sharedInstance.iswwwPath = NO;
        sharedInstance.isOpenDatabase = NO;
    });
    return sharedInstance;
}
@end
