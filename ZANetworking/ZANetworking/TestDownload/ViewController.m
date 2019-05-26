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
    
    TrackDownload *track1 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/hismart-d1acf.appspot.com/o/Dung-Yeu-Nua-Em-Met-Roi-MIN.mp3?alt=media&token=c396378c-a166-4f26-950e-48eeefec13a6" trackName:@"Đừng yên nữa em mệt rồi"];
    TrackDownload *track2 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/hismart-d1acf.appspot.com/o/Best%20Music%20Mix%202019%20%E2%99%AB%E2%99%AB%20Gaming%20Music%20%E2%99%AB%20Trap%20House%20Dubstep%20EDM.mp3?alt=media&token=95f7bce8-9cbd-41f5-a578-31439037724f" trackName:@"Music Mix"];
    TrackDownload *track3 = [[TrackDownload alloc] initFromURLString:@"https://firebasestorage.googleapis.com/v0/b/hismart-d1acf.appspot.com/o/Best%20Music%20Mix%202019%20%E2%99%AB%E2%99%AB%20Gaming%20Music%20%E2%99%AB%20Trap%20House%20Dubstep%20EDM.mp3?alt=media&token=95f7bce8-9cbd-41f5-a578-31439037724f" trackName:@"Music Mix"];
    
    [self.trackDownloads addObject:track1];
    [self.trackDownloads addObject:track2];
    [self.trackDownloads addObject:track3];
    
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
        trackDownload.status = ZASessionTaskStatusCompleted;
    }];
}

- (void)didSelectPauseAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)didSelectResumeAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)didSelectCancelAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
