/*
    Copyright (c) 2012, Salesforce.com Foundation
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
* @date 2012 
* @description Controller for Relationships Setings VF page 
*/
public with sharing class STTG_Relationships_CTRL {
    
    /*** General Settings Properties ***/
    public npe4__Relationship_Settings__c relSettings{get;set;}
    //controls the active tab
    public String active_tab{get;set;}
    //edit controls
    public Boolean canEditRelSettings{get;set;}
    //dynamically load possible custom gender fields for selection options
    public List<SelectOption> genderFieldOptions{get{
        if (genderFieldOptions == null){
            genderFieldOptions = new List<SelectOption>();
            //add a default option
            genderFieldOptions.add(new SelectOption('', '-None-'));
                        
            map<String, Schema.SObjectField> conFieldTokenList = Schema.SObjectType.Contact.fields.getMap(); 
           
            //only get the describe information for custom fields
            for(string fieldName : conFieldTokenList.keyset()){
                if (fieldname.endsWith('npe4____c')){
                    genderFieldOptions.add(new SelectOption(fieldName, fieldName)); 
                }               
            }
        }               
        return genderFieldOptions;
    }set;}  
    /******/
    
    /*** Relationship Error Properties ***/
    public List<Error__c> relErrorsList{get{
        if (relErrorsList == null){        
           relErrorsList = new List<Error__c>();
           relErrorsList = [select id, Name, Record_URL__c, 
                          Error_Type__c, Full_Message__c, Datetime__c
                          from Error__c order by Datetime__c desc limit 1000];
        }                           
       return relErrorsList;
    }set;}
    public Integer relErrorsSize{get{return relErrorsList.size();}set;}
    /******/
            
    /*** Relationship Autocreate Properties ***/       
    public List<npe4__Relationship_Auto_Create__c> relAutoCreateList{get{
        relACMap = npe4__Relationship_Auto_Create__c.getAll();       
        return relACMap.values();
    }set;}
    public Integer acListSize{get{return relACMap.keySet().size();}set;}
    public Map<String, npe4__Relationship_Auto_Create__c> relACMap = new Map<String, npe4__Relationship_Auto_Create__c>();
    public String selectedACName{get;set;}
    public npe4__Relationship_Auto_Create__c activeAC{get;set;}
    public Boolean CMSelected{get{if(activeAC.npe4__Object__c == 'CampaignMember')return true;else return false;}}
    public Boolean canCRUDAC{get;set;}    
    public List<SelectOption> ACfieldOptions{get{
        ACfieldOptions = new List<SelectOption>();
        ACfieldOptions.add(new SelectOption('', '-None-'));
        if(activeAC.npe4__Object__c != null){
            map<String, Schema.SObjectField> fieldTokenMap = new Map<String, Schema.SobjectField>();
            if(activeAC.npe4__Object__c == 'Contact'){
                fieldTokenMap = Schema.SObjectType.Contact.fields.getMap();         
            }   
            else if (activeAC.npe4__Object__c == 'CampaignMember'){
                fieldTokenMap = Schema.SObjectType.CampaignMember.fields.getMap();          
            }   
            for (String s : fieldTokenMap.keySet()){
                if (s.equalsIgnoreCase('ReportsToId') || (s.endsWith('npe4____c') && !s.startsWith('npe01__') && !s.startsWith('npo02__') && !s.startsWith('npe03__'))){
                    //if we've hit the limit, throw a warning and recommend manual entry
                    if (system.Limits.getFieldsDescribes() == system.Limits.getLimitFieldsDescribes()){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, system.Label.npe4.RelationshipsCustomFieldOverload));                 
                    }
                    else{
                        Schema.DescribeFieldResult F = fieldTokenMap.get(s).getDescribe();             
                        List <Schema.sObjectType> sobjref = new List<Schema.sObjectType>(); 
                        sobjref = F.getReferenceTo();
                        for (Schema.sObjectType objT : sobjref){
                            if (objT == Contact.sObjectType){
                                ACfieldOptions.add(new SelectOption(F.getName(), F.getName()));
                            }                   
                        }               
                    }           
                }
            }
        }                                      
        return ACfieldOptions;      
    }set;}
    public List<String> cTypeOptions{get;set;}
    public List<SelectOption> ACCampaignTypeOptions{get{
        ACCampaignTypeOptions = new List<SelectOption>();
        Map<String, Schema.SObjectField> fieldMap = Schema.Sobjecttype.Campaign.fields.getMap(); 
        List<Schema.PicklistEntry> values = FieldMap.get('Type').getDescribe().getPickListValues();        
        for (Schema.PicklistEntry a : values){ 
            ACCampaignTypeOptions.add(new SelectOption(a.getLabel(), a.getValue())); 
        }
        return ACCampaignTypeOptions;
    }set;}
    /******/
    
    /*** Relationship Lookup Properties ***/
    public Boolean canCRUDRL{get;set;}
    public npe4__Relationship_Lookup__c activeRL{get;set;}
    public String selectedRLName{get;set;}
    public List<npe4__Relationship_Lookup__c> relLookupList{get{              
        return (List<npe4__Relationship_Lookup__c>)setCon.getRecords();
    }set;}
    public Integer numLookups{get;set;}
    public Integer pageSize{get;set;}
    public Integer rlListSize{get{return relLookupMap.keySet().size();}set;}
    public Map<String, npe4__Relationship_Lookup__c> relLookupMap = new Map<String, npe4__Relationship_Lookup__c>();
    public Boolean hasNextRL{get{return setCon.getHasNext();}set;}
    public Boolean hasPreviousRL{get{return setCon.getHasPrevious();}set;}
    public Integer pageNumberRL{get{return setCon.getPageNumber();}set;}    
    public Integer pageCountRL{get{
        Integer recDiv;
        recDiv = (Integer)setCon.getResultSize()/pageSize;
        if (Math.mod((Long)setCon.getResultSize(), (Long)pageSize) > 0)
           recDiv++;
        return recDiv;
    }set;}
    public ApexPages.Standardsetcontroller setCon{get{
        if (setCon == null) {
            pageSize = 20;  
            
            // Sort them by name
            List<String> roleNames = new List<String>();
            roleNames.addAll(relLookupMap.keySet());
            roleNames.sort();  
            
            list<npe4__Relationship_Lookup__c> listRel = new list<npe4__Relationship_Lookup__c>();
            for (string str : roleNames) {
                listRel.add(relLookupMap.get(str));
            }     
            
            setCon = new ApexPages.Standardsetcontroller(listRel);
            numLookups = setCon.getResultSize();
            setCon.setPageSize(pageSize);
        }        
        return setCon;                  
    }set;}
          
    /******/
    
    public STTG_Relationships_CTRL(){        
        relACMap = npe4__Relationship_Auto_Create__c.getAll();  
        relLookupMap = npe4__Relationship_Lookup__c.getAll();
        active_tab = 'general_settings'; 
        canEditRelSettings = false;
        canCRUDAC = false;
        if(relErrorsSize > 0){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Some errors have occurred during the normal operation of your Relationships package.  Please check the Relationship Errors tab below for more information.'));          
        }
    }
    
    public void getSettingsFirstTime(){
        relSettings = REL_Utils.getRelationshipSettings();        
    }
    
    
    public PageReference cancel(){      
        
        //reset general settings
        canEditRelSettings = false;
        relSettings = REL_Utils.getRelationshipSettings();
        
        //reset autocreate rel
        activeAC = new npe4__Relationship_Auto_Create__c();           
        canCRUDAC = false;
        
        //reset rl
        canCRUDRL = false;
        activeRL = new npe4__Relationship_Lookup__c();
        
        return null;
    }
    
    public PageReference deleteErrors(){
        delete relErrorsList;
        //requery
        relErrorsList = [select id, Name, Record_URL__c, 
                          Error_Type__c, Full_Message__c, Datetime__c
                          from Error__c order by Datetime__c desc limit 1000];
        return null;
    }
    
    /** General Settings Methods **/
    
    public PageReference saveGeneralSettings(){
        canEditRelSettings = false;
        try{
            update relSettings;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error updating General Settings.  Please refresh your page and try again.'));
        }
        return null;
    }
    public PageReference editGeneralSettings(){
        canEditRelSettings = true;      
        return null;        
    }   
    
    /*** Autorelationships CRUD Methods ***/
    public PageReference deleteAC(){     
        activeAC = relACMap.get(selectedACName);
        delete activeAC;
        //refetch the map
        relACMap = npe4__Relationship_Auto_Create__c.getAll();                                       
        return null;
    }
    public PageReference editAC(){      
        activeAC = relACMap.get(selectedACName);
        cTypeOptions = new List<String>();
        if(activeAC.npe4__Campaign_Types__c != null)
            cTypeOptions = activeAC.npe4__Campaign_Types__c.split(';');               
        canCRUDAC = true;
        return null;
    }
    public PageReference addAC(){
        activeAC = new npe4__Relationship_Auto_Create__c();
        cTypeOptions = new List<String>();
        canCRUDAC = true;
        return null;
    }
    public PageReference saveAC(){
        //compile the selected types
        String cTypes = '';
        if (activeAC.npe4__Object__c == 'CampaignMember'){
            for (String s : cTypeOptions){
                cTypes += s + ';';                      
            }
        }                   
        activeAC.npe4__Campaign_Types__c = cTypes;
        //if this is a new AC, we need to set the name 
        if (activeAC.Id == null){
            integer keyCount = relACMap.keySet().size();
            activeAC.Name = 'AutoCreateRel-' + keyCount;            
            //if the name is taken, increment until we find the next value slot...
            while(relACMap.containsKey(activeAC.Name)){
                keyCount++;              
                activeAC.Name = 'AutoCreateRel-' + keyCount;
            }       
        }
        if (activeAC.npe4__Object__c != null && activeAC.npe4__Field__c != null && activeAC.npe4__Relationship_Type__c != null){
            try{
                //upsert our active ac
                upsert activeAC;
                canCRUDAC = false;
                //refetch the data
                relACMap = npe4__Relationship_Auto_Create__c.getAll();  
            }catch(Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error Saving Auto-Relationship Record.  Please refresh your page and try again.'));
            }
        }
        else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Auto-creation requires a valid Object, Field and Relationship Type to save.'));           
        }           
        return null;
    }   

    /*** Relationship Lookup CRUD Methods ***/
    public PageReference deleteLookup(){        
        activeRL = relLookupMap.get(selectedRLName);
        delete activeRL;
        relLookupMap = npe4__Relationship_Lookup__c.getAll();  
        setCon = null;      
        return null;
    } 
    public PageReference editLookup(){
        activeRL = relLookupMap.get(selectedRLName);
        canCRUDRL = true;
        return null;
    }
    public PageReference addLookup(){
        activeRL = new npe4__Relationship_Lookup__c();
        canCRUDRL = true;
        return null;
    }
    public PageReference saveLookup(){
        canCRUDRL = false;
        try{
            upsert activeRL;
            relLookupMap = npe4__Relationship_Lookup__c.getAll();
            setCon = null;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error Saving Relationship Lookup Record.  Please refresh your page and try again.'));
        }
        return null;
    }
}