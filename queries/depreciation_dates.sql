WITH depreciation_dates as(
  SELECT id,
    payment_date,
    calendar_at,
    year as period_year
  From calendar
    Cross JOIN payments
  Where calendar_at >= payment_date
    AND calendar_at <= payment_date + interval '10 years'
    AND payment_type = 'equipment'
)
Select *
FROM depreciation_dates