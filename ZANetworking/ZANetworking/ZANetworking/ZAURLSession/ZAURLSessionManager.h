//
//  ZAURLSessionManager.h
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZAURLSessionManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)downloadTaskFromURLString:(NSString *)urlString
                                headers:(NSDictionary *)header;

@end

NS_ASSUME_NONNULL_END
