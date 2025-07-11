/* sql case study on laptop dataset data cleaning + exploratory data analysis*/
select * from laptop;
-- create a backup

create table laptops like laptop;
insert into laptops select * from laptop;

select * from laptops;

-- number of rows
select count(*) from laptops;

-- check memory consumption
select * from information_schema.tables 
where table_schema='campusx'
and table_name='laptops';

-- drop non important cols
select * from laptops;

alter table laptops drop column `Unnamed: 0`;
select * from laptops;

-- drop null values
select * from laptops where company is null 
and typename is null and ScreenResolution is null 
and cpu is null and ram is null and memory is null and gpu is null
and opsys is null and weight is null and price is null ;

select * from laptops;

-- drop duplicates
select *, count(*) from laptops group by company,typename,inches,ScreenResolution,
cpu,ram,memory,gpu,opsys,weight,price having count(*)>1;

select * from laptops where company='Asus' and Typename='Notebook' and inches='15.6'
and ScreenResolution='1366x768'and cpu='Intel Celeron Dual Core N3050 1.6GHz'and 
ram='4GB' and memory ='500GB HDD'and 
gpu='Intel HD Graphics'and opsys='Windows 10'and weight= '2.2kg'
and price='19660.32';
set session sql_mode = (select replace(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));
set sql_safe_updates=0;
delete from laptops where `index` not in 
                 (select * from(select min(`index`) from laptops
	       group by company,typename,inches,ScreenResolution,
	       cpu,ram,memory,gpu,opsys,weight,price ) as temp);
                 
                 
        

 -- clean RAM change column data type
 select distinct company from laptops;# no null values which is good
 select distinct typename from laptops;
 
 alter table laptops modify column inches  decimal(10,2);# changed the datatype of inches from text to decimal
 select distinct ram from laptops;
 update laptops
 set ram=replace(ram,'GB','') ;
 select * from laptops;
SELECT DISTINCT weight FROM laptops WHERE weight NOT REGEXP '^[0-9.]+$';
UPDATE laptops
SET weight = NULL
WHERE TRIM(weight) = '' OR weight = '?'; 
 alter table laptops modify column ram int;
 update laptops set weight=replace(weight,'kg','');
 alter table laptops modify column weight float;
 
 select * from laptops;
 


update laptops set price=round(price);
alter table laptops modify column price int;

-- checking the RAM size after conversion
select data_length/1024 from information_schema.tables where 
table_schema='campusx' and table_name='laptops';

 select distinct opsys from laptops;
/*macOS No OS Windows 10 Mac OS X Linux Windows 10 S Chrome OS Windows 7 Android*/
update laptops set opsys=
case 
   when opsys like '%mac%' then 'mac'
   when opsys like 'windows%' then 'windows'
   when opsys like '%linux%' then 'linux'
   when opsys ='No OS' then 'N/A'
   else 'other'
end  ;

select * from laptops;

select distinct gpu from laptops;

alter table laptops 
add column gpu_brand varchar(255) after gpu,
add column gpu_name varchar(255) after gpu_brand;

update laptops set gpu_brand= substring_index(gpu,' ',1);
update laptops set gpu_name=replace(gpu,gpu_brand,'') ;

select * from laptops;


alter table laptops drop column gpu;

alter table laptops
add column cpu_brand varchar(255) after cpu,
add column cpu_name  varchar(255) after cpu_brand,
add column cpu_speed decimal(10,2) after cpu_name;
 

update laptops set cpu_brand=substring_index(cpu,' ',1) ;
set sql_safe_updates=0;
update laptops set cpu_speed=replace(substring_index(cpu,' ',-1),'GHz','');

update laptops set cpu_name=
substring_index(substring_index(cpu,' ',3),' ',-2) ;

select * from laptops;

alter table laptops drop column cpu;

update laptops
set screenresolution=substring_index(screenresolution,' ',-1);

update laptops set typename='Convertible'  where typename='2 in 1 Convertible';
select distinct typename from laptops;

alter table laptops add column memory_type varchar(255) after memory;

update laptops set memory_type= 
case 
   when memory not like '%+%' then 
      case 
	when substring_index(memory,' ',-1)='storage' then 'Flash'
          else substring_index(memory,' ',-1)
       end
    else 'Hybrid'
 end ;
 
select * from laptops;
alter table laptops add column memory_space integer after memory;

delete from laptops where memory='1.0TB' ;
delete from laptops where memory not regexp '^[0-9]';
delete from laptops where lower(memory) like '%1.0tb%';


select memory, replace(substring_index(memory,' ',1),'TB','')*1000 from laptops;


