//
//  DownloadTableViewCell.h
//  ZANetworking
//
//  Created by MACOS on 5/26/19.
//  Copyright © 2019 com.trieund. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackDownload.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DownloadTableViewCellDelegate <NSObject>

@required
- (void)didSelectDownloadAtIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectPauseAtIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectResumeAtIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectCancelAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface DownloadTableViewCell : UITableViewCell

@property (weak, nonatomic) id<DownloadTableViewCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *startDownloadButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *downloadStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *percentDownloadLabel;

- (void)configCellByTrackDownload:(TrackDownload *)trackDownload indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
