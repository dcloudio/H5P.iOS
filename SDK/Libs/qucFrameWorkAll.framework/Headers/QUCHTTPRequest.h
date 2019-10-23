//
//  QUCHTTPRequest.h
//
//  Created by Sam Vermette on 20.09.11.
//  Copyright 2011 samvermette.com. All rights reserved.
//
//  https://github.com/samvermette/SVHTTPRequest
//

#import <Foundation/Foundation.h>
#import <AvailabilityMacros.h>
typedef void (^QUCHTTPRequestCompletionHandler)(id response, NSHTTPURLResponse *urlResponse,NSDictionary *responseCookie,NSError *error);
typedef void (^QUCHTTPRequestProcessHandler)(float progress);

enum {
	QUCHTTPRequestMethodGET = 0,
    QUCHTTPRequestMethodPOST,
    QUCHTTPRequestMethodPUT,
    QUCHTTPRequestMethodDELETE,
    QUCHTTPRequestMethodHEAD
};

typedef NSUInteger QUCHTTPRequestMethod;

@interface QUCHTTPRequest : NSOperation

+ (QUCHTTPRequest*)GET:(NSString*)address parameters:(NSDictionary*)parameters cookie:(NSString *) cookie completion:(QUCHTTPRequestCompletionHandler)completionBlock;
+ (QUCHTTPRequest*)GET:(NSString*)address parameters:(NSDictionary*)parameters cookie:(NSString *) cookie saveToPath:(NSString*)savePath progress:(QUCHTTPRequestProcessHandler)progressBlock completion:(QUCHTTPRequestCompletionHandler)completionBlock;

+ (QUCHTTPRequest*)POST:(NSString*)address parameters:(NSObject*)parameters cookie:(NSString *) cookie completion:(QUCHTTPRequestCompletionHandler)completionBlock;
+ (QUCHTTPRequest*)POST:(NSString *)address parameters:(NSObject *)parameters cookie:(NSString *) cookie progress:(QUCHTTPRequestProcessHandler)progressBlock completion:(QUCHTTPRequestCompletionHandler)completionBlock;
+ (QUCHTTPRequest*)PUT:(NSString*)address parameters:(NSObject*)parameters cookie:(NSString *) cookie completion:(QUCHTTPRequestCompletionHandler)completionBlock;

+ (QUCHTTPRequest*)DELETE:(NSString*)address parameters:(NSDictionary*)parameters cookie:(NSString *) cookie completion:(QUCHTTPRequestCompletionHandler)completionBlock;
+ (QUCHTTPRequest*)HEAD:(NSString*)address parameters:(NSDictionary*)parameters cookie:(NSString *) cookie completion:(QUCHTTPRequestCompletionHandler)completionBlock;

+ (QUCHTTPRequest*)RequestWithGetOrPost:(QUCHTTPRequestMethod)method Address:(NSString *)address parameters:(NSDictionary *)parameters cookie:(NSString *)cookie saveToPath:(NSString *)savePath progress:(QUCHTTPRequestProcessHandler)progressBlock completion:(QUCHTTPRequestCompletionHandler)completionBlock;

- (QUCHTTPRequest*)initWithAddress:(NSString*)urlString
                            method:(QUCHTTPRequestMethod)method
                        parameters:(NSObject*)parameters
                            cookie:(NSString *)cookie
                        completion:(QUCHTTPRequestCompletionHandler)completionBlock;

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

+ (void)setDefaultTimeoutInterval:(NSTimeInterval)interval;
+ (void)setDefaultUserAgent:(NSString*)userAgent;

@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, readwrite) BOOL sendParametersAsJSON;
@property (nonatomic, readwrite) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, readwrite) NSUInteger timeoutInterval;

@end


// the following methods are only to be accessed from QUCHTTPRequest.m and QUCHTTPClient.m

@protocol QUCHTTPRequestPrivateMethods <NSObject>

@property (nonatomic, strong) NSString *requestPath;

- (QUCHTTPRequest*)initWithAddress:(NSString*)urlString
                            method:(QUCHTTPRequestMethod)method
                        parameters:(NSObject*)parameters
                            cookie:(NSString *)cookie
                        saveToPath:(NSString*)savePath
                          progress:(QUCHTTPRequestProcessHandler)progressBlock
                        completion:(QUCHTTPRequestCompletionHandler)completionBlock;


- (void)signRequestWithUsername:(NSString*)username password:(NSString*)password;

@end