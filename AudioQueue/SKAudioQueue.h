//
//  SKAudioQueue.h
//  SKAudioQueue
//
//  Created by steven on 2015/1/22.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SKAudioQueue;

@protocol SKAudioQueueDelegate <NSObject>

- (void)requestDataWithCallback:(void (^)(const void ** dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions))inCallback;

- (void)audioQueueWillStart:(SKAudioQueue *)inAudioQueue;
- (void)audioQueueDidStart:(SKAudioQueue *)inAudioQueue;
- (void)audioQueueDidStop:(SKAudioQueue *)inAudioQueue;
- (void)audioQueue:(SKAudioQueue *)inAudioQueue updateElapsedTime:(NSTimeInterval)inElapsedTime;

@end

@interface SKAudioQueue : NSObject
{
	__weak id <SKAudioQueueDelegate> delegate;
	
	AudioStreamBasicDescription audioStreamDescription;
	AudioQueueRef audioQueue;
	Float32 deviceVolume;
	Float32 volumeOffset;
	Float32 currentVolume;
	
	NSTimer *playingTimeTracker;
	NSTimeInterval playingTimeBase;
	
	BOOL requestPlay;
	BOOL playing;
	BOOL dataRequestSuspended;
	BOOL primed;

}

- (void)play;
- (void)pause;
- (void)stop;
- (void)updateVolumeLevel;
- (void)reset;

- (id)initWithAudioStreamDescription:(AudioStreamBasicDescription *)description;

- (BOOL)matchAudioStreamBasicDescription:(AudioStreamBasicDescription *)description;

@property (readonly, nonatomic) AudioStreamBasicDescription audioStreamDescription;
@property (weak, nonatomic) id <SKAudioQueueDelegate> delegate;
@property (readonly, nonatomic) BOOL requestPlay;
@property (readonly, nonatomic) BOOL playing;
@property (readonly, nonatomic) Float32 currentVolume;
@property (assign, nonatomic) Float32 volumeOffset;
@end
