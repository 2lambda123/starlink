/*+
 *  Name:
 *     gaiaArray

 *  Purpose:
 *     Utility routines for handling arrays.

 *  Language:
 *     C

 *  Copyright:
 *     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
 *     All Rights Reserved.

 *  Licence:
 *     This program is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU General Public License as
 *     published by the Free Software Foundation; either version 2 of the
 *     License, or (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be
 *     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 *     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program; if not, write to the Free Software
 *     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
 *     02111-1307, USA

 *  Authors:
 *     PWD: Peter W. Draper, Starlink - University of Durham

 *  History:
 *     23-MAR-2006 (PWD):
 *        Original version.
 *     {enter_changes_here}
 *-
 */

#if HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>
#include <math.h>

#include <gaiaArray.h>
#include <gaiaUtils.h>
#include <prm_par.h>
#include <cnf.h>
#include "byteswap.h"

#define MIN(a,b) ( (a) < (b) ? (a) : (b) )
#define MAX(a,b) ( (a) > (b) ? (a) : (b) )

/* The type "long" may have 64 bits, need to know this for byte-swapping
 * macros */
#if SIZEOF_LONG == 8
#define FITS_ULONG unsigned long
#define FITS_UINT unsigned int
#else
#define FITS_ULONG unsigned long long
#define FITS_UINT unsigned long
#endif

/* Local types as HDS type strings, static for simple export */
static char *hdstypes[] = {
    "_UBYTE", "_BYTE", "_UWORD", "_WORD", "_INTEGER", "_REAL", "_DOUBLE"
};

/* A double precistion number just greater than another */
static double EPSILON = 10.0 * DBL_EPSILON;

/* Prototypes for local functions */
static void DataNormalise( void *inPtr, int intype, int nel,
                           int isfits, int haveblank, int inBlank,
                           double bscale, double bzero, int cnfmalloc,
                           int freescaled, void **outPtr,
                           int *outtype );

static void RawImageFromCube( ARRAYinfo *cubeinfo, int dims[], int axis,
                              int index, void **outPtr, size_t *nel,
                              int cnfmalloc );

static void RawSubImageFromCube( ARRAYinfo *cubeinfo, int dims[3], int axis,
                                 int index, int lbnd[2], int ubnd[2],
                                 void **outPtr, size_t *nel, int cnfmalloc );

static void GetSubImage( void *inPtr, int dims[2], int nbytes, int lbnd[2],
                         int ubnd[2], void *outPtr );

/**
 * Create an ARRAYinfo structure for a data array. If blank isn't set for your
 * data just set haveblank to 0. Note that NaN will be used for FITS floating
 * point values, so you should set haveblank 1 for those.
 */
ARRAYinfo *gaiaArrayCreateInfo( void *ptr, int type, long el, int isfits,
                                int haveblank, int blank, double bscale,
                                double bzero, int cnfmalloc )
{
    ARRAYinfo *info = (ARRAYinfo *) malloc( sizeof( ARRAYinfo ) );
    info->ptr = ptr;
    info->type = type;
    info->el = el;
    info->isfits = isfits;
    info->haveblank = haveblank;
    info->blank = blank;
    info->bscale = bscale;
    info->bzero = bzero;
    info->cnfmalloc = cnfmalloc;

    return info;
}

/**
 * Free an ARRAYinfo structure.
 */
void gaiaArrayFreeInfo( ARRAYinfo *info )
{
    if ( info != NULL ) {
        free( info );
    }
}

/**
 * Convert an HDS data type into a local enum value. Returns HDS_UNKNOWN if
 * the type cannot be understood (should be _BYTE, _UBYTE, _WORD, _UWORD,
 * _INTEGER, _REAL or _DOUBLE, case-insentive allowed and truncation to
 * uniqueness).
 */
int gaiaArrayHDSType( char *typePtr )
{
    int type = HDS_UNKNOWN;

    if ( typePtr[0] == '_' ) {
        if ( typePtr[1] == 'u' || typePtr[1] == 'U' ) {
            if ( typePtr[2] == 'b' || typePtr[2] == 'B' ) {
                type = HDS_UBYTE;
            }
            else if ( typePtr[2] == 'w' || typePtr[2] == 'W' ) {
                type = HDS_UWORD;
            }
        }
        else if ( typePtr[1] == 'b' || typePtr[1] == 'B' ) {
            type = HDS_BYTE;
        }
        else if ( typePtr[1] == 'w' || typePtr[1] == 'W' ) {
            type = HDS_WORD;
        }
        else if ( typePtr[1] == 'i' || typePtr[1] == 'I' ) {
            type = HDS_INTEGER;
        }
        else if ( typePtr[1] == 'r' || typePtr[1] == 'R' ) {
            type = HDS_REAL;
        }
        else if ( typePtr[1] == 'd' || typePtr[1] == 'D' ) {
            type = HDS_DOUBLE;
        }
    }
    return type;
}

/**
 * Convert a FITS bitpix into a local enum value. Returns HDS_UNKNOWN if
 * the type cannot be understood (should be _BYTE, _UBYTE, _WORD, _UWORD,
 * _INTEGER, _REAL or _DOUBLE).
 */
int gaiaArrayFITSType( int bitpix )
{
    int type = HDS_UNKNOWN;

    switch (bitpix)
    {
    case -8:
        /* This is not standard */
        type = HDS_BYTE;
        break;
    case 8:
        type = HDS_UBYTE;
        break;
    case -16:
        type = HDS_UWORD;
        break;
    case 16:
        type = HDS_WORD;
        break;
    case -32:
        type = HDS_REAL;
        break;
    case 32:
        type = HDS_INTEGER;
        break;
    case -64:
        type = HDS_DOUBLE;
        break;
    case 64:
        /* This is not supported, should be HDS_LONG... */
        type = HDS_UNKNOWN;
        break;
    }
    return type;
}

/**
 * Convert a local enum into a FITS bitpix.
 */
