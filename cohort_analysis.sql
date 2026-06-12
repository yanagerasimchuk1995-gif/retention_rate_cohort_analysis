with users_parsed as (
select user_id,
       promo_signup_flag,
       to_date(case  
       when length(split_part(normalized, '-', 3)) = 2 then 
       '20' || split_part(normalized, '-',3)
       else split_part(normalized, '-', 3) -- Перевірила довжину року і додала "20", якщо він був двозначний
       end || '-' || 
       right('00' || split_part(normalized, '-', 2),2)
       || '-' ||
       right ('00' || split_part(normalized, '-', 1),2), 'YYYY-MM-DD') as signup_date -- Додала нулі до дня і місяця і об'єднала з роком, щоб отримати потрібний формат і конвертувала у тип date
from (select user_id,                                                                
      promo_signup_flag,
      replace(replace(split_part(trim(signup_datetime),' ', 1), '/', '-'), '.', '-') as normalized
from project.cohort_users_raw) as normal_date), -- Прибрала пробіли, часову частину, замінила всі розділювачі "/, ." на "-"
events_parsed as (
select user_id,
       event_type,
       to_date(case  
       when length(split_part(normalized, '-', 3)) = 2 then 
       '20' || split_part(normalized, '-',3)
       else split_part(normalized, '-', 3) -- Перевірила довжину року і додала "20", якщо він був двозначний.
       end || '-' || 
       right('00' || split_part(normalized, '-', 2),2)
       || '-' ||
       right ('00' || split_part(normalized, '-', 1),2), 'YYYY-MM-DD') as event_date  -- Додала нулі до дня і місяця і об'єднала з роком, щоб отримати потрібний формат і конвертувала у тип date
from (select user_id,                                                                
      event_type,
      replace(replace(split_part(trim(event_datetime),' ', 1), '/', '-'), '.', '-') as normalized
from project.cohort_events_raw) as normal_date), -- Прибрала пробіли, часову частину, замінила всі розділювачі "/, ." на "-"
user_activity as (
select u.user_id,
       promo_signup_flag,
       signup_date,
       event_date,
       event_type,
       date_trunc('month', signup_date)::date as cohort_month, 
       date_trunc('month', event_date)::date as activity_month, -- Округлила дати реєстрації та дати подій до початку місяця
       (extract(year from date_trunc('month', event_date))*12 + extract(month from date_trunc('month', event_date)))
       - 
       (extract(year from date_trunc('month', signup_date))*12 + extract(month from date_trunc('month', signup_date))) as month_offset -- Знайшла різницю між датою реєстрації і датою події, тобто стаж користувача
from users_parsed u
left join events_parsed e
on u.user_id = e.user_id 
where signup_date is not null
and event_date is not null
and event_type is not null 
and event_type != 'test_event') -- Відфільтрувала користувачів без дати реєстрації, події з відустньою датою, події без типу та тестові події
select promo_signup_flag,
       cohort_month,
       month_offset,
       count(distinct user_id) as users_total 
from user_activity
where activity_month between '2025-01-01' and '2025-06-01'
group by promo_signup_flag, cohort_month, month_offset
order by promo_signup_flag, cohort_month, month_offset; -- Як результат отримала таблицю з унікальною кількістю користувачів розподілену за типом залучення, місяцем залучення та стажем користувача

 



