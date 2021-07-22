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
* @group ErrorHandling
* @description A wrapper to help show errors on the LWC front end. 
*/
public with sharing class ERR_ExceptionData {
    public String exceptionType;
    
    // This will contain the error message
    // If it is not an DML error
    public String errorMessage;

    // These fields will only be used if it is an DML Error message
    // The integer is for the row which has an error
    public Map<Integer, String> DMLErrorMessageMapping;
    public Map<Integer, List<String>> DMLErrorFieldNameMapping;

    /*******************************************************************************************************
    * @description Takes an exception and pulls the information from the exception to 
    * fill in the necessary information for the wrapper. 
    * @param e Exception to become wrapped.
    */
    public ERR_ExceptionData(Exception e) {
        exceptionType = e.getTypeName();

        DMLErrorMessageMapping = new Map<Integer, String>();
        DMLErrorFieldNameMapping = new Map<Integer, List<String>>();
      
        if (exceptionType == new System.DmlException().getTypeName()) {
            DmlException dmlCastedException = (DmlException)e;
            for (Integer i = 0; i < dmlCastedException.getNumDml(); i++) {
                
                DMLErrorMessageMapping.put(i, dmlCastedException.getDmlMessage(i));
             
                if (dmlCastedException.getDmlFieldNames(i).size() > 0) {
                    DMLErrorFieldNameMapping.put(i, dmlCastedException.getDmlFieldNames(i));
                }
            }
        } else {
            this.errorMessage = e.getMessage();
        }
    }

    /*******************************************************************************************************
    * @description Creates an exception wrapper which holds just the error message
    * instead of information from an exception. 
    * This is used for displaying BDI errors. 
    * @param errorMessage   The error message to set in the wrapper. 
    */
    public ERR_ExceptionData(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    /*******************************************************************************************************
    * @description Creates an exception wrapper that is JSON serialized. 
    * @param errorMessage The error message to create a wrapper with. 
    * @return The JSON serialized string of the exception wrapper. 
    */
    public static String createExceptionWrapperJSONString(String errorMessage) {
        ERR_ExceptionData exceptionWrapper = new ERR_ExceptionData(errorMessage);
        String JSONExceptionData = JSON.serialize(exceptionWrapper);

        return JSONExceptionData;
    }

    /*******************************************************************************************************
    * @description Creates an exception wrapper that is JSON serialized. 
    * @param e Exception to wrap. 
    * @return The JSON serialized string of the exception wrapper. 
    */
    public static String createExceptionWrapperJSONString(Exception e) {
        ERR_ExceptionData exceptionWrapper = new ERR_ExceptionData(e);
        String JSONExceptionData = JSON.serialize(exceptionWrapper);

        return JSONExceptionData;
    }
}
