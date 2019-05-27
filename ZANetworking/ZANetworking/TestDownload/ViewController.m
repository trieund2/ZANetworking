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
@property (nonatomic) NSMutableDictionary<NSURLRequest *, TrackDownload *> *currentDownload;
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
    
    TrackDownload *track1 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/bustracking-1524793108793.appspot.com/o/Dung-Yeu-Nua-Em-Met-Roi-MIN.mp3?alt=media&token=6c7578e0-a8cf-4a7b-988f-b719e013b50d" trackName:@"Đừng yên nữa em mệt rồi"];
    TrackDownload *track2 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/bustracking-1524793108793.appspot.com/o/30%20Minute%20Deep%20Sleep%20Music%20Calming%20Music%20Relaxing%20Music%20Soothing%20Music%20Calming%20Music%20%E2%98%AF426B.mp3?alt=media&token=6ffe629d-f6b3-42a6-830a-116cb6224e17" trackName:@"30 Minute Deep Sleep Music"];
    TrackDownload *track3 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/bustracking-1524793108793.appspot.com/o/30%20Minute%20Deep%20Sleep%20Music%20Calming%20Music%20Relaxing%20Music%20Soothing%20Music%20Calming%20Music%20%E2%98%AF426B.mp3?alt=media&token=6ffe629d-f6b3-42a6-830a-116cb6224e17" trackName:@"30 Minute Deep Sleep Music"];
    TrackDownload *track4 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/bustracking-1524793108793.appspot.com/o/30%20Minute%20Deep%20Sleep%20Music%20Calming%20Music%20Relaxing%20Music%20Soothing%20Music%20Calming%20Music%20%E2%98%AF426B.mp3?alt=media&token=6ffe629d-f6b3-42a6-830a-116cb6224e17" trackName:@"30 Minute Deep Sleep Music"];
    TrackDownload *track5 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/bustracking-1524793108793.appspot.com/o/30%20Minute%20Deep%20Sleep%20Music%20Calming%20Music%20Relaxing%20Music%20Soothing%20Music%20Calming%20Music%20%E2%98%AF426B.mp3?alt=media&token=6ffe629d-f6b3-42a6-830a-116cb6224e17" trackName:@"30 Minute Deep Sleep Music"];
    
    TrackDownload *track6 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/100MB.bin" trackName:@"Test file 100MB"];
    TrackDownload *track7 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/1GB.bin" trackName:@"Test file 1GB"];
    TrackDownload *track8 = [[TrackDownload alloc] initFromURLString:@"https://speed.hetzner.de/10GB.bin" trackName:@"Test file 10GB"];
    
    [self.trackDownloads addObject:track1];
    [self.trackDownloads addObject:track2];
    [self.trackDownloads addObject:track3];
    [self.trackDownloads addObject:track4];
    [self.trackDownloads addObject:track5];
    [self.trackDownloads addObject:track6];
    [self.trackDownloads addObject:track7];
    [self.trackDownloads addObject:track8];
    
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
    __weak typeof(self) weakSelf = self;
    TrackDownload *trackDownload = [self.trackDownloads objectAtIndex:indexPath.row];
    if (nil == trackDownload) { return; }
    
    [ZASessionManager.sharedManager downloadTaskFromURLString:trackDownload.urlString headers:NULL priority:(ZADownloadPriorityMedium) progressBlock:^(NSProgress * progress) {
        trackDownload.progress = progress;
        trackDownload.status = ZASessionTaskStatusRunning;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.downloadTableView reloadData];
        });
    } destinationBlock:^NSURL *(NSURL *location) {
        return [self localFilePathForURL:[NSURL URLWithString:trackDownload.urlString]];
    } completionBlock:^(NSURLResponse *response, NSError *error) {
        trackDownload.status = ZASessionTaskStatusSuccessed;
    }];
}

- (void)didSelectPauseAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)didSelectResumeAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)didSelectCancelAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
