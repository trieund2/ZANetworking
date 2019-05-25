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

@interface ZAURLSessionManager ()
@property (readonly, nonatomic) NSURLSession *session;
@property (readonly, nonatomic) dispatch_queue_t root_queue;
@property (readonly, nonatomic) NSOperationQueue *sessionDelegateQueue;
@property (readonly, nonatomic) NSMutableDictionary<NSNumber*, ZAURLSessionTaskInfo*> *taskIdToTaskInfo;
@property (readonly, nonatomic) NSMutableDictionary<NSURLRequest*, NSNumber*> *urlRequestToTaskId;
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
        _root_queue = dispatch_queue_create("com.za.zanetworking.sessionmanager.rootqueue", DISPATCH_QUEUE_SERIAL);
        _sessionDelegateQueue = [[NSOperationQueue alloc] init];
        _sessionDelegateQueue.maxConcurrentOperationCount = 1;
        _taskIdToTaskInfo = [[NSMutableDictionary alloc] init];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self delegateQueue:_sessionDelegateQueue];
    }
    
    return self;
}

#pragma mark - Interface methods

- (NSURLRequest *)downloadTaskFromURLString:(NSString *)urlString
                                    headers:(NSDictionary *)header
                                   priority:(ZADownloadPriority)priority
                              progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                           destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                            completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    __block NSURLRequest *request = nil;
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(self.root_queue, ^{
        ZAURLSessionTaskRequest *taskRequest = [[ZAURLSessionTaskRequest alloc] initWithProgressBlock:progressBlock
                                                                                     destinationBlock:destinationBlock
                                                                                      completionBlock:completionBlock];
        request = [weakSelf buildURLRequestFromURLString:urlString headers:header];
        NSURLSessionDownloadTask *downloadTask = nil;
        ZAURLSessionTaskInfo* taskInfo = [weakSelf taskInfoForURLRequest:request];
        if (taskInfo) {
            downloadTask = taskInfo.downloadTask;
        } else {
            downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            ZAURLSessionTaskInfo *taskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:downloadTask taskRequest:taskRequest];
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]] = taskInfo;
            [downloadTask resume];
            [taskInfo canChangeToStatus:(ZAURLSessionTaskStatusRunning)];
        }
        
        weakSelf.urlRequestToTaskId[request] = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    });
    
    return request;
}

- (void)resumeDownloadTaskByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZAURLSessionTaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:request];
        ZAURLSessionTaskRequest *resumeRequest = taskInfo.requestToTaskRequestPause[request];
        
        if (resumeRequest) {
            [taskInfo.requestToTaskRequestPause removeObjectForKey:request];
            NSURLSessionDownloadTask *resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.receivedData];
            ZAURLSessionTaskInfo *resumeTaskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:resumeTask taskRequest:resumeRequest];
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier]] = resumeTaskInfo;
            weakSelf.urlRequestToTaskId[request] = [NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier];
            [resumeTask resume];
            [resumeTaskInfo canChangeToStatus:(ZAURLSessionTaskStatusRunning)];
        }
        
        if (taskInfo.requestToTaskRequestPause.count == 0
            && taskInfo.requestIdToTaskRequestDownloading.count == 0) {
            [weakSelf removeTaskInfoByRequest:request];
        }
    });
}

- (void)pauseDownloadTaskByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZAURLSessionTaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:request];
        ZAURLSessionTaskRequest *pauseRequest = taskInfo.requestToTaskRequestPause[request];
        if (pauseRequest) {
            [taskInfo.requestToTaskRequestPause removeObjectForKey:request];
            NSURLSessionDownloadTask *resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.receivedData];
            ZAURLSessionTaskInfo *taskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:resumeTask taskRequest:pauseRequest];
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier]] = taskInfo;
            weakSelf.urlRequestToTaskId[request] = [NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier];
            [resumeTask resume];
            [taskInfo canChangeToStatus:(ZAURLSessionTaskStatusRunning)];
        }
        
        if (taskInfo.requestToTaskRequestPause.count == 0
            && taskInfo.requestIdToTaskRequestDownloading.count == 0) {
            [weakSelf removeTaskInfoByRequest:request];
        }
    });
}

