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

#import <Foundation/Foundation.h>
#import <AddressBook/ABAddressBook.h>
#import "PGPlugin.h"
#import "PGMethod.h"
#import "PGContact.h"

@interface PGContacts : PGPlugin
{
}
/*
 * search - searches for contacts.  Only person records are currently supported.
 *
 * arguments:
 *  1: successcallback - this is the javascript function that will be called with the array of found contacts
 *  2:  errorCallback - optional javascript function to be called in the event of an error with an error code.
 * options:  dictionary containing ContactFields and ContactFindOptions
 *	fields - ContactFields array
 *  findOptions - ContactFindOptions object as dictionary
 *
 */
- (void)search:(PGMethod*)command;

/*
 * save - saves a new contact or updates and existing contact
 *
 * arguments:
 *  1: success callback - this is the javascript function that will be called with the JSON representation of the saved contact
 *		search calls a fixed navigator.service.contacts._findCallback which then calls the success callback stored before making the call into obj-c
 */
- (void)save:(PGMethod*)command;

/*
 * remove - removes a contact from the address book
 *
 * arguments:
 *  1:  1: successcallback - this is the javascript function that will be called with a (now) empty contact object
 *
 * options:  dictionary containing Contact object to remove
 *	contact - Contact object as dictionary
 */
- (void)remove:(PGMethod*)command;

- (void)getAddressBook:(PGMethod*)command;

- (void) dealloc;

@end
@interface CDVAddressBookAccessError : NSObject
{}
@property (assign) CDVContactError errorCode;
- (CDVAddressBookAccessError*)initWithCode:(CDVContactError)code;
@end
typedef void (^ CDVAddressBookWorkerBlock)(
ABAddressBookRef         addressBook,
CDVAddressBookAccessError* error
);


@interface CDVAddressBookHelper : NSObject
{}

- (void)createAddressBook:(CDVAddressBookWorkerBlock)workerBlock;
@end
