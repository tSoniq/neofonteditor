/** @file       NeoFont.cc
 *  @brief      NeoFont class implementation.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */

#include <string.h>
#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include "NeoFont.h"
#include "AppletID.h"


/* -------------------------------------------------------------------------------------------------------------------------------
 *
 *      Macros.
 *
 * -------------------------------------------------------------------------------------------------------------------------------
 */

/* Applet file definition constants.
 */
#define kAppletOffMagic1            (0x0000)        /**< kMagic1 (big-endian, 32 bit). */
#define kAppletOffFileSize          (0x0004)        /**< File size (big-endian, 32 bit). */
#define kAppletOffID1               (0x0014)        /**< ID byte */
#define kAppletOffID0               (0x0015)        /**< ID byte */
#define kAppletOffControlCode       (0x0142)        /**< Very dubious offset to 68k lea code for data table (!). */
#define kAppletOffFontName          (0x01f2)        /**< Start of zero terminated font name. */
#define kAppletOffAppletName        (0x0018)        /**< Start of zero terminated smart applet name (description). */
#define kAppletOffVersionMajor      (0x003c)        /**< Major version number. */
#define kAppletOffVersionMinor      (0x003d)        /**< Minor version number. */
#define kAppletOffVersionBuild      (0x003e)        /**< Release code (letter). */
#define kAppletOffAppletInfo        (0x0040)        /**< Applet information string (64 bytes long). */

#define kAppletRelOffFontHeight     (0x00)          /**< Offset to font height, relative to 16 byte font info structure. */
#define kAppletRelOffWidthTable     (0x04)          /**< Offset to 8 bute font width table, relative to font info structure. */
#define kAppletRelOffLocationTable  (0x08)          /**< Offset to 16 bit bit data offset table, relative to font info structure. */
#define kAppletRelOffBitmaps        (0x0c)          /**< Start of font bitmap data, relative to font info structure. */

#define kMagic1              (0xc0ffeeadu)          /**< Value for kAppletOffMagic. */



/* Helper macros used to decode big-endian values from a byte array.
 */
#define XB8(a, x)   ((unsigned)a[x])
#define XB16(a, x)  ((((unsigned)a[x]) << 8) | (((unsigned)a[x+1]) << 0))
#define XB32(a, x)  ((((unsigned)a[x]) << 24) | (((unsigned)a[x+1]) << 16) | (((unsigned)a[x+2]) << 8) | (((unsigned)a[x+3]) << 0))



/* -------------------------------------------------------------------------------------------------------------------------------
 *
 *      Private Data.
 *
 * -------------------------------------------------------------------------------------------------------------------------------
 */

/** Header data from the file.
 */
