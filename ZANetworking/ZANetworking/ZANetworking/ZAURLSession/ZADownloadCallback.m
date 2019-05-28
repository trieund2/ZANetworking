//
//  ZAURLSessionTaskRequest.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZADownloadCallback.h"

@implementation ZADownloadCallback

- (instancetype)init {
    return [self initWithProgressBlock:nil destinationBlock:nil completionBlock:nil];
}

- (instancetype)initWithProgressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                     destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                      completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    if (self = [super init]) {
        _identifier = NSUUID.UUID.UUIDString;
        _progressBlock = progressBlock;
        _destinationBlock = destinationBlock;
        _completionBlock = completionBlock;
    }
    
    return self;
}

@end
