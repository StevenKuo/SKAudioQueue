//
//  SKAudioStream.h
//  SKAudioQueue
//
//  Created by steven on 2015/1/23.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//


#import "SKAudioQueue.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SKAudioDataProcessor.h"

@class SKAudioStream;

@protocol SKAudioStreamDelegate <NSObject>

- (void)audioStreamDidStartPlaying:(SKAudioStream *)inAudioStream;
- (void)audioStreamDidStopPlaying:(SKAudioStream *)inAudioStream;
- (void)audioStream:(SKAudioStream *)inAudioStream updatePlaybackTime:(NSTimeInterval)inPlaybackTime;

- (void)audioStreamDidHandleAudioProcess:(SKAudioStream *)inAudioStream;
- (void)audioStreamDidFinishProcess:(SKAudioStream *)inAudioStream;

- (void)audioStreamCompleteLoadingData:(SKAudioStream *)inAudioStream;
- (void)audioStream:(SKAudioStream *)inAudioStream updateAvailableTime:(NSTimeInterval)inAvailableTime;

- (SKAudioQueue *)availableAudioQueue:(SKAudioStream *)inAudioStream audioStreamBasicDescription:(AudioStreamBasicDescription *)description;

- (NSUInteger)crossfadeInSec:(SKAudioStream *)inAudioStream;
- (NSUInteger)crossfadeOutSec:(SKAudioStream *)inAudioStream;

@end

@interface SKAudioStreamCrossFadeHandler : NSObject
{
	SKAudioQueue *audioQueue;
	NSTimeInterval crossFadeTime;
	NSTimer *timer;
	Float32 valueOffset;
	BOOL completed;
}
- (instancetype)initWithAudioQueue:(SKAudioQueue *)queue targetVolumeValue:(Float32)value crossFadeTime:(NSTimeInterval)time;
- (void)start;
- (void)pauseCrossFade;
- (void)drop;

@property (readonly, nonatomic) BOOL completed;
@end

@interface SKAudioStream : NSObject
{
	__weak id <SKAudioStreamDelegate> delegate;

	SKAudioQueue *audioQueue;
	SKAudioDataProcessor *dataProcessor;
	NSURLSession *operationSession;
	
	SKAudioStreamCrossFadeHandler *fadeInHandler;
	SKAudioStreamCrossFadeHandler *fadeOutHandler;
	
}

- (id)initWithAudioContentURL:(NSURL *)inURL;
- (instancetype)initWithAudioContentPath:(NSString *)inPath;
- (void)cancel;

- (void)playAudioQueue;
- (void)pauseAudioQueue;
- (void)stopAudioQueue;
- (void)seekAudioQueueWithTime:(NSTimeInterval)inTime;

- (void)startFadeIn;
- (void)startFadeOut;

- (NSTimeInterval)availablePlayTime;
- (NSTimeInterval)accuratePlayEndTime;

@property (readonly, nonatomic) SKAudioQueue *audioQueue;
@property (weak, nonatomic) id <SKAudioStreamDelegate> delegate;
@property (readonly, nonatomic) NSTimeInterval currentPlaybackTime;
@property (readonly, nonatomic) BOOL loadingCompleted;
@end
