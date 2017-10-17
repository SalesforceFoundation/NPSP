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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups.htm
* @description Selector class for Rollup relevant summary/target fields
*/public class RLLP_Results_SEL {

    /**
     * @description For a given SObject, identify all referenced fields from the currently defined Rollups and
     * and Filter Rules and build a SOQL statement that queries all these fields (excluding fields that the current
     * User does not have permissions to access).
     * @param resultObject ObjectType being queried
     * @return SOQL query WITHOUT a where clause
     */
    public static String getResultsQuery(SObjectType resultObject) {

        // Start by getting all the fields referenced by any Filter Group or active Rollup
        List<Schema.DescribeFieldResult> allFieldsToQuery = new List<DescribeFieldResult>();
        allFieldsToQuery.addAll(CMT_FilterRule_SEL.getReferencedFieldsByObject(resultObject));
        allFieldsToQuery.addAll(RLLP_Rollup_SEL.getReferencedFieldsByObject(resultObject));

        // Loop through the FieldDescribeResults list and add each field that is accessible to the current user
        // to the Set of strings (enforcing uniqueness)
        Set<String> queryFields = new Set<String>{'Id'};
        for (DescribeFieldResult dfr : allFieldsToQuery) {
            if (dfr.isAccessible()) {
                queryFields.add(dfr.getName());
            }
        }
        // Convert the Set to the List to support String.Join()
        List<String> fieldsList = new List<String>(queryFields);

        // Build the final SOQL string with the full list of fields
        String soql = 'SELECT ' + String.join(fieldsList, ',') + ' FROM ' + resultObject.getDescribe().getName();

        return soql;
    }

}