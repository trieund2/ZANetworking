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
    if (self = [super init]) {
        _downloadTask = downloadTask;
        _resumeData = NULL;
        _status = ZASessionTaskStatusInitialized;
        _monitorIdToDownloadMonitorDownloading = [[NSMutableDictionary alloc] init];
        _monitorIdToDownloadMonitorPause = [[NSMutableDictionary alloc] init];
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
            return (status == ZASessionTaskStatusRunning) || (status == ZASessionTaskStatusSuccessed) || (status == ZASessionTaskStatusCancelled);
            
        case ZASessionTaskStatusSuccessed:
        case ZASessionTaskStatusCancelled:
        case ZASessionTaskStatusFailed:
            return YES;
    }
}

- (void)changeStatusTo:(ZASessionTaskStatus)status {
//#if DEBUG
//    NSAssert([self canChangeToStatus:status], @"Error: Status can not be changed");
//#endif
    if (![self canChangeToStatus:status]) { return; }
    _status = status;
}

@end
