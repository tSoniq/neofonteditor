/** @file       NeoFontEditor.h
 *  @brief      Wrapper for NeoFont to permit Cocoa message access to editing functions and to add editor state.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NeoCharacter.h"
#import "NeoFont.h"

/** Pastboard signature for character data.
 */
#define kNeoFontEditorPboardType    @"NeoFontEditorCharacter"



@interface NeoFontEditor : NSDocument
{
    /* Local data.
     */
    NeoFont *font;                  /**< The font. */
    int characterNumber;            /**< The current character number. */
    NSFont *systemFont;             /**< Font context for load from system font. */
    unsigned proposedCustomIdent;   /**< Proposed custom applet ID. */
    BOOL canEditFullID;             /**< Logical true to allow control over the Applet ID and name strings. */

    /* References for interface builder components.
     */
    IBOutlet NSView *pixelEditor;                           /**< The main edit window. */
    IBOutlet NSTextField *fontHeightTextField;              /**< The font height display. */
    IBOutlet NSTextField *characterWidthTextField;          /**< The character width display. */
    IBOutlet NSTextField *characterCodeASCII;               /**< Character code display, as ASCII. */
    IBOutlet NSTextField *characterCodeHEX;                 /**< Character code display, as hexadecimal. */
    IBOutlet NSTextField *characterCodeDEC;                 /**< Character code display, as decimal. */
    IBOutlet NSTextField *appletNameTextField;              /**< Used for the applet name. */
    IBOutlet NSTextField *appletInfoTextField;              /**< Used for the applet info string. */
    IBOutlet NSTextField *fontNameTextField;                /**< Used for the font name. */
    IBOutlet NSTextField *versionTextField;                 /**< Used for the version string. */
    IBOutlet NSPopUpButton *identButton;                    /**< The unique ID field. */
    IBOutlet NSTextField *fontLinesTextField;               /**< Output field to show the number of lines. */
    IBOutlet NSView* navView;                               /**< Navigation view. */
    IBOutlet NSView* previewView;                           /**< Preview view. */
    IBOutlet NSTextField* previewTextField;                 /**< Preview text. */
    IBOutlet NSButton *globalEditSwitch;                    /**< Switch to select global editing. */
    IBOutlet NSWindow *editorWindow;                        /**< The document window. */
    IBOutlet NSWindow *appletIDSheet;                       /**< The applet ID sheet. */
    IBOutlet NSTextField *appletIDTextField;                /**< The applet ID entry. */
}

/* Editor methods.
 */
- (NeoFont *)font;
- (NeoCharacter *)character;
- (int)characterNumber;
- (void)setCharacterNumber:(int)n;
- (void)redisplay;
- (void)renderCharacter:(NeoCharacter*)ch context:(CGContextRef)con x:(float)x y:(float)y size:(float)size;
- (NSString*)previewString;
- (int)pixelInCharacter:(int)ch atX:(int)x y:(int)y;
- (void)setPixelInCharacter:(int)ch atX:(int)x y:(int)y to:(int)v;
- (void)setIdent:(int)n;
- (void)validateIdent;

/* Methods for interface builder actions.
 */
- (IBAction)actionCharacterWidthInc:(id)sender;             /**< Button used to increment the character width. */
- (IBAction)actionCharacterWidthDec:(id)sender;             /**< Button used to decrement the character width. */
- (IBAction)actionCharacterWidthSet:(id)sender;             /**< Button used to set the character width. */
- (IBAction)actionFontHeightInc:(id)sender;                 /**< Button used to increment the font height. */
- (IBAction)actionFontHeightDec:(id)sender;                 /**< Button used to decrement the font height. */
- (IBAction)actionFontHeightSet:(id)sender;                 /**< Button used to set the font height. */
- (IBAction)actionNextCharacter:(id)sender;                 /**< Go to next character. */
- (IBAction)actionPrevCharacter:(id)sender;                 /**< Go to previous character. */
- (IBAction)actionGotoCharacterASCII:(id)sender;            /**< Go to explicit character. */
- (IBAction)actionGotoCharacterHEX:(id)sender;              /**< Go to explicit character. */
- (IBAction)actionGotoCharacterDEC:(id)sender;              /**< Go to explicit character. */
- (IBAction)actionScrollUp:(id)sender;                      /**< Scroll functions. */
- (IBAction)actionScrollDown:(id)sender;                    /**< Scroll functions. */
- (IBAction)actionScrollLeft:(id)sender;                    /**< Scroll functions. */
- (IBAction)actionScrollRight:(id)sender;                   /**< Scroll functions. */
- (IBAction)actionScrollUpLeft:(id)sender;                  /**< Scroll functions. */
- (IBAction)actionScrollUpRight:(id)sender;                 /**< Scroll functions. */
- (IBAction)actionScrollDownLeft:(id)sender;                /**< Scroll functions. */
- (IBAction)actionScrollDownRight:(id)sender;               /**< Scroll functions. */
- (IBAction)actionReflectLeftRight:(id)sender;              /**< Reflect functions. */
- (IBAction)actionReflectUpDown:(id)sender;                 /**< Reflect functions. */
- (IBAction)actionPreviewText:(id)sender;                   /**< Signals that the preview string has been modified. */
- (IBAction)actionBold:(id)sender;                          /**< Make the character bold. */
- (IBAction)actionAppletInfo:(id)sender;                    /**< The applet info has changed. */
- (IBAction)actionFontName:(id)sender;                      /**< The font name has changed. */
- (IBAction)actionVersion:(id)sender;                       /**< The version string has changed. */
- (IBAction)actionIdent:(id)sender;                         /**< The ident string has changed. */
- (IBAction)actionMouseClickAtX:(int)x y:(int)y;            /**< User has clicked on character graphic. */
- (IBAction)cut:(id)sender;                                 /**< Standard cut/copy/paste commands. */
- (IBAction)copy:(id)sender;                                /**< Standard cut/copy/paste commands. */
- (IBAction)paste:(id)sender;                               /**< Standard cut/copy/paste commands. */
- (IBAction)actionSetCustomAppletID:(id)sender;             /**< Used to open the custom applet ID value sheet. */
- (IBAction)closeCustomAppletIDSheet:(id)sender;            /**< Used to dismiss the custom applet ID sheet. */
@end