static uint8_t file_prefix[] =
{
    0xc0, 0xff, 0xee, 0xad, 0x00, 0x00, 0x10, 0x44,  0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00,
    0xff, 0x00, 0x00, 0x31, 0xaf, 0x00, 0x01, 0x00,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x20, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x94,  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x02, 0x48, 0xe7, 0x03, 0x00,  0x2e, 0x2f, 0x00, 0x0c, 0x2c, 0x2f, 0x00, 0x10,
    0x20, 0x6f, 0x00, 0x14, 0x42, 0x90, 0x20, 0x3c,  0xff, 0x00, 0x00, 0x00, 0xc0, 0x87, 0x67, 0x6e,
    0x20, 0x7c, 0x00, 0x00, 0x00, 0x82, 0x4e, 0xbb,  0x88, 0xfe, 0x02, 0x87, 0x00, 0xff, 0xff, 0xff,
    0x20, 0x07, 0x0c, 0x80, 0x00, 0x01, 0x00, 0x00,  0x64, 0x4e, 0x0c, 0x40, 0x00, 0x01, 0x67, 0x0e,
    0x0c, 0x40, 0x00, 0x02, 0x67, 0x18, 0x0c, 0x40,  0x00, 0x06, 0x67, 0x20, 0x60, 0x3a, 0x20, 0x46,
    0x22, 0x7c, 0x00, 0x00, 0x01, 0x0c, 0x43, 0xfb,  0x98, 0xfe, 0x20, 0x89, 0x60, 0x44, 0x20, 0x3c,
    0x00, 0x00, 0x00, 0x00, 0xd0, 0x8d, 0x20, 0x46,  0x20, 0x80, 0x60, 0x36, 0x20, 0x7c, 0x00, 0x00,
    0x00, 0x36, 0x4e, 0xbb, 0x88, 0xfe, 0x22, 0x3c,  0x00, 0x00, 0x00, 0x00, 0x70, 0x00, 0x10, 0x35,
    0x18, 0x00, 0x20, 0x46, 0x20, 0x80, 0x60, 0x1a,  0x20, 0x46, 0x42, 0x90, 0x60, 0x14, 0x20, 0x07,
    0x72, 0x18, 0xb0, 0x81, 0x67, 0x02, 0x60, 0x0a,  0x20, 0x7c, 0x00, 0x00, 0x00, 0x0a, 0x4e, 0xbb,
    0x88, 0xfe, 0x4c, 0xdf, 0x00, 0xc0, 0x4e, 0x75,  0x20, 0x3c, 0x00, 0x00, 0x00, 0x00, 0xd0, 0x8d,
    0x22, 0x40, 0x20, 0x7c, 0x00, 0x00, 0x0e, 0xe8,  0x41, 0xfb, 0x88, 0xfe, 0x12, 0x90, 0x20, 0x7c,
    0x00, 0x00, 0x0e, 0xdd, 0x41, 0xfb, 0x88, 0xfe,  0x13, 0x50, 0x00, 0x01, 0x20, 0x7c, 0x00, 0x00,
    0x0e, 0xd0, 0x41, 0xfb, 0x88, 0xfe, 0x13, 0x50,  0x00, 0x02, 0x20, 0x7c, 0x00, 0x00, 0x0e, 0xc3,
    0x41, 0xfb, 0x88, 0xfe, 0x13, 0x50, 0x00, 0x03,  0x20, 0x7c, 0x00, 0x00, 0x0e, 0xb6, 0x41, 0xfb,
    0x88, 0xfe, 0x23, 0x50, 0x00, 0x04, 0x4a, 0xa9,  0x00, 0x04, 0x67, 0x14, 0x20, 0x10, 0x20, 0x7c,
    0xff, 0xff, 0xfe, 0x6c, 0x41, 0xfb, 0x88, 0xfe,  0x22, 0x08, 0xd0, 0x81, 0x23, 0x40, 0x00, 0x04,
    0x20, 0x7c, 0x00, 0x00, 0x0e, 0x92, 0x41, 0xfb,  0x88, 0xfe, 0x23, 0x50, 0x00, 0x08, 0x4a, 0xa9,
    0x00, 0x08, 0x67, 0x14, 0x20, 0x10, 0x20, 0x7c,  0xff, 0xff, 0xfe, 0x44, 0x41, 0xfb, 0x88, 0xfe,
    0x22, 0x08, 0xd0, 0x81, 0x23, 0x40, 0x00, 0x08,  0x20, 0x7c, 0x00, 0x00, 0x0e, 0x6e, 0x41, 0xfb,
    0x88, 0xfe, 0x23, 0x50, 0x00, 0x0c, 0x4a, 0xa9,  0x00, 0x0c, 0x67, 0x14, 0x20, 0x10, 0x20, 0x7c,
    0xff, 0xff, 0xfe, 0x1c, 0x41, 0xfb, 0x88, 0xfe,  0x22, 0x08, 0xd0, 0x81, 0x23, 0x40, 0x00, 0x0c,
    0x4e, 0x75
};



/* -------------------------------------------------------------------------------------------------------------------------------
 *
 *      Private Functions.
 *
 * -------------------------------------------------------------------------------------------------------------------------------
 */

/** Helper function used to write a 32 bit big endian value to a byte array.
 *
 *  @param  data    The data array.
 *  @param  offset  The offset.
 *  @param  value   The value to write.
 */
static void write32b(uint8_t *data, int offset, int value)
{
    data[offset + 0] = (value >> 24) & 255;
    data[offset + 1] = (value >> 16) & 255;
    data[offset + 2] = (value >>  8) & 255;
    data[offset + 3] = (value >>  0) & 255;
}





/* -------------------------------------------------------------------------------------------------------------------------------
 *
 *      NeoFont class definition.
 *
 * -------------------------------------------------------------------------------------------------------------------------------
 */

