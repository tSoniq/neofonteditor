/** @file       NeoFontEditor.mm
 *  @brief      Wrapper for NeoFont to permit Cocoa message access to editing functions and to add editor state.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */

#include <math.h>
#include <stdint.h>
#import "NeoFontEditor.h"
#import "FontConverter.h"
#import "AppletID.h"
#import "NeoCharacterEncoding.h"


@implementation NeoFontEditor

/** Constructor.
 */
- (id)init
{
    if ((self = [super init]))
    {
        font = new NeoFont;
        characterNumber = 65;
        systemFont = [[NSFont systemFontOfSize:12.0] retain];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        canEditFullID = [defaults boolForKey:@"CanEditFullID"];

        if (!canEditFullID)
        {
            [self validateIdent];
        }
    }
    return self;
}

/** Destructor.
 */
- (void)dealloc
{
    if (0 != font) delete font;
    font = 0;
    [systemFont release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"NeoFontEditor";
}


// Add any code here that needs to be executed once the windowController has loaded the document's window.
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    /* Get the 'advanced' AppletID preference option. This is used to unlock editing of the applet ID and
     * font name strings. It can not be configured from the Font Editor - use a terminal and the 'defaults'
     * command.
     */


    /* Set some fields read-only if not in full editor mode.
     */
    NSColor *backColor = [NSColor windowBackgroundColor];
    [appletNameTextField setEditable:NO];
    [appletNameTextField setSelectable:NO];
    [appletNameTextField setBackgroundColor:backColor];
    if (!canEditFullID)
    {
        [appletInfoTextField setEditable:NO];
        [fontNameTextField setEditable:NO];

        [appletInfoTextField setSelectable:NO];
        [fontNameTextField setSelectable:NO];

        [appletInfoTextField setBackgroundColor:backColor];
        [fontNameTextField setBackgroundColor:backColor];

        [appletNameTextField setToolTip:@"This is the name of the Applet that is shown in AlphaSmart Manager. It is implicitly set from the 'Applet ID' pop-up menu."];
        [appletInfoTextField setToolTip:@"This is an additional information string, usually used for copyright attribution. It is implicitly set from the 'Applet ID' pop-up menu."];
        [fontNameTextField setToolTip:@"This is the name of the font, as shown on the Neo. It is implicitly set from the 'Applet ID' pop-up menu."];
    }
    else
    {
        [appletInfoTextField setEditable:YES];
        [fontNameTextField setEditable:YES];

        [appletNameTextField setToolTip:@"This is the name of the Applet that is shown in AlphaSmart Manager. It is implicitly set from the 'Font Name' box."];
        [appletInfoTextField setToolTip:@"This is an additional information string, usually used for copyright attribution. It is implicitly set from the 'Applet ID' pop-up menu."];
        [fontNameTextField setToolTip:@"This is the name of the font, as shown on the Neo. It is also used to set the Applet name that will be displayed in AlphaSmart Manager."];
    }


    // Populate the ident button menu.
    [identButton removeAllItems];
    [identButton setAutoenablesItems:NO];
    const int kNumUserMenus = (kAppletID_UserMax - kAppletID_UserMin + 1);
    for (int i = 0; i <  kNumUserMenus; i++)
    {
        NSString *name = [NSString stringWithFormat:@"Custom Font %d", (i+1)];
        [identButton addItemWithTitle:name];
        NSMenuItem *item = [identButton itemAtIndex:i];
        [item setTag:(i+kAppletID_UserMin)];
        [item setEnabled:YES];
    }

    if (canEditFullID)
    {
        [[[identButton lastItem] menu] addItem:[NSMenuItem separatorItem]];     // Dubious way to add a separator to the menu
        [identButton addItemWithTitle:@"other"];
        NSMenuItem *item = [identButton itemAtIndex:kNumUserMenus];
        [item setEnabled:NO];
        [item setTag:0];
        item = [identButton itemAtIndex:kNumUserMenus+1];
        [item setEnabled:YES];
        [item setTag:0];
    }
    
    [self redisplay];
}


/** Return a coded representation of the document for save operations.
 */
