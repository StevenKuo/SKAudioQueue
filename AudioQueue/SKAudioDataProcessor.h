//
//  SKAudioDataProcessor.h
//  SKAudioQueue
//
//  Created by steven on 2015/1/23.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "SKAudioParser.h"
#import "SKAudioBuffer.h"

@class SKAudioDataProcessor;

@protocol SKAudioDataProcessorDelegate <NSObject>

- (AudioStreamBasicDescription)audioQueueUsedAudioStreamBasicDescription;

- (void)parsedDifferentFromAudioQueueUesdAudioStreamBasicDescription:(AudioStreamBasicDescription *)inAudioStreamBasicDescription;
- (void)audioDataProcessorDidStartPrepareAudioPacket:(SKAudioDataProcessor *)inProcessor;
@end

@interface SKAudioDataProcessor : NSObject
{
	__weak id <SKAudioDataProcessorDelegate> delegate;
	
	SKAudioParser *parser;
	SKAudioBuffer *buffer;
}


@property (weak, nonatomic) id <SKAudioDataProcessorDelegate> delegate;
@property (readonly, nonatomic) SKAudioBuffer *buffer;
@property (readonly, nonatomic) SKAudioParser *parser;
@end