/** Class constructor.
 */
NeoFont::NeoFont()
    :
        m_appletName(),
        m_appletInfo(),
        m_fontName(),
        m_versionMajor(1),
        m_versionMinor(0),
        m_versionBuild(' '),
        m_ident(kAppletID_UserMin),
        m_height(16),
        m_characters()
{
    setFontName("Unnamed");
    setAppletInfo("Neo Custom Font. Copyright (c) 2008 [author].");
    clear();
    setHeight(16);       // Required to ensure character height values are initialised
    remakeVersionString();
}


/** Class destructor.
 */
NeoFont::~NeoFont()
{
    // Nothing at present.
}


/** Get the name of the applet.
 *
 *  @return            A pointer to a c-string.
 */
const char *NeoFont::appletName() const
{
    return &m_appletName[0];
}


/** Get the applet info string.
 *
 *  @return            A pointer to a c-string.
 */
const char *NeoFont::appletInfo() const
{
    return &m_appletInfo[0];
}


/** Get the name of the font.
 *
 *  @return            A pointer to a c-string.
 */
const char *NeoFont::fontName() const
{
    return &m_fontName[0];
}


/** Get the complete version string.
 *
 *  @return         A pointer to a C-string describing the version.
 */
const char *NeoFont::version() const
{
    return m_versionString;
}


/** Get Unique ID.
 *
 *  @return             The unique ID.
 */
int NeoFont::ident() const
{
    return m_ident;
}


/** Return the current font height.
 *
 * @return          The font height, in pixels.
 */
int NeoFont::height() const
{
   return m_height;
}


/** Set the name of the applet.
 *
 *  @param  n          The name to use.
 */
const char *NeoFont::setAppletName(const char* n)
{
    strncpy(m_appletName, n, sizeof m_appletName);
    m_appletName[sizeof m_appletName - 1] = 0;
	return m_appletName;
}


/** Set the applet's info text.
 *
 *  @param  n          The name to use.
 */
const char *NeoFont::setAppletInfo(const char* n)
{
    strncpy(m_appletInfo, n, sizeof m_appletInfo);
    m_appletInfo[sizeof m_appletInfo - 1] = 0;
	return m_appletInfo;
}


/** Set the name of the font and implicitly the name of the applet.
 *
 *  @param  n          The name to use.
 */
const char *NeoFont::setFontName(const char* n)
{
    strncpy(m_fontName, n, sizeof m_fontName);
    m_fontName[sizeof m_fontName - 1] = 0;
    strncpy(m_appletName, "Neo Font - ", sizeof m_appletName);
    strncat(m_appletName, m_fontName, sizeof m_appletName - 1 - strlen(m_appletName));
	return m_fontName;
}


/** Set the version from a string.
 *
 *  @param  v       The version string, in form "a.bc", where a is the major version, b the minor version and c the build letter.
 *                  Note that leading zeros in the minor version are significant. eg: 1.1 is treated as 1.10.
 */
const char *NeoFont::setVersion(const char *v)
{
    int major = m_versionMajor;
    int minor = m_versionMinor;
    char bc = ' ';
    sscanf(v, "%d.%d%c", &major, &minor, &bc);
    m_versionMajor = major & 255;
    m_versionMinor = minor & 255;
    m_versionBuild = bc;
    remakeVersionString();
	return m_versionString;
}


/** Set Unique ID.
 *
 *  @param  id         The new ID. Only the LS 16 bits are used.
 */
int NeoFont::setIdent(int id)
{
    m_ident = (id & 0xffffu);
	return m_ident;
}


/** Set all characters in the font to the same height.
 *
 * @param  h        The required height, in pixels.
 * @return          The applied font height, in pixels, after limiting is applied.
 */
int NeoFont::setHeight(int h)
{
    if (h < kNeoCharacterMinHeight) h = kNeoCharacterMinHeight;
    if (h > kNeoCharacterMaxHeight) h = kNeoCharacterMaxHeight;
    
    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++)
    {
        m_characters[i].setHeight(h);
    }
    
    m_height = h;
    return m_height;
}


/** Clear all font data. The contents of each character are erased, and a default width
 *  applied. The height is left unchanged.
 */
