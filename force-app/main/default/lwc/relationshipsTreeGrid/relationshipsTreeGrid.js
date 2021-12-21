import { LightningElement, api, track } from "lwc";
import getInitialView from "@salesforce/apex/RelationshipsTreeGridController.getInitialView";
import getRelationships from "@salesforce/apex/RelationshipsTreeGridController.getRelationships";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import RELATIONSHIP_CONTACT from "@salesforce/schema/npe4__Relationship__c.npe4__Contact__c";
import RELATIONSHIP_OBJECT from "@salesforce/schema/npe4__Relationship__c";

import REL_View_Contact_Record from "@salesforce/label/c.REL_View_Contact_Record";
import REL_Create_New_Relationship from "@salesforce/label/c.REL_Create_New_Relationship";
import REL_RECenter from "@salesforce/label/c.REL_RECenter";
import REL_No_Relationships from "@salesforce/label/c.REL_No_Relationships";

const ACTION_DEFS = {
    NEW_RELATIONSHIP: {
        label: REL_Create_New_Relationship,
        name: "new_relationship",
    },
    RE_CENTER: {
        label: REL_RECenter,
        name: "re_center",
    },
    VIEW_RECORD: {
        label: REL_View_Contact_Record,
        name: "view_record",
    },
};

const COLUMNS_DEF = [
    {
        fieldName: "contactName",
        type: "text",
    },
    {
        fieldName: "title",
        type: "text",
    },
    {
        fieldName: "accountName",
        type: "text",
    },
    {
        fieldName: "relationshipExplanation",
        type: "text",
    },
    {
        type: "action",
        typeAttributes: {
            rowActions: [],
        },
    },
];

