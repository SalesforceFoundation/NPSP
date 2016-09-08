/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Engagement Plans
* @group-content ../../ApexDocContent/EngagementPlans.htm
* @description Controller for Manage Engagement Plan Template UI.
*/
public with sharing class EP_ManageEPTemplate_CTRL {

    /** @description Custom exception class for throwing exceptions. */
    private class permsException extends Exception {}

    /** @description The current template */
    public Engagement_Plan_Template__c template { get; set; }

    /** @description EP Tasks that have been removed from the page and need to be deleted on save.*/
    private List<Engagement_Plan_Task__c> tasksToDelete = new List<Engagement_Plan_Task__c>();

    /** @description Utilities class for querying tasks associated to the template. */
    private EP_Task_UTIL util;

    /** @description Property used by the Add Dependent Task and Delete Task buttons to tell where in the heirarchy
    * to perform the functions. */
    public String currentTaskLevel {get; set;}

    /** @description Set the select options Reminder Time field.*/
    public List<SelectOption> reminderTimeOptions {
        get {
            List<SelectOption> options = new List<SelectOption>{
                new SelectOption('0', '12:00 AM'),
                new SelectOption('30', '12:30 AM'),
                new SelectOption('60', '1:00 AM'),
                new SelectOption('90', '1:30 AM'),
                new SelectOption('120', '2:00 AM'),
                new SelectOption('150', '2:30 AM'),
                new SelectOption('180', '3:00 AM'),
                new SelectOption('210', '3:30 AM'),
                new SelectOption('240', '4:00 AM'),
                new SelectOption('270', '4:30 AM'),
                new SelectOption('300', '5:00 AM'),
                new SelectOption('330', '5:30 AM'),
                new SelectOption('360', '6:00 AM'),
                new SelectOption('390', '6:30 AM'),
                new SelectOption('420', '7:00 AM'),
                new SelectOption('450', '7:30 AM'),
                new SelectOption('480', '8:00 AM'),
                new SelectOption('510', '8:30 AM'),
                new SelectOption('540', '9:00 AM'),
                new SelectOption('570', '9:30 AM'),
                new SelectOption('600', '10:00 AM'),
                new SelectOption('630', '10:30 AM'),
                new SelectOption('660', '11:00 AM'),
                new SelectOption('690', '11:30 AM'),
                new SelectOption('720', '12:00 PM'),
                new SelectOption('750', '12:30 PM'),
                new SelectOption('780', '1:00 PM'),
                new SelectOption('810', '1:30 PM'),
                new SelectOption('840', '2:00 PM'),
                new SelectOption('870', '2:30 PM'),
                new SelectOption('900', '3:00 PM'),
                new SelectOption('930', '3:30 PM'),
                new SelectOption('960', '4:00 PM'),
                new SelectOption('990', '4:30 PM'),
                new SelectOption('1020', '5:00 PM'),
                new SelectOption('1050', '5:30 PM'),
                new SelectOption('1080', '6:00 PM'),
                new SelectOption('1110', '6:30 PM'),
                new SelectOption('1140', '7:00 PM'),
                new SelectOption('1170', '7:30 PM'),
                new SelectOption('1200', '8:00 PM'),
                new SelectOption('1230', '8:30 PM'),
                new SelectOption('1260', '9:00 PM'),
                new SelectOption('1290', '9:30 PM'),
                new SelectOption('1320', '10:00 PM'),
                new SelectOption('1350', '10:30 PM'),
                new SelectOption('1380', '11:00 PM'),
                new SelectOption('1410', '11:30 PM')
            };
            return options;
        }
        set;
    }

    /** @description Picklist options for the Task Priority field. We're using Task values directly in case they have
    * been updated from their defaults.*/
    public List<SelectOption> taskPriorityOptions {
        get {
            return listSelectOptions('Task','Priority');
        }
    }

    /** @description Picklist options for the Task Status field. We're using Task values directly in case they have
    * been updated from their defaults.*/
    public List<SelectOption> taskStatusOptions {
        get {
            return listSelectOptions('Task','Status');
        }
    }

    /** @description Returns a list of SelectOptions for a given object and picklist field name.
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @return List<SelectOption> The select options for this picklist field.
    */
    private List<SelectOption> listSelectOptions(String objectName, String fieldName) {
        Schema.DescribeFieldResult describeField = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        List<SelectOption> result = new List<SelectOption>();
        for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
            if (entry.isActive()) {
                result.add(new SelectOption(entry.getLabel(), entry.getValue()));
            }
        }
        return result;
    }

    /** @description Returns the default SelectOption for a given object and picklist field name.
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @return String The default select option for this picklist field.
    */
    private String defaultSelectOption(String objectName, String fieldName) {
        Schema.DescribeFieldResult describeField = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
            if (entry.isDefaultValue()) {
                return entry.getValue();
            }
        }
        return null;
    }

    /** @description Creates an Engagement Plan Task with defaults set for required picklist fields.
    * @return Engagement_Plan_Task__c A new Engagement Plan Task.
    */
    private Engagement_Plan_Task__c getTaskDefaults() {
        Engagement_Plan_Task__c result = new Engagement_Plan_Task__c(
            Priority__c = defaultSelectOption('Task','Priority'),
            Status__c = defaultSelectOption('Task','Status')
        );
        return result;
    }

    /** @description Checks field level security for EP Template and EP Task fields. */
    private void checkFLS() {
        List<String> templateFields = new List<String>{
            'Name', 'Default_Assignee__c', 'Automatically_Update_Child_Task_Due_Date__c', 'Reschedule_To__c', 'Skip_Weekends__c', 'Description__c'
        };

        List<String> epTaskFields = new List<String>{
            'Name', 'Assigned_To__c', 'Comments__c', 'Days_After__c', 'Parent_Task__c', 'Priority__c',
            'Reminder__c', 'Reminder_Time__c', 'Send_Email__c', 'Status__c', 'Type__c'
        };

        for (String fieldName : templateFields) {
            checkFieldFLS('Engagement_Plan_Template__c', fieldName);
        }

        for (String fieldName : epTaskFields) {
            checkFieldFLS('Engagement_Plan_Task__c', fieldName);
        }
    }

    /** @description For a given object and field, verifies that the field is accessible and updateable,
    * throwing an exception if it isn't.*/
    private void checkFieldFLS(String objectName, String fieldName) {
        DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(
            UTIL_Namespace.StrTokenNSPrefix(objectName), 
            fieldName.endsWith('__c')?UTIL_Namespace.StrTokenNSPrefix(fieldName):fieldName
        );
        if (dfr == null || !dfr.isAccessible() || !dfr.isUpdateable()) {
            throw (new permsException(
                string.format(
                    label.flsError, 
                    new string[]{UTIL_Namespace.StrTokenNSPrefix(objectName) + '.' + 
                                 UTIL_Namespace.StrTokenNSPrefix(fieldName)}
                )
            ));
        }
    }

    /** @description Constructor queries for tasks related to this template and fills out task wrapper heirarchy.*/
    public EP_ManageEPTemplate_CTRL(ApexPages.StandardController controller) {
        checkFLS();

        Id templateId = ApexPages.currentPage().getParameters().get('Id');

        util = new EP_Task_UTIL(templateId);

        template = util.templateMap.get(templateId);
        
        if (templateId == null || template == null) {
            template = new Engagement_Plan_Template__c();
        }

        initWrapperHeirarchy();
    }

    /** @description Iterates over tasks related to the current template, creating a list of parent
    * EP tasks and a heirarchy of wrappers.*/
    public void initWrapperHeirarchy() {
        parentTaskWrappers = new list<TaskWrapper>();
        
        for (Integer i=0; i < util.epTaskMap.values().size(); i++) {
            Engagement_Plan_Task__c task = util.epTaskMap.values()[i];
            //seed top level tasks, then get children recursively
            if (task.Parent_Task__c == null) {
                TaskWrapper wrapper = new TaskWrapper(task);
                
                if (!task.Engagement_Plan_Tasks__r.isEmpty()) {
                    initChildrenRecursive(wrapper);
                }

                parentTaskWrappers.add(wrapper);
            }
        }
    }

    /** @description Navigates the heirarchy of Engagement Plan Tasks and recursively creates a wrapper heirarchy.
    * @param wrapper The TaskWrapper to create children wrappers for.
    * @return void This method updates class properties.
    */
    public void initChildrenRecursive(TaskWrapper wrapper) {
        for (Integer i=0; i<wrapper.detail.Engagement_Plan_Tasks__r.size(); i++) {
            Engagement_Plan_Task__c childTask = util.epTaskMap.get(wrapper.detail.Engagement_Plan_Tasks__r[i].id);
            
            TaskWrapper childWrapper = new TaskWrapper(childTask);
            childWrapper.parent = wrapper;
            wrapper.children.add(childWrapper);

            if (!childTask.Engagement_Plan_Tasks__r.isEmpty()) {
                initChildrenRecursive(childWrapper);
            }
        }
    }
    
    /** @description Save method attempts to save the template, delete EP Tasks that have been removed, create and 
    * update EP Tasks. */
    public pageReference saveClose() {

        try {
            upsert template;

            delete tasksToDelete;

            list<Engagement_Plan_Task__c> tasksForInsert = new List<Engagement_Plan_Task__c>();
            list<Engagement_Plan_Task__c> tasksForUpdate = new List<Engagement_Plan_Task__c>();

            //first, find and insert all EP Tasks without an Id
            for (TaskWrapper wrapper : mapTaskWrappers.values()) {
                Engagement_Plan_Task__c epTask = wrapper.detail;
                epTask.Engagement_Plan_Template__c = template.id;
                if (epTask.Id == null) {
                    tasksForInsert.add(epTask);
                }
            }

            if (!tasksForInsert.isEmpty()) {
                insert tasksForInsert;
            }

            //then, fill out any parent lookups and update everything
            for (TaskWrapper wrapper : mapTaskWrappers.values()) {
                Engagement_Plan_Task__c epTask = wrapper.detail;
                if (epTask.Parent_Task__c == null && wrapper.parent != null) {
                    epTask.Parent_Task__c = wrapper.parent.detail.Id;
                }
                tasksForUpdate.add(epTask);
            }

            if (!tasksForUpdate.isEmpty()) {
                update tasksForUpdate;
            }

            pageReference source = new pageReference('/'+template.Id);
            source.setRedirect(true);
            source.getParameters().put('t',''+(System.currentTimeMillis()));
            return source;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }

    /** @description Adds a new top level EP task. */
    public pageReference addTask() {
        Engagement_Plan_Task__c newTask = getTaskDefaults();

        TaskWrapper wrapper = new TaskWrapper(newTask);
        parentTaskWrappers.add(wrapper);

        return null;
    }

    /** @description Adds a new dependent EP task to the heirarchy. */
    public pageReference addDependentTask() {
        TaskWrapper parentTask = mapTaskWrappers.get(currentTaskLevel);

        Engagement_Plan_Task__c newTask = getTaskDefaults();
        if (parentTask.detail.Id != null) {
            newTask.Parent_Task__c = parentTask.detail.Id;
        }

        TaskWrapper newWrapper = new TaskWrapper(newTask);
        newWrapper.parent = parentTask;
        
        parentTask.children.add(newWrapper);

        return null;
    }
    
    /** @description Deletes a task from the heirarchy, reparenting any children tasks to the
    * deleted task's parent, and recalculating level names. */
    public pageReference deleteTask() {
        TaskWrapper currentTask = mapTaskWrappers.get(currentTaskLevel);

        //add to list for delete if Id is present
        if (currentTask.detail.Id != null) {
            tasksToDelete.add(currentTask.detail);
        }

        //reparent children wrappers and sobjects
        if (!currentTask.children.isEmpty()) {
            for (TaskWrapper child : currentTask.children) {
                //set sobject EP Task parent lookup
                if (currentTask.parent != null) {
                    child.detail.Parent_Task__c = currentTask.parent.detail.Id;
                    child.parent = currentTask.parent;
                } else {
                    child.parent = null;
                    child.detail.Parent_Task__c = null;
                }
            }
        }

        removeFromHeirarchy(currentTask);

        return null;
    }

    /** @description Removes a given wrapper from the heirarchy by removing the current wrapper from the parent's list
    * of children, and adding current children to parent's list of children. 
    * @param wrapper The TaskWrapper to remove from the wrapper heirarchy.
    * @return void This method updates class properties.
    */

    private void removeFromHeirarchy(TaskWrapper wrapper) {
        //reconfigure wrapper heirarchy
        if (wrapper.parent != null) {
            //remove from children list of parent
            for (Integer i=0; i<wrapper.parent.children.size(); i++) {
                if (wrapper.parent.children[i].level == wrapper.level) {
                    wrapper.parent.children.remove(i);
                    break;
                }
            }
            //add current task's children to parent wrapper
            for (TaskWrapper child : wrapper.children) {
                wrapper.parent.children.add(child);
            }
        } else {
            //remove from main list
            for (Integer i=0; i<parentTaskWrappers.size(); i++) {
                if (parentTaskWrappers[i].level == wrapper.level) {
                    parentTaskWrappers.remove(i);
                    break;
                }
            }
            //add children to main list
            for (TaskWrapper child : wrapper.children) {
                parentTaskWrappers.add(child);
            }
        }
    }

    /** @description Hex codes for SLDS colors used in the EP task input side color bars.*/
    private static final List<String> sidebarColors = new List<String>{'#EF7EAD', '#F88962', '#4BC076', '#7F8DE1', '#0C8EFF'};

    /** @description The top level TaskWrappers to display on the page.*/
    public List<TaskWrapper> parentTaskWrappers {get; set;}

    /** @description A map of level strings to TaskWrappers to easily get the current wrapper.*/
    public Map<String, TaskWrapper> mapTaskWrappers {get; set;}

    /** @description Inner class wrapper of Engagement Plan Tasks to enable displaying the nested heirarchy.*/
    public Class TaskWrapper {
        public Engagement_Plan_Task__c detail { get; set; }
        public List<TaskWrapper> children { get; set; }

        private TaskWrapper parent;

        private String level;

        public TaskWrapper(Engagement_Plan_Task__c task) {
            this.detail = task;
            this.children = new List<TaskWrapper>();
        }
    }

    /** @description Generates the markup for the dynamicComponent each time it is rendered. Creates a nested heirarchy
    * of Engagement Plan Task forms.
    * @return Component.Apex.OutputPanel
    */
    public Component.Apex.OutputPanel getTaskTree(){
    
        mapTaskWrappers = new Map<String, TaskWrapper>();

        Component.Apex.OutputPanel topLevelPanel = new Component.Apex.OutputPanel(styleClass = 'slds-form', layout='block');
    
        for (integer i = 0; i < parentTaskWrappers.size(); i++) {
            topLevelPanel.childComponents.add( addChildComponents(parentTaskWrappers[i], i, 'parentTaskWrappers', String.valueOf(i+1)) );
        }

        //add task button
        Component.Apex.OutputPanel buttonGridPanel = new Component.Apex.OutputPanel(styleClass='slds-grid', layout='block');
        Component.Apex.OutputPanel buttonColPanel = new Component.Apex.OutputPanel(styleClass='slds-col slds-p-around--medium', layout='block');

        Component.Apex.CommandButton addTaskButton = new Component.Apex.CommandButton(
            styleClass = 'slds-button slds-button--brand slds-float--left',
            rerender = 'taskTree',
            immediate = false
        );
        addTaskButton.expressions.action = '{!addTask}';
        addTaskButton.expressions.value = '{!$Label.EPAddTask}';
        
        buttonGridPanel.childComponents.add(buttonColPanel);
        buttonColPanel.childComponents.add(addTaskButton);

        topLevelPanel.childComponents.add(buttonGridPanel);

        return topLevelPanel;
    }

    /** @description Generates the markup for a single Engagement Plan Task form, then calls itself recursively for that
    * task's children.
    * @param wrapper The TaskWrapper for the current Engagement Plan Task.
    * @param level The number for which child record we're at in the current place of the heirarchy.
    * @param accessString The string for accessing the current place in the heirarchy using a nested expression.
    * @param levelString The numbered heirarchy level for naming and accessing EP Tasks.
    * @return Component.Apex.OutputPanel A form for an EP Task and its children.
    */
    private Component.Apex.OutputPanel addChildComponents(TaskWrapper wrapper, Integer level, String accessString, String levelString) {
        accessString += '[' + level + ']';
        wrapper.level = levelString;
        mapTaskWrappers.put(wrapper.level, wrapper);

        //number for looping through the available colors for the side bar
        Integer colorNumber = Math.mod(wrapper.level.countMatches('-'), sidebarColors.size());

        Component.Apex.OutputPanel topLevelPanel = new Component.Apex.OutputPanel(styleClass='slds-m-left--medium slds-m-top--small', layout='block');
        Component.Apex.OutputPanel formPanel = new Component.Apex.OutputPanel();
    
        //creates a box around the form with a label for the heirarchy level, and a color bar to more easily grock which level we're at
        Component.Apex.OutputText boxAndLabel = new Component.Apex.OutputText(value='<div aria-labelledby="task' + wrapper.level + 
            '", class="slds-m-left--medium slds-m-top--small"><fieldset class="slds-box slds-theme--default slds-container--fluid '+
            'slds-p-around--small", style="border-left: 6px solid ' + sidebarColors[colorNumber] + '"><legend id=task' + wrapper.level + 
            ' class="slds-text-heading--small">' + Schema.Sobjecttype.Task.getLabel() + ' ' + wrapper.level + '</legend>', escape=false);

        Component.Apex.OutputPanel firstRow = new Component.Apex.OutputPanel(styleClass='slds-grid', layout='block');
        Component.Apex.OutputPanel secondRow = new Component.Apex.OutputPanel(styleClass='slds-grid', layout='block');
        Component.Apex.OutputPanel cardFooter = new Component.Apex.OutputPanel(styleClass='slds-grid', layout='block');
        Component.Apex.OutputPanel buttonGroup = new Component.Apex.OutputPanel(styleClass='slds-button-group slds-p-top--large', layout='block');

        firstRow.childComponents.add(genericInputPanel(wrapper, accessString, 'Name', 'slds-col slds-size--1-of-4', 'slds-input'));
        firstRow.childComponents.add(genericInputPanel(wrapper, accessString, 'Assigned_To__c', 'slds-col slds-size--1-of-4', 'lookupInput203'));
        firstRow.childComponents.add(genericInputPanel(wrapper, accessString, 'Type__c', 'slds-col slds-size--1-of-4', 'slds-select'));
        firstRow.childComponents.add(selectListInputPanel(wrapper, accessString, 'Priority__c', ' slds-col slds-size--1-of-4', 'slds-select','taskPriorityOptions'));

        secondRow.childComponents.add(selectListInputPanel(wrapper, accessString, 'Status__c', ' slds-col slds-size--1-of-4', 'slds-select','taskStatusOptions'));
        secondRow.childComponents.add(genericInputPanel(wrapper, accessString, 'Send_Email__c', 'slds-col slds-size--1-of-8 slds-p-top--medium slds-p-left--medium', 'slds-checkbox'));
        secondRow.childComponents.add(genericInputPanel(wrapper, accessString, 'Reminder__c', 'slds-col slds-size--1-of-8 slds-p-top--medium', 'slds-checkbox'));
        secondRow.childComponents.add(selectListInputPanel(wrapper, accessString, 'Reminder_Time__c', ' slds-col slds-size--1-of-4', 'slds-select','reminderTimeOptions'));
        secondRow.childComponents.add(genericInputPanel(wrapper, accessString, 'Days_After__c', 'slds-col slds-size--1-of-4', 'slds-input'));

        Component.Apex.OutputText addDependentTaskButton = new Component.Apex.OutputText(
            value='<button onclick="addDependentTaskJS(\''+ wrapper.level +'\');return false;" '+ 
            'class="slds-button slds-button--brand">'+Label.EPAddDependentTask+'</button>',
            escape=false
        );
         
        Component.Apex.OutputText deleteTaskButton = new Component.Apex.OutputText(
            value='<button onclick="deleteTaskJS(\''+ wrapper.level +'\');return false;" '+ 
            'class="slds-button slds-button--destructive">'+Label.EPDeleteTask+'</button>',
            escape=false
        );
        
        buttonGroup.childComponents.add(addDependentTaskButton);
        buttonGroup.childComponents.add(deleteTaskButton);
        cardFooter.childComponents.add(buttonGroup);
        cardFooter.childComponents.add(commentsInputPanel(wrapper, accessString, 'Comments__c', 'slds-col slds-p-left--medium', 'slds-textarea'));

        topLevelPanel.childComponents.add(formPanel);
        formPanel.childComponents.add(boxAndLabel);
        
        formPanel.childComponents.add(firstRow);
        formPanel.childComponents.add(secondRow);
        formPanel.childComponents.add(cardFooter);

        //closes the box
        formPanel.childComponents.add(new Component.Apex.OutputText(value='</fieldset></div>', escape=false));

        //recursively call this method to add children
        for (integer i = 0; i < wrapper.children.size(); i++) {
            topLevelPanel.childComponents.add( addChildComponents(wrapper.children[i], i, accessString + '.children', levelString+'-'+(i+1)) );
        } 
        return topLevelPanel;
    }

    /** @description Generates the markup for an SLDS styled form element with label.
    * @param wrapper The TaskWrapper for the current Engagement Plan Task.
    * @param fieldName The name of the field.
    * @param outterCss CSS markup for the field input container.
    * @return Component.Apex.OutputPanel A form field container and label.
    */
    private Component.Apex.OutputPanel fieldLabelPanel(TaskWrapper wrapper, String fieldName, String outterCss) {
        Component.Apex.OutputPanel result = new Component.Apex.OutputPanel(styleClass='slds-form-element ' + outterCss, layout='block');
        Component.Apex.OutputLabel fieldLabel = new Component.Apex.OutputLabel(
            value=UTIL_Describe.getFieldLabel(
                UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Task__c'),
                //don't namespace prefix standard fields like Name
                fieldName.endsWith('__c')?UTIL_Namespace.StrTokenNSPrefix(fieldName):fieldName
            ), 
            styleClass='slds-form-element__label'
        );
        fieldLabel.for = fieldName + wrapper.level;
        result.childComponents.add(fieldLabel);
        return result;
    }

    /** @description Generates the markup for an SLDS styled apex:inputField.
    * @param wrapper The TaskWrapper for the current Engagement Plan Task.
    * @param accessString The string for accessing the current place in the heirarchy using a nested expression.
    * @param fieldName The name of the field.
    * @param outterCss CSS markup for the field input container.
    * @param inputCss CSS markup for the input itself.
    * @return Component.Apex.OutputPanel OutputPanel containing the markup for an inputField.
    */
    private Component.Apex.OutputPanel genericInputPanel(TaskWrapper wrapper, String accessString, String fieldName, String outterCss, String inputCss) {
        Component.Apex.OutputPanel outterPanel = fieldLabelPanel(wrapper, fieldName, outterCss);

        Component.Apex.InputField fieldInput = new Component.Apex.InputField(
            id = fieldName + wrapper.level,
            value = wrapper.detail.get(fieldName),
            styleClass = 'slds-form-element__control ' + inputCss,
            //Set the Name field as required for auto validation
            required = fieldName == 'Name'
        );
        fieldInput.expressions.value = '{!' + accessString + '.detail.' + fieldName + '}';
        outterPanel.childComponents.add(fieldInput);

        return outterPanel;
    }

    /** @description Generates the markup for an SLDS styled picklist.
    * @param wrapper The TaskWrapper for the current Engagement Plan Task.
    * @param accessString The string for accessing the current place in the heirarchy using a nested expression.
    * @param fieldName The name of the field.
    * @param outterCss CSS markup for the field input container.
    * @param inputCss CSS markup for the input itself.
    * @param selectOptions The controller parameter containing the selectOptions for this picklist.
    * @return Component.Apex.OutputPanel OutputPanel containing the markup for a picklist field.
    */
    private Component.Apex.OutputPanel selectListInputPanel(TaskWrapper wrapper, String accessString, String fieldName, String outterCss, String inputCss, String selectOptions) {
        Component.Apex.OutputPanel outterPanel = fieldLabelPanel(wrapper, fieldName, outterCss);

        Component.Apex.SelectList selectList = new Component.Apex.SelectList(
            id = fieldName + wrapper.level,
            value = wrapper.detail.get(fieldName),
            styleClass = 'slds-form-element__control ' + inputCss,
            style = 'height: calc(1.875rem + 2px);',
            size = 1,
            multiselect = false
        );
        selectList.expressions.value = '{!' + accessString + '.detail.' + fieldName + '}';
        Component.Apex.SelectOptions options = new Component.Apex.SelectOptions();
        options.expressions.value='{!'+selectOptions+'}';
        selectList.childComponents.add(options);
        outterPanel.childComponents.add(selectList);

        return outterPanel;
    }

    /** @description Generates the markup for an SLDS styled text area.
    * @param wrapper The TaskWrapper for the current Engagement Plan Task.
    * @param accessString The string for accessing the current place in the heirarchy using a nested expression.
    * @param fieldName The name of the field.
    * @param outterCss CSS markup for the field input container.
    * @param inputCss CSS markup for the input itself.
    * @return Component.Apex.OutputPanel OutputPanel containing the markup for a text area field.
    */
    private Component.Apex.OutputPanel commentsInputPanel(TaskWrapper wrapper, String accessString, String fieldName, String outterCss, String inputCss) {
        Component.Apex.OutputPanel outterPanel = fieldLabelPanel(wrapper, fieldName, outterCss);

        Component.Apex.InputTextarea fieldInput = new Component.Apex.InputTextarea(
            id = fieldName + wrapper.level,
            value = wrapper.detail.get(fieldName),
            styleClass = 'slds-form-element__control ' + inputCss,
            rows = 1
        );
        fieldInput.expressions.value = '{!' + accessString + '.detail.' + fieldName + '}';
        outterPanel.childComponents.add(fieldInput);

        return outterPanel;
    }
}