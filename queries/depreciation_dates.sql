WITH depreciation_dates as(
  SELECT p.id,
    c.calendar_at AS depreciation_month,
    c.year as period_year,
    case
      when year = Date_part('month', payment_date + interval '10 years')
      and month = date_part('month', payment_date) then 1
      when month = 12 then 1
      else 0
    end as flag_1_year,
    p.amount amount
  FROM calendar_month c -- calendar_month view created instead of calendar. Calendar populates too many rows due to daily grainularity whereas the task expects monthly grainularity. Calendar.sql also creates the view.
    CROSS JOIN payments p
  WHERE p.payment_type = 'equipment'
    AND c.calendar_at >= p.payment_date
    AND c.calendar_at <= p.payment_date + interval '10 years'
    AND id = 66
)
Select *
FROM depreciation_dates