int gaiaArrayFITSBitpix( int type )
{
    int bitpix = 8;

    switch ( type )
    {
    case HDS_BYTE:
        bitpix = -8;
        break;
    case HDS_UBYTE:
        bitpix = 8;
        break;
    case HDS_UWORD:
        bitpix = -16;
        break;
    case HDS_WORD:
        bitpix = 16;
        break;
    case HDS_REAL:
        bitpix = -32;
        break;
    case HDS_INTEGER:
        bitpix = 32;
        break;
    case HDS_DOUBLE:
        bitpix = -64;
        break;
    }
    return bitpix;
}

/**
 * Convert a local enum type into an HDS string type. Returns _UBYTE if type
 * is not known.
 */
char const *gaiaArrayTypeToHDS( int type )
{
    if ( type >= 0 && type < 7 ) {
        return hdstypes[type];
    }
    return "_UBYTE";
}

/**
 * Convert a local enum type into an HDS string type that represents the
 * type that would be used to return an image or spectrum (different for
 * scaled integer FITS data).
 */
char const *gaiaArrayFullTypeToHDS( int intype, double bscale, double bzero )
{
    int type = gaiaArrayScaledType( intype, bscale, bzero );
    if ( type >= 0 && type < 7 ) {
        return hdstypes[type];
    }
    return "_UBYTE";
}

/**
 * Convert a local enum type into a type that represents the type that would
 * be used to return an image or spectrum (different for scaled integer FITS
 * data).
 */
int gaiaArrayScaledType( int intype, double bscale, double bzero )
{
    int outtype = intype;
    int scaled = ( intype < HDS_REAL && ( bscale != 1.0 || bzero != 0.0 ) );

    if ( scaled ) {
        if ( intype == HDS_INTEGER ) {
            outtype = HDS_DOUBLE;
        }
        else {
            outtype = HDS_REAL;
        }
    }
    return outtype;
}

/**
 *  Return the sizeof() of a known type.
 */
size_t gaiaArraySizeOf( int type )
{
    switch ( type )
    {
        case HDS_DOUBLE :
            return sizeof( double );

        case HDS_REAL :
            return sizeof( float );

        case HDS_INTEGER :
            return sizeof( int );

        case HDS_WORD :
            return sizeof( short );

        case HDS_UWORD :
            return sizeof( unsigned short );

        case HDS_BYTE :
            return sizeof( char );

    }
    /* Default, HDS_UBYTE */
    return sizeof( unsigned char );
}

/**
 *  Convert an array from a supported type into double precision and return
 *  the result in a simple pre-allocated array. Any HDS BAD values to be
 *  replaced with the given value. Assumes data are in native representation,
 *  that's machine byte order and have HDS bad values.
 */
void gaiaArrayToDouble( ARRAYinfo *info, double badValue, double *outPtr )
{
    void *inPtr = info->ptr;
    int nel = info->el;
    int type = info->type;

    /* Define loop as macro to save typing and maintenance */
#define CONVERT_AND_COPY(type,badFlag)    \
{                                         \
    double *dataPtr = outPtr;             \
    int i;                                \
    type *fromPtr = (type *) inPtr;       \
    type value;                           \
    for ( i = 0; i < nel; i++ ) {         \
        value = *fromPtr++;               \
        if ( value == badFlag ) {         \
            *dataPtr++ = badValue;        \
        }                                 \
        else {                            \
            *dataPtr++ = (type) value;    \
        }                                 \
    }                                     \
}
    switch ( type )
    {
        case HDS_DOUBLE:
            CONVERT_AND_COPY(double,VAL__BADD)
        break;

        case HDS_REAL:
            CONVERT_AND_COPY(float,VAL__BADR)
        break;

        case HDS_INTEGER:
            CONVERT_AND_COPY(int,VAL__BADI)
        break;

        case HDS_WORD:
            CONVERT_AND_COPY(short,VAL__BADW)
        break;

        case HDS_UWORD:
            CONVERT_AND_COPY(unsigned short,VAL__BADUW)
        break;

        case HDS_BYTE:
            CONVERT_AND_COPY(char,VAL__BADB)
        break;

        case HDS_UBYTE:
            CONVERT_AND_COPY(unsigned char,VAL__BADUB)
        break;
    }
#undef CONVERT_AND_COPY
}

/**
 *  Name:
 *     gaiaArrayImageFromCube
 *
 *  Purpose:
 *     Given an array of 3 significant dimensions, in a supported data type,
 *     extract a 2D image section and return the data in that section
 *     in an ARRAYinfo structure. The dataType should be one of the
 *     enumerations HDS_xxxx defined in gaiaArray.h (these correspond to the
 *     HDS data types). The underlying data will be changed if byte-swapping
 *     is needed and may be converted into a floating point type, if the
 *     data are FITS and have non-trivial bscale and bzero values.
 *
 *  Arguments:
 *     cubeinfo
 *         Pointer to the cube ARRAYinfo structure.
 *     dims[3]
 *         The dimensions of the cube.
 *     axis
 *         The axis that will be lost. One of 0, 1, 2. Losing the last axis is
 *         fastest.
 *     index
 *         The index of the plane that will be extracted (along axis "axis").
 *     imageinfo
 *         a pointer to a pointer to be assigned to a new ARRAYinfo structure.
 *         The necessary memory will be allocated using malloc or cnfMalloc as
 *         determined by the final argument. Freeing it is the responsibility
 *         of the caller.
 *     cnfmalloc
 *         Whether to use cnfMalloc to allocate the image data. Otherwise
 *         malloc will be used.
 */
