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

#import "ImageViewController.h"
#import "ImageDocument.h"
#import "PhewWindowController.h"

@interface ImageViewController ()
{
    IBOutlet IKImageView *imageView;
    IBOutlet NSScrollView *scrollView;
    PhewWindowController *windowController;
}
@end

@implementation ImageViewController

- (IKImageView *)imageView {
    return imageView;
}

#pragma mark -

- (void)viewWillAppear {
    [super viewWillAppear];
    
    if (!imageView) {
        imageView = [[IKImageView alloc] initWithFrame:self.view.frame];
        [imageView setHasVerticalScroller:YES];
        [imageView setHasHorizontalScroller:YES];
        [imageView setAutohidesScrollers:YES];
        [imageView setAutoresizes:YES];
        [imageView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [imageView setDelegate:self];
        [imageView setBackgroundColor:[NSColor colorWithRed:0.87 green:0.87 blue:0.87 alpha:1.0]];
        //[scrollView setDocumentView:imageView];
        //[scrollView.documentView addSubview:imageView];
        [self.view addSubview:imageView];
    }
    
    windowController = self.view.window.windowController;
    ImageDocument *imgDoc = windowController.document;
    
    if (imgDoc) {
        
        [imageView setImage:[imgDoc CGImage] imageProperties:@{}];        
        
        BOOL fits = [windowController setToIdealSize];
        if (fits) {
            [imageView setZoomFactor:1.0];
        } else {
            self.fitToSize = YES;
            [imageView zoomImageToFit:self];
        }

        
        [windowController updateTitle];
        [self setRepresentedObject:imgDoc];
    }
}
    
- (void)viewDidDisappear {
    [imageView setImage:NULL imageProperties:nil];
    [imageView setImageWithURL:nil];
    imageView = nil;
}

- (void)windowDimensionsChanged {
    if (self.fitToSize) {
        [CATransaction begin];
        [CATransaction setValue:@(0.f) forKey:kCATransactionAnimationDuration];
        [imageView zoomImageToFit:self];
        [CATransaction commit];
    }
}
    
#pragma mark - IKImageViewDelegate
    
-(void) imageWillChange: (IKImageView *) imageView {
    
}

#pragma mark -

- (IBAction)imageScaleChangedInMenu:(id)sender {
     NSString *str = [sender title];
    
    if ([str isEqualToString:@"Zoom to Fit"]) {
        [self zoomToFit:self];
    } else {
        NSArray *items = [str componentsSeparatedByString:@" "];
        NSString *cmd = items[0];
        NSString *percStr = [cmd substringToIndex:3];
        CGFloat factor = [percStr intValue]/100.f;
        [self setImageZoomFactor:factor];
    }
    [windowController updateTitle];
}

- (IBAction)zoomToFit:(id)sender {
    self.fitToSize = YES;
    [imageView zoomImageToFit:self];
}

- (IBAction)actualSize:(id)sender {
    [self setImageZoomFactor:1.0];
}

- (void)setImageZoomFactor:(CGFloat)factor {
    self.fitToSize = NO;
    [imageView setZoomFactor:factor];
}

@end
