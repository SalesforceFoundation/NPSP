/*
    Copyright (c) 2018, Salesforce.org
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
*/
/**
* @author Salesforce.org
* @date 2018
* @group Utilities
* @description Methods used to manipulate string objects
*
*/
public class UTIL_String {
    
    /*********************************************************************************************************
     * @description Removes from a string all values that are not an english language alpha character
     * @param target The target string for the operation
     * @return String
     */
    public static String removeNonAsciiAlphabeticCharacters(String target) {

        if (target == null) {
            return null;
        }    

        return target.replaceAll('[^A-Za-z]', '');

    }

    /*********************************************************************************************************
     * @description Removes from a string all values that are not a numeric character
     * @param target The target string for the operation
     * @return String
     */
    public static String removeNonNumericCharacters(String target) {

        if (target == null) {
            return null;
        }    

        return target.replaceAll('[^0-9]', '');

    }

    /*********************************************************************************************************
     * @description Removes from a string all values that are not a numeric or an english language character  
     * @param target The target string for the operation
     * @return String
     */
    public static String removeNonAsciiAlphanumericCharacters(String target) {

        if (target == null) {
            return null;
        }    

        return target.replaceAll('[^A-Za-z0-9]', '');

    }    
}
