#import "NavView.h"

@implementation NavView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
	}
	return self;
}

/** Re-draw the navigation display. 
 */
- (void)drawRect:(NSRect)rect
{
    CGRect region = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetGrayFillColor(context, 0.6, 1.0);
    CGContextFillRect(context, region);
    
    NeoCharacter *character = [neoFontEditor character];
    NeoFont *font = [neoFontEditor font];

    int character_width = character->width();
    int character_height = character->height();
    
    float display_width = region.size.width;
    float display_height = region.size.height;

    float pixel_size = 2;

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

    /* Render the current character.
     */
    CGContextSetGrayFillColor(context, 0.0, 1.0);
    [neoFontEditor renderCharacter:character context:context x:horizontal_offset y:vertical_offset size:pixel_size];

    /* Render following and preceeding characters.
     */
    CGContextSetGrayFillColor(context, 0.4, 1.0);
    float x = horizontal_offset;
    int character_number = [neoFontEditor characterNumber];
    for (unsigned int i = 1; i <= 32; i++)
    {
        x += (character->width() + 2.0) * pixel_size;
		if (x >= display_width) break;  // off right hand edge of visible display
        character = font->character((character_number + i) % kNeoFontCharacterCount);
        [neoFontEditor renderCharacter:character context:context x:x y:vertical_offset size:pixel_size];
    }
	x = horizontal_offset;
    for (unsigned int i = 1; i <= 32; i++)
    {
        character = font->character((character_number - i) % kNeoFontCharacterCount);
		if (x < 0.0) break;  // off left hand edge of visible display
        x -= (character->width() + 2.0) * pixel_size;
        [neoFontEditor renderCharacter:character context:context x:x y:vertical_offset size:pixel_size];
    }
}

- (void)mouseDown:(NSEvent *)event
{
    NSRect rect = [self bounds];
    CGRect region = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    NSPoint eventLocation = [event locationInWindow];
    NSPoint hit = [self convertPoint:eventLocation fromView:nil];
    

    NeoCharacter *character = [neoFontEditor character];
    NeoFont *font = [neoFontEditor font];

    int character_width = character->width();
    int character_height = character->height();
    
    float display_width = region.size.width;
    float display_height = region.size.height;

    float pixel_size = 2;

    if ((pixel_size * character_width) + 1 >= display_width)
    {
        pixel_size = (display_width - 1) / character_width;
    }
    if ((pixel_size * character_height) + 1 >= display_height)
    {
        pixel_size = (display_height - 1) / character_height;
    }


    float horizontal_offset = (display_width - ((float)character_width * pixel_size)) / 2.0;

    float x = horizontal_offset;
    int character_number = [neoFontEditor characterNumber];
    int matched_character = -1;
    for (unsigned int i = 1; matched_character < 0 && i <= 32; i++)
    {
        x += (character->width() + 2.0) * pixel_size;
		if (x >= display_width) break;  // off right hand edge of visible display
        character = font->character((character_number + i) % kNeoFontCharacterCount);

        if (hit.x >= x && hit.x < (x + (character->width() + 2.0) * pixel_size))
        {
            matched_character = character_number + i;
        }
    }
	x = horizontal_offset;
    for (unsigned int i = 1; matched_character < 0 && i <= 32; i++)
    {
        character = font->character((character_number - i) % kNeoFontCharacterCount);
		if (x < 0.0) break;  // off left hand edge of visible display
        x -= (character->width() + 2.0) * pixel_size;

        if (hit.x >= x && hit.x < (x + (character->width() + 2.0) * pixel_size))
        {
            matched_character = character_number - i;
        }
    }

    if (matched_character >= 0)
    {
        [neoFontEditor setCharacterNumber:matched_character];
    }
}

@end
