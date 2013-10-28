/** @file       NeoCharacter.cc
 *  @brief      Neo font character class definition.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */

#include <stdint.h>
#include <string.h>
#include "NeoCharacter.h"



/** Helper macto used to translate (x,y) coordinates to a byte index.
 *
 *  @param  x       Pixel x-coordinate.
 *  @param  y       Pixel y-coordinate.
 *  @return         The byte index.
 */
#define XY_TO_BYTE(x, y)  (((x) + ((y) * kNeoCharacterMaxWidth)) / 8)



/** Helper macro used to translate (x,y) coordinates to a bit index within a byte.
 *
 *  @param  x       Pixel x-coordinate.
 *  @param  y       Pixel y-coordinate.
 *  @return         The bit index.
 */
#if (0 == (kNeoCharacterMaxWidth & 7))
#define XY_TO_BIT(x, y)   ((x) & 7)
#else
#define XY_TO_BIT(x, y)   (((x) + ((y) * kNeoCharacterMaxWidth)) & 7)
#endif


/** Class constructor.
 */
NeoCharacter::NeoCharacter()
    :
        m_width(8),
        m_height(8),
        m_bitmap()
{
    clear();
}


/** Copy constructor.
 */
NeoCharacter::NeoCharacter(const NeoCharacter &other)
    :
        m_width(other.m_width),
        m_height(other.m_height),
        m_bitmap()
{
    memcpy(m_bitmap, other.m_bitmap, sizeof m_bitmap);
}


/** Destructor.
 */
NeoCharacter::~NeoCharacter()
{
    // Nothing.
}


/** Obtain the width of a character.
 *
 *  @return         The width of the character, in pixels.
 */
int NeoCharacter::width() const
{
    return m_width;
}


/** Obtain the height of a character.
 *
 *  @return         The height of the character, in pixels.
 */
int NeoCharacter::height() const
{
    return m_height;
}


/** Set the width of a character.
 *
 *  @param  w       The new width, in pixels.
 *  @return         The actual width used.
 */
int NeoCharacter::setWidth(int w)
{
    if (w > kNeoCharacterMaxWidth) w = kNeoCharacterMaxWidth;
    if (w < kNeoCharacterMinWidth) w = kNeoCharacterMinWidth;
    m_width = w;
    return m_width;
}


/** Set the height of a character.
 *
 *  @param  h       The new height, in pixels.
 *  @return         The actual height used.
 */
int NeoCharacter::setHeight(int h)
{
    if (h > kNeoCharacterMaxHeight) h = kNeoCharacterMaxHeight;
    if (h < kNeoCharacterMinHeight) h = kNeoCharacterMinHeight;
    if (h > m_height)
    {
        for (int y = m_height; y < h; y++)
        {
            for (int x = 0; x < m_width; x++)
            {   
                // Clear newly expanded rows
                m_bitmap[XY_TO_BYTE(x,y)] &= ~(1u << XY_TO_BIT(x,y));
            }
        }
    }
    m_height = h;
    return m_height;
}


/** Clear all pixels in the character.
 */
void NeoCharacter::clear()
{
    for (unsigned int i = 0; i < sizeof m_bitmap; i++)
    {
        m_bitmap[i] = 0;
    }
}


/** Read a pixel.
 *
 *  @param  x       Horizontal coordinate. Zero denotes the left-hand edge, getWidth() - 1 denotes the right-hand edge.
 *  @param  y       Vertical coordinate. Zero denotes the upper-edge, getHeight() - 1 denotes the lower-edge.
 *  @return         Zero if the pixel is clear, one if it is set.
 */
int NeoCharacter::getPixel(int x, int y) const
{
    if (x < 0 || x >= m_width || y < 0 || y >= m_height) return 0;
    else return (m_bitmap[XY_TO_BYTE(x,y)] >> XY_TO_BIT(x,y)) & 1;
}


/** Set a pixel.
 *
 *  @param  x       Horizontal coordinate. Zero denotes the left-hand edge, getWidth() - 1 denotes the right-hand edge.
 *  @param  y       Vertical coordinate. Zero denotes the upper-edge, getHeight() - 1 denotes the lower-edge.
 */
void NeoCharacter::setPixel(int x, int y)
{
    if (x >= 0 && x < m_width && y >= 0 && y < m_height)
    {
        m_bitmap[XY_TO_BYTE(x,y)] |= (1u << XY_TO_BIT(x,y));
    }
}
 

