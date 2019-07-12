//
//  UCloudRtcStream.h
//  UCloudRtcSDK
//
//  Created by tony on 2019/2/23.
//  Copyright © 2019年 ucloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
@class UCloudRtcStreamStatsInfo,UIView;

@interface UCloudRtcStream : NSObject
@property (nonatomic, readonly) NSString *streamId;
@property(nonatomic, readonly) NSString *userId;
@property(nonatomic, assign) BOOL hasSubscribe;//是否被当前用户订阅

/**渲染到指定视图*/
- (void)renderOnView:(NSView *)view;
/**获取流状态信息*/
- (void)getReportStates:(void (^)(UCloudRtcStreamStatsInfo *info))completion;


@end
