//
//  UCloudMainViewController.m
//  URTC
//
//  Created by ucloud on 2020/10/12.
//  Copyright © 2020 UCloud. All rights reserved.
//

#import "UCloudMainViewController.h"
#import "UCloudRemoteViewItem.h"
#import <UCloudRtcSdk_mac/UCloudRtcSdk_mac.h>

//线上
#error 请到UCloud控台申请< https://docs.ucloud.cn/urtc/quick >
#define APP_ID @""
#define APP_KEY @""

#define Record_Bucket @"urtc-test"
#define Record_Region @"cn-bj"

@interface UCloudMainViewController ()<NSCollectionViewDelegate, NSCollectionViewDataSource, UCloudRtcEngineDelegate>
{
    NSString *_cloudRecordFileName;//云端录制文件名字
}
@property (weak) IBOutlet NSView *localView;
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (weak) IBOutlet NSButton *stopBtn;
@property (weak) IBOutlet NSButton *micBtn;
@property (weak) IBOutlet NSButton *camaroBtn;
@property (strong) IBOutlet NSView *topBarView;
@property (weak) IBOutlet NSTextField *roomLB;
@property (weak) IBOutlet NSTextField *userLB;
@property (weak) IBOutlet NSTextField *timeField;
@property (weak) IBOutlet NSTextField *cloudLB;
@property (weak) IBOutlet NSTextField *desktopLB;
@property (strong) IBOutlet NSView *localScreenView;


@property (nonatomic, strong) dispatch_source_t timer;


@property (nonatomic , strong) UCloudRtcEngine *rtcEngine;
@property (nonatomic, strong) NSMutableArray *canSubstreamList;
@property (nonatomic, strong) NSMutableArray *remoteStreamList;//已订阅远端流
@property (nonatomic, strong) NSMutableArray *collectionViewRenderList;//collectionview渲染列表

@end
static NSString *mainCellID = @"UCloudRemoteViewItemId";

@implementation UCloudMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    _canSubstreamList = [NSMutableArray arrayWithCapacity:0];
    _remoteStreamList = [NSMutableArray arrayWithCapacity:0];
    _collectionViewRenderList = [NSMutableArray arrayWithCapacity:0];
          
    [self setupUI];
        
    
}
- (void)viewDidAppear {
    [super viewDidAppear];
    [self setupTrackArea];
    self.roomLB.stringValue = self.roomId;
    self.userLB.stringValue = self.userId;
    
    // 初始化SDK
    [self initURTC];
    

}
- (void)viewDidLayout {
    [super viewDidLayout];
    [self updateTrackingAreas];
}
- (void)awakeFromNib {
    [super awakeFromNib];
}


