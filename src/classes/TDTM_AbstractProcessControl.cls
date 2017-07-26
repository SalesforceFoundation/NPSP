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
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Base class for process control logic
 *
***/
public class TDTM_AbstractProcessControl {

    /*******************************************************************************************************
    * @description Map to track the specific recursion type status
    */
    private static Map<String, Integer> recursionMap = new Map<String, Integer>();


    /*******************************************************************************************************
    * @description Increment/Decrement the static flag counter that tracks whether the processing
    *    trigger has been called already
    * @param b A boolean where true increments the counter and false decrements it.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    public static void setRecursionFlag(String flag, boolean b) {
        Integer recursionFlag = (recursionMap.containsKey(flag) ? recursionMap.get(flag) : 0);
        recursionFlag += (b ? 1 : -1);
        if (recursionFlag < 0) {
            recursionFlag = 0;
        }
        recursionMap.put(flag, recursionFlag);
    }

    /********************************************************************************************************
    * @description Returns true if the recursionFlag value is greater than 1
    */
    public static Boolean checkRecursionState(String flag) {
        return (recursionMap.containsKey(flag) ? recursionMap.get(flag) : 0) > 0;
    }
}