//
//  MPRequest.h
//  MiPassportDemo
//
//  Created by 李 业 on 13-7-12.
//  Copyright (c) 2013年 李 业. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MPRequestDelegate;

@interface MPRequest : NSObject{
    NSURLConnection *_connection;
    NSMutableData *_responseData;
}

@property(nonatomic,assign) id<MPRequestDelegate> delegate;

/**
 * The URL which will be contacted to execute the request.
 */
@property(nonatomic, strong) NSString *url;

/**
 * The API method which will be called.
 */
@property(nonatomic, strong) NSString *httpMethod;

/**
 * The dictionary of parameters to pass to the method.
 *
 * These values in the dictionary will be converted to strings using the
 * standard Objective-C object-to-string conversion facilities.
 */
@property(nonatomic,strong) NSMutableDictionary* params;

/**
 * The encrypt method and key which will be used to generate a sign.
 */
@property(nonatomic, strong) NSString *encryptAlgorithm;
@property(nonatomic, strong) NSString *encryptKey;

- (id)initWithWithParams:(NSMutableDictionary *) params
              httpMethod:(NSString *) httpMethod
                delegate:(id<MPRequestDelegate>) delegate
              requestURL:(NSString *) url
        encryptAlgorithm:(NSString *)algorithm
              encryptKey:(NSString *)key;

- (void)connect;

+ (MPRequest *)requestWithParams:(NSMutableDictionary *) params
                      httpMethod:(NSString *) httpMethod
                        delegate:(id<MPRequestDelegate>) delegate
                      requestURL:(NSString *) url
                encryptAlgorithm:(NSString *)algorithm
                      encryptKey:(NSString *)key;

+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod;
+ (NSString *)getParamValueFromUrl:(NSString*)url paramName:(NSString *)paramName;

@end


////////////////////////////////////////////////////////////////////////////////

/*
 *Your application should implement this delegate
 */
@protocol MPRequestDelegate <NSObject>

@optional

/**
 * Called just before the request is sent to the server.
 */
- (void)requestLoading:(MPRequest *)request;

/**
 * Called when the server responds and begins to send back data.
 */
- (void)request:(MPRequest *)request didReceiveResponse:(NSURLResponse *)response;

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(MPRequest *)request didFailWithError:(NSError *)error;

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number,
 * depending on thee format of the API response.
 */
- (void)request:(MPRequest *)request didLoad:(id)result;

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(MPRequest *)request didLoadRawResponse:(NSData *)data;

@end