- (void)initURTC {
    //初始化engine
    self.rtcEngine = [[UCloudRtcEngine alloc]initWithAppID:APP_ID appKey:APP_KEY completionBlock:^(int errorCode) {}];
    [self.rtcEngine setPreviewMode:(UCloudRtcVideoViewModeScaleAspectFill)];
    //设置远端视频渲染模式
    [self.rtcEngine setRemoteViewMode:UCloudRtcVideoViewModeScaleAspectFit];
    
    self.rtcEngine.roomType = self.roomType;
    
    //指定SDK模式
    self.rtcEngine.engineMode = UCloudRtcEngineModeTrival;
    //设置日志级别
    [self.rtcEngine.logger setLogLevel:UCloudRtcLogLevel_DEBUG];
    //混音相关配置
//    NSString *file = [[NSBundle mainBundle] pathForResource:@"dy" ofType:@"mp3"];
//    self.rtcEngine.fileMix = NO;
//    self.rtcEngine.fileLoop = YES;
//    self.rtcEngine.filePath = file ? file : @"";
//
//    self.rtcEngine.videopath = @"aaa";
//    self.rtcEngine.audiopath = @"bbb";
    NSString *tmpDir = NSTemporaryDirectory();
    tmpDir = [tmpDir substringToIndex:tmpDir.length-1];
//    /var/folders/ml/qfdpk__54fg538n8k47910qm0000gn/T
    NSLog(@"outputpath: %@",tmpDir);
    self.rtcEngine.outputpath = tmpDir;
    self.rtcEngine.openNativeRecord = YES;
//    self.rtcEngine.orientationMode = UCloudRtcOrientationModeLandscapeLeft;

//    self.rtcEngine.reConnectTimes = 30;
//    self.rtcEngine.overTime = 10;

    //设置视频编码格式
    self.rtcEngine.videoDefaultCodec = @"H264";
//    self.rtcEngine.isTrackVolume = YES;
    
    //设置代理
    self.rtcEngine.delegate = self;
//    self.rtcEngine.enableLocalAudio = NO;
//    self.rtcEngine.enableLocalVideo = NO;
    
//    self.rtcEngine.streamProfile = UCloudRtcEngine_StreamProfileDownload;
//    self.rtcEngine.isAutoPublish = false;
    
    NSLog(@"sdk版本号：%@",[UCloudRtcEngine currentVersion]);
       
    //加入房间
    NSString *toekn= @"";// =@"eyJ1c2VyX2lkIjoiMjIiLCJyb29tX2lkIjoiNTk5MTciLCJhcHBfaWQiOiJ1cnRjLWVna2VhbWM1In0=.17bba7b4bb178cd1d6797bb53268b32fb80bbc4915893434785ebb74f6";
    //    加入房间
    [self.rtcEngine joinRoomWithRoomId:self.roomId userId:self.userId token:toekn completionHandler:^(NSDictionary * _Nonnull response, int errorCode) {
      NSLog(@"----加入房间---:%@",response);
      if ([[response valueForKey:@"isRejoin"] boolValue]) {
          NSLog(@"--yj---重连-----");
      } else {
          NSLog(@"--yj---首次-----");
      }
    }];

}
- (void)setupUI {
    [self setupCollectionView];
    
    self.topBarView.wantsLayer = YES;
    self.topBarView.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0.35].CGColor;
    
}

- (void)setupTimer {
    __block int count = 0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
        count ++;
        int seconds = count % 60;
        int minutes = (count / 60) % 60;
        int hours = count / 3600;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timeField.stringValue = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
        });
    });
    dispatch_resume(_timer);
}

- (void)removeTimer {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
}



- (void)mouseEntered:(NSEvent *)event {
    NSDictionary *userInfo = event.trackingArea.userInfo;
    [self updateTrackingAreaWithUserInfo:userInfo eventType:1];
        
}

- (void)mouseExited:(NSEvent *)event {
    NSDictionary *userInfo = event.trackingArea.userInfo;
    [self updateTrackingAreaWithUserInfo:userInfo eventType:2];

}


/// 更新鼠标UI事件
/// @param userInfo userInfo
/// @param type 1：mouseEntered；2：mouseExited
- (void)updateTrackingAreaWithUserInfo:(NSDictionary *)userInfo eventType:(int)type {
    if (userInfo && [userInfo.allKeys containsObject:@"tag"]) {
        int tag = [userInfo[@"tag"] intValue];
        if (tag == 0) {
            self.topBarView.hidden = (type == 1) ? NO : YES;
            
        } else {
            CGFloat value = type == 1 ? 0.65 : 1.0;
            switch (tag) {
                case 1:
                    [self.stopBtn setAlphaValue:value];
                    break;
                case 2:
                    [self.micBtn setAlphaValue:value];
                    break;
                case 3:
                    [self.camaroBtn setAlphaValue:value];
                    break;
                default:
                    break;
            }
        }
        
        
    }
}

-(void)startAnimation:(id)animationTarget endPoint:(NSPoint)endPoint{
    NSRect startFrame = [animationTarget frame];
    NSRect endFrame = NSMakeRect(endPoint.x, endPoint.y, startFrame.size.width, startFrame.size.height);
    
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                
                                animationTarget,NSViewAnimationTargetKey,
                                
                                NSViewAnimationFadeInEffect,NSViewAnimationEffectKey,
                                
                                [NSValue valueWithRect:startFrame],NSViewAnimationStartFrameKey,
                                
                                [NSValue valueWithRect:endFrame],NSViewAnimationEndFrameKey, nil];
    
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dictionary]];
//    animation.delegate = self;
    animation.duration = 2.25;
    //NSAnimationBlocking阻塞
    //NSAnimationNonblocking异步不阻塞
    //NSAnimationNonblockingThreaded线程不阻塞
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation startAnimation];
}


