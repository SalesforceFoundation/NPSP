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

    public static final String PARAM_ROLLUP_TYPE = 'RollupType';
    public static final String PARAM_ROLLUP_DEFS = 'RollupDefinitions';
    public static final String PARAM_OPPORTUNITY_STAGE = 'OpportunityStage';

    private Map<String, Object> params;

    /** @description Constructor
     * @param params Map<String,Object> parameters list from the CallableApi.call() method
     */
    public CallableApiParameters(Map<String, Object> params) {
        this.params = params;
    }

    /**
     * @description Retrieve the specified Parameter as a String value
     * @param paramName
     */
    public String getString(String paramName) {
        try {
            return (String) params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('String', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Boolean value
     * @param paramName
     */
    public Boolean getBoolean(String paramName) {
        try {
            return (Boolean)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Boolean', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a List<String> collection
     * @param paramName
     */
    public List<String> getListString(String paramName) {
        try {
            return (List<String>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('List<String>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a Set<String> collection
     * @param paramName
     */
    public Set<String> getSetString(String paramName) {
        try {
            return (Set<String>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('Set<String>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a List<SObject> collection
     * @param paramName
     */
    public List<SObject> getSObjects(String paramName) {
        try {
            return (List<SObject>)params.get(paramName);
        } catch (Exception ex) {
            throwParameterException('List<Object>', paramName);
        }
        return null;
    }

    /**
     * @description Retrieve the specified Parameter as a List<CRLP_Rollup> collection. This expects to the parameter
     * value to be a JSON String. This method will deserialize and return as the appropriate data type.
     * @param paramName
     */
    public List<CRLP_Rollup> getRollupDefinitions(String paramName) {
        try {
            String rollupDefsJson = getString(paramName);
            return (List<CRLP_Rollup>)JSON.deserialize(rollupDefsJson, List<CRLP_Rollup>.class);
        } catch (Exception ex) {
            throwParameterException('List<CRLP_Rollup> JSON', paramName);
        }
        return null;
    }

    /**
     * @description Thrown a custom exception when the parameter cannot be cast as the specified type
     */
    private void throwParameterException(String dataType, String paramName) {
        throw new ParameterException(String.format( System.Label.CallableApiParameterError,
                new List<String>{ '[' + dataType + '] ' + paramName} ));
    }

    /**
    * @description Exception class for Parameter Parsing
    */
    private class ParameterException extends Exception {}

}