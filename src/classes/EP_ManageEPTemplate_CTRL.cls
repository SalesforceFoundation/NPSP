public with sharing class EP_ManageEPTemplate_CTRL {

    /** @description The Id of the Household Object or Account */
    public ID templateId { get; set; }
    public Engagement_Plan_Template__c template { get; set; }

    public EP_Task_UTIL util;

    private class permsException extends Exception {}

    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    public string namespacePrefix { get; set; }

    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    public EP_ManageEPTemplate_CTRL() {
        this(null);
    }

    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    public EP_ManageEPTemplate_CTRL(ApexPages.StandardController controller) {
        namespacePrefix = UTIL_Namespace.getNamespace();

        templateId = ApexPages.currentPage().getParameters().get('Id');

        util = new EP_Task_UTIL(templateId);

        template = util.templateMap.get(templateId);

        parentTaskWrappers = new list<taskWrapper>();


        for (Engagement_Plan_Task__c task : util.epTaskMap.values()) {
            //seed top level tasks, then get children recursively
            if (task.Dependent_Task__c == null) {
                taskWrapper wrapper = new taskWrapper(task);
                parentTaskWrappers.add(wrapper);
                addChildrenRecursive(wrapper);
            }
        }
    }

    public void addChildrenRecursive(taskWrapper wrapper) {
        for (Engagement_Plan_Task__c task : wrapper.detail.Engagement_Plan_Tasks__r) {
            Engagement_Plan_Task__c childTask = util.epTaskMap.get(task.id);
            taskWrapper childWrapper = new taskWrapper(childTask);
            wrapper.children.add(childWrapper);
            addChildrenRecursive(childWrapper);
        }
    }

    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    private void checkFLS() {
        List<String> templateFields = new List<String>{
            'Name', 'Blank_Assignment_Rule__c', 'Delay_Type__c', 'Skip_Day__c', 'Skip_Weekends__c', 'Description__c'
        };

        List<String> epTaskFields = new List<String>{
            'Name', 'Assigned_To__c', 'Comments__c', 'Days_After__c', 'Dependent_Task__c', 'Priority__c',
            'Reminder__c', 'Reminder_Minutes__c', 'Send_Email__c', 'Status__c', 'Type__c'
        };

        for (String fieldName : templateFields) {
            checkFieldFLS('Engagement_Plan_Template__c', fieldName);
        }

        for (String fieldName : epTaskFields) {
            checkFieldFLS('Engagement_Plan_Task__c', fieldName);
        }
    }

    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    private void checkFieldFLS(String objectName, String fieldName) {
        DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(
            UTIL_Namespace.StrTokenNSPrefix(objectName), fieldName
        );
        if (dfr == null || !dfr.isAccessible() || !dfr.isUpdateable()) {
            throw (new permsException(
                string.format(
                    label.flsError, 
                    new string[]{UTIL_Namespace.StrTokenNSPrefix(objectName + '.' + fieldName)}
                )
            ));
        }
    }
    
    /** @description what is the namespace (null if unmanaged, or npsp if managed) */
    public pageReference saveClose() {
        pageReference source = new pageReference('/'+templateId);
        source.setRedirect(true);
        source.getParameters().put('t',''+(System.currentTimeMillis()));
        
        try {
            upsert template;
            return source;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
    }







    List<taskWrapper> parentTaskWrappers {get; set;}

    public Class taskWrapper {
        public Engagement_Plan_Task__c detail { get; set; }
        public List<taskWrapper> children { get; set; }

        public taskWrapper(Engagement_Plan_Task__c task) {
            this.detail = task;
            this.children = new List<taskWrapper>();
        }
    }

    public Component.Apex.OutputPanel getTaskTree(){
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel(styleClass = 'slds-size--1-of-1');
    
        for(taskWrapper wrapper : parentTaskWrappers) {
            outPanel.childComponents.add( addChildComponents(wrapper, 0, 'parentTaskWrappers') );
        }
        
        return outPanel;
    }

    private Component.Apex.OutputPanel addChildComponents(taskWrapper wrapper, Integer level, String accessString) {
        accessString = accessString + '[' + level + ']';
        Component.Apex.OutputPanel outPanel = new Component.Apex.OutputPanel(styleClass='slds-card slds-m-around--medium');//slds-col--padded 
        
        Component.Apex.OutputPanel namePanel = new Component.Apex.OutputPanel(styleClass='slds-form-element');//slds-col--padded 
        Component.Apex.OutputLabel nameLabel = new Component.Apex.OutputLabel(
            value=UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Task__c'),'Name'), 
            styleClass='slds-form-element__label'
        );
        namePanel.childComponents.add(nameLabel);

        Component.Apex.InputText nameInput = new Component.Apex.InputText(
            value = wrapper.detail.Name,
            styleClass = 'slds-form-element__control slds-input'
        );
        nameInput.expressions.value = '{!' + accessString + '}';
        namePanel.childComponents.add(nameInput);

        Component.Apex.OutputPanel sendEmailPanel = new Component.Apex.OutputPanel(styleClass='slds-form-element');//slds-col--padded 
        Component.Apex.OutputLabel sendEmailLabel = new Component.Apex.OutputLabel(
            value=UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Task__c'),UTIL_Namespace.StrTokenNSPrefix('Send_Email__c')), 
            styleClass='slds-form-element__label'
        );
        sendEmailPanel.childComponents.add(sendEmailLabel);

        Component.Apex.InputCheckbox sendEmailInput = new Component.Apex.InputCheckbox(
            value = wrapper.detail.Send_Email__c,
            styleClass = 'slds-form-element__control slds-checkbox'
        );
        sendEmailInput.expressions.value = '{!' + accessString + '}';
        sendEmailPanel.childComponents.add(sendEmailInput);

        outPanel.childComponents.add(namePanel);
        outPanel.childComponents.add(sendEmailPanel);


        /*for (integer i = 0; i < wrapper.children.size(); i++) {
            outPanel.childComponents.add( addChildComponents(wrapper.children[i] , level, accessString + '.children') );
        }*/
        return outPanel;
    }
}