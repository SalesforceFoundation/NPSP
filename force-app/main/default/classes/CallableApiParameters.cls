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
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Parses and Casts Callable_API Parameter values into the requested data type. Throws an Exception
* if the parameter cannot be retrieved and cast into the appropriate data type.
*/
public class CallableApiParameters {

    public static final String PARAM_ROLLUP_PARENTID = 'ParentId';
    public static final String PARAM_ROLLUP_TYPE = 'RollupType';
    public static final String PARAM_ROLLUP_TYPES = 'RollupTypes';
    public static final String PARAM_ROLLUP_DEFS = 'RollupDefinitions';
    public static final String PARAM_ROLLUP_DATA = 'RollupData';
    public static final String PARAM_ROLLUP_COMMIT = 'CommitToDatabase';
    public static final String PARAM_OPPORTUNITY_STAGE = 'OpportunityStage';
    public static final String PARAM_OPPORTUNITY_IDS = 'OpportunityIds';
    public static final String PARAM_CONTEXT_TYPE = 'ContextType';
    public static final String PARAM_PROCESSING_BOUNDARY = 'ProcessingBoundary';
    public static final String PARAM_DISABLE_ALLOCATION_TRIGGERS = 'DisableAllocationTriggers';
    public static final String PARAM_SCHEDULE_JOBS = 'ScheduleJobs';
    public static final String PARAM_SCHEDULED_JOB_NAME = 'JobName';
    public static final String PARAM_SCHEDULED_JOB_CRON_EXPRESSION = 'CronExpression';
    public static final String PARAM_SCHEDULED_JOB_CLASS = 'ApexClass';
    public static final String PARAM_RECORD_IDS = 'RecordIds';
    public static final String PARAM_START_DATE = 'StartDate';
    public static final String PARAM_END_DATE = 'EndDate';
    public static final String PARAM_PAUSE_DATA = 'PauseData';
    public static final String PARAM_REFUND_RECORDS = 'RefundRecords';

    private Map<String, Object> params;

    /**
     * @description Constructor
     * @param params Map<String,Object> parameters list from the CallableApi.call() method
     */
    public CallableApiParameters(Map<String, Object> params) {
        this.params = params;
    }

    /**
     * @description Allow the getDataType methods to thrown an exception if the parameter is missing
     * entirely. Disabled by default.
     */
    private Boolean isParamRequired = false;

    /**
     * @description Allow the getDataType methods to thrown an exception if a string parameter is empty.
     */
    private Boolean isParamEmptyStringProhibited = false;

    /**
     * @description Configure all future calls to retrieve a typed-parameter to require the parameter
     * @return this
     */
    public CallableApiParameters withRequiredParamCheck() {
        this.isParamRequired = true;
        return this;
    }

    /**
     * @description Configure all future calls to retrieve a string parameter to require a non-empty string
     * @return this
     */
    public CallableApiParameters withEmptyStringParamCheck() {
        this.isParamEmptyStringProhibited = true;
        return this;
    }

    /**
     * @description Configure all future calls to retrieve a typed-parameter to not require the parameter
     * @return this
     */
    public CallableApiParameters withoutRequiredParamCheck() {
        this.isParamRequired = false;
        return this;
    }

