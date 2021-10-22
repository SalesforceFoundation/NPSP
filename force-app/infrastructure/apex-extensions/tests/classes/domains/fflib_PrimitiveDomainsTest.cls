/**
 * File Name: DatesTest
 * @description Unit test class for Primitive domains
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
@IsTest(IsParallel=true)
private class fflib_PrimitiveDomainsTest
{
    @IsTest
    static void testDates()
    {
        final Set<Date> dateSet = new Set<Date>
        {
                Date.newInstance(2020, 02, 02),
                Date.newInstance(2021, 02, 01),
                Date.newInstance(2022, 02, 02)
        };

        final List<Date> dateList = new List<Date>
        {
                Date.newInstance(2020, 02, 02),
                Date.newInstance(2021, 02, 01),
                Date.newInstance(2022, 02, 02)
        };

        fflib_Dates datesA = new fflib_Dates(dateSet);
        fflib_Dates DatesB = new fflib_Dates(dateList);
        fflib_Dates DatesC = new fflib_Dates((List<Object>) dateList);

        System.assert(datesA.getDateSet().containsAll(DatesB.getDates()));
        System.assert(datesA.getDateSet().containsAll(DatesC.getDates()));
    }

    @IsTest
    static void testDateTimes()
    {
        final Set<Datetime> dateSet = new Set<Datetime>
        {
                Datetime.newInstance(2020, 02, 02, 01, 00, 00),
                Datetime.newInstance(2021, 02, 01, 01, 00, 00),
                Datetime.newInstance(2022, 02, 02, 01, 00, 00)
        };

        final List<Datetime> dateList = new List<Datetime>
        {
                Datetime.newInstance(2020, 02, 02, 01, 00, 00),
                Datetime.newInstance(2021, 02, 01, 01, 00, 00),
                Datetime.newInstance(2022, 02, 02, 01, 00, 00)
        };

        fflib_DateTimes datetimeA = new fflib_DateTimes(dateSet);
        fflib_DateTimes datetimeB = new fflib_DateTimes(dateList);
        fflib_DateTimes datetimeC = new fflib_DateTimes((List<Object>) dateList);

        System.assert(datetimeA.getDateTimeSet().containsAll(datetimeB.getDateTimes()));
        System.assert(datetimeA.getDateTimeSet().containsAll(datetimeC.getDateTimes()));
    }

    @IsTest
    static void testDecimal()
    {
        final Set<Decimal> dataSet = new Set<Decimal> {5.5, 1.1, -1.1, -2.7};
        final List<Decimal> dataList = new List<Decimal> {5.5, 1.1, -1.1, -2.7};

        fflib_Decimals domainA = new fflib_Decimals(dataSet);
        fflib_Decimals domainB = new fflib_Decimals(dataList);
        fflib_Decimals domainC = new fflib_Decimals((List<Object>) dataList);

        System.assert(domainA.getDecimalSet().containsAll(domainB.getDecimals()));
        System.assert(domainA.getDecimalSet().containsAll(domainC.getDecimals()));
    }

    @IsTest
    static void testDoubles()
    {
        final Set<Double> dataSet = new Set<Double> {1261992, 3.14159265};
        final List<Double> dataList = new List<Double> {1261992, 3.14159265};

        fflib_Doubles domainA = new fflib_Doubles(dataSet);
        fflib_Doubles domainB = new fflib_Doubles(dataList);
        fflib_Doubles domainC = new fflib_Doubles((List<Object>) dataList);

        System.assert(domainA.getDoubleSet().containsAll(domainB.getDoubles()));
        System.assert(domainA.getDoubleSet().containsAll(domainC.getDoubles()));
    }

    @IsTest
    static void testIds()
    {
        final Set<Id> dataSet = new Set<Id>
        {
                fflib_IDGenerator.generate(Schema.Account.SObjectType),
                fflib_IDGenerator.generate(Schema.Account.SObjectType),
                fflib_IDGenerator.generate(Schema.Account.SObjectType)
        };

        fflib_Ids domainA = new fflib_Ids(dataSet);
        fflib_Ids domainB = new fflib_Ids(new List<Id>(dataSet));
        fflib_Ids domainC = new fflib_Ids((List<Object>) new List<Id>(dataSet));

        System.assert(domainA.getIds().containsAll(domainB.getIdList()));
        System.assert(domainA.getIds().containsAll(domainC.getIdList()));
    }

    @IsTest
    static void testIds_Objects()
    {
        final fflib_Objects data = new fflib_Objects(new List<Id>(
                new Set<Id>
        {
                fflib_IDGenerator.generate(Schema.Account.SObjectType),
                fflib_IDGenerator.generate(Schema.Account.SObjectType),
                fflib_IDGenerator.generate(Schema.Account.SObjectType)
        }));

        fflib_Ids domainA = new fflib_Ids(data);

        System.assert(domainA.getIds().containsAll((List<Id>) data.getObjects()));
    }

    @IsTest
    static void testIntegers()
    {
        final Set<Integer> dataSet = new Set<Integer> {1261, 31415};

        fflib_Integers domainA = new fflib_Integers(dataSet);
        fflib_Integers domainB = new fflib_Integers(new List<Integer>(dataSet));
        fflib_Integers domainC = new fflib_Integers((List<Object>) new List<Integer>(dataSet));

        System.assert(domainA.getIntegerSet().containsAll(domainB.getIntegers()));
        System.assert(domainA.getIntegerSet().containsAll(domainC.getIntegers()));
    }

    @IsTest
    static void testLongs()
    {
        final Set<Long> dataSet = new Set<Long> {1261, 31415};

        fflib_Longs domainA = new fflib_Longs(dataSet);
        fflib_Longs domainB = new fflib_Longs(new List<Long>(dataSet));
        fflib_Longs domainC = new fflib_Longs((List<Object>) new List<Long>(dataSet));

        System.assert(domainA.getLongSet().containsAll(domainB.getLongs()));
        System.assert(domainA.getLongSet().containsAll(domainC.getLongs()));
    }

    @IsTest
    static void testStrings()
    {
        final Set<String> dataSet = new Set<String> {'Hello', 'World'};

        fflib_Strings domainA = new fflib_Strings(dataSet);
        fflib_Strings domainB = new fflib_Strings(new List<String>(dataSet));
        fflib_Strings domainC = new fflib_Strings((List<Object>) new List<String>(dataSet));

        System.assert(domainA.getStringSet().containsAll(domainB.getStrings()));
        System.assert(domainA.getStringSet().containsAll(domainC.getStrings()));
    }
}