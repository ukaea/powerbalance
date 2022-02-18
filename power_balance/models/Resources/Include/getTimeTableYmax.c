/*
BSD 3-Clause License

Copyright (c) 1998-2020, Modelica Association and contributors
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/****************************************************************************
 *                          Get Time Table Y max                            *
 *                                                                          *
 * Extra Modelica C function for returning the maximum y value from a time  *
 * table. This code is loaded during compilation of the models.             *
 *                                                                          *
 * @author :  A. Petrov                                                     *
 * @date   :  last modified 2022-02-02                                      *
 *                                                                          *
 ***************************************************************************/
#include <sys/types.h>
#include <stddef.h>

#define TABLE_ROW0(j) table[j]
#define TABLE_COL0(i) table[(i)*nCol]

typedef size_t Interval[2];

typedef struct CombiTimeTable
{
    char *key;     /* Key consisting of concatenated names of file and table */
    double *table; /* Table values */
    size_t nRow;   /* Number of rows of table */
} CombiTimeTable;

double maximumValue(void *_tableID)
{
    double yMax = 0.;
    CombiTimeTable *tableID = (CombiTimeTable *)_tableID;
    if (NULL != tableID && NULL != tableID->table)
    {
        const double *table = tableID->table;
        const size_t nRow = tableID->nRow;
        yMax = TABLE_ROW0(0);
        int i;
        for (i = 1; i < nRow; i++)
        {
            if (TABLE_ROW0(i) > yMax)
            {
                yMax = TABLE_ROW0(i);
            }
        }
    }
    return yMax;
}
