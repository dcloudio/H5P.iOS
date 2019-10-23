//
//  SqliteInstanse.h
//  libSqlite
//
//  Created by 4Ndf on 2019/6/1.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SqliteInstanse : NSObject
@property (nonatomic,retain)NSMutableArray* keys;
@property(nonatomic,assign)CFMutableDictionaryRef map;
@property(nonatomic,retain)NSMutableDictionary *  nameDic;
@property(nonatomic,assign)BOOL iswwwPath;
@property(nonatomic,assign)BOOL iswwwDB;
@property(nonatomic,assign)BOOL isOpenDatabase;
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
