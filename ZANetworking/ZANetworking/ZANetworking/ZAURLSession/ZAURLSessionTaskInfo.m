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

@end
