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

#import "ImageDocument.h"
#import "FLIFImage.h"

@interface ImageDocument ()

@end

@implementation ImageDocument

- (void)dealloc {
    if (self.cgImageRef) {
        CGImageRelease(self.cgImageRef);
    }
}

+ (BOOL)autosavesInPlace {
    return NO;
}

- (void)makeWindowControllers {
    [self addWindowController:[[NSStoryboard storyboardWithName:@"Main" bundle:nil]
                               instantiateControllerWithIdentifier:@"Document Window Controller"]];
}

- (nullable NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return self.data;
}

- (BOOL)readFromData:(NSData *)theData ofType:(NSString *)typeName error:(NSError **)outError {
    
    BOOL readSuccess = NO;
    *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSFileReadUnknownError
                                userInfo:nil];
    
    if (theData != nil) {
        CGImageRef imgRef = [FLIFImage CGImageFromFLIFData:theData];
        if (imgRef) {
            self.cgImageRef = imgRef;
            self.data = theData;
            readSuccess = YES;
            *outError = nil;
        }
    }
    return readSuccess;
}

- (NSSize)dimensions {
    return NSMakeSize(CGImageGetWidth(self.cgImageRef),
                      CGImageGetHeight(self.cgImageRef));
}

@end
