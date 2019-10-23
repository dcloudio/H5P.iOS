//
//  PGIO+Digest.m
//  libIO
//
//  Created by dcloud on 2019/6/1.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "PGIO+Digest.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>

@implementation PGFile(Digest)
- (NSString*) fileMD5HashWithPath:(CFStringRef)filePath {
    size_t chunkSizeForReadingData = 256;
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    bool handleStatus = NO;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) {
        goto done;
    }
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream){
        goto done;
    }
    
    handleStatus = (bool)CFReadStreamOpen(readStream);
    if (!handleStatus ) {
        goto done;
    }
    
    {
        CC_MD5_CTX hashObject;
        // Initialize the hash object
        CC_MD5_Init(&hashObject);
        
        // Feed the data to the hash object
        bool hasMoreData = true;
        while (hasMoreData) {
            uint8_t buffer[chunkSizeForReadingData];
            CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                      (UInt8 *)buffer,
                                                      (CFIndex)sizeof(buffer));
            if (readBytesCount == -1) break;
            if (readBytesCount == 0) {
                hasMoreData = false;
                continue;
            }
            CC_MD5_Update(&hashObject,
                          (const void *)buffer,
                          (CC_LONG)readBytesCount);
        }
        
        // Check if the read operation succeeded
        handleStatus = !hasMoreData;
        
        // Compute the hash digest
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &hashObject);
        
        // Abort if the read operation failed
        if (!handleStatus){
            goto done;
        }
        // Compute the string result
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        result = CFStringCreateWithCString(kCFAllocatorDefault,
                                           (const char *)hash,
                                           kCFStringEncodingUTF8);
    }
    
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return [(NSString*)result autorelease];
}

- (NSString*) fileSha1HashWithPath:(CFStringRef)filePath {
    size_t chunkSizeForReadingData = 256;
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    bool handleStatus = NO;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) {
        goto done;
    }
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream){
        goto done;
    }
    
    handleStatus = (bool)CFReadStreamOpen(readStream);
    if (!handleStatus ) {
        goto done;
    }
    
    {
        CC_SHA1_CTX hashObject;
        // Initialize the hash object
        CC_SHA1_Init(&hashObject);
        
        // Feed the data to the hash object
        bool hasMoreData = true;
        while (hasMoreData) {
            uint8_t buffer[chunkSizeForReadingData];
            CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                      (UInt8 *)buffer,
                                                      (CFIndex)sizeof(buffer));
            if (readBytesCount == -1) break;
            if (readBytesCount == 0) {
                hasMoreData = false;
                continue;
            }
            CC_SHA1_Update(&hashObject,
                          (const void *)buffer,
                          (CC_LONG)readBytesCount);
        }
        
        // Check if the read operation succeeded
        handleStatus = !hasMoreData;
        
        // Compute the hash digest
        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1_Final(digest, &hashObject);
        
        // Abort if the read operation failed
        if (!handleStatus){
            goto done;
        }
        // Compute the string result
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        result = CFStringCreateWithCString(kCFAllocatorDefault,
                                           (const char *)hash,
                                           kCFStringEncodingUTF8);
    }
    
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return [(NSString*)result autorelease];
}

@end
