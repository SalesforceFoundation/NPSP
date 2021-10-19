/**
 * For the original lightning-datatable mock that comes with
 * @salesforce/sfdx-lwc-jest, see:
 * https://github.com/salesforce/sfdx-lwc-jest/blob/master/src/lightning-stubs/datatable/datatable.js
 */
import { LightningElement, api } from 'lwc';

export const mockGetSelectedRows = jest.fn();

export function getSelectedRowsImpl() {
    if(this.selectedRows && this.selectedRows.length > 0) {
        return this.data.filter(record => {
            return this.selectedRows.includes(record[this.keyField]);
        });
    }
    return [];
}

export default class Datatable extends LightningElement {
    @api columnWidthsMode;
    @api columns;
    @api data;
    @api defaultSortDirection;
    @api draftValues;
    @api enableInfiniteLoading;
    @api errors;
    @api hideCheckboxColumn;
    @api hideTableHeader;
    @api isLoading;
    @api keyField;
    @api loadMoreOffset;
    @api maxColumnWidth;
    @api maxRowSelection;
    @api minColumnWidth;
    @api renderConfig;
    @api resizeColumnDisabled;
    @api resizeStep;
    @api rowNumberOffset;
    @api selectedRows;
    @api showRowNumberColumn;
    @api sortedBy;
    @api sortedDirection;
    @api suppressBottomBar;
    @api wrapTextMaxLines;
    @api getSelectedRows = mockGetSelectedRows;
}