- (NSData *)dataOfType:(NSString*)typeName error:(NSError**)error
{
    if ([typeName isEqualTo:@"OS3KApp"])
	{
		NSMutableData *data = [[NSMutableData alloc] init];
		unsigned int length = font->appletSize();
		[data setLength:length];
		font->encodeApplet((uint8_t*)[data mutableBytes], [data length]);
        if (error) *error = nil;
	    return [data autorelease];
	}
	else
	{
        NSLog(@"NeoFontEditor: dataOfType: Unknown format %@\n", typeName);
        if (error) *error = [NSError errorWithDomain:@"Unrecognised file type" code:1 userInfo:nil];
        return nil;
	}
}



/** Method used to load data.
 */
- (BOOL)readFromData:(NSData*)data ofType:(NSString*)typeName error:(NSError**)error
{
    if ([typeName isEqualToString:@"OS3KApp"])
    {
        /* Neo smart applet.
         */
        bool result = font->decodeApplet((const uint8_t*)[data bytes], [data length]);
        if (!result)
        {
            [self redisplay];
            if (error) *error = [NSError errorWithDomain:@"Unable to parse Neo font data" code:1 userInfo:nil];
            return NO;
        }
        else
        {
            if (! canEditFullID)
            {
                if (font->ident() < kAppletID_UserMin || font->ident() > kAppletID_UserMax)
                {
                    // The following make it harder to accidentally overwrite an existing (non-user) font file
                    [self setFileURL:nil];
                    [self updateChangeCount:NSChangeReadOtherContents];
                }
            }
            [self validateIdent];
            [[self undoManager] removeAllActions];
            [self redisplay];
            if (error) *error = nil;
            return YES;
        }
    }
    else
    {
        /* Unknown format.
         */
        NSLog(@"NeoFontEditor: readFromData: Unknown format %@\n", typeName);
        if (error) *error = [NSError errorWithDomain:@"Unrecognised file type" code:1 userInfo:nil];
        [self redisplay];
        return NO;
    }
}



/** Archive a character to a data object.
 *
 *  @param  ch      The character number.
 *  @return         An NSData object containing the character.
 */
- (NSData*)archiveCharacter:(int)ch
{
    NeoCharacter *character = font->character(ch);
    NSMutableData *data = [NSMutableData dataWithLength:character->archiveSize()];
    character->saveArchive((uint8_t*)[data mutableBytes]);
    return data;
}



/** Restore a character from a data object.
 *
 *  @param  ch      The character number.
 *  @param  data    An NSData object containing the character data.
 */
- (void)restoreCharacter:(int)ch from:(NSData *)data
{
    NeoCharacter *character = font->character(ch);
    character->loadArchive((const uint8_t*)[data bytes]);   // Restore the character
}



/** Undo/redo handling for operations that require a single character to be archived.
 *
 *  @param  ch      The character number.
 *  @param  data    The character object, encoded as NSData. Pass nil if setting up an initial undo request.
 *  @param  reason  Reason string used to update the undo manager.
 */
- (void)handleUndo:(NSData *)data reason:(NSString *)reason character:(int)ch
{
    NeoCharacter *character = font->character(ch);

    /* Archive and save the current character.
     */
    NSMutableData *originalData = [NSMutableData dataWithLength:character->archiveSize()];
    character->saveArchive((uint8_t*)[originalData mutableBytes]);

    /* Load the specified data, if present.
     */
    if (nil != data)
    {
        assert([data length] == character->archiveSize());
        character->loadArchive((const uint8_t*)[data bytes]);   // Restore the character
        [self setCharacterNumber:ch];                           // Select the target character
        [self redisplay];                                       // Make sure that the display is updated
    }

    /* Update the undo stack.
     */
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] handleUndo:originalData reason:reason character:ch];
    if (! [undo isUndoing])  [undo setActionName:reason];
}


/** Undo/redo handling for operations that require the entire font to be archived..
 *
 *  @param  data    The character object, encoded as NSData. Pass nil if setting up an initial undo request.
 *  @param  reason  Reason string used to update the undo manager.
 */
- (void)handleUndo:(NSData *)data reason:(NSString *)reason
{
    /* Archive and save the current font.
     */
    NSMutableData *originalData = [NSMutableData dataWithLength:font->archiveSize()];
    font->saveArchive((uint8_t*)[originalData mutableBytes]);

    /* Load the specified data, if present.
     */
    if (nil != data)
    {
        assert([data length] == font->archiveSize());
        font->loadArchive((const uint8_t*)[data bytes]);        // Restore the font
        [self redisplay];                                       // Make sure that the display is updated
    }

    /* Update the undo stack.
     */
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] handleUndo:originalData reason:reason];
    if (! [undo isUndoing])  [undo setActionName:reason];
}



