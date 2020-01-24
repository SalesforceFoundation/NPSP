/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Utility
* @description SObject utility methods
*
*/
public with sharing class UTIL_SObject {

    /***
    * @description Extracts SObject Ids from a list of SObjects
    * @param records List of SObject records
    * @return Set<Id> Record Ids
    */
    public static Set<Id> extractIds(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return new Set<Id>();
        }
        return new Map<Id, SObject>(records).keySet();
    }

    /***
    * @description Extracts SObject Ids from a set of SObjects
    * @param records Set of SObject records
    * @return Set<Id> Record Ids
    */
    public static Set<Id> extractIds(Set<SObject> records) {
        if (records == null || records.isEmpty()) {
            return new Set<Id>();
        }

        return extractIds(new List<SObject>(records));
    }

    /***
    * @description Extract Id type field from a list of same SObjects 
    * @param records List of Sobject record to be extract
    * @param fieldName SObject to be extract
    * @retrun Set<Id> a set of extracted Id set
    */
    public static Set<Id> extractId(List<SObject> records, Schema.SObjectField fieldName) {
        return new Set<Id>((List<Id>) extractField(List<Id>.Class, records, fieldName.getDescribe().getName()));
    }

    /***
    * @description Extract Id type field from a list of same SObjects 
    * @param records List of Sobject record to be extract
    * @param fieldName SObject to be extract
    * @retrun Set<String> a set of extracted String set
    */
    public static Set<String> extractString(List<SObject> records, Schema.SObjectField fieldName) {
        return new Set<String>((List<String>) extractField(List<String>.Class, records, fieldName.getDescribe().getName()));
    }

    /***
    * @description Extract Datetime type field from a list of same SObjects 
    * @param records List of Sobject record to be extract
    * @param fieldName SObject to be extract
    * @retrun Set<Datatime> a set of extracted Datatime set
    */
    public static Set<Datetime> extractDatetime(List<SObject> records, Schema.SObjectField fieldName) {
        return new Set<Datetime>((List<Datetime>) extractField(List<Datetime>.Class, records, fieldName.getDescribe().getName()));
    }

    /***
    * @description Extract Decimal type field from a list of same SObjects 
    * @param records List of Sobject record to be extract
    * @param fieldName SObject to be extract
    * @retrun Set<Decimal> a set of extracted Decimal set
    */
    public static Set<Decimal> extractDecimal(List<SObject> records, Schema.SObjectField fieldName) {
        return new Set<Decimal>((List<Decimal>) extractField(List<Decimal>.Class, records, fieldName.getDescribe().getName()));
    }

    /***
    * @description Extract any type field from a list of same SObjects
    * @param listType The type of the list field being return
    * @param records List of SObject record to be extract
    * @param fieldName String SObject to be extract
    * @retrun Object[] an Object of extracted list to be converted to any type of list/set
    */
    private static Object[] extractField(Type listType, List<SObject> records, String fieldName) {
        Object[] pluck  = (Object[]) listType.newInstance();
        if (records == null || records.isEmpty()) {
            return pluck;
        }

        for (SObject record : records) {
            pluck.add(record.get(fieldName));
        }

        return pluck;
    }
}
