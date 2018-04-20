//
//  SKAudioEngine.h
//  SKAudioQueue
//
//  Created by steven on 2015/1/23.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKAudioStream.h"

@class SKAudioEngine;

@protocol SKAudioEngineDelegate <NSObject>

- (void)audioEngineDidStartStreaming:(SKAudioEngine *)SKAudioEngine;
- (void)audioEngineDidStopStreaming:(SKAudioEngine *)SKAudioEngine;
- (void)audioEngineDidReadAudioPacket:(SKAudioEngine *)inAudioEngine;
- (void)audioEngineDidEndPlaying:(SKAudioEngine *)inAudioEngine;
- (void)audioEngine:(SKAudioEngine *)SKAudioEngine receivedLoadingError:(NSError *)error;
- (void)audioEngine:(SKAudioEngine *)SKAudioEngine updatePlaybackTime:(NSTimeInterval)inPlaybackTime;
- (void)audioEngine:(SKAudioEngine *)SKAudioEngine updateAvailablePlayTime:(NSTimeInterval)inAvailablePlayTime;
- (void)audioEngineCompleteLoadingData:(SKAudioEngine *)inAudioEngine;

@optional
- (BOOL)audioEngineShouldBeginCrossFade:(SKAudioEngine *)inAudioEngine;
- (void)audioEngineBeginCrossFade:(SKAudioEngine *)inAudioEngine;

@end

@interface SKAudioEngine : NSObject
{
	__weak id <SKAudioEngineDelegate> delegate;
	
	SKAudioStream *currentAudioStream;
	SKAudioStream *previousAudioStream;
    
    NSMutableArray *existAudioQueues;
	
	BOOL enableCrossFade;
	BOOL crossing;
}

- (void)loadAudioContentWithURL:(NSURL *)inURL;
- (void)loadAudioContentWithPath:(NSString *)inPath;
- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)inTime;

@property (assign ,nonatomic) BOOL enableCrossFade;
@property (weak, nonatomic) id <SKAudioEngineDelegate> delegate;
@property (assign, nonatomic) NSUInteger crossfadeInSec;
@property (assign, nonatomic) NSUInteger crossfadeOutSec;
@end
