//
//  ZAURLSessionTaskBlock.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZAURLSessionTaskBlock.h"

@implementation ZAURLSessionTaskBlock

- (instancetype)initWithProgressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                     destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                      completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock {
    if (self = [self init]) {
        self.progressBlock = progressBlock;
        self.destinationBlock = destinationBlock;
        self.completionBlock = completionBlock;
    }
    return self;
}

@end
