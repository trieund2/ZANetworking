//
//  ZASessionManager.h
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZADownloadPriority.h"
#import "ZADownloadMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZASessionManager : NSObject <NSURLSessionDownloadDelegate>

+ (instancetype)sharedManager;

- (NSString *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(nullable NSDictionary<NSString *, NSString *> *)header
                               priority:(ZADownloadPriority)priority
                          progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                       destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                        completionBlock:(ZAURLSessionTaskCompletionBlock)completionBloc;

- (void)resumeDownloadTaskByDownloadMonitorId:(NSString *)monitorId;
- (void)pauseDownloadTaskByDownloadMonitorId:(NSString *)monitorId;
- (void)cancelDownloadTaskByMonitorId:(NSString *)monitorId;

@end

NS_ASSUME_NONNULL_END
