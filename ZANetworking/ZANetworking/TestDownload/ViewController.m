//
//  ViewController.m
//  ZANetworking
//
//  Created by CPU12202 on 5/23/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "ViewController.h"
#import "ZANetworking.h"
#import "TrackDownload.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *downloadTableView;
@property (nonatomic) NSMutableArray<TrackDownload *> *trackDownloads;
@property (nonatomic) NSMutableDictionary<NSString *, TrackDownload *> *currentDownload;
@end

@implementation ViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    _currentDownload = [[NSMutableDictionary alloc] init];
    [self initDownloadTableView];
    [self initDataSource];
}

#pragma mark - Init

- (void)initDownloadTableView {
    UINib *downloadNib = [UINib nibWithNibName:@"DownloadTableViewCell" bundle:NULL];
    [self.downloadTableView registerNib:downloadNib forCellReuseIdentifier:@"DownloadTableViewCell"];
    self.downloadTableView.delegate = self;
    self.downloadTableView.dataSource = self;
}

- (void)initDataSource {
    _trackDownloads = [[NSMutableArray alloc] init];
    
    TrackDownload *track1 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/100MB.bin" trackName:@"Test file 100MB"];
    TrackDownload *track2 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/100MB.bin" trackName:@"Test file 100MB"];
    TrackDownload *track3 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/100MB.bin" trackName:@"Test file 100MB"];
    TrackDownload *track4 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/100MB.bin" trackName:@"Test file 100MB"];
    TrackDownload *track5 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/1GB.bin" trackName:@"Test file 1GB"];
    TrackDownload *track6 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/1GB.bin" trackName:@"Test file 1GB"];

    [self.trackDownloads addObject:track1];
    [self.trackDownloads addObject:track2];
    [self.trackDownloads addObject:track3];
    [self.trackDownloads addObject:track4];
    [self.trackDownloads addObject:track5];
    [self.trackDownloads addObject:track6];
    
    [self.downloadTableView reloadData];
}

#pragma mark - Helper

- (NSURL *)localFilePathForURL:(NSURL *)url {
    NSURL *documentsPath = [NSFileManager.defaultManager URLsForDirectory:(NSDocumentationDirectory) inDomains:(NSUserDomainMask)].firstObject;
    return [documentsPath URLByAppendingPathComponent:url.lastPathComponent];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.trackDownloads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadTableViewCell"];
    cell.delegate = self;
    TrackDownload *trackDownload = [self.trackDownloads objectAtIndex:indexPath.row];
    [cell configCellByTrackDownload:trackDownload indexPath:indexPath];
    return cell;
}

#pragma mark - DownloadTableViewCellDelegate

- (void)didSelectDownloadAtIndexPath:(NSIndexPath *)indexPath {
    TrackDownload *trackDownload = [self.trackDownloads objectAtIndex:indexPath.row];
    if (nil == trackDownload) { return; }
    __weak typeof(self) weakSelf = self;
    
    NSString *identifier = [ZASessionManager.sharedManager downloadTaskFromURLString:trackDownload.urlString headers:NULL priority:(ZADownloadPriorityMedium) progressBlock:^(NSProgress * progress, NSString *callBackIdentifier) {
        
        TrackDownload *currentTrackDownload = [weakSelf.currentDownload objectForKey:callBackIdentifier];
        if (currentTrackDownload) {
            NSUInteger index = [weakSelf.trackDownloads indexOfObject:currentTrackDownload];
            currentTrackDownload.progress = progress;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                DownloadTableViewCell *cell = [weakSelf.downloadTableView cellForRowAtIndexPath:indexPath];
                [cell configCellByTrackDownload:currentTrackDownload indexPath:indexPath];
            });
        }
    } destinationBlock:^NSURL *(NSURL *location, NSString *callBackIdentifier) {
        return [self localFilePathForURL:[NSURL URLWithString:trackDownload.urlString]];
    } completionBlock:^(NSURLResponse *response, NSError *error, NSString *callBackIdentifier) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            TrackDownload *currentTrackDownload = [weakSelf.currentDownload objectForKey:callBackIdentifier];
            
            if (error) {
                currentTrackDownload.status = ZASessionTaskStatusFailed;
            } else {
                [weakSelf.currentDownload removeObjectForKey:callBackIdentifier];
                currentTrackDownload.status = ZASessionTaskStatusSuccessed;
            }
            
            if (currentTrackDownload) {
                NSUInteger index = [weakSelf.trackDownloads indexOfObject:currentTrackDownload];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    DownloadTableViewCell *cell = [weakSelf.downloadTableView cellForRowAtIndexPath:indexPath];
                    [cell configCellByTrackDownload:currentTrackDownload indexPath:indexPath];
                });
            }
        });
    }];
    
    trackDownload.identifier = identifier;
    trackDownload.status = ZASessionTaskStatusRunning;
    self.currentDownload[identifier] = trackDownload;
    [self.downloadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)didSelectPauseAtIndexPath:(NSIndexPath *)indexPath {
    TrackDownload *trackDownload = [self.trackDownloads objectAtIndex:indexPath.row];
    if (nil == trackDownload) { return; }
    
    [ZASessionManager.sharedManager pauseDownloadTaskByIdentifier:trackDownload.identifier];
    trackDownload.status = ZASessionTaskStatusPaused;
    
    [self.downloadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)didSelectResumeAtIndexPath:(NSIndexPath *)indexPath {
    TrackDownload *trackDownload = [self.trackDownloads objectAtIndex:indexPath.row];
    if (nil == trackDownload) { return; }
    
    [ZASessionManager.sharedManager resumeDownloadTaskByIdentifier:trackDownload.identifier];
    trackDownload.status = ZASessionTaskStatusRunning;
    [self.downloadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)didSelectCancelAtIndexPath:(NSIndexPath *)indexPath {
    TrackDownload *trackDownload = [self.trackDownloads objectAtIndex:indexPath.row];
    if (nil == trackDownload) { return; }
    
    [ZASessionManager.sharedManager cancelDownloadTaskByIdentifier:trackDownload.identifier];
    trackDownload.status = ZASessionTaskStatusCancelled;
    [self.downloadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

@end