/** Return the current font.
 */
- (NeoFont *)font
{
    return font;
}


/** Return the current focus character reference.
 */
- (NeoCharacter *)character
{
    return font->character(characterNumber);
}


/** Set the width of character(s).
 *
 *  @param  ch      The character number, or -1 for all characters in the font.
 *  @param  w       The new width.
 */
- (void)setCharacter:(int)ch width:(int)w
{
    if (ch >= 0)
    {
        [self handleUndo:nil reason:@"set character width" character:ch];
        font->character(ch)->setWidth(w);
    }
    else
    {
        [self handleUndo:nil reason:@"set character width (all)"];
        for (unsigned i = 0; i < kNeoFontCharacterCount; i++)
        {
            font->character(i)->setWidth(w);
        }
    }

    [self redisplay];    
}


/** Relative character width change.
 *
 *  @param  ch      The character number, or -1 for all characters in the font.
 *  @param  delta   The change to apply to the character width (eg: +1 to increment, -1 to decrement).
 */
- (void)setCharacter:(int)ch widthDelta:(int)delta
{
    if (ch >= 0)
    {
        [self handleUndo:nil reason:@"adjust character width" character:ch];
        font->character(ch)->setWidth(font->character(ch)->width() + delta);
    }
    else
    {
        [self handleUndo:nil reason:@"adjust character width (all)"];
        for (unsigned i = 0; i < kNeoFontCharacterCount; i++)
        {
            font->character(i)->setWidth(font->character(i)->width() + delta);
        }
    }

    [self redisplay];    
}



/** Return the font height.
 */
-(int)fontHeight
{
    return font->height();
}


/** Set the current font height.
 *
 *  @param  h       The requested font height, in pixels.
 *  @return         The value actually applied (it may be limited).
 */
- (void)setFontHeight:(int)h
{
    [self handleUndo:nil reason:@"set font height"];
    font->setHeight(h);
    [self redisplay];    
}




/** Get the name of the applet.
 *
 *  @return         The name string for the applet.
 */
- (NSString *)appletName
{
    return [NSString stringWithUTF8String:font->appletName()];
}


/** Get the applet info string.
 *
 *  @return         The name string for the applet.
 */
- (NSString *)appletInfo
{
    return [NSString stringWithUTF8String:font->appletInfo()];
}

/** Set the info string for the applet.
 *
 *  @param  n       The new info string.
 */
- (void)setAppletInfo:(NSString *)n
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] setAppletInfo:[self appletInfo]];
    if (! [undo isUndoing])  [undo setActionName:@"set applet info"];
    font->setAppletInfo([n UTF8String]);
    [self redisplay];    
}




/** Get the name of the font.
 *
 *  @return         The name string for the font.
 */
- (NSString *)fontName
{
    return [NSString stringWithUTF8String:font->fontName()];
}

/** Set the name of the font.
 *
 *  @param  n       The name string for the font.
 */
- (void)setFontName:(NSString *)n
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] setFontName:[self fontName]];
    if (! [undo isUndoing])  [undo setActionName:@"set font name"];
    font->setFontName([n UTF8String]);
    [self redisplay];
}




/** Get the applet ident.
 *
 *  @return         The ident number for the applet.
 */
- (int)ident
{
    return font->ident();
}


/** Validate the applet ident, changing data if necessary.
 */
- (void)validateIdent
{
    if (canEditFullID)
    {
        // Nothing - the secondary identity controls are enabled for editing
    }
    else
    {
        // Make sure that the font ident is in legal range and that the secondary ID fields are correctly set
        int n = font->ident();
        if (n < kAppletID_UserMin) n = kAppletID_UserMin;
        if (n > kAppletID_UserMax) n = kAppletID_UserMax;
        font->setIdent(n);
        int customIndex = (n - kAppletID_UserMin) + 1;
        NSString *appletInfo = [NSString stringWithFormat:@"User defined font"];
        NSString *fontName = [NSString stringWithFormat:@"Custom Font %d", customIndex];

        font->setAppletInfo([appletInfo UTF8String]);
        font->setFontName([fontName UTF8String]);
    }
}


/** Set the applet ident.
 *
 *  @param  n       The new info string.
 */
