//
//  GzipUtil.m
//  Syncing
//
//  Created by Rodrigo Suhr on 10/15/15.
//  Copyright © 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "GzipUtil.h"
#import <zlib.h>
#import <dlfcn.h>

#pragma clang diagnostic ignored "-Wcast-qual"

@implementation GzipUtil

static void *libzOpen()
{
    static void *libz;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        libz = dlopen("/usr/lib/libz.dylib", RTLD_LAZY);
    });
    return libz;
}

+ (NSData *)gzippedDataWithCompressionLevel:(float)level withUnzippedData:(NSData *)unzippedData
{
    if (unzippedData.length == 0 || [GzipUtil isGzippedData:unzippedData])
    {
        return unzippedData;
    }
    
    void *libz = libzOpen();
    int (*deflateInit2_)(z_streamp, int, int, int, int, int, const char *, int) =
    (int (*)(z_streamp, int, int, int, int, int, const char *, int))dlsym(libz, "deflateInit2_");
    int (*deflate)(z_streamp, int) = (int (*)(z_streamp, int))dlsym(libz, "deflate");
    int (*deflateEnd)(z_streamp) = (int (*)(z_streamp))dlsym(libz, "deflateEnd");
    
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.avail_in = (uint)unzippedData.length;
    stream.next_in = (Bytef *)(void *)unzippedData.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;
    
    static const NSUInteger ChunkSize = 16384;
    
    NSMutableData *output = nil;
    int compression = (level < 0.0f)? Z_DEFAULT_COMPRESSION: (int)(roundf(level * 9));
    if (deflateInit2(&stream, compression, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY) == Z_OK)
    {
        output = [NSMutableData dataWithLength:ChunkSize];
        while (stream.avail_out == 0)
        {
            if (stream.total_out >= output.length)
            {
                output.length += ChunkSize;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            deflate(&stream, Z_FINISH);
        }
        deflateEnd(&stream);
        output.length = stream.total_out;
    }
    
    return output;
}

+ (NSData *)gzippedData:(NSData *)unzippedData;
{
    return [GzipUtil gzippedDataWithCompressionLevel:-1.0f withUnzippedData:unzippedData];
}

+ (NSData *)gunzippedData:(NSData *)zippedData
{
    if (zippedData.length == 0 || ![GzipUtil isGzippedData:zippedData])
    {
        return zippedData;
    }
    
    void *libz = libzOpen();
    int (*inflateInit2_)(z_streamp, int, const char *, int) =
    (int (*)(z_streamp, int, const char *, int))dlsym(libz, "inflateInit2_");
    int (*inflate)(z_streamp, int) = (int (*)(z_streamp, int))dlsym(libz, "inflate");
    int (*inflateEnd)(z_streamp) = (int (*)(z_streamp))dlsym(libz, "inflateEnd");
    
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.avail_in = (uint)zippedData.length;
    stream.next_in = (Bytef *)zippedData.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;
    
    NSMutableData *output = nil;
    if (inflateInit2(&stream, 47) == Z_OK)
    {
        int status = Z_OK;
        output = [NSMutableData dataWithCapacity:zippedData.length * 2];
        while (status == Z_OK)
        {
            if (stream.total_out >= output.length)
            {
                output.length += zippedData.length / 2;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            status = inflate (&stream, Z_SYNC_FLUSH);
        }
        if (inflateEnd(&stream) == Z_OK)
        {
            if (status == Z_STREAM_END)
            {
                output.length = stream.total_out;
            }
        }
    }
    
    return output;
}

+ (BOOL)isGzippedData:(NSData *)zippedData
{
    const UInt8 *bytes = (const UInt8 *)zippedData.bytes;
    return (zippedData.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b);
}

@end