update laptops set memory_space=
case 
    when memory not like '%+%' then 
    case
	     when memory like '%TB%' then cast(replace(substring_index(memory, ' ', 1), 'TB', '') as unsigned) * 1000
	     else 
	      cast(replace(substring_index(memory, ' ', 1), 'GB', '') as unsigned)
    end 
    when memory like '%+%' then
    case
	       when substring_index(trim(substring_index(memory,'+',-1)),' ',1) like '%TB%' then 
                      case 
                        when substring_index(trim(substring_index(memory,'+',1)),' ',1) like '%TB%'then cast(replace(substring_index(trim(substring_index(memory,'+',1)),' ',1),'TB','') as unsigned)*1000+cast(replace(substring_index(trim(substring_index(memory,'+',-1)),' ',1) ,'TB','')as unsigned)*1000 
	              else  cast(replace(substring_index(trim(substring_index(memory,'+',1)),' ',1),'GB','') as unsigned)+cast(replace(substring_index(trim(substring_index(memory,'+',-1)),' ',1) ,'TB','')as unsigned)*1000 
	            end
                 else
                    case 
                        when substring_index(trim(substring_index(memory,'+',1)),' ',1) like '%TB%'then cast(replace(substring_index(trim(substring_index(memory,'+',1)),' ',1),'TB','') as unsigned)*1000+cast(replace(substring_index(trim(substring_index(memory,'+',-1)),' ',1) ,'GB','')as unsigned) 
	              else  cast(replace(substring_index(trim(substring_index(memory,'+',1)),' ',1),'GB','') as unsigned)+cast(replace(substring_index(trim(substring_index(memory,'+',-1)),' ',1) ,'GB','')as unsigned)
		 end
     end	         
end;




alter table laptops drop column memory;

select * from laptops;

     /* exploratory data analysis*/
-- head,tail,sample

select * from laptops order by `index` limit 5;     
select * from laptops order by `index`  desc limit 5;

select * from laptops order by rand() limit 5;

-- univariate analysis
   -- for numerical cols
set @row=0;    
  
select 
  (select count(price) from laptops) as count_price,
  (select min(price) from laptops) as min_price,
  (select max(price) from laptops) as max_price,
  (select avg(price) from laptops) as avg_price,
  (select std(price) from laptops) as std_price,
  avg(case when rownum = q1_row then price end) as Q1,
  avg(case when rownum = q2_row then price end) as Median,
  avg(case when rownum = q3_row then price end) as Q3
from (
 
  select price, @row:=@row+1 as rownum
  from laptops
  order by price
) as ordered
join (
  select 
    floor(count(*) * 0.25) as q1_row,
    floor(count(*) * 0.5) as q2_row,
    floor(count(*) * 0.75) as q3_row
  from laptops
) as percentiles;
-- missing value
select count(price) from laptops where price is null;

-- outliers
set @minimum=32448-1.5*(79813-32448);
set @maximum=79813+1.5*(79813-32448);

delete from laptops
where price in (
  select * from (
    select price from laptops
    where price < @minimum or price > @maximum
  ) as outliers
);

select * from laptops;
-- histogram
select price,
sum(case when price between 0 and 25000 then 1 else 0 end) as '0-25k',
sum(case when price between 25001 and 50000 then 1 else 0 end) as '25k-50k',
sum(case when price between 50001 and 75000 then 1 else 0 end) as '50k-75k',
sum(case when price between 75001 and 100000 then 1 else 0 end) as '75k-100k',
sum(case when price>100000 then 1 else 0 end) as '>100k'
from laptops;

-- categorical cols
select * from laptops;
select company, count(company) from laptops
group by company order by count(company) desc;

-- bivariate analysis
select corr(price, weight) from laptops;

select
  (
    avg(price * weight) - avg(price) * avg(weight)
  ) /
  (std(price) * std(weight)) as correlation
from laptops
where price is not null and weight is not null;

select * from laptops;

-- categorical and numerical
select company,min(price) as min_price, max(price) as max_price,
std(price) as std_price,avg(price) as avg_price from laptops
group by company;

set sql_safe_updates=0;
--  missing value treatment
#there are no missing values, lets make some of them
update laptops set price=null  where `index` in (7,869,1148);
-- replace with mean
update laptops
set price = (
  select avg_price from (
    select round(avg(price)) as avg_price from laptops
  ) as temp
)
where price is null;

update laptops l1
join (
  select company, avg(price) as avg_price
  from laptops
  where price is not null
  group by company
) as l2
on l1.company = l2.company
set l1.price = l2.avg_price
where l1.price is null;


select * from laptops;

