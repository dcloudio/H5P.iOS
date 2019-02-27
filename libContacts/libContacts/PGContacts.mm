/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "PGContacts.h"
#import "NSArray+Comparisons.h"

@implementation PGContacts

- (void)dealloc {
    [super dealloc];
}
// no longer used since code gets AddressBook for each operation.
// If address book changes during save or remove operation, may get error but not much we can do about it
// If address book changes during UI creation, display or edit, we don't control any saves so no need for callback

/*void addressBookChanged(ABAddressBookRef addressBook, CFDictionaryRef info, void* context)
 {
 // note that this function is only called when another AddressBook instance modifies
 // the address book, not the current one. For example, through an OTA MobileMe sync
 Contacts* contacts = (Contacts*)context;
 [contacts addressBookDirty];
 }*/

- (PGPlugin*)initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:(PDRCoreApp *)app
{
    self = (PGContacts*)[super initWithWebView:(PDRCoreAppFrame*)theWebView withAppContxt:app];
    
    /*if (self) {
     addressBook = ABAddressBookCreate();
     ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, self);
     }*/
    
    return self;
}

// overridden to clean up Contact statics
- (void)onAppTerminate
{
    // NSLog(@"Contacts::onAppTerminate");
}

- (void)search:(PGMethod*)command
{
    NSString* callbackId = [command.arguments objectAtIndex:0];
    NSArray* fields = [command.arguments objectAtIndex:1];
    NSDictionary* findOptions = [command.arguments objectAtIndex:2 withDefault:[NSNull null]];
    
    if ( ![fields isKindOfClass:[NSArray class]] ) {
        fields = nil;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // from Apple:  Important You must ensure that an instance of ABAddressBookRef is used by only one thread.
        // which is why address book is created within the dispatch queue.
        // more details here: http: //blog.byadrian.net/2012/05/05/ios-addressbook-framework-and-gcd/
        CDVAddressBookHelper* abHelper = [[[CDVAddressBookHelper alloc] init] autorelease];
        PGContacts* weakSelf = self;     // play it safe to avoid retain cycles
        // it gets uglier, block within block.....
        [abHelper createAddressBook: ^(ABAddressBookRef addrBook, CDVAddressBookAccessError* errCode) {
            if (addrBook == NULL) {
                // permission was denied or other error - return error
                PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                                       messageToErrorObject:errCode ? errCode.errorCode:UNKNOWN_ERROR];
                [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
                return;
            }
            
            NSArray* foundRecords = nil;
            // get the findOptions values
            BOOL multiple = YES;         // default is false
            NSArray* filter = nil;
            NSString* filterValue = nil;
            NSMutableArray *filterFilelds = nil;
            BOOL filterIsId = NO;
            ABRecordID filterRecordID = 0;

            if ([findOptions isKindOfClass:[NSDictionary class]]) {
                id value = nil;
                filter = (NSArray*)[findOptions objectForKey:@"filter"];
                if ( ![filter isKindOfClass:[NSArray class]] ) {
                    filter = nil;
                }
                value = [findOptions objectForKey:@"multiple"];
                if ([value isKindOfClass:[NSNumber class]]) {
                    // multiple is a boolean that will come through as an NSNumber
                    multiple = [(NSNumber*)value boolValue];
                    // NSLog(@"multiple is: %d", multiple);
                }
            }
            
            for ( NSDictionary *dict in filter ) {
                if ( !filterFilelds ) {
                    filterFilelds = [NSMutableArray array];
                }
                NSString *fileld = [dict objectForKey:@"field"];
                NSString *value = [dict objectForKey:@"value"];
                if ( NSOrderedSame == [@"id" caseInsensitiveCompare:fileld] ) {
                    filterIsId = YES;
                    filterRecordID = (ABRecordID)[value integerValue];
                    break;
                }
                if ( [fileld isKindOfClass:[NSString class]]
                    && [value isKindOfClass:[NSString class]]) {
                    [filterFilelds addObject:fileld];
                    filterValue = value;
                    break;
                }
            }
            
           // NSDictionary* returnFields = [[PGContact class] calcReturnFields:fields];
            NSMutableArray* matches = nil;
//            if (!filter /*|| [filter isEqualToString:@""]*/) {
//                // get all records
//                foundRecords = ( NSArray*)ABAddressBookCopyArrayOfAllPeople(addrBook);
//                if (foundRecords && ([foundRecords count] > 0)) {
//                    // create Contacts and put into matches array
//                    // doesn't make sense to ask for all records when multiple == NO but better check
//                    NSUInteger xferCount = multiple == YES ? [foundRecords count] : 1;
//                    matches = [NSMutableArray arrayWithCapacity:xferCount];
//                    
//                    for (NSUInteger k = 0; k < xferCount; k++) {
//                        PGContact* xferContact = [[PGContact alloc] initFromABRecord:( ABRecordRef)[foundRecords objectAtIndex:k]];
//                        [matches addObject:xferContact];
//                        [xferContact release];
//                        xferContact = nil;
//                    }
//                }
//            } else
            {
                //开始匹配联系人
                NSDictionary* searchFileds = nil;
                searchFileds = [[PGContact class] calcReturnFields:filterFilelds];
                if ( filterIsId ) {
                    ABRecordRef ref = (NSArray*)ABAddressBookGetPersonWithRecordID(addrBook, filterRecordID);
                    if ( ref ) {
                        foundRecords = [NSArray arrayWithObjects:(id)ref, nil];
                    }
                } else {
                    foundRecords = (NSArray*)ABAddressBookCopyArrayOfAllPeople(addrBook);
                }
                matches = [NSMutableArray arrayWithCapacity:1];
                BOOL bFound = NO;
                NSUInteger testCount = [foundRecords count];
              //  NSUInteger xferCount = multiple == YES ? testCount : 1;
                for (NSUInteger j = 0; j < testCount; j++) {
                    PGContact* testContact = [[PGContact alloc] initFromABRecord:( ABRecordRef)[foundRecords objectAtIndex:j]];
                    if (testContact ) {
                        if ( [searchFileds count] > 0 ) {
                            bFound = [testContact foundValue:filterValue inFields:searchFileds];
                            if (bFound) {
                                [matches addObject:testContact];
                                if ( !multiple ) {
                                    break;
                                }
                            }
                            [testContact release];
                            testContact = nil;
                        } else {
                            [matches addObject:testContact];
                            if ( !multiple ) {
                                break;
                            }
                        }
                    }
                }
            }
            //开始过滤联系人字段
            NSMutableArray* returnContacts = [NSMutableArray arrayWithCapacity:1];
            
            if ((matches != nil) && ([matches count] > 0)) {
                NSDictionary* returnFields = nil;
                if ( nil == fields
                    || ([fields isKindOfClass:[NSArray class]] && 0== [fields count])
                    ) {
                    returnFields = [PGContact defaultFields];
                } else {
                    returnFields = [[PGContact class] calcReturnFields:fields];
                    if ( nil == returnFields ) {
                        returnFields = [PGContact defaultFields];
                    }
                }
                // convert to JS Contacts format and return in callback
                // - returnFields  determines what properties to return
                @autoreleasepool {
                   // NSUInteger count = multiple == YES ? [matches count] : 1;
                    NSUInteger count = [matches count];
                    for (NSUInteger i = 0; i < count; i++) {
                        PGContact* newContact = [matches objectAtIndex:i];
                        NSDictionary* aContact = [newContact toDictionary:returnFields allowNull:NO withAppContext:self.appContext];
                        [returnContacts addObject:aContact];
                    }
                }
            }
            // return found contacts (array is empty if no contacts found)
            PDRPluginResult* result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray:returnContacts];
            [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
            // NSLog(@"findCallback string: %@", jsString);
            
            if (addrBook) {
                CFRelease(addrBook);
            }
        }];
    });     // end of workQueue block
    
    return;
}

