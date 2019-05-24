//
//  NSURL+URIEquivalence.m
//  ZANetworking
//
//  Created by CPU12202 on 5/24/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "NSURL+URIEquivalence.h"

@implementation NSURL (URIEquivalence)

- (BOOL)isEquivalent:(NSURL *)aURL {
    if ([self isEqual:aURL]) { return YES; }
    
    if ([[self scheme] caseInsensitiveCompare:[aURL scheme]] != NSOrderedSame) { return NO; }
    
    if ([[self host] caseInsensitiveCompare:[aURL host]] != NSOrderedSame) { return NO; }
    
    if ([[self path] compare:[aURL path]] != NSOrderedSame) { return NO; }
    
    if ([self port] || [aURL port]) {
        if (![[self port] isEqual:[aURL port]]) { return NO; }
        if (![[self query] isEqual:[aURL query]]) { return NO; }
    }

    return YES;
}

@end
