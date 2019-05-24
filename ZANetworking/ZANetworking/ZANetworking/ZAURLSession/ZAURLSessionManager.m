//
//  ZAURLSessionManager.m
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionManager.h"

#pragma mark - Queue Helper

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
        dispatch_sync(url_session_manager_creation_queue(), block);
    } else {
        block();
    }
}

#pragma mark -

@interface ZAURLSessionManager ()
@property (readonly, nonatomic) NSURLSession *session;
@property (readonly, nonatomic) dispatch_queue_t rootQueue;
@property (readonly, nonatomic) NSOperationQueue *sessionDelegateQueue;
@property (readonly, nonatomic) NSMutableDictionary *mutableTaskIdentifierKeyedByRequestIdentifier;
@property (readonly, nonatomic) NSMutableDictionary *mutableTaskInfoKeyedByTaskIdentifier;
@end

#pragma mark -

@implementation ZAURLSessionManager

#pragma mark - Lifecycles

+ (instancetype)sharedManager
{
    static ZAURLSessionManager *urlSessionManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urlSessionManager = [[ZAURLSessionManager new] init];
    });
    
    return urlSessionManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _rootQueue = dispatch_queue_create("com.za.zanetworking.session.manager.rootqueue", DISPATCH_QUEUE_SERIAL);
        _sessionDelegateQueue = [[NSOperationQueue alloc] init];
        _sessionDelegateQueue.maxConcurrentOperationCount = 1;
        _mutableTaskInfoKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
        _mutableTaskIdentifierKeyedByRequestIdentifier = [[NSMutableDictionary alloc] init];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self delegateQueue:_sessionDelegateQueue];
    }
    
    return self;
}

- (void)dealloc
{
    
}

#pragma mark - Interface methods

- (NSString *)downloadTaskFromURLString:(NSString *)urlString headers:(NSDictionary *)header priority:(ZADownloadPriority)priority {
    __block NSURLSessionDownloadTask *downloadTask = nil;
    __weak typeof(self) weakSelf = self;
    url_session_manager_create_task_safely(^{
        NSURLRequest *request = [weakSelf buildURLRequestFromURLString:urlString headers:header];
        // TODO: check if don't have request create new downloadtask
        downloadTask = [weakSelf.session downloadTaskWithRequest:request];
    });
    
    NSString *requestIdentifier = [[NSUUID UUID] UUIDString];
    if (downloadTask) {
        // init task info
        self.mutableTaskInfoKeyedByTaskIdentifier[@(downloadTask.taskIdentifier)] = downloadTask;
        self.mutableTaskIdentifierKeyedByRequestIdentifier[requestIdentifier] = [NSNumber numberWithInteger:downloadTask.taskIdentifier];
        [downloadTask resume];
    } else {
        // TODO: add current request to taskInfo
    }
    
    return NULL;
}

- (void)resumeDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

- (void)pauseDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

- (void)cancelDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

#pragma mark - Build URLRequest Helper

- (nullable NSURLRequest *)buildURLRequestFromURLString:(nonnull NSString *)urlString headers:(nullable NSDictionary *)header {
    if (!urlString) { return NULL; }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) { return NULL; }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = [self getTimeoutInterval];
    if (header) {
        request.allHTTPHeaderFields = header;
    }
    
    return request;
}

- (NSTimeInterval)getTimeoutInterval {
    return 1.0;
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
