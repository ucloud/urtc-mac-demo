//
//  UCloudRemoteViewItem.m
//  URTC
//
//  Created by ucloud on 2020/10/12.
//  Copyright © 2020 UCloud. All rights reserved.
//

#import "UCloudRemoteViewItem.h"
#import <UCloudRtcSdk_mac/UCloudRtcStream.h>
@interface UCloudRemoteViewItem ()
@property (weak) IBOutlet NSView *remoteView;

@end

@implementation UCloudRemoteViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    
}

- (void)setStreamModel:(UCloudRtcStream *)streamModel {
    _streamModel = streamModel;
    
    [streamModel renderOnView:self.remoteView];

}

- (IBAction)camaroClick:(NSButton *)sender {
    if (self.muteComplete) {
        self.muteComplete(self.streamModel, 0, !sender.state);
    }
}

- (IBAction)micClick:(NSButton *)sender {
    if (self.muteComplete) {
        self.muteComplete(self.streamModel, 1, !sender.state);
    }
}

- (void)dealloc {
    NSLog(@"------%@ dealloc-----",self);
    
}
@end
