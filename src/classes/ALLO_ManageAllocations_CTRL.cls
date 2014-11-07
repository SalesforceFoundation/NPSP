/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Controller for the Manage Allocations page.
*/
public with sharing class ALLO_ManageAllocations_CTRL {

	public list<Allocation__c> listAllo {get;set;}
    public Allocation__c defaultAllo {get;set;}

    public integer listAlloSize {
        get{
            return listAllo.size();
        }
        set;
    }

    public list<Allocation__c> listAlloForDelete = new list<Allocation__c>();

    public id parentId {get;set;}
    public Opportunity opp {get;set;}
    public Campaign cam {get;set;}
    public npe03__Recurring_Donation__c rd {get;set;}
    public decimal parentAmount {get;set;}
    public static Allocations_Settings__c settings {get;set;}

    //row number sent back by page for add and delete row methods
    public integer rowNumber {get;set;}

    //constructor finds parent object, queries it, and sets parentId and parentAmount if possible
    public ALLO_ManageAllocations_CTRL() {

        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();

        map<string,string> params = ApexPages.currentPage().getParameters();
        parentAmount = 0;        
        
        if (params.containsKey('opp')) {
            parentId = String.escapeSingleQuotes(params.get('opp'));
            opp = [SELECT Id, Name, Amount FROM Opportunity WHERE Id = :parentId];
            //only Opportunities have parent amounts and enforce being below this amount
            parentAmount = opp.Amount;
        } else if (params.containsKey('cam')) {
            parentId = String.escapeSingleQuotes(params.get('cam'));
            cam = [SELECT Id, Name FROM Campaign WHERE Id = :parentId];
        } else if (params.containsKey('rd')) {
            parentId = string.escapeSingleQuotes(params.get('rd'));
            rd = [SELECT Id, Name FROM npe03__Recurring_Donation__c WHERE Id = :parentId];
        }

        defaultAllo = new Allocation__c();
        listAllo = [SELECT Id, Name, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c WHERE Opportunity__c = :parentId OR Campaign__c = :parentId OR Recurring_Donation__c = :parentId];

        //find default allocation if enabled, remove from list
        if (settings.Default_Allocations_Enabled__c && opp!=null) {
            for (integer i=0; i<listAllo.size(); i++) {
                if (listAllo[i].General_Accounting_Unit__c == settings.Default__c) {
                    defaultAllo = listAllo[i];
                    listAllo.remove(i);
                    break;
                }
            }
        }

        if (listAllo.isEmpty())
            addRow();
    }

    public pageReference addRow() {
        Allocation__c allo = new Allocation__c();

        if (opp!=null)
            allo.Opportunity__c = parentId;
        else if (cam!=null)
            allo.Campaign__c = parentId;
        else if (rd!=null)
            allo.Recurring_Donation__c = parentId;

        //enable adding to the last row
        if (rowNumber == null || rowNumber >= listAllo.size()-1)
            listAllo.add(allo);
        else
            listAllo.add(rowNumber+1, allo);
        return null;
    }

    public pageReference delRow() {
        //add to deletion list if the allocation has an id
        if (listAllo[rowNumber].id!=null)
            listAlloForDelete.add(listAllo[rowNumber]);
        listAllo.remove(rowNumber);

        return null;
    }

    public pageReference saveClose() {
        list<Allocation__c> listAlloForInsert = new list<Allocation__c>();
        list<Allocation__c> listAlloForUpdate = new list<Allocation__c>();
        pageReference source = new pageReference('/'+parentId);

        //split into insert and update cases so we can reset recursion flags for each operation
        for (Allocation__c allo : listAllo) {
            if (allo.id!=null) listAlloForUpdate.add(allo);
            else listAlloForInsert.add(allo);
        }

        try {
            if (!listAlloForDelete.isEmpty()) {
                ALLO_Allocations_TDTM.resetFlags(false);
                delete listAlloForDelete;

                //allow user to delete all GAUs and save with one empty GAU
                if (listAllo.size()==1 && listAllo[0].General_Accounting_Unit__c==null && listAllo[0].Amount__c==null && listAllo[0].Percent__c==null)
                    return source;
            }
            if (!listAlloForUpdate.isEmpty()) {
                ALLO_Allocations_TDTM.resetFlags(false);
                update listAlloForUpdate;
            }
            if (!listAlloForInsert.isEmpty()) {
                ALLO_Allocations_TDTM.resetFlags(false);
                insert listAlloForInsert;
            }
            
            return source;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
    }

    public pageReference cancel() {
        pageReference source = new pageReference('/'+parentId);
        return source;
    }
}