//
//  SKAudioStream.m
//  SKAudioQueue
//
//  Created by steven on 2015/1/23.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "SKAudioStream.h"
#import "SKAudioBuffer.h"
#import <AVFoundation/AVFoundation.h>

@implementation SKAudioStreamCrossFadeHandler

- (instancetype)initWithAudioQueue:(SKAudioQueue *)queue targetVolumeValue:(Float32)value crossFadeTime:(NSTimeInterval)time
{
	self = [super init];
	if (self) {
		audioQueue = queue;
		crossFadeTime = time;
		valueOffset = value / crossFadeTime / 2.0;
	}
	return self;
}

- (void)_zapTimer
{
	if (timer) {
		if ([timer isValid]) {
			[timer invalidate];
		}
		timer = nil;
	}
	
}
- (void)drop
{
	[self _zapTimer];
	completed = YES;
	audioQueue.volumeOffset = 0.0;
	[audioQueue updateVolumeLevel];
}
- (void)start
{
	if (!crossFadeTime) {
		return;
	}
	[self _zapTimer];
	timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(_changeVolume:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	[timer fire];
}

- (void)_changeVolume:(id)sender
{
	if (crossFadeTime == 0) {
		[self drop];
		return;
	}
	crossFadeTime -= 0.5;
	audioQueue.volumeOffset += valueOffset;
	[audioQueue updateVolumeLevel];
}

- (void)pauseCrossFade
{
	[self _zapTimer];
}

@synthesize completed;
@end


@implementation SKAudioStream


- (id)initWithAudioContentURL:(NSURL *)inURL
{
	self = [super init];
    if (self) {
		
		dataProcessor = [[SKAudioDataProcessor alloc] init];
		dataProcessor.delegate = (id)self;
		

		NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		NSURLSessionConfiguration *myConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
		operationSession = [NSURLSession sessionWithConfiguration:myConfiguration delegate:(id)self delegateQueue:operationQueue];
		
		[self _fetchAudioContentWithURL:inURL];
		
	}
	return self;
}

- (instancetype)initWithAudioContentPath:(NSString *)inPath
{
	self = [super init];
	if (self) {
		dataProcessor = [[SKAudioDataProcessor alloc] init];
		dataProcessor.delegate = (id)self;
		
		NSData *audioData = [NSData dataWithContentsOfFile:inPath];
		if (audioData) {
			[dataProcessor.parser parseData:audioData];
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			if ([dataProcessor.buffer availablePlayLength] > 0.0) {
				[delegate audioStream:self updateAvailableTime:[dataProcessor.buffer availablePlayLength]];
			}
		});
	}
	return self;
}

- (void)cancel
{
    [audioQueue stop];
    
    if (fadeOutHandler) {
        [fadeOutHandler drop];
        fadeOutHandler = nil;
    }
    
    if (fadeInHandler) {
        [fadeInHandler drop];
        fadeInHandler = nil;
    }
    
    
	[operationSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		if ([downloadTasks count]) {
			for (NSURLSessionDataTask *task in downloadTasks) {
				[task cancel];
			}
		}
		else if ([dataTasks count]) {
			for (NSURLSessionDataTask *task in dataTasks) {
				[task cancel];
			}
		}
	}];
}

- (void)playAudioQueue
{
	if (audioQueue.playing) {
		return;
	}
	
	NSError *audioSessionError = nil;
	[[AVAudioSession sharedInstance] setActive:YES error:&audioSessionError];
	
	[dataProcessor.buffer resetReadPacketIndexWithTime:currentPlaybackTime];
	
	[audioQueue play];
}

- (void)pauseAudioQueue
{
    if (fadeInHandler && !fadeInHandler.completed) {
        [fadeInHandler pauseCrossFade];
    }
    
    if (fadeOutHandler && !fadeOutHandler.completed) {
        [fadeOutHandler pauseCrossFade];
    }
	[audioQueue pause];
}

- (void)stopAudioQueue
{
	[audioQueue stop];
}

- (void)seekAudioQueueWithTime:(NSTimeInterval)inTime
{
	if (audioQueue.playing) {
		[audioQueue pause];
		[dataProcessor.buffer resetReadPacketIndexWithTime:inTime];
		[audioQueue play];
		return;
	}
	[dataProcessor.buffer resetReadPacketIndexWithTime:inTime];
}

