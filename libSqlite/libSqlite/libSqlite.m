//
//  libSqlite.m
//  libSqlite
//
//  Created by 4Ndf on 2019/3/16.
//  Copyright © 2019年 Dcloud. All rights reserved.
//

#import "libSqlite.h"
#import <sqlite3.h>
#import "PTPathUtil.h"
#import "PDRCoreAppFrame.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppManager.h"
#import "SqliteInstanse.h"
@interface libSqlite()
@property(nonatomic,retain)SqliteInstanse* sqliteInstanse;
@end
@implementation libSqlite

-(SqliteInstanse*)sqliteInstanse{
    if (!_sqliteInstanse) {
        _sqliteInstanse = [SqliteInstanse sharedInstance];
    }
    return _sqliteInstanse ;
}
- (NSString*)getName:(NSString*)name{
    if(self.sqliteInstanse.keys == nil){
        return name;
    }
    for (NSString * str in self.sqliteInstanse.keys){
        if([str isEqualToString:name]){
            return str;
        }
    }
    return name;
}
-(NSData*)isOpenDatabase:(PGMethod*)command{
    if ( !command.arguments && ![command.arguments isKindOfClass:[NSArray class]] ) {
        return [self resultWithUndefined];
    }else{
        NSArray *args = (NSArray*)command.arguments;
        NSDictionary* dic = [args objectAtIndex:0];
        NSString * name = [self getName:dic[@"name"]];
//        NSString* path = [args objectAtIndex:1];
        if (name.length>0 ) {
            if (self.sqliteInstanse.nameDic.allKeys.count>0) {
                NSDictionary * dic = self.sqliteInstanse.nameDic[name];
                BOOL isOpenDatabase = [dic[@"isOpenDatabase"] boolValue];
                if (isOpenDatabase) {
                    return [self resultWithBool:YES];
                }else{
                    return [self resultWithBool:NO];
                }
            }else{
                return [self resultWithUndefined];
            }
        }else{
            return [self resultWithUndefined];
        }
    }
}
- (void)openDatabase:(PGMethod*)command
{
    
    NSString* cbId = [command.arguments objectAtIndex:0];
    NSString* name = [command.arguments objectAtIndex:1];
    name = [self getName:name];
    NSString* path = [command.arguments objectAtIndex:2];
    
    if (self.sqliteInstanse.nameDic.allKeys.count>0) {
        NSDictionary * dic = self.sqliteInstanse.nameDic[name];
        if (dic !=nil) {
            BOOL iswwwDB = [dic[@"iswwwDB"] boolValue];
            BOOL iswwwPath = [dic[@"iswwwPath"] boolValue];
            NSString * daPath = dic[@"dbPath"];
            NSString * tPath = [PTPathUtil h5Path2SysPath:path basePath:self.JSFrameContext.baseURL?self.JSFrameContext.baseURL:@""];
            if (tPath.length>0 && daPath.length>0 && [tPath isEqualToString:daPath]) {
                if (iswwwPath == YES && iswwwDB == NO) {
                    [self toErrorCallback:cbId withCode:-1403 withMessage:@"Cannot create file private directory,such as:\'www\'"];
                    return ;
                }
            }
//            else if(tPath.length>0 && daPath.length>0){
//                [self toErrorCallback:cbId withCode:-1404 withMessage:@"Error:The name of the database and the database path does not match!"];
//                return;
//            }
        }
    }
    
    PDRCoreApp *coreApp = (PDRCoreApp*)[PDRCore Instance].appManager.activeApp;
    NSString* wwwPath = [coreApp.workRootPath stringByAppendingPathComponent:@"/www"];
    NSString * dbPath  = [PTPathUtil h5Path2SysPath:path basePath:self.JSFrameContext.baseURL?self.JSFrameContext.baseURL:@""];
    if ([dbPath containsString:wwwPath]) {//传过来的路径是否是www目录
        self.sqliteInstanse.iswwwPath  = YES;
    }else{
        self.sqliteInstanse.iswwwPath = NO;
    }
    
    NSString * jdPath  = [PTPathUtil h5Path2SysPath:path basePath:self.JSFrameContext.baseURL appInfo:self.appContext.appInfo];
    if([[NSFileManager defaultManager] fileExistsAtPath:jdPath] == NO){
        if (self.sqliteInstanse.iswwwPath == YES) {
            self.sqliteInstanse.iswwwDB =YES;
            [self toErrorCallback:cbId withCode:-1403 withMessage:@"Cannot create file private directory,such as:\'www\'"];
            return;
        }else{
            self.sqliteInstanse.iswwwDB = NO;
        }
        NSArray * arr = [path componentsSeparatedByString:@"/"];
        jdPath = [jdPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@",[arr lastObject]]  withString:@""];
        NSError* error;
        BOOL issuuc =  [[NSFileManager defaultManager] createDirectoryAtPath:jdPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (issuuc ==NO) {
             [self toErrorCallback:cbId withCode:-1404 withMessage:[NSString stringWithFormat:@"Error:%@", error.description]];
        }else{
            jdPath = [NSString stringWithFormat:@"%@/%@",jdPath,[arr lastObject]];
        }
    }else if(self.sqliteInstanse.iswwwPath ==YES){
        self.sqliteInstanse.iswwwDB =YES;
    }else{
        self.sqliteInstanse.iswwwDB = NO;
    }
    NSMutableDictionary * dic = nil;
    if (self.sqliteInstanse.nameDic[name]==nil) {
        dic  = [NSMutableDictionary new];
    }else{
        dic = self.sqliteInstanse.nameDic[name];
    }
    [dic setValue:[NSNumber numberWithBool:self.sqliteInstanse.iswwwDB] forKey:@"iswwwDB"];
    [dic setValue:[NSNumber numberWithBool:self.sqliteInstanse.iswwwPath] forKey:@"iswwwPath"];
    [dic setValue:dbPath forKey:@"dbPath"];
    [self.sqliteInstanse.nameDic setObject:dic forKey:name];
    
    if(CFDictionaryContainsKey(self.sqliteInstanse.map, (__bridge const void *)(name))){
        [self toErrorCallback:cbId withCode:-1402 withMessage:@"Same Name Already Open"];
        return;
    }
    sqlite3 * database;
    if (self.sqliteInstanse.iswwwDB) {
        if (sqlite3_open_v2(jdPath.UTF8String, &database, SQLITE_OPEN_READONLY, NULL)== SQLITE_OK) {
            CFDictionaryAddValue(self.sqliteInstanse.map,(__bridge const void *)(name),database);
            [self.sqliteInstanse.keys addObject:name];
            [dic setValue:[NSNumber numberWithBool:YES] forKey:@"isOpenDatabase"];
            [self.sqliteInstanse.nameDic setObject:dic forKey:name];
            [self toSucessCallback:cbId withJSON:@{}];
        }else{
            sqlite3_close(database);
            [self toErrorCallback:cbId withCode:-1404 withMessage:@"Error: open database fail"];
        }
    }else{
        if (sqlite3_open(jdPath.UTF8String, &database) == SQLITE_OK) {
            CFDictionaryAddValue(self.sqliteInstanse.map,(__bridge const void *)(name),database);
            [self.sqliteInstanse.keys addObject:name];
            [dic setValue:[NSNumber numberWithBool:YES] forKey:@"isOpenDatabase"];
            [self.sqliteInstanse.nameDic setObject:dic forKey:name];
            [self toSucessCallback:cbId withJSON:@{}];
        }else{
            sqlite3_close(database);
            [self toErrorCallback:cbId withCode:-1404 withMessage:@"Error:open database fail"];
        }
    }
}
- (void)selectSql:(PGMethod*)command
{
    NSString* cbId = [command.arguments objectAtIndex:0];
    NSString* name = [command.arguments objectAtIndex:1];
    name = [self getName:name];
    NSString* sql = [command.arguments objectAtIndex:2];
//    if (self.nameDic.allKeys.count>0) {
//        NSDictionary * dic = self.nameDic[name];
//        BOOL iswwwDB =  [dic[@"iswwwDB"] boolValue];
////        if (iswwwDB ==YES) {
////            if (!([sql containsString:@"select"]||[sql containsString:@"SELECT"])) {
////                [self toErrorCallback:cbId withCode:-2 withMessage:@"www目录下数据库只有读权限！"];
////                return;
////            }
//        }
//    }
    if(self.sqliteInstanse.map == nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    const sqlite3 * database=CFDictionaryGetValue(self.sqliteInstanse.map,(__bridge const void *)(name));
    if(database==nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare(database, sql.UTF8String, -1, &stmt, NULL);
    if (result == SQLITE_OK) {
        NSMutableArray * res=[[NSMutableArray alloc] init];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSMutableDictionary * data=[[NSMutableDictionary alloc] init];
            int l = sqlite3_column_count(stmt);
            for (int i=0; i<l; i++) {
                int type = sqlite3_column_type(stmt, i);
                NSString * name=[NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
                switch (type) {
                    case SQLITE_NULL:
                        data[name]=nil;
                        break;
                    case SQLITE_TEXT:
                        data[name]=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, i)];
                        break;
                    case SQLITE_FLOAT:
                        data[name]=@(sqlite3_column_double(stmt, i));
                        break;
                    case SQLITE_INTEGER:
                        data[name]=@(sqlite3_column_int(stmt, i));
                        break;
                    case SQLITE_BLOB:
                        data[name] = [NSString stringWithFormat:@"%s",sqlite3_column_blob(stmt, i)];
                    default:
                        break;
                }
            }
            [res addObject:data];
        }
        [self toSucessCallback:cbId withArray:res];
    }else{
        if (result ==SQLITE_READONLY) {
            [self toErrorCallback:cbId withCode:-1404 withMessage:@"Error: Attempt to write a readonly database. Cannot create file private directory,such as:\'www\'"];
        }else{
            const char * mes = sqlite3_errmsg(database);
            [self toErrorCallback:cbId withCode:-1404 withMessage:[NSString stringWithFormat:@"Error:%s",mes]];
        }
    }
    sqlite3_finalize(stmt);
}
- (void)executeSql:(PGMethod*)command
{
    NSString* cbId = [command.arguments objectAtIndex:0];
    NSString* name = [command.arguments objectAtIndex:1];
    name = [self getName:name];
    NSString* sql = [command.arguments objectAtIndex:2];
//    if (self.nameDic.allKeys.count>0) {
//        NSDictionary * dic = self.nameDic[name];
//        BOOL iswwwDB =  [dic[@"iswwwDB"] boolValue];
//        if (iswwwDB ==YES) {
////            [self toErrorCallback:cbId withCode:-2 withMessage:@"www目录下数据库只有读权限！"];
////            return;
//        }
//    }
    if(self.sqliteInstanse.map == nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    const sqlite3 * database=CFDictionaryGetValue(self.sqliteInstanse.map,(__bridge const void *)(name));
    if(database==nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    char *error = NULL;
    int result = sqlite3_exec(database, sql.UTF8String, nil, nil, &error);
    if(result == SQLITE_OK){
        [self toSucessCallback:cbId withJSON:@{}];
    }else{
        if (result ==SQLITE_READONLY) {
            [self toErrorCallback:cbId withCode:-1404 withMessage:@"Error:Attempt to write a readonly database. Cannot create file private directory,such as:\'www\'"];
        }else{
            [self toErrorCallback:cbId withCode:-1404 withMessage:[NSString stringWithFormat:@"Error:%@", [NSString stringWithUTF8String:error]]];
        }
    }
    sqlite3_free(error);
}

- (void)transaction:(PGMethod*)command
{
    NSString* cbId = [command.arguments objectAtIndex:0];
    NSString* name = [command.arguments objectAtIndex:1];
    name = [self getName:name];
    NSString* operation = [command.arguments objectAtIndex:2];
//    if (self.nameDic.allKeys.count>0) {
//        NSDictionary * dic = self.nameDic[name];
//        BOOL iswwwDB =  [dic[@"iswwwDB"] boolValue];
//        if (iswwwDB ==YES) {
////            [self toErrorCallback:cbId withCode:-2 withMessage:@"www目录下数据库只有读权限！"];
////            return;
//        }
//    }
    if(self.sqliteInstanse.map == nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    const sqlite3 * database=CFDictionaryGetValue(self.sqliteInstanse.map,(__bridge const void *)(name));
    if(database==nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    
    char *error = NULL;
    int result = sqlite3_exec(database, operation.uppercaseString.UTF8String, NULL, NULL, &error);
    if (result ==SQLITE_OK){
        [self toSucessCallback:cbId withJSON:@{}];
    }else{
        if (result ==SQLITE_READONLY) {
            [self toErrorCallback:cbId withCode:-1404 withMessage:@"Error:Attempt to write a readonly database. Cannot create file private directory,such as:\'www\'"];
        }else{
            [self toErrorCallback:cbId withCode:-1404 withMessage:[NSString stringWithFormat:@"Error:%@", [NSString stringWithUTF8String:error]]];
        }
    }
    sqlite3_free(error);
}

- (void)closeDatabase:(PGMethod*)command
{
    NSString* cbId = [command.arguments objectAtIndex:0];
    NSString* name = [command.arguments objectAtIndex:1];
    name = [self getName:name];
    if(self.sqliteInstanse.map == nil){
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
        return;
    }
    const sqlite3 * database=CFDictionaryGetValue(self.sqliteInstanse.map,(__bridge const void *)(name));
    if(database!=nil){
        sqlite3_close(database);
        CFDictionaryRemoveValue(self.sqliteInstanse.map,(__bridge const void *)(name));        
        [self.sqliteInstanse.keys removeObject:name];
        [self.sqliteInstanse.nameDic removeObjectForKey:name];
        [self toSucessCallback:cbId withJSON:@{}];
    }else{
        [self toErrorCallback:cbId withCode:-1401 withMessage:@"Not Open"];
    }
}
- (void)dealloc
{
    for (NSString * name in self.sqliteInstanse.nameDic.allKeys) {
        const sqlite3 * database=CFDictionaryGetValue(self.sqliteInstanse.map,(__bridge const void *)(name));
        sqlite3_close(database);
        CFDictionaryRemoveValue(self.sqliteInstanse.map,(__bridge const void *)(name));
        [self.sqliteInstanse.keys removeObject:name];
    }
    [self.sqliteInstanse.nameDic removeAllObjects];
}
@end
