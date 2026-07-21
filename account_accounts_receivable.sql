Create materialized view account_accounts_receivable as
SELECT date_part ('year', payment_at) as period_year,
  'Accounts Receivable' as account,
  sum(price * quantity) as total_amount
From sales
where payment_method <> 'cash'
  AND date_part('month', payment_at) = 12
group by date_part ('year', payment_at)