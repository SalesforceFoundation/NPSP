import { LightningElement, api, track } from "lwc";
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import RELATIONSHIP_CONTACT from "@salesforce/schema/npe4__Relationship__c.npe4__Contact__c";
import RELATIONSHIP_OBJECT from "@salesforce/schema/npe4__Relationship__c";

import REL_View_Contact_Record from "@salesforce/label/c.REL_View_Contact_Record";
import REL_Create_New_Relationship from "@salesforce/label/c.REL_Create_New_Relationship";
import REL_RECenter from "@salesforce/label/c.REL_RECenter";


const TABLE_ACTIONS = {
    LOAD_RELATIONS: "load_relations",
    RE_CENTER: "re_center",
    VIEW_RECORD: "view_record"
};

const COLUMNS_DEF = [
    {
        label: "Name",
        fieldName: "name",
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
        label: "Relationship Explanation",
        fieldName: "explanation",
        type: "text"
    },
    {
        type: "action",
        typeAttributes: {
            rowActions: [
                {
                    label: REL_View_Contact_Record,
                    name: TABLE_ACTIONS.VIEW_RECORD
                },
                {
                    label: REL_Create_New_Relationship,
                    name: TABLE_ACTIONS.NEW_RELATIONSHIP
                },
                {
                    label: REL_RECenter,
                    name: TABLE_ACTIONS.RE_CENTER
                }
            ]
        }
    }
];

export default class RelationshipsTreeGrid extends NavigationMixin(LightningElement) {
    @api recordId;

    @api
    set isLightningOut(val) {
        this._isLightningOut = val;
    }

    get isLightningOut() {
        return this._isLightningOut;
    }

    @track relationships;
    columns = COLUMNS_DEF;
    contactName;
    displayedRelationshipIds = [];
    contactIdsLoaded = [];
    vfPageURL;
    _isLightningOut = false;


    async connectedCallback() {
        const relationshipsView = await getRelationships({ contactId: this.recordId });
        this.vfPageURL = relationshipsView.vfPageURL;
        this.relationships = relationshipsView.nodes.map(relationship => {
            this.displayedRelationshipIds.push(relationship.relId);
            return {
                ...relationship,
                name: [relationship.firstName, relationship.lastName].join(" "),
                _children: []
            };
        });

        this.contactName = [relationshipsView.rootNode.firstName, relationshipsView.rootNode.lastName].join(" ");
    }

    async handleToggle(event) {
        const { name, isExpanded, hasChildrenContent, row } = event.detail;
        if (!hasChildrenContent) {

            const relationshipsView = await getRelationships({ contactId: row.id });

            const filteredChildren = relationshipsView.nodes.map(relationship => {
                if (this.isAlreadyLoaded(relationship.id)) {
                    return {
                        ...relationship,
                        name: [relationship.firstName, relationship.lastName].join(" ")
                    };
                }
                return {
                    ...relationship,
                    name: [relationship.firstName, relationship.lastName].join(" "),
                    _children: []
                };
            }).filter(relationship => {
                // to prevent circular relationships / cycles, only show each individual relationship once
                return !this.displayedRelationshipIds.includes(relationship.relId);
            });

            this.relationships = this.addChildrenToRow(this.relationships, filteredChildren, row);
        }
    }

    addChildrenToRow(relationships, children, row) {
        return relationships.map(relationship => {
            if (relationship._children && relationship._children.length > 0) {
                const _children = this.addChildrenToRow(relationship._children, children, row);
                return {
                    ...relationship,
                    _children
                };
            }

            if (relationship.id === row.id) {
                delete relationship._children;
            }

            if (relationship.relId === row.relId) {
                if (children.length > 0) {
                    this.displayedRelationshipIds = this.displayedRelationshipIds.concat(children.map(child => child.relId));
                    this.contactIdsLoaded.push(relationship.id);
                    return {
                        ...relationship,
                        _children: children
                    };
                } else {
                    delete relationship._children;
                }
            }

            return relationship;
        });
    }

    navigateToRecord(recordId) {
        if (this.isLightningOut) {
            window.open('/' + recordId);
        } else {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId,
                    actionName: "view"
                }
            });
        }
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

    reCenterOnContact(contactId) {
        if (this.isLightningOut) {
            window.location = this.vfPageURL + "?isdtp=p1&id=" + contactId;
        } else {
            const navigateArgs = {
                type: "standard__webPage",
                attributes: {
                    url: this.vfPageURL + "?id=" + contactId
                }
            };

            this[NavigationMixin.Navigate](navigateArgs);
        }
    }

    handleRowAction(event) {
        const { action, row } = event.detail;

        switch (action.name) {
            case TABLE_ACTIONS.VIEW_RECORD:
                this.navigateToRecord(row.id);
                break;
            case TABLE_ACTIONS.RE_CENTER:
                this.reCenterOnContact(row.id);
                break;
            case TABLE_ACTIONS.NEW_RELATIONSHIP:
                this.newRelationship(row.id);
                break;
        }
    }

    isAlreadyLoaded(contactId) {
        return this.contactIdsLoaded.includes(contactId);
    }
}