/** @file       PreView.h
 *  @brief      Handle display events in the preview view.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */
#import <Cocoa/Cocoa.h>
#import <NeoFontEditor.h>

#define NeoFontEditorPreviewMaxCharacters   (512)

@interface PreView : NSView
{
    IBOutlet NeoFontEditor *neoFontEditor;                      /**< The enclosing editor object. */
    unsigned count;                                             /**< The number of characters in the preview display. */
    float positions[NeoFontEditorPreviewMaxCharacters + 1];     /**< Array of screen x-coordinates for each character. */
    unsigned characters[NeoFontEditorPreviewMaxCharacters];     /**< The corresponding character number. */
}
@end
