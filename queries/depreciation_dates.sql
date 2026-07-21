-- Equipment depreciation schedule (straight-line, 10 years / 120 months)
--
-- One row per month for each equipment purchase, from the month after purchase
-- through the 10-year mark. Uses the calendar_month view (monthly grain) so no
-- day-level filtering is needed.
--
--   installments  = amount / 120        (monthly depreciation)
--   flag_1_year   = 1 on every 12th installment (each 12-month anniversary)
--   total_amount  = running accumulated depreciation (rounded for display)
--
-- Returns 360 rows: 3 equipment payments x 120 months.

WITH depreciation_dates AS (
  SELECT
    p.id,
    c.calendar_at AS depreciation_month,
    c.year        AS period_year,
    CASE WHEN row_number() OVER (PARTITION BY p.id ORDER BY c.calendar_at) % 12 = 0
         THEN 1 ELSE 0 END                        AS flag_1_year,
    p.amount,
    p.amount / count(*) OVER (PARTITION BY p.id)   AS installments
  FROM calendar_month c
  CROSS JOIN payments p
  WHERE p.payment_type = 'equipment'
    AND c.calendar_at >= p.payment_date
    AND c.calendar_at <= p.payment_date + interval '10 years'
),
depreciation_sum AS (
  SELECT *,
    round(sum(installments) OVER (PARTITION BY id ORDER BY depreciation_month), 2) AS total_amount
  FROM depreciation_dates
)
SELECT * FROM depreciation_sum;
