//
//  ZAURLSessionManager.h
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZADownloadPriority.h"
#import "ZAURLSessionTaskRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZAURLSessionManager : NSObject <NSURLSessionDownloadDelegate>

+ (instancetype)sharedManager;

- (NSString *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(NSDictionary *)header
                               priority:(ZADownloadPriority)priority
                          progressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                       destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                        completionBlock:(ZAURLSessionTaskCompletionBlock)completionBloc;

- (void)resumeDownloadTaskWithIdentifier:(NSString *)identifier;
- (void)pauseDownloadTaskWithIdentifier:(NSString *)identifier;
- (void)cancelDownloadTaskWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
