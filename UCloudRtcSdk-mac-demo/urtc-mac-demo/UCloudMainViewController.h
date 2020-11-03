//
//  UCloudMainViewController.h
//  URTC
//
//  Created by ucloud on 2020/10/12.
//  Copyright © 2020 UCloud. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LeaveRoomComplete)(void);

@interface UCloudMainViewController : NSViewController
@property (strong) NSString *roomId;
@property (strong) NSString *userId;
@property (assign) NSInteger roomType;

@property (copy) LeaveRoomComplete leaveRoomComplete;
@end

NS_ASSUME_NONNULL_END
