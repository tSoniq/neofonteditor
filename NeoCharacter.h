/** @file       NeoCharacter.h
 *  @brief      Neo font character object header file.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */
#ifndef _NEOCHARACTER_H_
#define _NEOCHARACTER_H_    (1)

/* Limits.
 */
#define kNeoCharacterMaxWidth       (128)       /**< Maximum width of a single character, in pixels. */
#define kNeoCharacterMinWidth       (1)         /**< Minimum width of a single character, in pixels. */
#define kNeoCharacterMinHeight      (1)         /**< Minimum font height, in pixels. */
#define kNeoCharacterMaxHeight      (66)        /**< Maximum font height, in pixels. */



/** Class used to code a single character.
 */
class NeoCharacter
{
public:

    NeoCharacter();
    NeoCharacter(const NeoCharacter &other);
    ~NeoCharacter();

    int width() const;
    int height() const;

    int setWidth(int w);    
    int setHeight(int h);
    
    void clear();

    int getPixel(int x, int y) const;
    void setPixel(int x, int y);
    void clearPixel(int x, int y);
    void flipPixel(int x, int y);
    void changePixel(int x, int y, int v);

    void transformTranslate(int dx, int dy);
    void transformFlipV();
    void transformFlipH();
    void transformBold();

    unsigned int archiveSize() const;
    void loadArchive(const uint8_t *data);
    void saveArchive(uint8_t *data) const;

private:

    /* Do not use pointer member variables here. The loadArchive() and saveArchive() methods both
     * in this class and in NeoFont have a trivial implementation that will need to be significantly
     * more complex if pointers are used.
     */
    int m_width;                    /**< Character width, in pixels. */
    int m_height;                   /**< Character height, in pixels. */
    
    /** Bitmap of character data. This is treated as an array of pixels, one bit per pixel.
     */
    uint8_t m_bitmap[((kNeoCharacterMaxWidth * kNeoCharacterMaxHeight) + 7) / 8];
};



#endif  // _NEOCHARACTER_H_