- (void)setupCollectionView {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
//    self.collectionView.selectable = YES;
    
    NSCollectionViewFlowLayout *flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = NSMakeSize(150, 150);
    flowLayout.sectionInset = NSEdgeInsetsMake(0, 0, 0, 0);
    flowLayout.minimumLineSpacing = 10;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    self.collectionView.collectionViewLayout = flowLayout;
    
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"UCloudRemoteViewItem" bundle:nil];
    [self.collectionView registerNib:nib forItemWithIdentifier:mainCellID];
      
}



- (void) updateTrackingAreas
{
    for (NSTrackingArea *trackingArea in self.view.trackingAreas) {
        [self.view removeTrackingArea:trackingArea];
    }
    for (NSTrackingArea *trackingArea in self.stopBtn.trackingAreas) {
        [self.view removeTrackingArea:trackingArea];
    }
    for (NSTrackingArea *trackingArea in self.micBtn.trackingAreas) {
        [self.view removeTrackingArea:trackingArea];
    }
    for (NSTrackingArea *trackingArea in self.camaroBtn.trackingAreas) {
        [self.view removeTrackingArea:trackingArea];
    }
    [self setupTrackArea];
    
}
- (void)setupTrackArea {
    

    NSTrackingArea *viewTrackArea = [[NSTrackingArea alloc] initWithRect:self.localView.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag": @0}];
    [self.view addTrackingArea:viewTrackArea];
    
    
    NSTrackingArea *stopBtnTrackArea = [[NSTrackingArea alloc] initWithRect:self.stopBtn.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag": @1}];
    [self.stopBtn addTrackingArea:stopBtnTrackArea];
    
    NSTrackingArea *micBtnTrackArea = [[NSTrackingArea alloc] initWithRect:self.micBtn.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag": @2}];
    [self.micBtn addTrackingArea:micBtnTrackArea];
    
    NSTrackingArea *camaroBtnTrackArea = [[NSTrackingArea alloc] initWithRect:self.camaroBtn.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag": @3}];
    [self.camaroBtn addTrackingArea:camaroBtnTrackArea];
}

- (IBAction)leaveRoom:(NSButton *)sender {
        
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"确定"];
    [alert addButtonWithTitle:@"取消"];
    alert.messageText = @"提示";
    alert.informativeText = @"你确定要离开房间吗？";
    __weak typeof(self) weakSelf = self;
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            // 释放引擎
            [weakSelf.rtcEngine leaveRoom];
            [weakSelf.rtcEngine distory];
            
            // 销毁定时器
            [weakSelf removeTimer];
            
            [weakSelf.view removeFromSuperview];
            [weakSelf removeFromParentViewController];
            if (weakSelf.leaveRoomComplete) {
                weakSelf.leaveRoomComplete();
            }
            
        } else if (returnCode == NSAlertSecondButtonReturn) {
            NSLog(@"取消");
        } else {
            NSLog(@"else");
        }
    }];
    
    
    
    
    
    
}

- (IBAction)openMicrophone:(NSButton *)sender {
    if (_rtcEngine.enableLocalAudio) {
        [_rtcEngine setMute:sender.state];
    }else{
//        [self.view makeToast:@"音频模块不可用,请在设置页面开启" duration:2 position:CSToastPositionCenter];
    }
    
}

- (IBAction)openCamaro:(NSButton *)sender {
    if (_rtcEngine.enableLocalVideo) {
        [_rtcEngine openCamera:!sender.state];
    }else{
//        [self.view makeToast:@"视频模块不可用,请在设置页面开启" duration:2 position:CSToastPositionCenter];

    }
}

