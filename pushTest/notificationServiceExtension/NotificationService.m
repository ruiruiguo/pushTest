//
//  NotificationService.m
//  bywdNotificationServiceExtension
//
//  Created by macjm on 2020/9/28.
//  Copyright © 2020 mac. All rights reserved.
//

#import "NotificationService.h"
#import "XSAudioManager.h"
#import <AVFoundation/AVFoundation.h>
#define kFileManager [NSFileManager defaultManager]

typedef void(^PlayVoiceBlock)(void);

@interface NotificationService ()<AVAudioPlayerDelegate,AVSpeechSynthesizerDelegate>
{
    AVSpeechSynthesizer *synthesizer;
}
@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
// AVSpeechSynthesisVoice 播放完毕之后的回调block
@property (nonatomic, copy)PlayVoiceBlock finshBlock;


//声音文件的播放器
@property (nonatomic, strong)AVAudioPlayer *myPlayer;
//声音文件的路径
@property (nonatomic, strong) NSString *filePath;

@end

@implementation NotificationService

/*
 *后台推送的json案例
 {"aps":{"alert":"钱到啦收款10000元","badge":1,"mutable-content":1,"amount":10000, "sound":"default"}}
 */

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    
    
    //step1: 推送json解析,获取推送金额
    NSMutableDictionary *dict = [self.bestAttemptContent.userInfo mutableCopy] ;
    NSDictionary *extras =  [dict objectForKey:@"aps"] ;
    BOOL playaudio =  [[extras objectForKey:@"amount"] boolValue] ;
    if(playaudio) {
        
        //step2:先处理金额，得到语音文件的数组,并播放语音(本地推送 -音频)
        NSString *amount = [extras objectForKey:@"amount"] ;//10000
        NSArray *musicArr = [[XSAudioManager sharedInstance] getMusicArrayWithNum:amount];
        __weak __typeof(self)weakSelf = self;
        [[XSAudioManager sharedInstance] pushLocalNotificationToApp:0 withArray:musicArr completed:^{
            // 播放完成后，通知系统
            weakSelf.contentHandler(weakSelf.bestAttemptContent);
        }];
        
    } else {
        //系统通知
        self.contentHandler(self.bestAttemptContent);
    }
}

// 30s的处理时间即将结束时，该方法会被调用，最后一次提醒用户去做处理
- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}



@end
