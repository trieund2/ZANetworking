//
//  ZAURLSessionManager.m
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZASessionManager.h"
#import "ZATaskInfo.h"

@interface ZASessionManager ()
@property (readonly, nonatomic) NSURLSession *session;
@property (readonly, nonatomic) dispatch_queue_t root_queue;
@property (readonly, nonatomic) NSOperationQueue *sessionDelegateQueue;
@property (readonly, nonatomic) NSMutableDictionary<NSNumber*, ZATaskInfo*> *taskIdToTaskInfo;
@property (readonly, nonatomic) NSMutableDictionary<NSURLRequest*, NSNumber*> *urlRequestToTaskId;
@property (readonly, nonatomic) NSMutableDictionary<NSString*, ZATaskInfo*> *downloadMonitorIdToTaskInfo;
@end

#pragma mark -

@implementation ZASessionManager

#pragma mark - Lifecycles

+ (instancetype)sharedManager
{
    static ZASessionManager *urlSessionManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urlSessionManager = [[ZASessionManager new] init];
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
        _urlRequestToTaskId = [[NSMutableDictionary alloc] init];
        _taskIdToTaskInfo = [[NSMutableDictionary alloc] init];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:_sessionDelegateQueue];
    }
    
    return self;
}

#pragma mark - Interface methods

- (NSURLRequest *)downloadTaskFromURLString:(NSString *)urlString
                                    headers:(nullable NSDictionary<NSString *, NSString *> *)header
                                   priority:(ZADownloadPriority)priority
                              progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                           destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                            completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    __block NSURLRequest *request = nil;
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(self.root_queue, ^{
        request = [weakSelf buildURLRequestFromURLString:urlString headers:header];
        if (nil == request) {
            return;
        }
        
        ZADownloadMonitor *downloadMonitor = [[ZADownloadMonitor alloc] initWithProgressBlock:progressBlock
                                                                             destinationBlock:destinationBlock
                                                                              completionBlock:completionBlock];
        NSURLSessionDownloadTask *downloadTask = nil;
        ZATaskInfo* taskInfo = [weakSelf taskInfoForURLRequest:request];
        if (taskInfo) {
            downloadTask = taskInfo.downloadTask;
        } else {
            downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            taskInfo = [[ZATaskInfo alloc] initWithDownloadTask:downloadTask taskRequest:downloadMonitor];
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]] = taskInfo;
            [downloadTask resume];
            [taskInfo changeStatusTo:(ZASessionTaskStatusRunning)];
        }
        
        taskInfo.requestToDownloadMonitorDownloading[request] = downloadMonitor;
        weakSelf.urlRequestToTaskId[request] = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    });
    
    return request;
}

- (void)resumeDownloadTaskByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:request];
        ZADownloadMonitor *resumeDownloadMonitor = taskInfo.requestToDownloadMonitorPause[request];
        
        if (resumeDownloadMonitor) {
            [taskInfo.requestToDownloadMonitorPause removeObjectForKey:request];
            NSURLSessionDownloadTask *resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.receivedData];
            ZATaskInfo *resumeTaskInfo = [[ZATaskInfo alloc] initWithDownloadTask:resumeTask taskRequest:resumeDownloadMonitor];
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier]] = resumeTaskInfo;
            weakSelf.urlRequestToTaskId[request] = [NSNumber numberWithUnsignedInteger:resumeTask.taskIdentifier];
            [resumeTask resume];
            [resumeTaskInfo canChangeToStatus:(ZASessionTaskStatusRunning)];
        }
        
        if (taskInfo.requestToDownloadMonitorPause.count == 0
            && taskInfo.requestToDownloadMonitorDownloading.count == 0) {
            [taskInfo.downloadTask cancel];
            [weakSelf removeDownloadTaskByRequest:request];
        }
    });
}

- (void)pauseDownloadTaskByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:request];
        ZADownloadMonitor *pauseDownloadMonitor = taskInfo.requestToDownloadMonitorDownloading[request];
        if (pauseDownloadMonitor) {
            [taskInfo.requestToDownloadMonitorDownloading removeObjectForKey:request];
            taskInfo.requestToDownloadMonitorPause[request] = pauseDownloadMonitor;
            
            if (taskInfo.requestToDownloadMonitorDownloading.count == 0) {
                [taskInfo.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    if (resumeData) {
                        taskInfo.receivedData = (NSMutableData *)resumeData;
                    }
                }];
            }
        }
    });
}

- (void)cancelDownloadTaskByRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:request];
        ZADownloadMonitor *cancelRequest = taskInfo.requestToDownloadMonitorPause[request];
        
        if (cancelRequest) {
            [taskInfo.requestToDownloadMonitorDownloading removeObjectForKey:request];
            
            if (taskInfo.requestToDownloadMonitorPause.count == 0
                && taskInfo.requestToDownloadMonitorDownloading.count == 0) {
                [taskInfo.downloadTask cancel];
                [weakSelf removeDownloadTaskByRequest:request];
            }
        }
    });
}

#pragma mark - DownloadTask Helper

- (nullable ZATaskInfo *)taskInfoForURLRequest:(NSURLRequest *)request {
    NSNumber *taskId = [self.urlRequestToTaskId objectForKey:request];
    if (taskId) {
        return [self.taskIdToTaskInfo objectForKey:taskId];
    }
    return NULL;
}

- (void)removeDownloadTaskByRequest:(NSURLRequest *)request {
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
    return 500.0;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        if (taskInfo) {
            for (ZADownloadMonitor *downloadMonitor in taskInfo.requestToDownloadMonitorDownloading.allValues) {
                if (downloadMonitor.completionBlock) {
                    downloadMonitor.completionBlock(downloadTask.response, downloadTask.error);
                }
                
                if (downloadMonitor.destinationBlock) {
                    NSError *fileManagerError = nil;
                    NSURL *downloadFile = downloadMonitor.destinationBlock(location);
                    [NSFileManager.defaultManager copyItemAtURL:location
                                                          toURL:downloadFile
                                                          error:&fileManagerError];
                }
            }
            
            if (taskInfo.requestToDownloadMonitorDownloading.count == 0 && taskInfo.requestToDownloadMonitorPause.count == 0) {
                
            }
        }
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
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        if (taskInfo) {
            for (ZADownloadMonitor *downloadMonitor in taskInfo.requestToDownloadMonitorDownloading.allValues) {
                if (downloadMonitor.progressBlock) {
                    downloadMonitor.progressBlock(progress);
                }
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
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        if (taskInfo) {
            for (ZADownloadMonitor *downloadMonitor in taskInfo.requestToDownloadMonitorDownloading.allValues) {
                if (downloadMonitor.progressBlock) {
                    downloadMonitor.progressBlock(progress);
                }
            }
        }
    });
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        if (error) {
            ZATaskInfo *taskInfo = [weakSelf taskInfoForURLRequest:task.originalRequest];
            for (ZADownloadMonitor *downloadMonitor in taskInfo.requestToDownloadMonitorDownloading.allValues) {
                downloadMonitor.completionBlock(task.response, error);
            }
            
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (resumeData) {
                taskInfo.receivedData = (NSMutableData *)resumeData;
            }
        }
    });
}

@end
