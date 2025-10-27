use campaign;

-- ------------------------------------------------------------------------------------------------------------
-- trying to alter table 'letter' 
describe letter;
drop table letter;
create table letter (
    account_number int,
    letter_code varchar(20),
    language varchar(20),
    Letter_trigger_date varchar(30)
    )
    ;
-- --------------------------------------------------------------------------------------------------------------

select call_date, count(acct_num) from call_record group by 1;
-- GROUP BY 1 is shorthand for grouping by the first column in the SELECT statement. In your query 
select decision_status, count(*) from decision group by 1;
select change_date, count(*) from change_record group by 1; 

select * from base;
select * from call_record;
select * from change_record;
select * from decision;
select * from letter; 

-- check how many ppl call in and respond everyday 
select c.Call_date, count(distinct c.acct_num) as num_of_ppl_call_in
from call_record as c
group by 1;

-- . What is the overall approval rate and decline rate? The base population should be the total responders
select * from base;
select * from decision;
-- count the total respones number 
select count(distinct B.acct_num) 
from base as B;
-- let's do the rate calculation -- 
-- in order to count AP and DL we need to use case when , then, else, end 
-- join 2 tables first (left join) -- to clean the data I guess 
select d.id,
       b.acct_num, 
       d.decision_status
	from decision as d
  left join base as b on
  b.acct_num = d.acct_num
  ; 
select
    round((sum(case when d.decision_status = 'AP' then 1 else 0 end) / count(distinct d.id)), 2) * 100 as approval_rate , 
    round((sum(case when d.decision_status = 'DL' then 1 else 0 end) / count(distinct d.id)), 2) * 100 as decline_rate 
  from decision as d; 
  

--  for approved accounts, check whether their credit limit has been changed correctly 
-- based on the offer amount – write the query to output the customers with mismatched credit limit increase (use derived table) 

-- join decision table, change_record, and base 
select d.acct_num,
       d.decision_status,
       c.credit_limit_before_ch,
       c.credit_limit_after_ch,
       b.offer_amount
	from decision d
  left join change_record as c on c.account_number = d.acct_num
  left join base as b on b.acct_num = d.acct_num
  ;
-- let's compare if credit limit after - before > offer amount 
select 
    d.acct_num,
    c.credit_limit_before_ch,
    c.credit_limit_after_ch,
    b.offer_amount,
    (c.credit_limit_after_ch - c.credit_limit_before_ch) as expect_credit_limit
  from decision as d 
  left join change_record as c on c.account_number = d.acct_num
  left join base as b on b.acct_num = d.acct_num 
  where d.decision_status = 'AP'
  and c.credit_limit_after_ch <> (c.credit_limit_before_ch + b.offer_amount)
  ; 
  
  
-- 4.1 Check whether letter has been sent out for each approved or declined customers. 
-- Output the customers without receiving any letter. Usually, if the letter trigger date >= 
-- decision date, we consider that the letter has been sent out
select 
    l.account_number,
    l.letter_trigger_date,
    d.decision_date,
    d.decision_status,
    datediff(l.letter_trigger_date, d.decision_date) as letter_miss 
   from letter as l
   left join decision as d 
   on d.acct_num = l.account_number
 where d.decision_status = 'AP' 'DL' 
 or datediff(l.letter_trigger_date, d.decision_date) !=0 
 or l.letter_trigger_date is null 
 order by letter_miss 
 -- order by letter_miss tp see whose letter was absolutly missed 
 ; 

-- 4.2 Check whether the letter is correctly sent out to each customer based on language and 
-- decision. Output the customers with wrong letter code 
SELECT * FROM
(select base.acct_num as acct_num, base.offer_amount, d.decision_status, d.decision_date,
l.language, l.letter_code,
case when decision_status='DL' and language='French' then 'RE002'
	 WHEN decision_status='AP' and language='French' then 'AE002'
     WHEN decision_status='DL' and language='English' then 'RE001'
     WHEN decision_status='AP' and language='English' then 'AE001'
     END AS letter_code2
from
base
left join
decision d
on base.acct_num=d.acct_num
left join
letter l
on 
base.acct_num=l.account_number 
where decision_status is not null) A
WHERE A.letter_code <> A.letter_code2;


-- 5. Create a final monitoring report which includes 