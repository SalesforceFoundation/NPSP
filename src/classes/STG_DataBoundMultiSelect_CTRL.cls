/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Settings
* @description Controller for the DataBoundMultiSelect component used in 
* many of our settings pages.  It basically takes a sobject field that
* contains a semicolon separated String of values, and displays them in
* a multiselect picklist.  On saving, it renders the selections back into
* a single semicolon separated String of values.
*/
public with sharing class STG_DataBoundMultiSelect_CTRL {

    /*********************************************************************************************************
    * @description Separator used to separate picklist field values.
    * It is used to separate picklist field labels when the page is in read mode, and
    * to separate picklist field API values when they are being saved.
    */
    private static final String SEPARATOR = ';';

    /*********************************************************************************************************
    * @description The list of SelectOptions 
    */
    public list<SelectOption> listSelectOption { get; set; }

    /*********************************************************************************************************
    * @description Whether in Edit mode or Read-Only mode 
    */
    public boolean isEditMode { get; set; }

    /*********************************************************************************************************
    * @description Whether disabled 
    */
    public boolean isDisabled { get; set; }

    /*********************************************************************************************************
    * @description The Object the control is databinding to 
    */
    public SObject sobjBinding { get; set; }

    /*********************************************************************************************************
    * @description The field on the object the control is databinding to 
    */
    public String strField { get; set; }
    
    /*********************************************************************************************************
    * @description The control's constructor 
    */
    public STG_DataBoundMultiSelect_CTRL() {
        isDisabled = false;
        isEditMode = false;
    }
    
    /*********************************************************************************************************
    * @description Values are displayed as a semicolon separated labels selected 
    * for the picklist field when the page is in view (read) mode.
    */
    public String strValues {
        get {
            if (strValues == null) {
                strValues = getPicklistLabels(String.valueOf(sobjBinding.get(strField)));
            }
            return strValues;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description A multi-select picklist field API values for the specified picklist field when the page is in edit mode.  
    * Setting this list will save those values into the object's field.
    */
    public List<String> listStrValues { 
        get {
            String apiValues = (String) String.valueOf(sobjBinding.get(strField));
            if (listStrValues == null && apiValues != null) {
                listStrValues = apiValues.split(SEPARATOR, 0);
            }
            return listStrValues;
        }
        set {
            listStrValues = value;//assign the picklist field API values
            strValues = null;//reset the picklist field labels

            //store the API values as a semiclon separated values into the picklist field
            String apiValues = listStrValues == null ? '' : String.join(listStrValues, SEPARATOR);
            sobjBinding.put(strField, apiValues);            
        }
    }

    /**
    * @description Maps specified picklist field API values into labels
    * @param apiValues Semicolon separated API values
    * @return String Semicolon separated labels
    */
    private String getPicklistLabels(String apiValues) {
        String labels = '';

        if (String.isBlank(apiValues)) {
            return labels;
        }

        Map<String, String> valueByLabel = getPicklistValueByLabel();

        for (String apiValue : apiValues.split(SEPARATOR, 0)) { 
            if (String.isBlank(labels)) {
                labels = valueByLabel.get(apiValue);
            } else {      
                labels += SEPARATOR + valueByLabel.get(apiValue);
            }
        }

        return labels;
    }

    /**
    * @description Constructs the picklist field SelectOption field values and labels
    * @return Map<String, String> Value by the label map
    */
    private Map<String, String> getPicklistValueByLabel() {
        Map<String, String> valueByLabel = new Map<String, String>();

        if (listSelectOption == null) {
            return valueByLabel;
        }

        for (SelectOption option : listSelectOption) {
            valueByLabel.put(option.getValue(), option.getLabel());
        }

        return valueByLabel;
    }
}