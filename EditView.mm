#import "EditView.h"

@implementation EditView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		// Add initialization code here
        drag.pixelState = 0;
        drag.lastX = -1;
        drag.lastY = -1;
		for (unsigned i = 0; i < sizeof highlightRow / sizeof highlightRow[0]; i++)
		{
		    highlightRow[i] = false;
		}
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
    CGRect frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    CGRect region = CGRectMake(rect.origin.x + 5.0, rect.origin.y + 4.0, rect.size.width - 10.0, rect.size.height - 8.0);
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetGrayFillColor(context, 0.6, 1.0);
    CGContextFillRect(context, frame);

    if (isFirstResponder)
    {
        CGContextSetRGBStrokeColor(context, 0.3, 0.35, 0.95, 1.0);
        CGContextSetLineWidth(context, 4.0);
        CGContextStrokeRect(context, frame);
    }
    
    
    NeoCharacter *character = [neoFontEditor character];

    int character_width = character->width();
    int character_height = character->height();
    
    float display_width = region.size.width;
    float display_height = region.size.height;

    float pixel_size = 16;

    if ((pixel_size * character_width) + 1 >= display_width)
    {
        pixel_size = (display_width - 1) / character_width;
    }
    if ((pixel_size * character_height) + 1 >= display_height)
    {
        pixel_size = (display_height - 1) / character_height;
    }

    float horizontal_offset = region.origin.x + (display_width - ((float)character_width * pixel_size)) / 2.0;
    float vertical_offset = region.origin.y + (display_height - ((float)character_height * pixel_size)) / 2.0;

    
    for (int x = 0; x < character_width; x++)
    {
        for (int y = 0; y < character_height; y++)
        {
            int pixel_state = character->getPixel(x, (character_height - y - 1));

            CGContextSetRGBStrokeColor(context, 0.9, 0.9, 1.0, 0.75);
            if (pixel_state) CGContextSetRGBFillColor(context,  0.0, 0.0, 0.5 * (((double)y)/character_height), 0.75);
            else if (highlightRow[y]) CGContextSetRGBFillColor(context,  0.7, 0.7, 0.9, 0.75);
            else CGContextSetRGBFillColor(context,  0.8, 0.8, 1.0, 0.75);

            CGRect pixel_rect = CGRectMake(
                horizontal_offset + (x * pixel_size),
                vertical_offset + (y * pixel_size),
                pixel_size,
                pixel_size);

            CGContextSetLineWidth(context, 2.0);
            CGContextFillRect(context, pixel_rect);
            CGContextStrokeRect(context, pixel_rect);
        }
    }
}


- (BOOL)mouseCoordinates:(NSEvent *)event toPixelX:(int*)x y:(int*)y
{
    NSRect rect = [self bounds];
    CGRect region = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    NSPoint eventLocation = [event locationInWindow];
    NSPoint hit = [self convertPoint:eventLocation fromView:nil];
    
    NeoCharacter *character = [neoFontEditor character];

    int character_width = character->width();
    int character_height = character->height();
    
    float display_width = region.size.width;
    float display_height = region.size.height;

    float pixel_size = 16;

    if ((pixel_size * character_width) + 1 >= display_width)
    {
        pixel_size = (display_width - 1) / character_width;
    }
    if ((pixel_size * character_height) + 1 >= display_height)
    {
        pixel_size = (display_height - 1) / character_height;
    }

    float horizontal_offset = (display_width - ((float)character_width * pixel_size)) / 2.0;
    float vertical_offset = (display_height - ((float)character_height * pixel_size)) / 2.0;

    float fx = ((hit.x - horizontal_offset) / pixel_size);
    float fy = ((hit.y - vertical_offset) / pixel_size);
    
    if (fx >= 0.0 && fx < (pixel_size * character_width) && fy >= 0.0 && fy < (pixel_size * character_height))
    {
        *x = (int) fx;
        *y = (int) (character_height - ((int)fy) - 1);
        return YES;
    }
    else
    {
        *x = -1;
        *y = -1;
        return NO;
    }
}


- (void)rightMouseDown:(NSEvent *)event
{
    int x, y;    
    if ([self mouseCoordinates:event toPixelX:&x y:&y])
    {
        int row = [neoFontEditor character]->height() - y - 1;
		if (row < sizeof highlightRow / sizeof highlightRow[0])
		{
		    highlightRow[row] = !highlightRow[row];
        }
    }
    [self setNeedsDisplay:YES];
}


- (void)otherMouseDown:(NSEvent *)event
{
    [self rightMouseDown:event];
}


- (void)mouseDown:(NSEvent *)event
{
    if (0 != ([event modifierFlags] & NSControlKeyMask))
    {
        [self rightMouseDown:event];
    }
    else
    {
        int x, y;
        
        if ([self mouseCoordinates:event toPixelX:&x y:&y])
        {
            drag.pixelState = ([neoFontEditor pixelInCharacter:[neoFontEditor characterNumber] atX:x y:y]) ? 0 : 1;
            drag.lastX = x;
            drag.lastY = y;
            [neoFontEditor setPixelInCharacter:[neoFontEditor characterNumber] atX:x y:y to:drag.pixelState];
            [self setNeedsDisplay:YES];
        }
    }
}


- (void)mouseDragged:(NSEvent *)event
{
    int x, y;
    if ([self mouseCoordinates:event toPixelX:&x y:&y])
    {
        if (x != drag.lastX || y != drag.lastY)
        {
            drag.lastX = x;
            drag.lastY = y;
            [neoFontEditor setPixelInCharacter:[neoFontEditor characterNumber] atX:x y:y to:drag.pixelState];
            [self setNeedsDisplay:YES];
        }
    }
}


- (void)mouseUp:(NSEvent *)event
{
    drag.lastX = -1;
    drag.lastY = -1;
}


- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    if (!isFirstResponder) [self setNeedsDisplay:YES];
    isFirstResponder = true;
    return YES;
}

- (BOOL)resignFirstResponder
{
    if (isFirstResponder) [self setNeedsDisplay:YES];
    isFirstResponder = false;
    return YES;
}

@end