- (void)setIdent:(int)n
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] setIdent:[self ident]];
    if (! [undo isUndoing])  [undo setActionName:@"set applet ident"];
    font->setIdent(n);
    [self validateIdent];
    [self redisplay];
}



/** Get the font version string.
 *
 *  @return         The font version string.
 */
- (NSString *)version
{
    return [NSString stringWithUTF8String:font->version()];
}

/** Set the version of the font.
 *
 *  @param  n       The version string for the font.
 */
- (void)setVersion:(NSString *)n
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] setVersion:[self version]];
    if (! [undo isUndoing])  [undo setActionName:@"set font version"];
    font->setVersion([n UTF8String]);
    [self redisplay];
}





/** Embolden.
 *
 *  @param  ch      The character number, or -1 to apply to all characters.
 */
- (void)transformBold:(int)ch
{
    if (ch >= 0)
    {
        [self handleUndo:nil reason:@"bold" character:ch];

        NeoCharacter *character = font->character(characterNumber);    
        character->setWidth(character->width() + 1);
        character->transformBold();
    }
    else
    {
        [self handleUndo:nil reason:@"bold (all)"];

        for (unsigned i = 0; i < kNeoFontCharacterCount; i++)
        {
            NeoCharacter *character = font->character(i);    
            character->setWidth(character->width() + 1);
            character->transformBold();
        }
    }

    [pixelEditor setNeedsDisplay:YES];
    [navView setNeedsDisplay:YES];
    [previewView setNeedsDisplay:YES];
}



/** Scroll the character.
 *
 *  @param  ch      The character number, or -1 to apply to all characters.
 *  @param  dx      The number of pixels to scroll in the x-direction (positive values => right left).
 *  @param  dy      The number of pixels to scroll in the y-direction (positive values => scroll down).
 */
- (void)transformTranslate:(int)ch dX:(int)dx dY:(int)dy
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] transformTranslate:ch dX:-dx dY:-dy];
    if (! [undo isUndoing])  [undo setActionName:(ch >= 0 ? @"translate" : @"translate (all)")];

    if (ch >= 0)
    {
        font->character(ch)->transformTranslate(dx, dy);
    }
    else
    {
        for (unsigned i = 0; i < kNeoFontCharacterCount; i++)
        {
            font->character(i)->transformTranslate(dx, dy);
        }
    }

    [pixelEditor setNeedsDisplay:YES];
    [navView setNeedsDisplay:YES];
    [previewView setNeedsDisplay:YES];
}


/** Flip the character horizontally.
 *
 *  @param  ch      The character number, or -1 to apply to all characters.
 */
- (void)transformFlipH:(int)ch
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] transformFlipH:ch];
    if (! [undo isUndoing])  [undo setActionName:(ch >= 0 ? @"flip-horizontal" : @"flip-horizontal (all)")];

    if (ch >= 0)
    {
        font->character(ch)->transformFlipH();
    }
    else
    {
        for (unsigned i = 0; i < kNeoFontCharacterCount; i++)
        {
            font->character(i)->transformFlipH();
        }
    }

    [pixelEditor setNeedsDisplay:YES];
    [navView setNeedsDisplay:YES];
    [previewView setNeedsDisplay:YES];
}

/** Flip the character vertically.
 */
- (void)transformFlipV:(int)ch
{
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] transformFlipV:ch];
    if (! [undo isUndoing])  [undo setActionName:(ch >= 0 ? @"flip-vertical" : @"flip-vertical (all)")];

    if (ch >= 0)
    {
        font->character(ch)->transformFlipV();
    }
    else
    {
        for (unsigned i = 0; i < kNeoFontCharacterCount; i++)
        {
            font->character(i)->transformFlipV();
        }
    }

    [pixelEditor setNeedsDisplay:YES];
    [navView setNeedsDisplay:YES];
    [previewView setNeedsDisplay:YES];
}


/** Get the value of a pixel at the specified coordinates.
 *
 *  @param  ch      The character number.
 *  @param  x       The x-coordinate (origin is left).
 *  @param  y       The y-coordinate (origin is top).
 *  @return         Zero if the pixel is clear, one if the pixel is set.
 */
- (int)pixelInCharacter:(int)ch atX:(int)x y:(int)y
{
    return font->character(ch)->getPixel(x, y);
}