- (void)save:(PGMethod*)command
{
    NSString* callbackId = [command.arguments objectAtIndex:0];
    NSDictionary* contactDict = [command.arguments objectAtIndex:1];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CDVAddressBookHelper* abHelper = [[[CDVAddressBookHelper alloc] init] autorelease];
        PGContacts* weakSelf = self;     // play it safe to avoid retain cycles
        
        [abHelper createAddressBook: ^(ABAddressBookRef addrBook, CDVAddressBookAccessError* errorCode) {
            PDRPluginResult* result = nil;
            if (addrBook == NULL) {
                // permission was denied or other error - return error
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:errorCode ? errorCode.errorCode:UNKNOWN_ERROR];
                [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
                return;
            }
            
            bool bIsError = FALSE, bSuccess = FALSE;
            BOOL bUpdate = NO;
            CDVContactError errCode = UNKNOWN_ERROR;
            CFErrorRef error;
            NSNumber* cId = [contactDict valueForKey:kW3ContactId];
            PGContact* aContact = nil;
            ABRecordRef rec = nil;
            if (cId && ![cId isKindOfClass:[NSNull class]]) {
                rec = ABAddressBookGetPersonWithRecordID(addrBook, [cId intValue]);
                if (rec) {
                    aContact = [[[PGContact alloc] initFromABRecord:rec] autorelease];
                    bUpdate = YES;
                }
            }
            if (!aContact) {
                aContact = [[[PGContact alloc] init] autorelease];
            }
            
            bSuccess = [aContact setFromContactDict:contactDict asUpdate:bUpdate];
            if (bSuccess) {
                if (!bUpdate) {
                    bSuccess = ABAddressBookAddRecord(addrBook, [aContact record], &error);
                }
                if (bSuccess) {
                    bSuccess = ABAddressBookSave(addrBook, &error);
                }
                if (!bSuccess) {         // need to provide error codes
                    bIsError = TRUE;
                    errCode = IO_ERROR;
                } else {
                    // give original dictionary back?  If generate dictionary from saved contact, have no returnFields specified
                    // so would give back all fields (which W3C spec. indicates is not desired)
                    // for now (while testing) give back saved, full contact
                    NSDictionary* newContact = [aContact toDictionary:[PGContact defaultFields]];
                    // NSString* contactStr = [newContact JSONRepresentation];
                    result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:newContact];
                }
            } else {
                bIsError = TRUE;
                errCode = IO_ERROR;
            }
            CFRelease(addrBook);
            
            if (bIsError) {
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:errCode];
            }
            
            if (result) {
                [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
            }
        }];
    });     // end of  queue
}

