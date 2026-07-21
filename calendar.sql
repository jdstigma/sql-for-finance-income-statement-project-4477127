-- ============================================================================
-- Calendar / Date dimension  (PostgreSQL)
-- Range: 2000-01-01 through 2049-12-31  (50-year period)
-- Date column: calendar_at
--
-- Builds two objects:
--   * calendar        - daily grain, one row per day (for exact-date joins to
--                        payment_date, loan_at, sale_day, etc.)
--   * calendar_month  - VIEW, one row per month (the 1st), for period schedules
--                        like depreciation - cross join it directly, no filter.
-- Re-runnable: drops and rebuilds each time.
-- ============================================================================

-- Drop the view first: it depends on calendar, so it would block DROP TABLE.
DROP VIEW  IF EXISTS calendar_month;
DROP TABLE IF EXISTS calendar;

CREATE TABLE calendar (
    date_key              integer     PRIMARY KEY,   -- YYYYMMDD, e.g. 20210131
    calendar_at           date        NOT NULL UNIQUE,
    year                  smallint    NOT NULL,
    quarter               smallint    NOT NULL,       -- 1..4
    quarter_name          text        NOT NULL,       -- 'Q1'
    month                 smallint    NOT NULL,       -- 1..12
    month_name            text        NOT NULL,       -- 'January'
    month_short           text        NOT NULL,       -- 'Jan'
    year_month            text        NOT NULL,       -- '2021-01'
    day_of_month          smallint    NOT NULL,       -- 1..31
    day_of_year           smallint    NOT NULL,       -- 1..366
    day_of_week           smallint    NOT NULL,       -- ISO: 1=Mon .. 7=Sun
    day_name              text        NOT NULL,       -- 'Monday'
    day_short             text        NOT NULL,       -- 'Mon'
    iso_week              smallint    NOT NULL,        -- ISO week number 1..53
    iso_year              smallint    NOT NULL,        -- ISO week-numbering year
    is_weekend            boolean     NOT NULL,
    first_day_of_month    date        NOT NULL,
    last_day_of_month     date        NOT NULL,
    is_last_day_of_month  boolean     NOT NULL
);

INSERT INTO calendar
SELECT
    to_char(d, 'YYYYMMDD')::integer                       AS date_key,
    d::date                                               AS calendar_at,
    EXTRACT(YEAR    FROM d)::smallint                     AS year,
    EXTRACT(QUARTER FROM d)::smallint                     AS quarter,
    'Q' || EXTRACT(QUARTER FROM d)::text                  AS quarter_name,
    EXTRACT(MONTH   FROM d)::smallint                     AS month,
    to_char(d, 'FMMonth')                                 AS month_name,
    to_char(d, 'Mon')                                     AS month_short,
    to_char(d, 'YYYY-MM')                                 AS year_month,
    EXTRACT(DAY     FROM d)::smallint                     AS day_of_month,
    EXTRACT(DOY     FROM d)::smallint                     AS day_of_year,
    EXTRACT(ISODOW  FROM d)::smallint                     AS day_of_week,
    to_char(d, 'FMDay')                                   AS day_name,
    to_char(d, 'Dy')                                      AS day_short,
    EXTRACT(WEEK    FROM d)::smallint                     AS iso_week,
    EXTRACT(ISOYEAR FROM d)::smallint                     AS iso_year,
    EXTRACT(ISODOW  FROM d) IN (6, 7)                     AS is_weekend,
    date_trunc('month', d)::date                          AS first_day_of_month,
    (date_trunc('month', d) + interval '1 month - 1 day')::date
                                                          AS last_day_of_month,
    d::date = (date_trunc('month', d) + interval '1 month - 1 day')::date
                                                          AS is_last_day_of_month
FROM generate_series(
        '2000-01-01'::date,
        '2049-12-31'::date,
        interval '1 day'
     ) AS gs(d);

-- Helpful secondary index for range scans / joins on the actual date.
CREATE INDEX ix_calendar_calendar_at ON calendar (calendar_at);

-- Monthly-grain companion: one row per month (the 1st of each month), 600 rows
-- over the 50-year span. Use this for period schedules so you don't have to
-- filter the daily table. Example - 10-year monthly depreciation of equipment:
--
--   SELECT p.id, p.payment_date, c.calendar_at AS depreciation_month
--   FROM   calendar_month c
--   CROSS JOIN payments p
--   WHERE  p.payment_type = 'equipment'
--     AND  c.calendar_at >= p.payment_date
--     AND  c.calendar_at <= p.payment_date + interval '10 years';
--
CREATE VIEW calendar_month AS
SELECT *
FROM calendar
WHERE day_of_month = 1;

-- Quick sanity checks:
--   SELECT count(*) FROM calendar;        -- 18263 daily rows (2000-2049)
--   SELECT count(*) FROM calendar_month;  -- 600 monthly rows
