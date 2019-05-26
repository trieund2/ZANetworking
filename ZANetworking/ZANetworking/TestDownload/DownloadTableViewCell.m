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

@end

#pragma mark - Init

@implementation DownloadTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

#pragma mark: - Interface methods

- (void)configCellByTrackDownload:(TrackDownload *)trackDownload indexPath:(NSIndexPath *)indexPath {
    self.currentIndexPath = indexPath;
    self.trackNameLabel.text = trackDownload.name;
    
    if (trackDownload.progress.totalUnitCount != 0) {
        CGFloat progress = (CGFloat)trackDownload.progress.completedUnitCount / (CGFloat)trackDownload.progress.totalUnitCount;
        [self.progressView setProgress:progress];
        self.percentDownloadLabel.text = [NSString stringWithFormat:@"%0.1f%%", progress * 100];
    }
    
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
            self.downloadStatusLabel.text = @"Cancel";
            [self.startDownloadButton setEnabled:YES];
            [self.pauseButton setEnabled:NO];
            [self.cancelButton setEnabled:NO];
            break;
            
        case ZASessionTaskStatusCompleted:
            self.downloadStatusLabel.text = @"Complete";
            [self.startDownloadButton setEnabled:YES];
            [self.pauseButton setEnabled:NO];
            [self.cancelButton setEnabled:NO];
            break;
            
        default:
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
        [self.delegate didSelectPauseAtIndexPath:self.currentIndexPath];
    }
}

- (IBAction)tapOnCancel:(id)sender {
    if ([self.delegate conformsToProtocol:@protocol(DownloadTableViewCellDelegate)]) {
        [self.delegate didSelectCancelAtIndexPath:self.currentIndexPath];
    }
}

@end
