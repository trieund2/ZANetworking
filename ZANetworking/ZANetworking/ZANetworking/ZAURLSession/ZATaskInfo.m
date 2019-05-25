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

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZADownloadMonitor *)taskRequest {
    return [self initWithDownloadTask:downloadTask taskRequest:taskRequest priority:ZADownloadPriorityMedium];
}

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZADownloadMonitor *)taskRequest
                            priority:(ZADownloadPriority)priority {
    if (self = [super init]) {
        _downloadTask = downloadTask;
        _priority = priority;
        _receivedData = [NSMutableData data];
        _status = ZAURLSessionTaskStatusInitialized;
        _requestToDownloadMonitorDownloading = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status {
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

- (void)changeStatusTo:(ZASessionTaskStatus)status {
#if DEBUG
    NSAssert([self canChangeToStatus:status], @"Error: Status can not be changed");
#endif
    if (![self canChangeToStatus:status]) { return; }
    _status = status;
}

@end