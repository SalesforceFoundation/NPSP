/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @group Error Record
* @description Track errors of a specific SObject record
*
*/
public class ErrorRecord {
    SObject sObjectRecord;
    List<String> errors = new List<String>();

    /**
    * @descripion Construct the Error Record class
    * @param record The Record that will be tracked 
    */
    public ErrorRecord(SObject record) {
        this.sObjectRecord = record;
    }

    /**
    * @description Append a single error to the collection
    * @param error The specific error message that will be added
    * @return ErrorRecord
    */
    public ErrorRecord addError(String error) {
        if (String.isNotBlank(error)) {
            this.errors.add(error);
        }

        return this;
    }

    /**
    * @description Append a colleciton of errors to the collection
    * @param errors The specific error messages that will be added
    * @return ErrorRecord
    */
    public ErrorRecord addErrors(List<String> errors) {
        if (errors != null) {
            this.errors?.addAll(errors);
        }

        return this;
    }

    /**
    * @description Returns Sobject record
    * @return SObject
    */
    public SObject getRecord() {
        return this.sObjectRecord;
    }

    /**
    * @description Check if the current tracked record has any validation error
    */
    public Boolean hasError() {
        return !this.errors.isEmpty();
    }

    /***
    * @description Returns errors
    * @return List<String>
    */
    public List<String> getErrors() {
        return this.errors?.clone();
    }

    /***
    * @description Returns the first added error
    * @return String
    */
    public String getFirstError() {
        return this.errors.isEmpty()
            ? null
            : this.errors[0];
    }
}