//
//  ZAURLSessionDownloadMonitorBlock.h
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ZAURLSessionTaskProgressBlock)(NSProgress *progress, NSString *callBackIdentifier);
typedef NSURL * (^ZAURLSessionDownloadTaskDestinationBlock)(NSURL *location, NSString *callBackIdentifier);
typedef void (^ZAURLSessionTaskCompletionBlock)(NSURLResponse *response, NSError *error, NSString *callBackIdentifier);

@interface ZADownloadCallback : NSObject

@property (copy, nonatomic, readonly) NSString *identifier;
@property (copy, nonatomic, readonly) ZAURLSessionTaskProgressBlock progressBlock;
@property (copy, nonatomic, readonly) ZAURLSessionDownloadTaskDestinationBlock destinationBlock;
@property (copy, nonatomic, readonly) ZAURLSessionTaskCompletionBlock completionBlock;

- (instancetype)initWithProgressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                     destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                      completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock NS_DESIGNATED_INITIALIZER;

@end
