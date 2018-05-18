(function () {

    var myApp = angular.module('myApp', ['ngHandsontable', 'ngSanitize']);

    myApp.controller('MainCtrl', function ($scope, $compile) {

        var changesToSave = [];

        BGE_HandsOnGridController.initGrid({batchId: batchId}, onInitHandler)

        function onInitHandler(result, event) {

            console.warn('BGE - onInitHandler');

            $scope.rowsCount = result.rowsCount;
            $scope.rowsAmount = result.rowsAmount;
            $scope.totalPages = result.rowsCount / 50;
            $scope.columnsData = result.columns;
            $scope.rowErrors = {};

            console.debug(result);

            $scope.lastSelectedRow = null;
            $scope.isTableLoaded = false; // Needed for afterCreateRow:as it fires before afterInit: & confuses all
            $scope.isIndexLoading = false;

            $scope.tableWidth = window.innerWidth * 91 / 100;
            $scope.tableHeight = window.innerHeight * 70 /100;


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

                data: result.data,

                outsideClickDeselects: false, //you must add this, otherwise getSelected() will return 'undefined'
                columnSorting: true,
                observeChanges: true,
                persistantState: false,
                contextMenu: true,
                manualColumnResize: true,
                manualRowResize: true,
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
                manualColumnResize: [50],
                colWidths: 150,
                rowHeights: 30,
                colHeaders: true,
                columnHeaderHeight: 40,
                fixedColumnsLeft: 2,
                columns: getHotColumns(),
    
                hiddenColumns: {
                    indicators: false
                },

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
                    console.log(indexRow, this.propToCol('Id'));
                    this.setDataAtCell(indexRow, this.propToCol('Id'), Date.now().toString());
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
                            this.setDataAtCell(indexRow, indexCol, dateISOFormatted);
                        }
                    }

                }

            }

            $scope.isIndexLoading = false;
            console.log("table ready");
        }

        function beforeRemoveRowHandler(index, amount) {

            if (!deletingRecords) {

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

                        hot.alter('remove_row');
                        hot.deselectCell();

                        // Set the flag back on false so we can continue deleting records individualy.
                        deletingRecords = false;
                    } else {

                        return false;
                    }
                } else {

                    alert("please select cell first");
                }
            }
        }

        function afterRemoveRowHandler(index, amount) {

            var pBatchId = getAllUrlParams().batchid;
            totalOfRecords = 0;

            Visualforce.remoting.Manager.invokeAction(
                '{!$RemoteAction.BGE_HandsOnGridController.calculateTotalOfRecords}',
                pBatchId,
                function (result) {

                    document.getElementById("totalOfRecords").value = result;
                    totalOfRecords = parseInt(result);

                    $scope.totalPages = calculateTotalPages(totalOfRecords);
                    $scope.$apply();
                });

            Visualforce.remoting.Manager.invokeAction(
                '{!$RemoteAction.BGE_HandsOnGridController.calculateTotalAmount}',
                pBatchId,
                function (result) {

                    document.getElementById("totalAmount").value = result;
                });

            reloadCurrentPageOfTheGrid();
        }

        function afterChangeHandler(changes, source) {

            console.warn('HOT - afterChangeHandler', source);

            if (source === 'edit' && !$scope.isIndexLoading) {

                var cellRecords = [];

                for (var i = 0; i < changes.length; i ++) {

                    if (changes[i][1] !== 'Id') {

                        var cellRecord = {
                            row: changes[i][0],
                            field: changes[i][1],
                            oldValue: changes[i][2],
                            newValue: changes[i][3],
                            recordId: this.getDataAtRowProp(changes[i][0], 'Id')
                        };

                        cellRecords.push(cellRecord);
                    }
                }

                var requestData = {
                    batchId: batchId,
                    cellRecords: JSON.stringify(cellRecords)
                };

                console.log(requestData);

                BGE_HandsOnGridController.dmlCellsGrid(requestData, onDmlGridHandler);

                function onDmlGridHandler(result, event) {
                    console.log(result);

                    if (result && result.length > 0) {

                        result.forEach(function(cellResponse) {

                            console.log(cellResponse);

                            if (cellResponse.errors) {

                                var errCell = hot.getCellMeta(cellResponse.row, hot.propToCol(cellResponse.field));

                                errCell.valid = false;
                                errCell.hasError = true;

                                if (!$scope.rowErrors[cellResponse.recordId]) {
                                    $scope.rowErrors[cellResponse.recordId] = [];
                                }
                                $scope.rowErrors[cellResponse.recordId] = cellResponse.errors;

                                debugRowErrors = $scope.rowErrors;
                            }

                            if (cellResponse.sfdcid) {
                                // setDataAtCell ALWAYS TRIGGER A FULL TABLE RENDER - USE WITH CARE AND IN BULK WHERE POSSIBLE
                                setTimeout(function() {
                                    hot.setDataAtCell(cellResponse.row, hot.propToCol('Id'), cellResponse.sfdcid);
                                }, 500);
                            }
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

        function afterSelectionEndHandler(row, column, rowEnd, columnEnd) {

            var timeout = 0;
            var self = this;

            if (wait) {

                timeout = 450;
            }

            setTimeout(function () {

                wait = false;

                var dataRowId = self.getDataAtRowProp($scope.lastSelectedRow, 'Id');

                var dataAtRow = self.getDataAtRow($scope.lastSelectedRow);


                if ($scope.lastSelectedRow !== null && $scope.lastSelectedRow !== row) {

                    if (changesToSave[dataRowId]) {

                        if (wasUpArrowPressed) {

                            row = row + 2;
                            wasUpArrowPressed = false;
                        }

                        console.log(row);
                        console.log($scope.lastSelectedRow);

                        triggerSave(dataRowId, row, $scope.lastSelectedRow, self, function (result, indexId) {

                            if (!dataRowId) {

                                self.setDataAtCell(row - 1, getColumnFromName('Id'), result.dataImportIds[0]);

                                dataRowId = result.dataImportIds[0];
                            }

                            var messages = validateRequiredFields(row, result.messages, false);

                            if (messages && messages.length > 0) {

                                // Add tooltip message
                                var escaped = addTooltip(dataRowId, row, result, messages);
                                console.log('es aca');
                                data[$scope.lastSelectedRow]['Errors'] = escaped;

                                console.warn('processing errors on "afterselection" ends');
                                if (!rowErrors[indexId]) {
                                    rowErrors[indexId] = [];
                                }

                                rowErrors[indexId] = rowErrors[indexId].concat(messages);
                                $('#' + indexId).find('div').show();
                            } else {

                                data[$scope.lastSelectedRow]['Errors'] = '';
                            }

                            var cellsToUpdate = [];

                            cellsToUpdate = [
                                [row - 1, getColumnFromName('Name'), result.name],
                                [row - 1, getColumnFromName('FailureInformation__c'), result.failureInformation],
                                [row - 1, getColumnFromName('Account1ImportStatus__c'), result.account1ImportStatus],
                                [row - 1, getColumnFromName('Account1Imported__c'), result.account1Imported],
                                [row - 1, getColumnFromName('Account2ImportStatus__c'), result.account2ImportStatus],
                                [row - 1, getColumnFromName('Account2Imported__c'), result.account2Imported],
                                [row - 1, getColumnFromName('Campaign_Member_Status__c'), result.campaignMemberStatus],
                                [row - 1, getColumnFromName('Contact1Imported__c'), result.contact1Imported],
                                [row - 1, getColumnFromName('Contact1ImportStatus__c'), result.contact1ImportStatus],
                                [row - 1, getColumnFromName('Contact2ImportStatus__c'), result.contact2ImportStatus],
                                [row - 1, getColumnFromName('Contact2Imported__c'), result.contact2Imported],
                                [row - 1, getColumnFromName('HomeAddressImportStatus__c'), result.homeAddressImportStatus],
                                [row - 1, getColumnFromName('HomeAddressImported__c'), result.homeAddressImported],
                                [row - 1, getColumnFromName('HouseholdAccountImported__c'), result.householdAccountImported],
                                [row - 1, getColumnFromName('HouseholdAccountImported__c'), result.householdAccountImported],
                                [row - 1, getColumnFromName('ImportedDate__c'), result.importedDate],
                                [row - 1, getColumnFromName('DonationImportStatus__c'), result.donationImportStatus],
                                [row - 1, getColumnFromName('DonationImported__c'), result.donationImported],
                                [row - 1, getColumnFromName('PaymentImportStatus__c'), result.paymentImportStatus],
                                [row - 1, getColumnFromName('PaymentImported__c'), result.paymentImported],
                                [row - 1, getColumnFromName('Status__c'), result.status]
                            ];

                            self.setDataAtCell(cellsToUpdate);

                            changesToSave = {};

                            // Inside a callback
                            $scope.lastSelectedRow = row;
                        });

                        changesToSave = {};
                    }
                }

            }, timeout);

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
        }

        Handsontable.Dom.addEvent(document.body, 'keydown', function (e) {

            if (e.keyCode === 9 || e.keyCode === 39) {

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
            } else if (e.keyCode === 37) {

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
        });

        /// Auxiliary Methods

        function getHotColumns() {

            var resultColumns = [];

            var errorCol = new Object();
            errorCol.title = ' ';
            errorCol.type = 'text';
            errorCol.data = 'Errors';
            errorCol.className = "htCenter htMiddle tooltip-column";
            errorCol.wordWrap = true;
            errorCol.disableVisualSelection = true;
            errorCol.renderer = tooltipCellRenderer;

            resultColumns.push(errorCol);

            var actionCol = new Object();
            actionCol.title = 'ACTIONS';
            actionCol.type = 'text';
            actionCol.data = 'Actions';
            actionCol.colWidths = 80;
            actionCol.className = "htCenter htMiddle";
            actionCol.renderer = actionCellsRenderer;

            resultColumns.push(actionCol);

            var recordIdCol = undefined;

            for (var i=0; i < $scope.columnsData.length; i++) {

                var col = new Object();
                var templateField = $scope.columnsData[i];

                col.data = templateField.apiName;

                if (templateField.required) {

                    col.required = true;
                }

                col.title = '<span>' + templateField.name.toUpperCase() + '</span>';
                col.type = templateField.type;

                // Enable type checking. If for example the user places text in a numeric column, mark the cell as red
                col.allowInvalid = true;

                // Center the content of the columns
                col.className = "htCenter htMiddle slds-truncate";

                // Do not wrap the content of the column
                col.wordWrap = false;

                if (templateField.apiName == "Id") {

                    col.readOnly = true;
                    col.hidden = true;
                    col.className = "htCenter htMiddle slds-truncate slds-hide";
                    col.disableVisualSelection = true;
                    recordIdCol = col;
                }

                if (templateField.type === "date") {

                    col.dateFormat = "YYYY-MM-DD";
                    col.correctFormat = true;
                    col.defaultDate = "today";
                }

                if (templateField.isDecimal === "true") {

                    col.format = '$0,0.00';
                    col.className = "htRight htMiddle";
                    col.title = '<span style="float: right">' + templateField.name.toUpperCase() + '</span>';
                }

                if (templateField.type === "email") {

                    col.type = 'text';
                }

                if (templateField.type === "text") {

                    col.className = "htLeft htMiddle";
                }

                // if (templateField.type === "dropdown") {

                //     // Check if by any change the list containing picklist values are null empty or undefined.
                //     if (templateField.pickListValuesList) {

                //          // allowInvalid: false - does not allow manual input of value that does not exist in the source.
                //          // In this case, the ENTER key is ignored and the editor field remains opened.
                //         col.allowInvalid = false;

                //         col.source = templateField.pickListValuesList;
                //     }
                // }


                if (templateField.apiName !== "Id") {

                    resultColumns.push(col);
                }

            }

            // Add Id column to the end
            resultColumns.push(recordIdCol);

            return resultColumns;
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

            var popupId = Date.now().toString();

            var messageSection = document.createElement('section');
            messageSection.id = popupId;
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
            messageSection.appendChild(messageSectionDivList);

            // cell.appendChild(messageSection);
            typpy(cell, {html: '#' + popupId});
        }

        function removeMessage() {

            $(".tooltip-error" ).remove();
        }

        // Renderers


        function tooltipCellRenderer(instance, td, row, col, prop, value, cellProperties) {

            var iconContainer = document.createElement('div');

            var rowId = instance.getDataAtCell(row, instance.propToCol('Id'));
            var rowErrors = $scope.rowErrors[rowId];

            console.log(rowId);
            console.log(rowErrors);

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
                // removeMessage();
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
            iconImage.style.width = "60%";
            iconImage.style.cursor = "pointer";

            iconContainer.appendChild(iconImage);
            Handsontable.dom.empty(td);
            td.appendChild(iconContainer);

            td.style.borderBottom = 'none';
            td.style.borderTop = 'none';
            td.style.borderLeft = 'none';
            td.style.background = 'white !important';
            td.className = 'tooltip-cell';
            td.id = row + col + Date.now();

            return td;
        }




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

        //To display action column icons
        function actionCellsRenderer(instance, td, row, col, prop, value, cellProperties) {

            Handsontable.TextCell.renderer.apply(this, arguments);

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

        function cellsRenderer(instance, td, row, col, prop, value, cellProperties) {

            try {

                Handsontable.TextCell.renderer.apply(this, arguments);

                if (col == 0) {

                    var dataRowId = instance.getDataAtRowProp(row, 'Id');
                    td.id = dataRowId;

                    if (dataRowId) {

                        $('#' + dataRowId).css( "border-top", "none");
                        $('#' + dataRowId).css( "border-bottom", "none");
                        $('#' + dataRowId).attr( "readonly", "readonly");
                    }

                    var escaped = Handsontable.helper.stringify(value);
                    td.innerHTML = escaped;
                    return td;
                }
            }
            catch(ex) {
                console.warn('Catching text exception');
            }
        }




    });





})();

