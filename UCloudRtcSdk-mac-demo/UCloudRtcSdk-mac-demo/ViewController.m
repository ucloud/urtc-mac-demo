//
//  ViewController.m
//  UCloudRtcSdk-mac-demo
//
//  Created by Tony on 2019/7/11.
//  Copyright © 2019 Tony. All rights reserved.
//
//线上
#define APP_ID @"URtc-h4r1txxy"
#define APP_KEY @"9129304dbf8c5c4bf68d70824462409f"

#import "ViewController.h"
#import <UCloudRtcSdk_mac/UCloudRtcSdk_mac.h>

#define VIDEO_WIDTH 600
#define VIDEO_HEIGHT 600

@interface ViewController ()<UCloudRtcEngineDelegate>
@property (weak) IBOutlet NSView *localVideoView;//本地视频
@property (weak) IBOutlet NSButton *joinButton;//加入房间
@property (weak) IBOutlet NSButton *publishButton;//发布
@property (weak) IBOutlet NSButton *sdkSetButton;//sdk设置
@property (weak) IBOutlet NSButton *switchButton;//切换摄像头
@property (weak) IBOutlet NSButton *muteMicButton;//静音
@property (weak) IBOutlet NSButton *listButton;//d可手动订阅的流列表

@property (weak) IBOutlet NSView *remoteView;
@property (weak) IBOutlet NSView *remoteView2;
@property (weak) IBOutlet NSView *remoteView3;
@property (weak) IBOutlet NSView *remoteView4;
@property (weak) IBOutlet NSView *remoteView5;

@property(nonatomic, strong) UCloudRtcEngine *engine;
@property(nonatomic, strong) NSMutableArray *allRemoteView;//渲染远程视频的视图
@property(nonatomic, strong) NSMutableArray *allRemoteStream;//所有远程流

@property(nonatomic, assign) bool bJoined;
@property(nonatomic, assign) bool bPublished;
@property(nonatomic, assign) bool bPublishedDesktop;

@property(nonatomic, assign) bool bStopCamera;
@property(nonatomic, assign) bool bMute;
@end

@implementation ViewController

{
    __weak IBOutlet NSTextField *roomField;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.bPublishedDesktop = NO;
    self.allRemoteView = [NSMutableArray array];
    self.allRemoteStream = [NSMutableArray array];
    [self.allRemoteView addObject:_remoteView];
    [self.allRemoteView addObject:_remoteView2];
    [self.allRemoteView addObject:_remoteView3];
    [self.allRemoteView addObject:_remoteView4];
    [self.allRemoteView addObject:_remoteView5];
    [UCloudRtcEngine setLogEnable:YES];
}

///选择是发布桌面还是摄像头 默认摄像头
- (IBAction)selectedDeskOrCam:(NSSegmentedControl *)sender {
    switch (sender.selectedSegment) {
        case 0:
            self.bPublishedDesktop = NO;
            break;
         case 1:
            self.bPublishedDesktop = YES;
            break;
        default:
            break;
    }
}


- (IBAction)joinRoom:(id)sender {

    if (self.bJoined == false && [roomField.stringValue isEqualToString:@""]) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert addButtonWithTitle:@"Ok"];
        alert.messageText = @"请输入房间号!";
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode){
            if(returnCode == NSAlertFirstButtonReturn){
                NSLog(@"请输入房间号!");
            }
        }];
        return;
    }
    if(self.bJoined == false)
    {
        _localVideoView.layer.backgroundColor = [NSColor blackColor].CGColor;
        
        self.engine = [[UCloudRtcEngine alloc]initWithUserId:[self getUserId] appId:APP_ID roomId:roomField.stringValue appKey:APP_KEY token:@""];
        self.engine.engineMode = UCloudRtcEngineModeTrival;
        self.engine.delegate = self;
        self.engine.isAutoPublish = YES;
        self.engine.isAutoSubscribe = YES;
        self.engine.isDesktop = self.bPublishedDesktop;
        [self.engine setLocalPreview:_localVideoView];
        [self.engine joinRoomWithcompletionHandler:^(NSData * _Nonnull data, NSURLResponse * _Nonnull response, NSError * _Nonnull error) {}];
        
        self.bJoined = true;
        self.joinButton.title = @"退出房间";
    }
    else if(self.engine!=nil && self.bJoined == true){
        [self.engine leaveRoom];
        self.bJoined = false;
        self.bPublished = false;
        self.bPublishedDesktop = false;
        self.joinButton.title = @"加入房间";
    }
}

- (void)startPublish:(id)sender
{
    if(self.bJoined == false )
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"提示" defaultButton:@"明白" alternateButton:nil otherButton:nil informativeTextWithFormat:@"请先加入房间"];
        [alert runModal];
        return;
    }
    
    if(self.engine!=nil && self.bPublished == false)
    {
        [self.engine publish];
        self.bPublished = true;
        self.publishButton.title = @"停止发布";
    }else
    {
        [self.engine unPublish];
        self.bPublished = false;
        self.publishButton.title = @"开始发布";
    }
}

- (IBAction)stopCamera:(id)sender
{
    if(self.engine!=nil && self.bStopCamera == false)
    {
        self.bStopCamera = true;
        [self.engine openCamera:NO];
        self.switchButton.title = @"打开摄像头";
    }else if(self.engine!=nil && self.bStopCamera == true)
    {
        self.bStopCamera = false;
        self.switchButton.title = @"关闭摄像头";
        [self.engine openCamera:YES];
    }
}

- (IBAction)startMute:(id)sender
{
    if(self.engine!=nil && self.bMute == false)
    {
        self.bMute = true;
        [self.engine setMute:YES];
        self.muteMicButton.title = @"打开声音";
    }else if(self.engine!=nil && self.bMute == true)
    {
        self.bMute = false;
        [self.engine setMute:NO];
        self.muteMicButton.title = @"静音";
    }
}

- (NSString *)getUserId {
    NSString* userId = [NSString stringWithFormat:@"%d",arc4random()%1000];
    return userId;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark UCloudRtcEngineDelegate
//加入房间成功 手动订阅模式下 canSubStreamList 会包含可订阅的流列表
-(void)uCloudRtcEngineDidJoinRoom:(NSMutableArray<UCloudRtcStream *> *)canSubStreamList{
    self.bJoined = YES;
}
//收到远程流
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager receiveRemoteStream:(UCloudRtcStream *)stream{
    [self.allRemoteStream addObject:stream];
    for (NSView *view  in self.allRemoteView) {
        if (view.hidden == YES) {
            [stream renderOnView:view];
            view.hidden = NO;
            view.toolTip = stream.userId;
            [view addToolTipRect:view.bounds owner:view userData:nil];
            break;
        }
    }
}

-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager didRemoveStream:(UCloudRtcStream *)stream{
    [self.allRemoteStream removeObject:stream];
    
    for (NSView *view in self.allRemoteView) {
        if ([view.toolTip isEqualToString:stream.userId]) {
            view.hidden = YES;
            for (NSView *subview  in [view subviews]) {
                [subview removeFromSuperview];
            }
        }
    }
}

-(void)uCloudRtcEngineDidLeaveRoom:(UCloudRtcEngine *)manager{
    NSLog(@"DidLeaveRoom!!!!!!!!!!!!!");
    
    for (NSView *view  in [self.localVideoView subviews]) {
        [view removeFromSuperview];
    }
    for (NSView *view  in self.allRemoteView) {
        view.hidden = YES;
        for (NSView *subview  in [view subviews]) {
            [subview removeFromSuperview];
        }
    }

    [self.allRemoteStream removeAllObjects];
}
@end
