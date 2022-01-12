# Generated from ApexParser.g4 by ANTLR 4.9.3
from antlr4 import *
if __name__ is not None and "." in __name__:
    from .ApexParser import ApexParser
else:
    from ApexParser import ApexParser

# This class defines a complete listener for a parse tree produced by ApexParser.
class ApexParserListener(ParseTreeListener):

    # Enter a parse tree produced by ApexParser#triggerUnit.
    def enterTriggerUnit(self, ctx:ApexParser.TriggerUnitContext):
        pass

    # Exit a parse tree produced by ApexParser#triggerUnit.
    def exitTriggerUnit(self, ctx:ApexParser.TriggerUnitContext):
        pass


    # Enter a parse tree produced by ApexParser#triggerCase.
    def enterTriggerCase(self, ctx:ApexParser.TriggerCaseContext):
        pass

    # Exit a parse tree produced by ApexParser#triggerCase.
    def exitTriggerCase(self, ctx:ApexParser.TriggerCaseContext):
        pass


    # Enter a parse tree produced by ApexParser#compilationUnit.
    def enterCompilationUnit(self, ctx:ApexParser.CompilationUnitContext):
        pass

    # Exit a parse tree produced by ApexParser#compilationUnit.
    def exitCompilationUnit(self, ctx:ApexParser.CompilationUnitContext):
        pass


    # Enter a parse tree produced by ApexParser#typeDeclaration.
    def enterTypeDeclaration(self, ctx:ApexParser.TypeDeclarationContext):
        return ctx.children

    # Exit a parse tree produced by ApexParser#typeDeclaration.
    def exitTypeDeclaration(self, ctx:ApexParser.TypeDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#classDeclaration.
    def enterClassDeclaration(self, ctx:ApexParser.ClassDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#classDeclaration.
    def exitClassDeclaration(self, ctx:ApexParser.ClassDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#enumDeclaration.
    def enterEnumDeclaration(self, ctx:ApexParser.EnumDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#enumDeclaration.
    def exitEnumDeclaration(self, ctx:ApexParser.EnumDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#enumConstants.
    def enterEnumConstants(self, ctx:ApexParser.EnumConstantsContext):
        pass

    # Exit a parse tree produced by ApexParser#enumConstants.
    def exitEnumConstants(self, ctx:ApexParser.EnumConstantsContext):
        pass


    # Enter a parse tree produced by ApexParser#interfaceDeclaration.
    def enterInterfaceDeclaration(self, ctx:ApexParser.InterfaceDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#interfaceDeclaration.
    def exitInterfaceDeclaration(self, ctx:ApexParser.InterfaceDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#typeList.
    def enterTypeList(self, ctx:ApexParser.TypeListContext):
        pass

    # Exit a parse tree produced by ApexParser#typeList.
    def exitTypeList(self, ctx:ApexParser.TypeListContext):
        pass


    # Enter a parse tree produced by ApexParser#classBody.
    def enterClassBody(self, ctx:ApexParser.ClassBodyContext):
        pass

    # Exit a parse tree produced by ApexParser#classBody.
    def exitClassBody(self, ctx:ApexParser.ClassBodyContext):
        pass


    # Enter a parse tree produced by ApexParser#interfaceBody.
    def enterInterfaceBody(self, ctx:ApexParser.InterfaceBodyContext):
        pass

    # Exit a parse tree produced by ApexParser#interfaceBody.
    def exitInterfaceBody(self, ctx:ApexParser.InterfaceBodyContext):
        pass


    # Enter a parse tree produced by ApexParser#classBodyDeclaration.
    def enterClassBodyDeclaration(self, ctx:ApexParser.ClassBodyDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#classBodyDeclaration.
    def exitClassBodyDeclaration(self, ctx:ApexParser.ClassBodyDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#modifier.
    def enterModifier(self, ctx:ApexParser.ModifierContext):
        pass

    # Exit a parse tree produced by ApexParser#modifier.
    def exitModifier(self, ctx:ApexParser.ModifierContext):
        pass


    # Enter a parse tree produced by ApexParser#memberDeclaration.
    def enterMemberDeclaration(self, ctx:ApexParser.MemberDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#memberDeclaration.
    def exitMemberDeclaration(self, ctx:ApexParser.MemberDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#methodDeclaration.
    def enterMethodDeclaration(self, ctx:ApexParser.MethodDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#methodDeclaration.
    def exitMethodDeclaration(self, ctx:ApexParser.MethodDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#constructorDeclaration.
    def enterConstructorDeclaration(self, ctx:ApexParser.ConstructorDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#constructorDeclaration.
    def exitConstructorDeclaration(self, ctx:ApexParser.ConstructorDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldDeclaration.
    def enterFieldDeclaration(self, ctx:ApexParser.FieldDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldDeclaration.
    def exitFieldDeclaration(self, ctx:ApexParser.FieldDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#propertyDeclaration.
    def enterPropertyDeclaration(self, ctx:ApexParser.PropertyDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#propertyDeclaration.
    def exitPropertyDeclaration(self, ctx:ApexParser.PropertyDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#interfaceMethodDeclaration.
    def enterInterfaceMethodDeclaration(self, ctx:ApexParser.InterfaceMethodDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#interfaceMethodDeclaration.
    def exitInterfaceMethodDeclaration(self, ctx:ApexParser.InterfaceMethodDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#variableDeclarators.
    def enterVariableDeclarators(self, ctx:ApexParser.VariableDeclaratorsContext):
        pass

    # Exit a parse tree produced by ApexParser#variableDeclarators.
    def exitVariableDeclarators(self, ctx:ApexParser.VariableDeclaratorsContext):
        pass


    # Enter a parse tree produced by ApexParser#variableDeclarator.
    def enterVariableDeclarator(self, ctx:ApexParser.VariableDeclaratorContext):
        pass

    # Exit a parse tree produced by ApexParser#variableDeclarator.
    def exitVariableDeclarator(self, ctx:ApexParser.VariableDeclaratorContext):
        pass


    # Enter a parse tree produced by ApexParser#arrayInitializer.
    def enterArrayInitializer(self, ctx:ApexParser.ArrayInitializerContext):
        pass

    # Exit a parse tree produced by ApexParser#arrayInitializer.
    def exitArrayInitializer(self, ctx:ApexParser.ArrayInitializerContext):
        pass


    # Enter a parse tree produced by ApexParser#typeRef.
    def enterTypeRef(self, ctx:ApexParser.TypeRefContext):
        pass

    # Exit a parse tree produced by ApexParser#typeRef.
    def exitTypeRef(self, ctx:ApexParser.TypeRefContext):
        pass


    # Enter a parse tree produced by ApexParser#arraySubscripts.
    def enterArraySubscripts(self, ctx:ApexParser.ArraySubscriptsContext):
        pass

    # Exit a parse tree produced by ApexParser#arraySubscripts.
    def exitArraySubscripts(self, ctx:ApexParser.ArraySubscriptsContext):
        pass


    # Enter a parse tree produced by ApexParser#typeName.
    def enterTypeName(self, ctx:ApexParser.TypeNameContext):
        pass

    # Exit a parse tree produced by ApexParser#typeName.
    def exitTypeName(self, ctx:ApexParser.TypeNameContext):
        pass


    # Enter a parse tree produced by ApexParser#typeArguments.
    def enterTypeArguments(self, ctx:ApexParser.TypeArgumentsContext):
        pass

    # Exit a parse tree produced by ApexParser#typeArguments.
    def exitTypeArguments(self, ctx:ApexParser.TypeArgumentsContext):
        pass


    # Enter a parse tree produced by ApexParser#formalParameters.
    def enterFormalParameters(self, ctx:ApexParser.FormalParametersContext):
        pass

    # Exit a parse tree produced by ApexParser#formalParameters.
    def exitFormalParameters(self, ctx:ApexParser.FormalParametersContext):
        pass


    # Enter a parse tree produced by ApexParser#formalParameterList.
    def enterFormalParameterList(self, ctx:ApexParser.FormalParameterListContext):
        pass

    # Exit a parse tree produced by ApexParser#formalParameterList.
    def exitFormalParameterList(self, ctx:ApexParser.FormalParameterListContext):
        pass


    # Enter a parse tree produced by ApexParser#formalParameter.
    def enterFormalParameter(self, ctx:ApexParser.FormalParameterContext):
        pass

    # Exit a parse tree produced by ApexParser#formalParameter.
    def exitFormalParameter(self, ctx:ApexParser.FormalParameterContext):
        pass


    # Enter a parse tree produced by ApexParser#qualifiedName.
    def enterQualifiedName(self, ctx:ApexParser.QualifiedNameContext):
        pass

    # Exit a parse tree produced by ApexParser#qualifiedName.
    def exitQualifiedName(self, ctx:ApexParser.QualifiedNameContext):
        pass


    # Enter a parse tree produced by ApexParser#literal.
    def enterLiteral(self, ctx:ApexParser.LiteralContext):
        pass

    # Exit a parse tree produced by ApexParser#literal.
    def exitLiteral(self, ctx:ApexParser.LiteralContext):
        pass


    # Enter a parse tree produced by ApexParser#annotation.
    def enterAnnotation(self, ctx:ApexParser.AnnotationContext):
        pass

    # Exit a parse tree produced by ApexParser#annotation.
    def exitAnnotation(self, ctx:ApexParser.AnnotationContext):
        pass


    # Enter a parse tree produced by ApexParser#elementValuePairs.
    def enterElementValuePairs(self, ctx:ApexParser.ElementValuePairsContext):
        pass

    # Exit a parse tree produced by ApexParser#elementValuePairs.
    def exitElementValuePairs(self, ctx:ApexParser.ElementValuePairsContext):
        pass


    # Enter a parse tree produced by ApexParser#elementValuePair.
    def enterElementValuePair(self, ctx:ApexParser.ElementValuePairContext):
        pass

    # Exit a parse tree produced by ApexParser#elementValuePair.
    def exitElementValuePair(self, ctx:ApexParser.ElementValuePairContext):
        pass


    # Enter a parse tree produced by ApexParser#elementValue.
    def enterElementValue(self, ctx:ApexParser.ElementValueContext):
        pass

    # Exit a parse tree produced by ApexParser#elementValue.
    def exitElementValue(self, ctx:ApexParser.ElementValueContext):
        pass


    # Enter a parse tree produced by ApexParser#elementValueArrayInitializer.
    def enterElementValueArrayInitializer(self, ctx:ApexParser.ElementValueArrayInitializerContext):
        pass

    # Exit a parse tree produced by ApexParser#elementValueArrayInitializer.
    def exitElementValueArrayInitializer(self, ctx:ApexParser.ElementValueArrayInitializerContext):
        pass


    # Enter a parse tree produced by ApexParser#block.
    def enterBlock(self, ctx:ApexParser.BlockContext):
        pass

    # Exit a parse tree produced by ApexParser#block.
    def exitBlock(self, ctx:ApexParser.BlockContext):
        pass


    # Enter a parse tree produced by ApexParser#localVariableDeclarationStatement.
    def enterLocalVariableDeclarationStatement(self, ctx:ApexParser.LocalVariableDeclarationStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#localVariableDeclarationStatement.
    def exitLocalVariableDeclarationStatement(self, ctx:ApexParser.LocalVariableDeclarationStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#localVariableDeclaration.
    def enterLocalVariableDeclaration(self, ctx:ApexParser.LocalVariableDeclarationContext):
        pass

    # Exit a parse tree produced by ApexParser#localVariableDeclaration.
    def exitLocalVariableDeclaration(self, ctx:ApexParser.LocalVariableDeclarationContext):
        pass


    # Enter a parse tree produced by ApexParser#statement.
    def enterStatement(self, ctx:ApexParser.StatementContext):
        pass

    # Exit a parse tree produced by ApexParser#statement.
    def exitStatement(self, ctx:ApexParser.StatementContext):
        pass


    # Enter a parse tree produced by ApexParser#ifStatement.
    def enterIfStatement(self, ctx:ApexParser.IfStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#ifStatement.
    def exitIfStatement(self, ctx:ApexParser.IfStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#switchStatement.
    def enterSwitchStatement(self, ctx:ApexParser.SwitchStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#switchStatement.
    def exitSwitchStatement(self, ctx:ApexParser.SwitchStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#whenControl.
    def enterWhenControl(self, ctx:ApexParser.WhenControlContext):
        pass

    # Exit a parse tree produced by ApexParser#whenControl.
    def exitWhenControl(self, ctx:ApexParser.WhenControlContext):
        pass


    # Enter a parse tree produced by ApexParser#whenValue.
    def enterWhenValue(self, ctx:ApexParser.WhenValueContext):
        pass

    # Exit a parse tree produced by ApexParser#whenValue.
    def exitWhenValue(self, ctx:ApexParser.WhenValueContext):
        pass


    # Enter a parse tree produced by ApexParser#whenLiteral.
    def enterWhenLiteral(self, ctx:ApexParser.WhenLiteralContext):
        pass

    # Exit a parse tree produced by ApexParser#whenLiteral.
    def exitWhenLiteral(self, ctx:ApexParser.WhenLiteralContext):
        pass


    # Enter a parse tree produced by ApexParser#forStatement.
    def enterForStatement(self, ctx:ApexParser.ForStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#forStatement.
    def exitForStatement(self, ctx:ApexParser.ForStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#whileStatement.
    def enterWhileStatement(self, ctx:ApexParser.WhileStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#whileStatement.
    def exitWhileStatement(self, ctx:ApexParser.WhileStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#doWhileStatement.
    def enterDoWhileStatement(self, ctx:ApexParser.DoWhileStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#doWhileStatement.
    def exitDoWhileStatement(self, ctx:ApexParser.DoWhileStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#tryStatement.
    def enterTryStatement(self, ctx:ApexParser.TryStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#tryStatement.
    def exitTryStatement(self, ctx:ApexParser.TryStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#returnStatement.
    def enterReturnStatement(self, ctx:ApexParser.ReturnStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#returnStatement.
    def exitReturnStatement(self, ctx:ApexParser.ReturnStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#throwStatement.
    def enterThrowStatement(self, ctx:ApexParser.ThrowStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#throwStatement.
    def exitThrowStatement(self, ctx:ApexParser.ThrowStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#breakStatement.
    def enterBreakStatement(self, ctx:ApexParser.BreakStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#breakStatement.
    def exitBreakStatement(self, ctx:ApexParser.BreakStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#continueStatement.
    def enterContinueStatement(self, ctx:ApexParser.ContinueStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#continueStatement.
    def exitContinueStatement(self, ctx:ApexParser.ContinueStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#insertStatement.
    def enterInsertStatement(self, ctx:ApexParser.InsertStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#insertStatement.
    def exitInsertStatement(self, ctx:ApexParser.InsertStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#updateStatement.
    def enterUpdateStatement(self, ctx:ApexParser.UpdateStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#updateStatement.
    def exitUpdateStatement(self, ctx:ApexParser.UpdateStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#deleteStatement.
    def enterDeleteStatement(self, ctx:ApexParser.DeleteStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#deleteStatement.
    def exitDeleteStatement(self, ctx:ApexParser.DeleteStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#undeleteStatement.
    def enterUndeleteStatement(self, ctx:ApexParser.UndeleteStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#undeleteStatement.
    def exitUndeleteStatement(self, ctx:ApexParser.UndeleteStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#upsertStatement.
    def enterUpsertStatement(self, ctx:ApexParser.UpsertStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#upsertStatement.
    def exitUpsertStatement(self, ctx:ApexParser.UpsertStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#mergeStatement.
    def enterMergeStatement(self, ctx:ApexParser.MergeStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#mergeStatement.
    def exitMergeStatement(self, ctx:ApexParser.MergeStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#runAsStatement.
    def enterRunAsStatement(self, ctx:ApexParser.RunAsStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#runAsStatement.
    def exitRunAsStatement(self, ctx:ApexParser.RunAsStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#expressionStatement.
    def enterExpressionStatement(self, ctx:ApexParser.ExpressionStatementContext):
        pass

    # Exit a parse tree produced by ApexParser#expressionStatement.
    def exitExpressionStatement(self, ctx:ApexParser.ExpressionStatementContext):
        pass


    # Enter a parse tree produced by ApexParser#propertyBlock.
    def enterPropertyBlock(self, ctx:ApexParser.PropertyBlockContext):
        pass

    # Exit a parse tree produced by ApexParser#propertyBlock.
    def exitPropertyBlock(self, ctx:ApexParser.PropertyBlockContext):
        pass


    # Enter a parse tree produced by ApexParser#getter.
    def enterGetter(self, ctx:ApexParser.GetterContext):
        pass

    # Exit a parse tree produced by ApexParser#getter.
    def exitGetter(self, ctx:ApexParser.GetterContext):
        pass


    # Enter a parse tree produced by ApexParser#setter.
    def enterSetter(self, ctx:ApexParser.SetterContext):
        pass

    # Exit a parse tree produced by ApexParser#setter.
    def exitSetter(self, ctx:ApexParser.SetterContext):
        pass


    # Enter a parse tree produced by ApexParser#catchClause.
    def enterCatchClause(self, ctx:ApexParser.CatchClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#catchClause.
    def exitCatchClause(self, ctx:ApexParser.CatchClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#finallyBlock.
    def enterFinallyBlock(self, ctx:ApexParser.FinallyBlockContext):
        pass

    # Exit a parse tree produced by ApexParser#finallyBlock.
    def exitFinallyBlock(self, ctx:ApexParser.FinallyBlockContext):
        pass


    # Enter a parse tree produced by ApexParser#forControl.
    def enterForControl(self, ctx:ApexParser.ForControlContext):
        pass

    # Exit a parse tree produced by ApexParser#forControl.
    def exitForControl(self, ctx:ApexParser.ForControlContext):
        pass


    # Enter a parse tree produced by ApexParser#forInit.
    def enterForInit(self, ctx:ApexParser.ForInitContext):
        pass

    # Exit a parse tree produced by ApexParser#forInit.
    def exitForInit(self, ctx:ApexParser.ForInitContext):
        pass


    # Enter a parse tree produced by ApexParser#enhancedForControl.
    def enterEnhancedForControl(self, ctx:ApexParser.EnhancedForControlContext):
        pass

    # Exit a parse tree produced by ApexParser#enhancedForControl.
    def exitEnhancedForControl(self, ctx:ApexParser.EnhancedForControlContext):
        pass


    # Enter a parse tree produced by ApexParser#forUpdate.
    def enterForUpdate(self, ctx:ApexParser.ForUpdateContext):
        pass

    # Exit a parse tree produced by ApexParser#forUpdate.
    def exitForUpdate(self, ctx:ApexParser.ForUpdateContext):
        pass


    # Enter a parse tree produced by ApexParser#parExpression.
    def enterParExpression(self, ctx:ApexParser.ParExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#parExpression.
    def exitParExpression(self, ctx:ApexParser.ParExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#expressionList.
    def enterExpressionList(self, ctx:ApexParser.ExpressionListContext):
        pass

    # Exit a parse tree produced by ApexParser#expressionList.
    def exitExpressionList(self, ctx:ApexParser.ExpressionListContext):
        pass


    # Enter a parse tree produced by ApexParser#primaryExpression.
    def enterPrimaryExpression(self, ctx:ApexParser.PrimaryExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#primaryExpression.
    def exitPrimaryExpression(self, ctx:ApexParser.PrimaryExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#arth1Expression.
    def enterArth1Expression(self, ctx:ApexParser.Arth1ExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#arth1Expression.
    def exitArth1Expression(self, ctx:ApexParser.Arth1ExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#dotExpression.
    def enterDotExpression(self, ctx:ApexParser.DotExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#dotExpression.
    def exitDotExpression(self, ctx:ApexParser.DotExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#bitOrExpression.
    def enterBitOrExpression(self, ctx:ApexParser.BitOrExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#bitOrExpression.
    def exitBitOrExpression(self, ctx:ApexParser.BitOrExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#arrayExpression.
    def enterArrayExpression(self, ctx:ApexParser.ArrayExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#arrayExpression.
    def exitArrayExpression(self, ctx:ApexParser.ArrayExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#newExpression.
    def enterNewExpression(self, ctx:ApexParser.NewExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#newExpression.
    def exitNewExpression(self, ctx:ApexParser.NewExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#assignExpression.
    def enterAssignExpression(self, ctx:ApexParser.AssignExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#assignExpression.
    def exitAssignExpression(self, ctx:ApexParser.AssignExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#methodCallExpression.
    def enterMethodCallExpression(self, ctx:ApexParser.MethodCallExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#methodCallExpression.
    def exitMethodCallExpression(self, ctx:ApexParser.MethodCallExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#bitNotExpression.
    def enterBitNotExpression(self, ctx:ApexParser.BitNotExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#bitNotExpression.
    def exitBitNotExpression(self, ctx:ApexParser.BitNotExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#arth2Expression.
    def enterArth2Expression(self, ctx:ApexParser.Arth2ExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#arth2Expression.
    def exitArth2Expression(self, ctx:ApexParser.Arth2ExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#logAndExpression.
    def enterLogAndExpression(self, ctx:ApexParser.LogAndExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#logAndExpression.
    def exitLogAndExpression(self, ctx:ApexParser.LogAndExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#castExpression.
    def enterCastExpression(self, ctx:ApexParser.CastExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#castExpression.
    def exitCastExpression(self, ctx:ApexParser.CastExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#bitAndExpression.
    def enterBitAndExpression(self, ctx:ApexParser.BitAndExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#bitAndExpression.
    def exitBitAndExpression(self, ctx:ApexParser.BitAndExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#cmpExpression.
    def enterCmpExpression(self, ctx:ApexParser.CmpExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#cmpExpression.
    def exitCmpExpression(self, ctx:ApexParser.CmpExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#bitExpression.
    def enterBitExpression(self, ctx:ApexParser.BitExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#bitExpression.
    def exitBitExpression(self, ctx:ApexParser.BitExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#logOrExpression.
    def enterLogOrExpression(self, ctx:ApexParser.LogOrExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#logOrExpression.
    def exitLogOrExpression(self, ctx:ApexParser.LogOrExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#condExpression.
    def enterCondExpression(self, ctx:ApexParser.CondExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#condExpression.
    def exitCondExpression(self, ctx:ApexParser.CondExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#equalityExpression.
    def enterEqualityExpression(self, ctx:ApexParser.EqualityExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#equalityExpression.
    def exitEqualityExpression(self, ctx:ApexParser.EqualityExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#postOpExpression.
    def enterPostOpExpression(self, ctx:ApexParser.PostOpExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#postOpExpression.
    def exitPostOpExpression(self, ctx:ApexParser.PostOpExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#negExpression.
    def enterNegExpression(self, ctx:ApexParser.NegExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#negExpression.
    def exitNegExpression(self, ctx:ApexParser.NegExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#preOpExpression.
    def enterPreOpExpression(self, ctx:ApexParser.PreOpExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#preOpExpression.
    def exitPreOpExpression(self, ctx:ApexParser.PreOpExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#subExpression.
    def enterSubExpression(self, ctx:ApexParser.SubExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#subExpression.
    def exitSubExpression(self, ctx:ApexParser.SubExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#instanceOfExpression.
    def enterInstanceOfExpression(self, ctx:ApexParser.InstanceOfExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#instanceOfExpression.
    def exitInstanceOfExpression(self, ctx:ApexParser.InstanceOfExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#thisPrimary.
    def enterThisPrimary(self, ctx:ApexParser.ThisPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#thisPrimary.
    def exitThisPrimary(self, ctx:ApexParser.ThisPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#superPrimary.
    def enterSuperPrimary(self, ctx:ApexParser.SuperPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#superPrimary.
    def exitSuperPrimary(self, ctx:ApexParser.SuperPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#literalPrimary.
    def enterLiteralPrimary(self, ctx:ApexParser.LiteralPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#literalPrimary.
    def exitLiteralPrimary(self, ctx:ApexParser.LiteralPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#typeRefPrimary.
    def enterTypeRefPrimary(self, ctx:ApexParser.TypeRefPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#typeRefPrimary.
    def exitTypeRefPrimary(self, ctx:ApexParser.TypeRefPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#idPrimary.
    def enterIdPrimary(self, ctx:ApexParser.IdPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#idPrimary.
    def exitIdPrimary(self, ctx:ApexParser.IdPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#soqlPrimary.
    def enterSoqlPrimary(self, ctx:ApexParser.SoqlPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#soqlPrimary.
    def exitSoqlPrimary(self, ctx:ApexParser.SoqlPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#soslPrimary.
    def enterSoslPrimary(self, ctx:ApexParser.SoslPrimaryContext):
        pass

    # Exit a parse tree produced by ApexParser#soslPrimary.
    def exitSoslPrimary(self, ctx:ApexParser.SoslPrimaryContext):
        pass


    # Enter a parse tree produced by ApexParser#methodCall.
    def enterMethodCall(self, ctx:ApexParser.MethodCallContext):
        pass

    # Exit a parse tree produced by ApexParser#methodCall.
    def exitMethodCall(self, ctx:ApexParser.MethodCallContext):
        pass


    # Enter a parse tree produced by ApexParser#dotMethodCall.
    def enterDotMethodCall(self, ctx:ApexParser.DotMethodCallContext):
        pass

    # Exit a parse tree produced by ApexParser#dotMethodCall.
    def exitDotMethodCall(self, ctx:ApexParser.DotMethodCallContext):
        pass


    # Enter a parse tree produced by ApexParser#creator.
    def enterCreator(self, ctx:ApexParser.CreatorContext):
        pass

    # Exit a parse tree produced by ApexParser#creator.
    def exitCreator(self, ctx:ApexParser.CreatorContext):
        pass


    # Enter a parse tree produced by ApexParser#createdName.
    def enterCreatedName(self, ctx:ApexParser.CreatedNameContext):
        pass

    # Exit a parse tree produced by ApexParser#createdName.
    def exitCreatedName(self, ctx:ApexParser.CreatedNameContext):
        pass


    # Enter a parse tree produced by ApexParser#idCreatedNamePair.
    def enterIdCreatedNamePair(self, ctx:ApexParser.IdCreatedNamePairContext):
        pass

    # Exit a parse tree produced by ApexParser#idCreatedNamePair.
    def exitIdCreatedNamePair(self, ctx:ApexParser.IdCreatedNamePairContext):
        pass


    # Enter a parse tree produced by ApexParser#noRest.
    def enterNoRest(self, ctx:ApexParser.NoRestContext):
        pass

    # Exit a parse tree produced by ApexParser#noRest.
    def exitNoRest(self, ctx:ApexParser.NoRestContext):
        pass


    # Enter a parse tree produced by ApexParser#classCreatorRest.
    def enterClassCreatorRest(self, ctx:ApexParser.ClassCreatorRestContext):
        pass

    # Exit a parse tree produced by ApexParser#classCreatorRest.
    def exitClassCreatorRest(self, ctx:ApexParser.ClassCreatorRestContext):
        pass


    # Enter a parse tree produced by ApexParser#arrayCreatorRest.
    def enterArrayCreatorRest(self, ctx:ApexParser.ArrayCreatorRestContext):
        pass

    # Exit a parse tree produced by ApexParser#arrayCreatorRest.
    def exitArrayCreatorRest(self, ctx:ApexParser.ArrayCreatorRestContext):
        pass


    # Enter a parse tree produced by ApexParser#mapCreatorRest.
    def enterMapCreatorRest(self, ctx:ApexParser.MapCreatorRestContext):
        pass

    # Exit a parse tree produced by ApexParser#mapCreatorRest.
    def exitMapCreatorRest(self, ctx:ApexParser.MapCreatorRestContext):
        pass


    # Enter a parse tree produced by ApexParser#mapCreatorRestPair.
    def enterMapCreatorRestPair(self, ctx:ApexParser.MapCreatorRestPairContext):
        pass

    # Exit a parse tree produced by ApexParser#mapCreatorRestPair.
    def exitMapCreatorRestPair(self, ctx:ApexParser.MapCreatorRestPairContext):
        pass


    # Enter a parse tree produced by ApexParser#setCreatorRest.
    def enterSetCreatorRest(self, ctx:ApexParser.SetCreatorRestContext):
        pass

    # Exit a parse tree produced by ApexParser#setCreatorRest.
    def exitSetCreatorRest(self, ctx:ApexParser.SetCreatorRestContext):
        pass


    # Enter a parse tree produced by ApexParser#arguments.
    def enterArguments(self, ctx:ApexParser.ArgumentsContext):
        pass

    # Exit a parse tree produced by ApexParser#arguments.
    def exitArguments(self, ctx:ApexParser.ArgumentsContext):
        pass


    # Enter a parse tree produced by ApexParser#soqlLiteral.
    def enterSoqlLiteral(self, ctx:ApexParser.SoqlLiteralContext):
        pass

    # Exit a parse tree produced by ApexParser#soqlLiteral.
    def exitSoqlLiteral(self, ctx:ApexParser.SoqlLiteralContext):
        pass


    # Enter a parse tree produced by ApexParser#query.
    def enterQuery(self, ctx:ApexParser.QueryContext):
        pass

    # Exit a parse tree produced by ApexParser#query.
    def exitQuery(self, ctx:ApexParser.QueryContext):
        pass


    # Enter a parse tree produced by ApexParser#subQuery.
    def enterSubQuery(self, ctx:ApexParser.SubQueryContext):
        pass

    # Exit a parse tree produced by ApexParser#subQuery.
    def exitSubQuery(self, ctx:ApexParser.SubQueryContext):
        pass


    # Enter a parse tree produced by ApexParser#selectList.
    def enterSelectList(self, ctx:ApexParser.SelectListContext):
        pass

    # Exit a parse tree produced by ApexParser#selectList.
    def exitSelectList(self, ctx:ApexParser.SelectListContext):
        pass


    # Enter a parse tree produced by ApexParser#selectEntry.
    def enterSelectEntry(self, ctx:ApexParser.SelectEntryContext):
        pass

    # Exit a parse tree produced by ApexParser#selectEntry.
    def exitSelectEntry(self, ctx:ApexParser.SelectEntryContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldName.
    def enterFieldName(self, ctx:ApexParser.FieldNameContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldName.
    def exitFieldName(self, ctx:ApexParser.FieldNameContext):
        pass


    # Enter a parse tree produced by ApexParser#fromNameList.
    def enterFromNameList(self, ctx:ApexParser.FromNameListContext):
        pass

    # Exit a parse tree produced by ApexParser#fromNameList.
    def exitFromNameList(self, ctx:ApexParser.FromNameListContext):
        pass


    # Enter a parse tree produced by ApexParser#subFieldList.
    def enterSubFieldList(self, ctx:ApexParser.SubFieldListContext):
        pass

    # Exit a parse tree produced by ApexParser#subFieldList.
    def exitSubFieldList(self, ctx:ApexParser.SubFieldListContext):
        pass


    # Enter a parse tree produced by ApexParser#subFieldEntry.
    def enterSubFieldEntry(self, ctx:ApexParser.SubFieldEntryContext):
        pass

    # Exit a parse tree produced by ApexParser#subFieldEntry.
    def exitSubFieldEntry(self, ctx:ApexParser.SubFieldEntryContext):
        pass


    # Enter a parse tree produced by ApexParser#soqlFieldsParameter.
    def enterSoqlFieldsParameter(self, ctx:ApexParser.SoqlFieldsParameterContext):
        pass

    # Exit a parse tree produced by ApexParser#soqlFieldsParameter.
    def exitSoqlFieldsParameter(self, ctx:ApexParser.SoqlFieldsParameterContext):
        pass


    # Enter a parse tree produced by ApexParser#soqlFunction.
    def enterSoqlFunction(self, ctx:ApexParser.SoqlFunctionContext):
        pass

    # Exit a parse tree produced by ApexParser#soqlFunction.
    def exitSoqlFunction(self, ctx:ApexParser.SoqlFunctionContext):
        pass


    # Enter a parse tree produced by ApexParser#dateFieldName.
    def enterDateFieldName(self, ctx:ApexParser.DateFieldNameContext):
        pass

    # Exit a parse tree produced by ApexParser#dateFieldName.
    def exitDateFieldName(self, ctx:ApexParser.DateFieldNameContext):
        pass


    # Enter a parse tree produced by ApexParser#typeOf.
    def enterTypeOf(self, ctx:ApexParser.TypeOfContext):
        pass

    # Exit a parse tree produced by ApexParser#typeOf.
    def exitTypeOf(self, ctx:ApexParser.TypeOfContext):
        pass


    # Enter a parse tree produced by ApexParser#whenClause.
    def enterWhenClause(self, ctx:ApexParser.WhenClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#whenClause.
    def exitWhenClause(self, ctx:ApexParser.WhenClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#elseClause.
    def enterElseClause(self, ctx:ApexParser.ElseClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#elseClause.
    def exitElseClause(self, ctx:ApexParser.ElseClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldNameList.
    def enterFieldNameList(self, ctx:ApexParser.FieldNameListContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldNameList.
    def exitFieldNameList(self, ctx:ApexParser.FieldNameListContext):
        pass


    # Enter a parse tree produced by ApexParser#usingScope.
    def enterUsingScope(self, ctx:ApexParser.UsingScopeContext):
        pass

    # Exit a parse tree produced by ApexParser#usingScope.
    def exitUsingScope(self, ctx:ApexParser.UsingScopeContext):
        pass


    # Enter a parse tree produced by ApexParser#whereClause.
    def enterWhereClause(self, ctx:ApexParser.WhereClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#whereClause.
    def exitWhereClause(self, ctx:ApexParser.WhereClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#logicalExpression.
    def enterLogicalExpression(self, ctx:ApexParser.LogicalExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#logicalExpression.
    def exitLogicalExpression(self, ctx:ApexParser.LogicalExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#conditionalExpression.
    def enterConditionalExpression(self, ctx:ApexParser.ConditionalExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#conditionalExpression.
    def exitConditionalExpression(self, ctx:ApexParser.ConditionalExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldExpression.
    def enterFieldExpression(self, ctx:ApexParser.FieldExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldExpression.
    def exitFieldExpression(self, ctx:ApexParser.FieldExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#comparisonOperator.
    def enterComparisonOperator(self, ctx:ApexParser.ComparisonOperatorContext):
        pass

    # Exit a parse tree produced by ApexParser#comparisonOperator.
    def exitComparisonOperator(self, ctx:ApexParser.ComparisonOperatorContext):
        pass


    # Enter a parse tree produced by ApexParser#value.
    def enterValue(self, ctx:ApexParser.ValueContext):
        pass

    # Exit a parse tree produced by ApexParser#value.
    def exitValue(self, ctx:ApexParser.ValueContext):
        pass


    # Enter a parse tree produced by ApexParser#valueList.
    def enterValueList(self, ctx:ApexParser.ValueListContext):
        pass

    # Exit a parse tree produced by ApexParser#valueList.
    def exitValueList(self, ctx:ApexParser.ValueListContext):
        pass


    # Enter a parse tree produced by ApexParser#currencyValue.
    def enterCurrencyValue(self, ctx:ApexParser.CurrencyValueContext):
        pass

    # Exit a parse tree produced by ApexParser#currencyValue.
    def exitCurrencyValue(self, ctx:ApexParser.CurrencyValueContext):
        pass


    # Enter a parse tree produced by ApexParser#withClause.
    def enterWithClause(self, ctx:ApexParser.WithClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#withClause.
    def exitWithClause(self, ctx:ApexParser.WithClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#filteringExpression.
    def enterFilteringExpression(self, ctx:ApexParser.FilteringExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#filteringExpression.
    def exitFilteringExpression(self, ctx:ApexParser.FilteringExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#dataCategorySelection.
    def enterDataCategorySelection(self, ctx:ApexParser.DataCategorySelectionContext):
        pass

    # Exit a parse tree produced by ApexParser#dataCategorySelection.
    def exitDataCategorySelection(self, ctx:ApexParser.DataCategorySelectionContext):
        pass


    # Enter a parse tree produced by ApexParser#dataCategoryName.
    def enterDataCategoryName(self, ctx:ApexParser.DataCategoryNameContext):
        pass

    # Exit a parse tree produced by ApexParser#dataCategoryName.
    def exitDataCategoryName(self, ctx:ApexParser.DataCategoryNameContext):
        pass


    # Enter a parse tree produced by ApexParser#filteringSelector.
    def enterFilteringSelector(self, ctx:ApexParser.FilteringSelectorContext):
        pass

    # Exit a parse tree produced by ApexParser#filteringSelector.
    def exitFilteringSelector(self, ctx:ApexParser.FilteringSelectorContext):
        pass


    # Enter a parse tree produced by ApexParser#groupByClause.
    def enterGroupByClause(self, ctx:ApexParser.GroupByClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#groupByClause.
    def exitGroupByClause(self, ctx:ApexParser.GroupByClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#orderByClause.
    def enterOrderByClause(self, ctx:ApexParser.OrderByClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#orderByClause.
    def exitOrderByClause(self, ctx:ApexParser.OrderByClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldOrderList.
    def enterFieldOrderList(self, ctx:ApexParser.FieldOrderListContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldOrderList.
    def exitFieldOrderList(self, ctx:ApexParser.FieldOrderListContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldOrder.
    def enterFieldOrder(self, ctx:ApexParser.FieldOrderContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldOrder.
    def exitFieldOrder(self, ctx:ApexParser.FieldOrderContext):
        pass


    # Enter a parse tree produced by ApexParser#limitClause.
    def enterLimitClause(self, ctx:ApexParser.LimitClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#limitClause.
    def exitLimitClause(self, ctx:ApexParser.LimitClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#offsetClause.
    def enterOffsetClause(self, ctx:ApexParser.OffsetClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#offsetClause.
    def exitOffsetClause(self, ctx:ApexParser.OffsetClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#allRowsClause.
    def enterAllRowsClause(self, ctx:ApexParser.AllRowsClauseContext):
        pass

    # Exit a parse tree produced by ApexParser#allRowsClause.
    def exitAllRowsClause(self, ctx:ApexParser.AllRowsClauseContext):
        pass


    # Enter a parse tree produced by ApexParser#forClauses.
    def enterForClauses(self, ctx:ApexParser.ForClausesContext):
        pass

    # Exit a parse tree produced by ApexParser#forClauses.
    def exitForClauses(self, ctx:ApexParser.ForClausesContext):
        pass


    # Enter a parse tree produced by ApexParser#boundExpression.
    def enterBoundExpression(self, ctx:ApexParser.BoundExpressionContext):
        pass

    # Exit a parse tree produced by ApexParser#boundExpression.
    def exitBoundExpression(self, ctx:ApexParser.BoundExpressionContext):
        pass


    # Enter a parse tree produced by ApexParser#dateFormula.
    def enterDateFormula(self, ctx:ApexParser.DateFormulaContext):
        pass

    # Exit a parse tree produced by ApexParser#dateFormula.
    def exitDateFormula(self, ctx:ApexParser.DateFormulaContext):
        pass


    # Enter a parse tree produced by ApexParser#signedInteger.
    def enterSignedInteger(self, ctx:ApexParser.SignedIntegerContext):
        pass

    # Exit a parse tree produced by ApexParser#signedInteger.
    def exitSignedInteger(self, ctx:ApexParser.SignedIntegerContext):
        pass


    # Enter a parse tree produced by ApexParser#soqlId.
    def enterSoqlId(self, ctx:ApexParser.SoqlIdContext):
        pass

    # Exit a parse tree produced by ApexParser#soqlId.
    def exitSoqlId(self, ctx:ApexParser.SoqlIdContext):
        pass


    # Enter a parse tree produced by ApexParser#soslLiteral.
    def enterSoslLiteral(self, ctx:ApexParser.SoslLiteralContext):
        pass

    # Exit a parse tree produced by ApexParser#soslLiteral.
    def exitSoslLiteral(self, ctx:ApexParser.SoslLiteralContext):
        pass


    # Enter a parse tree produced by ApexParser#soslClauses.
    def enterSoslClauses(self, ctx:ApexParser.SoslClausesContext):
        pass

    # Exit a parse tree produced by ApexParser#soslClauses.
    def exitSoslClauses(self, ctx:ApexParser.SoslClausesContext):
        pass


    # Enter a parse tree produced by ApexParser#searchGroup.
    def enterSearchGroup(self, ctx:ApexParser.SearchGroupContext):
        pass

    # Exit a parse tree produced by ApexParser#searchGroup.
    def exitSearchGroup(self, ctx:ApexParser.SearchGroupContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldSpecList.
    def enterFieldSpecList(self, ctx:ApexParser.FieldSpecListContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldSpecList.
    def exitFieldSpecList(self, ctx:ApexParser.FieldSpecListContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldSpec.
    def enterFieldSpec(self, ctx:ApexParser.FieldSpecContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldSpec.
    def exitFieldSpec(self, ctx:ApexParser.FieldSpecContext):
        pass


    # Enter a parse tree produced by ApexParser#fieldList.
    def enterFieldList(self, ctx:ApexParser.FieldListContext):
        pass

    # Exit a parse tree produced by ApexParser#fieldList.
    def exitFieldList(self, ctx:ApexParser.FieldListContext):
        pass


    # Enter a parse tree produced by ApexParser#updateList.
    def enterUpdateList(self, ctx:ApexParser.UpdateListContext):
        pass

    # Exit a parse tree produced by ApexParser#updateList.
    def exitUpdateList(self, ctx:ApexParser.UpdateListContext):
        pass


    # Enter a parse tree produced by ApexParser#updateType.
    def enterUpdateType(self, ctx:ApexParser.UpdateTypeContext):
        pass

    # Exit a parse tree produced by ApexParser#updateType.
    def exitUpdateType(self, ctx:ApexParser.UpdateTypeContext):
        pass


    # Enter a parse tree produced by ApexParser#networkList.
    def enterNetworkList(self, ctx:ApexParser.NetworkListContext):
        pass

    # Exit a parse tree produced by ApexParser#networkList.
    def exitNetworkList(self, ctx:ApexParser.NetworkListContext):
        pass


    # Enter a parse tree produced by ApexParser#soslId.
    def enterSoslId(self, ctx:ApexParser.SoslIdContext):
        pass

    # Exit a parse tree produced by ApexParser#soslId.
    def exitSoslId(self, ctx:ApexParser.SoslIdContext):
        pass


    # Enter a parse tree produced by ApexParser#id.
    def enterId(self, ctx:ApexParser.IdContext):
        pass

    # Exit a parse tree produced by ApexParser#id.
    def exitId(self, ctx:ApexParser.IdContext):
        pass


    # Enter a parse tree produced by ApexParser#anyId.
    def enterAnyId(self, ctx:ApexParser.AnyIdContext):
        pass

    # Exit a parse tree produced by ApexParser#anyId.
    def exitAnyId(self, ctx:ApexParser.AnyIdContext):
        pass



del ApexParser