- (void)remove:(PGMethod*)command
{
    NSString* callbackId = [command.arguments objectAtIndex:0];
    NSNumber* cId = [command.arguments objectAtIndex:1];
    
    CDVAddressBookHelper* abHelper = [[[CDVAddressBookHelper alloc] init] autorelease];
    PGContacts* weakSelf = self;  // play it safe to avoid retain cycles
    
    [abHelper createAddressBook: ^(ABAddressBookRef addrBook, CDVAddressBookAccessError* errorCode) {
        PDRPluginResult* result = nil;
        if (addrBook == NULL) {
            // permission was denied or other error - return error
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:errorCode ? errorCode.errorCode:UNKNOWN_ERROR];
            [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
            return;
        }
        
        bool bIsError = FALSE, bSuccess = FALSE;
        CDVContactError errCode = UNKNOWN_ERROR;
        CFErrorRef error;
        ABRecordRef rec = nil;
        if (cId && ![cId isKindOfClass:[NSNull class]] && ([cId intValue] != kABRecordInvalidID)) {
            rec = ABAddressBookGetPersonWithRecordID(addrBook, [cId intValue]);
            if (rec) {
                bSuccess = ABAddressBookRemoveRecord(addrBook, rec, &error);
                if (!bSuccess) {
                    bIsError = TRUE;
                    errCode = IO_ERROR;
                } else {
                    bSuccess = ABAddressBookSave(addrBook, &error);
                    if (!bSuccess) {
                        bIsError = TRUE;
                        errCode = IO_ERROR;
                    } else {
                        // set id to null
                        // [contactDict setObject:[NSNull null] forKey:kW3ContactId];
                        // result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: contactDict];
                        result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:0];
                        // NSString* contactStr = [contactDict JSONRepresentation];
                    }
                }
            } else {
                // no record found return error
                bIsError = TRUE;
                errCode = UNKNOWN_ERROR;
            }
        } else {
            // invalid contact id provided
            bIsError = TRUE;
            errCode = INVALID_ARGUMENT_ERROR;
        }
        
        if (addrBook) {
            CFRelease(addrBook);
        }
        if (bIsError) {
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:errCode];
        }
        if (result) {
            [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
        }
    }];
    return;
}

