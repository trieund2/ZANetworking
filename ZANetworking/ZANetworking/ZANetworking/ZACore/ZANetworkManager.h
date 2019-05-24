//
//  ZANetworkManager.h
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

FOUNDATION_EXPORT NSString * const kNetworkStatusDidChangeNotification;

@interface ZANetworkManager : NSObject

/* Make init private. Use sharedInstance instead. */
- (instancetype)init NS_UNAVAILABLE;

/* Return singleton. */
+ (instancetype)sharedInstance;

- (NetworkStatus)currentNetworkStatus;

- (NSString *)currentNetworkStatusString;

@end