- (void)_fetchAudioContentWithURL:(NSURL *)inURL
{
	NSURLRequest *request = [NSURLRequest requestWithURL:inURL];
	NSURLSessionDataTask *task = [operationSession dataTaskWithRequest:request];
	[task resume];
}

- (NSTimeInterval)availablePlayTime
{
	return [dataProcessor.buffer availablePlayLength];
}

- (NSTimeInterval)accuratePlayEndTime
{
	return [dataProcessor.buffer availablePlayLength];
}

- (void)startFadeIn
{
    if (!fadeInHandler) {
        fadeInHandler = [[SKAudioStreamCrossFadeHandler alloc] initWithAudioQueue:audioQueue targetVolumeValue:audioQueue.currentVolume crossFadeTime:[delegate crossfadeInSec:self]];
    }
    [fadeInHandler start];
}
- (void)startFadeOut
{
    if (loadingCompleted) {
        if (!fadeOutHandler) {
            fadeOutHandler = [[SKAudioStreamCrossFadeHandler alloc] initWithAudioQueue:audioQueue targetVolumeValue:-audioQueue.currentVolume crossFadeTime:[delegate crossfadeOutSec:self]];
        }
        [fadeOutHandler start];
    }
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
	[dataProcessor.parser parseData:data];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (audioQueue) {
			if (audioQueue.requestPlay || [dataProcessor.buffer availablePlayLength] < [self _minimumPlayLength]) {
				return ;
			}
			[audioQueue play];
		}
	});
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^{
		loadingCompleted = YES;
	});
	if ([dataProcessor.buffer availablePlayLength] > 0.0) {
		[delegate audioStream:self updateAvailableTime:[dataProcessor.buffer availablePlayLength]];
	}
}

#pragma mark - processor delegate

- (AudioStreamBasicDescription)audioQueueUsedAudioStreamBasicDescription
{
	return audioQueue.audioStreamDescription;
}

- (void)parsedDifferentFromAudioQueueUesdAudioStreamBasicDescription:(AudioStreamBasicDescription *)inAudioStreamBasicDescription
{
	dispatch_async(dispatch_get_main_queue(), ^{
        SKAudioQueue *queue = [delegate availableAudioQueue:self audioStreamBasicDescription:inAudioStreamBasicDescription];
        [queue reset];
        audioQueue = queue;
		audioQueue.delegate = (id)self;
		
		if ([dataProcessor.buffer availablePlayLength] < [self _minimumPlayLength]) {
			return ;
		}
		[audioQueue play];
	});
}
- (void)audioDataProcessorDidStartPrepareAudioPacket:(SKAudioDataProcessor *)inProcessor
{
	[delegate audioStreamDidHandleAudioProcess:self];
}

#pragma mark - audio queue delegate

- (void)requestDataWithCallback:(void (^)(const void ** dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions))inCallback
{
	[dataProcessor.buffer prepareDataWithCallback:^(const void **dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions, BOOL noAvailablePacket) {
		if (noAvailablePacket) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				if (!loadingCompleted) {
					[audioQueue pause];
				}
				else {
					[audioQueue pause];
					[delegate audioStreamDidFinishProcess:self];
				}
			});
			return ;
		}
		inCallback(dataPackets, packetCount, packetDescriptions);
	}];
}

- (void)audioQueueWillStart:(SKAudioQueue *)inAudioQueue
{
	NSError *__unused audioSessionError = nil;
	BOOL __unused categorySet = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
}

- (void)audioQueueDidStart:(SKAudioQueue *)inAudioQueue
{	
    [delegate audioStreamDidStartPlaying:self];
}
- (void)audioQueueDidStop:(SKAudioQueue *)inAudioQueue
{
    [delegate audioStreamDidStopPlaying:self];
}
- (void)audioQueue:(SKAudioQueue *)inAudioQueue updateElapsedTime:(NSTimeInterval)inElapsedTime;
{
    NSTimeInterval bufferHeadTime = [dataProcessor.buffer readPacketTime];
    currentPlaybackTime = bufferHeadTime + inElapsedTime;
    [delegate audioStream:self updatePlaybackTime:currentPlaybackTime];
}

- (NSTimeInterval)_minimumPlayLength
{
    return 5.0;
}


@synthesize delegate;
@synthesize audioQueue;
@synthesize currentPlaybackTime;
@synthesize loadingCompleted;
@end
