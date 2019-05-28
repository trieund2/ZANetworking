//
//  ZANetworkManager.m
//  ZANetworking
//
//  Created by CPU12166 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ZANetworkManager.h"

NSString * const NetworkStatusDidChangeNotification = @"NetworkStatusDidChangeNotification";
NSString * const NetworkStatusPreviousValue = @"NetworkStatusPreviousValue";
NSString * const NetworkStatusCurrentValue = @"NetworkStatusCurrentValue";

@interface ZANetworkManager ()

@property (strong, nonatomic) Reachability *reach;
@property (assign, nonatomic) NetworkStatus tempNetworkStatus;

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
        self.tempNetworkStatus = self.currentNetworkStatus;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(networkStatusChangedHandler:)
                                                   name:kReachabilityChangedNotification
                                                 object:nil];
    }
    return self;
}

- (void)networkStatusChangedHandler:(NSNotification *)notification {
    NSDictionary *object = @{NetworkStatusPreviousValue : @(self.tempNetworkStatus),
                             NetworkStatusCurrentValue : @(self.currentNetworkStatus)};
    [NSNotificationCenter.defaultCenter postNotificationName:NetworkStatusDidChangeNotification object:object];
    self.tempNetworkStatus = self.currentNetworkStatus;
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