void gaiaArrayImageFromCube( ARRAYinfo *cubeinfo, int dims[3], int axis,
                             int index, ARRAYinfo **imageinfo, int cnfmalloc )
{
    int normtype;
    int type = cubeinfo->type;
    size_t nel;
    void *normPtr = NULL;
    void *outPtr = NULL;

    /* Get the raw image data */
    outPtr = NULL;
    RawImageFromCube( cubeinfo, dims, axis, index, &outPtr, &nel, cnfmalloc );

    /* Normalise the data to remove byte-swapping and unrecognised
     * BAD values, and convert from a scaled variant. For NDFs this is a
     * null op. */
    DataNormalise( outPtr, type, nel, cubeinfo->isfits, cubeinfo->haveblank,
                   cubeinfo->blank, cubeinfo->bscale, cubeinfo->bzero,
                   cnfmalloc, 1, &normPtr, &normtype );

    /* Create the ARRAYinfo structure, note not FITS and BSCALE and BZERO are
     * no longer used. */
    *imageinfo = gaiaArrayCreateInfo( normPtr, normtype, nel,
                                      0, 0, 0, 1.0, 0.0, cnfmalloc );
}

/*
 * Extract an image from a cube, just returning the raw data. The output
 * memory may be pre-allocated (when it isn't make sure *outPtr is set to
 * NULL). No normalisation of the data is attempted.
 */
static void RawImageFromCube( ARRAYinfo *cubeinfo, int dims[3], int axis,
                              int index, void **outPtr, size_t *nel,
                              int cnfmalloc )
{
    char *ptr;
    int axis1;
    int axis2;
    int i;
    int indices[3];
    int j;
    int k;
    int l;
    int offs;
    int strides[3];
    int type = cubeinfo->type;
    size_t length;
    size_t offset;
    void *inPtr = cubeinfo->ptr;

    if ( axis == 2 ) {

        /* If we're losing the last dimension, then this is just a memcpy */
        *nel = (size_t) dims[0] * (size_t) dims[1];
        length = (*nel) * gaiaArraySizeOf( type );

        if ( *outPtr == NULL ) {
            if ( cnfmalloc == 1 ) {
                *outPtr = cnfMalloc( length );
            }
            else {
                *outPtr = malloc( length );
            }
        }

        /* Get the offset into cube of first pixel (in bytes). */
        offset = length * (size_t) index;
        ptr = ((char *) inPtr) + offset;

        /* And copy the memory */
        memcpy( *outPtr, ptr, length );
    }
    else {

        /* Noncontiguous memory, so need to pick it out pixel by pixel */

        /* Pick out axes we're keeping and set the index of the image to pick
         * out along axis "axis" */
        indices[axis] = index;
        if ( axis == 0 ) {
            axis1 = 1;
            axis2 = 2;
        }
        else {
            axis1 = 0;
            axis2 = 2;
        }

        *nel = (size_t) dims[axis1] * (size_t) dims[axis2];
        length = (*nel) * gaiaArraySizeOf( type );;

        /* Allocate the memory */
        if ( *outPtr == NULL ) {
            if ( cnfmalloc == 1 ) {
                *outPtr = cnfMalloc( length );
            }
            else {
                *outPtr = malloc( length );
            }
        }

        /* Get the strides for stepping around dimensions */
        gaiaArrayGetStrides( 3, dims, strides );

        /* Copy the image, use type switch to keep pointer arithmetic simple.
         * Use a macro to keep repeated code under control */
#define EXTRACT_AND_COPY(type)                    \
{                                                 \
    type *fromPtr = (type *) inPtr;               \
    type *toPtr = (type *) *outPtr;               \
    k = 0;                                        \
    for ( i = 0; i < dims[axis2]; i++ ) {         \
        indices[axis2] = i;                       \
        for ( j = 0; j < dims[axis1]; j++ ) {     \
            indices[axis1] = j;                   \
            offs = 0;                             \
            for ( l = 0; l < 3; l++ ) {           \
                offs += strides[l] * indices[l];  \
            }                                     \
            toPtr[k++] = fromPtr[offs];           \
        }                                         \
    }                                             \
}
        switch ( type )
        {
            case HDS_DOUBLE:
                EXTRACT_AND_COPY(double)
            break;

            case HDS_REAL:
                EXTRACT_AND_COPY(float)
            break;

            case HDS_INTEGER:
                EXTRACT_AND_COPY(int)
            break;

            case HDS_WORD:
                EXTRACT_AND_COPY(short)
            break;

            case HDS_UWORD:
                EXTRACT_AND_COPY(unsigned short)
            break;

            case HDS_BYTE:
                EXTRACT_AND_COPY(char)
            break;

            case HDS_UBYTE:
                EXTRACT_AND_COPY(unsigned char)
            break;
        }
    }
#undef EXTRACT_AND_COPY

}

/*
 * Extract a subimage from a cube, just returning the raw data. The output
 * memory may be pre-allocated (when it isn't make sure *outPtr is set to
 * NULL). No normalisation of the data is attempted. The bounds of the image
 * are given by the lbnd and ubnd arrays, these define the extents of the
 * region to extract.
 */
