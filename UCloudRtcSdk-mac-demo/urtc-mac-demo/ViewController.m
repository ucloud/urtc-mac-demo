//
//  ViewController.m
//  URTC
//
//  Created by ucloud on 2020/9/9.
//  Copyright © 2020 UCloud. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UCloudMainViewController.h"

@interface ViewController ()
@property (weak) IBOutlet NSView *centerView;
@property (weak) IBOutlet NSTextField *roomTf;
@property (weak) IBOutlet NSTextField *userTf;
@property (weak) IBOutlet NSSegmentedControl *segControl;
@property (weak) IBOutlet NSButton *joinBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    

    
}
- (void)viewWillAppear
{
    [super viewWillAppear];
    self.view.window.restorable = NO;
    [self.view.window setContentSize:NSMakeSize(1000, 600)];
    
}

- (void)viewWillLayout{
    [super viewWillLayout];
    self.view.wantsLayer = YES;
    if([self isDarkMode]){
        self.centerView.layer.backgroundColor = [NSColor colorWithRed:18/255.0 green:31/255.0 blue:55/255.0 alpha:1.0].CGColor;
        self.view.layer.backgroundColor = [NSColor colorWithRed:239/255.0 green:242/255.0 blue:245/255.0 alpha:1].CGColor;
        self.joinBtn.layer.backgroundColor = [NSColor colorWithRed:95/255.0 green:135/255.0 blue:248/255.0 alpha:.6].CGColor;

    }else{
        self.view.layer.backgroundColor = [NSColor colorWithRed:95/255.0 green:135/255.0 blue:248/255.0 alpha:1].CGColor;
        self.centerView.layer.backgroundColor = [NSColor whiteColor].CGColor;
        self.joinBtn.layer.backgroundColor = [NSColor colorWithRed:95/255.0 green:135/255.0 blue:248/255.0 alpha:1].CGColor;


    }
}

/**
 判断当前是否是暗黑主题
 */
- (BOOL)isDarkMode{
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance;
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    }
    return NO;
}
- (void)setupUI {
    self.view.wantsLayer =true;
    self.view.layer.backgroundColor = [NSColor colorWithRed:95/255.0 green:135/255.0 blue:248/255.0 alpha:1].CGColor;
    [self.view setNeedsDisplay:YES];
    
    
    self.centerView.wantsLayer =true;
    self.centerView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.centerView.layer.cornerRadius = 5;
    self.centerView.layer.masksToBounds = YES;
    [self.centerView setNeedsDisplay:YES];
    
    self.joinBtn.bordered = NO;
    self.joinBtn.wantsLayer =true;
    self.joinBtn.layer.backgroundColor = [NSColor colorWithRed:95/255.0 green:135/255.0 blue:248/255.0 alpha:1].CGColor;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    self.joinBtn.attributedTitle = [[NSAttributedString alloc] initWithString:@"加入房间" attributes:@{
        NSForegroundColorAttributeName: [NSColor whiteColor], NSParagraphStyleAttributeName: style}];
    self.joinBtn.layer.cornerRadius = 3.0;
    self.joinBtn.layer.masksToBounds = YES;
    
    self.userTf.stringValue = [self getUserId];
    self.roomTf.stringValue = @"test007";
        
}
- (NSString *)getUserId {
   NSString* userId = [NSString stringWithFormat:@"mac_%d",arc4random()%10000000];
    return userId;
}


- (IBAction)joinChannelPage:(NSButton *)sender {
    self.centerView.alphaValue = 0;
    
    UCloudMainViewController *mainController = [[UCloudMainViewController alloc] initWithNibName:@"UCloudMainViewController" bundle:nil];
    
    mainController.roomId = self.roomTf.stringValue;
    mainController.userId = self.userTf.stringValue;
    mainController.roomType = self.segControl.selectedSegment;
    
    mainController.view.frame = self.view.bounds;
    [self.view addSubview:mainController.view];
    [self addChildViewController:mainController];
    mainController.leaveRoomComplete = ^{
        self.centerView.alphaValue = 1;
    };

    mainController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:mainController.view attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
        [NSLayoutConstraint constraintWithItem:mainController.view attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
        [NSLayoutConstraint constraintWithItem:mainController.view attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
        [NSLayoutConstraint constraintWithItem:mainController.view attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]
    ]];
   
    
}




- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

@end



