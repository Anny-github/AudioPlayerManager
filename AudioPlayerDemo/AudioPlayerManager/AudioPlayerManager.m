//
//  AudioPlayerManager.m
//  AudioPlayerDemo
//
//  Created by anne on 16/12/19.
//  Copyright © 2016年 anne. All rights reserved.
//

#import "AudioPlayerManager.h"
#import <AVFoundation/AVFoundation.h>
#import "QFDownloadManager.h"

#define AUDIOCACHE  @"AudioCache"
#define FILEMANAGER  [NSFileManager defaultManager]

@interface AudioPlayerManager ()<AVAudioPlayerDelegate>

@property(nonatomic,strong)AVAudioPlayer *player;
@property(nonatomic,copy)NSString *cachePath;
@property(nonatomic,copy)PlayProgressBlock playProgressBlock;
@property(nonatomic,copy)PlayStatusChangeBlock playStatusChangeBlock;
@property(nonatomic,strong)NSTimer *timer;

@end

@implementation AudioPlayerManager

static AudioPlayerManager *sharedMgr;
static dispatch_once_t onceToken = 0;

+(instancetype)shared{
    
    dispatch_once(&onceToken, ^{
        sharedMgr = [[AudioPlayerManager alloc]init];
    });
    return sharedMgr;
    
}

-(void)playAudioUrl:(NSString*)audioURL playProgress:(PlayProgressBlock)progressBlock playStatus:(PlayStatusChangeBlock)playStatusChangeBlock{
    
    self.playProgressBlock = progressBlock;
    self.playStatusChangeBlock = playStatusChangeBlock;
    
    NSString *filePath = [self audioFilePath:audioURL];
    if (![FILEMANAGER fileExistsAtPath:filePath]) { //文件不存在，未下载
        
        [[QFDownloadManager shareInstance]setStrContentURL:audioURL];
        [[QFDownloadManager shareInstance]setIsShowHUD:YES];
        [[QFDownloadManager shareInstance] setProgressBlock:^(float progress){
            
        }];
        [[QFDownloadManager shareInstance] startDownloadWithCompleteBlock:^(NSError *error, NSString *strSavedPath) {
            //把下载好的文件移动到目标文件夹
            if (!error) {
                NSError *moveError = nil;
                [FILEMANAGER moveItemAtPath:strSavedPath toPath:filePath error:&moveError];
                if (moveError) {
                    NSLog(@"文件移动失败---%@",moveError);
                }else{
                    [self playWithAudioPath:filePath];
                }
            }else{
                NSLog(@"音频文件下载失败---%@",error);
            }
        }];
        
        
    }else{ //文件已存在，直接播放
        [self playWithAudioPath:filePath];
    }
}

-(void)playWithAudioPath:(NSString*)audioPath{
    NSURL *fileUrl = [NSURL fileURLWithPath:audioPath];
    NSError *playError = nil;
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:fileUrl error:&playError];
    
    if (playError) {
        NSLog(@"音频播放器初始化失败----%@",playError);
    }else{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        
        self.player.delegate = self;
        self.player.delegate = self;
        [self.player prepareToPlay];
        [self.player play];
        
        self.playStatusChangeBlock(PlayStatus_Start);
    }
    
}
-(void)pausePlay{
    [self.player pause];
    [self.timer setFireDate:[NSDate distantFuture]];
    self.playStatusChangeBlock(PlayStatus_Pause);

}

-(void)continuePlay{
    [self.player play];
    [self.timer fire];
    self.playStatusChangeBlock(PlayStatus_Start);

}

-(void)stopPlay{
    [self.player stop];
    [self.timer invalidate];
    self.player.delegate = nil;
    self.player = nil;
    self.playStatusChangeBlock(PlayStatus_Stop);

}
-(void)seekToTime:(NSTimeInterval)time{
    [self.player setCurrentTime:time];
}

-(void)timerEvent{
    self.playProgressBlock(self.player.currentTime,self.player.duration);
}

#pragma mark --文件路径
-(NSString*)documentPath{
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    return documentPath;
}

-(NSString*)audioCacheFolder{
   
    NSString *audioFolder =  [[self documentPath] stringByAppendingPathComponent:AUDIOCACHE];
    if (![FILEMANAGER fileExistsAtPath:audioFolder]) {
        NSError *error = nil;
        [FILEMANAGER createDirectoryAtPath:audioFolder withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"音频文件夹创建失败----%@",error);
        }
    }
    
    return audioFolder;
}
//用url作为文件名
-(NSString*)audioFilePath:(NSString*)audioURL{
    NSString *fileName = [audioURL stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    return [[self audioCacheFolder] stringByAppendingPathComponent:fileName];
}

#pragma mark - 音频播放delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.playStatusChangeBlock(PlayStatus_Finish);
    
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    self.playStatusChangeBlock(PlayStatus_Error);
}
@end
