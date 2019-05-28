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
    TrackDownload *track6 = [[TrackDownload alloc] initFromURLString:@"https://download.microsoft.com/download/8/7/D/87D36A01-1266-4FD3-924C-1F1F958E2233/Office2010DevRefs.exe" trackName:@"Test file 50MB microsoft"];
    TrackDownload *track7 = [[TrackDownload alloc] initFromURLString:@"https://download.microsoft.com/download/B/1/7/B1783FE9-717B-4F78-A39A-A2E27E3D679D/ENU/x64/spPowerPivot16.msi" trackName:@"Test file 100MB microsoft"];
    TrackDownload *track8 = [[TrackDownload alloc] initFromURLString:@"https://download.microsoft.com/download/8/b/2/8b2347d9-9f9f-410b-8436-616f89c81902/WindowsServer2003.WindowsXP-KB914961-SP2-x64-ENU.exe" trackName:@"Test file 350MB microsoft"];

    [self.trackDownloads addObjectsFromArray:@[track1, track2, track3, track4, track5, track6, track7, track8]];
    
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