void NeoFont::clear()
{
    for (unsigned int i = 0; i < sizeof kNeoFontCharacterCount; i++)
    {
        m_characters[i].setWidth(8);
        m_characters[i].clear();
    }
}


/** Get a pointer to a specific character object instance.
 *
 * @param  index    The character number.
 * @return          A pointer to the character object, or zero if index is out of range.
 */
NeoCharacter *NeoFont::character(int index)
{
   if (index < 0 || index >= kNeoFontCharacterCount)
   {
       return 0;
   }
   else
   {
       return &m_characters[index];
   }
}


/** Method used to calculate how large an applet generated from the current font definition will be.
 *  This depends on many thing, but most notably the widths and heights of the characters.
 *
 *  @return         The size of the font file data given the current font definitions (in bytes).
 */
unsigned int NeoFont::appletSize() const
{
    unsigned int size = sizeof file_prefix;                 // Header
    size += strlen(fontName()) + 1;                         // Name string, rounded to next higher number of words
    while ((size % 2) != 0) size ++;                        // Pad to next word boundary
    size += kNeoFontCharacterCount;                         // Width table
    size += kNeoFontCharacterCount * 2;                     // Offset table
    unsigned int bytes_per_column = ((height() + 7) / 8);   // Number of bytes for pixel column (common to all characters)
    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++) size += ((m_characters[i]).width())*bytes_per_column; // Per character sizes
    while ((size % 4) != 0) size ++;                        // Pad to next word boundary
    size += 16;                                             // Font information table
    size += 4;                                              // Magic word 0xcafefeed at end
    return size;
}


/** Method used to convert a font in to a Smart Applet file.
 *
 *  @param  data    A pointer to the font data (the Neo file).
 *  @param  length  The number of bytes of data.
 *  @return         The number of bytes in the file, or zero if failed.
 */
