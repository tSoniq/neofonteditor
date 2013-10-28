//
//  FontConverter.mm
//  NeoFontEditor
//
//  Created by Mark on 19/07/2006.
//  Copyright 2006 Alquanto. All rights reserved.
//

#include <math.h>
#import "FontConverter.h"
#import "NeoCharacterEncoding.h"


@implementation FontConverter


/** Find the pixel height of a font when rendered as a bitmap. This is a kludge to allow automatic
 *  scaling of the Mac font to match the Neo size. There seems to be no way to do this other than
 *	by trying it?
 *
 *	@return				The pixel height of the Neo font that is needed to render the indicated font.
 */
+ (float) pixelHeightOfFont:(NSFont*)font
{
	/* This code replicates what is in loadFont to ensure equivalent metrics.
	 */
    const int fontHeight = 128;
    const int maxFontWidth = fontHeight * 64;

    NSBitmapImageRep* bitmap = nil;
    
    bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:nil
        pixelsWide:maxFontWidth
        pixelsHigh:fontHeight
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace
        bytesPerRow:0
        bitsPerPixel:0];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [context setShouldAntialias:NO];
    [NSGraphicsContext setCurrentContext:context];
    
    /* Set the font attributes.
     */
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];

    NSMutableString *unicode_string = [[NSMutableString alloc] init];

    /* Find the maximum height of a character. There seems to be no obvious way to work out in advance
	 * what the actual hight of the font will be...
     */
	[unicode_string setString:@"Ay"];
        
	NSSize stringSize = [unicode_string sizeWithAttributes:attributes];

    [unicode_string release];
    [attributes release];
    [NSGraphicsContext restoreGraphicsState];
    [bitmap release];

	return ceil(stringSize.height);
}


/** Convert the specified MacOS font in to a Neo bitmap font.
 *
 *  @param  neo         The Neo font object to initialise.
 *  @param  mac         The Mac font identifier.
 */
+ (void)loadFont:(NeoFont*)neo from:(NSFont*)system
{
    const int fontHeight = neo->height();
    const int maxFontWidth = fontHeight * 64;

    NSRect offscreenRect = NSMakeRect(0.0, 0.0, (float)maxFontWidth, (float)fontHeight);

    NSBitmapImageRep* bitmap = nil;
    
    bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:nil
        pixelsWide:maxFontWidth
        pixelsHigh:fontHeight
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace
        bytesPerRow:0
        bitsPerPixel:0];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [context setShouldAntialias:NO];
    [NSGraphicsContext setCurrentContext:context];
    

    /* Set the font attributes.
     */
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:system forKey:NSFontAttributeName];
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];

    /* Loop over the characters to convert. The Neo uses UTF character maps.
     */
    NSMutableString *unicode_string = [[NSMutableString alloc] init];
    for (int code = 0; code < 256; code++)
    {
        [unicode_string setString:@""];
        [unicode_string appendFormat:@"%C", (unichar)NeoCharacterToUTF16(code)];
        
        NSPoint stringOrigin;
        NSSize stringSize;
    
        stringSize = [unicode_string sizeWithAttributes:attributes];
        stringOrigin.x = 0.0;
        stringOrigin.y = 0.0;
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:offscreenRect];
        [[NSColor blackColor] set];
        [unicode_string drawAtPoint:stringOrigin withAttributes:attributes];
    
        int width = ((int) ceil(stringSize.width));
		
        NeoCharacter *neo_character = neo->character(code);
        neo_character->setWidth(width);
        neo_character->clear();
        
        for (int y = 0; y < fontHeight; y++)
        {
            for (int x = 0; x < width; x++)
            {
                unsigned int p[4];
    
                [bitmap getPixel:p atX:x y:y];
    
                const float bright = ((float)(p[0] + p[1] + p[2]) / (3*256.0)) * ((float)p[3]) / 256;
                if (bright < 0.9) neo_character->setPixel(x,y);
            }
        }
    
    } // next character

    [unicode_string release];
    [NSGraphicsContext restoreGraphicsState];
    [bitmap release];
}


@end
