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
@property (readonly, nonatomic) NSMutableDictionary<NSURLRequest*, ZATaskInfo*> *urlRequestToTaskInfo;
@property (readonly, nonatomic) NSMutableDictionary<NSString*, ZATaskInfo*> *downloadMonitorIdToTaskInfo;
@property (readonly, nonatomic) NSMutableDictionary<NSNumber*, ZATaskInfo*> *taskIdToTaskInfo;
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
        _downloadMonitorIdToTaskInfo = [[NSMutableDictionary alloc] init];
        _taskIdToTaskInfo = [[NSMutableDictionary alloc] init];
        _urlRequestToTaskInfo = [[NSMutableDictionary alloc] init];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:_sessionDelegateQueue];
    }
    
    return self;
}

#pragma mark - Interface methods

- (NSString *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(nullable NSDictionary<NSString *, NSString *> *)header
                               priority:(ZADownloadPriority)priority
                          progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                       destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                        completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    __block ZADownloadMonitor *downloadMonitor;
    __weak typeof(self) weakSelf = self;
    
    dispatch_sync(self.root_queue, ^{
        NSURLRequest *request = [weakSelf buildURLRequestFromURLString:urlString headers:header];
        if (nil == request) { return; }
        
        downloadMonitor = [[ZADownloadMonitor alloc] initWithProgressBlock:progressBlock
                                                          destinationBlock:destinationBlock
                                                           completionBlock:completionBlock];
        ZATaskInfo* taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:request];
        
        if (nil == taskInfo) {
            NSURLSessionDownloadTask *downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            taskInfo = [[ZATaskInfo alloc] initWithDownloadTask:downloadTask];
            [downloadTask resume];
            weakSelf.downloadMonitorIdToTaskInfo[downloadMonitor.identifier] = taskInfo;
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithInteger:downloadTask.taskIdentifier]] = taskInfo;
            weakSelf.urlRequestToTaskInfo[request] = taskInfo;
            [taskInfo changeStatusTo:(ZASessionTaskStatusRunning)];
        }
        
        weakSelf.downloadMonitorIdToTaskInfo[downloadMonitor.identifier] = taskInfo;
        taskInfo.monitorIdToDownloadMonitorDownloading[downloadMonitor.identifier] = downloadMonitor;
        
        if (taskInfo.status == ZASessionTaskStatusPaused || taskInfo.status == ZASessionTaskStatusFailed) {
            [self resumeDownloadTaskByDownloadMonitorId:downloadMonitor.identifier];
        }
    });
    
    return downloadMonitor.identifier;
}

- (void)pauseDownloadTaskByDownloadMonitorId:(NSString *)monitorId {
    if (nil == monitorId) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.downloadMonitorIdToTaskInfo objectForKey:monitorId];
        ZADownloadMonitor *pauseDownloadMonitor = taskInfo.monitorIdToDownloadMonitorDownloading[monitorId];
        
        if (pauseDownloadMonitor) {
            [taskInfo.monitorIdToDownloadMonitorDownloading removeObjectForKey:monitorId];
            taskInfo.monitorIdToDownloadMonitorPause[monitorId] = pauseDownloadMonitor;
            
            if (taskInfo.monitorIdToDownloadMonitorDownloading.count == 0) {
                [taskInfo changeStatusTo:(ZASessionTaskStatusPaused)];
                [taskInfo.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    if (resumeData) {
                        taskInfo.resumeData = (NSMutableData *)resumeData;
                    }
                }];
            }
        }
    });
}

