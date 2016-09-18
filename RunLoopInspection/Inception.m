//
//  Inception.m
//  RunLoopInspection
//
//  Created by changtang on 16/9/13.
//  Copyright © 2016年 TCTONY. All rights reserved.
//

#import "Inception.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import "fishhook.h"

#pragma mark - demo
static int (*orig_open)(const char *, int, ...);
static int (*orig_close)(int);

int my_open(const char *path, int oflag, ...) {
    va_list ap = {0};
    mode_t mode = 0;

    if ((oflag & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_start(ap, oflag);
        mode = va_arg(ap, int);
        va_end(ap);
        printf("\n---------:Calling real open('%s', %d, %d)\n", path, oflag, mode);
        return orig_open(path, oflag, mode);
    } else {
        printf("\n---------:Calling real open('%s', %d)\n", path, oflag);
        return orig_open(path, oflag, mode);
    }
}

int my_close(int fd) {
    printf("\n---------:Calling real close(%d)\n", fd);
    return orig_close(fd);
}

void inception_demo(const char *argv0) {
    rebind_symbols((struct rebinding[2]){{"open", my_open, (void *)&orig_open}, {"close", my_close, (void *)&orig_close}}, 2);

    // Open our own binary and print out first 4 bytes (which is the same
    // for all Mach-O binaries on a given architecture)
    int fd = open(argv0, O_RDONLY);
    uint32_t magic_number = 0;
    read(fd, &magic_number, 4);
    printf("Mach-O Magic Number: %x\n", magic_number);
    close(fd);
}

#pragma mark - runloop

#define ENABLE_HOOK_OBSERVER    0
#define ENABLE_HOOK_SOURCE      0
#define ENABLE_HOOK_TIMER       1

#if ENABLE_HOOK_OBSERVER
static void (*orig_CFRunLoopAddObserver)(CFRunLoopRef, CFRunLoopObserverRef, CFRunLoopMode);
void my_CFRunLoopAddObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFRunLoopMode mode) {
    NSLog(@"\n---------:Calling CFRunLoopAddObserver(runloop(%p), %@, %@)\n\n",
          rl,
          observer,
          mode);
    orig_CFRunLoopAddObserver(rl, observer, mode);
}
#endif
#if ENABLE_HOOK_SOURCE
static void (*orig_CFRunLoopAddSource)(CFRunLoopRef rl, CFRunLoopSourceRef source, CFRunLoopMode mode);
void my_CFRunLoopAddSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFRunLoopMode mode) {
    NSLog(@"\n---------:Calling CFRunLoopAddSource(runloop(%p), %@, %@)\n\n",
          rl,
          source,
          mode);
    orig_CFRunLoopAddSource(rl, source, mode);
}
#endif
#if ENABLE_HOOK_TIMER
static void (*orig_CFRunLoopAddTimer)(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFRunLoopMode mode);
void my_CFRunLoopAddTimer(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFRunLoopMode mode) {
    NSLog(@"\n---------:Calling CFRunLoopAddTimer(runloop(%p), %@, %@)\n\n",
          rl,
          timer,
          mode);
    orig_CFRunLoopAddTimer(rl, timer, mode);
}
#endif


static struct rebinding rebindings[] = {
#if ENABLE_HOOK_OBSERVER
    { "CFRunLoopAddObserver",
        my_CFRunLoopAddObserver,
        (void *)&orig_CFRunLoopAddObserver },
#endif
#if ENABLE_HOOK_SOURCE
    { "CFRunLoopAddSource",
        my_CFRunLoopAddSource,
        (void *)&orig_CFRunLoopAddSource },
#endif
#if ENABLE_HOOK_TIMER
    { "CFRunLoopAddTimer",
        my_CFRunLoopAddTimer,
        (void *)&orig_CFRunLoopAddTimer },
#endif
};

void inception_runloop() {
    rebind_symbols(rebindings, sizeof(rebindings)/sizeof(struct rebinding));
}