- (IBAction)cloudRecord:(NSButton *)sender {
    if (sender.state == NSControlStateValueOn) {
        self.cloudLB.textColor = [NSColor colorWithRed:190/255.0 green:0 blue:10/255.0 alpha:1];
        self.cloudLB.stringValue = @"录制中...";
        [self startMixPushAndRecord];
    } else {
        self.cloudLB.textColor = [NSColor whiteColor];
        self.cloudLB.stringValue = @"云端录制";
        [self stopMix];
    }
    
//    [_rtcEngine publishWithMediaType:(UCloudRtcStreamMediaTypeScreen)];
}
- (IBAction)shareDesktop:(NSButton *)sender {
    if (sender.state == NSControlStateValueOn) {
        self.desktopLB.textColor = [NSColor colorWithRed:190/255.0 green:0 blue:10/255.0 alpha:1];
        self.desktopLB.stringValue = @"共享中...";
        
        [self.rtcEngine publishWithMediaType:(UCloudRtcStreamMediaTypeScreen)];
    } else {
        self.desktopLB.textColor = [NSColor whiteColor];
        self.desktopLB.stringValue = @"桌面共享";
        [self.rtcEngine unpublishWithMediaType:(UCloudRtcStreamMediaTypeScreen)];
    }
    
}


/// 转推、录制、转推录制、更新
- (void)startMixPushAndRecord {
    UCloudRtcMixConfig *mixConfig = [UCloudRtcMixConfig new];
    mixConfig.type = UCloudRtcMixConfigTypeRecord;
    mixConfig.streams = @[];
    mixConfig.pushurl = @[];
    mixConfig.layout = 1;
    mixConfig.layouts = @[];
    mixConfig.bgColor = @{@"r": @200,@"g": @100, @"b": @50};
    mixConfig.bitrate = 600;
    mixConfig.framerate = 15;
    mixConfig.videocodec = @"h264";
    mixConfig.qualitylevel = @"CB";
    mixConfig.audiocodec = @"aac";
    mixConfig.mainviewtype = 1;
    mixConfig.mainviewuid = self.userId;
    mixConfig.width = 640;
    mixConfig.height = 480;
    mixConfig.bucket = Record_Bucket;
    mixConfig.region = Record_Region;
    mixConfig.watertype = 1;
    mixConfig.waterpos = 1;
    mixConfig.waterurl = @"http://urtc-living-test.cn-bj.ufileos.com/test.png";
    mixConfig.mimetype = 0;
    mixConfig.addstreammode = 1;
    [self.rtcEngine startMix:mixConfig];
}
- (void)stopMix {
    UCloudRtcMixStopConfig *mixStopConfig = [UCloudRtcMixStopConfig new];
    mixStopConfig.type = UCloudRtcMixConfigTypeRecord;
    mixStopConfig.pushurl = @[];
    [self.rtcEngine stopMix: mixStopConfig];
}

- (IBAction)queryMix:(NSButton *)sender {
    [self.rtcEngine queryMix];
}
- (IBAction)addMixStream:(NSButton *)sender {
    NSArray *streams = @[
        @{
            @"user_id":@"xgvg6khk",
            @"media_type":@(UCloudRtcStreamMediaTypeCamera)
        }
    ];
    [self.rtcEngine addMixStream:streams];
}
- (IBAction)deleteMixStream:(NSButton *)sender {
    NSArray *streams = @[
        @{
            @"user_id":@"xgvg6khk",
            @"media_type":@(UCloudRtcStreamMediaTypeCamera)
        }
    ];
    [self.rtcEngine deleteMixStream:streams];
}


#pragma mark ------UCloudRtcEngineDelegate method-----
-(void)uCloudRtcEngineDidJoinRoom:(BOOL)succeed streamList:(NSMutableArray<UCloudRtcStream *> *)canSubStreamList{
    
    
    
}

//新成员加入房间
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager memberDidJoinRoom:(NSDictionary *)memberInfo{
    NSString *message = [NSString stringWithFormat:@"用户:%@ 加入房间",memberInfo[@"user_id"]];
    

}
//成员离开房间
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager memberDidLeaveRoom:(NSDictionary *)memberInfo{
    NSString *message = [NSString stringWithFormat:@"用户:%@ 离开房间",memberInfo[@"user_id"]];
    

}

