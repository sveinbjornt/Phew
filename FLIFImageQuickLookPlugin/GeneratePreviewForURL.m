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

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Foundation/Foundation.h>
#include "FLIFImage.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

//    typedef NS_ENUM(NSInteger, QLPreviewMode)
//    {
//        kQLPreviewNoMode		= 0,
//        kQLPreviewGetInfoMode	= 1,	// File -> Get Info and Column view in Finder
//        kQLPreviewCoverFlowMode	= 2,	// Finder's Cover Flow view
//        kQLPreviewUnknownMode	= 3,
//        kQLPreviewSpotlightMode	= 4,	// Desktop Spotlight search popup bubble
//        kQLPreviewQuicklookMode	= 5,	// File -> Quick Look in Finder (also qlmanage -p)
//    }

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
    
    @autoreleasepool {
        
        NSString *path = [(__bridge NSURL *)url path];
        CGImageRef cgImgRef = [FLIFImage CGImageFromFLIFImageFileAtPath:path];
        
        if (cgImgRef == NULL) {
            QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, nil);
            return -1;
        }
        
        CGFloat width = CGImageGetWidth(cgImgRef);
        CGFloat height = CGImageGetHeight(cgImgRef);        
        
        // Add image dimensions to title
        NSString *newTitle = [NSString stringWithFormat:@"%@ (%d x %d)", [path lastPathComponent], (int)width, (int)height];
        
//        NSLog(@"Options: %@", [(__bridge NSDictionary *)options description]);
        
        NSDictionary *newOpt = @{   (NSString *)kQLPreviewPropertyDisplayNameKey : newTitle,
                                    (NSString *)kQLPreviewPropertyWidthKey : @(width),
                                    (NSString *)kQLPreviewPropertyHeightKey : @(height) };
        
        // Draw image
        CGContextRef ctx = QLPreviewRequestCreateContext(preview, CGSizeMake(width, height), YES, (__bridge CFDictionaryRef)newOpt);
        CGContextDrawImage(ctx, CGRectMake(0,0,width,height), cgImgRef);
        QLPreviewRequestFlushContext(preview, ctx);
        
        // Cleanup
        CGImageRelease(cgImgRef);
        CGContextRelease(ctx);
        
    }
    return kQLReturnNoError;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {
    // Implement only if supported
}
