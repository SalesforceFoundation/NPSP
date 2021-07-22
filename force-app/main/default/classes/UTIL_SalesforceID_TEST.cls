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
* @description The test class for the UTIL_SalesforceID class
*/
@isTest(isParallel=true)
public class UTIL_SalesforceID_TEST {

    /*******************************************************************************************************************
    * @description Test call with null ids
    */
    @isTest
    public static void computeDistanceForNullIds() {
        System.assertEquals (-1, UTIL_SalesforceId.computeRecordDistance(null, null), 'Null Check');
    }

    /*******************************************************************************************************************
    * @description Test call with ids for different objects
    */
    @isTest
    public static void computeDistanceForIdsOfDifferentTypes() {
        System.assertEquals (-2, UTIL_SalesforceId.computeRecordDistance(UserInfo.getOrganizationId(), UserInfo.getUserId()), 'Ids of different objects Check');
    }

    /*******************************************************************************************************************
    * @description Test call computing distance when the id's are the same
    */
    @isTest
    public static void computeDistanceForSameId() {
        System.assertEquals (0, UTIL_SalesforceId.computeRecordDistance(UserInfo.getOrganizationId(), UserInfo.getOrganizationId()), 'The same Id should return zero');
    }

    /*******************************************************************************************************************
    * @description Test directly Converting String version of a String to a long value
    */
    @isTest
    public static void convertIDStrToLong() {
        System.assertEquals (370595490, UTIL_SalesforceId.convertIDStrToLong('0010m00000P4yocAAB'), 'Convert ID String to Long');
    }
}
