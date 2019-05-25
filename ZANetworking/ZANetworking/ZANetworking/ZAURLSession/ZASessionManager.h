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

@interface ZASessionManager : NSObject <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

+ (instancetype)sharedManager;

- (NSURLRequest *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(NSDictionary *)header
                               priority:(ZADownloadPriority)priority
                          progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                       destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                        completionBlock:(ZAURLSessionTaskCompletionBlock)completionBloc;

- (void)resumeDownloadTaskByRequest:(NSURLRequest *)request;
- (void)pauseDownloadTaskByRequest:(NSURLRequest *)request;
- (void)cancelDownloadTaskByRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
