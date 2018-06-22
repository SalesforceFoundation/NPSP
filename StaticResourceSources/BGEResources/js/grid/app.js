(function () {

    var myApp = angular.module('myApp', ['ngHandsontable', 'ngSanitize']);

    myApp.controller('MainCtrl', function ($scope, $compile, $timeout, $window) {

        $scope.nextPageAction = nextPageAction;
        $scope.prevPageAction = prevPageAction;
        $scope.backAction = backAction;

        BGE_HandsOnGridController.initGrid({batchId: batchId}, onInitHandler);

        function onInitHandler(result, event) {

            console.log(result);

            $scope.templateId = result.templateId;
            $scope.selectPopper = undefined;
            $scope.isIndexLoading = false;
            $scope.isTableLoaded = false; // Needed for afterCreateRow:as it fires before afterInit: & confuses all
            $scope.pageChangeLoader = false;

            if (!$scope.templateId || $scope.templateId == null) {
                $scope.templateId = false;
                $scope.isTableLoaded = true;
                $scope.$apply();
                return;
            }

            $scope.templateId = true;

            $scope.rowsCount = result.rowsCount;
            $scope.rowsAmount = result.rowsAmount;
            $scope.templateFields = result.templateFields;

            $scope.offset = 0;
            $scope.columnsData = result.columns;
            $scope.rowsData = result.data;
            $scope.totalPages = Math.ceil($scope.rowsCount / 50) + 1;
            $scope.prevButonDisabled = true;
            $scope.nextButonDisabled = false;
            $scope.rowErrors = {};

            $scope.lastSelectedRow = null;
            $scope.lastSelectedColumn = null;

            $scope.tableWidth = window.innerWidth * .985;
            $scope.tableHeight = window.innerHeight - 130;

            $scope.removeRowOnColumnAction = removeRowOnColumnAction;

            var table = document.getElementById('my-hot-table');

            hot = new Handsontable(table, {

                data: $scope.rowsData,

                outsideClickDeselects: false, //you must add this, otherwise getSelected() will return 'undefined'
                columnSorting: true,
                observeChanges: true,
                persistantState: false,
                contextMenu: true,
                readOnly: false,
                sortIndicator: true,
                fillHandle: true,
                autoWrapRow: true,
                stretchH: 'all',
                minSpareRows: 0,
                width: $scope.tableWidth,
                height: $scope.tableHeight,
                minRows: 50,
                maxRows: 50,
                rowHeights: 30,
                colHeaders: true,
                columnHeaderHeight: 40,
                fixedColumnsLeft: 3,
                columns: getHotColumns(),
                contextMenu: ['remove_row'],

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
                beforeKeyDown: beforeKeyDownHandler
            });

            $scope.$apply();

            //Map to save cells with invalid format values
            movedSideWays = false;
        }

        function backAction() {

            $window.location.href = '/' + batchId;
        }

        function prevPageAction() {

            if ($scope.offset > 0) {
                $scope.offset --;
                $scope.nextButonDisabled = false;
                changePageHandler();
            }
        }

        function nextPageAction() {

            $scope.offset ++;

            if ($scope.offset >= $scope.totalPages - 1) {
                $scope.offset = $scope.totalPages - 1;
                $scope.nextButonDisabled = true;
            }

            changePageHandler();
        }

        function removeRowOnColumnAction() {

            var row = hot.getSelected()[0];

            hot.alter('remove_row', row);

            $timeout(function() {
                hot.render();
                updateSummaryData();
            }, 200);
        }

        function changePageHandler() {

            $scope.pageChangeLoader = true;
            BGE_HandsOnGridController.changePageGrid({batchId: batchId, templateFields: $scope.templateFields, offset: $scope.offset}, changePageGridHandler)

            function changePageGridHandler(result, event) {

                $scope.prevButonDisabled = true;
                if ($scope.offset > 0) {
                    $scope.prevButonDisabled = false;
                }

                hot.loadData(result.data);
                $scope.pageChangeLoader = false;

                var totalColumns = hot.countCols();
                var totalRows = hot.countRows();
    
                for (var indexRow = 0; indexRow < totalRows; indexRow++) {
    
                    var cellValue = hot.getDataAtCell(indexRow, hot.propToCol('Id'));
                    if (cellValue == null) {
                        hot.setDataAtCell(indexRow, hot.propToCol('Id'), Date.now().toString(), 'manual');
                    }
                }

                // clean errors when changing pages
                $scope.rowErrors = {};

                $scope.$apply();
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
        function afterOnCellMouseDownHandler(event, coords) {

            if (coords.row < 0) {
                hot.deselectCell();
            }
        }

        function afterInitHandler() {

            // console.warn('HOT - afterInitHandler');

            $scope.isTableLoaded = true;
            $scope.isIndexLoading = true;

            var totalColumns = this.countCols();
            var totalRows = this.countRows();

            for (var indexRow = 0; indexRow < totalRows; indexRow++) {

                var cellValue = this.getDataAtCell(indexRow, this.propToCol('Id'));
                if (cellValue == null) {
                    this.setDataAtCell(indexRow, this.propToCol('Id'), Date.now().toString(), 'manual');
                }
            }

            $scope.isIndexLoading = false;

            renderBindings();
        }

        function beforeRemoveRowHandler(index, amount, visualRows) {

            // console.warn('HOT - beforeRemoveRowHandler');
            deleteRow(index, amount, visualRows);
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

                BGE_HandsOnGridController.deleteRowsGrid(requestData, deleteRowsGridHandler);

                function deleteRowsGridHandler(result, event) {

                    if (callback) {
                        callback();
                    }
                };
            });
        }

        function afterRemoveRowHandler(index, amount) {

            // console.warn('HOT - afterRemoveRowHandler');

            updateSummaryData();
        }

        function beforeChangeHandler(changes, source) {

        }

        function afterChangeHandler(changes, source) {

            // console.warn('HOT - afterChangeHandler', source);

            var sourceOptions = ['edit', 'autofill', 'paste'];

            if (sourceOptions.includes(source) && !$scope.isIndexLoading) {

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

                            for (var index = 0; index < $scope.rowErrors[newCellId].length; index ++) {

                                var element = $scope.rowErrors[newCellId][index];

                                if (element.field === changes[i][1]) {
                                    $scope.rowErrors[newCellId].splice(index, 1);
                                }
                            }

                            newCell.valid = true;
                            newCell.hasError = false;
                        }
                        else if (changes[i][1] !== 'Id' && changes[i][1] !== 'Actions') {

                            var col = this.propToCol(changes[i][1])
                            var cellType = this.getDataType(changes[i][0], hot.propToCol('Id'));


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
                                cellRecords.push(cellRecord);
                            }
                            else if ((newValue == 'NaN') && (cellType == 'date')) {
                                if (!$scope.rowErrors[cellRecord.recordId] || ($scope.rowErrors[cellRecord.recordId] && $scope.rowErrors[cellRecord.recordId].length == 0)) {
                                    $scope.rowErrors[cellRecord.recordId] = [];
                                    $scope.rowErrors[cellRecord.recordId].push({field: cellRecord.field, messages: 'Illegal assignment from String to Date'});
                                }
                                else {

                                    var isFieldIn = false;
                                    $scope.rowErrors[cellRecord.recordId].forEach(function(element){

                                        if (element.field === cellRecord.field) {
                                            element.messages = 'Illegal assignment from String to Date';
                                            isFieldIn = true;
                                        }
                                    });

                                    if (!isFieldIn) {
                                        $scope.rowErrors[cellRecord.recordId].push({field: cellRecord.field, messages: 'Illegal assignment from String to Date'});
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

                    BGE_HandsOnGridController.dmlCellsRowGrid(requestData, onDmlGridHandler);
                }
                else {

                    $timeout(function() {
                        hot.render();
                    }, 500);

                }

                function onDmlGridHandler(result, event) {

                    if (result && result.length > 0) {

                        result.forEach(function(cellResponse) {

                            // console.log(cellResponse);

                            var errCell = hot.getCellMeta(cellResponse.row, hot.propToCol(cellResponse.field));

                            if (cellResponse.errors) {

                                errCell.valid = false;
                                errCell.hasError = true;

                                if (!$scope.rowErrors[cellResponse.recordId] || ($scope.rowErrors[cellResponse.recordId] && $scope.rowErrors[cellResponse.recordId].length == 0)) {
                                    $scope.rowErrors[cellResponse.recordId] = [];
                                    $scope.rowErrors[cellResponse.recordId] = cellResponse.errors;
                                }
                                else {

                                    var isFieldIn = false;
                                    $scope.rowErrors[cellResponse.recordId].forEach(function(element) {

                                        if (element.field === cellResponse.field) {
                                            element.messages = cellResponse.messages
                                            isFieldIn = true;
                                        }
                                    });

                                    if (!isFieldIn) {
                                        $scope.rowErrors[cellResponse.recordId] = $scope.rowErrors[cellResponse.recordId].concat(cellResponse.errors);
                                    }
                                }

                                debugRowErrors = $scope.rowErrors;
                            }
                            else if ($scope.rowErrors[cellResponse.recordId]) {

                                errCell.valid = true;
                                errCell.hasError = false;

                                for (var index = 0; index < $scope.rowErrors[cellResponse.recordId].length; index ++) {

                                    var element = $scope.rowErrors[cellResponse.recordId][index];

                                    if (element.field === cellResponse.field) {
                                        $scope.rowErrors[cellResponse.recordId].splice(index, 1);
                                    }
                                }
                            }


                            if (cellResponse.sfdcid) {
                                // setDataAtCell ALWAYS TRIGGER A FULL TABLE RENDER - USE WITH CARE AND IN BULK WHERE POSSIBLE
                                hot.setDataAtCell(cellResponse.row, hot.propToCol('Id'), cellResponse.sfdcid, 'manual');

                                if (cellResponse.sfdcid !== cellResponse.recordId) {

                                    if ($scope.rowErrors[cellResponse.recordId] && $scope.rowErrors[cellResponse.recordId].length > 0) {
                                        $scope.rowErrors[cellResponse.sfdcid] = $scope.rowErrors[cellResponse.recordId];
                                    }
                                }
                            }

                            $timeout(function() {

                                hot.render();
                                updateSummaryData();
                            }, 200);
                        });
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

            if ($scope.lastSelectedRow === null) {
                $scope.lastSelectedRow = row;
                $scope.lastSelectedColumn = col;
            }

            $scope.lastSelectedColumn = col;
        }

        function afterSelectionEndHandler(row, column, rowEnd, columnEnd) {

            if ((row != $scope.lastSelectedRow)) {

                var recordId = hot.getDataAtRowProp($scope.lastSelectedRow, 'Id');

                BGE_HandsOnGridController.dryRunRowGrid({batchId: batchId, recordId: recordId}, dryRunRowGridHandler);

                function dryRunRowGridHandler(result, event) {

                    $scope.lastSelectedRow = row;
                    $scope.$apply();
                }
            }
        }

        function afterCreateRowHandler(index, amount) {

            if ($scope.isTableLoaded === true) {
                hot.render();
            }
        }

        function beforeKeyDownHandler(event) {

            if (event.keyCode === 9 || event.keyCode === 37 || event.keyCode === 39) {

                var selection = hot.getSelected();

                var rowIndex = selection[0];
                var colIndex = selection[1];
    
                var numberOfColumns = hot.countCols();
                var numberOfRows = hot.countRows();
    
                var lastColumn = numberOfColumns - 1;
                var lastRow = numberOfRows - 1;
    
                var isFirstRow = (rowIndex === 0) ? true : false;


                // Enter shouldn't go into Edit mode on a cell, instead it should move to the next row.
                if (event.keyCode === 13) {

                    event.stopImmediatePropagation();

                    rowIndex ++;

                    hot.selectCell(rowIndex, colIndex);
                }
                if (event.keyCode === 9 || event.keyCode === 39) {

                    // Tab or right arrow was pressed
                    console.log('Tab or right arrow was pressed');
                    try {

                        if (colIndex === 0) {

                            colIndex = 1;
                        }

                        hot.selectCell(rowIndex, colIndex);
                    }
                    catch(err) {

                        console.log(err);
                    }
                }
                else if (event.keyCode === 37) {

                    // Left arrow was pressed
                    console.log('Left arrow or shift + tab was pressed');
                    try {

                        console.log('COLUMN INDEX ', colIndex);
                        if (colIndex === 1) {

                            colIndex = lastColumn;

                            if (isFirstRow) {

                                rowIndex = lastRow;
                            }
                            else {

                                row --;
                            }
                        }

                        hot.selectCell(rowIndex, colIndex);
                    }
                    catch(err) {

                        console.log(err);
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
                    result = 'text';
                    break;

                case 'DATE':
                case 'DATETIME':
                    result = 'date';
                    break;

                case 'CURRENCY':
                case 'NUMBER':
                case 'DECIMAL':
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
            idCol.manualColumnResize = false;
            idCol.disableVisualSelection = true;
            frozenColumns.push(idCol);

            var errorCol = new Object();
            errorCol.title = ' ';
            errorCol.type = 'text';
            errorCol.data = 'Errors';
            errorCol.className = "htCenter htMiddle tooltip-column";
            errorCol.wordWrap = true;
            errorCol.manualColumnResize = false;
            errorCol.colWidths = 30;
            errorCol.disableVisualSelection = true;
            errorCol.renderer = tooltipCellRenderer;
            errorCol.readOnly = true;
            frozenColumns.push(errorCol);

            var actionCol = new Object();
            actionCol.title = 'ACTIONS';
            actionCol.data = 'Actions';
            actionCol.disableVisualSelection = true;
            actionCol.manualColumnResize =  true;
            actionCol.colWidths = 80;
            actionCol.className = "htCenter htMiddle action-cell";
            frozenColumns.push(actionCol);

            for (var i = 0; i < $scope.columnsData.length; i++) {

                var templateField = $scope.columnsData[i];

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
                }
                else if (templateField.type === "CURRENCY") {
                    col.format = '$0,0.00'
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                }
                else if (templateField.type === "DECIMAL") {
                    col.format = '0.00';
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                }
                else if (templateField.type === "NUMBER") {
                    col.format = '0';
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = '<div class="amount-style">' + templateField.label.toUpperCase() + '</div>';
                }
                else if (templateField.type === "EMAIL") {

                }
                if (templateField.type === "PICKLIST") {
                    col.strict = false;

                    // Check if by any change the list containing picklist values are null empty or undefined.
                    if (templateField.picklistValues) {

                         // allowInvalid: false - does not allow manual input of value that does not exist in the source.
                         // In this case, the ENTER key is ignored and the editor field remains opened.
                        col.source = Object.keys(templateField.picklistValues);

                        if (templateField.isRecordType) {
                            $scope.recordTypeMap = templateField.picklistValues;
                        }
                    }
                }

                if (templateField.apiName !== "Id") {
                    resultColumns.push(col);
                }
            }

            return frozenColumns.concat(resultColumns);
        }

        function getColumnIndexByProp(prop){

            if (prop) {

                for (var index = 0; index < $scope.columnsData.length; index ++) {

                    if ($scope.columnsData[index].data && (prop.toLowerCase() === $scope.columnsData[index].data.toLowerCase())) {
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

        function addMessage(cell, errors) {

            removeMessage();
            var messageSection = document.createElement('section');
            messageSection.className = 'slds-popover slds-nubbin_left slds-theme_error tooltip-error';
            messageSection.role = 'dialog'

            var messageSectionDiv = document.createElement('div');
            messageSectionDiv.className = 'slds-popover__body';

            var messageSectionDivList = document.createElement('ul');
            messageSectionDivList.style.listStyleType = 'disc';

            errors.forEach(function(errorElement) {

                var messageSectionDivListElement = document.createElement('li');
                messageSectionDivListElement.innerHTML = errorElement.field + " : " + errorElement.messages;
                messageSectionDivList.appendChild(messageSectionDivListElement);
            })

            messageSectionDiv.appendChild(messageSectionDivList);
            messageSection.appendChild(messageSectionDiv);
            document.body.appendChild(messageSection);

            var popper = new Popper(cell, messageSection, {
                placement: 'top-end'
            });
        }

        function removeMessage() {
            $(".tooltip-error" ).remove();
        }

        function renderBindings() {

            if (window.attachEvent) {
                window.attachEvent('onresize', updateHotTable);
            }
            else {
                window.addEventListener('resize', updateHotTable, true);
            }

            $(".amount-style").parent().css('text-align', 'right');
        }

        function updateSummaryData() {

            BGE_HandsOnGridController.getSummaryData({batchId: batchId}, getSummaryDataHandler)

            function getSummaryDataHandler(result, event) {

                $scope.rowsCount = result.rowsCount;
                $scope.rowsAmount = result.rowsAmount;
                $scope.totalPages = Math.ceil($scope.rowsCount / 50) + 1;

                if ($scope.offset >= $scope.totalPages - 1) {
                    $scope.nextButonDisabled = true;
                }
                else {
                    $scope.nextButonDisabled = false;
                }

                $scope.$apply();
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

        // Renderers

        function actionCellsRenderer(instance, td, row, col, prop, value, cellProperties) {

            var selectElement = getLightningPicklist();

            Handsontable.dom.addEvent(selectElement, 'click', function (e) {
                e.preventDefault(); // prevent selection quirk
            });

            Handsontable.dom.empty(td);
            td.appendChild(selectElement);

            td.className = 'action-cell';

            return td;
        }

        function tooltipCellRenderer(instance, td, row, col, prop, value, cellProperties) {

            Handsontable.renderers.TextRenderer.apply(this, arguments);

            var iconContainer = document.createElement('div');

            var rowId = instance.getDataAtCell(row, instance.propToCol('Id'));
            var rowErrors = $scope.rowErrors[rowId];

            if (rowErrors && rowErrors.length > 0) {
                iconContainer.style.display = 'block';
            }
            else {
                iconContainer.style.display = 'none';
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

                if (rowErrors && rowErrors.length > 0) {
                    iconContainer.style.display = 'block';
                    addMessage(td, rowErrors);
                }
            });

            var iconImage = document.createElement('img');
            iconImage.className = 'tooltip-image';
            iconImage.src = resourcePath + '/icons/warning.png';
            // iconImage.style.width = "60%";
            iconImage.style.cursor = "pointer";

            iconContainer.appendChild(iconImage);
            Handsontable.dom.empty(td);
            td.appendChild(iconContainer);

            td.style.borderBottom = 'none';
            td.style.borderTop = 'none';
            td.style.borderLeft = 'none';
            td.style.background = 'white !important';
            td.className = 'tooltip-cell';

            return td;
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

        function getLightningPicklist() {

            var divControl = document.createElement('div');

            divControl.className = 'slds-dropdown-trigger slds-dropdown-trigger_click picklist-click';

            var divButton = document.createElement('button');
            divButton.className = 'slds-button slds-button_icon slds-button_icon-border-filled';
            divButton.setAttribute('aria-haspopup', 'true');
            divButton.setAttribute('data-jq-dropdown','#jq-dropdown-1');
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

    });

})();

