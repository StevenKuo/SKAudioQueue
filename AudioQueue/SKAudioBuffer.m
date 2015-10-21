//
//  SKAudioBuffer.m
//  SKAudioQueue
//
//  Created by steven on 2015/1/22.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "SKAudioBuffer.h"

@implementation SKAudioBuffer

- (id)init
{
	self = [super init];
	if (self) {
		
		audioData = [[NSMutableData alloc] init];
		packetDescData = [[NSMutableData alloc] init];
		
	}
	return self;
}

- (NSTimeInterval)availablePlayLength
{
	AudioStreamBasicDescription audioStreamDescription = [delegate usedAudioStreamBasicDescription];
	if (audioStreamDescription.mSampleRate > 0 && audioStreamDescription.mFramesPerPacket > 0) {
		return (availablePacketCount) / (audioStreamDescription.mSampleRate / audioStreamDescription.mFramesPerPacket);
	}
	return 0.0;
}

- (void)storePacketData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount
{
	for (NSUInteger packetIndex = 0; packetIndex < inPacketsCount ; packetIndex ++) {
		inPacketDescriptions[packetIndex].mStartOffset += audioData.length;
	}
	
	@synchronized (self) {
		[audioData appendBytes:inBytes length:inLength];
		[packetDescData appendBytes:inPacketDescriptions length:sizeof(AudioStreamPacketDescription) * inPacketsCount];
		availablePacketCount += inPacketsCount;
	}
}

- (void)prepareDataWithCallback:(void (^)(const void ** dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions, BOOL noAvailablePacket))inCallback
{
//	NSLog(@"audioPlayerRequestData readIndex :%d", readPacketIndex);
//	NSLog(@"audioPlayerRequestData avaliblePacketCount :%d", availablePacketCount);
	@synchronized (self) {
		if (readPacketIndex >= availablePacketCount) {
			inCallback(nil, 0, nil, YES);
			return;
		}
		if (readPacketIndex == 0) {
			[delegate audioBufferDidBeginReadPacket:self];
		}
		
		AudioStreamPacketDescription* packetDescriptions = (AudioStreamPacketDescription* )packetDescData.bytes;
		size_t packetSize = (NSUInteger)([self _packetsPerSecond] * 8.0);
		
		const void **data = calloc(packetSize, sizeof(void *));
		AudioStreamPacketDescription *descs = calloc(packetSize, sizeof(AudioStreamPacketDescription));
		
		size_t index;
		size_t offset = 0;
		
		for (index = 0; index < packetSize; index ++) {
			if (readPacketIndex >= availablePacketCount) {
				break;
			}
			data[index] = audioData.bytes + packetDescriptions[readPacketIndex].mStartOffset;
			memcpy(&(descs[index]), &packetDescriptions[readPacketIndex], sizeof(AudioStreamPacketDescription));
			descs[index].mStartOffset = offset;
			offset += descs[index].mDataByteSize;
			
			readPacketIndex ++;
		}
		
		inCallback(data, (UInt32)index, descs, NO);
		
		free(descs);
		free(data);
	}
}

- (double)_packetsPerSecond
{
	AudioStreamBasicDescription audioStreamDescription = [delegate usedAudioStreamBasicDescription];
	return audioStreamDescription.mSampleRate / audioStreamDescription.mFramesPerPacket;
}


- (void)resetReadPacketIndexWithTime:(NSTimeInterval)inTime
{
	NSTimeInterval realPlaybackTime = inTime;
    
	if (realPlaybackTime < 0.0) {
		realPlaybackTime = 0.0;
	}
	
	packetReadHead = (size_t)(realPlaybackTime * [self _packetsPerSecond]);
	readPacketIndex = packetReadHead;
}


- (NSTimeInterval)readPacketTime
{
    return (NSTimeInterval)packetReadHead / [self _packetsPerSecond];
}

@synthesize delegate;
@end
