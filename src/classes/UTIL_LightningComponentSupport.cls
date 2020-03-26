/*
    Copyright (c) 2019, Salesforce.org
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
* @group Utilities
* @description Class which holds utilities for working with Lightning Components
*/

public with sharing class UTIL_LightningComponentSupport {
    /**
     * @description Maps Schema.DisplayType to lightning-datatable column.type
     */
    @TestVisible
    private static final Map<Schema.DisplayType, String> TYPES_BY_DISPLAY_TYPE = new Map<Schema.DisplayType, String> {
        Schema.DisplayType.BOOLEAN => 'checkbox',
        Schema.DisplayType.CURRENCY => 'currency',
        Schema.DisplayType.DATE => 'date-local',
        Schema.DisplayType.DATETIME => 'date',
        Schema.DisplayType.DOUBLE => 'number',
        Schema.DisplayType.EMAIL => 'email',
        Schema.DisplayType.ENCRYPTEDSTRING => 'text',
        Schema.DisplayType.ID => 'text',
        Schema.DisplayType.INTEGER => 'number',
        Schema.DisplayType.JSON => 'text',
        Schema.DisplayType.LOCATION => 'location',
        Schema.DisplayType.LONG => 'number',
        Schema.DisplayType.MULTIPICKLIST => 'text',
        Schema.DisplayType.PERCENT => 'percent',
        Schema.DisplayType.PHONE => 'phone',
        Schema.DisplayType.PICKLIST => 'text',
        Schema.DisplayType.REFERENCE => 'text',
        Schema.DisplayType.STRING => 'text',
        Schema.DisplayType.TEXTAREA => 'text',
        Schema.DisplayType.TIME => 'date',
        Schema.DisplayType.URL => 'url'
    };

    /**
     * @description Maps Schema.DisplayType to lightning-datatable column.typeAttributes
     */
    @TestVisible
    private static final Map<Schema.DisplayType, Map<String, Object>> TYPE_ATTRIBUTES_BY_DISPLAY_TYPE = new Map<Schema.DisplayType, Map<String, Object>> {
        Schema.DisplayType.DATE => new Map<String, Object> {
            'year' => 'numeric',
            'month' => 'numeric',
            'day' => 'numeric'
        },
        Schema.DisplayType.DATETIME => new Map<String, Object> {
            'year' => 'numeric',
            'month' => 'numeric',
            'day' => 'numeric',
            'hour' => '2-digit',
            'minute' => '2-digit',
            'hour12' => 'true'
        },
        Schema.DisplayType.TIME => new Map<String, Object> {
            'hour' => '2-digit',
            'minute' => '2-digit',
            'hour12' => 'true'
        }
    };

    public static final String LIGHTNING_DATA_TYPE_NUMBER = 'number';
    public static final String LIGHTNING_DATA_TYPE_TEXT = 'text';
    public static final String LIGHTNING_DATA_TYPE_CHECKBOX = 'checkbox';
    public static final String LIGHTNING_DATA_TYPE_DATE = 'date';
    public static final String LIGHTNING_DATA_TYPE_DATE_LOCAL = 'date-local';

    /*******************************************************************************************************
    * @description Converts Apex field data type to type expected by lightning:datatable.
    * @param fieldDisplayType: the Schema.DisplayType from DescribeFieldResult
    * @return the datatype string expected by lightning components
    */
    public static String getLightningDataTableDataType(Schema.DisplayType fieldDisplayType) {
        if (fieldDisplayType == Schema.DisplayType.DATETIME) {
            return LIGHTNING_DATA_TYPE_DATE;
        } else if (fieldDisplayType == Schema.DisplayType.DATE) {
            return LIGHTNING_DATA_TYPE_DATE_LOCAL;
        } else if (fieldDisplayType == Schema.DisplayType.DOUBLE) {
            return LIGHTNING_DATA_TYPE_NUMBER;
        } else if (fieldDisplayType == Schema.DisplayType.STRING) {
            return LIGHTNING_DATA_TYPE_TEXT;
        } else {
            return fieldDisplayType.name().toLowerCase();
        }
    }

    /*******************************************************************************************************
    * @description Returns the corresponding Lightning field type from an Apex field type
    * @param fieldDisplayType: the Schema.DisplayType from DescribeFieldResult
    * @return the datatype string expected by lightning components
    */
    public static String getLightningInputDataType(Schema.DisplayType fieldDisplayType) {
        if (fieldDisplayType == Schema.DisplayType.CURRENCY) {
            return LIGHTNING_DATA_TYPE_NUMBER;
        } else if (fieldDisplayType == Schema.DisplayType.STRING) {
            return LIGHTNING_DATA_TYPE_TEXT;
        } else if (fieldDisplayType == Schema.DisplayType.BOOLEAN) {
            return LIGHTNING_DATA_TYPE_CHECKBOX;
        } else {
            return fieldDisplayType.name().toLowerCase();
        }
    }

    /***
    * @description Converts Apex field data type to type expected by lightning:datatable.
    * @param fieldDisplayType Field display type
    * @return String The data type expected by lightning components
    */
    public static String getColumnType(Schema.DisplayType fieldDisplayType) {
        String dataType = TYPES_BY_DISPLAY_TYPE.get(fieldDisplayType);

        return String.isBlank(dataType)
            ? fieldDisplayType.name().toLowerCase()
            : dataType;
    }

    /***
    * @description Returns type attributes used in the data table
    * @param fieldDisplayType Field display type
    * @return Map<String, Object> Attribute by data type map
    */
    public static Map<String, Object> getColumnTypeAttributes(Schema.DisplayType fieldDisplayType) {
        return TYPE_ATTRIBUTES_BY_DISPLAY_TYPE.get(fieldDisplayType);
    }

    /**
    * @description Values used to set the variant property on a Notice.
    */
    public enum Variant {
        INFO, WARNING, ERROR
    }

    /**
    * @description An Apex class that represents the Notice object in the
    * lightning:notificationsLibrary.  Used to construct instances in Apex that can then be
    * referenced in lightning.
    */
    public virtual class Notice {
        public String header { get; set; }
        public String title { get; set; }
        public String message { get; set; }
        public String variant { get; private set; }

        public void setVariant(Variant variant) {
            if (variant != null) {
                this.variant = variant.name().toLowerCase();
            }
        }
    }
}