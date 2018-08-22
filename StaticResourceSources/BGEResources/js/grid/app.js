var templateId = '';
var selectPopper = undefined;
var isIndexLoading = false;
var isTableLoaded = false; // Needed for afterCreateRow:as it fires before afterInit: & confuses all

var rowsCount = 0;
var rowsAmount = 0;
var templateFields = '';

var offset = 0;
var columnsData = '';
var rowsData = '';
var totalPages = 0;

var rowErrors = {};

var lastSelectedRow = null;
var lastSelectedColumn = null;

var tableWidth = 0;
var tableHeight = 0;

// onLoad Constructor
(function () {

    // Table Initalization
    Visualforce.remoting.Manager.invokeAction('{!$RemoteAction.BGE_HandsOnGridController.initGrid}', { batchId: batchId }, onInitHandler);

    function onInitHandler(result, event) {

        templateId = result.templateId;
        selectPopper = undefined;
        isIndexLoading = false;
        isTableLoaded = false; // Needed for afterCreateRow:as it fires before afterInit: & confuses all

        hideElements("#loadSpinnerEmbedded"); // Only used for pagination

        toggleDisabledButton("previousPageButton", true);

        if (result.data.length == 0) {
            toggleDisabledButton("nextPageButton", true);
        }

        // If the batch record hasn't template associated, displays alert message, else continue
        if (!templateId || templateId == null) {

            templateId = false;
            isTableLoaded = true;

            hideElements("#loadSpinner");
            showElements("#noTemplatesMessage");

            return;
        }

        templateId = true;
        hideElements("#noTemplatesMessage");

        rowsCount = result.rowsCount;
        rowsAmount = result.rowsAmount;
        templateFields = result.templateFields;

        offset = 0;
        columnsData = result.columns;
        rowsData = result.data;
        totalPages = Math.ceil(rowsCount / 50) + 1;

        rowErrors = {};

        lastSelectedRow = null;
        lastSelectedColumn = null;

        tableWidth = window.innerWidth * .985;
        tableHeight = window.innerHeight - 130;

        var table = document.getElementById('my-hot-table');

        hot = new Handsontable(table, {

            data: rowsData,

            outsideClickDeselects: false, //you must add this, otherwise getSelected() will return 'undefined'
            columnSorting: true,
            observeChanges: true,
            persistantState: false,
            contextMenu: true,
            readOnly: false,
            sortIndicator: true,
            fillHandle: true,
            autoWrapRow: true,
            minSpareRows: 0,
            width: tableWidth,
            height: tableHeight,
            minRows: 50,
            maxRows: 50,
            rowHeights: 30,
            colHeaders: true,
            columnHeaderHeight: 40,
            fixedColumnsLeft: 3,
            manualRowResize: false,
            columns: getHotColumns(),
            contextMenu: {
                items: {
                    remove_row: {
                        disabled: function (){
                            return false
                        }
                    }
                }
            },
            manualColumnResize: true,
            renderAllRows: false,

            cells: cellsHandler,
            afterInit: afterInitHandler,
            beforeRemoveRow: beforeRemoveRowHandler,
            afterRemoveRow: afterRemoveRowHandler,
            beforeChange: beforeChangeHandler,
            afterChange: afterChangeHandler,
            afterSelection: afterSelectionHandler,
            afterSelectionEnd: afterSelectionEndHandler,
            afterOnCellMouseDown: afterOnCellMouseDownHandler,
            afterCreateRow: afterCreateRowHandler,
            beforeKeyDown: beforeKeyDownHandler,
            afterScrollHorizontally: afterScrollHandler,
            afterScrollVertically: afterScrollHandler,
            modifyColWidth: modifyColWidthHandler,
            afterOnCellMouseOver: afterOnCellMouseOverHandler
        });

        displaySummaryData(result); // Updates summary data
        displayPaginationData(); // Updates pagination data

        //Map to save cells with invalid format values
        movedSideWays = false;
    }

})();

    function backAction() {

        window.history.back();
    }

    function prevPageAction() {

        if (offset > 0) {
            offset --;

            toggleDisabledButton("nextPageButton", false);
            displayPaginationData();

            changePageHandler();
        }
    }

    function nextPageAction() {

        offset ++;

        if (offset >= totalPages - 1) {
            offset = totalPages - 1;

            toggleDisabledButton("nextPageButton", true);
        }

        displayPaginationData();
        changePageHandler();
    }

    function removeRowOnColumnAction() {

        var row = hot.getSelected()[0];

        hot.alter('remove_row', row);

        setTimeout(function() {

            hot.render();
            updateSummaryData();
        }, 200);
    }

    function changePageHandler() {

        showElements("#loadSpinnerEmbedded");

        Visualforce.remoting.Manager.invokeAction('{!$RemoteAction.BGE_HandsOnGridController.changePageGrid}', {batchId: batchId, templateFields: templateFields, offset: offset}, changePageGridHandler);

        function changePageGridHandler(result, event) {

            toggleDisabledButton("previousPageButton", true);

            if (offset > 0) {
                toggleDisabledButton("previousPageButton", false);
            }

            hot.loadData(result.data);

            hideElements("#loadSpinnerEmbedded");

            var totalColumns = hot.countCols();
            var totalRows = hot.countRows();

            for (var indexRow = 0; indexRow < totalRows; indexRow++) {

                var cellValue = hot.getDataAtCell(indexRow, hot.propToCol('Id'));
                if (cellValue == null) {
                    hot.setDataAtCell(indexRow, hot.propToCol('Id'), Date.now().toString(), 'manual');
                }
            }

            // Clean errors when changing pages
            rowErrors = {};
            
            hot.render();
        }
    }

    function cellsHandler(row, col, prop) {

        if (prop === 'Errors') {
            return { type: { renderer: tooltipCellRenderer } };
        }
        else if (prop == 'Actions') {
            return { type: { renderer: actionCellsRenderer } };
        }
    }

    /**
     * We want to prevent header row being selected
     * TODO: we need to the same with first columns too
     * 'coords.row < 0' because we only want to handle clicks on the header row
     * @param {*} event
     * @param {*} coords
     */
    function afterOnCellMouseDownHandler(event, coords, td) {

        if (coords.row < 0) {
            hot.deselectCell();
        }

        var now = new Date().getTime();

        if (!(td.lastClick && now - td.lastClick < 200)) {
            td.lastClick = now;
            return;
        }

        var editor =  hot.getActiveEditor();
        var colType = hot.getDataType(coords.row, coords.col);

        if (colType == "dropdown") {
            editor.TEXTAREA.setAttribute("disabled", "true");
        }
    }

    function afterInitHandler() {

        isTableLoaded = true;
        isIndexLoading = true;

        hideElements("#loadSpinner");

        var totalColumns = this.countCols();
        var totalRows = this.countRows();

        for (var indexRow = 0; indexRow < totalRows; indexRow++) {

            var cellValue = this.getDataAtCell(indexRow, this.propToCol('Id'));

            if (cellValue == null) {
                this.setDataAtCell(indexRow, this.propToCol('Id'), Date.now().toString(), 'manual');
            }
        }

        isIndexLoading = false;

        renderBindings();
    }

    function afterScrollHandler() {

        setCellsHeight();
    }

    function afterOnCellMouseOverHandler(event, coords, td) {

        var editor =  hot.getActiveEditor();

        if (editor) {
            var colType = hot.getDataType(editor.row, editor.col);

            if ( (coords.col === 1 || coords.col === 2) && (colType === 'date' || colType === 'dropdown') ) {
                hot.destroyEditor();
            }
        }
    }

    function beforeRemoveRowHandler(index, amount, visualRows) {
        deleteRow(index, amount, visualRows);
    }

    function modifyColWidthHandler(width, col) {

        if (col === 0) {

            return 5;
        }
        else if (col === 1) {

            return 40;
        }
        else if (col === 2) {

            return 70;
        }
        else {

            return width;
        }
    }

    function deleteRow(index, amount, visualRows, callback) {

        var rowRecordIds = [];
        var columnIndex = hot.propToCol('Id');

        visualRows.forEach(function(element) {

            var rowRecordId = hot.getDataAtCell(element, columnIndex);
            rowRecordIds.push(rowRecordId);

            var requestData = {
                batchId: batchId,
                rowRecordIds: JSON.stringify(rowRecordIds)
            }

            Visualforce.remoting.Manager.invokeAction('{!$RemoteAction.BGE_HandsOnGridController.deleteRowsGrid}', requestData, deleteRowsGridHandler);

            function deleteRowsGridHandler(result, event) {

                if (callback) {
                    callback();
                }
            };
        });
    }

    function afterRemoveRowHandler(index, amount) {

        updateSummaryData();
    }

    function beforeChangeHandler(changes, source) {

        if (source === "CopyPaste.paste" || source === "Autofill.fill") {

            for (var i = 0; i < changes.length; i++) {

                var row = changes[i][0];
                var col = hot.propToCol(changes[i][1]);
                var cellColType = hot.getDataType(row, col);

                if (cellColType == "dropdown") {

                    var cell = hot.getCellMeta(row, col);

                    if (!cell.__proto__.source.includes(changes[i][3])) {
                        cell.instance.setDataAtCell(row, col, cell.__proto__.source[0]);
                    }
                }
            }
        }
    }

    function afterChangeHandler(changes, source) {

        var sourceOptions = ['edit', 'Autofill.fill', 'CopyPaste.paste'];

        if (sourceOptions.includes(source) && !isIndexLoading) {

            var cellRecords = [];

            for (var i = 0; i < changes.length; i ++) {

                var newValue = changes[i][3];
                var oldValue = changes[i][2];

                var cellRecord = {};

                if ((!newValue) && (!oldValue)) {
                    // This value is skipped
                }
                else {

                    var newCell = hot.getCellMeta(changes[i][0], hot.propToCol(changes[i][1]));
                    var newCellId = hot.getDataAtCell(changes[i][0], hot.propToCol('Id'));

                    if (newCell.hasError == true && (newCellId.toString().length < 18) && (!newValue || newValue == null || newValue == '')) {

                        for (var index = 0; index < rowErrors[newCellId].length; index ++) {

                            var element = rowErrors[newCellId][index];

                            if (element.field === changes[i][1]) {
                                rowErrors[newCellId].splice(index, 1);
                            }
                        }

                        newCell.valid = true;
                        newCell.hasError = false;
                    }
                    else if (changes[i][1] !== 'Id' && changes[i][1] !== 'Actions') {

                        var col = this.propToCol(changes[i][1])
                        var cellType = this.getDataType(changes[i][0], hot.propToCol('Id'));

                        // set new external Id value if the Id cell have null value in the data import that have changes
                        if (!this.getDataAtRowProp(changes[i][0], 'Id')) {

                            this.setDataAtRowProp(changes[i][0], 'Id', Date.now().toString(), 'manual');
                        }

                        var cellRecord = {
                            row: changes[i][0],
                            field: changes[i][1],
                            oldValue: changes[i][2],
                            newValue: newValue,
                            type: cellType,
                            recordId: this.getDataAtRowProp(changes[i][0], 'Id')
                        };

                        if (!newValue) {
                            newValue = null;
                            cellRecord.newValue = null;
                        }

                        if (cellRecord.newValue && (newValue !== 'NaN') && (cellRecord.oldValue !== cellRecord.newValue) || newValue == null) {

                            if (hot.getDataType(newCell.row, newCell.col) == "dropdown") {

                                var cell = hot.getCellMeta(newCell.row, newCell.col);
                                var includesValue = cell.__proto__.source.includes(changes[0][3]);

                                if (includesValue && newValue!= cell.__proto__.source[0]) {
                                    cellRecords.push(cellRecord);
                                }
                            }
                            else {
                                cellRecords.push(cellRecord);
                            }
                        }
                        else if ((newValue == 'NaN') && (cellType == 'date')) {

                            if (!rowErrors[cellRecord.recordId] || (rowErrors[cellRecord.recordId] && rowErrors[cellRecord.recordId].length == 0)) {

                                rowErrors[cellRecord.recordId] = [];
                                rowErrors[cellRecord.recordId].push({field: cellRecord.field, messages: 'Illegal assignment from String to Date'});
                            }
                            else {

                                var isFieldIn = false;
                                rowErrors[cellRecord.recordId].forEach(function(element){

                                    if (element.field === cellRecord.field) {
                                        element.messages = 'Illegal assignment from String to Date';
                                        isFieldIn = true;
                                    }
                                });

                                if (!isFieldIn) {
                                    rowErrors[cellRecord.recordId].push({field: cellRecord.field, messages: 'Illegal assignment from String to Date'});
                                }
                            }
                        }

                    }
                    else {
                        updateSummaryData();
                    }
                }
            }
            if (cellRecords.length > 0) {

                var requestData = {
                    batchId: batchId,
                    cellRecords: JSON.stringify(cellRecords)
                };

                Visualforce.remoting.Manager.invokeAction('{!$RemoteAction.BGE_HandsOnGridController.dmlCellsRowGrid}', requestData, onDmlGridHandler);
            }
            else {

                setTimeout(function() {
                    hot.render();
                }, 200);
            }

            function onDmlGridHandler(result, event) {

                var idCellsForUpdate = [];

                if (result && result.length > 0) {

                    result.forEach(function(cellResponse) {

                        var errCell = hot.getCellMeta(cellResponse.row, hot.propToCol(cellResponse.field));

                        if (cellResponse.errors) {

                            errCell.valid = false;
                            errCell.hasError = true;

                            if (!rowErrors[cellResponse.recordId] || (rowErrors[cellResponse.recordId] && rowErrors[cellResponse.recordId].length == 0)) {
                                rowErrors[cellResponse.recordId] = [];
                                rowErrors[cellResponse.recordId] = cellResponse.errors;
                            }
                            else {

                                var isFieldIn = false;
                                rowErrors[cellResponse.recordId].forEach(function(element) {

                                    if (element.field === cellResponse.field) {
                                        element.messages = cellResponse.messages
                                        isFieldIn = true;
                                    }
                                });

                                if (!isFieldIn) {
                                    rowErrors[cellResponse.recordId] = rowErrors[cellResponse.recordId].concat(cellResponse.errors);
                                }
                            }

                            debugRowErrors = rowErrors;

                        }
                        else if (rowErrors[cellResponse.recordId]) {

                            errCell.valid = true;
                            errCell.hasError = false;

                            for (var index = 0; index < rowErrors[cellResponse.recordId].length; index ++) {

                                var element = rowErrors[cellResponse.recordId][index];

                                if (element.field === cellResponse.field) {
                                    rowErrors[cellResponse.recordId].splice(index, 1);
                                }
                            }
                        }

                        if (cellResponse.sfdcid) {

                            idCellsForUpdate.push([cellResponse.row, hot.propToCol('Id'), cellResponse.sfdcid]);

                            if (cellResponse.sfdcid !== cellResponse.recordId) {

                                if (rowErrors[cellResponse.recordId] && rowErrors[cellResponse.recordId].length > 0) {
                                    rowErrors[cellResponse.sfdcid] = rowErrors[cellResponse.recordId];
                                }
                            }
                        }

                    });

                    // setDataAtCell ALWAYS TRIGGER A FULL TABLE RENDER - USE WITH CARE AND IN BULK WHERE POSSIBLE
                    hot.setDataAtCell(idCellsForUpdate, 'manual');

                    setTimeout(function() {
                        hot.render();
                        updateSummaryData();
                    }, 200);
                }
            }
        }
        else {
            // source === 'paste'
            // source === 'autofill'
            // source === 'loadData'
            // And other custom sources
        }
    }

    /**
    * When HOT starts - it sets the initial row on the last selected ROW.
    * @param {*} row
    */
    function afterSelectionHandler(row, col) {

        setActionButtonActive(row, col);

        document.getElementById('action-menu-container').style.display = 'none';

        if (lastSelectedRow === null) {
            lastSelectedRow = row;
            lastSelectedColumn = col;
        }

        lastSelectedColumn = col;
    }

    function afterSelectionEndHandler(row, col, rowEnd, colEnd) {

        // fix for remove selection box when actions cells and tooltip cells are being selected in the grid
        if (col < 3) {
            console.log('hide');
            hideElements(".wtBorder.current");
        }

        if ((row != lastSelectedRow)) {

            var recordId = hot.getDataAtRowProp(lastSelectedRow, 'Id');

            Visualforce.remoting.Manager.invokeAction('{!$RemoteAction.BGE_HandsOnGridController.dryRunRowGrid}', {batchId: batchId, recordId: recordId}, dryRunRowGridHandler);

            function dryRunRowGridHandler(result, event) {

                lastSelectedRow = row;
            }
        }
    }

    function afterCreateRowHandler(index, amount) {

        if (isTableLoaded === true) {
            hot.render();
        }
    }

    function beforeKeyDownHandler(event) {

        var totalSelection = hot.getSelected();

        // Check if one only cell was selected, else cells will be deselected after a key is pressed
        // (except Command(Mac) or Control(Mac/Win) keys, used for select multiple cells)
        if (totalSelection && totalSelection.length == 1 &&
            totalSelection[0][0] == totalSelection[0][2] &&
            totalSelection[0][1] == totalSelection[0][3]) {

            var tab = event.keyCode === 9;
            var left = event.keyCode === 37;
            var up = event.keyCode === 38;
            var right = event.keyCode === 39;
            var down = event.keyCode === 40;
            var enter = event.keyCode === 13;
            var spacebar = event.keyCode === 32;
            var shift = event.shiftKey;
            var selection = totalSelection[0];
            var rowIndex = selection[0];
            var colIndex = selection[1];
            var selectedColType = hot.getDataType(rowIndex, colIndex);

            var numberOfColumns = hot.countCols();
            var numberOfRows = hot.countRows();

            var lastRow = numberOfRows - 1;
            var lastColumn = numberOfColumns - 1;

            var firstRow = 0;
            var isFirstRow = (rowIndex === firstRow) ? true : false;

            var tooltipCol = 1;
            var actionCol = 2;

            if (selectedColType == "dropdown") {

                var editor = hot.getActiveEditor();

                if (!tab && !left && !up && !right && !down) {

                    if (spacebar) {
                        //prevent spacebar default behavior to auto scroll down
                        event.preventDefault();
                    }

                    disableEdit(editor);
                }
            }

            if (tab || left || up || right || down) {

                if (tab || enter) {
                    event.preventDefault();
                }

                //== ACTIONS column ==//
                if (colIndex === actionCol) {

                    if (down || up) {
                        event.preventDefault();
                    }
                    else if (left || shift && tab) {

                        event.preventDefault();

                        if (!isTooltipDisplayed(rowIndex)) {

                            colIndex = 0;

                            if (isFirstRow) {
                                rowIndex = 0;
                            }
                        }
                        else {
                            colIndex = actionCol;
                        }

                        try {
                            hot.selectCell(rowIndex, colIndex);
                        }
                        catch(err) {
                            console.log(err);
                        }
                    }
                    else if (right || tab) {

                        try {
                            hot.selectCell(rowIndex, colIndex);
                        }
                        catch(err) {
                            console.log(err);
                        }
                    }
                }
                //== TOOLTIP / ERROR column ==//
                else if (colIndex === tooltipCol) {

                    if (up) {
                        event.preventDefault();

                        var topRow = isFirstRow ? firstRow : (rowIndex - 1);

                        if (!isTooltipDisplayed(topRow)) {
                            colIndex = actionCol;
                        }

                        hot.selectCell(rowIndex, colIndex);
                    }
                    else if (down) {

                        event.preventDefault();

                        var numberOfRows = hot.countRows();
                        var lastRow = numberOfRows - 1;
                        rowIndex = (rowIndex === lastRow) ? lastRow : (rowIndex + 1);

                        if (!isTooltipDisplayed(rowIndex)) {
                            colIndex = actionCol;
                        }

                        hot.selectCell(rowIndex, colIndex);
                    }
                    else if (left || shift && tab) {

                        event.preventDefault();
                        colIndex = 0;

                        if (isFirstRow) {
                            rowIndex = firstRow;
                        }

                        try {
                            hot.selectCell(rowIndex, colIndex);
                        }
                        catch(err) {
                            console.log(err);
                        }
                    }
                    else if (right || tab) {
                        event.preventDefault();

                        try {
                            hot.selectCell(rowIndex, colIndex);
                        }
                        catch(err){
                            console.log(err);
                        }
                    }
                }
                //== last row last column cell selected == //
                else if (rowIndex === lastRow && colIndex === lastColumn) {

                        if (!shift && (right || tab)) {

                            if (!isTooltipDisplayed(firstRow)) {
                                hot.selectCell(firstRow, actionCol);
                            }
                            else {
                                hot.selectCell(firstRow, tooltipCol);
                            }
                        }
                        else if (shift && tab) {
                            hot.selectCell(rowIndex, colIndex);
                        }
                }
                //== last cell of every column selected ==//
                else if (colIndex == lastColumn) {

                    if (!shift &&  (right || tab)) {

                        var nextRow = rowIndex + 1;

                        if (!isTooltipDisplayed(nextRow)) {
                            colIndex = actionCol;
                            rowIndex++;
                        }
                        else {
                            colIndex = tooltipCol;
                            rowIndex++;
                        }
                        hot.selectCell(rowIndex, colIndex);
                    }
                    else if (shift && right) {
                        event.preventDefault();
                    }
                }
            }
            else if ((enter || spacebar) && selectedColType != "dropdown") {

                if (colIndex === tooltipCol) {
                    event.preventDefault();

                    var numberOfRows = hot.countRows();
                    var lastRow = numberOfRows - 1;
                    rowIndex = (rowIndex === lastRow) ? lastRow : (rowIndex + 1);

                    if (!isTooltipDisplayed(rowIndex, tooltipCol)) {
                        colIndex = actionCol;
                        hot.selectCell(rowIndex, colIndex);
                    }
                    else {
                        hot.selectCell(rowIndex, colIndex);
                    }
                }
                else if (colIndex === actionCol) {

                    event.stopImmediatePropagation();

                    var selector = '#actionCellId-' + rowIndex + ' button';
                    document.querySelectorAll(".action-cell button")[rowIndex].click();

                    document.querySelector('ul.jq-dropdown-menu :first-child > a').focus();
                }
                else {

                    if (enter) {

                        event.stopImmediatePropagation();
                        rowIndex++;

                        hot.selectCell(rowIndex, colIndex);
                    }
                }
            }
        }
    }

    function beforeRendererHandler(td, row, col, prop, value, cellProperties) {

        if (prop != 'Actions' && prop != 'Errors') {

            if (value != null && value.toString().match(/^\d+$/)) {

                var cellType = this.getDataType(row, col);

                if (cellType === 'date') {

                    var strValue = value.toString();

                    value = formatDateValue(strValue);

                    this.setDataAtCell(row, col, value);
                }
            }
        }
    }

    function disableEdit(editor) {
        editor.TEXTAREA.setAttribute("disabled", "true");
    }

    /// Auxiliary Methods

    function getCellDataType(sfdcDatatype) {

        var result = undefined;

        switch(sfdcDatatype) {

            case 'PICKLIST':
                result = 'dropdown'
                break;

            case 'BOOLEAN':
                result = 'boolean'
                break;

            case 'STRING':
            case 'EMAIL':
            case 'ID':
            case 'TEXTAREA':
            case 'URL':
                result = 'text';
                break;

            case 'DATE':
            case 'DATETIME':
                result = 'date';
                break;

            case 'CURRENCY':
            case 'NUMBER':
            case 'INTEGER':
            case 'DECIMAL':
            case 'DOUBLE':
            case 'PERCENT':
                result = 'numeric';
                break;
        }

        return result;
    }

    function getHotColumns() {

        var frozenColumns = [];
        var resultColumns = [];

        var idCol = new Object();
        idCol.title = ' ';
        idCol.type = 'text';
        idCol.data = 'Id';
        idCol.className = "htCenter htMiddle tooltip-column";
        idCol.wordWrap = true;
        idCol.colWidths = 5;
        idCol.readOnly = true;
        idCol.disableVisualSelection = true;
        frozenColumns.push(idCol);

        var errorCol = new Object();
        errorCol.title = ' ';
        errorCol.type = 'text';
        errorCol.data = 'Errors';
        errorCol.className = "htCenter htMiddle tooltip-column";
        errorCol.wordWrap = true;
        errorCol.colWidths = 40;
        errorCol.disableVisualSelection = false;
        errorCol.renderer = tooltipCellRenderer;
        errorCol.readOnly = true;
        frozenColumns.push(errorCol);

        var actionCol = new Object();
        actionCol.title = 'ACTIONS';
        actionCol.data = 'Actions';
        actionCol.colWidths = 70;
        actionCol.className = "htCenter htMiddle action-cell";
        actionCol.disableVisualSelection = true;
        frozenColumns.push(actionCol);

        for (var i = 0; i < columnsData.length; i++) {

            var templateField = columnsData[i];

            var col = new Object();
            col.data = templateField.apiName;
            col.required = templateField.required;
            col.title = getColumnTitle(templateField);
            col.type = getCellDataType(templateField.type);
            col.allowInvalid = true;
            col.wordWrap = false;
            col.colWidths = 210;

            col.className = "htLeft htMiddle slds-truncate";

            if (templateField.type === "DATE") {
                col.dateFormat = 'M/D/YYYY';
                col.className = "htLeft htMiddle slds-truncate custom-date";
                col.correctFormat = true;
                col.datePickerConfig = { 'yearRange': [1000, 3000] }
                col.colWidths = 170;
                col.editor = DateEditorCustom;
                col.renderer = dropdownAndDateCellRenderer;
            }
            else if (templateField.type === "CURRENCY") {
                col.numericFormat = { pattern: '$0,0.00', culture: 'en-US' };
                col.className = "htRight htMiddle slds-truncate";
                col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                col.colWidths = 100;
                col.editor = NumberEditorCustom;
            }
            else if (templateField.type === "DECIMAL" || templateField.type === "DOUBLE") {
                col.numericFormat = { pattern: '0.00', culture: 'en-US' };
                col.className = "htRight htMiddle slds-truncate";
                col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                col.colWidths = 100;
                col.editor = NumberEditorCustom;
            }
            else if (templateField.type === "NUMBER" || templateField.type === "INTEGER") {
                col.numericFormat = { pattern: '0', culture: 'en-US' };
                col.className = "htRight htMiddle slds-truncate";
                col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                col.colWidths = 100;
                col.editor = NumberEditorCustom;
            }
            else if (templateField.type === "EMAIL" || templateField.type === "STRING" ||
                    templateField.type === "TEXTAREA" || templateField.type === "URL") {

                col.editor = TextEditorCustom;
            }
            else if (templateField.type === "BOOLEAN") {

                col.type = "checkbox";
                col.colWidths = 50;
            }
            else if (templateField.type === 'PHONE') {

                col.colWidths = 150;
                col.editor = TextEditorCustom;
            }
            else if (templateField.type === 'PERCENT') {
                col.type = "numeric";
                col.numericFormat = { pattern: '0.000%', culture: 'en-US' };
                col.className = "htRight htMiddle slds-truncate";
                col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                col.colWidths = 80;
                col.editor = NumberEditorCustom;
            }
            else if (templateField.type === 'GEOLOCATION') {
                col.type = "text";
                col.colWidths = 170;
            }
            else if (templateField.type === 'TIME') {
                col.type = 'time';
                col.timeFormat= 'h:mm:ss a';
                col.correctFormat= true;
                col.colWidths = 80;
                col.editor = TextEditorCustom;
            }

            if (templateField.type === "PICKLIST") {
                col.strict = false;
                // Check if by any change the list containing picklist values are null empty or undefined.
                if (templateField.picklistValues) {

                    // allowInvalid: false - does not allow manual input of value that does not exist in the source.
                    // In this case, the ENTER key is ignored and the editor field remains open.
                    col.source = Object.keys(templateField.picklistValues);

                    if (templateField.isRecordType) {
                        recordTypeMap = templateField.picklistValues;
                    }
                }

                col.renderer = dropdownAndDateCellRenderer;
            }

            if (templateField.apiName !== "Id") {
                resultColumns.push(col);
            }
        }

        return frozenColumns.concat(resultColumns);
    }

    function getColumnIndexByProp(prop){

        if (prop) {

            for (var index = 0; index < columnsData.length; index ++) {

                if (columnsData[index].data && (prop.toLowerCase() === columnsData[index].data.toLowerCase())) {
                    return index;
                }
            }
        }
        return -1;
    }

    function getColumnTitle(templateField) {

        var result = templateField.label.toUpperCase();

        if (result === 'RECORD TYPE ID') {

            result = 'RECORD TYPE';
        }

        return result;
    }

    function setActionButtonActive(row, col) {

        setTimeout(function () {

            removeClassToElements('.action-cell button', 'action-button-active');

            if (col === 2) {
                var selector = '#actionCellId-' + row + ' button';
                document.querySelectorAll(".action-cell button")[row].classList.add('action-button-active');
            }

        }, 250);
    }

    function addMessage(cell, errors) {

        removeMessage();
        var messageSection = document.createElement('section');
        messageSection.className = 'slds-popover slds-nubbin_bottom-left slds-theme_error tooltip-error';
        messageSection.role = 'dialog';

        var messageSectionDiv = document.createElement('div');
        messageSectionDiv.className = 'slds-popover__body';

        var messageSectionDivList = document.createElement('ul');
        messageSectionDivList.style.listStyleType = 'none';

        if (errors.length <= 3) {

            errors.forEach(function(errorElement) {

                var messageSectionDivListElement = document.createElement('li');
                messageSectionDivListElement.className += "slds-p-around_xx-small";

                messageSectionDivListElement.innerHTML = setErrorMessage(errorElement.field, errorElement.messages);
                messageSectionDivList.appendChild(messageSectionDivListElement);
            })
        }
        else {

            var moreCounter = errors.length - 3;

            for (var i = 0; i < 4; i++) {

                var messageSectionDivListElement = document.createElement('li');
                messageSectionDivListElement.className += "slds-p-around_xx-small";

                if (i != 3) {
                    messageSectionDivListElement.innerHTML = setErrorMessage(errors[i].field, errors[i].messages);
                    messageSectionDivList.appendChild(messageSectionDivListElement);
                }
                else {
                    messageSectionDivListElement.innerHTML = '(' + moreCounter + ' more...)';
                    messageSectionDivList.appendChild(messageSectionDivListElement);
                }
            }
        }

        messageSectionDiv.appendChild(messageSectionDivList);
        messageSection.appendChild(messageSectionDiv);
        document.body.appendChild(messageSection);

        var popper = new Popper(cell, messageSection, {
            placement: 'top-end'
        });
    }

    function removeMessage() {

        removeElementsByClass('tooltip-error');
    }

    function removeElementsByClass(className) {

        var elements = document.getElementsByClassName(className);

        while (elements.length > 0) {
            elements[0].parentNode.removeChild(elements[0]);
        }
    }

    function removeClassToElements(selector, className) {

        var elements = document.querySelectorAll(selector);

        for (var i=0; i < elements.length; i++) {
            elements[i].classList.remove(className);
        }
    }

    function removeElementsById(elemId) {

        var element = document.getElementById(elemId);

        element.parentNode.removeChild(element);
    }

    function toggleElements(selector) {

        var elements = document.document.querySelectorAll(selector);

        for (var i=0; i < elements.length; i++) {

            if (element.style.display == 'block') {
                element.style.display = 'none';
            }
            else if (element.style.display == 'none') {
                element.style.display = 'block';
            }
        }
    }

    function showElements(selector) {

        var elements = document.querySelectorAll(selector);

        for (var i=0; i < elements.length; i++) {
            elements[i].style.display = 'block';
        }
    }

    function hideElements(selector) {

        var elements = document.querySelectorAll(selector);

        for (var i=0; i < elements.length; i++) {
            elements[i].style.display = 'none';
        }
    }

    function displaySummaryData(data) {

        document.getElementById("totalOfRecords").innerHTML = data.rowsCount;
        document.getElementById("totalAmount").innerHTML = numbro(data.rowsAmount).formatCurrency( { thousandSeparated: true,
                                                                                                     mantissa: 2
                                                                                                   } );
    }

    function displayPaginationData() {

        document.getElementById("totalPagesNumber").innerHTML = Math.ceil(rowsCount / 50) + 1;
        document.getElementById("actualPageNumber").innerHTML = offset + 1;
    }

    function toggleDisabledButton(elemId, value) {

        document.getElementById(elemId).disabled = value;
    }

    function renderBindings() {

        if (window.attachEvent) {
            window.attachEvent('onresize', updateHotTable);
        }
        else {
            window.addEventListener('resize', updateHotTable, true);
        }

        var amountElements = document.getElementsByClassName("amount-style");

        for (var i = 0; i < amountElements.length; i++) {
            amountElements[i].parentNode.style.textAlign = "right";
        }
    }

    function updateSummaryData() {

        Visualforce.remoting.Manager.invokeAction('{!$RemoteAction.BGE_HandsOnGridController.getSummaryData}', {batchId: batchId}, getSummaryDataHandler);

        function getSummaryDataHandler(result, event) {

            rowsCount = result.rowsCount;
            rowsAmount = result.rowsAmount;
            totalPages = Math.ceil(rowsCount / 50) + 1;

            if (offset >= totalPages - 1) {

                toggleDisabledButton("nextPageButton", true);
            }
            else {

                toggleDisabledButton("nextPageButton", false);
            }

            displaySummaryData(result);
            document.getElementById("totalPagesNumber").innerHTML = Math.ceil(result.rowsCount / 50) + 1;
        }
    }

    function updateHotTable() {

        var newWidth = window.innerWidth * .985;
        var newHeight = window.innerHeight - document.getElementById("my-hot-table").offsetTop - 27;

        if (hot) {

        }
        hot.updateSettings({
            width: newWidth,
            height: newHeight
        });
    }


    // Editors

    var NumberEditorCustom = Handsontable.editors.TextEditor.prototype.extend();
    var TextEditorCustom = Handsontable.editors.TextEditor.prototype.extend();
    var DateEditorCustom = Handsontable.editors.DateEditor.prototype.extend();

    NumberEditorCustom.prototype.createElements = function () {
        // Call the original createElements method
        Handsontable.editors.TextEditor.prototype.createElements.apply(this, arguments);

        this.TEXTAREA.className = 'htRight handsontableInput';

        Handsontable.dom.empty(this.TEXTAREA_PARENT);
        this.TEXTAREA_PARENT.appendChild(this.TEXTAREA);
    };

    TextEditorCustom.prototype.createElements = function () {

        // Call the original createElements method
        Handsontable.editors.TextEditor.prototype.createElements.apply(this, arguments);

        this.TEXTAREA.className = 'htLeft handsontableInput';

        Handsontable.dom.empty(this.TEXTAREA_PARENT);
        this.TEXTAREA_PARENT.appendChild(this.TEXTAREA);
    };

    DateEditorCustom.prototype.createElements = function () {
        // Call the original createElements method
        Handsontable.editors.DateEditor.prototype.createElements.apply(this, arguments);

        // Create datepicker input and update relevant properties
        this.TEXTAREA.className = 'htLeft handsontableInput';

        // Replace textarea with datepicker input
        Handsontable.dom.empty(this.TEXTAREA_PARENT);
        this.TEXTAREA_PARENT.appendChild(this.TEXTAREA);
    };


    // Renderers

    function actionCellsRenderer(instance, td, row, col, prop, value, cellProperties) {

        Handsontable.renderers.HtmlRenderer.apply(this, arguments);

        var selectElement = getLightningPicklist(row);

        Handsontable.dom.addEvent(selectElement, 'click', function (e) {
            e.preventDefault(); // prevent selection quirk
        });

        Handsontable.dom.empty(td);
        td.appendChild(selectElement);

        td.className = 'action-cell';
        td.id = 'actionCellId-' + row;

        return td;
    }

    function tooltipCellRenderer(instance, td, row, col, prop, value, cellProperties) {

        setCellsHeight();

        Handsontable.renderers.HtmlRenderer.apply(this, arguments);

        var iconContainer = document.createElement('div');

        var rowId = instance.getDataAtCell(row, instance.propToCol('Id'));
        var rowErr = rowErrors[rowId];

        if (rowErr && rowErr.length > 0) {

            iconContainer.style.display = 'block';
        }
        else {

            iconContainer.style.display = 'none';
            removeMessage();
        }

        Handsontable.dom.addEvent(iconContainer, 'click', function (e) {
            e.preventDefault(); // prevent selection quirk
        });
        Handsontable.dom.addEvent(iconContainer, 'mouseleave', function (e) {
            e.preventDefault(); // prevent selection quirk
            removeMessage();
        });
        Handsontable.dom.addEvent(iconContainer, 'mousemove', function (e) {
            e.preventDefault(); // prevent selection quirk

            if (rowErr && rowErr.length > 0) {
                iconContainer.style.display = 'block';
                addMessage(td, rowErr);
            }
        });

        var iconImage = document.createElement('img');
        iconImage.className = 'tooltip-image';
        iconImage.src = resourcePath + '/icons/warning.png';
        // iconImage.style.width = "60%";
        iconImage.style.cursor = "pointer";
        iconImage.style.paddingTop = '5px';

        iconContainer.appendChild(iconImage);
        Handsontable.dom.empty(td);
        td.appendChild(iconContainer);

        td.style.background = 'white !important';
        td.style.borderBottom = 'none';
        td.style.borderTop = 'none';
        td.style.borderLeft = 'none';

        td.className = 'tooltip-cell';

        return td;
    }

    function dropdownAndDateCellRenderer(instance, TD, row, col, prop, value, cellProperties) {

        var val = value == null ? '' : value;

        TD.className = "htRight htMiddle slds-truncate htNoWrap htAutocomplete";

        var innerContent = '<div class="slds-grid slds-nowrap slds-size_12-of-12">' +
                                '<div class="slds-size_11-of-12" style="text-align: left">' +
                                    '<div class="ellipsis slds-size_12-of-12" style="vertical-align: middle;">' + val + '</div>' +
                                '</div>' +
                                '<div class="slds-size_1-of-12">' +
                                    '<div class="slds-size_12-of-12 htAutocompleteArrow">▼</div>' +
                                '</div>' +
                        '</div>';

        TD.innerHTML = innerContent;

        var rowId = instance.getDataAtCell(row, instance.propToCol('Id'));
        var rowErr = rowErrors[rowId];

        var errorInCell = false;

        if (rowErr) {
            for (var i=0; i < rowErr.length; i++) {
                if (rowErr[i].field == prop) {
                    errorInCell = true;
                }
            }
        }

        if (errorInCell) {
            TD.className = "htRight htMiddle slds-truncate htNoWrap htAutocomplete htInvalid";
        }

        return TD;
    }

    // Validation Errors

    function emailValidator(value, callback) {

        setTimeout(function () {

            if (/.+@.+/.test(value)) {
                callback(true);
            } else {
                callback(false);
            }
        }, 1000);
    };

    // ACTION picklist
    function getLightningPicklist(row) {

        var divControl = document.createElement('div');

        divControl.className = 'slds-dropdown-trigger slds-dropdown-trigger_click picklist-click';

        var divButton = document.createElement('button');
        divButton.id = 'actionBtnId-' + row;

        divButton.className = 'slds-button slds-button_icon slds-button_icon-border-filled';

        divButton.setAttribute('aria-haspopup', 'true');
        divButton.setAttribute('data-jq-dropdown', '#action-menu-container');
        divButton.style.height = "25px";
        divButton.style.width = "25px";

        var iconImage = document.createElement('img');
        iconImage.className = 'slds-button__icon';
        iconImage.src = resourcePath + '/icons/click.png';
        iconImage.style.cursor = "pointer";

        divButton.appendChild(iconImage);
        divControl.appendChild(divButton);

        return divControl;
    }

    function getLightningPicklistOption(option) {

        var liElement = document.createElement('li');
        liElement.setAttribute('role', 'presentation');
        liElement.className = 'slds-dropdown__item';

        var liLinkElement = document.createElement('a');
        liLinkElement.role = 'menuitem';
        liLinkElement.setAttribute('href', 'javascript:void(0);');

        var liLinkSpanElement = document.createElement('span');
        liLinkSpanElement.className = 'slds-truncate';
        liLinkSpanElement.setAttribute('title', option);
        liLinkElement.appendChild(liLinkSpanElement);
        liElement.appendChild(liLinkElement);

        return liElement;
    }

    function setErrorMessage(apiName, errorMsg) {

        var message = apiName.split("_c").join("");

        var message = message.split("_").join(" ").trim();
        for (var i = 0; i < message.length; i++) {
            if (!isNaN(message[i]) && message[i] != " ") {
                message = message.split(message[i]).join("");
                break;
            }
        }
        message = message + " : " + errorMsg;
        return message;
    }

    function isTooltipDisplayed(row) {

        var rowId = hot.getDataAtCell(row, hot.propToCol('Id'));
        var rowErr = rowErrors[rowId];

        return (rowErr && rowErr.length > 0) ? true : false;
    }

    function setCellsHeight() {

        var headerElements = document.getElementsByTagName("th");
        var dataElements = document.getElementsByTagName("td");

        for (var i = 0; i < headerElements.length; i++) {
            headerElements[i].style.height = "40px";
        }

        for (var i = 0; i < dataElements.length; i++) {
            dataElements[i].style.height = "30px";
        }
    }