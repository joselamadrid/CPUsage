//
//  AppDelegate.m
//  CPUsage
//
//  Created by Josemac on 25.10.12.
//  Copyright (c) 2012 Jose. All rights reserved.
//

#import "AppDelegate.h"
#include <stdlib.h>

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    int mib[2U] = { CTL_HW, HW_NCPU };
    size_t sizeOfNumCPUs = sizeof(numCPUs);
    int status = sysctl(mib, 2U, &numCPUs, &sizeOfNumCPUs, NULL, 0U);
    if(status)
        numCPUs = 1;

    CPUUsageLock = [[NSLock alloc] init];

    updateTimer = [[NSTimer scheduledTimerWithTimeInterval:1
                                                    target:self
                                                  selector:@selector(updateInfo:)
                                                  userInfo:nil
                                                   repeats:YES] retain];
}

- (void)updateInfo:(NSTimer *)timer
{
    natural_t numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
    if(err == KERN_SUCCESS)
    {
        [CPUUsageLock lock];
        float avgTotal;
        for(unsigned i = 0U; i < numCPUs; ++i)
        {
            float inUse, total;
            if(prevCpuInfo)
            {
                inUse = (
                         (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                         + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                         + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                         );
                total = inUse + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            }
            else
            {
                inUse = cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                total = inUse + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }

            //NSLog(@"Core: %u Usage: %f",i,inUse / total);
            avgTotal += (inUse / total) * 100;
        }
        [CPUUsageLock unlock];

        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%i", (int)avgTotal/numCPUs]];

        if(prevCpuInfo)
        {
            size_t prevCpuInfoSize = sizeof(integer_t) * numPrevCpuInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)prevCpuInfo, prevCpuInfoSize);
        }

        prevCpuInfo = cpuInfo;
        numPrevCpuInfo = numCpuInfo;

        cpuInfo = NULL;
        numCpuInfo = 0U;
    } else {
        NSLog(@"Error!");
        [NSApp terminate:nil];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [updateTimer release];
    [CPUUsageLock release];
    return NSTerminateNow;
}

@end
