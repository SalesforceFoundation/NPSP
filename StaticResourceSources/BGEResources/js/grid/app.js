(function () {

    var myApp = angular.module('myApp', ['ngHandsontable', 'ngSanitize']);

    myApp.controller('MainCtrl', function ($scope, $compile, $timeout) {

        var changesToSave = [];

        BGE_HandsOnGridController.initGrid({batchId: batchId}, onInitHandler)

        function onInitHandler(result, event) {

            // console.warn('BGE - onInitHandler');

            $scope.rowsCount = result.rowsCount;
            $scope.rowsAmount = result.rowsAmount;
            $scope.offset = 0;
            $scope.totalPages = Math.ceil(result.rowsCount / 50);
            $scope.columnsData = result.columns;
            $scope.rowsData = result.data;
            $scope.prevButtonEnabled = false;
            $scope.rowErrors = {};

            console.debug(result);

            $scope.lastSelectedRow = null;
            $scope.isTableLoaded = false; // Needed for afterCreateRow:as it fires before afterInit: & confuses all
            $scope.isIndexLoading = false;

            $scope.tableWidth = window.innerWidth * .985;
            $scope.tableHeight = window.innerHeight * .81;

            $scope.nextPageAction = nextPageAction;
            $scope.prevPageAction = prevPageAction;

            // Flag that is set true if the user have just pressed the up arrow key.
            wasUpArrowPressed = false;

            //Map to save cells with invalid format values
            movedSideWays = false;

            wait = false;
            updatedCellsMap = {};

            var changesToSave = {};


            // Flag to prevent a bug when deleting multiple records.
            var deletingRecords = false;

            var dynamicColumns = [];

            var table = document.getElementById('my-hot-table');

            console.log(result.data);

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
                currentRowClassName: 'current-row',
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
                afterRender: afterRenderHandler,
                beforeRemoveRow: beforeRemoveRowHandler,
                afterRemoveRow: afterRemoveRowHandler,
                afterChange: afterChangeHandler,
                afterSelection: afterSelectionHandler,
                afterSelectionEnd: afterSelectionEndHandler,
                afterOnCellMouseDown: afterOnCellMouseDownHandler,
                afterCreateRow: afterCreateRowHandler,
                beforeKeyDown: beforeKeyDownHandler
            });

            $scope.$apply();
        }

        function prevPageAction() {
            console.log("prev");

            if ($scope.offset > 0) {
                $scope.offset --;
                changePageHandler();
            }
        }

        function nextPageAction() {

            $scope.offset ++;
            changePageHandler();
        }

        function changePageHandler() {

            $scope.isTableLoaded = false;

            BGE_HandsOnGridController.changePageGrid({batchId: batchId, offset: $scope.offset}, changePageGridHandler)

            function changePageGridHandler(result, event) {

                $scope.prevButtonEnabled = true;
                if ($scope.offset > 0) {
                    $scope.prevButtonEnabled = false;
                }

                hot.loadData(result.data);
                $scope.isTableLoaded = true;

                $scope.$apply();
            }
        }


        function cellsHandler(row, col, prop) {

            // console.warn('HOT - cellsHandler');

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

                for (var indexCol = 0; indexCol < totalColumns; indexCol++) {

                    var cellType = this.getDataType(indexRow, indexCol);

                    if (cellType === 'date') {

                        cellValue = this.getDataAtCell(indexRow, indexCol);

                        if (cellValue != null) {

                            // get date valie displayed in milliseconds
                            var dateOriginalMilliseconds = new Date(cellValue);

                            // create a new milliseconds date value that match with UTC time (getTimezoneOffset function retrieve value in seconds)
                            var dateUTCMilliseconds = cellValue + ((dateOriginalMilliseconds.getTimezoneOffset() * 60 * 1000));

                            // create new date using UTC milliseconds value
                            var dateUTC = new Date(dateUTCMilliseconds);

                            // format to ISO standard format
                            var dateISOFormatted = dateUTC.toISOString();

                            // set correct data in cell
                            this.setDataAtCell(indexRow, indexCol, dateISOFormatted, 'manual');
                        }
                    }

                }

            }

            $scope.isIndexLoading = false;
            console.log("table ready");

            renderBindings();
        }

        function afterRenderHandler(isForced) {

            console.warn('HOT - afterRenderHandler');
            updateSummaryData();
        }

        function beforeRemoveRowHandler(index, amount, visualRows) {

            console.warn('HOT - beforeRemoveRowHandler');
            deleteRow(index, amount, visualRows);
        }

        function deleteRow(index, amount, visualRows, callback) {

            console.log(index, amount);
            console.log(visualRows);

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

            console.warn('HOT - afterRemoveRowHandler');

            updateSummaryData();
        }

        function afterChangeHandler(changes, source) {

            console.warn('HOT - afterChangeHandler', source);

            var sourceOptions = ['edit', 'autofill', 'paste'];

            if (sourceOptions.includes(source) && !$scope.isIndexLoading) {

                var cellRecords = [];

                for (var i = 0; i < changes.length; i ++) {

                    var cellRecord = {};

                    if (changes[i][1] !== 'Id' && changes[i][1] !== 'Actions') {

                        var col = this.propToCol(changes[i][1])
                        var cellType = this.getDataType(changes[i][0], col);
                        var newValue = changes[i][3];

                        if (cellType == 'date') {
                            newValue = (new Date(newValue)).getTime().toString();
                        }

                        var cellRecord = {
                            row: changes[i][0],
                            field: changes[i][1],
                            oldValue: changes[i][2],
                            newValue: newValue,
                            type: cellType,
                            recordId: this.getDataAtRowProp(changes[i][0], 'Id')
                        };

                        if (cellRecord.newValue && (newValue !== 'NaN') && (cellRecord.oldValue !== cellRecord.newValue)) {
                            cellRecords.push(cellRecord);
                        }
                    }
                    else {
                        updateSummaryData();
                    }
                }

                if (cellRecords.length > 0) {

                    var requestData = {
                        batchId: batchId,
                        cellRecords: JSON.stringify(cellRecords)
                    };

                    console.log(requestData);

                    BGE_HandsOnGridController.dmlCellsGrid(requestData, onDmlGridHandler);
                }

                function onDmlGridHandler(result, event) {

                    console.log(result);

                    if (result && result.length > 0) {

                        result.forEach(function(cellResponse) {

                            console.log(cellResponse);

                            if (cellResponse.sfdcid) {
                                // setDataAtCell ALWAYS TRIGGER A FULL TABLE RENDER - USE WITH CARE AND IN BULK WHERE POSSIBLE
                                hot.setDataAtCell(cellResponse.row, hot.propToCol('Id'), cellResponse.sfdcid, 'manual');
                            }

                            var errCell = hot.getCellMeta(cellResponse.row, hot.propToCol(cellResponse.field));

                            $scope.rowErrors[cellResponse.recordId] = [];

                            if (cellResponse.errors) {

                                errCell.valid = false;
                                errCell.hasError = true;

                                if (!$scope.rowErrors[cellResponse.recordId]) {
                                    $scope.rowErrors[cellResponse.recordId] = [];
                                }

                                $scope.rowErrors[cellResponse.recordId] = cellResponse.errors;

                                debugRowErrors = $scope.rowErrors;
                            }
                            else {

                                errCell.valid = true;
                                errCell.hasError = false;
                            }

                            $timeout(function() {

                                hot.render();
                                updateSummaryData();
                            }, 500);
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
        function afterSelectionHandler(row) {

            if ($scope.lastSelectedRow === null) {
                $scope.lastSelectedRow = row;
            }
        }

        function afterSelectionEndHandler(row, column, rowEnd, columnEnd) {

            if ((row != $scope.lastSelectedRow) && ($scope.hasRowChanged)) {

                var recordId = self.getDataAtRowProp($scope.lastSelectedRow, 'Id');

                BGE_HandsOnGridController.dryRunRowGrid({batchId: batchId, recordId: recordId}, dryRunRowGridHandler);

                function dryRunRowGridHandler(result, event) {

                    console.log(result);

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

            // Enter shouldn't go into Edit mode on a cell, instead it should move to the next row.
            if (event.keyCode === 13) {

                event.stopImmediatePropagation();

                var selection = hot.getSelected();
                var rowIndex = selection[0];
                var colIndex = selection[1];

                rowIndex ++;

                hot.selectCell(rowIndex, colIndex);
            }
            if (event.keyCode === 9 || event.keyCode === 39) {

                // Tab or right arrow was pressed
                movedSideWays = true;

                var selection = hot.getSelected();
                var rowIndex = selection[0];
                var colIndex = selection[1];
                var numerOfColumns = hot.countCols();

                if (colIndex === 0) {

                    colIndex = 1;
                }

                hot.selectCell(rowIndex, colIndex);
            }
            else if (event.keyCode === 37) {

                // Left arrow was pressed
                movedSideWays = true;

                var selection = hot.getSelected();
                var rowIndex = selection[0];
                var colIndex = selection[1];
                var numerOfColumns = hot.countCols();

                if (colIndex === 2) {

                    colIndex = 1;
                }

                hot.selectCell(rowIndex, colIndex);
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
            // actionCol.type = 'text';
            actionCol.data = 'Actions';
            actionCol.disableVisualSelection = true;
            actionCol.manualColumnResize =  true;
            actionCol.colWidths = 80;
            actionCol.className = "htCenter htMiddle";
            // actionCol.renderer = actionCellsRenderer;
            frozenColumns.push(actionCol);

            for (var i = 0; i < $scope.columnsData.length; i++) {

                var templateField = $scope.columnsData[i];

                var col = new Object();
                col.data = templateField.apiName;
                col.required = templateField.required;
                col.title = templateField.label.toUpperCase();
                col.type = getCellDataType(templateField.type);
                col.allowInvalid = true;
                col.wordWrap = false;
                col.colWidths = 200;

                col.className = "htLeft htMiddle slds-truncate";

                if (templateField.type === "DATE") {
                    // col.dateFormat = "YYYY-MM-DD";
                    col.dateFormat = 'MM/DD/YYYY';
                    col.className = "htRight htMiddle slds-truncate custom-date";
                    col.correctFormat = true;
                    col.renderer = dateCellRenderer;
                }
                else if (templateField.type === "CURRENCY") {
                    col.format = '$0,0.00'
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = templateField.label.toUpperCase();
                }
                else if (templateField.type === "DECIMAL") {
                    col.format = '0.00';
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = '<div style="float: right">' + templateField.label.toUpperCase() + '</div>';
                }
                else if (templateField.type === "NUMBER") {
                    col.format = '0';
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = '<div style="float: right">' + templateField.label.toUpperCase() + '</div>';
                }
                else if (templateField.type === "EMAIL") {

                }
                if (templateField.type === "PICKLIST") {

                    // Check if by any change the list containing picklist values are null empty or undefined.
                    if (templateField.picklistValues) {

                         // allowInvalid: false - does not allow manual input of value that does not exist in the source.
                         // In this case, the ENTER key is ignored and the editor field remains opened.
                        col.source = Object.values(templateField.picklistValues);
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

        function addMessage(cell, errors) {

            removeMessage();
            var messageSection = document.createElement('section');
            messageSection.className = 'slds-popover slds-nubbin_left slds-theme_error tooltip-error';
            messageSection.role = 'dialog'

            var messageSectionDiv = document.createElement('div');
            messageSectionDiv.className = 'slds-popover__body';

            var messageSectionDivList = document.createElement('ul');

            errors.forEach(function(errorElement) {

                var messageSectionDivListElement = document.createElement('li');
                messageSectionDivListElement.innerHTML = errorElement.fields.join() + " : " + errorElement.messages.join();
                messageSectionDivList.appendChild(messageSectionDivListElement);
            })

            messageSectionDiv.appendChild(messageSectionDivList);
            messageSection.appendChild(messageSectionDiv);
            document.body.appendChild(messageSection);

            var popper = new Popper(cell, messageSection, {
                placement: 'right'
            });
        }

        function removeMessage() {
            $(".tooltip-error" ).remove();
        }

        function renderBindings() {

            $('.action-items').click(function(event) {

                event.preventDefault();

                var optionSelect = document.createElement('select');
                // messageSection.className = 'slds-popover slds-nubbin_left slds-theme_error tooltip-error';

                var optionSelectOption = document.createElement('option');
                optionSelectOption.value = 'delete row';
                optionSelectOption.innerHTML = 'delete row';

                optionSelect.appendChild(optionSelectOption);

                var popper = new Popper(this, optionSelectOption, {
                    placement: 'right'
                });
            });

            if (window.attachEvent) {
                window.attachEvent('onresize', updateHotTable);
            }
            else {
                window.addEventListener('resize', updateHotTable, true);
            }
        }

        function updateSummaryData() {

            BGE_HandsOnGridController.getSummaryData({batchId: batchId}, getSummaryDataHandler)

            function getSummaryDataHandler(result, event) {

                $scope.rowsCount = result.rowsCount;
                $scope.rowsAmount = result.rowsAmount;
                $scope.$apply();
            }
        }

        function updateHotTable() {

            var newWidth = window.innerWidth * .985;
            var newHeight = window.innerHeight * .81;

            if (hot) {
    
            }
            hot.updateSettings({
                width: newWidth,
                height: newHeight
            });
        }

        // Renderers

        function dateCellRenderer(instance, td, row, col, prop, value, cellProperties) {

            Handsontable.DateCell.renderer.apply(this, arguments);
        }

        function emailCellRenderer(instance, td, row, col, prop, value, cellProperties) {


        }

        function actionCellsRenderer(instance, td, row, col, prop, value, cellProperties) {

            var divElement = document.createElement('div');
            var selectElement = document.createElement('select');
            selectElement.style.width = "90%";
            selectElement.style.marginLeft = "5px";
            selectElement.style.marginRight = "5px";
            var optionElement = document.createElement('option');
            optionElement.setAttribute('label', '');
            optionElement.setAttribute('value', 'None');
            optionElement.setAttribute('selected', 'true');
            selectElement.appendChild(optionElement);
            optionElement = document.createElement('option');
            optionElement.setAttribute('label', 'Remove');
            optionElement.setAttribute('value', 'Remove');
            selectElement.appendChild(optionElement);
            divElement.appendChild(selectElement);

            Handsontable.dom.addEvent(selectElement, 'change', function (e) {
                e.preventDefault(); // prevent selection quirk
                console.log('on change');

                var value = $(selectElement).val();

                if (value === 'Remove') {
                    hot.alter('remove_row', row);
                }
            });

            Handsontable.dom.addEvent(selectElement, 'click', function (e) {
                e.preventDefault(); // prevent selection quirk
                console.log('on click');
            });

            Handsontable.dom.empty(td);
            td.appendChild(divElement);

            return td;
        }

        //To display action column icons
        function actionCellsRendererOld(instance, td, row, col, prop, value, cellProperties) {

            Handsontable.renderers.TextRenderer.apply(this, arguments);

            Handsontable.dom.addEvent(td, 'click', function (e) {
                e.preventDefault(); // prevent selection quirk
            });

            var dataRowId = instance.getDataAtRowProp(row, 'Id');

            var isDisabled = 'disabled=\"false\"';

            var actionsMenu = '';

            if (dataRowId) {
                actionsMenu = '<div class="action-options slds-m-top slds-hide" style="position:absolute;"><div class="slds-popover toggle" style="position:absolute; width: 11em;" role="tooltip"><div class="slds-popover__body" style="padding: 0 !important"><div class="slds-media slds-no-space slds-has-divider_bottom-space slds-media_center"><button class="slds-button slds-button_neutral remove-my-row" style="border: none;">Remove row</button></div></div></div></div>';
            }

            // var actionIcon = '<div>' + actionsMenu + '<button class="slds-button slds-button_icon slds-button_icon-border-filled" onClick="displayActionMenu(' + row + ');"><svg class="slds-icon slds-icon-text-default slds-icon_x-small" aria-hidden="true"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#down" /></svg></button></div>';
            // var actionsMenu = '<div class="action-options slds-m-top slds-hide" style="position:absolute;"><div class="slds-popover toggle" style="position:absolute; width: 11em;" role="tooltip"><div class="slds-popover__body" style="padding: 0 !important"><div class="slds-media slds-no-space slds-has-divider_bottom-space slds-media_center"><button class="slds-button slds-button_neutral" style="border: none;">Remove row</button></div></div></div></div>';
            var actionIcon = '<div class="action-global">' + actionsMenu + '<button class="slds-button slds-button_icon slds-button_icon-border-filled slds-button_icon-x-small action-items" tabindex="-1" title="Actions"><svg class="slds-button__icon slds-button__icon_hint slds-button__icon_small" aria-hidden="true"><use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg><span class="slds-assistive-text">Actions</span></button></div>';

            td.innerHTML = actionIcon;
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

        /// LEGACY Methods

        function getColumnFromName(name) {
            return -1;
        }

        function validateRequiredFields(row, messages, onMass) {

            var cellsMeta = hot.getCellsMeta();
            var col = 0;

            if (!onMass) {
                row = row - 1;
            }

            if (!messages) {
                messages = [];
            } else if (messages.length > 0) {
                // messages.push('\<br\>');
            }

            cellsMeta.forEach(function (cell) {

                var value = hot.getDataAtCell(row, col);

                if (cell && cell.row == row) {

                    // FIRST OF ALL - INIT Validation values
                    // cell.valid = true;

                    if (cell.required && !value) {

                        cell.valid = false;
                        messages.push(cell.data + ' field is required');
                    } else if (cell.hasError) {
                        cell.valid = false;
                    } else if (cell.hasError != undefined && !cell.hasError) {

                        cell.valid = true;
                    }

                    //Get cell errors, for errors of type format (like email) - To outline the cell on red.
                    var indexMap = cell.row + cell.prop;
                    var cellOnMass = updatedCellsMap[indexMap];

                    if (cellOnMass && cellOnMass.hasError) {
                        cell.valid = false;
                    }

                    col++;
                }
            });
            hot.validateCells = hot.render();

            return messages;
        }

        function triggerSave(id, row, lastSelectedRow, self, callback) {

            var dataAtLastSelectedRow = {};

            if (!dataAtLastSelectedRow[id]) {

                dataAtLastSelectedRow[id] = {};
            }

            // LOAD COMPLETE DATA IMPORT ROW AND SEND TO PROCESS
            for (var i = 0; i < dynamicColumns.length; i++) {

                var prop = dynamicColumns[i].data;
                var type = dynamicColumns[i].type;
                var cellValue = self.getDataAtRowProp($scope.lastSelectedRow, prop);

                if (cellValue != undefined) {

                    dataAtLastSelectedRow[id][prop] = cellValue;

                    if (cellValue == '' && type == 'date') {

                        dataAtLastSelectedRow[id][prop] = null;
                    }
                }
            }

            // Get Batch Id from URL
            var pBatchId = getAllUrlParams().batchid;

            console.log('new row');

            var totalColumns = self.countCols();

            var recordCell = self.getCell($scope.lastSelectedRow, totalColumns - 1);

            if (data) {

                Visualforce.remoting.Manager.invokeAction(
                    '{!$RemoteAction.BGE_HandsOnGridController.save}',
                    id,
                    pBatchId,
                    JSON.stringify(dataAtLastSelectedRow),

                    function (result, event) {

                        callback(result, $(recordCell).text());

                        $scope.$apply();
                    }
                );

                Visualforce.remoting.Manager.invokeAction(
                    '{!$RemoteAction.BGE_HandsOnGridController.calculateTotalOfRecords}',
                    pBatchId,
                    function (result) {

                        document.getElementById("totalOfRecords").value = result;
                    });
            }

        }

        function reloadCurrentPageOfTheGrid() {

            var pBatchId = getAllUrlParams().batchid;

            Visualforce.remoting.Manager.invokeAction(
                '{!$RemoteAction.BGE_HandsOnGridController.changePage}',
                pBatchId, offset,
                function (result, event) {

                    hot.loadData(result);
                });
        }

        function calculateTotalPages(pTotalOfRecords) {

            var result = 0;
            var module = pTotalOfRecords % 50;

            if (module >= 0) {

                result = (pTotalOfRecords / 50) + 1;
            } else {

                result = Math.floor(pTotalOfRecords / 50);
            }

            return parseInt(result);
        }

        function triggerDryRunProcess() {

            $('.dryrunbutton').on('click', function () {

                var pBatchId = getAllUrlParams().batchid;

                Visualforce.remoting.Manager.invokeAction(
                    '{!$RemoteAction.BGE_HandsOnGridController.dryRunProcess}',
                    pBatchId,
                    function (result, event) {

                        if (result != null && result.success) {

                            return;
                        }

                        $scope.$apply();
                    }
                );
            });
        }

        function triggerDeleteAll() {

            $('.deletebutton').on('click', function () {

                var selection = hot.getSelected();

                if (selection != undefined) {

                    var r = confirm("Delete record?");

                    if (r == true) {

                        // Set the flag on true so the "before remove" event does not fire the individual remove function hence showing an exception error.
                        deletingRecords = true;

                        var start = selection[0];
                        var end = selection[2];
                        var gridData = hot.getData();
                        var batchIds = [];

                        if (start <= end) {

                            for (var r = start; r <= end; r++) {

                                var row = gridData[r];
                                var dataRowId = row[getColumnFromName('Id')];

                                batchIds.push(dataRowId);
                            }
                        } else {

                            for (i = -start; i <= -end; i++) {

                                var row = gridData[-i];
                                var dataRowId = row[getColumnFromName('Id')];
                                batchIds.push(dataRowId);
                            }
                        }


                        Visualforce.remoting.Manager.invokeAction(
                            '{!$RemoteAction.BGE_HandsOnGridController.deleteAll}',
                            batchIds,
                            function (result, event) {

                                $scope.$apply();
                            }
                        );


                        if (start <= end) {

                            // If selection starts from the first row.
                            if (gridData[start - 1] !== null && gridData[end + 1]) {

                                hot.alter('remove_row', start, end);
                            } else {

                                hot.alter('remove_row', start, end + 1);
                            }
                        } else {

                            hot.alter('remove_row', end, start + 1);
                        }

                        hot.deselectCell();

                        // Set the flag back on false so we can continue deleting records individualy.
                        deletingRecords = false;
                    } else {

                        return false;
                    }
                } else {

                    alert("please select cell first");
                }
            });
        }

        function displayActionMenu(row) {

            if ($('#' + row + 'menu').hasClass('slds-hide')) {

                $('.is-displayed').addClass("slds-hide");
                $('.is-displayed').removeClass("is-displayed");
                $('#' + row + 'menu').removeClass("slds-hide");
                $('#' + row + 'menu').addClass("is-displayed");

            } else {
                $('#' + row + 'menu').addClass("slds-hide");
            }
        }

    });

})();

