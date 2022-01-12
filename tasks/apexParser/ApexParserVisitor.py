# Generated from ApexParser.g4 by ANTLR 4.9
from antlr4 import *
if __name__ is not None and "." in __name__:
    from .ApexParser import ApexParser
else:
    from ApexParser import ApexParser

# This class defines a complete generic visitor for a parse tree produced by ApexParser.

class ApexParserVisitor(ParseTreeVisitor):

    # Visit a parse tree produced by ApexParser#triggerUnit.
    def visitTriggerUnit(self, ctx:ApexParser.TriggerUnitContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#triggerCase.
    def visitTriggerCase(self, ctx:ApexParser.TriggerCaseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#compilationUnit.
    def visitCompilationUnit(self, ctx:ApexParser.CompilationUnitContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeDeclaration.
    def visitTypeDeclaration(self, ctx:ApexParser.TypeDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#classDeclaration.
    def visitClassDeclaration(self, ctx:ApexParser.ClassDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#enumDeclaration.
    def visitEnumDeclaration(self, ctx:ApexParser.EnumDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#enumConstants.
    def visitEnumConstants(self, ctx:ApexParser.EnumConstantsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#interfaceDeclaration.
    def visitInterfaceDeclaration(self, ctx:ApexParser.InterfaceDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeList.
    def visitTypeList(self, ctx:ApexParser.TypeListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#classBody.
    def visitClassBody(self, ctx:ApexParser.ClassBodyContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#interfaceBody.
    def visitInterfaceBody(self, ctx:ApexParser.InterfaceBodyContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#classBodyDeclaration.
    def visitClassBodyDeclaration(self, ctx:ApexParser.ClassBodyDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#modifier.
    def visitModifier(self, ctx:ApexParser.ModifierContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#memberDeclaration.
    def visitMemberDeclaration(self, ctx:ApexParser.MemberDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#methodDeclaration.
    def visitMethodDeclaration(self, ctx:ApexParser.MethodDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#constructorDeclaration.
    def visitConstructorDeclaration(self, ctx:ApexParser.ConstructorDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldDeclaration.
    def visitFieldDeclaration(self, ctx:ApexParser.FieldDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#propertyDeclaration.
    def visitPropertyDeclaration(self, ctx:ApexParser.PropertyDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#interfaceMethodDeclaration.
    def visitInterfaceMethodDeclaration(self, ctx:ApexParser.InterfaceMethodDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#variableDeclarators.
    def visitVariableDeclarators(self, ctx:ApexParser.VariableDeclaratorsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#variableDeclarator.
    def visitVariableDeclarator(self, ctx:ApexParser.VariableDeclaratorContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arrayInitializer.
    def visitArrayInitializer(self, ctx:ApexParser.ArrayInitializerContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeRef.
    def visitTypeRef(self, ctx:ApexParser.TypeRefContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arraySubscripts.
    def visitArraySubscripts(self, ctx:ApexParser.ArraySubscriptsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeName.
    def visitTypeName(self, ctx:ApexParser.TypeNameContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeArguments.
    def visitTypeArguments(self, ctx:ApexParser.TypeArgumentsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#formalParameters.
    def visitFormalParameters(self, ctx:ApexParser.FormalParametersContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#formalParameterList.
    def visitFormalParameterList(self, ctx:ApexParser.FormalParameterListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#formalParameter.
    def visitFormalParameter(self, ctx:ApexParser.FormalParameterContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#qualifiedName.
    def visitQualifiedName(self, ctx:ApexParser.QualifiedNameContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#literal.
    def visitLiteral(self, ctx:ApexParser.LiteralContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#annotation.
    def visitAnnotation(self, ctx:ApexParser.AnnotationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#elementValuePairs.
    def visitElementValuePairs(self, ctx:ApexParser.ElementValuePairsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#elementValuePair.
    def visitElementValuePair(self, ctx:ApexParser.ElementValuePairContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#elementValue.
    def visitElementValue(self, ctx:ApexParser.ElementValueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#elementValueArrayInitializer.
    def visitElementValueArrayInitializer(self, ctx:ApexParser.ElementValueArrayInitializerContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#block.
    def visitBlock(self, ctx:ApexParser.BlockContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#localVariableDeclarationStatement.
    def visitLocalVariableDeclarationStatement(self, ctx:ApexParser.LocalVariableDeclarationStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#localVariableDeclaration.
    def visitLocalVariableDeclaration(self, ctx:ApexParser.LocalVariableDeclarationContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#statement.
    def visitStatement(self, ctx:ApexParser.StatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#ifStatement.
    def visitIfStatement(self, ctx:ApexParser.IfStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#switchStatement.
    def visitSwitchStatement(self, ctx:ApexParser.SwitchStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#whenControl.
    def visitWhenControl(self, ctx:ApexParser.WhenControlContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#whenValue.
    def visitWhenValue(self, ctx:ApexParser.WhenValueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#whenLiteral.
    def visitWhenLiteral(self, ctx:ApexParser.WhenLiteralContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#forStatement.
    def visitForStatement(self, ctx:ApexParser.ForStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#whileStatement.
    def visitWhileStatement(self, ctx:ApexParser.WhileStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#doWhileStatement.
    def visitDoWhileStatement(self, ctx:ApexParser.DoWhileStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#tryStatement.
    def visitTryStatement(self, ctx:ApexParser.TryStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#returnStatement.
    def visitReturnStatement(self, ctx:ApexParser.ReturnStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#throwStatement.
    def visitThrowStatement(self, ctx:ApexParser.ThrowStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#breakStatement.
    def visitBreakStatement(self, ctx:ApexParser.BreakStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#continueStatement.
    def visitContinueStatement(self, ctx:ApexParser.ContinueStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#insertStatement.
    def visitInsertStatement(self, ctx:ApexParser.InsertStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#updateStatement.
    def visitUpdateStatement(self, ctx:ApexParser.UpdateStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#deleteStatement.
    def visitDeleteStatement(self, ctx:ApexParser.DeleteStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#undeleteStatement.
    def visitUndeleteStatement(self, ctx:ApexParser.UndeleteStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#upsertStatement.
    def visitUpsertStatement(self, ctx:ApexParser.UpsertStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#mergeStatement.
    def visitMergeStatement(self, ctx:ApexParser.MergeStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#runAsStatement.
    def visitRunAsStatement(self, ctx:ApexParser.RunAsStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#expressionStatement.
    def visitExpressionStatement(self, ctx:ApexParser.ExpressionStatementContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#propertyBlock.
    def visitPropertyBlock(self, ctx:ApexParser.PropertyBlockContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#getter.
    def visitGetter(self, ctx:ApexParser.GetterContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#setter.
    def visitSetter(self, ctx:ApexParser.SetterContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#catchClause.
    def visitCatchClause(self, ctx:ApexParser.CatchClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#finallyBlock.
    def visitFinallyBlock(self, ctx:ApexParser.FinallyBlockContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#forControl.
    def visitForControl(self, ctx:ApexParser.ForControlContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#forInit.
    def visitForInit(self, ctx:ApexParser.ForInitContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#enhancedForControl.
    def visitEnhancedForControl(self, ctx:ApexParser.EnhancedForControlContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#forUpdate.
    def visitForUpdate(self, ctx:ApexParser.ForUpdateContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#parExpression.
    def visitParExpression(self, ctx:ApexParser.ParExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#expressionList.
    def visitExpressionList(self, ctx:ApexParser.ExpressionListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#primaryExpression.
    def visitPrimaryExpression(self, ctx:ApexParser.PrimaryExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arth1Expression.
    def visitArth1Expression(self, ctx:ApexParser.Arth1ExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#dotExpression.
    def visitDotExpression(self, ctx:ApexParser.DotExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#bitOrExpression.
    def visitBitOrExpression(self, ctx:ApexParser.BitOrExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arrayExpression.
    def visitArrayExpression(self, ctx:ApexParser.ArrayExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#newExpression.
    def visitNewExpression(self, ctx:ApexParser.NewExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#assignExpression.
    def visitAssignExpression(self, ctx:ApexParser.AssignExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#methodCallExpression.
    def visitMethodCallExpression(self, ctx:ApexParser.MethodCallExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#bitNotExpression.
    def visitBitNotExpression(self, ctx:ApexParser.BitNotExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arth2Expression.
    def visitArth2Expression(self, ctx:ApexParser.Arth2ExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#logAndExpression.
    def visitLogAndExpression(self, ctx:ApexParser.LogAndExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#castExpression.
    def visitCastExpression(self, ctx:ApexParser.CastExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#bitAndExpression.
    def visitBitAndExpression(self, ctx:ApexParser.BitAndExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#cmpExpression.
    def visitCmpExpression(self, ctx:ApexParser.CmpExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#bitExpression.
    def visitBitExpression(self, ctx:ApexParser.BitExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#logOrExpression.
    def visitLogOrExpression(self, ctx:ApexParser.LogOrExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#condExpression.
    def visitCondExpression(self, ctx:ApexParser.CondExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#equalityExpression.
    def visitEqualityExpression(self, ctx:ApexParser.EqualityExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#postOpExpression.
    def visitPostOpExpression(self, ctx:ApexParser.PostOpExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#negExpression.
    def visitNegExpression(self, ctx:ApexParser.NegExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#preOpExpression.
    def visitPreOpExpression(self, ctx:ApexParser.PreOpExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#subExpression.
    def visitSubExpression(self, ctx:ApexParser.SubExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#instanceOfExpression.
    def visitInstanceOfExpression(self, ctx:ApexParser.InstanceOfExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#thisPrimary.
    def visitThisPrimary(self, ctx:ApexParser.ThisPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#superPrimary.
    def visitSuperPrimary(self, ctx:ApexParser.SuperPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#literalPrimary.
    def visitLiteralPrimary(self, ctx:ApexParser.LiteralPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeRefPrimary.
    def visitTypeRefPrimary(self, ctx:ApexParser.TypeRefPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#idPrimary.
    def visitIdPrimary(self, ctx:ApexParser.IdPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soqlPrimary.
    def visitSoqlPrimary(self, ctx:ApexParser.SoqlPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soslPrimary.
    def visitSoslPrimary(self, ctx:ApexParser.SoslPrimaryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#methodCall.
    def visitMethodCall(self, ctx:ApexParser.MethodCallContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#dotMethodCall.
    def visitDotMethodCall(self, ctx:ApexParser.DotMethodCallContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#creator.
    def visitCreator(self, ctx:ApexParser.CreatorContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#createdName.
    def visitCreatedName(self, ctx:ApexParser.CreatedNameContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#idCreatedNamePair.
    def visitIdCreatedNamePair(self, ctx:ApexParser.IdCreatedNamePairContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#noRest.
    def visitNoRest(self, ctx:ApexParser.NoRestContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#classCreatorRest.
    def visitClassCreatorRest(self, ctx:ApexParser.ClassCreatorRestContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arrayCreatorRest.
    def visitArrayCreatorRest(self, ctx:ApexParser.ArrayCreatorRestContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#mapCreatorRest.
    def visitMapCreatorRest(self, ctx:ApexParser.MapCreatorRestContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#mapCreatorRestPair.
    def visitMapCreatorRestPair(self, ctx:ApexParser.MapCreatorRestPairContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#setCreatorRest.
    def visitSetCreatorRest(self, ctx:ApexParser.SetCreatorRestContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#arguments.
    def visitArguments(self, ctx:ApexParser.ArgumentsContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soqlLiteral.
    def visitSoqlLiteral(self, ctx:ApexParser.SoqlLiteralContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#query.
    def visitQuery(self, ctx:ApexParser.QueryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#subQuery.
    def visitSubQuery(self, ctx:ApexParser.SubQueryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#selectList.
    def visitSelectList(self, ctx:ApexParser.SelectListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#selectEntry.
    def visitSelectEntry(self, ctx:ApexParser.SelectEntryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldName.
    def visitFieldName(self, ctx:ApexParser.FieldNameContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fromNameList.
    def visitFromNameList(self, ctx:ApexParser.FromNameListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#subFieldList.
    def visitSubFieldList(self, ctx:ApexParser.SubFieldListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#subFieldEntry.
    def visitSubFieldEntry(self, ctx:ApexParser.SubFieldEntryContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soqlFieldsParameter.
    def visitSoqlFieldsParameter(self, ctx:ApexParser.SoqlFieldsParameterContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soqlFunction.
    def visitSoqlFunction(self, ctx:ApexParser.SoqlFunctionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#dateFieldName.
    def visitDateFieldName(self, ctx:ApexParser.DateFieldNameContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#typeOf.
    def visitTypeOf(self, ctx:ApexParser.TypeOfContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#whenClause.
    def visitWhenClause(self, ctx:ApexParser.WhenClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#elseClause.
    def visitElseClause(self, ctx:ApexParser.ElseClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldNameList.
    def visitFieldNameList(self, ctx:ApexParser.FieldNameListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#usingScope.
    def visitUsingScope(self, ctx:ApexParser.UsingScopeContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#whereClause.
    def visitWhereClause(self, ctx:ApexParser.WhereClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#logicalExpression.
    def visitLogicalExpression(self, ctx:ApexParser.LogicalExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#conditionalExpression.
    def visitConditionalExpression(self, ctx:ApexParser.ConditionalExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldExpression.
    def visitFieldExpression(self, ctx:ApexParser.FieldExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#comparisonOperator.
    def visitComparisonOperator(self, ctx:ApexParser.ComparisonOperatorContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#value.
    def visitValue(self, ctx:ApexParser.ValueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#valueList.
    def visitValueList(self, ctx:ApexParser.ValueListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#currencyValue.
    def visitCurrencyValue(self, ctx:ApexParser.CurrencyValueContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#withClause.
    def visitWithClause(self, ctx:ApexParser.WithClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#filteringExpression.
    def visitFilteringExpression(self, ctx:ApexParser.FilteringExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#dataCategorySelection.
    def visitDataCategorySelection(self, ctx:ApexParser.DataCategorySelectionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#dataCategoryName.
    def visitDataCategoryName(self, ctx:ApexParser.DataCategoryNameContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#filteringSelector.
    def visitFilteringSelector(self, ctx:ApexParser.FilteringSelectorContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#groupByClause.
    def visitGroupByClause(self, ctx:ApexParser.GroupByClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#orderByClause.
    def visitOrderByClause(self, ctx:ApexParser.OrderByClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldOrderList.
    def visitFieldOrderList(self, ctx:ApexParser.FieldOrderListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldOrder.
    def visitFieldOrder(self, ctx:ApexParser.FieldOrderContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#limitClause.
    def visitLimitClause(self, ctx:ApexParser.LimitClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#offsetClause.
    def visitOffsetClause(self, ctx:ApexParser.OffsetClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#allRowsClause.
    def visitAllRowsClause(self, ctx:ApexParser.AllRowsClauseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#forClauses.
    def visitForClauses(self, ctx:ApexParser.ForClausesContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#boundExpression.
    def visitBoundExpression(self, ctx:ApexParser.BoundExpressionContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#dateFormula.
    def visitDateFormula(self, ctx:ApexParser.DateFormulaContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#signedInteger.
    def visitSignedInteger(self, ctx:ApexParser.SignedIntegerContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soqlId.
    def visitSoqlId(self, ctx:ApexParser.SoqlIdContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soslLiteral.
    def visitSoslLiteral(self, ctx:ApexParser.SoslLiteralContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soslClauses.
    def visitSoslClauses(self, ctx:ApexParser.SoslClausesContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#searchGroup.
    def visitSearchGroup(self, ctx:ApexParser.SearchGroupContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldSpecList.
    def visitFieldSpecList(self, ctx:ApexParser.FieldSpecListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldSpec.
    def visitFieldSpec(self, ctx:ApexParser.FieldSpecContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#fieldList.
    def visitFieldList(self, ctx:ApexParser.FieldListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#updateList.
    def visitUpdateList(self, ctx:ApexParser.UpdateListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#updateType.
    def visitUpdateType(self, ctx:ApexParser.UpdateTypeContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#networkList.
    def visitNetworkList(self, ctx:ApexParser.NetworkListContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#soslId.
    def visitSoslId(self, ctx:ApexParser.SoslIdContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#id.
    def visitId(self, ctx:ApexParser.IdContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by ApexParser#anyId.
    def visitAnyId(self, ctx:ApexParser.AnyIdContext):
        return self.visitChildren(ctx)



del ApexParser