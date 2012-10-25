//
//  AppDelegate.h
//  CPUsage
//
//  Created by Josemac on 25.10.12.
//  Copyright (c) 2012 Jose. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	processor_info_array_t cpuInfo, prevCpuInfo;
	mach_msg_type_number_t numCpuInfo, numPrevCpuInfo;
	unsigned numCPUs;
	NSTimer *updateTimer;
	NSLock *CPUUsageLock;
}

@property (assign) IBOutlet NSWindow *window;

@end
