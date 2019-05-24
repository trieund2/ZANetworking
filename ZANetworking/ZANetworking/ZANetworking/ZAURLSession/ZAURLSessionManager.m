//
//  ZAURLSessionManager.m
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionManager.h"
#import "ZAURLSessionTaskInfo.h"
#import "NSURL+URIEquivalence.h"

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

/// This method return Request Identifier. Use this Identifier to pause, cancel, resume task
- (NSString *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(NSDictionary *)header
                               priority:(ZADownloadPriority)priority
                          progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                       destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                        completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    
    ZAURLSessionTaskRequest *taskRequest = [[ZAURLSessionTaskRequest alloc] initWithProgressBlock:progressBlock
                                                                                 destinationBlock:destinationBlock
                                                                                  completionBlock:completionBlock];
    
    __block NSURLSessionDownloadTask *downloadTask = nil;
    __weak typeof(self) weakSelf = self;
    url_session_manager_create_task_safely(^{
        NSURLRequest *request = [weakSelf buildURLRequestFromURLString:urlString headers:header];
        downloadTask = [weakSelf downloadTaskForURLRequest:request];
        if (!downloadTask) {
            downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            ZAURLSessionTaskInfo *taskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:downloadTask taskRequest:taskRequest];
            weakSelf.mutableTaskInfoKeyedByTaskIdentifier[@(downloadTask.taskIdentifier)] = taskInfo;
            [downloadTask resume];
        }
        
        weakSelf.mutableTaskIdentifierKeyedByRequestIdentifier[taskRequest.identifier] = [NSNumber numberWithInteger:downloadTask.taskIdentifier];
    });
    
    return taskRequest.identifier;
}

- (void)resumeDownloadTaskWithIdentifier:(NSString *)identifier {
    if (!identifier) { return; }
    
    ZAURLSessionTaskInfo *taskInfo = self.mutableTaskInfoKeyedByTaskIdentifier[identifier];
    
    if (!taskInfo) { return; }
    
    if ([taskInfo canChangeToStatus:(kURLSessionTaskRunning)]) {
        return;
    }
    
    NSURLSessionDownloadTask *resumeDownloadTask = [self.session downloadTaskWithResumeData:taskInfo.receivedData];
    [self.mutableTaskIdentifierKeyedByRequestIdentifier removeObjectForKey:identifier];
    
    [taskInfo resumeDownloadTaskByIdentifier:identifier];
    
}

- (void)pauseDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

- (void)cancelDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

#pragma mark - Build URLRequest Helper

- (nullable NSURLSessionDownloadTask *)downloadTaskForURLRequest:(NSURLRequest *)request {
    
    for (id key in self.mutableTaskInfoKeyedByTaskIdentifier) {
        if ([key isKindOfClass:NSNumber.class]) {
            NSNumber *taskIdentifier = (NSNumber *)key;
            id value = [self.mutableTaskIdentifierKeyedByRequestIdentifier objectForKey:taskIdentifier];
            
            if ([value isKindOfClass:ZAURLSessionTaskInfo.class]) {
                ZAURLSessionTaskInfo *taskInfo = (ZAURLSessionTaskInfo *)value;
                if ([taskInfo.downloadTask.originalRequest.URL isEquivalent:request.URL]) {
                    return taskInfo.downloadTask;
                }
            }
        }
    }
    
    return NULL;
}

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
