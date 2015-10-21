//
//  SKAudioDataProcessor.m
//  SKAudioQueue
//
//  Created by steven on 2015/1/23.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "SKAudioDataProcessor.h"

@implementation SKAudioDataProcessor


- (id)init
{
	self = [super init];
	if (self) {
		parser = [[SKAudioParser alloc] init];
		parser.delegate = (id)self;
		
		
		buffer = [[SKAudioBuffer alloc] init];
		buffer.delegate = (id)self;
		
	}
	return self;
}

#pragma mark - parser delegate

- (void)audioStreamParser:(SKAudioParser *)inParser didObtainStreamDescription:(AudioStreamBasicDescription *)inDescription
{
	NSLog(@"mSampleRate: %f", inDescription->mSampleRate);
	NSLog(@"mFormatID: %u", (unsigned int)inDescription->mFormatID);
	NSLog(@"mFormatFlags: %u", (unsigned int)inDescription->mFormatFlags);
	NSLog(@"mBytesPerPacket: %u", (unsigned int)inDescription->mBytesPerPacket);
	NSLog(@"mFramesPerPacket: %u", (unsigned int)inDescription->mFramesPerPacket);
	NSLog(@"mBytesPerFrame: %u", (unsigned int)inDescription->mBytesPerFrame);
	NSLog(@"mChannelsPerFrame: %u", (unsigned int)inDescription->mChannelsPerFrame);
	NSLog(@"mBitsPerChannel: %u", (unsigned int)inDescription->mBitsPerChannel);
	NSLog(@"mReserved: %u", (unsigned int)inDescription->mReserved);
	
	NSAssert((inDescription->mFormatID == 778924083 ||
			  inDescription->mFormatID == 1633772334 ||
			  inDescription->mFormatID == 1633772320), @"Must be MP3 or AAC");
	
	AudioStreamBasicDescription audioStreamDescription;
	memcpy(&audioStreamDescription, inDescription, sizeof(AudioStreamBasicDescription));
	NSAssert(inDescription->mSampleRate == 44100.0, @"Sample rate must be 44100.");
	
	
	AudioStreamBasicDescription currentDescription = [delegate audioQueueUsedAudioStreamBasicDescription];
	if (currentDescription.mFormatID == inDescription->mFormatID &&
		currentDescription.mSampleRate == inDescription->mSampleRate &&
		currentDescription.mFormatFlags == inDescription->mFormatFlags &&
		currentDescription.mBytesPerPacket == inDescription->mBytesPerPacket &&
		currentDescription.mFramesPerPacket == inDescription->mFramesPerPacket &&
		currentDescription.mBytesPerFrame == inDescription->mBytesPerFrame &&
		currentDescription.mChannelsPerFrame == inDescription->mChannelsPerFrame &&
		currentDescription.mBitsPerChannel == inDescription->mBitsPerChannel) {
		return;
	}
	
	AudioStreamBasicDescription *desciption = calloc(sizeof(AudioStreamBasicDescription), 1);
	memcpy(desciption, inDescription, sizeof(AudioStreamBasicDescription));
	
	[delegate parsedDifferentFromAudioQueueUesdAudioStreamBasicDescription:desciption];
}
- (void)audioStreamParser:(SKAudioParser *)inParser packetData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount
{
	[buffer storePacketData:inBytes dataLength:inLength packetDescriptions:inPacketDescriptions packetsCount:inPacketsCount];
}

#pragma mark - buffer delegate

- (AudioStreamBasicDescription)usedAudioStreamBasicDescription
{
	return [delegate audioQueueUsedAudioStreamBasicDescription];
}

- (void)audioBufferDidBeginReadPacket:(SKAudioBuffer *)inBuffer
{
	[delegate audioDataProcessorDidStartPrepareAudioPacket:self];
}


@synthesize delegate;
@synthesize buffer;
@synthesize parser;
@end
