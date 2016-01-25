//
//  HomeViewController.m
//  CustomerSystem-ios
//
//  Created by dhc on 15/2/13.
//  Copyright (c) 2015年 easemob. All rights reserved.
//

#import "HomeViewController.h"

#import "EaseMob.h"
#import "EMIMHelper.h"
#import "MallViewController.h"
#import "SettingViewController.h"
#import "ChatViewController.h"
#import "UIViewController+HUD.h"
#import "ChatSendHelper.h"
#import "LocalDefine.h"
#import "MoreChoiceView.h"
#import <AudioToolbox/AudioToolbox.h>
//两次提示的默认间隔
static const CGFloat kDefaultPlaySoundInterval = 3.0;

@interface HomeViewController () <UIAlertViewDelegate, IChatManagerDelegate>
{
    MallViewController *_mallController;
    SettingViewController *_settingController;
    
    UIBarButtonItem *_chatItem;
}

@property (strong, nonatomic) NSDate *lastPlaySoundDate;
@property (strong, nonatomic) MoreChoiceView *choiceView;

@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //if 使tabBarController中管理的viewControllers都符合 UIRectEdgeNone
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.tabBarController.hidesBottomBarWhenPushed = YES;
    self.title = NSLocalizedString(@"title.mall", @"Mall");
    
#warning 把self注册为SDK的delegate
    [self registerNotifications];
    
    [self setupSubviews];
    self.selectedIndex = 0;
    
    UIButton *chatButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 90, 44)];
    [chatButton setTitle:NSLocalizedString(@"customerChat", @"Customer") forState:UIControlStateNormal];
    [chatButton addTarget:self action:@selector(chatItemAction) forControlEvents:UIControlEventTouchUpInside];
    [chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _chatItem = [[UIBarButtonItem alloc] initWithCustomView:chatButton];
    self.navigationItem.rightBarButtonItem = _chatItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatAction:) name:KNOTIFICATION_CHAT object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self unregisterNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private action

- (void)chatItemAction
{
    if (_choiceView.hidden) {
        _choiceView.hidden = NO;
    } else {
        _choiceView.hidden = YES;
    }
//    [self chatAction:nil];
}

- (void)chatAction:(NSNotification *)notification
{
    [[EMIMHelper defaultHelper] loginEasemobSDK];
    NSString *cname = [[EMIMHelper defaultHelper] cname];
    ChatViewController *chatController;
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        if ([notification.object objectForKey:kpreSell]) {
            chatController = [[ChatViewController alloc] initWithChatter:cname type:[[notification.object objectForKey:kpreSell] boolValue]?ePreSaleType:eAfterSaleType];
        } else {
            chatController = [[ChatViewController alloc] initWithChatter:cname type:eAfterSaleType];
            chatController.commodityInfo = (NSDictionary *)notification.object;
        }
    } else {
        chatController = [[ChatViewController alloc] initWithChatter:cname type:eSaleTypeNone];
    }
    chatController.title = @"演示客服";
    [self.navigationController pushViewController:chatController animated:YES];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.tag == 0) {
        self.title = NSLocalizedString(@"title.mall", @"Mall");
        self.navigationItem.rightBarButtonItem = _chatItem;
    }
    else if (item.tag == 1){
        self.title = NSLocalizedString(@"title.setting", @"Setting");
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - private

-(void)registerNotifications
{
    [self unregisterNotifications];
    
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
}

-(void)unregisterNotifications
{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
}

- (void)setupSubviews
{
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7)
    {
        self.tabBar.tintColor = RGBACOLOR(242, 83, 131, 1);
    }
    else{
        self.tabBar.tintColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    }
    
    _mallController = [[MallViewController alloc] initWithNibName:nil bundle:nil];
    _mallController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"title.mall", @"Mall") image:nil tag:0];
    [_mallController.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_mallHL"] withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_mall"]];
    [self unSelectedTapTabBarItems:_mallController.tabBarItem];
    [self selectedTapTabBarItems:_mallController.tabBarItem];
    
    _settingController = [[SettingViewController alloc] initWithNibName:nil bundle:nil];
    _settingController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"title.setting", @"Setting") image:nil tag:1];
    [_settingController.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_settingHL"]
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_setting"]];
    _settingController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self unSelectedTapTabBarItems:_settingController.tabBarItem];
    [self selectedTapTabBarItems:_settingController.tabBarItem];
    
    self.viewControllers = @[_mallController, _settingController];
    [self selectedTapTabBarItems:_mallController.tabBarItem];
    
    _choiceView = [[MoreChoiceView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    _choiceView.hidden = YES;
    [self.view addSubview:_choiceView];
}

-(void)unSelectedTapTabBarItems:(UITabBarItem *)tabBarItem
{
    [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont systemFontOfSize:14], UITextAttributeFont,[UIColor grayColor],UITextAttributeTextColor,
                                        nil] forState:UIControlStateNormal];
}

-(void)selectedTapTabBarItems:(UITabBarItem *)tabBarItem
{
    [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont systemFontOfSize:14],
                                        UITextAttributeFont,RGBACOLOR(242, 83, 131, 1),UITextAttributeTextColor,
                                        nil] forState:UIControlStateSelected];
}

- (void)networkChanged:(EMConnectionState)connectionState
{
//    _connectionState = connectionState;
//    [_chatListVC networkChanged:connectionState];
}

#pragma mark - private chat