export default class RelationshipsTreeGrid extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isLightningOut;
    @api contactName;

    @track relationships;

    columns;
    contactIdsLoaded = [];
    displayedRelationshipIds = [];
    hasData = true;
    isLoading;
    vfPageURL;

    @track labels = {
        REL_No_Relationships,
    };

    async connectedCallback() {
        const relationshipsListView = await this.getInitialView(this.recordId);

        if (relationshipsListView) {
            this.columns = COLUMNS_DEF.map((column) => this.buildColumn(column, relationshipsListView));
            this.vfPageURL = relationshipsListView.vfPageURL;
            this.relationships = relationshipsListView.relations.map((relation) =>
                this.buildInitialRelationships(relation)
            );

            if (this.relationships.length === 0) {
                this.hasData = false;
            }

            this.labels.relationshipsPlural = relationshipsListView.labels.relationshipsPlural;

            this.isLoading = false;
        }
    }

    buildColumn(column, relationshipsListView) {
        if (column.fieldName) {
            return this.addFieldLabelToColumn(column, relationshipsListView);
        } else if (column.type === "action") {
            return this.buildActionsColumn(relationshipsListView);
        }
        return column;
    }

    buildInitialRelationships(relationship) {
        this.displayedRelationshipIds.push(relationship.relationshipId);
        return this.buildRowWithEmptyChildren(relationship);
    }

    buildRowWithEmptyChildren(relationship) {
        return {
            ...relationship,
            _children: [],
        };
    }

    addFieldLabelToColumn(column, relationshipsListView) {
        return {
            ...column,
            label: relationshipsListView.labels[column.fieldName],
        };
    }

    buildActionsColumn(relationshipsListView) {
        let rowActions = [ACTION_DEFS.VIEW_RECORD];

        if (relationshipsListView.showCreateRelationshipButton) {
            rowActions.push(ACTION_DEFS.NEW_RELATIONSHIP);
        }

        if (this.isLightningOut) {
            rowActions.push(ACTION_DEFS.RE_CENTER);
        }

        return {
            type: "action",
            typeAttributes: { rowActions },
        };
    }

    async getInitialView(contactId) {
        try {
            return await getInitialView({ contactId });
        } catch (ex) {
            this.dispatchEvent(new CustomEvent("accesserror", { detail: ex.body.message }));
        }
    }

    async getRelationships(contactId) {
        try {
            return await getRelationships({ contactId });
        } catch (ex) {
            this.dispatchEvent(new CustomEvent("accesserror", { detail: ex.body.message }));
        }
    }

    async handleToggle(event) {
        const { hasChildrenContent, row } = event.detail;
        if (!hasChildrenContent) {
            const relationshipViews = await this.getRelationships(row.contactId);

            const filteredChildren = this.buildRowsFromViews(relationshipViews);

            this.relationships = this.walkRelationshipsToAppendChildren(this.relationships, filteredChildren, row);
        }
    }

    buildRowsFromViews(relationshipViews) {
        return relationshipViews
            .map((relationship) => {
                if (this.isAlreadyLoaded(relationship.contactId)) {
                    return relationship;
                }
                return this.buildRowWithEmptyChildren(relationship);
            })
            .filter((relationship) => {
                // to prevent circular relationships / cycles, only show each individual relationship once
                return !this.displayedRelationshipIds.includes(relationship.relationshipId);
            });
    }

    walkRelationshipsToAppendChildren(relationships, children, row) {
        return relationships.map((relationship) => {
            if (relationship._children && relationship._children.length > 0) {
                const _children = this.walkRelationshipsToAppendChildren(relationship._children, children, row);
                return {
                    ...relationship,
                    _children,
                };
            }
            return this.updateRelationshipRow(relationship, row, children);
        });
    }

    updateRelationshipRow(relationship, row, children) {
        if (relationship.contactId === row.contactId) {
            delete relationship._children;
        }

        if (relationship.relationshipId === row.relationshipId) {
            if (children.length > 0) {
                return this.attachChildrenToRow(children, relationship);
            } else {
                delete relationship._children;
            }
        }

        return relationship;
    }

    attachChildrenToRow(children, relationship) {
        this.displayedRelationshipIds = this.displayedRelationshipIds.concat(
            children.map((child) => child.relationshipId)
        );
        this.contactIdsLoaded.push(relationship.contactId);
        return {
            ...relationship,
            _children: children,
        };
    }

    navigateToRecord(recordId) {
        if (this.isLightningOut) {
            window.open("/" + recordId);
        } else {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId,
                    actionName: "view",
                },
            });
        }
    }

    newRelationship(recordId) {
        const defaultFieldValues = encodeDefaultFieldValues({
            [RELATIONSHIP_CONTACT.fieldApiName]: recordId,
        });

        if (this.isLightningOut) {
            window.open("/lightning/o/npe4__Relationship__c/new?defaultFieldValues=" + defaultFieldValues);
        } else {
            const navigateArgs = {
                type: "standard__objectPage",
                attributes: {
                    objectApiName: RELATIONSHIP_OBJECT.objectApiName,
                    actionName: "new",
                },
                state: { defaultFieldValues },
            };

            this[NavigationMixin.Navigate](navigateArgs);
        }
    }

    reCenterOnContact(contactId) {
        // action only visible when component is hosted on vf page in lightning out
        if (this.isLightningOut) {
            window.location = this.vfPageURL + "?isdtp=p1&id=" + contactId;
        }
    }

    handleRowAction(event) {
        const { action, row } = event.detail;

        switch (action.name) {
            case ACTION_DEFS.VIEW_RECORD.name:
                this.navigateToRecord(row.contactId);
                break;
            case ACTION_DEFS.RE_CENTER.name:
                this.reCenterOnContact(row.contactId);
                break;
            case ACTION_DEFS.NEW_RELATIONSHIP.name:
                this.newRelationship(row.contactId);
                break;
        }
    }

    isAlreadyLoaded(contactId) {
        return this.contactIdsLoaded.includes(contactId) || this.recordId === contactId;
    }

    get tableLabel() {
        if (this.contactName && this.labels.relationshipsPlural) {
            return `${this.labels.relationshipsPlural} - ${this.contactName}`;
        }
    }
}
