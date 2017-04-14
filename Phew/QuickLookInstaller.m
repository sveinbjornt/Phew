/*
 Copyright (c) 2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

#import "QuickLookInstaller.h"
#import "STPrivilegedTask.h"

#define kQuickLookLibraryFolder @"/Library/QuickLook/"
#define kQuickLookHomeFolder    [@"~/Library/QuickLook/" stringByExpandingTildeInPath]

@implementation QuickLookInstaller

+ (NSArray *)installLocationsForPlugin:(NSString *)pluginName {
    
    NSString *libQLPluginPath = [NSString stringWithFormat:@"%@%@.qlgenerator", kQuickLookLibraryFolder, pluginName];
    NSString *homeQLPluginPath = [NSString stringWithFormat:@"%@/%@.qlgenerator", kQuickLookHomeFolder, pluginName];
    
    NSMutableArray *items = [NSMutableArray array];
    
    for (NSString *path in @[libQLPluginPath, homeQLPluginPath]) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSString *plistPath = [NSString stringWithFormat:@"%@/Contents/Info.plist", path];
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            float bundleVersion = [plist[@"CFBundleShortVersionString"] floatValue];
            
            NSDictionary *itemInfo = @{ @"path": path, @"version": [NSNumber numberWithFloat:bundleVersion] };
            [items addObject:itemInfo];
        }
    }
    
    return [NSArray arrayWithArray:items];
}

// returns 0 for none installed
+ (CGFloat)versionCurrentlyInstalled:(NSString *)pluginName {
    CGFloat version = 0.f;
    for (NSDictionary *item in [QuickLookInstaller installLocationsForPlugin:pluginName]) {
        if ([item[@"version"] floatValue] > version) {
            version = [item[@"version"] floatValue];
        }
    }
    return version;
}

+ (BOOL)uninstallPlugin:(NSString *)pluginName {
    NSArray *items = [QuickLookInstaller installLocationsForPlugin:pluginName];
    
    for (NSDictionary *i in items) {
        BOOL needsAdmin = ![[NSFileManager defaultManager] isDeletableFileAtPath:i[@"path"]];
        NSString *binary = @"/bin/rm";
        NSArray *args = @[@"-r", i[@"path"]];
        if (needsAdmin) {
            [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:binary arguments:args];
        } else {
            [NSTask launchedTaskWithLaunchPath:binary arguments:args];
        }
    }
    
    return YES;
}

+ (BOOL)installPluginAtPath:(NSString *)pluginPath forUserOnly:(BOOL)userOnly {
    BOOL isDir = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (!([fm fileExistsAtPath:pluginPath isDirectory:&isDir] && isDir)) {
        NSLog(@"No plugin at path: %@", pluginPath);
        return NO;
    }
    
    NSString *dir = userOnly ? kQuickLookHomeFolder : kQuickLookLibraryFolder;
    if (![dir hasSuffix:@"/"]) {
        dir = [dir stringByAppendingString:@"/"];
    }
    
    BOOL needsAdmin = ![fm isWritableFileAtPath:dir];
    
    NSString *binary = @"/bin/cp";
    NSArray *args = @[@"-r", pluginPath, dir];
    
    if (needsAdmin) {
        [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:binary arguments:args];
    } else {
        [NSTask launchedTaskWithLaunchPath:binary arguments:args];
    }
    
    return YES;
}

@end
