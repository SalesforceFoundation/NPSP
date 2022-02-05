/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Domain class for Field Mappings in NPSP.
*/
public with sharing class FieldMappings extends fflib_SObjects2 {

    @TestVisible
    private static FieldMappingSelector mappingSelector {
        get {
            if (mappingSelector == null) {
                mappingSelector = FieldMappingSelector.newInstance();
            }
            return mappingSelector;
        }
        set;
    }

    @TestVisible
    private static List<Data_Import_Field_Mapping__mdt> mappingRecords {
        get {
            if (mappingRecords == null) {
                mappingRecords = mappingSelector.getFieldMappings();
            }
            return mappingRecords;
        }
        set;
    }

    public FieldMappings(List<Data_Import_Field_Mapping__mdt> records){
        super(records);
    }

    public static FieldMappings newInstance() {
        return new FieldMappings(mappingRecords);
    }

    /**
     * @param devName DeveloperName of the field mapping to check
     * @description   This method looks to see if the field mapping exists and is deleted.
     */
    public Boolean isDeleted(String devName) {
        Data_Import_Field_Mapping__mdt d = getMappingByDevName(devName);
        if (d != null && d.Is_Deleted__c) {
            return true;
        } else {
            return false;
        }
    }

    private Data_Import_Field_Mapping__mdt getMappingByDevName(String devName) {
        for (Data_Import_Field_Mapping__mdt d :
                (List<Data_Import_Field_Mapping__mdt>) getRecords()) {
            if (d.DeveloperName == devName) {
                return d;
            }
        }
        return null;
    }
}