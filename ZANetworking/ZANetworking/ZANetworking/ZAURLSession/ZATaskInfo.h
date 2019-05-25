//
//  ZAURLSessionTaskInfo.h
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZADownloadMonitor.h"
#import "ZASessionTaskStatus.h"
#import "ZADownloadPriority.h"

@interface ZATaskInfo : NSObject

@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic,) NSMutableData *receivedData;
@property (assign, nonatomic) ZASessionTaskStatus status;
@property (assign, nonatomic) ZADownloadPriority priority;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSURLRequest *, ZADownloadMonitor*> *requestToDownloadMonitorDownloading;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSURLRequest *, ZADownloadMonitor*> *requestToDownloadMonitorPause;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZADownloadMonitor *)taskRequest;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                         taskRequest:(ZADownloadMonitor *)taskRequest
                            priority:(ZADownloadPriority)priority NS_DESIGNATED_INITIALIZER;

/* Return a BOOL shows that if this task can change to a specific status or not */
- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status;

/**
 * @abstract Change this task's status to a new one
 * @discussion Do this only after checking `canChangeToStatus` to see whether change action is possible.
 * @warning If you try to change task's status to a forbidden one, it will throw an error in debug mode.
 */
- (void)changeStatusTo:(ZASessionTaskStatus)status;

@end
