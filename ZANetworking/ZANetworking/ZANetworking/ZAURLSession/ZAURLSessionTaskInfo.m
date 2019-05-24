//
//  ZAURLSessionTaskInfo.m
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionTaskInfo.h"

@interface ZAURLSessionTaskInfo ()

@property (strong, nonatomic) NSData *receivedData;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (assign, nonatomic) ZAURLSessionTaskStatus status;
@property (assign, nonatomic) ZAURLSessionTaskPriority priority;

@end

@implementation ZAURLSessionTaskInfo

@end
