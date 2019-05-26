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
        _status = ZASessionTaskStatusInitialized;
        _requestToDownloadMonitorDownloading = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status {
    switch (_status) {
        case ZASessionTaskStatusInitialized:
            return YES;
            
        case ZASessionTaskStatusRunning:
            return (status == ZASessionTaskStatusPaused) || (status == ZASessionTaskStatusCompleted) || (status == ZASessionTaskStatusCancelled);
            
        case ZASessionTaskStatusPaused:
            return (status == ZASessionTaskStatusRunning) || (status == ZASessionTaskStatusCompleted) || (status == ZASessionTaskStatusCancelled);
            
        case ZASessionTaskStatusCompleted:
        case ZASessionTaskStatusCancelled:
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