/** Set the value of a pixel at the specified coordinates.
 *
 *  @param  ch      The character number.
 *  @param  x       The x-coordinate (origin is left).
 *  @param  y       The y-coordinate (origin is top).
 *  @param  v       The value to set. Use +1 to set a pixel, 0 to clear it, -1 to flip it.
 *  @return         The actual value applied. Zero for a clear pixel, one for a set pixel.
 */
- (void)setPixelInCharacter:(int)ch atX:(int)x y:(int)y to:(int)v
{
    assert(ch >= 0 && ch < kNeoFontCharacterCount);

    NeoCharacter *character = font->character(ch);
    
    NSUndoManager *undo = [self undoManager];
    [[undo prepareWithInvocationTarget:self] setPixelInCharacter:ch atX:x y:y to:[self pixelInCharacter:ch atX:x y:y]];
    if (! [undo isUndoing]) 
    {
        if (v < 0) [undo setActionName:@"toggle pixel"];
        else if (v == 0) [undo setActionName:@"clear pixel"];
        else [undo setActionName:@"set pixel"];
    }
    character->changePixel(x, y, v);

    [pixelEditor setNeedsDisplay:YES];
    [navView setNeedsDisplay:YES];
    [previewView setNeedsDisplay:YES];
}



/** Increment the character width.
 */
- (IBAction)actionCharacterWidthInc:(id)sender
{
    if (![globalEditSwitch intValue])
    {
        [self setCharacter:characterNumber widthDelta:1];
    }
    else
    {
        [self setCharacter:-1 widthDelta:1];
    }
}



/** Decrement the character width.
 */
- (IBAction)actionCharacterWidthDec:(id)sender
{
    if (![globalEditSwitch intValue])
    {
        [self setCharacter:characterNumber widthDelta:-1];
    }
    else
    {
        [self setCharacter:-1 widthDelta:-1];
    }
}


/** Set the character width.
 */
- (IBAction)actionCharacterWidthSet:(id)sender
{
    int w = [characterWidthTextField intValue];
    if (![globalEditSwitch intValue])
    {
        [self setCharacter:characterNumber width:w];
    }
    else
    {
        [self setCharacter:-1 width:w];
    }
}


/** Increment the font height.
 */
- (IBAction)actionFontHeightInc:(id)sender
{
    [self setFontHeight:[self fontHeight] + 1];
}


/** Decrement the font height.
 */
- (IBAction)actionFontHeightDec:(id)sender
{
    [self setFontHeight:[self fontHeight] - 1];
}

/** Set the font height from a value.
 */
- (IBAction)actionFontHeightSet:(id)sender
{
    [self setFontHeight:[fontHeightTextField intValue]];
}


/** Move to the next character.
 */
- (IBAction)actionNextCharacter:(id)sender
{
    [self setCharacterNumber:(characterNumber + 1)];
}


/** Move to the previous character.
 */
- (IBAction)actionPrevCharacter:(id)sender
{
    [self setCharacterNumber:(characterNumber - 1)];
}


/** Goto a character from an ASCII code.
 */
- (IBAction)actionGotoCharacterASCII:(id)sender
{
	NSData *encoded_data = [[characterCodeASCII stringValue] dataUsingEncoding:NSWindowsCP1252StringEncoding allowLossyConversion:YES];
	unsigned int len = [encoded_data length];
	int n;
	if (len > 0)
	{
		n = * ((unsigned char*) [encoded_data bytes]);
	}
	else
	{
		n = [self characterNumber];
	}
		
    [self setCharacterNumber:n];
}


/** Goto a character from a hex code.
 */
- (IBAction)actionGotoCharacterHEX:(id)sender
{
    const char *str = [[characterCodeHEX stringValue] UTF8String];
    int n = characterNumber;
    sscanf(str, "%x", &n);
    [self setCharacterNumber:n];
}


/** Goto a character from a decimal code.
 */
- (IBAction)actionGotoCharacterDEC:(id)sender
{
    [self setCharacterNumber:[characterCodeDEC intValue]];
}


/** Update the applet info.
 */
- (IBAction)actionAppletInfo:(id)sender
{
    [self setAppletInfo:[appletInfoTextField stringValue]];
}

/** Update the font name.
 */
- (IBAction)actionFontName:(id)sender
{
    [self setFontName:[fontNameTextField stringValue]];
}

/** Update the applet version.
 */
- (IBAction)actionVersion:(id)sender
{
    [self setVersion:[versionTextField stringValue]];
}

/** Update the ident.
 */
