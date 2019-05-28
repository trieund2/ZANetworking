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
@property (readonly, nonatomic) NSMutableDictionary<NSURLRequest*, ZATaskInfo*> *urlRequestToTaskInfo;
@property (readonly, nonatomic) NSMutableDictionary<NSString*, ZATaskInfo*> *callbackIdToTaskInfo;
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
        _callbackIdToTaskInfo = [[NSMutableDictionary alloc] init];
        _taskIdToTaskInfo = [[NSMutableDictionary alloc] init];
        _urlRequestToTaskInfo = [[NSMutableDictionary alloc] init];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:nil];
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
    
    __block ZADownloadCallback *callBack = [[ZADownloadCallback alloc] initWithProgressBlock:progressBlock
                                                                            destinationBlock:destinationBlock
                                                                             completionBlock:completionBlock];
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        NSURLRequest *request = [weakSelf buildURLRequestFromURLString:urlString headers:header];
        if (nil == request) { return; }
        
        ZATaskInfo* taskInfo = [weakSelf.urlRequestToTaskInfo objectForKey:request];
        
        if (nil == taskInfo) {
            NSURLSessionDownloadTask *downloadTask = [weakSelf.session downloadTaskWithRequest:request];
            [downloadTask resume];
            taskInfo = [[ZATaskInfo alloc] initWithDownloadTask:downloadTask originalRequest:request];
            [taskInfo changeStatusTo:(ZASessionTaskStatusRunning)];
            weakSelf.urlRequestToTaskInfo[request] = taskInfo;
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithInteger:downloadTask.taskIdentifier]] = taskInfo;
        }
        
        weakSelf.callbackIdToTaskInfo[callBack.identifier] = taskInfo;
        
        if (taskInfo.status == ZASessionTaskStatusPaused || taskInfo.status == ZASessionTaskStatusFailed) {
            taskInfo.callBackIdToCallBackPause[callBack.identifier] = callBack;
            [self resumeDownloadTaskByIdentifier:callBack.identifier];
        } else {
            taskInfo.callBackIdToCallBackDownloading[callBack.identifier] = callBack;
        }
    });
    
    return callBack.identifier;
}

- (void)pauseDownloadTaskByIdentifier:(NSString *)identifier {
    if (nil == identifier) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.callbackIdToTaskInfo objectForKey:identifier];
        if (nil == taskInfo) { return ; }
        ZADownloadCallback *pauseCallBack = taskInfo.callBackIdToCallBackDownloading[identifier];
        if (nil == pauseCallBack) { return; }
        
        [taskInfo.callBackIdToCallBackDownloading removeObjectForKey:identifier];
        taskInfo.callBackIdToCallBackPause[identifier] = pauseCallBack;
        
        if (taskInfo.callBackIdToCallBackDownloading.count == 0) {
            [taskInfo changeStatusTo:(ZASessionTaskStatusPaused)];
            [taskInfo.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                if (resumeData) {
                    taskInfo.resumeData = (NSMutableData *)resumeData;
                }
            }];
        }
    });
}

