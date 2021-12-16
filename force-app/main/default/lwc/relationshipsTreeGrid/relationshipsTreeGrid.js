import { LightningElement, api, track } from "lwc";
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";


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

export default class RelationshipsTreeGrid extends LightningElement {
    @api contactId;

    @track relationships;
    columns = COLUMNS_DEF;
    contactName;

    async connectedCallback() {
        const relationshipsView = await getRelationships({ contactId: this.contactId });
        this.relationships = relationshipsView.nodes.map(relationship => {
            return {
                ...relationship,
                ancestors: [this.contactId],
                _children: []
            };
        });

        this.contactName = `${relationshipsView.rootNode.firstName} ${relationshipsView.rootNode.lastName}`;
    }

    async handleToggle(event) {
        const { name, isExpanded, hasChildrenContent, row } = event.detail;
        if (!hasChildrenContent) {

            const relationshipsView = await getRelationships({ contactId: row.id });

            const filteredChildren = relationshipsView.nodes.map(relationship => {
                return {
                    ...relationship,
                    ancestors: [...row.ancestors, row.id],
                    _children: []
                };
            }).filter(relationship => {
                return !row.ancestors.includes(relationship.id);
            });

            this.relationships = this.addChildrenToRow(this.relationships, filteredChildren, row.relId);
        }
    }

    addChildrenToRow(relationships, children, rowId) {
        return relationships.map(relationship => {
            if (relationship._children && relationship._children.length > 0) {
                const _children = this.addChildrenToRow(relationship._children, children, rowId);
                return {
                    ...relationship,
                    _children
                };
            }

            if (relationship.relId === rowId) {
                if (children.length > 0) {
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