static void RawSubImageFromCube( ARRAYinfo *cubeinfo, int dims[3], int axis,
                                 int index, int lbnd[2], int ubnd[2],
                                 void **outPtr, size_t *nel, int cnfmalloc )
{
    char *iptr;
    int axis1;
    int axis2;
    int i;
    int indices[3];
    int j;
    int k;
    int l;
    int offs;
    int strides[3];
    int type = cubeinfo->type;
    size_t length;
    size_t offset;
    size_t nbytes;
    size_t subdims[2];
    void *inPtr = cubeinfo->ptr;

    /* Calculate the size of the returned subimage, and allocate it */
    subdims[0] = (size_t) ubnd[0] - lbnd[0] + 1;
    subdims[1] = (size_t) ubnd[1] - lbnd[1] + 1;
    *nel = subdims[0] * subdims[1];
    nbytes = gaiaArraySizeOf( type );
    length = (*nel) * nbytes;
    if ( *outPtr == NULL ) {
        if ( cnfmalloc == 1 ) {
            *outPtr = cnfMalloc( length );
        }
        else {
            *outPtr = malloc( length );
        }
    }

    if ( axis == 2 ) {

        /* Losing last dimension, so can treat images as contiguous. */

        /* Move to the start of the image plane we want. */
        iptr = inPtr;
        offset = index * dims[0] * dims[1] * nbytes;
        iptr += offset;

        /* And get the subimage. */
        GetSubImage( iptr, dims, nbytes, lbnd, ubnd, *outPtr );
    }
    else {

        /* Noncontiguous memory, so need to pick it out pixel by pixel */

        /* Pick out axes we're keeping and set the index of the image to pick
         * out along axis "axis" */
        indices[axis] = index;
        if ( axis == 0 ) {
            axis1 = 1;
            axis2 = 2;
        }
        else {
            axis1 = 0;
            axis2 = 2;
        }

        /* Get the strides for stepping around dimensions */
        gaiaArrayGetStrides( 3, dims, strides );

        /* Copy the image, use type switch to keep pointer arithmetic simple.
         * Use a macro to keep repeated code under control */
#define EXTRACT_AND_COPY(type)                                  \
{                                                               \
            type *fromPtr = (type *) inPtr;                     \
            type *toPtr = (type *) *outPtr;                     \
            k = 0;                                              \
            for ( i = lbnd[1]; i < ubnd[1]; i++ ) {             \
                indices[axis2] = i;                             \
                for ( j = lbnd[0]; j < ubnd[0]; j++ ) {         \
                    indices[axis1] = j;                         \
                    offs = 0;                                   \
                    for ( l = 0; l < 3; l++ ) {                 \
                        offs += strides[l] * indices[l];        \
                    }                                           \
                    toPtr[k++] = fromPtr[offs];                 \
                }                                               \
            }                                                   \
        }

        switch ( type )
        {
            case HDS_DOUBLE:
                EXTRACT_AND_COPY(double)
            break;

            case HDS_REAL:
                EXTRACT_AND_COPY(float)
            break;

            case HDS_INTEGER:
                EXTRACT_AND_COPY(int)
            break;

            case HDS_WORD:
                EXTRACT_AND_COPY(short)
            break;

            case HDS_UWORD:
                EXTRACT_AND_COPY(unsigned short)
            break;

            case HDS_BYTE:
                EXTRACT_AND_COPY(char)
            break;

            case HDS_UBYTE:
                EXTRACT_AND_COPY(unsigned char)
            break;
        }
    }
#undef EXTRACT_AND_COPY

}

/**
 * Extract a subimage. The main image must be contiguous and is pointed at by
 * inPtr. The data type is unknown, so the correct number of bytes per pixel
 * is used.
 */
static void GetSubImage( void *inPtr, int dims[2], int nbytes, int lbnd[2],
                         int ubnd[2], void *outPtr )
{
    char *iptr;
    char *optr;
    size_t i;
    size_t offset;
    size_t subdims[2];
    size_t dims0;
    size_t subdims0;

    /* Dimensions of sub-image */
    subdims[0] = (size_t) ubnd[0] - lbnd[0] + 1;
    subdims[1] = (size_t) ubnd[1] - lbnd[1] + 1;

    /* First dimensions in bytes */
    subdims0 = subdims[0] * nbytes;
    dims0 = dims[0] * nbytes;

    /* Get the offset of the first line in input */
    offset = (size_t) ( lbnd[1] * dims[0] + lbnd[0] ) * nbytes;

    /* Loop over all output lines */
    optr = outPtr;
    for ( i = 0; i < subdims[1]; i++ ) {

        /* Get address of first element of this line, in the input. */
        iptr = ((char *) inPtr) + offset;

        /* And copy the memory */
        memcpy( optr, iptr, subdims0 );

        /* Move output to start of next line */
        optr += subdims0;

        /* Move offset to start of next line, in the input. */
        offset += dims0 ;
    }
}


/**
 *  Name:
 *     gaiaArraySpectrumFromCube
 *
 *  Purpose:
 *     Given an array of 3 significant dimensions, in a supported data type,
 *     extract a 1D spectral section and return the data in that section in a
 *     simple array. The returned data will be byte-swapped and bad-value
 *     transformed if necessary.
 *
 *  Arguments:
 *     info
 *         Pointer to the cube structure.
 *     dims[3]
 *         The dimensions of the cube.
 *     axis
 *         The axis that will be extracted. One of 0, 1, 2. Extracting from
 *         the first axis is fastest.
 *     arange[2]
 *         A range (lower and upper indices) along axis for the extraction,
 *         NULL if whole of axis is to be returned.
 *     index1
 *     index2
 *         The indices of the spectrum to extract (these are along the two
 *         axes which are not "axis").
 *     cnfmalloc
 *         Whether to use cnfMalloc to allocate the image data. Otherwise
 *         malloc will be used.
 *     outPtr
 *         a pointer to a pointer that will point at the extracted spectrum on
 *         exit. This memory is allocated using malloc or cnfMalloc as
 *         determined by the cnfMalloc argument. Freeing it is the
 *         responsibility of the caller, or you can call gaiaArrayFree.
 *     nel
 *         the number of elements extracted
 *     outtype
 *         the type of the returned data, may be different for scaled FITS
 *         integer types.
 *
 *  Notes:
 *     If the spectrum isn't within the array bounds then an empty spectrum
 *     (full of zeros) will be returned.
 */