- (IBAction)actionIdent:(id)sender
{
    NSMenuItem *item = [identButton selectedItem];
    unsigned appletID = [item tag];
    if (appletID != 0)
    {
        if ([self ident] != appletID)    // Don't change if the idents are the same
        {
            [self setIdent:appletID];
        }
    }
    else
    {
        [self actionSetCustomAppletID:nil];
    }
}


/* Scroll methods.
 */
- (IBAction)actionScrollUp:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:0 dY:-1];
}

- (IBAction)actionScrollDown:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:0 dY:1];
}

- (IBAction)actionScrollLeft:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:-1 dY:0];
}

- (IBAction)actionScrollRight:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:1 dY:0];
}

- (IBAction)actionScrollUpLeft:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:-1 dY:-1];
}

- (IBAction)actionScrollUpRight:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:1 dY:-1];
}

- (IBAction)actionScrollDownLeft:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:-1 dY:1];
}

- (IBAction)actionScrollDownRight:(id)sender
{
    [self transformTranslate:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber) dX:1 dY:1];
}


/* Reflect methods.
 */
- (IBAction)actionReflectLeftRight:(id)sender
{
    [self transformFlipH:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber)];
}

- (IBAction)actionReflectUpDown:(id)sender
{
    [self transformFlipV:(([globalEditSwitch intValue] != 0) ? -1 : characterNumber)];
}

/* Embolden methods.
 */
- (IBAction)actionBold:(id)sender
{
    if (! [globalEditSwitch intValue])
    {
        [self transformBold:characterNumber];
    }
    else
    {
        [self transformBold:-1];
    }
}


/** Notification that the preview text has changed.
 */
- (IBAction)actionPreviewText:(id)sender
{
    [self redisplay];
}


/** User has clicked on the character graphic.
 *
 *  @param  x           Horizontal pixel position.
 *  @param  y           Vertical pixel position.
 */
- (IBAction)actionMouseClickAtX:(int)x y:(int)y
{
    [self setPixelInCharacter:characterNumber atX:x y:y to:-1];
}


/** Cut the current character.
 *
 *  @param  sender      The sender (nil in this case).
 */
- (IBAction)cut:(id)sender
{
    [self copy:sender];
    [self handleUndo:nil reason:@"cut" character:characterNumber];
    font->character(characterNumber)->clear();
    [self redisplay];
}

/** Copy the current character.
 *
 *  @param  sender      The sender (nil in this case).
 */
- (IBAction)copy:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:kNeoFontEditorPboardType] owner:self];
    [pb setData:[self archiveCharacter:characterNumber] forType:kNeoFontEditorPboardType];
    [self redisplay];
}

/** Paste the current character.
 *
 *  @param  sender      The sender (nil in this case).
 */
- (IBAction)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObject:kNeoFontEditorPboardType]];
    if (type)
    {
        NeoCharacter ch;
        NSData *value = [pb dataForType:kNeoFontEditorPboardType];
        ch.loadArchive((const uint8_t*)[value bytes]);

        if (ch.height() <= font->height())
        {
            // The character is shorter or the same height as the current font.
            [self handleUndo:nil reason:@"paste" character:characterNumber];
            ch.setHeight(font->height());

        }
        else
        {
            // The character is taller than the current font height. Resize the font to accomodate.
            [self handleUndo:nil reason:@"paste"];
            font->setHeight(ch.height());
        }

        *font->character(characterNumber) = ch;
    }

    [self redisplay];
}


/** Return the current character number.
 *
 *  @return         The number of the currently edited character.
 */
- (int)characterNumber
{
    return characterNumber;
}


/** Set the current character number.
 */
- (void)setCharacterNumber:(int)n
{
    if (n < 0) n = (kNeoFontCharacterCount - 1) - ((-n - 1) % kNeoFontCharacterCount);
    else n = n % kNeoFontCharacterCount;

    characterNumber = n;

    [self redisplay];
}


/** Set the global edit switch value.
 */
- (void)setGlobalEditSwitchValue:(int)n
{
    [globalEditSwitch setIntValue:n];
}


/** Return the preview string.
 */
- (NSString*)previewString
{
    return [previewTextField stringValue];
}


/** Method invoked to perform any redraws that have been requested.
 */