    /**
     * @description Retrieve the specified Parameter as a String value
     * @param paramName Map key for the params collection
     * @return String representation of that parameter
     */
    public String getString(String paramName) {
        validateRequiredParameter('String', paramName);
        validateStringParameterNotBlank('String', paramName);
        try {
            return (String) params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('String', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Boolean value
     * @param paramName Map key for the params collection
     * @return Boolean
     */
    public Boolean getBoolean(String paramName) {
        validateRequiredParameter('Boolean', paramName);
        try {
            return (Boolean)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Boolean', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Boolean value, and use the default if not found in the map
     * @param paramName Map key for the params collection
     * @param defaultValue Default if null
     * @return Boolean
     */
    public Boolean getBoolean(String paramName, Boolean defaultValue) {
        validateRequiredParameter('Boolean', paramName);
        try {
            if (params.get(paramName) != null) {
                return (Boolean) params.get(paramName);
            }
        } catch (Exception ex) {
            throwParameterException('Boolean', paramName);
        }
        return defaultValue;
    }

    /**
     * @description Retrieve the specified Parameter as a Datetime value
     * @param paramName Map key for the params collection
     * @param defaultValue Default if null
     * @return Datetime
     */
    public Datetime getDatetime(String paramName) {
        validateRequiredParameter('Datetime', paramName);
        try {
            if (params.get(paramName) != null) {
                return (Datetime) params.get(paramName);
            }
        } catch (Exception ex) {
            throwParameterException('Datetime', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Date value
     * @param paramName Map key for the params collection
     * @return Date
     */
    public Date getDate(String paramName) {
        validateRequiredParameter('Date', paramName);
        try {
            return (Date) params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Date', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as an Exception
     * @param paramName Map key for the params collection
     * @param defaultValue Default if null
     * @return Exception
     */
    public Exception getException(String paramName) {
        try {
            return (Exception) params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Exception', paramName);
        }
        return null;
    }

/**
     * @description Retrieve the specified Parameter as a List<String> collection
     * @param paramName Map key for the params collection
     * @return List<String>
     */
    public List<String> getListString(String paramName) {
        validateRequiredParameter('List<String>', paramName);
        try {
            return (List<String>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('List<String>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Set<String> collection
     * @param paramName Map key for the params collection
     * @return Set<String>
     */
    public Set<String> getSetString(String paramName) {
        validateRequiredParameter('Set<String>', paramName);
        try {
            return (Set<String>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Set<String>', paramName);
        }
        return null;
    }

     /**
     * @description Retrieve the specified Parameter as a Set<Id> collection
     * @param paramName Map key for the params collection
     * @return Set<Id>
     */
    public Set<Id> getSetId(String paramName) {
        validateRequiredParameter('Set<Id>', paramName);
        try {
            return (Set<Id>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Set<Id>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Set<String> collection
     * @param paramName Map key for the params collection
     * @return Map<Id, String>
     */
    public Map<Id, String> getStringsById(String paramName) {
        validateRequiredParameter('Map<Id, String>', paramName);
        try {
            return (Map<Id, String>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Map<Id, String>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a List<SObject> collection
     * @param paramName Map key for the params collection
     * @return List<SObject>
     */
    public List<SObject> getSObjects(String paramName) {
        validateRequiredParameter('List<SObject>', paramName);
        try {
            return (List<SObject>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('List<SObject>', paramName);
        }
        return null;
    }

  /**
     * @description Retrieve the specified Parameter as a List<Object> collection
     * @param paramName Map key for the params collection
     * @return List<Object>
     */
    public List<Object> getObjects(String paramName) {
        validateRequiredParameter('List<Object>', paramName);
        try {
            return (List<Object>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('List<Object>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a List<CRLP_Rollup> collection. This expects to the parameter
     * value to be a JSON String. This method will deserialize and return as the appropriate data type.
     * @param paramName Map key for the params collection
     * @return List<CRLP_Rollup>
     */
    public List<CRLP_Rollup> getRollupDefinitions(String paramName) {
        validateRequiredParameter('List<CRLP_Rollup>', paramName);
        try {
            String rollupDefsJson = getString(paramName);
            return (List<CRLP_Rollup>)JSON.deserialize(rollupDefsJson, List<CRLP_Rollup>.class);
        } catch (Exception ex) {
            throwParameterException('List<CRLP_Rollup> JSON', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a map of data where the outer map key is the parent record
     * id (i.e., Opportunity), and the inner map is each related SObjectName where the first SObject Name is "Opportunity".
     * value to be a JSON String. This method will deserialize and return as the appropriate data type.
     * @param paramName Map key for the params collection
     * @return Map<Id, Map<SObjectType, List<SObject>>>
     */
    public Map<Id, Map<SObjectType, List<SObject>>> getRollupDataMap(String paramName) {
        String paramType = 'Map<Id, Map<SObjectType, List<SObject>>>';
        validateRequiredParameter(paramType, paramName);
        try {
            return (Map<Id, Map<SObjectType, List<SObject>>>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException(paramType, paramName);
        }
        return null;
    }

    public Map<Id, RD2_ApiService.PauseObject> getPauseObjectsById(String paramName) {
        String paramType = 'Map<Id, RD2_ApiService.PauseObject>';
        validateRequiredParameter(paramType, paramName);
        try {
            return convertObjectIntoPauseObject((Map<Id, Object>) params.get(paramName));
        } catch (Exception ex) {
            throwParameterException('Map<Id, RD2_ApiService.PauseObject>', paramName);
        }

        return null;
    }

    private Map<Id, RD2_ApiService.PauseObject> convertObjectIntoPauseObject(Map<Id, Object> pauseParams) {
        Map<Id, RD2_ApiService.PauseObject> pauseData = new Map<Id, RD2_ApiService.PauseObject>();

        for (Id key : pauseParams.keySet()) {
            Object pauseObject = pauseParams.get(key);

            if (!(pauseObject instanceof String)) {
                pauseObject = JSON.serialize(pauseObject);
            }
            RD2_ApiService.PauseObject convertedPauseStructure = 
                (RD2_ApiService.PauseObject) JSON.deserialize((String) pauseObject, RD2_ApiService.PauseObject.class);

            pauseData.put(key, convertedPauseStructure);
        }

        return pauseData;
    }

    /**
     * @description Throw an exception if the specific parameter is missing. Does not validate
     * data type. That is handled by the specific 'get' methods. This only validates that the parameter
     * is present. This check is disabled by default, but can be enabled when required.
     * @param paramType The Parameter Data Type
     * @param paramName The parameter name to check for
     */
    private void validateRequiredParameter(String paramType, String paramName) {
        if (isParamRequired && !params.containsKey(paramName)) {
            throwParameterException(paramType, paramName);
        }
    }

    /**
     * @description Throw an exception if a string parameter is empty. Does not validate
     * data type. That is handled by the specific 'get' methods. This only validates that the
     * string parameter is non-empty. This check is disabled by default, but can be enabled when required.
     * @param paramType The Parameter Data Type
     * @param paramName The parameter name to check for
     */
    private void validateStringParameterNotBlank(String paramType, String paramName) {
        if (!isParamEmptyStringProhibited || !params.containsKey(paramName)) {
            return;
        }

        String paramString = ((String) params.get(paramName)).trim();
        if (String.isEmpty(paramString)) {
            throwParameterException(paramType, paramName);
        }
    }

    /**
     * @description Thrown a custom exception when the parameter cannot be cast as the specified type
     * @param dataType Data type of the parameter
     * @param paramName Map key for the params collection
     */
    private void throwParameterException(String dataType, String paramName) {
        throw new ParameterException(String.format( System.Label.CallableApiParameterError,
                new List<String>{ dataType, paramName} ));
    }

    /**
    * @description Exception class for Parameter Parsing
    */
    private class ParameterException extends Exception {}

}