void gaiaArraySpectrumFromCube( ARRAYinfo *info, int dims[3], int axis,
                                int arange[2], int index1, int index2,
                                int cnfmalloc, void **outPtr, int *nel,
                                int *outtype )
{
    int lower;
    int outside = 0;
    int upper;
    size_t length;
    void *inPtr = info->ptr;
    int intype = info->type;
    void *normPtr;

    /* Allocate memory for spectrum. Only need "arange" spanning values when
     * that is set. */
    if ( arange == NULL ) {
        lower = 0;
        upper = dims[axis];
        *nel = (size_t) dims[axis];
    }
    else {
        lower = MAX( 0,              MIN( arange[0], arange[1] ) );
        upper = MIN( dims[axis] - 1, MAX( arange[1], arange[0] ) );
        upper++;
        *nel = upper - lower;
    }
    length = (*nel) * gaiaArraySizeOf( intype );
    if ( cnfmalloc == 1 ) {
        *outPtr = cnfMalloc( length );
    }
    else {
        *outPtr = malloc( length );
    }

    /* Check bounds. */
    if ( index1 < 0 || index2 < 0 ) {
        outside = 1;
    }
    else {
        if ( axis == 0 ) {
            if ( index1 >= dims[1] || index2 >= dims[2] ) {
                outside = 1;
            }
        }
        else if ( axis == 1 ) {
            if ( index1 >= dims[0] || index2 >= dims[2] ) {
                outside = 1;
            }
        }
        else if ( axis == 2 ) {
            if ( index1 >= dims[0] || index2 >= dims[1] ) {
                outside = 1;
            }
        }
    }

    if ( outside ) {

        /* Out of bounds, so return empty spectrum */
        memset( *outPtr, 0, length );
    }
    else if ( axis == 0 ) {

        /* If we're extracting from the first dimension then this is just a
         * memcpy of a contiguous piece of memory. */
        char *ptr;
        int strides[3];
        size_t offset;

        /* Get the offset into cube of first pixel on the line. */
        gaiaArrayGetStrides( 3, dims, strides );
        offset = (size_t) strides[1] * index1 + (size_t) strides[2] * index2;

        /* Correct for arange offset. */
        offset += lower;

        /* Set the address of first pixel, remember to include sizeof(type). */
        ptr = ((char *) inPtr) + ( offset * gaiaArraySizeOf( intype ) );

        /* And copy the memory */
        memcpy( *outPtr, ptr, length );
    }
    else {

        /* Non-contiguous memory, so need to pick it out pixel by pixel */
        int i;
        int indices[3];
        int j;
        int k;
        int offset;
        int strides[3];

        /* Get the strides for stepping around cube with these dimensions. */
        gaiaArrayGetStrides( 3, dims, strides );

        /* Set up indices to select the spectral line. */
        indices[0] = index1;
        if ( axis == 1 ) {
            indices[1] = 0;
            indices[2] = index2;
        }
        else {
            indices[1] = index2;
            indices[2] = 0;
        }

        /* Copy the spectrum, use type switch to keep pointer arithmetic
         * simple and a macro to define repeated code. */
#define EXTRACT_AND_COPY(type)                               \
{                                                            \
    type *fromPtr = (type *) inPtr;                          \
    type *toPtr = (type *) *outPtr;                          \
    for ( k = 0, i = lower; i < upper; k++, i++ ) {          \
        offset = 0;                                          \
        indices[axis] = i;                                   \
        for ( j = 0; j < 3; j++ ) {                          \
            offset += strides[j] * indices[j];               \
        }                                                    \
        toPtr[k] = fromPtr[offset];                          \
    }                                                        \
}
        switch ( intype )
        {
            case HDS_DOUBLE:
                EXTRACT_AND_COPY(double)
            break;
            case HDS_REAL:
                EXTRACT_AND_COPY(float)
            break;
            case HDS_INTEGER:
                EXTRACT_AND_COPY(int)
            break;
            case HDS_WORD:
                EXTRACT_AND_COPY(short)
            break;
            case HDS_UWORD:
                EXTRACT_AND_COPY(unsigned short)
            break;
            case HDS_BYTE:
                EXTRACT_AND_COPY(char)
            break;
            case HDS_UBYTE:
                EXTRACT_AND_COPY(unsigned char)
            break;
        }
    }
#undef EXTRACT_AND_COPY

    /* Normalise the data to remove byte-swapping and unrecognised
     * BAD values transform scaled FITS integer data. */
    DataNormalise( *outPtr, intype, *nel, info->isfits, info->haveblank,
                   info->blank, info->bscale, info->bzero, cnfmalloc, 1,
                   &normPtr, outtype );
    *outPtr = normPtr;
}

/**
 *  Name:
 *     gaiaArrayRegionSpectrumFromCube
 *
 *  Purpose:
 *     Given an array of 3 significant dimensions, in a supported data type,
 *     create a 1D spectral section from the data in a region, and return the
 *     data in that section in a simple array. The returned data will be
 *     byte-swapped and bad-value transformed if necessary.
 *
 *     The region is a simple ARD description covering some area in the image
 *     planes. The data in each such region of an image plane is combined to
 *     form a point in the extracted spectrum. So a description
 *     "CIRCLE(100,100,50)", would extract each circle of data, centered at
 *     100,100 with radius 50, in each image plane and combine it to a single
 *     value using the suggested method. Repeated for each image plane gives a
 *     region spectrum.
 *
 *  Arguments:
 *     info
 *         Pointer to the cube structure.
 *     dims[3]
 *         The dimensions of the cube.
 *     axis
 *         The axis that will be extracted. One of 0, 1, 2. Extracting from
 *         the first axis is fastest.
 *     arange[2]
 *         A range (lower and upper indices) along axis for the extraction,
 *         NULL if whole of axis is to be returned.
 *     region
 *         The region to combine each image plane of data in. This is an
 *         ARD description (usually a simple CIRCLE, RECT, etc.).
 *     method
 *         The combination method, GAIA_ARRAY_MEAN or GAIA_ARRAY_MEDIAN
 *         (defined in gaiaArray.h).
 *     cnfmalloc
 *         Whether to use cnfMalloc to allocate the image data. Otherwise
 *         malloc will be used.
 *     outPtr
 *         a pointer to a pointer that will point at the extracted spectrum on
 *         exit. This memory is allocated using malloc or cnfMalloc as
 *         determined by the cnfMalloc argument. Freeing it is the
 *         responsibility of the caller, or you can call gaiaArrayFree.
 *     nel
 *         the number of elements extracted
 *     outtype
 *         the type of the returned data, may be different for scaled FITS
 *         integer types.
 *
 *  Notes:
 *     If the spectrum isn't within the array bounds then an empty spectrum
 *     (full of zeros) will be returned.
 */
