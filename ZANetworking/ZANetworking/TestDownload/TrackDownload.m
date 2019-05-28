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
        _identifier = nil;
        _priority = ZADownloadPriorityHigh;
    }
   
    return self;
}

- (id)initFromURLString:(NSString *)urlString trackName:(NSString *)name {
    if (self = [self initFromURLString:urlString]) {
        _name = name;
    }
    
    return self;
}

- (id)initFromURLString:(NSString *)urlString trackName:(NSString *)name priority:(ZADownloadPriority)priority {
    if (self = [self initFromURLString:urlString trackName:name]) {
        _priority = priority;
    }
    
    return self;
}

@end
