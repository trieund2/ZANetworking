//
//  ZAURLSessionTaskInfo.h
//  ZANetworking
//
//  Created by CPU12166 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ZAURLSessionTaskStatus) {
    kURLSessionTaskNotRunning = 0,
    kURLSessionTaskRunning = 1,
    kURLSessionTaskCompleted = 2,
    kURLSessionTaskPaused = 3,
    kURLSessionTaskCancelled = 4
};

typedef NS_ENUM(NSInteger, ZAURLSessionTaskPriority) {
    kURLSessionTaskPriorityVeryHigh = 0,
    kURLSessionTaskPriorityHigh = 1,
    kURLSessionTaskPriorityMedium = 2,
    kURLSessionTaskPriorityLow = 3
};

@interface ZAURLSessionTaskInfo : NSObject

@end
