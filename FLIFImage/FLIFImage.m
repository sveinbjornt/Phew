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

#import "FLIFImage.h"

#import "flif.h"
#import <AppKit/AppKit.h>

static NSData *DecodeFLIFData(NSData *data, FLIF_IMAGE **image) {
    
    FLIF_DECODER *flif_dec = flif_create_decoder();
    if (!flif_dec) {
        NSLog(@"Error instantiating FLIF decoder");
        return nil;
    }
    
    flif_decoder_decode_memory(flif_dec, [data bytes], [data length]);
    
    // returns the number of frames (1 if it is not an animation)
    size_t image_count = flif_decoder_num_images(flif_dec);
    if (!image_count) {
        flif_destroy_decoder(flif_dec);
        NSLog(@"Image count 0");
        return nil;
    }
    
    FLIF_IMAGE *flifimage;
    flifimage = flif_decoder_get_image(flif_dec, 0);
    if (flifimage == NULL) {
        flif_destroy_decoder(flif_dec);
        NSLog(@"FLIF image is null from decoder");
        return nil;
    }
    
    *image = flifimage;
    
    size_t w = flif_image_get_width(flifimage);
    size_t h = flif_image_get_height(flifimage);
    
    size_t row_length = w * 4;
    size_t byte_length = h * row_length;
    
    // allocate buffer
    char *buf = calloc(byte_length, 1);
    if (!buf) {
        flif_destroy_decoder(flif_dec);
        NSLog(@"Could not alloc memory");
        return nil;
    }
    char *idx = (char *)buf;
    
    // read all rows into buffer
    for (int y = 0; y < h; y++)
    {
        flif_image_read_row_RGBA8(flifimage, y, idx, row_length);
        idx += row_length;
    }

    flif_destroy_decoder(flif_dec);
    
    return [NSData dataWithBytesNoCopy:buf length:byte_length freeWhenDone:YES];
}

@implementation FLIFImage

+ (BOOL)isFLIFImageAtPath:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]
                                         options:NSDataReadingMappedAlways
                                           error:nil];
    return [FLIFImage isFLIFImageData:data];
}

+ (BOOL)isFLIFImageData:(NSData *)data {
    if ([data length] < 4) {
        return NO;
    }
    
    NSData *headerMagicData = [data subdataWithRange:NSMakeRange(0, 4)];
    char magic[] = { 'F', 'L', 'I', 'F' }; // FLIF magic header
    NSData *flifHeaderMagicData = [NSData dataWithBytes:&magic length:4];
        
    return [headerMagicData isEqualToData:flifHeaderMagicData];
}

#pragma mark -

+ (NSImage *)newImageFromFLIFImageFileAtPath:(NSString *)path {
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data == nil) {
        return nil;
    }
    
    return [FLIFImage newImageFromFLIFData:data];
}

// It is the responsibility of the caller to dispose of
// the CGImageRef returned from this function

+ (CGImageRef)newCGImageFromFLIFImageFileAtPath:(NSString *)path {
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data) {
        return [FLIFImage newCGImageFromFLIFData:data];
    }
    
    return nil;
}

#pragma mark - 

+ (NSImage *)newImageFromFLIFData:(NSData *)data {
    
    FLIF_IMAGE *flifimage;
    NSData *pixelData = DecodeFLIFData(data, &flifimage);
    if (pixelData == nil) {
        return nil;
    }
    
    // get image info
    size_t w = flif_image_get_width(flifimage);
    size_t h = flif_image_get_height(flifimage);
    size_t row_length = w * 4;
    size_t channels = flif_image_get_nb_channels(flifimage);
    BOOL has_alpha = (channels > 3);
    
    // Create bitmap image rep
    //char *planes[] = { [pixelData bytes] };
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                         pixelsWide:w
                                                                         pixelsHigh:h
                                                                      bitsPerSample:8
                                                                    samplesPerPixel:channels
                                                                           hasAlpha:has_alpha
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                       bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
                                                                        bytesPerRow:row_length
                                                                       bitsPerPixel:4*8];
    if (imageRep == nil) {
        NSLog(@"Failed to create bitmap image rep");
        return nil;
    }
    
    // Copy pixel data over, that way it's no longer our responsibility
    memcpy([imageRep bitmapData], [pixelData bytes], [pixelData length]);
    
    // Create NSImage
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
    [image addRepresentation:imageRep];
    
    return image;
}

// It is the responsibility of the caller to dispose of
// the CGImageRef returned from this function

+ (CGImageRef)newCGImageFromFLIFData:(NSData *)data {
    
    FLIF_IMAGE *flifimage;
    NSData *pixelData = DecodeFLIFData(data, &flifimage);
    if (pixelData == nil) {
        return nil;
    }
    
    // Get image info
    size_t w = flif_image_get_width(flifimage);
    size_t h = flif_image_get_height(flifimage);
    size_t row_length = w * 4;
    size_t channels = flif_image_get_nb_channels(flifimage);
    BOOL has_alpha = (channels > 3);

    // Create CGImage
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)pixelData);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo info = has_alpha ? kCGBitmapByteOrderDefault | kCGImageAlphaLast : kCGBitmapByteOrderDefault;
    
    CGImageRef cgImageRef = CGImageCreate(w,
                                          h,
                                          8,
                                          32,
                                          row_length,
                                          colorspace,
                                          info,
                                          provider,
                                          NULL,
                                          true,
                                          kCGRenderingIntentDefault);
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    
    return cgImageRef;
}

@end
