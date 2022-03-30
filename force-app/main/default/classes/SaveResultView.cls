/*
 *
 *     Copyright (c) 2022, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
/**
* @author Salesforce.org
* @date 2022
* @description View class representing a successful Save of a Recurring Donation
*/
public class SaveResultView {
    @AuraEnabled public Boolean success;
    @AuraEnabled public Id recordId;
    @AuraEnabled public String recordName;
    @AuraEnabled public List<SaveErrorView> errors;

    public SaveResultView(Database.SaveResult result, npe03__Recurring_Donation__c rd) {
        this(result);
        this.recordName = rd.Name;
    }

    public SaveResultView(Database.SaveResult result) {
        this.success = result.isSuccess();
        this.recordId = result.id;
        if (!this.success) {
            this.errors = new List<SaveErrorView>();
            for(Database.Error err : result.getErrors()) {
                this.errors.add(new SaveErrorView(err));
            }
        }
    }

    public SaveResultView(String errorMessage) {
        this.success = false;
        this.errors = new List<SaveErrorView>();
        this.errors.add(new SaveErrorView(errorMessage));
    }
}