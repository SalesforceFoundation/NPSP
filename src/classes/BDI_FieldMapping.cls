/*
    Copyright (c) 2014 Salesforce.org
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
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description define behaviors of field mapping classes
*/

public abstract class BDI_FieldMapping {

    /** @description The batch data import custom settings */
    protected Data_Import_Settings__c BDISettings;

    public static BDI_FieldMapping mappingInstance = null;

    /*******************************************************************************************************
    * @description flag to allow us to test out field level security exception
    */
    public Boolean failFieldLevelSecurity = false;


    public BDI_FieldMapping() {

    }

    public static BDI_FieldMapping getInstance() {
        //if(Data_Import_Settings.getInstance().Use_Custom_Metadata_Mapping__c) {
        //    mappingInstance = new BDI_FieldMapping_CustomMetadata();
        //} else {
        mappingInstance = new BDI_FieldMappingHelpText();
        //}
        return mappingInstance;
    }

    public abstract Map<String,String> getFieldMap(String dataImportObjectName, 
            String targetObjectName, 
            List<String> dataImportFields);

    /*******************************************************************************************************
    * @description our exception object for Field Level Security errors.
    */
    public class FLSException extends Exception {}


}