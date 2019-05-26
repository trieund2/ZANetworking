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
    ZASessionTaskStatusInitialized  = 0,
    // Status when task runs.
    ZASessionTaskStatusRunning      = 1,
    // Status when task is paused, might be resumed later.
    ZASessionTaskStatusPaused       = 2,
    // Status when task completed, may be failed or successful.
    ZASessionTaskStatusCompleted    = 3,
    // Status when task is cancelled, can not be resumed later.
    ZASessionTaskStatusCancelled    = 4
};

#endif /* ZAURLSessionTaskStatus_h */
