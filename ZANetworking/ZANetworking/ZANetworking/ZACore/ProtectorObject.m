//
//  ProtectorObject.m
//  ZANetworking
//
//  Created by CPU12202 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ProtectorObject.h"
#import "pthread.h"

@interface ProtectorObject ()

@property (nonatomic, readonly) pthread_mutex_t protector_mutex;

@end

@implementation ProtectorObject

- (instancetype)initFromObject:(id)object {
    if (self = [super init]) {
        pthread_mutex_init(&(_protector_mutex), NULL);
        _object = object;
    }
    
    return self;
}

- (void)performWithBlock:(void (^)(void))block {
    pthread_mutex_lock(&(_protector_mutex));
    block();
    pthread_mutex_unlock(&(_protector_mutex));
}

@end
