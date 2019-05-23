//
//  ZAURLSessionManager.m
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionManager.h"

#pragma mark - Helper

static dispatch_queue_t url_session_manager_creation_queue() {
    static dispatch_queue_t urlSessionManagerCreationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urlSessionManagerCreationQueue = dispatch_queue_create("com.za.zanetworking.session.manager.create", DISPATCH_QUEUE_SERIAL);
    });
    
    return urlSessionManagerCreationQueue;
}

static void url_session_manager_create_task_safely(dispatch_block_t _Nonnull block) {
    if (block) {
        dispatch_async(url_session_manager_creation_queue(), block);
    } else {
        block();
    }
}

#pragma mark -

@interface ZAURLSessionManager ()
@property (readwrite, nonatomic) NSURLSession *session;
@property (readwrite, nonatomic) NSURLSessionConfiguration *sessionConfiguration;
@property (readonly, nonatomic) NSMutableDictionary *mutableTaskIdentifierKeyedByRequestIdentifier;
@property (readonly, nonatomic) NSMutableDictionary *mutableTaskInfoKeyedByTaskIdentifier;
@end

#pragma mark -

@implementation ZAURLSessionManager

#pragma mark - Lifecycles

+ (instancetype)sharedManager {
    static ZAURLSessionManager *urlSessionManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        urlSessionManager = [[ZAURLSessionManager new] init];
    });
    
    return urlSessionManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (!self.sessionConfiguration) {
            self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        
        _mutableTaskInfoKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
        _mutableTaskIdentifierKeyedByRequestIdentifier = [[NSMutableDictionary alloc] init];
        _session = [NSURLSession sharedSession];
    }
    
    return self;
}

#pragma mark - Interface methods

- (NSString *)downloadTaskFromURLString:(NSString *)urlString headers:(NSDictionary *)header priority:(ZADownloadPriority)priority {
    __block NSURLSessionDownloadTask *downloadTask = nil;
    url_session_manager_create_task_safely(^{
       
    });
    
    return NULL;
}

- (void)resumeDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

- (void)pauseDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

- (void)cancelDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

#pragma mark - Helper methods

- (nullable NSURLRequest *)buildRequestFromURLString:(NSString *)urlString headers:(NSDictionary *)header {
    return NULL;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

@end