void gaiaArrayRegionSpectrumFromCube( ARRAYinfo *info, int dims[3], int axis,
                                      int arange[2], char *region, int method,
                                      int cnfmalloc, void **outPtr, int *nel,
                                      int *outtype )
{
    char *error_mess;
    double sum;
    int *fullMaskPtr;
    int *maskPtr;
    int *subMaskPtr;
    int count;
    int i;
    int idummy;
    int intype = info->type;
    int j;
    int k;
    int l;
    int lbnd[2];
    int lower;
    int m;
    int n;
    int maskSize;
    int mdims[2];
    int planeSize;
    int ubnd[2];
    int upper;
    size_t length;
    size_t sdummy;
    void *tmpPtr;

    /* Need to take care when the output type is not the same as the input
     * type, this happens for scaled FITS data. Allocate memory as this type
     * not intype. */
    *outtype = gaiaArrayScaledType( intype, info->bscale, info->bzero );

    /* Allocate memory for spectrum. Only need "arange" spanning values when
     * that is set. */
    if ( arange == NULL ) {
        lower = 0;
        upper = dims[axis];
        *nel = (size_t) dims[axis];
    }
    else {
        lower = MAX( 0,              MIN( arange[0], arange[1] ) );
        upper = MIN( dims[axis] - 1, MAX( arange[1], arange[0] ) );
        upper++;
        *nel = upper - lower;
    }
    length = (*nel) * gaiaArraySizeOf( *outtype );
    if ( cnfmalloc == 1 ) {
        *outPtr = cnfMalloc( length );
    }
    else {
        *outPtr = malloc( length );
    }

    /* Generate the ARD mask */
    planeSize = 1;
    j = 0;
    for ( i = 0; i < 3; i++ ) {
        if ( i != axis ) {
            planeSize *= dims[i];
            mdims[j++] = dims[i];
        }
    }
    fullMaskPtr = malloc( planeSize * sizeof( int ) );
    lbnd[0] = ubnd[0] = lbnd[1] = ubnd[1] = 0;
    if ( gaiaUtilsCreateArdMask( region, fullMaskPtr, mdims, lbnd, ubnd,
                                 &error_mess ) != 1 ) {

        /* ARD description failed, so just return an empty spectrum */
        free( error_mess );
        memset( *outPtr, 0, length );
        return;
    }
    if ( lbnd[0] == ubnd[0] && lbnd[1] == ubnd[1] ) {

        /* ARD description has no pixels, so just return an empty spectrum */
        memset( *outPtr, 0, length );
        return;
    }

    /*  ARD bounds are off by 1 pixel, why? */
    lbnd[0]--;
    lbnd[1]--;
    ubnd[0]--;
    ubnd[1]--;

    /* The mask may not cover the whole image plane, so just consider that
     * from now on to speed up extraction. */
    maskSize = ( ubnd[1] - lbnd[1] + 1 ) * ( ubnd[0] - lbnd[0] + 1 );
    subMaskPtr = malloc( maskSize * sizeof( int ) );
    GetSubImage( fullMaskPtr, mdims, sizeof( int ), lbnd, ubnd, subMaskPtr );
    free( fullMaskPtr );

    /* Walk the cube extracting each image plane in turn.  */
    /* ==================================================  */

    /* Allocate memory for the image slice, do this just once. Note that FITS
     * scaled data still allocates memory each image extraction and this is
     * intype as the data is raw. */
    tmpPtr = malloc( maskSize * gaiaArraySizeOf( intype ) );

    /* Use some poor man's generics to get the extraction and combination code
     * for all the supported data types. */

#define EXTRACT_AND_COMBINE_MEAN(outtype,badFlag)                       \
{                                                                       \
    void *imagePtr;                                                     \
    outtype *ptr;                                                       \
    outtype *specPtr;                                                   \
    specPtr = (outtype *) *outPtr;                                      \
    for ( i = lower; i < upper; i++ ) {                                 \
        RawSubImageFromCube( info, dims, axis, i, lbnd, ubnd, &tmpPtr,  \
                             &sdummy, 0 );                              \
        DataNormalise( tmpPtr, intype, maskSize, info->isfits,          \
                       info->haveblank, info->blank, info->bscale,      \
                       info->bzero, 0, 0, &imagePtr, &idummy );         \
        sum = 0.0;                                                      \
        count = 0;                                                      \
        maskPtr = subMaskPtr;                                           \
        ptr = imagePtr;                                                 \
        for ( j = 0; j < maskSize; j++ ) {                              \
            if ( *maskPtr > 1 ) {                                       \
                if ( *ptr != badFlag ) {                                \
                    sum += (double) *ptr;                               \
                    count++;                                            \
                }                                                       \
            }                                                           \
            maskPtr++;                                                  \
            ptr++;                                                      \
        }                                                               \
        if ( count > 0 ) {                                              \
            *specPtr = (outtype) (sum/(double)count );                  \
        }                                                               \
        else {                                                          \
            *specPtr = (outtype) 0;                                     \
        }                                                               \
        specPtr++;                                                      \
        if ( imagePtr != tmpPtr ) {                                     \
            free( imagePtr );                                           \
        }                                                               \
    }                                                                   \
}


#define EXTRACT_AND_COMBINE_MEDIAN(outtype,badFlag)                     \
{                                                                       \
    outtype *imagePtr;                                                  \
    outtype *specPtr;                                                   \
    outtype x;                                                          \
    outtype t;                                                          \
    specPtr = (outtype *) *outPtr;                                      \
    for ( i = lower; i < upper; i++ ) {                                 \
        RawSubImageFromCube( info, dims, axis, i, lbnd, ubnd, &tmpPtr,  \
                             &sdummy, 0 );                              \
        DataNormalise( tmpPtr, intype, maskSize, info->isfits,          \
                       info->haveblank, info->blank, info->bscale,      \
                       info->bzero, 0, 0, (void **) &imagePtr,          \
                       &idummy );                                       \
        /* Need to clean out masked and bad values for this one */      \
        count = 0;                                                      \
        for ( j = 0; j < maskSize; j++ ) {                              \
            if ( subMaskPtr[j] >= 2 && imagePtr[j] != badFlag ) {       \
                imagePtr[count] = imagePtr[j];                          \
                count++;                                                \
            }                                                           \
        }                                                               \
        if ( count > 0 ) {                                              \
            /* Find K'th value, using Wirth's algorithm */              \
            /* Original implementation by N. Devillard */               \
            k = count&1 ? count/2 : count/2 - 1;                        \
            l = 0;                                                      \
            m = count - 1;                                              \
            while ( l < m ) {                                           \
                x = imagePtr[k];                                        \
                n = l;                                                  \
                j = m;                                                  \
                do {                                                    \
                    while ( imagePtr[n] < x ) n++;                      \
                    while ( x < imagePtr[j] ) j--;                      \
                    if ( n <= j ) {                                     \
                        t = imagePtr[n];                                \
                        imagePtr[n] = imagePtr[j];                      \
                        imagePtr[j] = t;                                \
                        n++;                                            \
                        j--;                                            \
                    }                                                   \
                }                                                       \
                while ( n <= j );                                       \
                if ( j < k ) l = n;                                     \
                if ( k < n ) m = j;                                     \
            }                                                           \
            *specPtr = (outtype) imagePtr[k];                           \
        }                                                               \
        else {                                                          \
            *specPtr = (outtype) 0;                                     \
        }                                                               \
        specPtr++;                                                      \
        if ( imagePtr != tmpPtr ) {                                     \
            free( imagePtr );                                           \
        }                                                               \
    }                                                                   \
}

    switch ( *outtype )
        {
            case HDS_DOUBLE:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(double,VAL__BADD)
                } 
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(double,VAL__BADD)
                }
            break;
            case HDS_REAL:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(float,VAL__BADR)
                }
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(float,VAL__BADR)
                }
            break;
            case HDS_INTEGER:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(int,VAL__BADI)
                }
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(int,VAL__BADI)
                }
            break;
            case HDS_WORD:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(short,VAL__BADW)
                }
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(short,VAL__BADW)
                }
            break;
            case HDS_UWORD:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(unsigned short,VAL__BADUW)
                }
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(unsigned short,VAL__BADUW)
                }
            break;
            case HDS_BYTE:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(char,VAL__BADB)
                }
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(char,VAL__BADB)
                }
            break;
            case HDS_UBYTE:
                if ( method == GAIA_ARRAY_MEAN ) {
                    EXTRACT_AND_COMBINE_MEAN(unsigned char,VAL__BADUB)
                }
                else {
                    EXTRACT_AND_COMBINE_MEDIAN(unsigned char,VAL__BADUB)
                }
            break;
        }
