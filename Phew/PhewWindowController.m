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

#import "PhewWindowController.h"
#import "ImageDocument.h"
#import "ImageViewController.h"

static inline NSRect AspectFitRectInRect(NSRect inRect, NSRect maxRect) {
    
    float originalAspectRatio = inRect.size.width / inRect.size.height;
    float maxAspectRatio = maxRect.size.width / maxRect.size.height;
    
    CGRect newRect = NSRectToCGRect(maxRect);
    if (originalAspectRatio > maxAspectRatio) {
        // scale by width
        newRect.size.height = maxRect.size.width * inRect.size.height / inRect.size.width;
        newRect.origin.y += (maxRect.size.height - newRect.size.height)/2.0;
    } else {
        newRect.size.width = maxRect.size.height  * inRect.size.width / inRect.size.height;
        newRect.origin.x += (maxRect.size.width - newRect.size.width)/2.0;
    }
    
    return NSRectFromCGRect(CGRectIntegral(newRect));
}

static BOOL CGImageWriteToFile(CGImageRef image, NSString *path, NSString *imageUTType) {
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, (CFStringRef)imageUTType, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
        CFRelease(destination);
        return NO;
    }
    
    CFRelease(destination);
    return YES;
}

static BOOL CGImageWritePixelDataToFile(CGImageRef image, NSString *path) {
    
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    UInt8 *buf = (UInt8 *)CFDataGetBytePtr(rawData);
    CFIndex length = CFDataGetLength(rawData);
    
    NSData *data = [NSData dataWithBytesNoCopy:buf length:length];
    BOOL success = [data writeToFile:path atomically:NO];
    
    data = nil;
    CFRelease(rawData);
    
    return success;
}

#pragma mark -

@interface PhewWindowController ()
{
    ImageViewController *viewController;
}

@property (retain) IBOutlet NSView *exportAccessoryView;
@property (weak) IBOutlet NSPopUpButton *exportFormatPopupButton;

@end

@implementation PhewWindowController

- (void)awakeFromNib {
    viewController = (ImageViewController *)self.contentViewController;
}

#pragma mark - Window Title

- (NSString *)generateTitle {
    NSSize imgSize = [(ImageDocument *)self.document dimensions];
    NSString *filename = [[[self.document fileURL] path] lastPathComponent];
    
    
    CGFloat zoom = [[viewController imageView] zoomFactor];
    int perc = (int)(zoom*100.f);
    NSString *newTitle = [NSString stringWithFormat:@"%@ (%d x %d) @ %d%%",
                          filename, (int)imgSize.width, (int)imgSize.height, perc];
    return newTitle;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [self generateTitle];
}

- (void)updateTitle {
    [[self window] setTitle:[self generateTitle]];
}

#pragma mark - Window Sizing

- (void)windowDidResize:(NSNotification *)notification {
    [viewController windowDimensionsChanged];
    if (viewController.fitToSize) {
        [self updateTitle];
    }
}

- (float)titleBarHeight {
    NSRect frame = NSMakeRect(0, 0, 100, 100);
    NSRect contentRect = [NSWindow contentRectForFrameRect:frame
                                                 styleMask:NSTitledWindowMask];
    return (frame.size.height - contentRect.size.height);
}

- (BOOL)setToIdealSize {
    
    NSRect visFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect newFrame = visFrame;
    
    // We need to fit window with titlebar + image inside visible frame
    ImageDocument *imgDoc = (ImageDocument *)self.document;
    NSSize imgSize = [imgDoc dimensions];
    imgSize.height += [self titleBarHeight];
    
    BOOL fits = !(visFrame.size.width < imgSize.width || visFrame.size.height < imgSize.height);
    
    if (!fits) {
        // aspect fit
        NSRect naturalFrame = NSMakeRect(0,0, imgSize.width, imgSize.height);
        newFrame = AspectFitRectInRect(naturalFrame, visFrame);
        newFrame.origin.x = visFrame.origin.x;
    } else {
        newFrame.size = imgSize;
    }
    
    // adjust to appear in top left corner
    newFrame.origin.y = visFrame.origin.y + visFrame.size.height - newFrame.size.height;
    
    [self.window setFrame:newFrame display:NO];
    
    return fits;    
}

#pragma mark - Exporting

- (IBAction)exportAs:(id)sender {
    
    // Create save panel and add our custom accessory view
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setPrompt:@"Save"];
    [sPanel setAccessoryView:self.exportAccessoryView];
    
    // Create *.png filename
    NSString *name = [[[[self.document fileURL] path] lastPathComponent] stringByDeletingPathExtension];
    name = [name stringByAppendingString:@".png"];
    [sPanel setNameFieldStringValue:name];
    
    //run save panel
    [sPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        
        if (result != NSModalResponseOK) {
            return;
        }
        
        NSString *path = [[sPanel URL] path];
        NSString *format = [self.exportFormatPopupButton titleOfSelectedItem];
        ImageDocument *imgDoc = (ImageDocument *)self.document;
        
        if ([format isEqualToString:@"Raw Pixel Data"]) {
            CGImageWritePixelDataToFile([imgDoc CGImage], path);
        } else {
            NSDictionary *formatMap = @{
                                        @"PNG":     (NSString *)kUTTypePNG,
                                        @"TIFF":    (NSString *)kUTTypeTIFF,
                                        @"BMP":     (NSString *)kUTTypeBMP
                                        };
            CGImageWriteToFile([imgDoc CGImage], path, formatMap[format]);
        }
        
    }];
}

- (IBAction)exportFormatChanged:(id)sender {
    NSSavePanel *panel = (NSSavePanel *)[sender window];
    
    NSString *format = [sender titleOfSelectedItem];
    NSDictionary *suffixMap = @{    @"PNG": @".png",
                                    @"BMP": @".bmp",
                                    @"TIFF": @".tiff",
                                    @"Raw Pixel Data": @".rgba" };
    NSString *suffix = suffixMap[format];
    
    NSString *currName = [panel nameFieldStringValue];
    NSString *newName = [currName stringByDeletingPathExtension];
    newName = [newName stringByAppendingString:suffix];
    
    [panel setNameFieldStringValue:newName];
}

@end
