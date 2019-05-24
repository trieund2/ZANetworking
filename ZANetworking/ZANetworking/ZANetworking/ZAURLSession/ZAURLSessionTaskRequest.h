//
//  ZAURLSessionTaskRequest.h
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ZAURLSessionTaskProgressBlock)(NSProgress *);
typedef NSURL * (^ZAURLSessionDownloadTaskDestinationBlock)(NSURL *location);
typedef void (^ZAURLSessionTaskCompletionBlock)(NSURLResponse *response, NSError *error);

typedef NS_ENUM(NSInteger, ZAURLSessionTaskRequestStatus) {
    // Status when request has been submited to Session manager
    kURLSessionTaskRequestInitialized = 0,
    // Status when request has been paused by its owner
    kURLSessionTaskRequestPaused = 1,
    // Status when request has been cancelled by its owner
    kURLSessionTaskRequestCancelled = 2
};

@interface ZAURLSessionTaskRequest : NSObject

@property (copy, nonatomic, readonly) NSString *identifier;
@property (assign, nonatomic, readonly) ZAURLSessionTaskRequestStatus status;
@property (copy, nonatomic, readonly) ZAURLSessionTaskProgressBlock progressBlock;
@property (copy, nonatomic, readonly) ZAURLSessionDownloadTaskDestinationBlock destinationBlock;
@property (copy, nonatomic, readonly) ZAURLSessionTaskCompletionBlock completionBlock;

- (instancetype)initWithProgressBlock:(ZAURLSessionTaskProgressBlock)progressBlock
                     destinationBlock:(ZAURLSessionDownloadTaskDestinationBlock)destinationBlock
                      completionBlock:(ZAURLSessionTaskCompletionBlock)completionBlock NS_DESIGNATED_INITIALIZER;

/* Return a BOOL shows that if this request can be paused or not */
- (BOOL)canBePaused;

/**
 * @abstract Pause this task request
 * @discussion Do this only after checking `canBePaused` to see whether this task can be paused or not.
 * @warning If you try to pause task when it can not be paused, it will throw an error in debug mode.
 */
- (void)pause;

/* Return a BOOL shows that if this request can be cancelled or not */
- (BOOL)canBeCancelled;

/**
 * @abstract Cancel this task request
 * @discussion Do this only after checking `canBeCancelled` to see whether this task can be cancelled or not.
 * @warning If you try to cancel task when it can not be cancelled, it will throw an error in debug mode.
 */
- (void)cancel;

@end
