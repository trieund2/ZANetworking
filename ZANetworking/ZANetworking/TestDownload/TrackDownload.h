//
//  TrackDownload.h
//  ZANetworking
//
//  Created by MACOS on 5/26/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZASessionTaskStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface TrackDownload : NSObject

@property (nonatomic) NSString *urlString;
@property (nonatomic) NSString *name;
@property (nonatomic) NSProgress *progress;
@property (nonatomic) ZASessionTaskStatus status;
@property (nonatomic) NSURLRequest *request;

- (id)initFromURLString:(NSString *)urlString;

- (id)initFromURLString:(NSString *)urlString trackName:(NSString *)name;

- (BOOL)canChangeToStatus:(ZASessionTaskStatus)status;

@end

NS_ASSUME_NONNULL_END
