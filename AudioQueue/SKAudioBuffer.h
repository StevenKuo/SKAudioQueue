//
//  SKAudioBuffer.h
//  SKAudioQueue
//
//  Created by steven on 2015/1/22.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SKAudioBuffer;

@protocol SKAudioBufferDelegate <NSObject>

- (AudioStreamBasicDescription)usedAudioStreamBasicDescription;
- (void)audioBufferDidBeginReadPacket:(SKAudioBuffer *)inBuffer;
@end

@interface SKAudioBuffer : NSObject
{
	__weak id <SKAudioBufferDelegate> delegate;
	
	NSMutableData *audioData;
	NSMutableData *packetDescData;
	NSUInteger availablePacketCount;
	NSUInteger packetReadHead;
	NSUInteger readPacketIndex;
	
}


- (NSTimeInterval)availablePlayLength;

- (void)storePacketData:(const void * )inBytes dataLength:(UInt32)inLength packetDescriptions:(AudioStreamPacketDescription* )inPacketDescriptions packetsCount:(UInt32)inPacketsCount;

- (void)prepareDataWithCallback:(void (^)(const void ** dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions, BOOL noAvailablePacket))inCallback;

- (void)resetReadPacketIndexWithTime:(NSTimeInterval)inTime;

- (NSTimeInterval)readPacketTime;

@property (weak, nonatomic) id <SKAudioBufferDelegate> delegate;
@end