unsigned int NeoFont::encodeApplet(uint8_t *data, unsigned int length) const
{
    if (length < appletSize())
    {
        return 0;   // Not enough output space
    }

    // Copy the prefix block (including outline header and applet loader code).
    for (unsigned int i = 0; i < sizeof file_prefix; i++)
    {
        data[i] = file_prefix[i];
    }

    // Set the ID in to the header. This appears to be used to distinguish between smart applets to avoid conflicts.
    data[kAppletOffID1] = (uint8_t)((m_ident >> 8) & 255);
    data[kAppletOffID0] = (uint8_t)((m_ident >> 0) & 255);

    // Overlay the version information.
    data[kAppletOffVersionMajor] = (uint8_t)m_versionMajor;
    data[kAppletOffVersionMinor] = (uint8_t)m_versionMinor;
    data[kAppletOffVersionBuild] = (uint8_t)m_versionBuild;
    
    // Overlay the applet name.
    for (unsigned int i = 0; i < strlen(m_appletName) && i < 31; i++)  data[i+kAppletOffAppletName] = m_appletName[i];

    // Overlay the info string.
    for (unsigned int i = 0; i < strlen(m_appletInfo) && i < 63; i++)  data[i+kAppletOffAppletInfo] = m_appletInfo[i];


    // Append the font name string and pad to the next word boundary.
    unsigned int offset = sizeof file_prefix;
    for (unsigned int i = 0; i < strlen(m_fontName); i++)  data[offset++] = m_fontName[i];
    data[offset++] = 0;
    while ((offset % 2) != 0) data[offset++] = 0;

    // Append the bitmap data.
    unsigned int bytes_per_column = ((height() + 7) / 8);
    unsigned int bitmap_offset = offset;
    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++)
    {
        unsigned int width = m_characters[i].width();
        unsigned int byte_count = bytes_per_column * m_characters[i].width();
        for (unsigned int byte = 0; byte < byte_count; byte++)
        {
            unsigned int b = 0;
            for (unsigned int bit = 0; bit < 8; bit++)
            {
                int x = byte % width;
                int y = bit + ((byte / width) * 8);
                if (m_characters[i].getPixel(x, y))  b = b | (1u << bit);
            }
            data[offset++] = b;
        }
    }
    
    // Pad to the next word boundary.
    while ((offset % 4) != 0) data[offset++] = 0;

    // Append the character width table.
    unsigned int width_table_offset = offset;
    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++)  data[offset++] = m_characters[i].width();
    
    // Append the bitmap offset table.
    unsigned int location_table_offset = offset;
    unsigned int temp_offset = 0;
    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++)
    {
        data[offset++] = (temp_offset / 256) & 255;
        data[offset++] = temp_offset & 255;
        temp_offset += bytes_per_column * m_characters[i].width();
    }
        
    // Append the font inforamtion structure.
    unsigned int font_info_offset = offset;
    data[offset++] = height();                          // Font height
    data[offset++] = maxWidth();                        // Maximum character width in the font
    data[offset++] = maxWidth() * bytes_per_column;     // Maximum number of bitmap bytes in any character in the font
    data[offset++] = 0x00;                              // *** UNKNOWN *** (probably reserved, as always zero)
    data[offset++] = (width_table_offset >> 24) & 255;
    data[offset++] = (width_table_offset >> 16) & 255;
    data[offset++] = (width_table_offset >>  8) & 255;
    data[offset++] = (width_table_offset >>  0) & 255;
    data[offset++] = (location_table_offset >> 24) & 255;
    data[offset++] = (location_table_offset >> 16) & 255;
    data[offset++] = (location_table_offset >>  8) & 255;
    data[offset++] = (location_table_offset >>  0) & 255;
    data[offset++] = (bitmap_offset >> 24) & 255;
    data[offset++] = (bitmap_offset >> 16) & 255;
    data[offset++] = (bitmap_offset >>  8) & 255;
    data[offset++] = (bitmap_offset >>  0) & 255;
    data[offset++] = 0xca;
    data[offset++] = 0xfe;
    data[offset++] = 0xfe;
    data[offset++] = 0xed;
    
    // Save the file size in the header.
    data[kAppletOffFileSize+0] = (offset >> 24) & 0xff;
    data[kAppletOffFileSize+1] = (offset >> 16) & 0xff;
    data[kAppletOffFileSize+2] = (offset >>  8) & 0xff;
    data[kAppletOffFileSize+3] = (offset >>  0) & 0xff;

    /* Encode the offset of the font info data in to the 68k assembly code (yuck!).
     * This is horribly dependent on the assembler code in the prefix area (it is
     * patching movea.l instructions that are used in conjunction with a pc relative
     * lea instruction to generate the addresses of the fields in the font info
     * structure).
     */
    write32b(data, 0x144, font_info_offset + 0 - 0x148);
    write32b(data, 0x150, font_info_offset + 1 - 0x154);
    write32b(data, 0x15e, font_info_offset + 2 - 0x162);
    write32b(data, 0x16c, font_info_offset + 3 - 0x170);
    write32b(data, 0x17a, font_info_offset + 4 - 0x17e);
    write32b(data, 0x1a2, font_info_offset + 8 - 0x1a6);
    write32b(data, 0x1ca, font_info_offset + 12 - 0x1ce);

	return offset;
}


/** Method used to parse a Neo smart applet containing font data and load this in to
 *  the font object.
 *
 *  @param  data    A pointer to the font data (the Neo file).
 *  @param  length  The number of bytes of data.
 *  @return         Logical true if the data was parsed correctly, false otherwise.
 */