- (void)cancelDownloadTaskByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZAURLSessionTaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:request];
        ZAURLSessionTaskRequest *pauseRequest = taskInfo.requestToTaskRequestPause[request];
        if (pauseRequest) {
            [taskInfo.requestToTaskRequestPause removeObjectForKey:request];
            NSURLSessionDownloadTask *resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.receivedData];
            ZAURLSessionTaskInfo *taskInfo = [[ZAURLSessionTaskInfo alloc] initWithDownloadTask:resumeTask taskRequest:pauseRequest];
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier]] = taskInfo;
            weakSelf.urlRequestToTaskId[request] = [NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier];
            [resumeTask resume];
            [taskInfo canChangeToStatus:(ZAURLSessionTaskStatusRunning)];
        }
        
        if (taskInfo.requestToTaskRequestPause.count == 0
            && taskInfo.requestIdToTaskRequestDownloading.count == 0) {
            [weakSelf removeTaskInfoByRequest:request];
        }
    });
}

#pragma mark - Task Helper

- (nullable ZAURLSessionTaskInfo *)taskInfoForURLRequest:(NSURLRequest *)request {
    __block ZAURLSessionTaskInfo *returnTaskInfo = nil;
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(self.root_queue, ^{
        NSNumber *taskId = [weakSelf.urlRequestToTaskId objectForKey:request];
        if (taskId) {
            returnTaskInfo = [weakSelf.taskIdToTaskInfo objectForKey:taskId];
        }
    });
    
    return returnTaskInfo;
}

- (void)removeTaskInfoByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        NSNumber *taskId = [weakSelf.urlRequestToTaskId objectForKey:request];
        if (taskId) {
            [weakSelf.taskIdToTaskInfo removeObjectForKey:taskId];
        }
        [weakSelf.urlRequestToTaskId removeObjectForKey:request];
    });
}

#pragma mark - Build URLRequest Helper

- (nullable NSURLRequest *)buildURLRequestFromURLString:(nonnull NSString *)urlString
                                                headers:(nullable NSDictionary<NSString *, NSString *> *)header {
    if (nil == urlString) { return NULL; }
    NSURL *url = [NSURL URLWithString:urlString];
    if (nil == url) { return NULL; }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = [self getTimeoutInterval];
    
    if (header) {
        for (NSString* key in header.allKeys) {
            NSString *value = [header objectForKey:key];
            if (value) {
                [request setValue:value forHTTPHeaderField:key];
            }
        }
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
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    __weak typeof(self) weakSelf = self;
    
    NSProgress *progress = [[NSProgress alloc] init];
    progress.totalUnitCount = totalBytesExpectedToWrite;
    progress.completedUnitCount = totalBytesWritten;
    
    dispatch_async(self.root_queue, ^{
        ZAURLSessionTaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        if (taskInfo) {
            for (ZAURLSessionTaskRequest *taskRequest in taskInfo.requestIdToTaskRequestDownloading.allValues) {
                taskRequest.progressBlock(progress);
            }
        }
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    __weak typeof(self) weakSelf = self;
    
    NSProgress *progress = [[NSProgress alloc] init];
    progress.totalUnitCount = expectedTotalBytes;
    progress.completedUnitCount = fileOffset;
    
    dispatch_async(self.root_queue, ^{
        ZAURLSessionTaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        if (taskInfo) {
            for (ZAURLSessionTaskRequest *taskRequest in taskInfo.requestIdToTaskRequestDownloading.allValues) {
                taskRequest.progressBlock(progress);
            }
        }
    });
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZAURLSessionTaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithUnsignedInteger:dataTask.taskIdentifier]];
        [taskInfo.receivedData appendData:data];
    });
}

@end
