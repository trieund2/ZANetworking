//
//  TrackDownload.m
//  ZANetworking
//
//  Created by MACOS on 5/26/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "TrackDownload.h"

@implementation TrackDownload

- (id)initFromURLString:(NSString *)urlString {
    if (self = [super init]) {
        _urlString = urlString;
        _progress = [[NSProgress alloc] init];
        _status = ZASessionTaskStatusInitialized;
        _request = nil;
    }
   
    return self;
}

- (id)initFromURLString:(NSString *)urlString trackName:(NSString *)name {
    if (self = [self initFromURLString:urlString]) {
        _name = name;
    }
    
    return self;
}

- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status {
    switch (_status) {
        case ZASessionTaskStatusInitialized:
            return YES;
            
        case ZASessionTaskStatusRunning:
            return (status == ZASessionTaskStatusPaused) || (status == ZASessionTaskStatusSuccessed) || (status == ZASessionTaskStatusCancelled);
            
        case ZASessionTaskStatusPaused:
            return (status == ZASessionTaskStatusRunning) || (status == ZASessionTaskStatusSuccessed) || (status == ZASessionTaskStatusCancelled);
            
        case ZASessionTaskStatusSuccessed:
        case ZASessionTaskStatusCancelled:
        case ZASessionTaskStatusFailed:
            return NO;
    }
}

@end
