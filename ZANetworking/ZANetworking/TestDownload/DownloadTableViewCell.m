//
//  DownloadTableViewCell.m
//  ZANetworking
//
//  Created by MACOS on 5/26/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import "DownloadTableViewCell.h"

@interface DownloadTableViewCell ()

@property (nonatomic) NSIndexPath *currentIndexPath;
@property (nonatomic) TrackDownload *trackDownload;
@end

#pragma mark - Init

@implementation DownloadTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

#pragma mark: - Interface methods

- (void)configCellByTrackDownload:(TrackDownload *)trackDownload indexPath:(NSIndexPath *)indexPath {
    self.trackDownload = trackDownload;
    self.currentIndexPath = indexPath;
    self.trackNameLabel.text = trackDownload.name;
    
    if (trackDownload.progress.totalUnitCount != 0) {
        CGFloat progress = (CGFloat)trackDownload.progress.completedUnitCount / (CGFloat)trackDownload.progress.totalUnitCount;
        self.progressView.progress = progress;
        self.percentDownloadLabel.text = [NSString stringWithFormat:@"%0.1f%%", progress * 100];
    } else {
        self.progressView.progress = 0;
        self.percentDownloadLabel.text = @"0%";
    }
    
    [self.pauseButton setTitle:@"Pause" forState:(UIControlStateNormal)];
    
    switch (trackDownload.status) {
        case ZASessionTaskStatusInitialized:
            self.downloadStatusLabel.text = @"Init";
            [self.startDownloadButton setEnabled:YES];
            [self.pauseButton setEnabled:NO];
            [self.cancelButton setEnabled:NO];
            break;
        
        case ZASessionTaskStatusRunning:
            self.downloadStatusLabel.text = @"Running";
            [self.startDownloadButton setEnabled:NO];
            [self.pauseButton setEnabled:YES];
            [self.cancelButton setEnabled:YES];
            break;
            
        case ZASessionTaskStatusPaused:
            self.downloadStatusLabel.text = @"Pause";
            [self.startDownloadButton setEnabled:NO];
            [self.pauseButton setEnabled:YES];
            [self.pauseButton setTitle:@"Resume" forState:(UIControlStateNormal)];
            [self.cancelButton setEnabled:YES];
            break;
         
        case ZASessionTaskStatusCancelled:
            self.progressView.progress = 0;
            self.percentDownloadLabel.text = @"0%";
            self.downloadStatusLabel.text = @"Cancel";
            [self.startDownloadButton setEnabled:YES];
            [self.pauseButton setEnabled:NO];
            [self.cancelButton setEnabled:NO];
            break;
            
        case ZASessionTaskStatusSuccessed:
            self.progressView.progress = 1;
            self.percentDownloadLabel.text = @"100%";
            self.downloadStatusLabel.text = @"Complete";
            [self.startDownloadButton setEnabled:YES];
            [self.pauseButton setEnabled:NO];
            [self.cancelButton setEnabled:NO];
            break;
            
        case ZASessionTaskStatusFailed:
            self.downloadStatusLabel.text = @"Fail";
            [self.startDownloadButton setEnabled:NO];
            [self.pauseButton setEnabled:YES];
            [self.pauseButton setTitle:@"Try again" forState:(UIControlStateNormal)];
            [self.cancelButton setEnabled:YES];
            break;
    }
}

#pragma mark - UIActions

- (IBAction)tapOnDownload:(id)sender {
    if ([self.delegate conformsToProtocol:@protocol(DownloadTableViewCellDelegate)]) {
        [self.delegate didSelectDownloadAtIndexPath:self.currentIndexPath];
    }
}

- (IBAction)tapOnPause:(id)sender {
    if ([self.delegate conformsToProtocol:@protocol(DownloadTableViewCellDelegate)]) {
        if (self.trackDownload.status == ZASessionTaskStatusPaused) {
            [self.delegate didSelectResumeAtIndexPath:self.currentIndexPath];
        } else {
            [self.delegate didSelectPauseAtIndexPath:self.currentIndexPath];
        }
        
    }
}

- (IBAction)tapOnCancel:(id)sender {
    if ([self.delegate conformsToProtocol:@protocol(DownloadTableViewCellDelegate)]) {
        [self.delegate didSelectCancelAtIndexPath:self.currentIndexPath];
    }
}

@end
