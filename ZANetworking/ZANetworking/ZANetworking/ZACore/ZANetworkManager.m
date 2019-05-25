//
//  ZANetworkManager.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZANetworkManager.h"

NSString * const kNetworkStatusDidChangeNotification = @"kNetworkStatusDidChangeNotification";

@interface ZANetworkManager ()

@property (strong, nonatomic) Reachability *reach;

@end

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
        self.reach = Reachability.reachabilityForInternetConnection;
        [self.reach startNotifier];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(networkStatusChangedHandler:)
                                                   name:kReachabilityChangedNotification
                                                 object:nil];
    }
    return self;
}

- (void)networkStatusChangedHandler:(NSNotification *)notification {
    [NSNotificationCenter.defaultCenter postNotificationName:kNetworkStatusDidChangeNotification object:nil];
}

- (NetworkStatus)currentNetworkStatus {
    return self.reach.currentReachabilityStatus;
}

- (NSString *)currentNetworkStatusString {
    return self.reach.currentReachabilityString;
}

- (BOOL)isConnectionAvailable {
    return self.currentNetworkStatus != NotReachable;
}

@end
