//
//  ZAURLSessionTaskInfo.m
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionTaskInfo.h"
#import "pthread.h"

@interface ZAURLSessionTaskInfo ()

@end

@implementation ZAURLSessionTaskInfo

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest {
    return [self initWithDownloadTask:downloadTask taskRequest:taskRequest priority:ZAURLSessionTaskPriorityMedium];
}

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest
                            priority:(ZAURLSessionTaskPriority)priority {
    if (self = [super init]) {
        _downloadTask = downloadTask;
        _priority = priority;
        _receivedData = [NSMutableData data];
        _status = ZAURLSessionTaskStatusInitialized;
        _requestIdToTaskRequestDownloading = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)canChangeToStatus:(ZAURLSessionTaskStatus)status {
    switch (_status) {
        case ZAURLSessionTaskStatusInitialized:
            return YES;
            
        case ZAURLSessionTaskStatusRunning:
            return (status == ZAURLSessionTaskStatusPaused) || (status == ZAURLSessionTaskStatusCompleted) || (status == ZAURLSessionTaskStatusCancelled);
            
        case ZAURLSessionTaskStatusPaused:
            return (status == ZAURLSessionTaskStatusRunning) || (status == ZAURLSessionTaskStatusCompleted) || (status == ZAURLSessionTaskStatusCancelled);
            
        case ZAURLSessionTaskStatusCompleted:
        case ZAURLSessionTaskStatusCancelled:
            return NO;
    }
}

- (void)changeStatusTo:(ZAURLSessionTaskStatus)status {
#if DEBUG
    NSAssert([self canChangeToStatus:status], @"Error: Status can not be changed");
#endif
    if (![self canChangeToStatus:status]) { return; }
    _status = status;
}

@end