//非自动订阅模式 新流加入会收到该回调
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager newStreamHasJoinRoom:(UCloudRtcStream *)stream{
//    [self.view makeToast:@"有新的流可以订阅" duration:1.5 position:CSToastPositionCenter];
    [_canSubstreamList addObject:stream];
//    [self.rtcEngine subscribeMethod:stream];
    

}
//非自动订阅模式 新流退出会收到该回调
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager streamHasLeaveRoom:(UCloudRtcStream *)stream{
//    [self.view makeToast:@"可订阅的流离开" duration:1.5 position:CSToastPositionCenter];
    UCloudRtcStream *newS = [UCloudRtcStream new];
    for (UCloudRtcStream *tempS in _canSubstreamList) {
       if ([tempS.streamId isEqualToString:stream.streamId]) {
           newS = tempS;
           break;
       }
    }
    [_canSubstreamList removeObject:newS];
    

}

-(void)localAudioVolumeChange:(int)volume{
    NSLog(@"本地音频音量为:%d",volume);
    

}
-(void)remoteAudioVolumeChange:(int)volume userID:(NSString *)uId{
    NSLog(@"远端流：%@ 音频音量为：%d",uId,volume);
    

}

-(void)uCloudRtcEngine:(UCloudRtcEngine *)channel remoteMute:(NSDictionary *)remoteMuteInfo{
    NSLog(@"remoteMuteInfo==%@",remoteMuteInfo);
    

}
- (void)uCloudRtcEngineDidLeaveRoom:(UCloudRtcEngine *)manager {
    
//    [self.view makeToast:@"退出房间" duration:1.5 position:CSToastPositionCenter];
//    [self dismissViewControllerAnimated:YES completion:^{}];
    NSLog(@"======退出房间");

}

- (void)uCloudRtcEngineDisconnectRoom:(UCloudRtcEngine *)manager {
//    [self.view makeToast:@"房间已断开连接" duration:1.5 position:CSToastPositionCenter];
    

}

- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager streamPublishSucceed:(NSString *)streamId {
    

}

- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager didChangePublishState:(UCloudRtcEnginePublishState)publishState mediaType:(UCloudRtcStreamMediaType)mediaType {
    NSString *titile = @"";
    NSString *tips = @"";
    switch (publishState) {
        case UCloudRtcEnginePublishStateUnPublish:

            titile = @"未发布";
            tips = @"未发布";
            break;
        case UCloudRtcEnginePublishStatePublishing: {
            titile = @"发布中...";
            tips = @"发布中...";
            break;
        }
            
        case UCloudRtcEnginePublishStatePublishSucceed:{
            titile = @"取消发布";
            tips = @"发布成功";
            if (mediaType == UCloudRtcStreamMediaTypeScreen) {
                // FIXME:screen                
                [self.rtcEngine.screenStream renderOnView:self.localScreenView];
            }
            else {
                [self.rtcEngine.localStream renderOnView:self.localView];
                [self setupTimer];
            }
            

            break;
        }
        case UCloudRtcEnginePublishStateRepublishing: {
            titile = tips = @"正在重新发布...";
            break;
        }
        case UCloudRtcEnginePublishStatePublishFailed: {
//            self.isConnected = NO;
            titile = @"重新发布";
            tips = @"发布失败";
            break;
        }
        case UCloudRtcEnginePublishStatePublishStoped: {
//            self.isConnected = NO;
            titile = @"重新发布";
            tips = @"发布已停止";
            if (mediaType == UCloudRtcStreamMediaTypeScreen) {
//                self.blueTestView.hidden = YES;
            }
            break;
        }
        default:
            break;
    }

//    [self.view makeToast:tips duration:1.5 position:CSToastPositionCenter];
    NSLog(@"didChange Camera PublishState--yj---:%@",tips);
    // FIXME:screen
    [self didChangePublishStateWithMediaType:mediaType tittle:titile];
}

