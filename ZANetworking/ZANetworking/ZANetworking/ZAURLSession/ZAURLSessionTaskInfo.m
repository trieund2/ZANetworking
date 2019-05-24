//
//  ZAURLSessionTaskInfo.m
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionTaskInfo.h"
#import "ZAURLSessionTaskRequest.h"

@interface ZAURLSessionTaskInfo ()

@end

@implementation ZAURLSessionTaskInfo

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest {
    return [self initWithDownloadTask:downloadTask taskRequest:taskRequest priority:kURLSessionTaskPriorityMedium];
}

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest
                            priority:(ZAURLSessionTaskPriority)priority {
    if (self = [super init]) {
        _downloadTask = downloadTask;
        _priority = priority;
        _taskRequests = [NSMutableArray arrayWithObject:taskRequest];
        _receivedData = [NSMutableData data];
        _status = kURLSessionTaskInitialized;
    }
    return self;
}

- (BOOL)canChangeToStatus:(ZAURLSessionTaskStatus)status {
    switch (_status) {
        case kURLSessionTaskInitialized:
            return YES;
            
        case kURLSessionTaskRunning:
            return (status == kURLSessionTaskPaused) || (status == kURLSessionTaskCompleted) || (status == kURLSessionTaskCancelled);
            
        case kURLSessionTaskPaused:
            return (status == kURLSessionTaskRunning) || (status == kURLSessionTaskCompleted) || (status == kURLSessionTaskCancelled);
            
        case kURLSessionTaskCompleted:
        case kURLSessionTaskCancelled:
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