- (void)_playSoundAndVibration
{
    NSTimeInterval timeInterval = [[NSDate date]
                                   timeIntervalSinceDate:self.lastPlaySoundDate];
    if (timeInterval < kDefaultPlaySoundInterval) {
        //如果距离上次响铃和震动时间太短, 则跳过响铃
        NSLog(@"skip ringing & vibration %@, %@", [NSDate date], self.lastPlaySoundDate);
        return;
    }
    
    // 保存最后一次响铃时间
    self.lastPlaySoundDate = [NSDate date];
     // 收到消息时，播放音频
    [self playNewMessageSound];
    // 收到消息时，震动
    [self playVibration];
}

- (void)_showNotificationWithMessage:(EMMessage *)message
{
    EMPushNotificationOptions *options = [[EaseMob sharedInstance].chatManager pushNotificationOptions];
    //发送本地推送
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date]; //触发通知的时间
    
    if (options.displayStyle == ePushNotificationDisplayStyle_messageSummary) {
        id<IEMMessageBody> messageBody = [message.messageBodies firstObject];
        NSString *messageStr = nil;
        switch (messageBody.messageBodyType) {
            case eMessageBodyType_Text:
            {
                messageStr = ((EMTextMessageBody *)messageBody).text;
            }
                break;
            case eMessageBodyType_Image:
            {
                messageStr = NSLocalizedString(@"message.image", @"Image");
            }
                break;
            case eMessageBodyType_Location:
            {
                messageStr = NSLocalizedString(@"message.location", @"Location");
            }
                break;
            case eMessageBodyType_Voice:
            {
                messageStr = NSLocalizedString(@"message.voice", @"Voice");
            }
                break;
            case eMessageBodyType_Video:{
                messageStr = NSLocalizedString(@"message.vidio", @"Vidio");
            }
                break;
            default:
                break;
        }
        
        NSString *title = message.from;
        notification.alertBody = [NSString stringWithFormat:@"%@:%@", title, messageStr];
    }
    else{
        notification.alertBody = NSLocalizedString(@"receiveMessage", @"you have a new message");
    }
    
#warning 去掉注释会显示[本地]开头, 方便在开发中区分是否为本地推送
    //notification.alertBody = [[NSString alloc] initWithFormat:@"[本地]%@", notification.alertBody];
    
    notification.alertAction = NSLocalizedString(@"open", @"Open");
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    //发送通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#pragma mark - IChatManagerDelegate 消息变化

- (void)didUpdateConversationList:(NSArray *)conversationList
{
//    [_chatListVC refreshDataSource];
}

// 未读消息数量变化回调
-(void)didUnreadMessagesCountChanged
{
//    [self setupUnreadMessageCount];
}

- (void)didFinishedReceiveOfflineMessages:(NSArray *)offlineMessages
{
//    [self setupUnreadMessageCount];
}

- (void)didFinishedReceiveOfflineCmdMessages:(NSArray *)offlineCmdMessages
{
    
}

// 收到消息回调
-(void)didReceiveMessage:(EMMessage *)message
{
#if !TARGET_IPHONE_SIMULATOR
    BOOL isAppActivity = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    if (!isAppActivity) {
        [self _showNotificationWithMessage:message];
    }else {
        [self _playSoundAndVibration];
    }
#endif
}

-(void)didReceiveCmdMessage:(EMMessage *)message
{
    NSString *msg = [NSString stringWithFormat:@"%@", message.ext];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"receiveCmdMessage", @"CMD message") message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - IChatManagerDelegate 登录状态变化

- (void)didLoginFromOtherDevice
{
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"loginAtOtherDevice", @"your login account has been in other places") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        alertView.tag = 100;
        [alertView show];

    } onQueue:nil];
}

- (void)didRemovedFromServer
{
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:NO completion:^(NSDictionary *info, EMError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"loginUserRemoveFromServer", @"your account has been removed from the server side") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        alertView.tag = 101;
        [alertView show];
    } onQueue:nil];
}

#pragma mark - 自动登录回调

- (void)willAutoReconnect
{
    [self hideHud];
    [self showHint:NSLocalizedString(@"reconnection.ongoing", @"reconnecting...")];
}

- (void)didAutoReconnectFinishedWithError:(NSError *)error
{
    [self hideHud];
    if (error) {
        [self showHint:NSLocalizedString(@"reconnection.fail", @"reconnection failure, later will continue to reconnection")];
    }else{
        [self showHint:NSLocalizedString(@"reconnection.success", @"reconnection successful！")];
    }
}

/**
 *  系统铃声播放完成后的回调
 */
void EMSystemSoundFinishedPlayingCallback(SystemSoundID sound_id, void* user_data)
{
    AudioServicesDisposeSystemSoundID(sound_id);
}

- (SystemSoundID)playNewMessageSound
{
    // 要播放的音频文件地址
    NSURL *bundlePath = [[NSBundle mainBundle] URLForResource:@"EaseMob" withExtension:@"bundle"];
    NSURL *audioPath = [[NSBundle bundleWithURL:bundlePath] URLForResource:@"in" withExtension:@"caf"];
    // 创建系统声音，同时返回一个ID
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(audioPath), &soundID);
    // Register the sound completion callback.
    AudioServicesAddSystemSoundCompletion(soundID,
                                          NULL, // uses the main run loop
                                          NULL, // uses kCFRunLoopDefaultMode
                                          EMSystemSoundFinishedPlayingCallback, // the name of our custom callback function
                                          NULL // for user data, but we don't need to do that in this case, so we just pass NULL
                                          );
    
    AudioServicesPlaySystemSound(soundID);
    
    return soundID;
}

// 震动
- (void)playVibration
{
    // Register the sound completion callback.
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate,
                                          NULL, // uses the main run loop
                                          NULL, // uses kCFRunLoopDefaultMode
                                          EMSystemSoundFinishedPlayingCallback, // the name of our custom callback function
                                          NULL // for user data, but we don't need to do that in this case, so we just pass NULL
                                          );
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
