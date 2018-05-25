(function () {

    var myApp = angular.module('myApp', ['ngHandsontable', 'ngSanitize']);

    myApp.controller('MainCtrl', function ($scope, $compile, $timeout, $window) {

        $scope.nextPageAction = nextPageAction;
        $scope.prevPageAction = prevPageAction;
        $scope.backAction = backAction;

        var changesToSave = [];

        BGE_HandsOnGridController.initGrid({batchId: batchId}, onInitHandler);

        function onInitHandler(result, event) {

            // console.warn('BGE - onInitHandler');

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

            $scope.offset = 0;
            $scope.columnsData = result.columns;
            $scope.rowsData = result.data;
            $scope.totalPages = Math.ceil($scope.rowsCount / 50) + 1;
            $scope.prevButonDisabled = true;
            $scope.nextButonDisabled = false;
            $scope.rowErrors = {};

            console.debug(result);

            $scope.lastSelectedRow = null;

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
        }

        function backAction() {

            $window.location.href = '/' + batchId;
        }

        function prevPageAction() {
            console.log("prev");

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

            console.log('removeRowOnColumnAction', row);

            hot.alter('remove_row', row);

            $timeout(function() {
                hot.render();
                updateSummaryData();
            }, 200);
        }

        function changePageHandler() {

            $scope.pageChangeLoader = true;
            BGE_HandsOnGridController.changePageGrid({batchId: batchId, offset: $scope.offset}, changePageGridHandler)

            function changePageGridHandler(result, event) {

                $scope.prevButonDisabled = true;
                if ($scope.offset > 0) {
                    $scope.prevButonDisabled = false;
                }

                hot.loadData(result.data);
                $scope.pageChangeLoader = false;
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

            console.warn('HOT - afterInitHandler');

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
            console.log("table ready");

            renderBindings();
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
            console.warn('SOURCE OPTIONS:    ', sourceOptions);
            console.warn('INDEX IS LOADING   ', $scope.isIndexLoading);
            console.warn('CHANGES:    ', changes);
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
                        else if ((newValue == 'NaN') && (cellType == 'date')) {

                            if (!$scope.rowErrors[cellRecord.recordId] || ($scope.rowErrors[cellRecord.recordId] && $scope.rowErrors[cellRecord.recordId].length == 0)) {
                                $scope.rowErrors[cellRecord.recordId] = [];
                                $scope.rowErrors[cellRecord.recordId].push({field: cellRecord.field, messages: 'Illegal assignment from String to Date'});
                            }
                            else {

                                var isFieldIn = false;
                                $scope.rowErrors[cellRecord.recordId].forEach(function(element){

                                    console.log(element.field, cellRecord.field)
                                    if (element.field === cellRecord.field) {
                                        element.messages = 'Illegal assignment from String to Date';
                                        isFieldIn = true;
                                    }
                                });

                                if (!isFieldIn) {
                                    $scope.rowErrors[cellRecord.recordId].push({field: cellRecord.field, messages: 'Illegal assignment from String to Date'});
                                }
                            }

                            $timeout(function() {
                                hot.render();
                            }, 500);
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

                            var errCell = hot.getCellMeta(cellResponse.row, hot.propToCol(cellResponse.field));

                            // $scope.rowErrors[cellResponse.recordId] = [];

                            if (cellResponse.errors) {

                                console.log(cellResponse.errors);

                                errCell.valid = false;
                                errCell.hasError = true;

                                if (!$scope.rowErrors[cellResponse.recordId] || ($scope.rowErrors[cellResponse.recordId] && $scope.rowErrors[cellResponse.recordId].length == 0)) {
                                    $scope.rowErrors[cellResponse.recordId] = [];
                                    $scope.rowErrors[cellResponse.recordId] = cellResponse.errors;
                                }
                                else {

                                    var isFieldIn = false;
                                    $scope.rowErrors[cellResponse.recordId].forEach(function(element){

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
            }

            if (col < 3) {
                hot.selectCell(row, 3);
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
                col.title = templateField.label.toUpperCase();
                col.type = getCellDataType(templateField.type);
                col.allowInvalid = true;
                col.wordWrap = false;
                col.colWidths = 200;

                col.className = "htLeft htMiddle slds-truncate";

                if (templateField.type === "DATE") {
                    // col.dateFormat = "YYYY-MM-DD";
                    col.dateFormat = 'MM/DD/YYYY';
                    col.className = "htLeft htMiddle slds-truncate custom-date";
                    col.correctFormat = true;
                    col.renderer = dateCellRenderer;
                }
                else if (templateField.type === "CURRENCY") {
                    col.format = '$0,0.00'
                    col.className = "htRight htMiddle slds-truncate";
                    col.title = '<div style="float: right">' + templateField.label.toUpperCase() + '</div>';
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

            // $('.action-items').click(function(event) {

            //     event.preventDefault();

            //     var optionSelect = document.createElement('select');
            //     // messageSection.className = 'slds-popover slds-nubbin_left slds-theme_error tooltip-error';

            //     var optionSelectOption = document.createElement('option');
            //     optionSelectOption.value = 'delete row';
            //     optionSelectOption.innerHTML = 'delete row';

            //     optionSelect.appendChild(optionSelectOption);

            //     $scope.selectPopper = new Popper(this, optionSelectOption, {
            //         placement: 'right'
            //     });
            // });

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

        function dateCellRenderer(instance, td, row, col, prop, value, cellProperties) {

            if (value && value !== null) {

                var formattedDate =  new Date(parseFloat(value));
                value = formattedDate.getMonth() + '/' + formattedDate.getDate() + '/' + formattedDate.getFullYear();
            }

            Handsontable.DateCell.renderer.apply(this, arguments);

            return td;
        }

        function emailCellRenderer(instance, td, row, col, prop, value, cellProperties) {


        }

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

        //To display action column icons
        function actionCellsRendererOld(instance, td, row, col, prop, value, cellProperties) {

            // Handsontable.renderers.TextRenderer.apply(this, arguments);

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

