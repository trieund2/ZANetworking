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
    return [self initWithDownloadTask:downloadTask taskRequest:taskRequest priority:ZAURLSessionTaskPriorityMedium];
}

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest
                            priority:(ZAURLSessionTaskPriority)priority {
    if (self = [super init]) {
        _downloadTask = downloadTask;
        _priority = priority;
        _receivedDataProtector = [[ProtectorObject alloc] initFromObject:[NSMutableData data]];
        _status = ZAURLSessionTaskStatusInitialized;
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:taskRequest forKey:taskRequest.identifier];
        _requestIdToTaskRequestProtector = [[ProtectorObject alloc] initFromObject:dict];
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
    pthread_mutex_lock(&url_session_task_info_mutex);
    _status = status;
    pthread_mutex_unlock(&url_session_task_info_mutex);
}

- (ZAURLSessionTaskRequest *)taskRequestByRequestId:(NSString *)identifier {
    ZAURLSessionTaskRequest *taskRequest;
    __weak typeof(self) weakSelf = self;
    [self.requestIdToTaskRequestProtector performWithBlock:^{
        [weakSelf.requestIdToTaskRequestProtector.object objectForKey:identifier];
    }];
    
    return taskRequest;
}

- (void)resumeDownloadTaskByIdentifier:(NSString *)identifier {
    __weak typeof(self) weakSelf = self;
    [self.requestIdToTaskRequestProtector performWithBlock:^{
        [weakSelf.requestIdToTaskRequestProtector.object removeObjectForKey:identifier];
    }];
}

- (void)addTaskRequest:(ZAURLSessionTaskRequest *)taskRequest {
    __weak typeof(self) weakSelf = self;
    [self.requestIdToTaskRequestProtector performWithBlock:^{
        weakSelf.requestIdToTaskRequestProtector.object[taskRequest.identifier] = taskRequest;
    }];
}

- (void)cancelTaskRequestByRequestId:(NSString *)requestId {
    __weak typeof(self) weakSelf = self;
    [self.requestIdToTaskRequestProtector performWithBlock:^{
        [weakSelf.requestIdToTaskRequestProtector.object removeObjectForKey:requestId];
    }];
}

- (NSUInteger)numberOfTaskRequests {
    __block NSUInteger count;
    __weak typeof(self) weakSelf = self;
    [self.requestIdToTaskRequestProtector performWithBlock:^{
        count = weakSelf.requestIdToTaskRequestProtector.object.count;
    }];
    return count;
}

@end
