//
//  SKAudioEngine.m
//  SKAudioQueue
//
//  Created by steven on 2015/1/23.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "SKAudioEngine.h"

@implementation SKAudioEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        crossfadeInSec = 10;
        crossfadeOutSec = 10;
        existAudioQueues = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)_resetCurrentAudioStream
{
	if (currentAudioStream) {
		currentAudioStream.delegate = nil;
		[currentAudioStream cancel];
		currentAudioStream = nil;
	}
}

- (void)resetCrossFadeStream
{
	crossing = NO;
	if (previousAudioStream) {
		previousAudioStream.delegate = nil;
		[previousAudioStream cancel];
		previousAudioStream = nil;
	}
}

- (void)cleanStream
{
	[self resetCrossFadeStream];
	[self _resetCurrentAudioStream];
}

- (void)loadAudioContentWithURL:(NSURL *)inURL
{
	[self _resetCurrentAudioStream];
	currentAudioStream = [[SKAudioStream alloc] initWithAudioContentURL:inURL];
	currentAudioStream.delegate = (id)self;
}

- (void)loadAudioContentWithPath:(NSString *)inPath
{
	[self _resetCurrentAudioStream];
	currentAudioStream = [[SKAudioStream alloc] initWithAudioContentPath:inPath];
	currentAudioStream.delegate = (id)self;
}

- (void)play
{
	[currentAudioStream playAudioQueue];
	[previousAudioStream playAudioQueue];
}

- (void)pause
{
	[currentAudioStream pauseAudioQueue];
	[previousAudioStream pauseAudioQueue];
}

- (void)stop
{
	[currentAudioStream stopAudioQueue];
	[previousAudioStream stopAudioQueue];
	
}

- (void)seekToTime:(NSTimeInterval)inTime
{
	[currentAudioStream seekAudioQueueWithTime:inTime];

}

- (NSTimeInterval)accuratePlayEndTime
{
	if (previousAudioStream) {
		return [previousAudioStream availablePlayTime];
	}
	return [currentAudioStream accuratePlayEndTime];
}

#pragma mark - stream delegate

- (void)audioStreamDidStartPlaying:(SKAudioStream *)inAudioStream
{
    if ([inAudioStream isEqual:previousAudioStream] && crossing) {
        [inAudioStream startFadeOut];
    }
    
	if (![inAudioStream isEqual:currentAudioStream]) {
		return;
	}
    if (previousAudioStream && crossing) {
        [inAudioStream startFadeIn];
    }
	
    [delegate audioEngineDidStartStreaming:self];
}

- (void)audioStreamDidHandleAudioProcess:(SKAudioStream *)inAudioStream
{
	if (![inAudioStream isEqual:currentAudioStream]) {
		return;
	}
	if ([delegate respondsToSelector:@selector(audioEngineDidReadAudioPacket:)]) {
		[delegate audioEngineDidReadAudioPacket:self];
	}
}

- (void)audioStreamDidFinishProcess:(SKAudioStream *)inAudioStream
{
	if ([inAudioStream isEqual:previousAudioStream]) {
		[self resetCrossFadeStream];
		return;
	}
	if ([delegate respondsToSelector:@selector(audioEngineDidEndPlaying:)]) {
		[delegate audioEngineDidEndPlaying:self];
	}
}

- (void)audioStreamCompleteLoadingData:(SKAudioStream *)inAudioStream
{
	if (![inAudioStream isEqual:currentAudioStream]) {
		return;
	}
	
	if ([delegate respondsToSelector:@selector(audioEngineCompleteLoadingData:)]) {
		[delegate audioEngineCompleteLoadingData:self];
	}
}

- (void)audioStreamDidStopPlaying:(SKAudioStream *)inAudioStream
{
	if (![inAudioStream isEqual:currentAudioStream]) {
		return;
	}
	crossing = NO;
	if ([delegate respondsToSelector:@selector(audioEngineDidStopStreaming:)]) {
		[delegate audioEngineDidStopStreaming:self];
	}
}
- (void)audioStream:(SKAudioStream *)inAudioStream updatePlaybackTime:(NSTimeInterval)inPlaybackTime
{
	if (![inAudioStream isEqual:currentAudioStream]) {
		return;
	}
	
	if (enableCrossFade && [inAudioStream availablePlayTime] - inPlaybackTime <= crossfadeOutSec && inAudioStream.loadingCompleted) {
		if (!crossing) {
			if ([delegate respondsToSelector:@selector(audioEngineShouldBeginCrossFade:)]) {
				if (![delegate audioEngineShouldBeginCrossFade:self]) {
					return;
				}
			}
            if (previousAudioStream && ![previousAudioStream isEqual:currentAudioStream]) {
                [self resetCrossFadeStream];
            }
			crossing = YES;
			previousAudioStream = currentAudioStream;
			currentAudioStream = nil;
			if ([delegate respondsToSelector:@selector(audioEngineBeginCrossFade:)]) {
				[delegate audioEngineBeginCrossFade:self];
			}
            [previousAudioStream startFadeOut];
		}
		return;
	}
	if ([delegate respondsToSelector:@selector(audioEngine:updatePlaybackTime:)]) {
		[delegate audioEngine:self updatePlaybackTime:inPlaybackTime];
	}
}

- (void)audioStream:(SKAudioStream *)inAudioStream updateAvailableTime:(NSTimeInterval)inAvailableTime
{
	if (![inAudioStream isEqual:currentAudioStream]) {
		return;
	}
	
	if ([delegate respondsToSelector:@selector(audioEngine:updateAvailablePlayTime:)]) {
		[delegate audioEngine:self updateAvailablePlayTime:inAvailableTime];
	}
}

- (void)audioStream:(SKAudioStream *)inAudioStream receivedLoadingError:(NSError *)error {
    if ([delegate respondsToSelector:@selector(audioEngine:receivedLoadingError:)]) {
        [delegate audioEngine:self receivedLoadingError:error];
    }
}

- (NSUInteger)crossfadeInSec:(SKAudioStream *)inAudioStream
{
    return crossfadeInSec;
}
- (NSUInteger)crossfadeOutSec:(SKAudioStream *)inAudioStream
{
    return crossfadeOutSec;
}

- (SKAudioQueue *)availableAudioQueue:(SKAudioStream *)inAudioStream audioStreamBasicDescription:(AudioStreamBasicDescription *)description
{
    for (SKAudioQueue *queue in existAudioQueues) {
        if (!queue.delegate && [queue matchAudioStreamBasicDescription:description]) {
            return queue;
        }
    }
    SKAudioQueue *queue = [[SKAudioQueue alloc] initWithAudioStreamDescription:description];
    [existAudioQueues addObject:queue];
    return queue;
}


@synthesize delegate;
@synthesize enableCrossFade;
@synthesize crossfadeInSec;
@synthesize crossfadeOutSec;
@end
