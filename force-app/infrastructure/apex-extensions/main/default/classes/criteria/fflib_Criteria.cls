/**
 * File Name: fflib_Criteria
 * @description A evaluator based on criteria
 *
 * @author architect ir. Wilhelmus G.J. Velzeboer
 *
 * Copyright (c), W.G.J. Velzeboer,
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above author notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the author nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
public virtual with sharing class fflib_Criteria
		implements Evaluator
{
	private static final String OPEN_BRACKET = '(';
	private static final String CLOSE_BRACKET = ')';
	private static final String FORMULA = 'FORMULA';

	// Add brace when generated to SQL
	private Boolean embraced = false;

	// List to hold all evaluators
	private List<Evaluator> evaluators;

	// The type of comparator NONE | AND | OR | FORMULA
	private String type;
	private IFormulaEvaluator formulaEvaluator;

	/**
	 * populate private variables with default settings.
	 */
	public fflib_Criteria()
	{
		this.evaluators = new List<Evaluator>();
		this.type = 'AND';
	}

	/**
	 * Changes the default comparator for each criteria to OR
	 *
	 * @return Instance of fflib_Criteria
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .orCriteria()
	 *          .equalTo(Account.Name, 'Example')
	 *  		.equalTo(Account.AccountNumber, '1234567')
	 *
	 *  Evaluates:
	 *      Name = 'Example' OR AccountNumber = '1234567'
	 */
	public virtual fflib_Criteria orCriteria()
	{
		this.type = 'OR';
		return this;
	}

	/**
	 * Changes the default comparator for each criteria to AND.
	 * By default the comparator is set to AND,
	 * so this method should only be used in custom implementations extended from fflib_Criteria
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .andCriteria()
	 *          .equalTo(Account.Name, 'Example')
	 *  		.equalTo(Account.AccountNumber, '1234567')
	 *
	 *  Evaluates:
	 *      Name = 'Example' AND AccountNumber = '1234567'
	 */
	public virtual fflib_Criteria andCriteria()
	{
		this.type = 'AND';
		return this;
	}

	/**
	 * Adds a sub criteria with OR comparator
	 *
	 * @param subCriteria The condition of the sub criteria
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 * new fflib_Criteria()
	 *          .equalTo(Account.Name, 'Example')
	 *          .addOrCriteria(
	 *              new fflib_Criteria()
	 *              		.equalTo(Account.AccountNumber, '0001')
	 *              		.equalTo(Account.AccountNumber, '0002'))
	 *
	 *  Evaluates:
	 *      Account.Name = 'Example' AND (Account.AccountNumber = '0001' OR Account.AccountNumber = '0002')
	 */
	public virtual fflib_Criteria addOrCriteria(fflib_Criteria subCriteria)
	{
		subCriteria.orCriteria();
		subCriteria.setEmbraced(true);
		evaluators.add(subCriteria);
		return this;
	}

	/**
	 * Adds a sub criteria with AND comparator
	 *
	 * @param subCriteria The condition of the sub criteria
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 * new fflib_Criteria()
	 *          .orCriteria()
	 *          .equalTo(Account.Name, 'Example')
	 *          .addAndCriteria(
	 *              new fflib_Criteria()
	 *              		.equalTo(Account.AccountNumber, '0001')
	 *              		.equalTo(Account.ShippingCountry, 'USA'))
	 *
	 *  Evaluates:
	 *      Name = 'Example' OR (AccountNumber = '0001' AND ShippingCountry = 'USA')
	 */
	public virtual fflib_Criteria addAndCriteria(fflib_Criteria subCriteria)
	{
		subCriteria.andCriteria();
		subCriteria.setEmbraced(true);
		evaluators.add(subCriteria);
		return this;
	}

	/**
	 * @param formula Formula string
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 * new fflib_Criteria()
	 *          .formulaCriteria('(1 OR 2) AND 3')
     *     		.equalTo(Account.AccountNumber, '0001')
	 *    		.equalTo(Account.AccountNumber, '0002')
	 *     		.equalTo(Account.ShippingCountry, 'USA'))
	 *
	 *  Evaluates:
	 *      (AccountNumber = '0001' OR AccountNumber = '0001') AND ShippingCountry = 'USA'
	 */
	public virtual fflib_Criteria formulaCriteria(String formula)
	{
		this.type = fflib_Criteria.FORMULA;
		this.formulaEvaluator = new FormulaEvaluator(formula.toUpperCase());
		return this;
	}

	public virtual String getEvaluatedFormula()
	{
		if (this.type != fflib_Criteria.FORMULA)
			throw new CriteriaException('Expected a Formula');

		return ((FormulaEvaluator) this.formulaEvaluator).getEvaluatedFormula();
	}


	private interface IFormulaEvaluator
	{
		Boolean evaluate(Object record, Map<Integer, Boolean> evaluatedResultByNumber);
		String toSOQL(Map<Integer, String> queryByNumber);
	}

	public class FormulaEvaluator implements IFormulaEvaluator
	{
		final private String formula;
		private Map<Integer, Boolean> evaluatedResultByNumber;
		private String type
		{
			get;
			set
			{
				if (type != null && type != value)
					throw new CriteriaException('Can not mix AND and OR, use brackets');
				type = value;
			}
		}

		List<IFormulaEvaluator> formulaParts = new List<IFormulaEvaluator>();

		public FormulaEvaluator(String formula)
		{
			this.formula = formula;
			String expression = String.valueOf(formula);
			while(expression.length() > 0)
			{
				if (expression.startsWith(' '))
				{
					expression = expression.removeStart(' ');
				}
				else if (expression.startsWith(OPEN_BRACKET))
				{
					String subFormula = fflib_StringUtils.getBetweenBrackets(OPEN_BRACKET, CLOSE_BRACKET, expression, 0);
					if (subFormula == null)
						throw new CriteriaException('Missing closing bracket');

					formulaParts.add(new FormulaEvaluator(subFormula));
					expression = expression.substring(subFormula.length() + 2);
				}
				else if (expression.startsWith('OR'))
				{
					type = 'OR';
					expression = expression.removeStart('OR');
				}
				else if (expression.startsWith('AND'))
				{
					type = 'AND';
					expression = expression.removeStart('AND');
				}
				else
				{
					String numberValue;
					if (expression.indexOf(' ') == -1)  // at the end of string
					{
						numberValue = expression;
						expression = '';
					}
					else
					{
						numberValue = expression.substring(0, expression.indexOf(' '));
						expression = expression.substring(expression.indexOf(' '));
					}
					formulaParts.add(new FormulaNumberEvaluator(Integer.valueOf(numberValue)));
				}
			}
		}

		public Boolean evaluate(Object record, Map<Integer, Boolean> evaluatedResultByNumber)
		{
			this.evaluatedResultByNumber = evaluatedResultByNumber;
			Boolean result = !(this.type == 'OR');
			for (IFormulaEvaluator evaluator : formulaParts)
			{
				Boolean evaluateResult = evaluator.evaluate(record, evaluatedResultByNumber);
				if (evaluateResult && (this.type == 'OR' || this.type == null))
				{
					return true;
				}
				else if (!evaluateResult && (this.type == 'AND' || this.type == null))
				{
					return false;
				}
			}
			return result;
		}

		public String getEvaluatedFormula()
		{
			String result = String.valueOf(this.formula);
			for (Integer i : this.evaluatedResultByNumber.keySet())
			{
				result = result.replace(
						String.valueOf(i+1),
						String.valueOf(evaluatedResultByNumber.get(i)).toUpperCase()
				);
			}
			return result;
		}

		public String toSOQL(Map<Integer, String> queryByNumber)
		{
			String result = '';
			for (IFormulaEvaluator evaluator : formulaParts)
			{
				if (result != '')
					result += ' ' + this.type + ' ';
				result += evaluator.toSOQL(queryByNumber);
			}
			return OPEN_BRACKET + result + CLOSE_BRACKET;
		}
	}

	private class FormulaNumberEvaluator implements IFormulaEvaluator
	{
		private Integer expressionNumber;

		public FormulaNumberEvaluator(Integer expressionNumber)
		{
			this.expressionNumber = expressionNumber;
		}

		public Boolean evaluate(Object record, Map<Integer, Boolean> evaluatedResultByNumber)
		{
			if (!evaluatedResultByNumber.containsKey(expressionNumber - 1))
				throw new CriteriaException('Expected a formula expression with number: ' + expressionNumber);

			return evaluatedResultByNumber.get(expressionNumber - 1);
		}

		public String toSOQL(Map<Integer, String> queryByNumber)
		{
			if (!queryByNumber.containsKey(expressionNumber - 1))
				throw new CriteriaException('Expected a formula expression with number: ' + expressionNumber);

			return queryByNumber.get(expressionNumber - 1);
		}
	}

	/**
	 * Add an equal to criteria comparing a fields value to a given value
	 *
	 * @param field The sObjectField to evaluate
	 * @param value The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .equalTo(Account.Name, 'Example')
	 *
	 * Evaluates:
	 *      Name = 'Example'
	 */
	public virtual fflib_Criteria equalTo(Schema.SObjectField field, Object value)
	{
		evaluators.add(new FieldEvaluator(field, fflib_Operator.EQUALS, value));
		return this;
	}

	public virtual fflib_Criteria equalTo(String relatedField, Object value)
	{
		evaluators.add(new RelatedFieldEvaluator(relatedField, fflib_Operator.EQUALS, value));
		return this;
	}

	/**
	 * Add a not equal to criteria while comparing a fields value to a given value
	 *
	 * @param field The sObjectField to evaluate
	 * @param value The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .notEqualTo(Account.Name, 'Example')
	 *
	 * Evaluates:
	 *      Name != 'Example'
	 */
	public virtual fflib_Criteria notEqualTo(Schema.SObjectField field, Object value)
	{
		evaluators.add(new FieldEvaluator(field, fflib_Operator.NOT_EQUALS, value));
		return this;
	}

	public virtual fflib_Criteria notEqualTo(String relatedField, Object value)
	{
		evaluators.add(new RelatedFieldEvaluator(relatedField, fflib_Operator.NOT_EQUALS, value));
		return this;
	}

	/**
	 * Evaluates the stored criteria based on the given SObject
	 *
	 * @param record The SObject to evaluate
	 *
	 * @return The Boolean result of the evaluated criteria
	 */
	public virtual Boolean evaluate(Object record)
	{
		if (this.evaluators.isEmpty()) return true;

		if (this.type == FORMULA) return evaluateFormula(record);

		Boolean result = !(this.type == 'OR');
		for (Evaluator evaluator : evaluators)
		{
			Boolean evaluateResult = evaluator.evaluate(record);
			if (evaluateResult && (this.type == 'OR' || this.type == 'NONE'))
			{
				return true;
			}
			else if (!evaluateResult && this.type == 'AND')
			{
				return false;
			}
		}
		return result;
	}

	private Boolean evaluateFormula(Object record)
	{
		try
		{
				Map<Integer, Boolean> evaluatedResultByNumber = new Map<Integer, Boolean>();
				for (Integer i = 0; i < evaluators.size(); i++)
				{
					evaluatedResultByNumber.put(i, evaluators.get(i).evaluate(record));
				}
				return formulaEvaluator.evaluate(record, evaluatedResultByNumber);
		}
		catch (Exception e)
		{
			// If an error occurs during the validation,
			// just return a null value and send a warning message to the debug log;
			System.debug(
					System.LoggingLevel.WARN,
					'Criteria condition failure with error: ' + e.getMessage() + '\n' + e.getStackTraceString()
			);
			return null;
		}
	}

	/**
	 * Compares the fields values to be greater or equal to the given value
	 * Evaluates to false if the field value is null
	 *
	 * @param field The Schema.sObjectField to use its value
	 * @param value The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .greaterOrEqualTo(Account.AnnualRevenue, 54321)
	 *
	 * Evaluates:
	 *      AnnualRevenue >= 54321
	 */
	public virtual fflib_Criteria greaterOrEqualTo(Schema.SObjectField field, Object value)
	{
		evaluators.add(new FieldEvaluator(field, fflib_Operator.GREATER_THAN_OR_EQUAL_TO, value));
		return this;
	}

	public virtual fflib_Criteria greaterOrEqualTo(String relatedField, Object value)
	{
		evaluators.add(new RelatedFieldEvaluator(relatedField, fflib_Operator.GREATER_THAN_OR_EQUAL_TO, value));
		return this;
	}

	/**
	 * Compares the fields values to be greater or equal to the given value
	 * Evaluates to false if the field value is null
	 *
	 * @param field The Schema.SObjectField to use its value
	 * @param value The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .greaterThan(Account.AnnualRevenue, 54321)
	 *
	 * Evaluates:
	 *      AnnualRevenue > 54321
	 */
	public virtual fflib_Criteria greaterThan(Schema.SObjectField field, Object value)
	{
		evaluators.add(new FieldEvaluator(field, fflib_Operator.GREATER_THAN, value));
		return this;
	}
	public virtual fflib_Criteria greaterThan(String relatedField, Object value)
	{
		evaluators.add(new RelatedFieldEvaluator(relatedField, fflib_Operator.GREATER_THAN, value));
		return this;
	}

	/**
	 * Compares the fields values to be less or equal to the given value
	 * Evaluates to true if the field value is null
	 *
	 * @param field The Schema.SObjectField to use its value
	 * @param value The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .lessOrEqualTo(Account.AnnualRevenue, 54321)
	 *
	 * Evaluates:
	 *      AnnualRevenue <= 54321
	 */
	public virtual fflib_Criteria lessOrEqualTo(Schema.SObjectField field, Object value)
	{
		evaluators.add(new FieldEvaluator(field, fflib_Operator.LESS_THAN_OR_EQUAL_TO, value));
		return this;
	}
	public virtual fflib_Criteria lessOrEqualTo(String relatedField, Object value)
	{
		evaluators.add(new RelatedFieldEvaluator(relatedField, fflib_Operator.LESS_THAN_OR_EQUAL_TO, value));
		return this;
	}


	/**
	 * Compares the fields values to be greater or equal to the given value
	 * Evaluates to true if the field value is null
	 *
	 * @param field The Schema.sObjectField to use its value
	 * @param value The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .lessThan(Account.AnnualRevenue, 54321)
	 *
	 * Evaluates:
	 *      AnnualRevenue < 54321
	 */
	public virtual fflib_Criteria lessThan(Schema.SObjectField field, Object value)
	{
		evaluators.add(new FieldEvaluator(field, fflib_Operator.LESS_THAN, value));
		return this;
	}
	public virtual fflib_Criteria lessThan(String relatedField, Object value)
	{
		evaluators.add(new RelatedFieldEvaluator(relatedField, fflib_Operator.LESS_THAN, value));
		return this;
	}

	/**
	 * Checks if the given sets contains the fields values
	 *
	 * @param field The Schema.sObjectField to use its value
	 * @param values The values to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .inSet(Account.Type, new Set<Object>{'Customer', 'Competitor', 'Partner'})
	 *
	 * Evaluates:
	 *      Account.Type IN ('Customer','Competitor','Partner')
	 */
	public virtual fflib_Criteria inSet(Schema.SObjectField field, Set<Object> values)
	{
		return inSet(field, new fflib_Objects(new List<Object>(values)));
	}
	public virtual fflib_Criteria inSet(String fieldName, Set<Object> values)
	{
		return inSet(fieldName, new fflib_Objects(new List<Object>(values)));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Date> values)
	{
		return inSet(field, new fflib_Dates(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Date> values)
	{
		return inSet(fieldName, new fflib_Dates(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Datetime> values)
	{
		return inSet(field, new fflib_DateTimes(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Datetime> values)
	{
		return inSet(fieldName, new fflib_DateTimes(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Decimal> values)
	{
		return inSet(field, new fflib_Decimals(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Decimal> values)
	{
		return inSet(fieldName, new fflib_Decimals(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Double> values)
	{
		return inSet(field, new fflib_Doubles(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Double> values)
	{
		return inSet(fieldName, new fflib_Doubles(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Id> values)
	{
		return inSet(field, new fflib_Ids(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Id> values)
	{
		return inSet(fieldName, new fflib_Ids(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Integer> values)
	{
		return inSet(field, new fflib_Integers(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Integer> values)
	{
		return inSet(fieldName, new fflib_Integers(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<Long> values)
	{
		return inSet(field, new fflib_Longs(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<Long> values)
	{
		return inSet(fieldName, new fflib_Longs(values));
	}
	public fflib_Criteria inSet(Schema.SObjectField field, Set<String> values)
	{
		return inSet(field, new fflib_Strings(values));
	}
	public fflib_Criteria inSet(String fieldName, Set<String> values)
	{
		return inSet(fieldName, new fflib_Strings(values));
	}
	/**
	 * checks if the given sets contains the fields values
	 *
	 * @param field The field to use its value
	 * @param values The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .inSet(Account.Type, new Objects(new Set<Object>{'Customer', 'Competitor', 'Partner'}))
	 *
	 * Evaluates:
	 *      Account.Type IN ('Customer','Competitor','Partner')
	 */
	public fflib_Criteria inSet(Schema.SObjectField field, fflib_Objects values)
	{
		evaluators.add(new FieldSetEvaluator(field, fflib_Operator.INx, values));
		return this;
	}
	public fflib_Criteria inSet(String fieldName, fflib_Objects values)
	{
		evaluators.add(new RelatedFieldSetEvaluator(fieldName, fflib_Operator.INx, values));
		return this;
	}

	/**
	 * Checks if the given sets does not contain the fields values
	 *
	 * @param field The Schema.sObjectField to use its value
	 * @param values The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .notInSet(Account.Type, new Set<Object>{'Customer', 'Competitor', 'Partner'})
	 *
	 * Evaluates:
	 *      Account.Type NOT IN ('Customer','Competitor','Partner')
	 */
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Date> values)
	{
		return notInSet(field, new fflib_Dates(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Date> values)
	{
		return notInSet(fieldName, new fflib_Dates(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Datetime> values)
	{
		return notInSet(field, new fflib_DateTimes(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Datetime> values)
	{
		return notInSet(fieldName, new fflib_DateTimes(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Decimal> values)
	{
		return notInSet(field, new fflib_Decimals(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Decimal> values)
	{
		return notInSet(fieldName, new fflib_Decimals(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Double> values)
	{
		return notInSet(field, new fflib_Doubles(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Double> values)
	{
		return notInSet(fieldName, new fflib_Doubles(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Id> values)
	{
		return notInSet(field, new fflib_Ids(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Id> values)
	{
		return notInSet(fieldName, new fflib_Ids(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Integer> values)
	{
		return notInSet(field, new fflib_Integers(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Integer> values)
	{
		return notInSet(fieldName, new fflib_Integers(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Long> values)
	{
		return notInSet(field, new fflib_Longs(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Long> values)
	{
		return notInSet(fieldName, new fflib_Longs(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<String> values)
	{
		return notInSet(field, new fflib_Strings(values));
	}
	public fflib_Criteria notInSet(String fieldName, Set<String> values)
	{
		return notInSet(fieldName, new fflib_Strings(values));
	}
	public fflib_Criteria notInSet(Schema.SObjectField field, Set<Object> values)
	{
		return notInSet(field, new fflib_Objects(new List<Object>(values)));
	}
	public fflib_Criteria notInSet(String fieldName, Set<Object> values)
	{
		return notInSet(fieldName, new fflib_Objects(new List<Object>(values)));
	}

	/**
	 * checks if the given sets contains the fields values
	 *
	 * @param field The field to use its value
	 * @param values The value to be compared to the fields value
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @example
	 *  new fflib_Criteria()
	 *          .notInSet(Account.Type, new Objects(new Set<Object>{'Customer', 'Competitor', 'Partner'}))
	 *
	 * Evaluates:
	 *      Account.Type NOT IN ('Customer','Competitor','Partner')
	 */
	public fflib_Criteria notInSet(Schema.SObjectField field, fflib_Objects values)
	{
		evaluators.add(new FieldSetEvaluator(field, fflib_Operator.NOT_IN, values));
		return this;
	}
	public fflib_Criteria notInSet(String fieldName, fflib_Objects values)
	{
		evaluators.add(new RelatedFieldSetEvaluator(fieldName, fflib_Operator.NOT_IN, values));
		return this;
	}

	/**
	 * Generates the SOQL equivalent of the criteria provided
	 *
	 * @return The "where" part in the SOQL statement
	 */
	public virtual String toSOQL()
	{
		if (this.evaluators.isEmpty()) return '';

		if (this.type == FORMULA) return formulaToSOQL();

		String result = '';
		for (Evaluator evaluator : this.evaluators)
		{
			if (result != '')
			{
				result += ' ' + this.type + ' ';
			}
			result += evaluator.toSOQL();
		}

		if (this.embraced) result = '(' + result + ')';

		return result;
	}

	private String formulaToSOQL()
	{
		Map<Integer, String> queryByNumber = new Map<Integer, String>();
		for (Integer i = 0; i < this.evaluators.size(); i++)
		{
			queryByNumber.put(i, evaluators.get(i).toSOQL());
		}

		String result = this.formulaEvaluator
				.toSOQL(queryByNumber);
		return result.substring(1, result.length() - 1);
	}

	private static String operatorToString(fflib_Operator operator)
	{
		if (operator == fflib_Operator.EQUALS)
			return '=';
		else if (operator == fflib_Operator.NOT_EQUALS)
			return '!=';
		else if (operator == fflib_Operator.LESS_THAN)
			return '<';
		else if (operator == fflib_Operator.LESS_THAN_OR_EQUAL_TO)
			return '<=';
		else if (operator == fflib_Operator.GREATER_THAN)
			return '>';
		else if (operator == fflib_Operator.GREATER_THAN_OR_EQUAL_TO)
			return '>=';
		else if (operator == fflib_Operator.LIKEx)
			return 'LIKE';
		else if (operator == fflib_Operator.INx)
			return 'IN';
		else if (operator == fflib_Operator.NOT_IN)
			return 'NOT IN';
		else if (operator == fflib_Operator.INCLUDES)
			return 'INCLUDES';
		else if (operator == fflib_Operator.EXCLUDES)
			return 'EXCLUDES';
		else
				return null;
	}

	/**
	 * Adds braces to the condition when generated to SOQL
	 *
	 * @param embraced Braces will be added if set to TRUE
	 */
	private void setEmbraced(Boolean embraced)
	{
		this.embraced = embraced;
	}

	/**
	 * @param value The value to convert
	 *
	 * @return Returns the given value converted to literal string
	 */
	private static String toLiteral(final Object value)
	{
		if (value == null) return 'null';

		if (value instanceof String || value instanceof Id)
		{
			String manipulated = (String) value;
			return '\'' + manipulated + '\'';
		}
		else if (value instanceof Boolean ||
				value instanceof Integer ||
				value instanceof Long ||
				value instanceof Double ||
				value instanceof Decimal)
		{
			return '' + value;
		}
		else if (value instanceof Date)
		{
			return '' + Datetime.newInstance(((Date) value).year(), ((Date) value).month(), ((Date) value).day()).format('yyyy-MM-dd');
		}
		else if (value instanceof Datetime)
		{
			return '' + ((Datetime) value).format('yyyy-MM-dd') + 'T' + ((Datetime) value).format('HH:mm:ss') + 'Z';
		}

		throw new CriteriaException(
				'invalid value; value must a primitive type (String|Id|Boolean|Integer|Long|Double|Decimal|Date|Datetime)'
		);
	}

	/**
	 * @param values The values to convert
	 *
	 * @return Returns the given values converted to literal string separated by a comma
	 */
	private static String toLiteral(final fflib_Objects values)
	{
		if (values.isEmpty()) return '';

		String result = '(';
		for (Object obj : values.getObjects())
		{
			if (result != '(')
			{
				result += ',';
			}
			result += toLiteral(obj);
		}
		return result + ')';
	}

	private interface Evaluator
	{
		Boolean evaluate(Object obj);
		String toSOQL();
	}

	/**
	 * Generic criteria handler for comparing against sets
	 */
	private virtual class FieldSetEvaluator implements Evaluator
	{
		private Schema.SObjectField sObjectField;
		private fflib_Objects values;
		private fflib_Operator operator;

		public FieldSetEvaluator(Schema.SObjectField sObjectField, fflib_Operator operator, fflib_Objects values)
		{
			this.sObjectField = sObjectField;
			this.values = values;
			this.operator = operator;
		}

		public Boolean evaluate(Object record)
		{
			if (!(record instanceof SObject))
				throw new CriteriaException('Only records of type SObject can have fieldCriteria');

			Object fieldValue = ((SObject) record).get(this.sObjectField);
			Boolean isIn = this.values.contains(fieldValue);
			return ((operator == fflib_Operator.INx && isIn) || (operator == fflib_Operator.NOT_IN && !isIn));
		}

		public String toSOQL()
		{
			return String.format(
					'{0} {1} {2}',
					new List<String>
					{
							this.sObjectField.getDescribe().getName(),
							operatorToString(this.operator),
							toLiteral(this.values)
					}
			);
		}
	}

	/**
	 * Generic field Evaluator
	 */
	private class FieldEvaluator implements Evaluator
	{
		private Schema.SObjectField sObjectField;
		private Object value;
		private fflib_Operator operator;

		public FieldEvaluator(Schema.SObjectField sObjectField, fflib_Operator operator, Object value)
		{
			this.sObjectField = sObjectField;
			this.value = value;
			this.operator = operator;
		}

		public Boolean evaluate(Object record)
		{
			if (!(record instanceof SObject))
				throw new CriteriaException('Only records of type SObject can have fieldCriteria');

			Object fieldValue = ((SObject) record).get(this.sObjectField);

			return fflib_Comparator.compareTo(fieldValue, operator, this.value);
		}

		public String toSOQL()
		{
			return String.join(
					new List<String>
					{
							this.sObjectField.getDescribe().getName(),
							operatorToString(this.operator),
							toLiteral(this.value)
					},
					''
			);
		}
	}

	private abstract class AbstractRelatedFieldEvaluator implements Evaluator
	{
		protected String fieldName;
		protected fflib_Operator operator;

		protected Object getFieldValue(Object record)
		{
			if (!fieldName.contains('.'))
			{
				return ((SObject) record).get(fieldName);
			}

			List<String> fieldPath = fieldName.split('\\.');
			SObject relatedObject = (SObject) record;
			for (Integer i = 0; i < fieldPath.size() - 1; i++)
			{
				relatedObject = relatedObject.getSObject(fieldPath.get(i));
			}
			return relatedObject.get(fieldPath.get(fieldPath.size()-1));
		}

	}

	private class RelatedFieldEvaluator extends AbstractRelatedFieldEvaluator
	{
		private Object value;

		public RelatedFieldEvaluator(String fieldName, fflib_Operator operator, Object value)
		{
			this.fieldName = fieldName;
			this.value = value;
			this.operator = operator;
		}

		public Boolean evaluate(Object record)
		{
			if (!(record instanceof SObject))
				throw new CriteriaException('Only records of type SObject can have fieldCriteria');

			Object fieldValue = getFieldValue(record);

			return fflib_Comparator.compareTo(fieldValue, operator, this.value);
		}

		public String toSOQL()
		{
			return String.join(
					new List<String>
					{
							this.fieldName,
							operatorToString(this.operator),
							toLiteral(this.value)
					},
					''
			);
		}
	}

	private class RelatedFieldSetEvaluator extends AbstractRelatedFieldEvaluator
	{
		private fflib_Objects values;

		public RelatedFieldSetEvaluator(String fieldName, fflib_Operator operator, fflib_Objects values)
		{
			this.fieldName = fieldName;
			this.values = values;
			this.operator = operator;
		}

		public Boolean evaluate(Object record)
		{
			if (!(record instanceof SObject))
				throw new CriteriaException('Only records of type SObject can have fieldCriteria');

			Object fieldValue = getFieldValue(record);
			Boolean isIn = this.values.contains(fieldValue);
			return ((operator == fflib_Operator.INx && isIn) || (operator == fflib_Operator.NOT_IN && !isIn));
		}

		public String toSOQL()
		{
			return String.format(
					'{0} {1} {2}',
					new List<String>
					{
							this.fieldName,
							operatorToString(this.operator),
							toLiteral(this.values)
					}
			);
		}
	}

	private class PropertyEvaluator implements Evaluator
	{
		private Object property;
		private Object value;
		private fflib_Operator operator;

		public PropertyEvaluator(Object property, fflib_Operator operator, Object value)
		{
			this.property = property;
			this.value = value;
			this.operator = operator;
		}

		public Boolean evaluate(Object dto)
		{
			Object fieldValue = getX(dto, this.property);
			return fflib_Comparator.compareTo(fieldValue, operator, this.value);
		}

		public String toSOQL()
		{
			throw new CriteriaException('Property Objects cannot be used in SOQL queries');
		}

		// todo - should be moved one abstraction level higher, to prevent it from serializing multiple times (for each condition)
		private Object getX(Object dto, Object propertyName)
		{
			String serializedJSON = JSON.serialize(dto);
			Map<Object, Object> valueByPropertyName =
					(Map<Object, Object>) JSON.deserializeUntyped(serializedJSON);
			return valueByPropertyName.get(propertyName);
		}
	}

	/**
	 * Class exception handler
	 */
	public class CriteriaException extends Exception
	{
	}
}