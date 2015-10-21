//
//  SKAudioQueue.m
//  SKAudioQueue
//
//  Created by steven on 2015/1/22.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "SKAudioQueue.h"

AudioStreamBasicDescription MP3AudioStreamDescription(void) {
	AudioStreamBasicDescription sourceFormat;
	bzero(&sourceFormat, sizeof(AudioStreamBasicDescription));
	sourceFormat.mSampleRate = 44100.0;
	sourceFormat.mFormatID = kAudioFormatMPEGLayer3;
	sourceFormat.mFormatFlags = 0;
	sourceFormat.mBytesPerPacket = 0;
	sourceFormat.mFramesPerPacket = 1152;
	sourceFormat.mBytesPerFrame = 0;
	sourceFormat.mChannelsPerFrame = 2;
	sourceFormat.mBitsPerChannel = 0;
	sourceFormat.mReserved = 0;
	return sourceFormat;
}

void audioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void audioQueuePropertyListenerProc(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

@implementation SKAudioQueue

- (void)dealloc
{
	[self _zapQueue];
	[self _zapTimer];
}

- (void)_zapQueue
{
	if (!audioQueue) {
		return;
	}
	delegate = nil;
	
	__unused OSStatus status;
	
	status = AudioQueueStop(audioQueue, YES);
	
	status = AudioQueueReset(audioQueue);
	
	status = AudioQueueDispose(audioQueue, YES);

	
	audioQueue = NULL;
}

- (id)init
{
	self = [super init];
	if (self) {
		audioStreamDescription = MP3AudioStreamDescription();
		
		OSStatus status;
		status = AudioQueueNewOutput(&audioStreamDescription, audioQueueOutputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue);
		status = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueuePropertyListenerProc, (__bridge void *)(self));
		status = AudioQueueGetParameter(audioQueue, kAudioQueueParam_Volume, &deviceVolume);
		
		UInt32 val = kAudioQueueHardwareCodecPolicy_PreferSoftware;
		AudioQueueSetProperty(audioQueue, kAudioQueueProperty_HardwareCodecPolicy, &val, sizeof(UInt32));
		
	}
	return self;
}

- (id)initWithAudioStreamDescription:(AudioStreamBasicDescription *)description
{
	if ((self = [super init])) {
		audioStreamDescription = *description;
		
		OSStatus status;
		status = AudioQueueNewOutput(&audioStreamDescription, audioQueueOutputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue);
		NSAssert(noErr == status, @"Must create audio queue %d", (int)status);
		
		status = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueuePropertyListenerProc, (__bridge void *)(self));
		NSAssert(noErr == status, @"Must add property listener %d", (int)status);
		
		status = AudioQueueGetParameter(audioQueue, kAudioQueueParam_Volume, &deviceVolume);
		NSAssert(noErr == status, @"Must get device volume %d", (int)status);
#if TARGET_OS_IPHONE
		UInt32 val = kAudioQueueHardwareCodecPolicy_PreferSoftware;
		AudioQueueSetProperty(audioQueue, kAudioQueueProperty_HardwareCodecPolicy, &val, sizeof(UInt32));
#endif
		
	}
	return self;
}

- (void)reset
{
    requestPlay = NO;
    volumeOffset = 0.0;
}

- (void)_zapTimer
{
	if ([playingTimeTracker isValid] && [playingTimeTracker respondsToSelector:@selector(invalidate)]) {
		[playingTimeTracker invalidate];
	}
	playingTimeTracker = nil;
}

- (void)_scheduleTimer
{
	[self _zapTimer];
	playingTimeBase = [self _currentDevicePlayingTime];
	playingTimeTracker = [NSTimer timerWithTimeInterval:1/60.0 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:playingTimeTracker forMode:NSRunLoopCommonModes];
	[playingTimeTracker fire];
}

- (void)handleTimer:(NSTimer *)inTimer
{
	[delegate audioQueue:self updateElapsedTime:[self _elapsedPlayingTime]];
}

- (NSTimeInterval)_currentDevicePlayingTime
{
	return [[NSProcessInfo processInfo] systemUptime];
}

- (NSTimeInterval)_elapsedPlayingTime
{
	return [self _currentDevicePlayingTime] - playingTimeBase;
}

- (BOOL)matchAudioStreamBasicDescription:(AudioStreamBasicDescription *)description
{
    if (description->mFormatID == audioStreamDescription.mFormatID &&
        description->mSampleRate == audioStreamDescription.mSampleRate &&
        description->mFormatFlags == audioStreamDescription.mFormatFlags &&
        description->mBytesPerPacket == audioStreamDescription.mBytesPerPacket &&
        description->mBytesPerFrame == audioStreamDescription.mBytesPerFrame &&
        description->mChannelsPerFrame == audioStreamDescription.mChannelsPerFrame &&
        description->mBitsPerChannel == audioStreamDescription.mBitsPerChannel) {
        return YES;
    }
    return NO;
}

