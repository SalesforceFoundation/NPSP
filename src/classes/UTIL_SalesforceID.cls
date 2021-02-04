/*
    Copyright (c) 2019 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
/**
* @author Salesforce.org
* @date 2019
* @group Utilities
* @description This class contains methods to help parse ids
*/
public inherited sharing class UTIL_SalesforceID {

    private static final String VALID_ID_CHAR = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';


    /*******************************************************************************************************
    * @description Determines a distance between 2 ids, for use primarily to determine whether chunking is
    * required when executing batch jobs.  If either id is null, it will return -1.  If the two ids are for
    * different objects, it will return -2.  Otherwise, it will always return a positive value representing
    * the number of ids in between them (which represents the max # of records present between the two ids).
    * A value of 0 would be returned if the two ids were the same.
    * @param id1 First Id to compare
    * @param id2 Second Id to compare
    * @return Long numberic distance between the two ids.  If a negative value is returned, it should be considered invalid
    ********************************************************************************************************/
     public static Long computeRecordDistance(ID id1, ID id2) {
        if (id1 == null || id2 == null) {
            return -1;
        }

        String id1Str = id1;
        String id1Prefix = id1Str.subString(0, 3);
        String id2Str = id2;
        String id2Prefix = id2Str.subString(0, 3);

        if (id1Prefix != id2Prefix) {
            return -2;
        }

        Long rawDiff = convertIdStrToLong(id1) - convertIdStrToLong(id2);
        return Math.abs(rawDiff);
    }


    /*******************************************************************************************************
    * @description Using characters 6 to 15 of the Salesforce Id, it converts the ID to a number to allow
    * a distance comparison between two ids for the same object.  The conversion uses the position in the
    * VALID_ID_CHAR string to determine the value to use for the digit.  The ID is essentially a BASE 62
    * value, with some character positions having special meaning like the first three characters being the
    * OBJECT prefix.  The primary reason to do this is to establish a distance between the min and max id
    * for an object when deciding whether a batch should execute in LDV or non LDV mode.  For 18 character
    * Ids, the trailing 3 characters are not used.
    * @param idString - String representation of the ID to convert.
    * @return Long converted numeric representation of the record Id only
    ********************************************************************************************************/
    @testVisible private static Long convertIDStrToLong(String idStr) {

        Long idVal = 0;

        String idPart = idStr.substring(6, 15);

        Integer pos = idPart.length() - 1;
        Long mux = 1;
        Long base = 62;
        for (Integer i = 0; i < idPart.length(); i++) {
            String digitStr = idPart.subString(pos, pos+1);
            Integer digit = VALID_ID_CHAR.indexOf(digitStr);
            if (digit >= 0) {
                idVal +=  digit * mux;
            }
            mux *= base;
            pos--;
        }
        return idVal;

    }

}
