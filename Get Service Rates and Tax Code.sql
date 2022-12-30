--------------------------------------------------------------------------
-- Accounts, Service Rates, and Tax code
-- Written by: Teo Espero, IT Administrator
-- Date written: 12/29/2022
-- Description:
--		This code was written to identify the service rate and tax code
--		being used by an account.
-- 
-- Code Revision History:
-- 
-- 	base code (12/29)
--		|
--		+ changed code to accomodate for spaces before street name (12/30)
--
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- step #1
-- get all the active accounts in springbrook
--------------------------------------------------------------------------

select
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) as AccountNum,
	mast.lot_no
	into #getaccts
from ub_master mast
where
	mast.acct_status='active'
order by
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)

-- show resulting table
--select * from #getaccts

--------------------------------------------------------------------------
-- step #2
-- connect it with lots to get the service area
--------------------------------------------------------------------------

select 
	ga.AccountNum,
	l.lot_no,
	l.city,
	l.misc_1,
	l.misc_2,
	misc_5,
	l.zip,
	l.street_number + ' ' + l.street_name + ', ' + l.city + ', ' + l.state + ', ' +l.zip as Locator
	into #getcity
from #getaccts ga
inner join
	lot l
	on l.lot_no=ga.lot_no
	and l.city='Seaside'
	--and l.misc_2 !='Institutional'
order by
	ga.AccountNum,
	ga.lot_no


-- show resulting data set
--select * from #getcity

--------------------------------------------------------------------------
-- step #3
-- get the service rates per account
--------------------------------------------------------------------------

select 
	gc.misc_2 as STCategory,
	gc.misc_1 as Boundary,
	gc.misc_5 as Subdivision,
	gc.AccountNum,
	gc.lot_no,
	gc.city,
	gc.zip,
	sr.service_code,
	gc.Locator
	into #getsr
from #getcity gc
inner join
	ub_service_rate sr
	on replicate('0', 6 - len(sr.cust_no)) + cast (sr.cust_no as varchar)+ '-'+replicate('0', 3 - len(sr.cust_sequence)) + cast (sr.cust_sequence as varchar)=gc.AccountNum
	and sr.rate_final_date is null
	and sr.service_number=1
	and sr.service_code not like 'WC%'
order by
	gc.misc_2,
	gc.AccountNum,
	sr.service_code,
	gc.lot_no

-- show resulting table
--select * from #getsr

--------------------------------------------------------------------------
-- step #4
-- get the service rates tax code
--------------------------------------------------------------------------

select 
	sr.STCategory,
	sr.Boundary,
	sr.AccountNum,
	sr.Subdivision,
	sr.lot_no,
	sr.city,
	sr.zip,
	sr.service_code,
	effective_date,
	tx.tax_code,
	tx.percentage_1,
	sr.Locator
from ub_service sc
left join
	ub_service_detail scd
	on scd.ub_service_id=sc.ub_service_id
	and year(scd.effective_date) = 2022
left join
	ub_service_to_tax stt
	on stt.ub_service_detail_id=scd.ub_service_detail_id
left join
	ub_tax tx
	on tx.ub_tax_id=stt.ub_tax_id
right join
	#getsr sr
	on sr.service_code = sc.service_code
order by
	sr.STCategory,
	sr.Subdivision,
	sr.AccountNum





--------------------------------------------------------------------------
-- step #5
-- cleanup
--------------------------------------------------------------------------

drop table #getaccts
drop table #getcity
drop table #getsr


