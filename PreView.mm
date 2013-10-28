#include <string.h>
#import "PreView.h"

@implementation PreView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
	{
		// Add initialization code here
        count = 0;
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
    CGRect region = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetGrayFillColor(context, 0.6, 1.0);
    CGContextFillRect(context, region);
    CGContextSetGrayFillColor(context, 0.0, 1.0);
    
	NeoFont *font = [neoFontEditor font];

    int character_height = font->height();
	float display_height = region.size.height;
    float pixel_size = 2;
    if ((pixel_size * character_height) + 1 >= display_height)
    {
        pixel_size = (display_height - 1) / character_height;
    }

    float vertical_offset = (display_height - ((float)character_height * pixel_size)) / 2.0;

    CGContextSetGrayFillColor(context, 0.3, 1.0);
    CGContextSetGrayStrokeColor(context, 0.5, 1.0);
    
    float x = 4.0;  // Leave some space to the left of the display.
	
	NSData *encoded_data = [[neoFontEditor previewString] dataUsingEncoding:NSWindowsCP1252StringEncoding allowLossyConversion:YES];
	const unsigned char *text = (const unsigned char *) [encoded_data bytes];
    const unsigned char *end = text + [encoded_data length];

    count = 0;
	
    while (text < end)
    {
        int code = *text ++;
        if (count < NeoFontEditorPreviewMaxCharacters)
        {
            positions[count] = x;
            characters[count] = code;
            count ++;
        }
        NeoCharacter *character = font->character(code);
        [neoFontEditor renderCharacter:character context:context x:x y:vertical_offset size:pixel_size];
        x += character->width() * pixel_size;
    }
    
    positions[count] = x;
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint eventLocation = [event locationInWindow];
    NSPoint hit = [self convertPoint:eventLocation fromView:nil];
    
    for (unsigned i = 0; i < count; i++)
    {
        if (hit.x >= positions[i] && hit.x < positions[i+1])
        {
            [neoFontEditor setCharacterNumber:characters[i]];
            break;
        }
    }
}

@end
