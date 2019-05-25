//
//  ZAURLSessionTaskRequest.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionTaskRequest.h"
#import "pthread.h"

@interface ZAURLSessionTaskRequest ()

@end

pthread_mutex_t url_session_task_request_mutex = PTHREAD_MUTEX_INITIALIZER;

@implementation ZAURLSessionTaskRequest

- (instancetype)init {
    return [self initWithProgressBlock:nil destinationBlock:nil completionBlock:nil];
}

- (instancetype)initWithProgressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                     destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                      completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    if (self = [super init]) {
        _identifier = NSUUID.UUID.UUIDString;
        _status = kURLSessionTaskRequestInitialized;
        _progressBlock = progressBlock;
        _destinationBlock = destinationBlock;
        _completionBlock = completionBlock;
    }
    return self;
}

- (BOOL)canBePaused {
    return _status == kURLSessionTaskRequestInitialized;
}

- (void)pause {
#if DEBUG
    NSAssert([self canBePaused], @"Error: Pause a task that can not be paused, id: %@", _identifier);
#endif
    if (![self canBePaused]) { return; }
    pthread_mutex_lock(&url_session_task_request_mutex);
    _status = kURLSessionTaskRequestPaused;
    pthread_mutex_unlock(&url_session_task_request_mutex);
}

- (BOOL)canBeCancelled {
    return _status != kURLSessionTaskRequestCancelled;
}

- (void)cancel {
#if DEBUG
    NSAssert([self canBeCancelled], @"Error: Cancel a task that can not be cancelled, id: %@", _identifier);
#endif
    if (![self canBeCancelled]) { return; }
    pthread_mutex_lock(&url_session_task_request_mutex);
    _status = kURLSessionTaskRequestCancelled;
    pthread_mutex_unlock(&url_session_task_request_mutex);
}

- (void)updateStatus:(ZAURLSessionTaskRequestStatus)status {
    pthread_mutex_lock(&url_session_task_request_mutex);
    _status = status;
    pthread_mutex_unlock(&url_session_task_request_mutex);
}

@end
