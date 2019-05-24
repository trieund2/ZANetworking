//
//  ZAURLSessionTaskInfo.h
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZAURLSessionTaskRequest;

typedef NS_ENUM(NSInteger, ZAURLSessionTaskStatus) {
    // Status when task has just been initialized.
    kURLSessionTaskInitialized = 0,
    // Status when task runs.
    kURLSessionTaskRunning = 1,
    // Status when task is paused, might be resumed later.
    kURLSessionTaskPaused = 2,
    // Status when task completed, may be failed or successful.
    kURLSessionTaskCompleted = 3,
    // Status when task is cancelled, can not be resumed later.
    kURLSessionTaskCancelled = 4
};

typedef NS_ENUM(NSInteger, ZAURLSessionTaskPriority) {
    kURLSessionTaskPriorityVeryHigh = 0,
    kURLSessionTaskPriorityHigh = 1,
    kURLSessionTaskPriorityMedium = 2,
    kURLSessionTaskPriorityLow = 3
};

@interface ZAURLSessionTaskInfo : NSObject

@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) NSMutableData *receivedData;
@property (assign, nonatomic, readonly) ZAURLSessionTaskStatus status;
@property (assign, nonatomic) ZAURLSessionTaskPriority priority;
@property (strong, nonatomic) NSMutableArray<ZAURLSessionTaskRequest *> *taskRequests;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest
                            priority:(ZAURLSessionTaskPriority)priority NS_DESIGNATED_INITIALIZER;

- (BOOL)canChangeToStatus:(ZAURLSessionTaskStatus)status;

- (void)changeStatusTo:(ZAURLSessionTaskStatus)status;

@end
