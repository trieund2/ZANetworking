//
//  ZAURLSessionTaskRequest.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZADownloadMonitor.h"
#import "pthread.h"

@interface ZADownloadMonitor ()

@end

pthread_mutex_t url_session_task_request_mutex = PTHREAD_MUTEX_INITIALIZER;

@implementation ZADownloadMonitor

- (instancetype)init {
    return [self initWithProgressBlock:nil destinationBlock:nil completionBlock:nil];
}

- (instancetype)initWithProgressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                     destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                      completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    if (self = [super init]) {
        _identifier = NSUUID.UUID.UUIDString;
        _progressBlock = progressBlock;
        _destinationBlock = destinationBlock;
        _completionBlock = completionBlock;
    }
    return self;
}

@end
