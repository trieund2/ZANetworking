//
//  NSURL+URIEquivalence.h
//  ZANetworking
//
//  Created by CPU12202 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (URIEquivalence)

- (BOOL)isEquivalent:(NSURL *)aURL;

@end

NS_ASSUME_NONNULL_END