- (void)redisplay
{
    // Display the applet ID
    int appletID = [self ident];
    int index = [identButton indexOfItemWithTag:appletID];
    if (index < 0)
    {
        index = [identButton numberOfItems] - 1;
        NSMenuItem *item = [identButton itemAtIndex:index];
        NSString *name = [NSString stringWithFormat:@"0x%04x", appletID];
        [item setTitle:name];
    }
    [identButton selectItemAtIndex:index];

    // Display the text fields in the applet
    [appletInfoTextField setStringValue:[NSString stringWithUTF8String:font->appletInfo()]];
    [fontNameTextField setStringValue:[NSString stringWithUTF8String:font->fontName()]];
    [versionTextField setStringValue:[NSString stringWithUTF8String:font->version()]];
    [appletNameTextField setStringValue:[self appletName]];

    // Show the number of lines that will be displayed and the unused space at the bottom of the screen
    int linesOccupied = 66 / [self fontHeight];       // Magic number: pixel height of Neo screen
    int unusedPixels = 66 % [self fontHeight];
    NSString *line = [NSString stringWithFormat:@"%d line%s / %d pixel%s", linesOccupied, (linesOccupied != 1 ? "s" : ""), unusedPixels, (unusedPixels != 1 ? "s" : "")];
    [fontLinesTextField setStringValue:line];

    // Show the current character width and font height
    [characterWidthTextField setIntValue:font->character(characterNumber)->width()];
    [fontHeightTextField setIntValue:[self fontHeight]];

    // Show the current character number. To allow the Mac encoding to function we need to
    // remap some of the control characters in CP1252.
    uint16_t utf16 = NeoCharacterToUTF16(characterNumber);
    CFStringRef ascii = CFStringCreateWithBytes(NULL, (const UInt8*)&utf16, sizeof utf16, kCFStringEncodingUnicode, false);
    NSString *dec = [NSString stringWithFormat:@"%d", characterNumber];
    NSString *hex = [NSString stringWithFormat:@"%02x", characterNumber];

    [characterCodeASCII setStringValue:(NSString*)ascii];
    [characterCodeDEC setStringValue:dec];
    [characterCodeHEX setStringValue:hex];

    CFRelease(ascii);
    ascii = 0;

    // Request redraws for the bit-maps and previews.
    [pixelEditor setNeedsDisplay:YES];
    [navView setNeedsDisplay:YES];
    [previewView setNeedsDisplay:YES];

    // On any redraw give the character panel focus.
    [editorWindow makeFirstResponder:pixelEditor];
}


/** Method used to render a character on to a graphics context. Only set pixels are drawn. This could
 *  be re-written to be a lot faster.
 *
 *  The current drawing colour is used.
 *  Only 'set' pixels are rendered. 'clear' pixels leave the background
 *  untouched.
 *
 *  The character is plotted on a matix of size*width() by size*height().
 *
 *  @param  ch          The character object to render.
 *  @param  con         The graphics context.
 *  @param  x           Coordinate for upper left point in display.
 *  @param  y           Coordinate for upper left point in display.
 *  @param  size        The pixel size.
 */
- (void)renderCharacter:(NeoCharacter*)ch context:(CGContextRef)con x:(float)x y:(float)y size:(float)size
{
    const int ch_width = ch->width();
    const int ch_height = ch->height();
    CGRect pixel_rect = CGRectMake(0, 0, size, size);

    for (unsigned int i = 0; i < ch_width; i++)
    {
        for (unsigned int j = 0; j < ch_height; j++)
        {
            if (ch->getPixel(i, (ch_height - 1 - j)))
            {
                pixel_rect.origin.x = x + (i * size);
                pixel_rect.origin.y = y + (j * size);
                CGContextFillRect(con, pixel_rect);
            }
        }
    }
}


/** Method used to request a conversion of a system font.
 */
- (void)changeFont:(id)sender 
{
    NSFont *oldFont = systemFont;
    NSFont *newFont = [sender convertFont:oldFont];
	newFont = [sender convertFont:newFont toSize:144];
	float existingPixels = [FontConverter pixelHeightOfFont:newFont];
	float existingPoint = [newFont pointSize];
	float targetPixels = (float) font->height();
	float targetPoint = floor(existingPoint * (targetPixels / existingPixels));
    newFont = [sender convertFont:newFont toSize:targetPoint];
	
    if (nil != newFont)
    {
        [self handleUndo:nil reason:@"Load system font"];
        systemFont = [newFont retain];
        [oldFont release];
        
        [FontConverter loadFont:font from:systemFont];
    }

    [self redisplay];
}


