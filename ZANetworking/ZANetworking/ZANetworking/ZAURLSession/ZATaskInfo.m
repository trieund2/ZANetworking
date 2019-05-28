//
//  ZAURLSessionTaskInfo.m
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZATaskInfo.h"
#import "pthread.h"

@interface ZATaskInfo ()

@end

@implementation ZATaskInfo

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask originalRequest:(NSURLRequest *)originalRequest {
    return [self initWithDownloadTask:downloadTask originalRequest:originalRequest priority:ZADownloadPriorityMedium];
}

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                     originalRequest:(NSURLRequest *)originalRequest
                            priority:(ZADownloadPriority)priority {
    if (self = [super init]) {
        _downloadTask = downloadTask;
        _downloadTask.priority = priority;
        _resumeData = NULL;
        _status = ZASessionTaskStatusInitialized;
        _callBackIdToCallBackDownloading = [[NSMutableDictionary alloc] init];
        _callBackIdToCallBackPause = [[NSMutableDictionary alloc] init];
        _completeFileLocation = NULL;
        _originalRequest = originalRequest;
    }
    
    return self;
}

- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status {
    switch (_status) {
        case ZASessionTaskStatusInitialized:
            return YES;
            
        case ZASessionTaskStatusRunning:
            return (status == ZASessionTaskStatusPaused) || (status == ZASessionTaskStatusSuccessed) || (status == ZASessionTaskStatusCancelled) || (status == ZASessionTaskStatusFailed);
            
        case ZASessionTaskStatusPaused:
            return (status == ZASessionTaskStatusRunning) || (status == ZASessionTaskStatusSuccessed) || (status == ZASessionTaskStatusCancelled) || (status == ZASessionTaskStatusFailed);
            
        case ZASessionTaskStatusSuccessed:
        case ZASessionTaskStatusCancelled:
        case ZASessionTaskStatusFailed:
            return YES;
    }
}

- (void)changeStatusTo:(ZASessionTaskStatus)status {
#if DEBUG
    NSAssert([self canChangeToStatus:status], @"Error: Status can not be changed");
#endif
    if (![self canChangeToStatus:status]) { return; }
    _status = status;
}

- (void)updateDownloadTaskPriorityByPriorityWasRemoved:(ZADownloadPriority)removedPriority {
    if (self.downloadTask.priority == removedPriority) {
        ZADownloadPriority newPriority = ZADownloadPriorityLow;
        for (ZADownloadCallback *callback in self.callBackIdToCallBackDownloading.allValues) {
            if (callback.priority > newPriority) {
                newPriority = callback.priority;
            }
        }
        self.downloadTask.priority = newPriority;
    }
}

@end
