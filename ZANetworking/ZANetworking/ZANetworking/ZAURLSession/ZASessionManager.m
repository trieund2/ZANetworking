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
        NSURLSessionDownloadTask *downloadTask = nil;
        ZATaskInfo* taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:request];
        if (taskInfo) {
            downloadTask = taskInfo.downloadTask;
        } else {
            downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            taskInfo = [[ZATaskInfo alloc] initWithDownloadTask:downloadTask taskRequest:downloadMonitor];
            weakSelf.downloadMonitorIdToTaskInfo[downloadMonitor.identifier] = taskInfo;
            [downloadTask resume];
            [taskInfo changeStatusTo:(ZASessionTaskStatusRunning)];
        }
        
        taskInfo.monitorIdToDownloadMonitorDownloading[downloadMonitor.identifier] = downloadMonitor;
        weakSelf.urlRequestToTaskInfo[request] = taskInfo;
    });
    
    return downloadMonitor.identifier;
}

- (void)resumeDownloadTaskByDownloadMonitorId:(NSString *)monitorId {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.downloadMonitorIdToTaskInfo objectForKey:monitorId];
        ZADownloadMonitor *resumeDownloadMonitor = taskInfo.monitorIdToDownloadMonitorPause[monitorId];
        
        if (resumeDownloadMonitor) {
            [taskInfo.monitorIdToDownloadMonitorPause removeObjectForKey:monitorId];
            NSURLSessionDownloadTask *resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.receivedData];
            ZATaskInfo *resumeTaskInfo = [[ZATaskInfo alloc] initWithDownloadTask:resumeTask taskRequest:resumeDownloadMonitor];
            weakSelf.urlRequestToTaskInfo[monitorId] = resumeTaskInfo;
            [resumeTask resume];
            [resumeTaskInfo canChangeToStatus:(ZASessionTaskStatusRunning)];
        }
        
        if (taskInfo.monitorIdToDownloadMonitorPause.count == 0
            && taskInfo.monitorIdToDownloadMonitorDownloading.count == 0) {
            [taskInfo.downloadTask cancel];

        }
    });
}

- (void)pauseDownloadTaskByDownloadMonitorId:(NSString *)monitorId {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.downloadMonitorIdToTaskInfo objectForKey:monitorId];
        ZADownloadMonitor *pauseDownloadMonitor = taskInfo.monitorIdToDownloadMonitorDownloading[monitorId];
        if (pauseDownloadMonitor) {
            [taskInfo.monitorIdToDownloadMonitorDownloading removeObjectForKey:monitorId];
            taskInfo.monitorIdToDownloadMonitorPause[monitorId] = pauseDownloadMonitor;
            
            if (taskInfo.monitorIdToDownloadMonitorDownloading.count == 0) {
                [taskInfo.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    if (resumeData) {
                        taskInfo.receivedData = (NSMutableData *)resumeData;
                    }
                }];
            }
        }
    });
}

- (void)cancelDownloadTaskByMonitorId:(NSString *)monitorId {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.downloadMonitorIdToTaskInfo objectForKey:monitorId];
        ZADownloadMonitor *cancelRequest = taskInfo.monitorIdToDownloadMonitorPause[monitorId];
        
        if (cancelRequest) {
            [taskInfo.monitorIdToDownloadMonitorDownloading removeObjectForKey:monitorId];
            
            if (taskInfo.monitorIdToDownloadMonitorPause.count == 0
                && taskInfo.monitorIdToDownloadMonitorDownloading.count == 0) {
                [taskInfo.downloadTask cancel];
                
            }
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
        ZATaskInfo *taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:downloadTask.originalRequest];
        if (taskInfo) {
            for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
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
            
            if (taskInfo.monitorIdToDownloadMonitorDownloading.count == 0 && taskInfo.monitorIdToDownloadMonitorPause.count == 0) {
                
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
        ZATaskInfo *taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:downloadTask.originalRequest];
        if (taskInfo) {
            for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
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
        ZATaskInfo *taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:downloadTask.originalRequest];
        if (taskInfo) {
            for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
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
            ZATaskInfo *taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:task.originalRequest];
            for (ZADownloadMonitor *downloadMonitor in taskInfo.monitorIdToDownloadMonitorDownloading.allValues) {
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