/** Method invoked when the user clicks the accept or cancel buttons on an invalid Applet ID dialogue.
 */
- (void)didEndInvalidAppletID:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    // [sheet close];
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [self actionSetCustomAppletID:nil];
    }
    else
    {
        // Cancel
    }

    [self redisplay];
}


/** Method invoked when the user clicks the accept or cancel buttons on a dubious Applet ID dialogue.
 */
- (void)didEndDubiousAppletID:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    // [sheet close];
    if (returnCode == NSAlertFirstButtonReturn)
    {
        if ([self ident] != proposedCustomIdent)    // Don't change if the idents are the same
        {
            NSUndoManager *undo = [self undoManager];
            [[undo prepareWithInvocationTarget:self] setIdent:[self ident]];
            if (! [undo isUndoing])  [undo setActionName:@"Change applet ident"];
            [self setIdent:proposedCustomIdent];
        }
    }
    else
    {
        // Cancel
    }

    [self redisplay];
}



/** Method invoked when the user clicks the accept or cancel buttons.
 */
- (IBAction)closeCustomAppletIDSheet:(id)sender
{
    int result = [sender tag];
    [NSApp endSheet:appletIDSheet];
    if (result)
    {
        /* User has selected 'ok'.
         * Validate the selected applet and issue a warning.
         */
        NSString *stringID = [appletIDTextField stringValue];
        const char* id_string = [stringID UTF8String];
        proposedCustomIdent = 0;
        sscanf(id_string, "%x", &proposedCustomIdent);
        if (0 == proposedCustomIdent) sscanf(id_string, "0x%x", &proposedCustomIdent);
        if (0 == proposedCustomIdent || 65535 < proposedCustomIdent)
        {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert addButtonWithTitle:@"Retry"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"The specified applet ID was invalid."];
            [alert setInformativeText:@"The Applet ID must be a non-zero 16 bit number."];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert beginSheetModalForWindow:editorWindow modalDelegate:self didEndSelector:@selector(didEndInvalidAppletID:returnCode:contextInfo:) contextInfo:nil];
        }
        else if (kAppletID_GroupMin > proposedCustomIdent || proposedCustomIdent > kAppletID_GroupMax)
        {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert addButtonWithTitle:@"Use"];
            [alert addButtonWithTitle:@"Cancel"];
            NSString *message = [NSString stringWithFormat:@"The specified applet ID of 0x%04x is outside of the recommended range 0x%04x - 0x%04x", proposedCustomIdent, kAppletID_GroupMin, kAppletID_GroupMax];
            [alert setMessageText:message];
            [alert setInformativeText:@" Using IDs outside of this range will increase the chance of a conflict with other Applets and may prevent the font or other applet from loading on the AlphaSmart device. Click 'Use' only if you are sure that the ID number is correct."];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert beginSheetModalForWindow:editorWindow modalDelegate:self didEndSelector:@selector(didEndDubiousAppletID:returnCode:contextInfo:) contextInfo:nil];
        }
        else
        {
            if ([self ident] != proposedCustomIdent)    // Don't change if the idents are the same
            {
                NSUndoManager *undo = [self undoManager];
                [[undo prepareWithInvocationTarget:self] setIdent:[self ident]];
                if (! [undo isUndoing])  [undo setActionName:@"Change applet ident"];
                [self setIdent:proposedCustomIdent];
            }
        }
    }
    else
    {
        // Cancel
    }

    [self redisplay];
}


/** Method used to terminate the sheet.
 */
- (void)didEndCustomAppletIDSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    [self redisplay];
}


/** Display and manage the applet ID model sheet. This is invoked by selecting the 'custom'
 *  applet ID menu item.
 */
- (void)actionSetCustomAppletID:(id)sender 
{
    if (!appletIDSheet) [NSBundle loadNibNamed:@"AppletIDSheet" owner:self];

    NSString *identString = [NSString stringWithFormat:@"%04x", [self ident]];
    [appletIDTextField setStringValue:identString];
    
    [NSApp beginSheet:appletIDSheet
            modalForWindow:editorWindow
            modalDelegate:self
            didEndSelector:@selector(didEndCustomAppletIDSheet:returnCode:contextInfo:)
            contextInfo:nil];
 
    // Sheet is up here.
    // Return processing to the event loop
}

@end
