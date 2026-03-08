# DAU,WAU,MAU 
SELECT dt,view_user_cnt AS dau FROM ecommerce.dm_user_behavior_daily ORDER BY dt;
SELECT dt,view_user_cnt AS wau FROM ecommerce.dm_user_behavior_weekly  where dt>'2019-10-01' ORDER BY dt;
SELECT dt,view_user_cnt AS mau FROM ecommerce.dm_user_behavior_montly ORDER BY dt;

# 월별 코호트 리텐션
-- 첫 구매월 이후 다른 달에 한번이라도 구매하면 재구매로 정의
with tep_table as
(with first_purchase as (select user_id, min(format_date('%Y-%m-01',event_time))first_purchase from ecommerce.complete_purchase group by user_id)
,purchase_table as( select distinct user_id, format_date('%Y-%m-%d',event_time)purchase_date from ecommerce.complete_purchase)
select purchase_table.user_id, purchase_date , first_purchase.first_purchase from purchase_table join first_purchase on purchase_table.user_id = first_purchase.user_id
order by purchase_date )

select first_purchase, count(distinct user_id)month0,
  COUNT(DISTINCT CASE WHEN FORMAT_DATE('%Y-%m-01', DATE_ADD(PARSE_DATE('%Y-%m-%d', first_purchase), INTERVAL 1 MONTH)) = FORMAT_DATE('%Y-%m-01', PARSE_DATE('%Y-%m-%d', purchase_date)) THEN user_id END) AS month1,
       COUNT(DISTINCT CASE 
WHEN FORMAT_DATE('%Y-%m-01', DATE_ADD(PARSE_DATE('%Y-%m-%d', first_purchase), INTERVAL 2 MONTH)) = FORMAT_DATE('%Y-%m-01', PARSE_DATE('%Y-%m-%d', purchase_date)) THEN user_id 
 END) AS month2,
       COUNT(DISTINCT CASE 
WHEN FORMAT_DATE('%Y-%m-01', DATE_ADD(PARSE_DATE('%Y-%m-%d', first_purchase), INTERVAL 3 MONTH)) = FORMAT_DATE('%Y-%m-01', PARSE_DATE('%Y-%m-%d', purchase_date)) 
 THEN user_id 
 END) AS month3,
       COUNT(DISTINCT CASE 
 WHEN FORMAT_DATE('%Y-%m-01', DATE_ADD(PARSE_DATE('%Y-%m-%d', first_purchase), INTERVAL 4 MONTH)) = FORMAT_DATE('%Y-%m-01', PARSE_DATE('%Y-%m-%d', purchase_date)) 
      THEN user_id 
     END) AS month4
from tep_table
group by first_purchase 
order by first_purchase;


# 신규 구매, 재구매 건수 월별
-- 재구매 유저는 첫 구매월 이후 다른 월에 산사람 + 첫 구매월 이지만 동일 달 다른 날 또 산사람
WITH daily AS (
  SELECT DISTINCT
    user_id,
    DATE(event_time) AS purchase_date,
    DATE_TRUNC(DATE(event_time), MONTH) AS purchase_month
  FROM ecommerce.complete_purchase
),
first_month AS (
  SELECT
    user_id,
    MIN(purchase_month) AS first_purchase_month
  FROM daily
  GROUP BY user_id
),
user_month AS (
  SELECT
    d.user_id,
    d.purchase_month,
    f.first_purchase_month,
    COUNT(DISTINCT d.purchase_date) AS active_purchase_days
  FROM daily d
  JOIN first_month f USING (user_id)
  GROUP BY d.user_id, d.purchase_month, f.first_purchase_month
)
SELECT
  purchase_month,

  COUNT(DISTINCT CASE
    WHEN purchase_month = first_purchase_month THEN user_id
  END) AS first_buyers,

  COUNT(DISTINCT CASE
    WHEN purchase_month > first_purchase_month
      OR (purchase_month = first_purchase_month AND active_purchase_days >= 2)
    THEN user_id
  END) AS repeat_buyers

FROM user_month
GROUP BY purchase_month
ORDER BY purchase_month;

# 주별 pv(view_cnt) - uv(view_user_cnt)
select view_cnt,view_user_cnt from ecommerce.dm_user_behavior_weekly;

# 월별 매출액
select datetime_trunc(event_time,MONTH) as month,ROUND(sum(price)) from ecommerce.complete_purchase group by month order by month;

# CVR(장바구니 담기- 결제전환율)
with a as (select format_date('%Y-%m', event_time) year_month,user_id from ecommerce.add_to_cart group by year_month,user_id
),
b as (select format_date('%Y-%m', event_time) year_month,user_id from ecommerce.complete_purchase group by year_month,user_id order by year_month)

select a.year_month,count(distinct a.user_id)add_cart , count(distinct b.user_id)purchase, 
ROUND((count(distinct b.user_id)/count(distinct a.user_id))*100)CVR

from a left join b on a.user_id=b.user_id and a.year_month = b.year_month group by a.year_month  order by a.year_month ;

# 월별 TOP3  카테고리 매출액
SELECT * FROM (
  SELECT format_date('%Y-%m', event_time) AS year_month, 
         SUBSTR(CAST(category_id AS STRING), 10) AS modified_category_id, 
         ROUND(SUM(price)) AS revenue 
  FROM ecommerce.complete_purchase 
  GROUP BY year_month, category_id 
  HAVING year_month = '2019-10' 
  ORDER BY revenue DESC 
  LIMIT 3
)
UNION ALL
SELECT * FROM (
  SELECT format_date('%Y-%m', event_time) AS year_month, 
         SUBSTR(CAST(category_id AS STRING), 10) AS modified_category_id, 
         ROUND(SUM(price)) AS revenue 
  FROM ecommerce.complete_purchase 
  GROUP BY year_month, category_id 
  HAVING year_month = '2019-11' 
  ORDER BY revenue DESC 
  LIMIT 3
)
UNION ALL
SELECT * FROM (
  SELECT format_date('%Y-%m', event_time) AS year_month, 
         SUBSTR(CAST(category_id AS STRING), 10) AS modified_category_id, 
         ROUND(SUM(price)) AS revenue 
  FROM ecommerce.complete_purchase 
  GROUP BY year_month, category_id 
  HAVING year_month = '2019-12' 
  ORDER BY revenue DESC 
  LIMIT 3
)
UNION ALL
SELECT * FROM (
  SELECT format_date('%Y-%m', event_time) AS year_month, 
         SUBSTR(CAST(category_id AS STRING), 10) AS modified_category_id, 
         ROUND(SUM(price)) AS revenue 
  FROM ecommerce.complete_purchase 
  GROUP BY year_month, category_id 
  HAVING year_month = '2020-01' 
  ORDER BY revenue DESC 
  LIMIT 3
)
UNION ALL
SELECT * FROM (
  SELECT format_date('%Y-%m', event_time) AS year_month, 
         SUBSTR(CAST(category_id AS STRING), 10) AS modified_category_id, 
         ROUND(SUM(price)) AS revenue 
  FROM ecommerce.complete_purchase 
  GROUP BY year_month, category_id 
  HAVING year_month = '2020-02' 
  ORDER BY revenue DESC 
  LIMIT 3) order by year_month;