- (void)resumeDownloadTaskByIdentifier:(NSString *)identifier {
    if (nil == identifier) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.callbackIdToTaskInfo objectForKey:identifier];
        if (nil == taskInfo) { return; }
        
        ZADownloadCallback *resumeCallBack = taskInfo.callBackIdToCallBackPause[identifier];
        if (nil == resumeCallBack) { return; }
        [taskInfo.callBackIdToCallBackPause removeObjectForKey:identifier];
        
        if (taskInfo.status == ZASessionTaskStatusRunning) {
            taskInfo.callBackIdToCallBackDownloading[identifier] = resumeCallBack;
        } else if (taskInfo.status == ZASessionTaskStatusSuccessed && taskInfo.completeFileLocation) {
            resumeCallBack.completionBlock(taskInfo.downloadTask.response, taskInfo.downloadTask.error, resumeCallBack.identifier);
            NSURL *filePath = resumeCallBack.destinationBlock(taskInfo.completeFileLocation, resumeCallBack.identifier);
            if (filePath) {
                [NSFileManager.defaultManager copyItemAtURL:taskInfo.completeFileLocation toURL:filePath error:NULL];
            }
            
            [weakSelf.callbackIdToTaskInfo removeObjectForKey:identifier];
            
            if (taskInfo.callBackIdToCallBackPause.count == 0) {
                [NSFileManager.defaultManager removeItemAtURL:taskInfo.completeFileLocation error:NULL];
                [weakSelf.urlRequestToTaskInfo removeObjectForKey:taskInfo.originalRequest];
            }
            
        } else if (taskInfo.status == ZASessionTaskStatusPaused || taskInfo.status == ZASessionTaskStatusFailed) {
            NSURLSessionDownloadTask *resumeTask;
            NSURLRequest *resumeRequest = taskInfo.originalRequest.copy;
            
            if (taskInfo.resumeData) {
                resumeTask = [weakSelf.session downloadTaskWithResumeData:taskInfo.resumeData.copy];
            } else {
                resumeTask = [weakSelf.session downloadTaskWithRequest:resumeRequest];
            }
            
            [resumeTask resume];
            
            ZATaskInfo *resumeTaskInfo = [[ZATaskInfo alloc] initWithDownloadTask:resumeTask originalRequest:resumeRequest];
            resumeTaskInfo.resumeData = taskInfo.resumeData.copy;
            resumeTaskInfo.callBackIdToCallBackDownloading[identifier] = resumeCallBack;
            [resumeTaskInfo changeStatusTo:(ZASessionTaskStatusRunning)];
            
            weakSelf.urlRequestToTaskInfo[resumeRequest] = resumeTaskInfo;
            weakSelf.callbackIdToTaskInfo[identifier] = resumeTaskInfo;
            weakSelf.taskIdToTaskInfo[[NSNumber numberWithInteger:resumeTask.taskIdentifier]] = resumeTaskInfo;
            
            for (NSString *pauseId in taskInfo.callBackIdToCallBackPause.allKeys) {
                if (pauseId) {
                    ZADownloadCallback *pauseCallBack = taskInfo.callBackIdToCallBackPause[pauseId];
                    if (pauseCallBack) {
                        resumeTaskInfo.callBackIdToCallBackPause[pauseId] = pauseCallBack;
                        weakSelf.callbackIdToTaskInfo[pauseId] = resumeTaskInfo;
                    }
                }
            }
            
            [taskInfo.callBackIdToCallBackPause removeAllObjects];
        }
        
        if (taskInfo.callBackIdToCallBackPause.count == 0
            && taskInfo.callBackIdToCallBackDownloading.count == 0) {
            [weakSelf.taskIdToTaskInfo removeObjectForKey:[NSNumber numberWithInteger:taskInfo.downloadTask.taskIdentifier]];
            [taskInfo.downloadTask cancel];
        }
    });
}

- (void)cancelDownloadTaskByIdentifier:(NSString *)identifier {
    if (nil == identifier) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.callbackIdToTaskInfo objectForKey:identifier];
        if (nil == taskInfo) { return; }
        ZADownloadCallback *cancelCallBack = taskInfo.callBackIdToCallBackPause[identifier];
        [weakSelf.callbackIdToTaskInfo removeObjectForKey:identifier];
        
        if (cancelCallBack) {
            [taskInfo.callBackIdToCallBackPause removeObjectForKey:identifier];
        } else {
            cancelCallBack = taskInfo.callBackIdToCallBackDownloading[identifier];
            [taskInfo.callBackIdToCallBackDownloading removeObjectForKey:identifier];
        }
        
        if (nil == cancelCallBack) {  return; }
        
        if (taskInfo.callBackIdToCallBackPause.count == 0
            && taskInfo.callBackIdToCallBackDownloading.count == 0) {
            [weakSelf.taskIdToTaskInfo removeObjectForKey:[NSNumber numberWithInteger:taskInfo.downloadTask.taskIdentifier]];
            [weakSelf.urlRequestToTaskInfo removeObjectForKey:taskInfo.originalRequest];
            [taskInfo.downloadTask cancel];
        }
    });
}

