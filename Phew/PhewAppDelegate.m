/*
 Phew - native, open-source FLIF image viewer for macOS
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

#import "PhewAppDelegate.h"
#import "QuickLookInstaller.h"
#import "NSWorkspace+Additions.h"

@interface PhewAppDelegate ()

@property (weak) IBOutlet NSMenuItem *installStatusMenuItem;
@property (weak) IBOutlet NSMenuItem *installActionMenuItem;

- (IBAction)installQuickLookPlugin:(id)sender;

@end

@implementation PhewAppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LaunchedPreviously"] == NO) {
    
        CGFloat v = [QuickLookInstaller versionCurrentlyInstalled:kPhewQuickLookPluginName];
        NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
        float appVersion = [plist[@"CFBundleShortVersionString"] floatValue];
        if (v == 0.f) {
            // suggest install
        } else if (v < appVersion) {
            // suggest update
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"LaunchedPreviously"];
    }
    
    [self updateQLPluginInstallStatus];
}

#pragma mark - QuickLook Plugin installer

- (void)updateQLPluginInstallStatus {
    NSArray *installedItems = [QuickLookInstaller installLocationsForPlugin:kPhewQuickLookPluginName];
    
    NSString *msg = [NSString stringWithFormat:@"%@ QuickLook Plugin not installed", kPhewQuickLookPluginName];
    if ([installedItems count]) {
        NSNumber *version = installedItems[0][@"version"];
        msg = [NSString stringWithFormat:@"%@ installed (v. %.1f)", kPhewQuickLookPluginName, [version floatValue]];
    }
    [self.installStatusMenuItem setTitle:msg];
    
    NSString *actionTitle = @"Install QuickLook Plugin";
    if ([installedItems count]) {
        actionTitle = @"Uninstall QuickLook Plugin";
    }
    [self.installActionMenuItem setTitle:actionTitle];
}

- (IBAction)installQuickLookPlugin:(id)sender {
    NSString *pluginName = kPhewQuickLookPluginName;
    if ([[sender title] hasPrefix:@"Uninstall"]) {
        [QuickLookInstaller uninstallPlugin:pluginName];
    } else {
        NSString *pluginPath = [[NSBundle mainBundle] pathForResource:pluginName ofType:@"qlgenerator"];
        [QuickLookInstaller installPluginAtPath:pluginPath forUserOnly:NO];
    }
    
    [self performSelector:@selector(updateQLPluginInstallStatus) withObject:nil afterDelay:1.0f];
}

#pragma mark - Web Links

- (IBAction)openReadMe:(id)sender {
    [[NSWorkspace sharedWorkspace] openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:@"ReadMe.html" ofType:nil]];
}

- (IBAction)openLicense:(id)sender {
    [[NSWorkspace sharedWorkspace] openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:@"License.html" ofType:nil]];
}

- (IBAction)visitWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sveinbjorn.org/phew"]];
}

- (IBAction)visitGitHubWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/sveinbjornt/Phew"]];
}

- (IBAction)makeADonation:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sveinbjorn.org/donations"]];
}

@end