- (void)play
{
	if (playing) {
		return;
	}
	
	[delegate audioQueueWillStart:self];
	
	requestPlay = YES;
	[self updateVolumeLevel];
	
	dataRequestSuspended = YES;
    AudioQueueReset(audioQueue);
	dataRequestSuspended = NO;
	
	primed = NO;
	
	[delegate requestDataWithCallback:^(const void **dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions) {
		
		if (![self _enqueueData:dataPackets packetCount:packetCount packetDescriptions:packetDescriptions]) {
			return;
		}
		OSStatus status;
		status = AudioQueueStart(audioQueue, NULL);
        if (status != noErr) {
            [delegate audioQueueDidStop:self];
        }
		
	}];
}

- (void)pause
{
	if (![self audioQueueRunning]) {
		return;
	}
	dataRequestSuspended = YES;
	
	OSStatus status;
	status = AudioQueuePause(audioQueue);
	status = AudioQueueStop(audioQueue, true);
	status = AudioQueueReset(audioQueue);
	[self _zapTimer];
	playing = NO;
    [delegate audioQueueDidStop:self];
	dataRequestSuspended = NO;
}

- (void)stop
{
	if (![self audioQueueRunning]) {
		return;
	}
	
	[self _zapTimer];
	dataRequestSuspended = YES;
	
	OSStatus status;
	
	status = AudioQueueStop(audioQueue, YES);
	
	status = AudioQueueReset(audioQueue);
	
	dataRequestSuspended = NO;
	
}

- (void)updateVolumeLevel
{
	currentVolume = deviceVolume;
	
	if (volumeOffset != 0) {
		currentVolume += volumeOffset;
		if (currentVolume > 1.0) currentVolume = 1.0;
		if (currentVolume < 0.0) currentVolume = 0.0;
	}
	
	__unused OSStatus status = AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, currentVolume);
	NSAssert(noErr == status, @"Must set device volume");
}

- (BOOL)_enqueueData:(const void **)inDataPackets packetCount:(UInt32)inCount packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions
{
	OSStatus status;
	
	if (!inCount) {
		return YES;
	}
	
	UInt32 totalSize = 0;
	UInt32 index;
	
	for (index = 0 ; index < inCount ; index++) {
		totalSize += inPacketDescriptions[index].mDataByteSize;
	}
	
	AudioQueueBufferRef buffer;
	status = AudioQueueAllocateBuffer(audioQueue, totalSize, &buffer);
	if (noErr != status) {
		return NO;
	}
	
	buffer->mAudioDataByteSize = totalSize;
	
	for (index = 0 ; index < inCount ; index++) {
		memcpy(buffer->mAudioData + inPacketDescriptions[index].mStartOffset, inDataPackets[index], inPacketDescriptions[index].mDataByteSize);
	}
	
	status = AudioQueueEnqueueBuffer(audioQueue, buffer, inCount, inPacketDescriptions);
	if (noErr != status) {
		return NO;
	}
	
	if (!primed) {
		UInt32 preparedFrames = 0;
		
		status = AudioQueuePrime(audioQueue, inCount, &preparedFrames);
		if (status == noErr) {
			primed = YES;
		}
		else {
			return NO;
		}
	}
	
	return YES;
}


- (BOOL)audioQueueRunning
{
	UInt32 propertyValue = 0;
	UInt32 propertySize = sizeof(propertyValue);
	OSStatus status;
	status = AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &propertyValue, &propertySize);
	
	return propertyValue != 0;
}

- (void)propertyUpdate:(AudioQueuePropertyID)inPropertyID
{
	if (inPropertyID != kAudioQueueProperty_IsRunning) {
		return;
	}
	if (!playing && [self audioQueueRunning]) {
		playing = YES;
        [delegate audioQueueDidStart:self];
		[self _scheduleTimer];
	}
	else if (playing && ![self audioQueueRunning]) {
		playing = NO;
        [delegate audioQueueDidStop:self];
	}
}

- (void)audioQueueOutputCallback:(AudioQueueBufferRef)inBuffer
{
	if (inBuffer) {
		__unused OSStatus status = AudioQueueFreeBuffer(audioQueue, inBuffer);
	}
	
	if (!dataRequestSuspended) {
		[delegate requestDataWithCallback:^(const void **dataPackets, UInt32 packetCount, AudioStreamPacketDescription *packetDescriptions) {
			
			[self _enqueueData:dataPackets packetCount:packetCount packetDescriptions:packetDescriptions];
		}];
	}
	
}

@synthesize delegate;
@synthesize audioStreamDescription;
@synthesize requestPlay;
@synthesize playing;
@synthesize currentVolume;
@synthesize volumeOffset;
@end


void audioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	[(__bridge SKAudioQueue *)inUserData audioQueueOutputCallback:inBuffer];
}
void audioQueuePropertyListenerProc(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	[(__bridge SKAudioQueue *)inUserData propertyUpdate:inID];
}
