//
//  ZASessionManager.h
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZADownloadPriority.h"
#import "ZADownloadCallback.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZASessionManager : NSObject <NSURLSessionDownloadDelegate>

+ (instancetype)sharedManager;

- (NSString *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(nullable NSDictionary<NSString *, NSString *> *)header
                               priority:(ZADownloadPriority)priority
                          progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                       destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                        completionBlock:(ZAURLSessionTaskCompletionBlock)completionBloc;

- (void)resumeDownloadTaskByIdentifier:(NSString *)identifier;
- (void)pauseDownloadTaskByIdentifier:(NSString *)identifier;
- (void)cancelDownloadTaskByIdentifier:(NSString *)identifier;
- (void)updateDownloadTaskPriority:(ZADownloadPriority)priority byIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