- (void)getAddressBook:(PGMethod*)command {
    NSString* callbackId = [command.arguments objectAtIndex:0];
   // NSNumber* type = [command.arguments objectAtIndex:1];
    
    CDVAddressBookHelper* abHelper = [[[CDVAddressBookHelper alloc] init] autorelease];
    PGContacts* weakSelf = self;  // play it safe to avoid retain cycles
    
    [abHelper createAddressBook: ^(ABAddressBookRef addrBook, CDVAddressBookAccessError* errorCode) {
        PDRPluginResult* result = nil;
        if (addrBook == NULL) {
            // permission was denied or other error - return error
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:errorCode ? errorCode.errorCode:UNKNOWN_ERROR];
            [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
            return;
        }
        if ( UNKNOWN_ERROR == errorCode.errorCode ) {
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:errorCode ? errorCode.errorCode:UNKNOWN_ERROR];
        } else {
            result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsInt:errorCode ? errorCode.errorCode:UNKNOWN_ERROR];
        }
        [weakSelf toCallback:callbackId withReslut:[result toJSONString]];
        if (addrBook) {
            CFRelease(addrBook);
        }
    }];
}

-(PGPluginAuthorizeStatus)authorizeStatus {
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    switch (authStatus) {
        case kABAuthorizationStatusNotDetermined:
            return PGPluginAuthorizeStatusNotDetermined;
        case kABAuthorizationStatusRestricted:
            return PGPluginAuthorizeStatusRestriction;
        case kABAuthorizationStatusDenied:
            return PGPluginAuthorizeStatusDenied;
        default:
            break;
    }
    return PGPluginAuthorizeStatusAuthorized;
}

@end

@implementation CDVAddressBookAccessError

@synthesize errorCode;

- (CDVAddressBookAccessError*)initWithCode:(CDVContactError)code
{
    self = [super init];
    if (self) {
        self.errorCode = code;
    }
    return self;
}

@end

@implementation CDVAddressBookHelper

/**
 * NOTE: workerBlock is responsible for releasing the addressBook that is passed to it
 */
- (void)createAddressBook:(CDVAddressBookWorkerBlock)workerBlock
{
    // TODO: this probably should be reworked - seems like the workerBlock can just create and release its own AddressBook,
    // and also this important warning from (http://developer.apple.com/library/ios/#documentation/ContactData/Conceptual/AddressBookProgrammingGuideforiPhone/Chapters/BasicObjects.html):
    // "Important: Instances of ABAddressBookRef cannot be used by multiple threads. Each thread must make its own instance."
    ABAddressBookRef addressBook = NULL;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if (&ABAddressBookCreateWithOptions != NULL) {
        CFErrorRef error = nil;
        // CFIndex status = ABAddressBookGetAuthorizationStatus();
        addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        // NSLog(@"addressBook access: %lu", status);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            // callback can occur in background, address book must be accessed on thread it was created on
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (error) {
                    workerBlock(NULL, [[[CDVAddressBookAccessError alloc] initWithCode:UNKNOWN_ERROR] autorelease]);
                } else if (!granted) {
                    workerBlock(NULL, [[[CDVAddressBookAccessError alloc] initWithCode:PERMISSION_DENIED_ERROR] autorelease]);
                } else {
                    // access granted
                    workerBlock(addressBook, [[[CDVAddressBookAccessError alloc] initWithCode:UNKNOWN_ERROR] autorelease]);
                }
            });
        });
    } else
#endif
    {
        // iOS 4 or 5 no checks needed
        addressBook = ABAddressBookCreate();
        workerBlock(addressBook, NULL);
    }
}

@end
