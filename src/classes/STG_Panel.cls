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
* @description Controller for the base settings panel class.
*/
public with sharing virtual class STG_Panel {
	
	public STG_Panel() {
		//UTIL_Debug.debug('***** STG_Panel constructor');
		isEditMode = false;
	}
	
	public virtual string idPanel() { return null; }
	
	public boolean isEditMode { get; set; }
	
	public boolean isReadOnlyMode {
		get {
			return !isEditMode;
		}
	}
    
    static public STG_SettingsService stgService {
        get {
            if (stgService == null)  { 
            	stgService = STG_SettingsService.stgService;
                //UTIL_Debug.debug('***** getting STG_SettingsService.stgService: ' + stgService);
            }
            return stgService;
        }
        private set;
    }

    public virtual PageReference saveSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
	        stgService.saveAll();
	        isEditMode = false;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
        
    }

    public virtual PageReference editSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = true;
        return null;
    }

    public virtual PageReference cancelEdit() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = false;
        return null;
    }
       
    static public list<SelectOption> listSOAccountModels {
        get {
            if (listSOAccountModels == null) {
                listSOAccountModels = new list<SelectOption>();
                listSOAccountModels.add(new SelectOption(CAO_Constants.HH_ACCOUNT_PROCESSOR, CAO_Constants.HH_ACCOUNT_PROCESSOR));
                listSOAccountModels.add(new SelectOption(CAO_Constants.ONE_TO_ONE_PROCESSOR, CAO_Constants.ONE_TO_ONE_PROCESSOR));
                listSOAccountModels.add(new SelectOption(CAO_Constants.BUCKET_PROCESSOR, CAO_Constants.BUCKET_PROCESSOR));
            }
            return listSOAccountModels;
        }
        private set;
    }

    static public list<SelectOption> listSOContactRoles {
        get {    
            if (listSOContactRoles == null) {
                listSOContactRoles = new list<SelectOption>();
                listSOContactRoles.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSOContactRoles.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSOContactRoles;
        }
        private set;
    }

    static public list<SelectOption> listSOHHRules {
        get {
            if (listSOHHRules == null) {
                listSOHHRules = new list<SelectOption>();
                listSOHHRules.add(new SelectOption(HH_Households.ALL_PROCESSOR, HH_Households.ALL_PROCESSOR));
                listSOHHRules.add(new SelectOption(HH_Households.ALL_INDIVIDUALS_PROCESSOR, HH_Households.ALL_INDIVIDUALS_PROCESSOR));
                listSOHHRules.add(new SelectOption(HH_Households.NO_HOUSEHOLDS_PROCESSOR, HH_Households.NO_HOUSEHOLDS_PROCESSOR));
            }
            return listSOHHRules;
        }
        private set;
    }
    
    static public list<SelectOption> listSOContactRecTypes {
        get {
            if (listSOContactRecTypes == null) {
                listSOContactRecTypes = new list<SelectOption>();
                listSOContactRecTypes.add(new SelectOption('', Label.stgLabelNone));
                listSOContactRecTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList('Contact'));            
            }       
            return listSOContactRecTypes;
        }
        private set;
    }    
        
    static public list<SelectOption> listSOAccountRecTypeIds {
        get {
            if (listSOAccountRecTypeIds == null) {
                listSOAccountRecTypeIds = new list<SelectOption>();
                listSOAccountRecTypeIds.add(new SelectOption('', Label.stgLabelNone));
                listSOAccountRecTypeIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList('Account'));            
            }       
            return listSOAccountRecTypeIds;
        }
        private set;
    }    

    static public list<SelectOption> listSOOppRecTypes {
        get {
            if (listSOOppRecTypes == null) {
                listSOOppRecTypes = new list<SelectOption>();
                listSOOppRecTypes.add(new SelectOption('', Label.stgLabelNone));
                listSOOppRecTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList('Opportunity'));            
            }       
            return listSOOppRecTypes;
        }
        private set;
    }    
        
    static public list<SelectOption> listSOOppRecTypesIds {
        get {
            if (listSOOppRecTypesIds == null) {
                listSOOppRecTypesIds = new list<SelectOption>();
                listSOOppRecTypesIds.add(new SelectOption('', Label.stgLabelNone));
                listSOOppRecTypesIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList('Opportunity'));            
            }       
            return listSOOppRecTypesIds;
        }
        private set;
    }    

    static public list<SelectOption> listSOOppContactRoles {
        get {
            if (listSOOppContactRoles == null) {
                listSOOppContactRoles = new list<SelectOption>();
                listSOOppContactRoles.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for(Schema.PicklistEntry pe : P) {
                    listSOOppContactRoles.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSOOppContactRoles;
        }
        private set;
    }
    
    static public list<SelectOption> listSOOppTypes {
    	get {
	        if (listSOOppTypes == null) {
	            listSOOppTypes = new list<SelectOption>();
	            listSOOppTypes.add(new SelectOption('', Label.stgLabelNone));
	            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.Type; 
	            list<Schema.PicklistEntry> P = F.getPicklistValues();
	        
	            for (Schema.PicklistEntry plistentry: P) {
	                listSOOppTypes.add(new SelectOption(plistentry.getLabel(),plistentry.getLabel()));
	            }
	        }
	        return listSOOppTypes;
    	}
    	private set;
    }

     static public list<SelectOption> listSORelTypes {
        get {    
            if (listSORelTypes == null) {
                listSORelTypes = new list<SelectOption>();
                listSORelTypes.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.npe4__Relationship__c.fields.npe4__Type__c; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSORelTypes.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSORelTypes;
        }
        private set;
    }

     static public list<SelectOption> listSOCampaignTypes {
        get {    
            if (listSOCampaignTypes == null) {
                listSOCampaignTypes = new list<SelectOption>();
                listSOCampaignTypes.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.Campaign.fields.Type; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSOCampaignTypes.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSOCampaignTypes;
        }
        private set;
    }

    static public list<SelectOption> listSOMailingReportIds {
        get {
            if (listSOMailingReportIds == null) {
                listSOMailingReportIds = new list<SelectOption>();
                listSOMailingReportIds.add(new SelectOption('', Label.stgLabelNone));
                for (Report rpt : [select Id, Name from Report where Name like '%mail%']) {
                    listSOMailingReportIds.add(new SelectOption(rpt.Id, rpt.Name));
                }
            }
            return listSOMailingReportIds;
        }
        private set;
    }
       
    static public string strHHAccountRecordTypeLabel {
    	get {
    		if (strHHAccountRecordTypeLabel == null) {
    			strHHAccountRecordTypeLabel = UTIL_RecordTypes.GetRecordTypeName('Account', stgService.stgCon.npe01__HH_Account_RecordTypeID__c);
    		}
    		return strHHAccountRecordTypeLabel;
    	}
    	private set;
    }
       
    static public string strOneToOneRecordTypeLabel {
        get {
            if (strOneToOneRecordTypeLabel == null) {
                strOneToOneRecordTypeLabel = UTIL_RecordTypes.GetRecordTypeName('Account', stgService.stgCon.npe01__One_to_One_RecordTypeID__c);
            }
            return strOneToOneRecordTypeLabel;
        }
        private set;
    }     
}