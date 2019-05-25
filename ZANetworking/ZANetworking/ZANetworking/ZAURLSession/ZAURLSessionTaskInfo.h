//
//  ZAURLSessionTaskInfo.h
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZAURLSessionTaskRequest.h"
#import "ProtectorObject.h"

typedef NS_ENUM(NSInteger, ZAURLSessionTaskStatus) {
    // Status when task has just been initialized.
    ZAURLSessionTaskStatusInitialized = 0,
    // Status when task runs.
    ZAURLSessionTaskStatusRunning = 1,
    // Status when task is paused, might be resumed later.
    ZAURLSessionTaskStatusPaused = 2,
    // Status when task completed, may be failed or successful.
    ZAURLSessionTaskStatusCompleted = 3,
    // Status when task is cancelled, can not be resumed later.
    ZAURLSessionTaskStatusCancelled = 4
};

typedef NS_ENUM(NSInteger, ZAURLSessionTaskPriority) {
    ZAURLSessionTaskPriorityVeryHigh    = 0,
    ZAURLSessionTaskPriorityHigh        = 1,
    ZAURLSessionTaskPriorityMedium      = 2,
    ZAURLSessionTaskPriorityLow         = 3
};

@interface ZAURLSessionTaskInfo : NSObject

@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic, readonly) NSMutableData *receivedData;
@property (assign, nonatomic, readonly) ZAURLSessionTaskStatus status;
@property (assign, nonatomic) ZAURLSessionTaskPriority priority;
@property (strong, nonatomic, readonly) ProtectorObject<NSMutableDictionary<NSString *, ZAURLSessionTaskRequest *> *> *requestIdToTaskRequestProtector;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZAURLSessionTaskRequest *)taskRequest
                            priority:(ZAURLSessionTaskPriority)priority NS_DESIGNATED_INITIALIZER;

/* Return a BOOL shows that if this task can change to a specific status or not */
- (BOOL)canChangeToStatus:(ZAURLSessionTaskStatus)status;

/**
 * @abstract Change this task's status to a new one
 * @discussion Do this only after checking `canChangeToStatus` to see whether change action is possible.
 * @warning If you try to change task's status to a forbidden one, it will throw an error in debug mode.
 */
- (void)changeStatusTo:(ZAURLSessionTaskStatus)status;

- (ZAURLSessionTaskRequest *)taskRequestByRequestId:(NSString *)identifier;

- (void)resumeDownloadTaskByIdentifier:(NSString *)identifier;

- (void)addTaskRequest:(ZAURLSessionTaskRequest *)taskRequest;

- (void)cancelTaskRequestByRequestId:(NSString *)requestId;

- (NSUInteger)numberOfTaskRequests;

@end
