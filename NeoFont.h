/** @file       NeoFont.h
 *  @brief      Header file for the NeoFont C++ class.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */

#ifndef _NEOFONT_H_
#define _NEOFONT_H_     (1)

#include "NeoCharacter.h"


#define kNeoFontCharacterCount  (256)                   /**< The number of characters in a Neo Font. */


/** Class describing a complete font.
 */
class NeoFont
{
public:

    NeoFont();
    ~NeoFont();
    
    const char* appletName() const;
    const char* appletInfo() const;
    const char* fontName() const;
    const char* version() const;
    int ident() const;
    int height() const;

    const char* setAppletInfo(const char* n);
    const char* setFontName(const char* n);
    const char* setAppletName(const char* n);
    const char* setVersion(const char* v);
    int setIdent(int i);
    int setHeight(int h);    

    void clear();
    
    NeoCharacter *character(int index);

    unsigned int appletSize() const;
    unsigned int encodeApplet(uint8_t *data, unsigned int length) const;
    bool decodeApplet(const uint8_t *data, unsigned int length);
    
    unsigned int archiveSize() const;
    void loadArchive(const uint8_t *data);
    void saveArchive(uint8_t *data) const;

private:

    /* Do not use pointer member variables here. The loadArchive() and saveArchive() methods both
     * in this class and in NeoFont have a trivial implementation that will need to be significantly
     * more complex if pointers are used.
     */
    char m_appletName[36];                                  /**< The name of the applet (seen in AS Manager). */
    char m_appletInfo[60];                                  /**< The applet information (copyright) text. */
    char m_fontName[24];                                    /**< The name of the font (seen on the Neo). */
    int m_versionMajor;                                     /**< Major version number. */
    int m_versionMinor;                                     /**< Minor version number. */
    int m_versionBuild;                                     /**< Build code (ASCII character). */
    char m_versionString[16];                               /**< Cached version string. */
    int m_ident;                                            /**< 16 bit Unique ID code. */
    int m_height;                                           /**< Font height (pixels) */
	NeoCharacter m_characters[kNeoFontCharacterCount];      /**< Array of character definitions. */

    void remakeVersionString();
    int maxWidth() const;
};



#endif      // _FONT_DEFINITION_H_
