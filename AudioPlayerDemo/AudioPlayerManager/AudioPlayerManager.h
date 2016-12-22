//
//  AudioPlayerManager.h
//  AudioPlayerDemo
//
//  Created by anne on 16/12/19.
//  Copyright © 2016年 anne. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,PlayStatus){
    PlayStatus_Error = 1,
    PlayStatus_Start,
    PlayStatus_Pause,
    PlayStatus_Stop,
    PlayStatus_Finish
    
};

typedef void(^PlayProgressBlock)(NSTimeInterval currentTime,NSTimeInterval duration);
typedef void(^PlayStatusChangeBlock)(PlayStatus playStatus);

@interface AudioPlayerManager : NSObject

+(instancetype)shared;

-(void)playAudioUrl:(NSString*)audioURL playProgress:(PlayProgressBlock)progressBlock playStatus:(PlayStatusChangeBlock)playStatusChangeBlock;
-(void)pausePlay;
-(void)continuePlay;
-(void)stopPlay;
-(void)seekToTime:(NSTimeInterval)time;

@end
