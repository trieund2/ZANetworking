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

pthread_mutex_t url_session_task_info_mutex = PTHREAD_MUTEX_INITIALIZER;

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
        _taskRequestsKeyedById = [NSMutableDictionary dictionaryWithObject:taskRequest forKey:taskRequest.identifier];
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
    pthread_mutex_lock(&url_session_task_info_mutex);
    _status = status;
    pthread_mutex_unlock(&url_session_task_info_mutex);
}

- (ZAURLSessionTaskRequest *)taskRequestByIdentifier:(NSString *)identifier {
    return [self.taskRequestsKeyedById objectForKey:identifier];
}

- (void)resumeDownloadTaskByIdentifier:(NSString *)identifier {
    [self.taskRequestsKeyedById removeObjectForKey:identifier];
}

@end
