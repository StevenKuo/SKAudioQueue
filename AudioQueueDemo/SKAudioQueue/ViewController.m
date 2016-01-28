//
//  ViewController.m
//  SKAudioQueue
//
//  Created by steven on 2015/1/22.
//  Copyright (c) 2015年 KKBOX. All rights reserved.
//

#import "ViewController.h"
#import "SKAudioEngine.h"


@interface ViewController ()
{
	
	UILabel *playbackTimeLabel;
	UISlider *slider;
	SKAudioEngine *engine;
    BOOL getPlayLength;
}
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
	startButton.frame = CGRectMake(100.0, 100.0, 100.0, 100.0);
	[startButton setTitle:@"start" forState:UIControlStateNormal];
	[startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[startButton addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:startButton];
	
	UIButton *playButton = [UIButton buttonWithType:UIButtonTypeSystem];
	playButton.frame = CGRectMake(100.0, 200.0, 100.0, 100.0);
	[playButton setTitle:@"play" forState:UIControlStateNormal];
	[playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[playButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:playButton];
	
	UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
	pauseButton.frame = CGRectMake(100.0, 300.0, 100.0, 100.0);
	[pauseButton setTitle:@"pause" forState:UIControlStateNormal];
	[pauseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[pauseButton addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:pauseButton];
	
	playbackTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(200.0, 400.0, 50.0, 50.0)];
	playbackTimeLabel.text = @"00:00";
	playbackTimeLabel.textColor = [UIColor whiteColor];
	[self.view addSubview:playbackTimeLabel];
	
	slider = [[UISlider alloc] initWithFrame:CGRectMake(30.0, 500.0, self.view.frame.size.width - 60.0, 50.0)];
	slider.minimumValue = 0.0;
	[slider addTarget:self action:@selector(change:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:slider];

	engine = [[SKAudioEngine alloc] init];
	engine.delegate = (id)self;
    engine.enableCrossFade = YES;
	// Do any additional setup after loading the view, typically from a nib.
	
}

- (void)start:(id)sender
{
    UIButton *b = (UIButton *)sender;
    b.hidden = YES;
	[engine loadAudioContentWithURL:[NSURL URLWithString:@"https://s3-us-west-2.amazonaws.com/kkstevenbucket/0806d9c94785710f646501c0312b.mp3"]];
	
	// local file
//	[engine loadAudioContentWithPath:$(your file path)]];
}

- (void)play:(id)sender
{
	[engine play];
}

- (void)pause:(id)sender
{
	[engine pause];
}

- (void)change:(id)sender
{
	[engine seekToTime:slider.value];
}

- (void)audioEngine:(SKAudioEngine *)SKAudioEngine updateAvailablePlayTime:(NSTimeInterval)inAvailablePlayTime
{
	slider.maximumValue = inAvailablePlayTime;
    getPlayLength = YES;
}

- (void)audioEngine:(SKAudioEngine *)SKAudioEngine updatePlaybackTime:(NSTimeInterval)inPlaybackTime
{
	if (slider.state == UIControlStateNormal && getPlayLength) {
		slider.value = inPlaybackTime;
	}
	
	NSString *s = @"00:00";
	if (inPlaybackTime > 0) {
		NSUInteger seconds = fmod(inPlaybackTime, 60.0);
		NSUInteger minutes = inPlaybackTime / 60.0;
		
		s = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
	}
	[playbackTimeLabel setText:s];
}

- (void)audioEngineDidStartStreaming:(SKAudioEngine *)SKAudioEngine
{
	
}
- (void)audioEngineDidStopStreaming:(SKAudioEngine *)SKAudioEngine
{
	
}
- (void)audioEngineDidReadAudioPacket:(SKAudioEngine *)inAudioEngine
{
	
}
- (void)audioEngineDidEndPlaying:(SKAudioEngine *)inAudioEngine
{
	
}
- (void)audioEngineCompleteLoadingData:(SKAudioEngine *)inAudioEngine
{
	
}

- (void)audioEngineBeginCrossFade:(SKAudioEngine *)inAudioEngine
{
    [engine loadAudioContentWithURL:[NSURL URLWithString:@"https://s3-us-west-2.amazonaws.com/kkstevenbucket/ece985aece828873749cf0e0d699.mp3"]];
}

@end
