import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";

import CONTACT_LASTNAME from "@salesforce/schema/Contact.LastName";
import CONTACT_FIRSTNAME from "@salesforce/schema/Contact.FirstName";
import RELATIONSHIP_CONTACT from "@salesforce/schema/npe4__Relationship__c.npe4__Contact__c";
import RELATIONSHIP_OBJECT from "@salesforce/schema/npe4__Relationship__c";


const TABLE_ACTIONS = {
    VIEW_RECORD: "view_record",
    LOAD_RELATIONS: "load_relations",
    NEW_RELATIONSHIP: "new_relationship"
};

const COLUMNS_DEF = [
    {
        label: "First Name",
        fieldName: "firstName",
        type: "text"
    },
    {
        label: "Last Name",
        fieldName: "lastName",
        type: "text"
    },
    {
        label: "Title",
        fieldName: "title",
        type: "text"
    },
    {
        label: "Account",
        fieldName: "accountName",
        type: "text"
    },
    {
        label: "Relation",
        fieldName: "type",
        type: "text"
    },
    {
        type: "action",
        typeAttributes: {
            rowActions: [
                {
                    label: "View Record",
                    name: TABLE_ACTIONS.VIEW_RECORD
                },
                {
                    label: "Load Relations",
                    name: TABLE_ACTIONS.LOAD_RELATIONS
                },
                {
                    label: "New Relationship",
                    name: TABLE_ACTIONS.NEW_RELATIONSHIP
                }
            ]
        }
    }
];

const CONTACT_FIELDS = [CONTACT_FIRSTNAME, CONTACT_LASTNAME];

export default class RelationshipsTable extends NavigationMixin(LightningElement) {
    @api contactId;

    columns = COLUMNS_DEF;
    contactName;
    tableLabel;

    @wire(getRelationships, { contactId: "$contactId" })
    relationships;

    @wire(getRecord, { recordId: "$contactId", fields: CONTACT_FIELDS })
    wiredContactName({ error, data }) {
        if (data) {
            const firstName = getFieldValue(data, CONTACT_FIRSTNAME);
            const lastName = getFieldValue(data, CONTACT_LASTNAME);
            this.contactName = `${firstName} ${lastName}`;
            this.tableLabel = `${this.contactName} Relationships`;
        }
    }

    connectedCallback() {
        this.dispatchEvent(new CustomEvent("tableload", {
                detail: {
                    id: this.contactId
                }
            }
        ));
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId,
                actionName: "view"
            }
        });
    }

    newRelationship(recordId) {

        const defaultFieldValues = encodeDefaultFieldValues({
            [RELATIONSHIP_CONTACT.fieldApiName]: recordId
        });

        const navigateArgs = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: RELATIONSHIP_OBJECT.objectApiName,
                actionName: "new"
            },
            state: { defaultFieldValues }
        };

        this[NavigationMixin.Navigate](navigateArgs);
    }

    loadRelations(recordId) {
        this.dispatchEvent(new CustomEvent("loadrelations", { detail: recordId }));
    }

    handleRowAction(event) {
        const { action, row } = event.detail;

        switch (action.name) {
            case TABLE_ACTIONS.VIEW_RECORD:
                this.navigateToRecord(row.id);
                break;
            case TABLE_ACTIONS.LOAD_RELATIONS:
                this.loadRelations(row.id);
                break;
            case TABLE_ACTIONS.NEW_RELATIONSHIP:
                this.newRelationship(row.id);
                break;
        }
    }

}