- (void)resumeDownloadTaskByDownloadMonitorId:(NSString *)monitorId {
    if (nil == monitorId) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.downloadMonitorIdToTaskInfo objectForKey:monitorId];
        ZADownloadMonitor *resumeDownloadMonitor = taskInfo.monitorIdToDownloadMonitorPause[monitorId];
        [taskInfo.monitorIdToDownloadMonitorPause removeObjectForKey:monitorId];
        [weakSelf.downloadMonitorIdToTaskInfo removeObjectForKey:monitorId];
        
        if (nil == resumeDownloadMonitor) {
            resumeDownloadMonitor = taskInfo.monitorIdToDownloadMonitorDownloading[monitorId];
        }
        
        if (nil == resumeDownloadMonitor) { return; }
        
        if (taskInfo.status == ZASessionTaskStatusRunning) {
            taskInfo.monitorIdToDownloadMonitorDownloading[monitorId] = resumeDownloadMonitor;
        } else if (taskInfo.status == ZASessionTaskStatusSuccessed) {
            resumeDownloadMonitor.completionBlock(taskInfo.downloadTask.response, taskInfo.downloadTask.error);
            NSURL *filePath = resumeDownloadMonitor.destinationBlock(taskInfo.completeFileLocation);
            if (filePath) {
                [NSFileManager.defaultManager copyItemAtURL:taskInfo.completeFileLocation toURL:filePath error:NULL];
            }
            
            [weakSelf.downloadMonitorIdToTaskInfo removeObjectForKey:monitorId];
            
            if (taskInfo.monitorIdToDownloadMonitorPause.count == 0) {
                [NSFileManager.defaultManager removeItemAtURL:taskInfo.completeFileLocation error:NULL];
                [weakSelf.urlRequestToTaskInfo removeObjectForKey:taskInfo.downloadTask.currentRequest];
            }
            
        } else if (taskInfo.status == ZASessionTaskStatusPaused || taskInfo.status == ZASessionTaskStatusFailed) {
            NSURLSessionDownloadTask *resumeTask;
            NSURLRequest *resumeRequest = taskInfo.downloadTask.currentRequest.copy;
            
            if (taskInfo.resumeData) {
                resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.resumeData];
            } else {
                resumeTask = [weakSelf.session downloadTaskWithRequest:resumeRequest];
            }
            
            ZATaskInfo *resumeTaskInfo = [[ZATaskInfo alloc] initWithDownloadTask:resumeTask];
            resumeTaskInfo.monitorIdToDownloadMonitorDownloading[monitorId] = resumeDownloadMonitor;
            weakSelf.urlRequestToTaskInfo[resumeRequest] = resumeTaskInfo;
            weakSelf.downloadMonitorIdToTaskInfo[monitorId] = resumeTaskInfo;
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithInteger:resumeTask.taskIdentifier]] = resumeTaskInfo;
            [resumeTask resume];
            [resumeTaskInfo canChangeToStatus:(ZASessionTaskStatusRunning)];
        }
        
        if (taskInfo.monitorIdToDownloadMonitorPause.count == 0
            && taskInfo.monitorIdToDownloadMonitorDownloading.count == 0) {
            [weakSelf.taskIdToTaskInfo removeObjectForKey:[NSNumber numberWithInteger:taskInfo.downloadTask.taskIdentifier]];
            [weakSelf.urlRequestToTaskInfo removeObjectForKey:taskInfo.downloadTask.currentRequest];
            [taskInfo.downloadTask cancel];
        }
    });
}

- (void)cancelDownloadTaskByMonitorId:(NSString *)monitorId {
    if (nil == monitorId) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.downloadMonitorIdToTaskInfo objectForKey:monitorId];
        ZADownloadMonitor *cancelRequest = taskInfo.monitorIdToDownloadMonitorPause[monitorId];
        [weakSelf.downloadMonitorIdToTaskInfo removeObjectForKey:monitorId];
        
        if (cancelRequest) {
            [taskInfo.monitorIdToDownloadMonitorPause removeObjectForKey:monitorId];
        } else {
            cancelRequest = taskInfo.monitorIdToDownloadMonitorDownloading[monitorId];
            [taskInfo.monitorIdToDownloadMonitorDownloading removeObjectForKey:monitorId];
        }
        
        if (nil == cancelRequest) {
            return;
        }
        
        if (taskInfo.monitorIdToDownloadMonitorPause.count == 0
            && taskInfo.monitorIdToDownloadMonitorDownloading.count == 0) {
            [weakSelf.taskIdToTaskInfo removeObjectForKey:[NSNumber numberWithInteger:taskInfo.downloadTask.taskIdentifier]];
            [weakSelf.urlRequestToTaskInfo removeObjectForKey:taskInfo.downloadTask.currentRequest];
            [taskInfo.downloadTask cancel];
        }
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
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
            downloadMonitor.completionBlock(downloadTask.response, downloadTask.error);
            NSURL *filePath = downloadMonitor.destinationBlock(location);
            if (filePath) {
                [NSFileManager.defaultManager copyItemAtURL:location
                                                      toURL:filePath
                                                      error:NULL];
            }
        }
        
        // When finish downloading will remove all downloadMonitorDownloading in TaskInfo
        for (NSString *monitorId in taskInfo.monitorIdToDownloadMonitorDownloading.allKeys) {
            if (monitorId) {
                [weakSelf.downloadMonitorIdToTaskInfo removeObjectForKey:monitorId];
            }
        }
        [taskInfo.monitorIdToDownloadMonitorDownloading removeAllObjects];
        
        if (taskInfo.monitorIdToDownloadMonitorPause.count == 0) {
            [NSFileManager.defaultManager removeItemAtURL:location error:NULL];
            [weakSelf.urlRequestToTaskInfo removeObjectForKey:downloadTask.currentRequest];
            [weakSelf.taskIdToTaskInfo removeObjectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        } else {
            taskInfo.completeFileLocation = location;
            taskInfo.status = ZASessionTaskStatusSuccessed;
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
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
            downloadMonitor.progressBlock(progress);
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
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
            downloadMonitor.progressBlock(progress);
        }
    });
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        if (error) {
            ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:task.taskIdentifier]];
            for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
                downloadMonitor.completionBlock(task.response, error);
            }
            
            [taskInfo changeStatusTo:(ZASessionTaskStatusFailed)];
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (resumeData) {
                taskInfo.resumeData = (NSMutableData *)resumeData;
            }
        }
    });
}

@end
