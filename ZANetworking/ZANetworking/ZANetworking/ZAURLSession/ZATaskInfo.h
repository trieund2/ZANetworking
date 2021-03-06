//
//  ZAURLSessionTaskInfo.h
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZADownloadCallback.h"
#import "ZASessionTaskStatus.h"
#import "ZADownloadPriority.h"

@interface ZATaskInfo : NSObject

@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic,) NSMutableData *resumeData;
@property (assign, nonatomic) ZASessionTaskStatus status;
@property (strong, nonatomic) NSURL *completeFileLocation;
@property (strong, nonatomic) NSURLRequest *originalRequest;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString*, ZADownloadCallback*> *callBackIdToCallBackDownloading;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString*, ZADownloadCallback*> *callBackIdToCallBackPause;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                     originalRequest:(NSURLRequest *)originalRequest;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                     originalRequest:(NSURLRequest *)originalRequest
                            priority:(ZADownloadPriority)priority NS_DESIGNATED_INITIALIZER;

/* Return a BOOL shows that if this task can change to a specific status or not */
- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status;

/**
 * @abstract Change this task's status to a new one
 * @discussion Do this only after checking `canChangeToStatus` to see whether change action is possible.
 * @warning If you try to change task's status to a forbidden one, it will throw an error in debug mode.
 */
- (void)changeStatusTo:(ZASessionTaskStatus)status;

- (void)updateDownloadTaskPriorityByPriorityWasRemoved:(ZADownloadPriority)removedPriority;

@end