- (void)updateDownloadTaskPriority:(ZADownloadPriority)priority byIdentifier:(NSString *)identifier {
    if (nil == identifier) { return; }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.callbackIdToTaskInfo objectForKey:identifier];
        if (taskInfo) {
            [taskInfo updateCallbackPriority:priority byIdentifier:identifier];
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
    NetworkStatus status = ZANetworkManager.sharedInstance.currentNetworkStatus;
    switch (status) {
        case ReachableViaWiFi:
            return 15;
            
        case ReachableViaWWAN:
            return 30;
            
        case NotReachable:
            return 0;
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        for (ZADownloadCallback *callBack in taskInfo.callBackIdToCallBackDownloading.allValues) {
            callBack.completionBlock(downloadTask.response, downloadTask.error, callBack.identifier);
            NSURL *filePath = callBack.destinationBlock(location, callBack.identifier);
            if (filePath) {
                [NSFileManager.defaultManager copyItemAtURL:location
                                                      toURL:filePath
                                                      error:NULL];
            }
        }
        
        for (NSString *callBackDownloading in taskInfo.callBackIdToCallBackDownloading.allKeys) {
            if (callBackDownloading) {
                [weakSelf.callbackIdToTaskInfo removeObjectForKey:callBackDownloading];
            }
        }
        [taskInfo.callBackIdToCallBackDownloading removeAllObjects];
        
        if (taskInfo.callBackIdToCallBackPause.count == 0) {
            [NSFileManager.defaultManager removeItemAtURL:location error:NULL];
            [weakSelf.urlRequestToTaskInfo removeObjectForKey:taskInfo.originalRequest];
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
    
    dispatch_async(self.root_queue, ^{
        NSProgress *progress = [[NSProgress alloc] init];
        progress.totalUnitCount = totalBytesExpectedToWrite;
        progress.completedUnitCount = totalBytesWritten;
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        for (ZADownloadCallback *callBackDownloading in taskInfo.callBackIdToCallBackDownloading.allValues) {
            callBackDownloading.progressBlock(progress, callBackDownloading.identifier);
        }
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        NSProgress *progress = [[NSProgress alloc] init];
        progress.totalUnitCount = expectedTotalBytes;
        progress.completedUnitCount = fileOffset;
        ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:downloadTask.taskIdentifier]];
        for (ZADownloadCallback *callBackDownloading in taskInfo.callBackIdToCallBackDownloading.allValues) {
            callBackDownloading.progressBlock(progress, callBackDownloading.identifier);
        }
    });
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.root_queue, ^{
        if (error) {
            ZATaskInfo *taskInfo = [weakSelf.taskIdToTaskInfo objectForKey:[NSNumber numberWithInteger:task.taskIdentifier]];
            for (NSString *callBackId in taskInfo.callBackIdToCallBackDownloading.allKeys) {
                ZADownloadCallback *callBackDownloading = [taskInfo.callBackIdToCallBackDownloading objectForKey:callBackId];
                if (callBackDownloading) {
                    callBackDownloading.completionBlock(task.response, error, callBackDownloading.identifier);
                    taskInfo.callBackIdToCallBackPause[callBackId] = callBackDownloading;
                }
            }
            
            [taskInfo.callBackIdToCallBackDownloading removeAllObjects];
            
            [taskInfo changeStatusTo:(ZASessionTaskStatusFailed)];
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (resumeData) {
                taskInfo.resumeData = (NSMutableData *)resumeData;
            }
        }
    });
}

@end
