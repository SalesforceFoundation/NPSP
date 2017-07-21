/*
    Copyright (c) 2017, Salesforce.org
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
 * @date 2017
 * @group Address Management
 * @description Process control class to prevent trigger recursion in async process for address handling
 *
***/
public class ADDR_ProcessControl {

    /*******************************************************************************************************
    * @description Flag to true to prevent the AfterUpdate trigger on the Contact from processing changes
    * to the Contact's address that are being made by this BeforeUpdate trigger. Only used by ADDR_Contact_TDTM.
    */
    public static Boolean hasAlreadyRunBeforeOnContact = false;

    /*******************************************************************************************************
    * @description Flag to prevent recursion into the Address trigger handler/logic
    */
    private static Integer recursionFlag = 0;

    /*******************************************************************************************************
    * @description Increment/Decrement the static flag counter that tracks whether the Address processing
    *    trigger has been called already
    * @param b A boolean where true increments the counter and false decrements it.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    public static void setRecursionFlag(boolean b) {
        recursionFlag += (b ? 1 : -1);
        if (recursionFlag < 0) {
            recursionFlag = 0;
        }
        UTIL_Debug.debug('>>>>>> setRecursionFlag(' + b + ') ==> ' + recursionFlag);
    }

    /* @description Returns true if the recursionFlag value is greater than 1 */
    public static Boolean checkRecursionState() {
        UTIL_Debug.debug('>>>>>> checkRecursionState() ==> ' + recursionFlag);
        return (recursionFlag > 0);
    }

	/*******************************************************************************************************
    * @description Simple static flag to prevent execution of the address validation triggers
    */
    private static Integer validationRecursionFlag = 0;
    public static Boolean doNotExecuteValidationTrigger;

    /* @description Returns true if the validationRecursionFlag value is greater than 1 */
    public static Boolean checkValidationRecursionState() {
        return (validationRecursionFlag > 0);
    }

    /*******************************************************************************************************
    * @description Increment/Decrement the static flag counter used to prevent Address Validation recursion
    * @param b A boolean where true increments the counter and false decrements it.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    public static void setValidationRecursionFlag(boolean b) {
        validationRecursionFlag += (b ? 1 : -1);
        if (validationRecursionFlag < 0) {
            validationRecursionFlag = 0;
        }
    }

	/*******************************************************************************************************
    * @description To support DML operations with more than 200 records, use a static Set of Id's that
    * have been passed to the verifyAddressRecords() method. This allows for a recursion check that goes
    * by the Id's of the records as opposed to a simple boolean.
    */
    public static Set<Id> processedIdsForValidation = new Set<Id>();


}