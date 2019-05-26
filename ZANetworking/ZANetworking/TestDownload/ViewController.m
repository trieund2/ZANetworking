//
//  ViewController.m
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ViewController.h"
#import "ZANetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testDownload];
}

- (void)testDownload {
    NSString *urlString = @"https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/Music6/v4/68/34/f1/6834f1f8-8fdb-4247-492a-c0caea580082/mzaf_3920281300599106672.plus.aac.p.m4a";
    [ZASessionManager.sharedManager downloadTaskFromURLString:urlString headers:NULL priority:(ZADownloadPriorityMedium) progressBlock:^(NSProgress * progress) {
        double percent = progress.completedUnitCount;
        NSLog(@"%f", percent);
    } destinationBlock:^NSURL *(NSURL *targetPath) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                              inDomain:NSUserDomainMask
                                                                     appropriateForURL:nil
                                                                                create:NO
                                                                                 error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:@"musicfilename"];
    } completionBlock:^(NSURLResponse *response, NSError *error) {
        
    }];
}

@end
