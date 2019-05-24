//
//  ZANetworkManager.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZANetworkManager.h"

@implementation ZANetworkManager

+ (instancetype)sharedInstance {
    static ZANetworkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZANetworkManager alloc] initSingleton];
    });
    return sharedInstance;
}

- (instancetype)initSingleton {
    if (self = [super init]) {
        
    }
    return self;
}

@end