bool NeoFont::decodeApplet(const uint8_t *data, unsigned int length)
{
    /* Check the magic number at the start of the file.
     */
    unsigned int magic = XB32(data, kAppletOffMagic1);
    if (magic != kMagic1)
    {
        return false;           // Unexpected magic number
    }
    
    /* Check the file length.
     */
    unsigned int filesize = XB32(data, kAppletOffFileSize);
    if (filesize != length)
    {
        return false;           // Applet file size does not match supplied file size
    }
    
    /* Try to decode the instructions that contain the address of the font data descriptor structure.
     * There are lots of very dubious assumptions made here, and a new compile of code for the
     * smart applet fonts will undoubtably break this scheme.
     */
    unsigned int code0 = XB16(data, 0x0142);    // movea.l #<value>, a0
    unsigned int code1 = XB32(data, 0x0144);    //          <value>
    unsigned int code2 = XB16(data, 0x0148);    // lea (<offset>, pc, a0.l), a0
    unsigned int code3 =  XB8(data, 0x014a);    //
    unsigned int code4 =  XB8(data, 0x014b);    //      <offset>

    if ((code0 != 0x207c) || (code2 != 0x41fb) || (code3 != 0x88))
    {
        return false;           // The code is not what was expected...
    }
    
    int pc_rel_offset = (code4 < 128) ? (code4) : (code4 - 256);
    unsigned int font_config_offset = 0x148 + 2 + pc_rel_offset + code1;

    unsigned int width_table = XB32(data, font_config_offset + kAppletRelOffWidthTable);
    unsigned int location_table = XB32(data, font_config_offset + kAppletRelOffLocationTable);
    unsigned int bitmap_start = XB32(data, font_config_offset + kAppletRelOffBitmaps);

    setHeight(XB8(data, font_config_offset + kAppletRelOffFontHeight));

    setAppletName((const char*) &data[kAppletOffAppletName]);
    setAppletInfo((const char*) &data[kAppletOffAppletInfo]);
    if (strlen(appletName()) > 11)
    {
        setFontName((const char*) &data[kAppletOffAppletName + 11]);        // Derive font name from applet name
    }
    else
    {
        setFontName((const char*) &data[kAppletOffFontName]);               // Else use embedded font name if applet name too short
    }
    
    m_versionMajor = data[kAppletOffVersionMajor];
    m_versionMinor = data[kAppletOffVersionMinor];
    m_versionBuild = data[kAppletOffVersionBuild];
    remakeVersionString();
    
    m_ident = (((int)data[kAppletOffID1]) * 256) + (int)data[kAppletOffID0];

    clear();        // Reset all bitmaps to empty so we only need to program 'set' pixels.

    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++)
    {
        unsigned int character_width = XB8(data, (width_table + i));
        unsigned int offset = XB16(data, (location_table + (i*2)));
        unsigned int bits = bitmap_start + offset;
        
        m_characters[i].setWidth(character_width);
        
        for (unsigned int x = 0; x < character_width; x++)
        {
            for (unsigned int y = 0; y < m_height; y++)
            {
                int byte_index = ((y / 8) * character_width) + x;
                int bit_index = y % 8;
                bool isSet = (XB8(data, (bits + byte_index)) & (1 << bit_index)) != 0;
                if (isSet) m_characters[i].setPixel(x, y);
            }
        }
    }
	
	return true;
}


/** Return the size of the archive data.
 *
 *  @return     The number of bytes in archive().
 */
unsigned int NeoFont::archiveSize() const
{
    return sizeof *this;
}


/** Return a pointer to the raw font data.
 *
 *  @return     A pointer to an array of bytes defining the character.
 */
void NeoFont::saveArchive(uint8_t *data) const
{
    memcpy(data, (void*)this, sizeof *this);
}


/** Load raw font data.
 *
 *  @param  data    The data to load. This must contain archiveSize() bytes.
 */
void NeoFont::loadArchive(const uint8_t *data)
{
    memcpy((void*)this, data, sizeof *this);
}


/** Update the cached ASCII version string from the numeric valus. This is a private routine that is
 *  also used to forceably keep the version numbers in a valid range. It must be called whenever a
 *  version number component changes.
 */
void NeoFont::remakeVersionString()
{
    if (m_versionMajor < 0) m_versionMajor = 0;
    if (m_versionMajor > 99) m_versionMajor = 99;
    if (m_versionMinor < 0) m_versionMinor = 0;
    if (m_versionMinor > 99) m_versionMinor = 99;
    if (!isprint(m_versionBuild)) m_versionBuild = '?';

    if (' ' == m_versionBuild)
    {
        snprintf(m_versionString, sizeof m_versionString, "%d.%d", m_versionMajor, m_versionMinor);
    }
    else
    {
        snprintf(m_versionString, sizeof m_versionString, "%d.%d%c", m_versionMajor, m_versionMinor, m_versionBuild);
    }
}


/** Get the width of the widest character in the font.
 *
 *  @return         The maximum width, in pixels.
 */
int NeoFont::maxWidth() const
{
    int max_width = 0;
    for (unsigned int i = 0; i < kNeoFontCharacterCount; i++)
    {
        int width = m_characters[i].width();
        if (width > max_width) max_width = width;
    }
    return max_width;
}


