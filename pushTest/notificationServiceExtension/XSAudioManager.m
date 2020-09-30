//
//  XSAudioManager.m
//  bywdNotificationServiceExtension
//
//  Created by 郭瑞 on 2020/9/30.
//  Copyright © 2020 mac. All rights reserved.
//

#import "XSAudioManager.h"
#import "NotificationService.h"
#import <AVFoundation/AVFoundation.h>

@implementation XSAudioManager

+ (instancetype)sharedInstance{
    static XSAudioManager *_instance = nil ;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[XSAudioManager alloc] init] ;
    }) ;
    return _instance ;
}

//循环调用本地通知,播放音频文件
-(void)pushLocalNotificationToApp:(NSInteger)index withArray:(NSArray *)tmparray completed:(XSNotificationPushCompleted)completed{
    __block NSInteger tmpindex = index;
    if(tmpindex < [tmparray count]){
        //获取本地mpe3e文件时长
        NSString *mp3Name = [NSString stringWithFormat:@"%@",tmparray[tmpindex]];
        if (!mp3Name) {
            mp3Name = @"money";
        }
        NSString *audioFileURL = [[NSBundle mainBundle] pathForResource:mp3Name ofType:@"mp3"];
        AVURLAsset *audioAsset=[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:audioFileURL] options:nil];
        CMTime audioDuration=audioAsset.duration;
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init]; //标题
        content.sound = [UNNotificationSound soundNamed:[NSString stringWithFormat:@"%@.mp3",mp3Name]];
        
        // repeats,是否重复，如果重复的话时间必须大于60s，要不会报错
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1  repeats:NO];
        /* */
        //添加通知的标识符，可以用于移除，更新等搡作
        NSString * identifier = [NSString stringWithFormat:@"%@%f",@"noticeId",audioDurationSeconds];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
            //第一条推送成功后，递归执行
            float time = audioDurationSeconds + 0.1;
            tmpindex = tmpindex+1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self pushLocalNotificationToApp:tmpindex withArray:tmparray  completed:completed];
            });
        }];
    }else{
        completed();
    }
    
}



-(NSArray *)getMusicArrayWithNum:(NSString *)numStr
{
    NSString *finalStr = [self caculateNumber:numStr];
    //前部分字段例如:***到账  user_payment是项目自定义的音乐文件
    NSMutableArray *finalArr = [[NSMutableArray alloc] initWithObjects:@"user_payment", nil];
    for (int i=0; i<finalStr.length; i++) {
        [finalArr addObject:[finalStr substringWithRange:NSMakeRange(i, 1)]];
    }
    return finalArr;
}

-(NSString *)caculateNumber:(NSString *)numstr {
    NSArray *numberchar = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    NSArray *inunitchar = @[@"",@"十",@"百",@"千"];
    NSArray *unitname   = @[@"",@"万",@"亿"];
    
    NSString *valstr =[NSString stringWithFormat:@"%.2f",numstr.doubleValue] ;
    NSString *prefix = @"" ;
    
    // 将金额分为整数部分和小数部分
    NSString *head = [valstr substringToIndex:valstr.length - 2 - 1] ;
    NSString *foot = [valstr substringFromIndex:valstr.length - 2] ;
//    if (head.length>8) {
//        return nil ;//只支持到千万，抱歉哈
//    }
    
    // 处理整数部分
    if([head isEqualToString:@"0"]) {
        prefix = @"0" ;
    }
    else {
        NSMutableArray *ch = [[NSMutableArray alloc]init] ;
        for (int i = 0; i < head.length; i++) {
            NSString * str = [NSString stringWithFormat:@"%x",[head characterAtIndex:i]-'0'] ;
            [ch addObject:str] ;
        }
        
        int zeronum = 0 ;
        for (int i = 0; i < ch.count; i++) {
            NSInteger index = (ch.count-1 - i)%4 ;       //取段内位置
            NSInteger indexloc = (ch.count-1 - i)/4 ;    //取段位置
            
            if ([[ch objectAtIndex:i]isEqualToString:@"0"]) {
                zeronum ++ ;
            }
            else {
                if (zeronum != 0) {
                    if (index != 3) {
                        prefix=[prefix stringByAppendingString:@"零"];
                    }
                    zeronum = 0;
                }
                if (ch.count >i) {
                    NSInteger numIndex = [[ch objectAtIndex:i]intValue];
                    if (numberchar.count >numIndex) {
                        prefix = [prefix stringByAppendingString:[numberchar objectAtIndex:numIndex]] ;
                    }
                }
                
                if (inunitchar.count >index) {
                    prefix = [prefix stringByAppendingString:[inunitchar objectAtIndex:index]] ;
                }

            }
            if (index == 0 && zeronum < 4) {
                if (unitname.count >indexloc) {
                    prefix = [prefix stringByAppendingString:[unitname objectAtIndex:indexloc]] ;

                }
            }
        }
    }
    
    //1十开头的改为十
      if([prefix hasPrefix:@"1十"]) {
          prefix = [prefix stringByReplacingOccurrencesOfString:@"1十" withString:@"十"] ;
      }
    
    //处理小数部分
    if([foot isEqualToString:@"00"]) {
        prefix = [prefix stringByAppendingString:@"元"] ;
    }
    else {
        prefix = [prefix stringByAppendingString:[NSString stringWithFormat:@"点%@元", foot]] ;
    }
    return prefix ;
}



 #pragma mark iOS12.1以下 播放语音
 //语音播报红包消息
- (void)speechWalllentMessage:(NSString *)numStr {
    
    //播放语音
    // 合成器 控制播放，暂停
    AVSpeechSynthesizer *_synthesizer;
    // 实例化说话的语言，说中文、英文
    AVSpeechSynthesisVoice *_voice;
    _voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh_CN"];
    // 要朗诵，需要一个语音合成器
    _synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:[NSString stringWithFormat:@"XX到账%@元",numStr]];
    //指定语音，和朗诵速度
    utterance.voice = _voice;
//    utterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    utterance.rate = 0.55;
    utterance.pitchMultiplier = 1.0f;  //改变音调
//    utterance.volume = 1;
    //启动
    [_synthesizer speakUtterance:utterance];
    
}

@end
