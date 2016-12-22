//
//  ViewController.m
//  AudioPlayerDemo
//
//  Created by anne on 16/12/19.
//  Copyright © 2016年 anne. All rights reserved.
//

#import "ViewController.h"
#import "AudioPlayerManager.h"
#define mp3Url @"http://ws.stream.qqmusic.qq.com/C400001wicCf3hj0dl.m4a?vkey=F5C83790125697B0869E7AD9CDB16D682B369C5D7905E53CA2BAB1FF298F9C6A87EC4AE24CC8D74FEB2D1752C78A4A3C09F8F27B3A738EE7&guid=6033629665&fromtag=30"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AudioPlayerManager shared]playAudioUrl:mp3Url playProgress:^(NSTimeInterval currentTime, NSTimeInterval duration) {
        
    } playStatus:^(PlayStatus playStatus) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
