//
//  ZAURLSessionTaskInfo.h
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZAURLSessionTaskRequest.h"
#import "ZAURLSessionTaskStatus.h"

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
@property (strong, nonatomic, readonly) NSMutableDictionary<NSURLRequest *, ZAURLSessionTaskRequest*> *requestIdToTaskRequestDownloading;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSURLRequest *, ZAURLSessionTaskRequest*> *requestToTaskRequestPause;

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

@end