#undef EXTRACT_AND_COMBINE_MEAN
#undef EXTRACT_AND_COMBINE_MEDIAN

    free( subMaskPtr );
    free( tmpPtr );
}

/**
 * Return a set of column major (Fortran/FITS/NDF) order strides for
 * stepping around a vectorised array of the given dimensionality
 *
 * Once returned you can access the array element data(i,j,k) element, as
 * in the following code segment:
 *
 *    int indices[3];
 *    indices[0] = i;
 *    indices[1] = j;
 *    indices[2] = k;
 *    int offset = 0;
 *    for ( int l = 0; l < 3; l++ ) {
 *       offset += strides[l] * indices[l];
 *    }
 *    value = data[offset];
 */
void gaiaArrayGetStrides( int ndims, int dims[], int strides[] )
{
    int i;
    int count = 1;
    for ( i = 0; i < ndims; i++ ) {
        strides[i] = count;
        count *= dims[i];
    }
}

/**
 * Free data previously allocated by these routines and associated with an
 * ARRAYinfo structure.
 */
void gaiaArrayFree( ARRAYinfo *info, int cnfMalloc )
{
    if ( info->ptr != NULL ) {
        if ( cnfMalloc ) {
            cnfFree( info->ptr );
        }
        else {
            free( info->ptr );
        }
        info->ptr = NULL;
    }
    else {
        fprintf( stderr, "gaiaArray: attempt to double free %p\n", info );
    }
}

/**
 *  Normalise an array if this machine does not have native FITS ordering and
 *  the data is in FITS format. Also transform FITS bad values into HDS ones.
 *
 *  If a scaled array is created the input data will be freed (since it is
 *  designed to replace this), unless freescaled is set to 0.
 */
