# Business insights

**Business:** a UK online retailer of all-occasion giftware (UCI Online Retail II, December 2009 to 9 December 2011).
**Headline measure:** Net Product Revenue = Sale + Cancellation rows = **£18,981,171.52** (39,516 orders).
Every number below was produced in MySQL and reproduced independently in Power BI (see `dax_measures.md`).

How to read this document: each insight is split into **Fact** (measured), **Interpretation** (my reading, which the data cannot prove), and **Potential action** (a suggestion, not a certainty). Anything the data cannot answer is listed at the end.

## Summary

| # | Insight | Key number |
|---|---|---|
| 1 | Revenue peaks in autumn, not December | Sep-Nov 2010 = 36% of 2010 net revenue |
| 2 | Growth is modest and noisy month to month | Jan-Nov 2011 vs 2010: +2.19% |
| 3 | The typical order is about £300, not £500 | Median £301.80 vs mean £498.55 |
| 4 | Cancellations are small, but two orders distort the rate | 3.65% (about 2.4% without two reversed orders) |
| 5 | The business depends on the UK | UK = 85.46% of net product revenue |
| 6 | International revenue is a few key accounts | Netherlands 95.8% one customer |
| 7 | A loyal core of repeat buyers carries revenue | 864 customers (15%) = 64.5% of identified sale revenue |
| 8 | Product revenue is spread across a long tail | Top 10 products = 7.62% |
| 9 | 13.5% of revenue has no customer ID | £2,569,366.77 |

## 1. Revenue peaks in autumn, not December

- **Fact:** September to November 2010 produced £3,317,127.26, which is **36%** of 2010 net product revenue (£9,167,334.85). November is the highest month in both years: £1,400,559.24 (2010) and £1,432,697.49 (2011). November 2010 was about 2.2 times the January-August 2010 monthly average (about £636,000). December 2010 (£760,323.91) was 45.7% below November 2010.
- **Interpretation:** the year is front-loaded into three months. The cause of the December drop cannot be seen in this data.
- **Potential action:** plan stock and marketing around September to November, and ask the operations team why December falls so sharply.

## 2. Growth is modest and noisy

- **Fact:** January to November 2011 net revenue was £8,590,935.96 against £8,407,010.94 for the same months of 2010: **+2.19%**. Single months ranged from -24.42% (April 2011) to +20.37% (May 2011). December 2011 covers only 1-9 December and is excluded from like-for-like comparisons.
- **Interpretation:** two years of data cannot separate a trend from noise.
- **Potential action:** do not react to single-month changes. Build the comparison over longer periods as more data arrives.

## 3. The typical order is about £300

- **Fact:** mean order value £498.55 (Gross Sales / 39,516 sale invoices), median **£301.80**. The mean is about 65% above the median.
- **Interpretation:** a minority of very large (probably wholesale) orders lifts the mean. No field flags wholesalers, so this is a reading, not a measurement.
- **Potential action:** report the median as the "typical order" next to the mean.

## 4. Cancellations are small, but two orders distort the rate

- **Fact:** cancellations total £719,677.94, which is **3.65%** of Gross Sales (£19,700,849.46). Two orders that were cancelled within minutes (£168,469.60 and £77,183.60) account for 1.2 percentage points: without them the rate is about **2.4%**. In total, 1,429 sale lines worth £364,141.55 (1.8% of sale revenue) were cancelled by the same customer within 24 hours (a lower bound: exact-quantity matches only).
- **Interpretation:** most of the cancellation rate is ordinary cancellation. The two very large reversals look like order-entry errors, but the data cannot show why they happened.
- **Potential action:** ask the team how the two largest orders arose, and report the cancellation rate with and without same-day reversals.

## 5. The business depends on the UK

- **Fact:** the UK produces £16,220,998.80, which is **85.46%** of net product revenue. All other countries together are £2,760,172.72 (14.5%). Only five countries exceed 1% of revenue: UK, Ireland (3.18%), Netherlands (2.88%), Germany (1.98%), France (1.55%).
- **Interpretation:** the business is a UK business with small export sales.
- **Potential action:** treat any UK-specific disruption as a risk to almost all revenue.

## 6. International revenue is a few key accounts

- **Fact:** one customer (14646) is **95.8%** of the Netherlands' identified revenue. One customer (12415) is 86.0% of Australia's. Two customers (14156 and 14911) are 98.0% of Ireland's (£556,563.03 of £567,842.74). In Germany (8.9%) and France (11.0%) the largest customer is far smaller.
- **Interpretation:** the Netherlands, Australia, and Ireland are better described as a handful of accounts than as markets.
- **Potential action:** treat those accounts as key accounts. Before planning international growth, look at Germany and France, where revenue comes from more buyers.

## 7. A loyal core of repeat buyers

- **Fact:** **72.35%** of customers placed two or more orders (4,234 of 5,852). The 864 customers with 11 or more orders (14.8% of customers) produce **64.5%** of sale revenue from identified customers. Customers who ordered once are 27.6% of customers but only 3.3% of revenue. The top 10 customers produce £2,660,456.26: 16.21% of identified revenue and 14.0% of all net product revenue, and all ten were still buying in the last weeks of the data.
- **Interpretation:** revenue depends more on a middle-to-top tier of repeat buyers than on the top 10 alone. The two-year window means some one-time buyers are simply new, so this is not a retention rate.
- **Potential action:** put retention effort on customers with six or more orders. Losing the top 10 would remove about 14% of revenue.

## 8. Product revenue is spread across a long tail

- **Fact:** the top 10 products (by stock code) produce £1,445,676.85, which is **7.62%** of net product revenue. The largest, REGENCY CAKESTAND 3 TIER, is 1.66%. There are about 5,000 product codes.
- **Interpretation:** no single product is critical. Revenue rank and unit rank differ: high-priced items lead on revenue, cheap items on units.
- **Potential action:** stocking decisions need a full cumulative-share (ABC) analysis, not a top-10 list.

## 9. 13.5% of revenue has no customer ID

- **Fact:** £2,569,366.77 (13.54%) of net product revenue has no customer ID (22.5% of rows), and about 97.6% of it is UK revenue.
- **Interpretation:** guest or unregistered purchases would be one explanation, but the data cannot confirm it.
- **Potential action:** ask how orders without a customer ID arise. Customer measures cover 86.5% of revenue.

## Why the data cleaning mattered

A plain sum of quantity times price over every row gives £18,909,762.12, which is £71,409.40 lower than Net Product Revenue. The raw table mixes real sales with cancellations, postage, fees, bad-debt entries, stock write-offs, gift vouchers, and test entries. Without classifying rows (Cleaning_Log R01-R17), a dashboard would have reported wrong revenue and an inflated count of units, and one order of 80,995 units would have distorted the average order value.

## Assumption verified: price is a unit price

On three products (13,720 sale lines), the average price falls as the quantity per line rises (for example 85099B: £3.03 for one unit, £1.83 for 25 or more). A line total would rise with quantity, so the evidence supports reading `Price` as a unit price. It is verified on three products, not on every product.

## What this data cannot answer

- **Profit or margin:** there is no cost data.
- **Delivery performance and returns reasons:** there are no shipping or reason fields.
- **Customer satisfaction:** there are no reviews.
- **Wholesale vs retail:** no field identifies the customer type.
- **Product categories:** there is no category field, and any grouping would be an assumption.
- **Customer tenure:** the data starts on 1 December 2009, so "first purchase" means "first seen here".
- **Sales channel:** a few rows (for example "AMAZON FEE") suggest marketplace sales, but the data has no channel field.
- **Why** the December drop, the April 2011 dip, or the two giant orders happened.