- (void)didChangePublishStateWithMediaType:(UCloudRtcStreamMediaType)mediaType tittle:(NSString *)title {
    switch (mediaType) {
        case UCloudRtcStreamMediaTypeCamera:
//            [self.bottomButton setTitle:[NSString stringWithFormat:@"%@摄像",title] forState:UIControlStateNormal];
            break;
        case UCloudRtcStreamMediaTypeScreen:
//            [self.screenBtn setTitle:[NSString stringWithFormat:@"%@桌面",title] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager didConnectFail:(id)data {
    NSLog(@"发布失败:%@",data);
//    self.isConnected = NO;
//    [self.view makeToast:[NSString stringWithFormat:@"发布失败:%@",data ?: @""] duration:.5 position:CSToastPositionCenter];

}

- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager receiveRemoteStream:(UCloudRtcStream *)stream {
    if (stream) {
        [_remoteStreamList addObject:stream];
    }
    [_collectionView reloadData];
    NSLog(@"添加远端流:%@",stream);
}

- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager didRemoveStream:(UCloudRtcStream * _Nonnull)stream{
    UCloudRtcStream *delete = [UCloudRtcStream new];
    for (UCloudRtcStream *obj in _remoteStreamList) {
        if ([obj.userId isEqualToString:stream.userId]) {
            delete = obj;
            break;
        }
    }
    [_remoteStreamList removeObject:delete];
    [_collectionView reloadData];
    
}

- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager error:(UCloudRtcError *)error{
    switch (error.errorType) {
        case UCloudRtcErrorTypeTokenInvalid:
//            [self.view makeToast:[NSString stringWithFormat:@"token无效"] duration:3.0 position:CSToastPositionCenter];
            break;
        case UCloudRtcErrorTypeJoinRoomFail:
//            [self.view makeToast:[NSString stringWithFormat:@"加入房间失败：%@",error.message] duration:3.0 position:CSToastPositionCenter];
            break;
        case UCloudRtcErrorTypeCreateRoomFail:
            break;
        case UCloudRtcErrorTypePublishStreamFail: {
//            self.isConnected = NO;
//            [self.bottomButton setTitle:@"开始发布" forState:UIControlStateNormal];
//            [self.view makeToast:[NSString stringWithFormat:@"发布失败：%@",error.message] duration:3.0 position:CSToastPositionCenter];
        }
            break;
        default:
//            [self.view makeToast:[NSString stringWithFormat:@"错误%ld:%@",(long)error.code,error.message] duration:3.0 position:CSToastPositionCenter];
            break;
    }
    

}
/// 开始录制
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager startMix:(UCloudRtcMixResponse * _Nonnull)mixReponse {
    _cloudRecordFileName = mixReponse.filename;
    if (_cloudRecordFileName) {
        
        NSLog(@"录制文件名字：%@",mixReponse.filename);
    } else {
        NSLog(@"转推id：%@",mixReponse.mixId);
    }
    
}
/// 停止录制
- (void)uCloudRtcEngineDidStopMix:(UCloudRtcEngine *_Nonnull)manager {
    if (!_cloudRecordFileName) {
        return;
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"复制地址"];
    [alert addButtonWithTitle:@"取消"];
    alert.messageText = @"录制地址";
    NSString *fileurl = [NSString stringWithFormat:@"http://%@.%@.ufileos.com/%@.mp4", Record_Bucket, Record_Region, _cloudRecordFileName];
    
//         http://"bucket存储空间名称.region地域.ufileos.com"/"file_name".mp4
    alert.informativeText = fileurl;
//        __weak typeof(self) weakSelf = self;
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
//                 http://"bucket存储空间名称.region地域.ufileos.com"/"file_name".mp4
            NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:@[NSPasteboardTypeString] owner:nil];
            [pasteboard setString:fileurl forType:NSPasteboardTypeString];
//
            
        } else if (returnCode == NSAlertSecondButtonReturn) {
            NSLog(@"取消");
        } else {
            NSLog(@"else");
        }
    }];

}

-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager receiveCustomCommand:(NSString *)fromUserID content:(NSString *)content{
//    [self.view makeToast:[NSString stringWithFormat:@"%@:%@",fromUserID,content] duration:3.0 position:CSToastPositionCenter];
    

}

-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager didReceiveStreamStatus:(NSArray<UCloudRtcStreamStatsInfo *> * _Nonnull)status{
    for (UCloudRtcStreamStatsInfo *info in status) {
        NSLog(@"stream status info :%@",info);
    }
    
//    NSLog(@"current categary:%@", [[AVAudioSession sharedInstance] category]);

}

