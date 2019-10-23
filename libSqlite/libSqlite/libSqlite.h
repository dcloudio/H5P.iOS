//
//  libSqlite.h
//  libSqlite
//
//  Created by 4Ndf on 2019/3/16.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#include "PGPlugin.h"
#include "PGMethod.h"
#import <Foundation/Foundation.h>

@interface libSqlite : PGPlugin
-(NSData*)isOpenDatabase:(PGMethod*)command;

- (void)openDatabase:(PGMethod*)command;

- (void)executeSql:(PGMethod*)command;

- (void)selectSql:(PGMethod*)command;

- (void)transaction:(PGMethod*)command;

- (void)closeDatabase:(PGMethod*)command;
@end
