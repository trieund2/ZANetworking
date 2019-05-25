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
#import "ProtectorObject.h"

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
@property (readonly, nonatomic) dispatch_queue_t root_queue;
@property (readonly, nonatomic) NSOperationQueue *sessionDelegateQueue;
@property (readonly, nonatomic) ProtectorObject<NSMutableDictionary<NSNumber*, ZAURLSessionTaskInfo*> *> *taskIdToTaskInfoProtector;
@property (readonly, nonatomic) ProtectorObject<NSMutableDictionary<NSString*, NSNumber*> *> *requestIdToTaskIdProtector;
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
        _root_queue = dispatch_queue_create("com.za.zanetworking.session.manager.rootqueue", DISPATCH_QUEUE_SERIAL);
        _sessionDelegateQueue = [[NSOperationQueue alloc] init];
        _sessionDelegateQueue.maxConcurrentOperationCount = 1;
        _taskIdToTaskInfoProtector = [[ProtectorObject alloc] initFromObject:[[NSMutableDictionary alloc] init]];
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
        ZAURLSessionTaskInfo* taskInfo = [weakSelf taskInfoForURLRequest:request];
        if (taskInfo) {
            [taskInfo addTaskRequest:taskRequest];
            downloadTask = taskInfo.downloadTask;
        } else {
            downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            ZAURLSessionTaskInfo *taskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:downloadTask taskRequest:taskRequest];
            [weakSelf addTaskInfo:taskInfo keyedByDownloadTaskId:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
            [downloadTask resume];
        }
        
        [weakSelf addDownloadTaskId:[NSNumber numberWithInteger:downloadTask.taskIdentifier] keyedByRequestId:taskRequest.identifier];
    });
    
    return taskRequest.identifier;
}

- (void)resumeDownloadTaskWithIdentifier:(NSString *)identifier {
    if (!identifier) { return; }
    
    __weak typeof(self) weakSelf = self;
    __block NSNumber *downloadTaskId;
    [self.requestIdToTaskIdProtector performWithBlock:^{
        downloadTaskId = [weakSelf.requestIdToTaskIdProtector.object objectForKey:identifier];
    }];
    if (!downloadTaskId) { return; }
    
    __block ZAURLSessionTaskInfo *taskInfo;
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        taskInfo = [weakSelf.taskIdToTaskInfoProtector.object objectForKey:downloadTaskId];
    }];
    if (!taskInfo) { return; }
    
    ZAURLSessionTaskRequest *resumeTaskRequest = [taskInfo taskRequestByIdentifier:identifier];
    if (!resumeTaskRequest) { return; }
    
    NSURLSessionDownloadTask *resumeDownloadTask = [self.session downloadTaskWithResumeData:taskInfo.receivedData];
    ZAURLSessionTaskInfo *resumeTaskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:resumeDownloadTask taskRequest:resumeTaskRequest];
    [self addTaskInfo:resumeTaskInfo keyedByDownloadTaskId:[NSNumber numberWithInteger:resumeDownloadTask.taskIdentifier]];
    [self addDownloadTaskId:[NSNumber numberWithInteger:resumeDownloadTask.taskIdentifier] keyedByRequestId:resumeTaskRequest.identifier];
    [resumeDownloadTask resume];
}

- (void)pauseDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

- (void)cancelDownloadTaskWithIdentifier:(NSString *)identifier {
    
}

#pragma mark - Helper

- (void)addTaskInfo:(ZAURLSessionTaskInfo *)taskInfo keyedByDownloadTaskId:(NSNumber *)downloadTaskId {
    __weak typeof(self) weakSelf = self;
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        weakSelf.taskIdToTaskInfoProtector.object[downloadTaskId] = taskInfo;
    }];
}

- (void)addDownloadTaskId:(NSNumber *)downloadTaskId keyedByRequestId:(NSString *)requestId {
    __weak typeof(self) weakSelf = self;
    [self.requestIdToTaskIdProtector performWithBlock:^{
        weakSelf.requestIdToTaskIdProtector.object[requestId] = downloadTaskId;
    }];
}

#pragma mark - Build URLRequest Helper

- (nullable ZAURLSessionTaskInfo *)taskInfoForURLRequest:(NSURLRequest *)request {
    __block ZAURLSessionTaskInfo *returnTaskInfo = nil;
    __weak typeof(self) weakSelf = self;
    
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        for (ZAURLSessionTaskInfo *taskInfo in weakSelf.taskIdToTaskInfoProtector.object.allValues) {
            if ([taskInfo.downloadTask.originalRequest.URL isEquivalent:request.URL]) {
                returnTaskInfo = taskInfo;
                break;
            }
        }
    }];
    
    return returnTaskInfo;
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
    
    __block ZAURLSessionTaskInfo *taskInfo = nil;
    __weak typeof(self) weakSelf = self;
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        taskInfo = [weakSelf.taskIdToTaskInfoProtector.object objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
    }];
    if (!taskInfo) { return; }
    [taskInfo.requestIdToTaskRequestProtector performWithBlock:^{
        for (ZAURLSessionTaskRequest *taskRequest in taskInfo.requestIdToTaskRequestProtector.object.allValues) {
            taskRequest.completionBlock(downloadTask.response, downloadTask.error);
        }
    }];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    __block ZAURLSessionTaskInfo *taskInfo = nil;
    __weak typeof(self) weakSelf = self;
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        taskInfo = [weakSelf.taskIdToTaskInfoProtector.object objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
    }];
    if (!taskInfo) { return; }
    
    NSProgress *progress = [[NSProgress alloc] init];
    progress.totalUnitCount = totalBytesExpectedToWrite;
    progress.completedUnitCount = totalBytesWritten;
    
    [taskInfo.requestIdToTaskRequestProtector performWithBlock:^{
        for (ZAURLSessionTaskRequest *taskRequest in taskInfo.requestIdToTaskRequestProtector.object.allValues) {
            taskRequest.progressBlock(progress);
        }
    }];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    __block ZAURLSessionTaskInfo *taskInfo = nil;
    __weak typeof(self) weakSelf = self;
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        taskInfo = [weakSelf.taskIdToTaskInfoProtector.object objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
    }];
    if (!taskInfo) { return; }
    
    NSProgress *progress = [[NSProgress alloc] init];
    progress.totalUnitCount = expectedTotalBytes;
    progress.completedUnitCount = fileOffset;
    
    [taskInfo.requestIdToTaskRequestProtector performWithBlock:^{
        for (ZAURLSessionTaskRequest *taskRequest in taskInfo.requestIdToTaskRequestProtector.object.allValues) {
            taskRequest.progressBlock(progress);
        }
    }];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    __block ZAURLSessionTaskInfo *taskInfo = nil;
    __weak typeof(self) weakSelf = self;
    [self.taskIdToTaskInfoProtector performWithBlock:^{
        taskInfo = [weakSelf.taskIdToTaskInfoProtector.object objectForKey:[NSNumber numberWithInteger:dataTask.taskIdentifier]];
    }];
    if (!taskInfo) { return; }
    
    [taskInfo.receivedData appendData:data];
}

@end
