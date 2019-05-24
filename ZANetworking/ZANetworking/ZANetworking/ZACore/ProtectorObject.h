//
//  ProtectorObject.h
//  ZANetworking
//
//  Created by CPU12202 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProtectorObject<ObjectType> : NSObject

@property (nonatomic, readonly) ObjectType object;

- (instancetype)initFromObject:(ObjectType)object;

- (void)aroundWithBlock:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