/** Clear a pixel.
 *
 *  @param  x       Horizontal coordinate. Zero denotes the left-hand edge, getWidth() - 1 denotes the right-hand edge.
 *  @param  y       Vertical coordinate. Zero denotes the upper-edge, getHeight() - 1 denotes the lower-edge.
 */
void NeoCharacter::clearPixel(int x, int y)
{
    if (x >= 0 && x < m_width && y >= 0 && y < m_height)
    {
        m_bitmap[XY_TO_BYTE(x,y)] &= ~(1u << XY_TO_BIT(x,y));
    }
}


/** Flip a pixel. If the pixel was set, it is cleared. If the pixel was clear, it is set.
 *
 *  @param  x       Horizontal coordinate. Zero denotes the left-hand edge, getWidth() - 1 denotes the right-hand edge.
 *  @param  y       Vertical coordinate. Zero denotes the upper-edge, getHeight() - 1 denotes the lower-edge.
 *  @return         Logical true if the pixel is left set, false if it is left clear.
 */
void NeoCharacter::flipPixel(int x, int y)
{
    if (x >= 0 && x < m_width && y >= 0 && y < m_height)
    {
        m_bitmap[XY_TO_BYTE(x,y)] = m_bitmap[XY_TO_BYTE(x,y)] ^ (1u << XY_TO_BIT(x,y));
    }
}


/** Set the value of a pixel at the specified coordinates.
 *
 *  @param  x       The x-coordinate (origin is left).
 *  @param  y       The y-coordinate (origin is top).
 *  @param  v       The value to set. Use +1 to set a pixel, 0 to clear it, -1 to flip it.
 *  @return         The final pixel state. 1 for a set pixel, zero for a clear one.
 */
void NeoCharacter::changePixel(int x, int y, int v)
{
    if (x >= 0 && x < m_width && y >= 0 && y < m_height)
    {
        if (v > 0)
        {
            setPixel(x, y);
        }
        else if (v == 0)
        {
            clearPixel(x, y);
        }
        else
        {
            flipPixel(x, y);
        }
    }
}



/** Translate the character.
 *
 *  @param  dx      The x-displacement (positive => right, negative => left).
 *  @param  dy      The y-displacement (positive => down, negative => up).
 */
void NeoCharacter::transformTranslate(int dx, int dy)
{
    if (dx < 0) dx = m_width - ((-dx) % m_width);
    if (dy < 0) dy = m_height - ((-dy) % m_height);

    NeoCharacter temp(*this);
    clear();
    for (int x = 0; x < m_width; x++)
    {
        for (int y = 0; y < m_height; y++)
        {
            if (temp.getPixel(x,y)) setPixel((x+dx) % m_width, (y+dy) % m_height);
        }
    }
}


/** Reflect the character vertically.
 */
void NeoCharacter::transformFlipV()
{
    NeoCharacter temp(*this);
    clear();    
    for (int x = 0; x < m_width; x++)
    {
        for (int y = 0; y < m_height; y++)
        {
            if (temp.getPixel(x,y)) setPixel(x, m_height - y - 1);
        }
    }
}


/** Reflect the character horizontally.
 */
void NeoCharacter::transformFlipH()
{
    NeoCharacter temp(*this);
    clear();    
    for (int x = 0; x < m_width; x++)
    {
        for (int y = 0; y < m_height; y++)
        {
            if (temp.getPixel(x,y)) setPixel(m_width - x - 1, y);
        }
    }
}


/** Make the character bolder by smearing pixels to the right. The character width is also increased.
 */
void NeoCharacter::transformBold()
{
    setWidth(m_width + 1);
    for (int y = 0; y < m_height; y++)
    {
        clearPixel(m_width - 1, y);
    }
    
    for (int x = m_width - 2; x >= 0; x--)
    {
        for (int y = 0; y < m_height; y++)
        {
            if (getPixel(x,y)) setPixel(x+1, y);
        }
    }
}


/** Return the size of the archive data.
 *
 *  @return     The number of bytes needed for an archive.
 */
unsigned int NeoCharacter::archiveSize() const
{
    return sizeof *this;
}


/** Save the character object to a byte array.
 *
 *  @return     A pointer to an array of bytes to receive the archive of at least archiveSize() bytes.
 */
void NeoCharacter::saveArchive(uint8_t *data) const
{
    memcpy(data, (void*)this, sizeof *this);
}


/** Load the character object from a byte array.
 *
 *  @param  data    The data to load. This must contain archiveSize() bytes.
 */
void NeoCharacter::loadArchive(const uint8_t *data)
{
    memcpy((void*)this, data, sizeof *this);
}