/// 音量状态回调
/// @param manager UCloudRtcEngine
/// @param audioStatus UCloudRtcAudioStats
-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager didReceiveAudioStatus:(UCloudRtcAudioStats *)audioStatus {
    NSLog(@"audio status info userId:%@,streamId:%@, volume:%ld",audioStatus.userId, audioStatus.streamId,audioStatus.volume);
}


/// 网络质量检测
/// @param manager UCloudRtcEngine
/// @param userId 用户id
/// @param txQuality 上行质量（枚举值）
/// @param rxQuality 下行质量（枚举值）
- (void)uCloudRtcEngine:(UCloudRtcEngine *)manager networkQuality:(NSString *)userId txQuality:(UCloudRtcNetworkQuality)txQuality rxQuality:(UCloudRtcNetworkQuality)rxQuality {
    NSString *txQualityStr;
    NSString *rxQualityStr;
    switch (txQuality) {
        case UCloudRtcNetworkQualityUnknown:
            txQualityStr = @"未知";
            break;
        case UCloudRtcNetworkQualityExcellent:
            txQualityStr = @"优秀";
            break;
        case UCloudRtcNetworkQualityGood:
            txQualityStr = @"良好";
            break;
        case UCloudRtcNetworkQualityPoor:
            txQualityStr = @"一般";
            break;
        case UCloudRtcNetworkQualityPoorer:
            txQualityStr = @"较差";
            break;
        case UCloudRtcNetworkQualityPoorest:
            txQualityStr = @"糟糕";
            break;
        case UCloudRtcNetworkQualityDisconnect:
            txQualityStr = @"连接断开";
            break;
        default:
            break;
    }
   switch (rxQuality) {
        case UCloudRtcNetworkQualityUnknown:
            rxQualityStr = @"未知";
            break;
        case UCloudRtcNetworkQualityExcellent:
            rxQualityStr = @"优秀";
            break;
        case UCloudRtcNetworkQualityGood:
            rxQualityStr = @"良好";
            break;
        case UCloudRtcNetworkQualityPoor:
            rxQualityStr = @"一般";
            break;
        case UCloudRtcNetworkQualityPoorer:
            rxQualityStr = @"较差";
            break;
        case UCloudRtcNetworkQualityPoorest:
            rxQualityStr = @"糟糕";
            break;
        case UCloudRtcNetworkQualityDisconnect:
           rxQualityStr = @"连接断开";
           break;
        default:
            break;
    }
    NSLog(@"userId:%@, 上行网络质量:%@，下行网络质量:%@",userId, txQualityStr, rxQualityStr);
}

-(void)uCloudRtcEngine:(UCloudRtcEngine *)manager connectState:(UCloudRtcConnectState)connectState{
    
    NSLog(@"重连成功");
    if (connectState == UCloudRtcConnectStateReConnected) {
//        [_streamList removeAllObjects];
    }
    [self reloadVideos];
}

- (void)reloadVideos {
//    CGFloat width = (CGRectGetWidth(self.listView.frame) - kHorizontalCount * 5) / kHorizontalCount;
//    CGFloat height = width / 3.0 * 4.0 + 5.0;
//
//    double count = self.streamList.count * 1.0;
//    int row = ceil(count / kHorizontalCount);
//    row = row < 4 ? row : 4;
//
//    self.heightOfListView.constant = height * row;
//    [self.view layoutSubviews];
//
//    [self.listView reloadData];
    
}



#pragma mark -- NSCollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_remoteStreamList count];
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    
    UCloudRemoteViewItem *item = [collectionView makeItemWithIdentifier:mainCellID forIndexPath:indexPath];
    item.streamModel = _remoteStreamList[indexPath.item];

    __weak typeof(self) weakSelf = self;
    item.muteComplete = ^(UCloudRtcStream * _Nonnull stream, int type, BOOL mute) {
        switch (type) {
            case 0:
                [weakSelf.rtcEngine setRemoteStream:stream muteVideo:mute];
                break;
             case 1:
                [weakSelf.rtcEngine setRemoteStream:stream muteAudio:mute];
                break;
            default:
                break;
        }
    };
//    item.imageView = [NSImageView imageViewWithImage:[NSImage imageNamed:@"end"]];
    return item;
}


- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}
@end
