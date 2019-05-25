//
//  ZAURLSessionTaskStatus.h
//  ZANetworking
//
//  Created by MACOS on 5/25/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#ifndef ZAURLSessionTaskStatus_h
#define ZAURLSessionTaskStatus_h

typedef NS_ENUM(NSInteger, ZASessionTaskStatus) {
    // Status when task has just been initialized.
    ZAURLSessionTaskStatusInitialized = 0,
    // Status when task runs.
    ZAURLSessionTaskStatusRunning = 1,
    // Status when task is paused, might be resumed later.
    ZAURLSessionTaskStatusPaused = 2,
    // Status when task completed, may be failed or successful.
    ZAURLSessionTaskStatusCompleted = 3,
    // Status when task is cancelled, can not be resumed later.
    ZAURLSessionTaskStatusCancelled = 4
};

#endif /* ZAURLSessionTaskStatus_h */