static void DataNormalise( void *inPtr, int intype, int nel, int isfits,
                           int haveblank, int inBlank, double bscale,
                           double bzero, int cnfmalloc, int freescaled,
                           void **outPtr, int *outtype )
{
    int i;
    int scaled;
    int fscaled;
    long length;

    /*  Only applies to FITS data */
    if ( ! isfits ) {
        *outPtr = inPtr;
        *outtype = intype;
        return;
    }
    /* Byte swap first, note we do this using macros that require integers,
     * so cannot merge with bad checking. Also any scaling must happen with
     * bad checking. */
#if BIGENDIAN
    /* Nothing to do */
#else
    switch ( intype )
    {
        case HDS_DOUBLE: {
            double *ptr = (double *)inPtr;
            for ( i = 0; i < nel; i++ ) {
                ptr[i] = SWAP_DOUBLE( ptr[i] );
            }
        }
        break;

        case HDS_REAL: {
            float *ptr = (float *)inPtr;
            for ( i = 0; i < nel; i++ ) {
                ptr[i] = SWAP_FLOAT( ptr[i] );
            }
        }
        break;

        case HDS_INTEGER: {
            int *ptr = (int *)inPtr;
            for ( i = 0; i < nel; i++ ) {
                ptr[i] = SWAP_INT( ptr[i] );
            }
        }
        break;

        case HDS_WORD: {
            short *ptr = (short *)inPtr;
            for ( i = 0; i < nel; i++ ) {
                ptr[i] = SWAP_SHORT( ptr[i] );
            }
        }
        break;

        case HDS_UWORD: {
            unsigned short *ptr = (unsigned short *)inPtr;
            unsigned short value;
            for ( i = 0; i < nel; i++ ) {
                value = ptr[i];
                ptr[i] = SWAP16( value );
            }
        }
        break;
    }
#endif

    /* If the data is to be scaled to a floating type, then allocate the
     * necessary memory. */
    *outtype = gaiaArrayScaledType( intype, bscale, bzero );
    scaled = ( intype != (*outtype) );
    if ( scaled ) {
        length = nel * gaiaArraySizeOf( *outtype );

        if ( cnfmalloc == 1 ) {
            *outPtr = cnfMalloc( length );
        }
        else {
            *outPtr = malloc( length );
        }
    }
    else {
        *outPtr = inPtr;
    }
    
    /* Scaling can also occur for floating point types, when BSCALE or BZERO
     * are non-trivial */
    fscaled = 0;
    if ( ( intype == HDS_DOUBLE || intype == HDS_REAL ) && 
         ( bscale != 1.0 || bzero != 0.0 ) ) {

        /* Make sure these values are significantly non-trivial */
        if ( fabs( bscale - 1.0 ) > EPSILON ) {
            fscaled = 1;
        }
        else if ( fabs( bzero - 1.0 ) > EPSILON ) {
            fscaled = 1;
        }
    }

    /* BAD value transformation and variant scaling for integer types */
    switch ( intype )
    {
        case HDS_DOUBLE: {
            double *ptr = (double *)inPtr;
            if ( fscaled ) {
                for ( i = 0; i < nel; i++ ) {
                    if ( isnan( ptr[i] ) ) {
                        ptr[i] = VAL__BADD;
                    }
                    else {
                        ptr[i] = ptr[i] * bscale + bzero;
                    }
                }
            }
            else {
                for ( i = 0; i < nel; i++ ) {
                    if ( isnan( ptr[i] ) ) {
                        ptr[i] = VAL__BADD;
                    }
                }
            }
        }
        break;

        case HDS_REAL: {
            float *ptr = (float *)inPtr;
            if ( fscaled ) {
                for ( i = 0; i < nel; i++ ) {
                    if ( isnan( ptr[i] ) ) {
                        ptr[i] = VAL__BADR;
                    }
                }
            }
            else {
                for ( i = 0; i < nel; i++ ) {
                    if ( isnan( ptr[i] ) ) {
                        ptr[i] = VAL__BADR;
                    }
                    else {
                        ptr[i] = ptr[i] * bscale + bzero;
                    }
                }
            }
        }
        break;

        case HDS_INTEGER: {
            if ( scaled && haveblank ) {
                int *ip = (int *)inPtr;
                double *op = (double *)*outPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( op[i] != inBlank ) {
                        op[i] = ip[i] * bscale + bzero;
                    }
                    else {
                        op[i] = VAL__BADD;
                    }
                }
            }
            else if ( haveblank ) {
                int *ptr = (int *)inPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( ptr[i] == inBlank ) {
                        ptr[i] = VAL__BADI;
                    }
                }
            }
            else if ( scaled ) {
                int *ip = (int *)inPtr;
                double *op = (double *)*outPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( op[i] != VAL__BADI ) {
                        op[i] = ip[i] * bscale + bzero;
                    }
                    else {
                        op[i] = VAL__BADD;
                    }
                }
            }
        }
        break;

        case HDS_WORD: {
            if ( haveblank && scaled ) {
                short blank = (short) inBlank;
                short *ip = (short *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != blank ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
            else if ( haveblank ) {
                short blank = (short) inBlank;
                short *ptr = (short *)inPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( ptr[i] == blank ) {
                        ptr[i] = VAL__BADW;
                    }
                }
            }
            else if ( scaled ) {
                short *ip = (short *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != VAL__BADW ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
        }
        break;

        case HDS_UWORD: {
            if ( scaled && haveblank ) {
                unsigned short blank = (unsigned short) inBlank;
                unsigned short *ip = (unsigned short *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != blank ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
            else if ( haveblank ) {
                unsigned short blank = (unsigned short) inBlank;
                unsigned short *ptr = (unsigned short *)inPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( ptr[i] == blank ) {
                        ptr[i] = VAL__BADUW;
                    }
                }
            }
            else if ( scaled ) {
                unsigned short *ip = (unsigned short *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != VAL__BADUW ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
        }
        break;

        case HDS_BYTE: {
            if ( scaled && haveblank ) {
                char blank = (char) inBlank;
                char *ip = (char *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != blank ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
            else if ( haveblank ) {
                char blank = (char) inBlank;
                char *ptr = (char *)inPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( ptr[i] == blank ) {
                        ptr[i] = VAL__BADB;
                    }
                }
            }
            else if ( scaled ) {
                char *ip = (char *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != VAL__BADB ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
        }
        break;

        case HDS_UBYTE: {
            if ( scaled && haveblank ) {
                unsigned char blank = (unsigned char) inBlank;
                unsigned char *ip = (unsigned char *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != blank ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
            else if ( haveblank ) {
                unsigned char blank = (unsigned char) inBlank;
                unsigned char *ptr = (unsigned char *)inPtr;
                for ( i = 0; i < nel; i++ ) {
                    if ( ptr[i] == blank ) {
                        ptr[i] = VAL__BADUB;
                    }
                }
            }
            else if ( scaled ) {
                unsigned char *ip = (unsigned char *)inPtr;
                float *op = (float *)*outPtr;
                float zero = (float) bzero;
                float scale = (float) bscale;
                for ( i = 0; i < nel; i++ ) {
                    if ( ip[i] != VAL__BADUB ) {
                        op[i] = ip[i] * scale + zero;
                    }
                    else {
                        op[i] = VAL__BADR;
                    }
                }
            }
        }
        break;
    }

    /* Free the memory if we produced a scaled version and it's requested. */
    if ( scaled && freescaled ) {
        if ( cnfmalloc ) {
            cnfFree( inPtr );
        }
        else {
            free( inPtr );
        }
    }
}
