//
//  UCloudRemoteViewItem.h
//  URTC
//
//  Created by ucloud on 2020/10/12.
//  Copyright © 2020 UCloud. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN
@class UCloudRtcStream;

/**
 type   0: 为摄像头
    1: 麦克风
 */
typedef void(^UCloudRtcMuteComplete)(UCloudRtcStream *stream, int type, BOOL mute);

@interface UCloudRemoteViewItem : NSCollectionViewItem

@property (nonatomic, strong) UCloudRtcStream *streamModel;

@property (strong, nonatomic) UCloudRtcMuteComplete muteComplete;

@end

NS_ASSUME_NONNULL_END
