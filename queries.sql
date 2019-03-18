-- Make a callforwarding, replace numbers in call_logs
update call_logs, call_forwarding
set call_logs.To = call_forwarding.To
where call_logs.To = call_forwarding.From;

-- Add info about UID_from and UID_To
DROP TEMPORARY TABLE IF EXISTS new_call_logs;
CREATE TEMPORARY TABLE new_call_logs 
		select calls_out.call_id, calls_out.From, calls_out.To,calls_out.UID as UID_From, numbers.UID as UID_To, calls_out.Timestamp_start, calls_out.Timestamp_end  from
		(select * from call_logs where call_dir="out") as calls_out left join numbers
		on calls_out.To = numbers.Phone_number
	union
		select calls_in.call_id, calls_in.From, calls_in.To, numbers.UID as UID_From, calls_in.UID as UID_To, calls_in.Timestamp_start, calls_in.Timestamp_end   from
		(select * from call_logs where call_dir="in") as calls_in left join numbers
		on calls_in.From = numbers.Phone_number;


DROP TEMPORARY TABLE IF EXISTS charges;
CREATE TEMPORARY TABLE charges
select new_call_logs.Call_id, new_call_logs.From, new_call_logs.To, new_call_logs.UID_to, 
	((UNIX_TIMESTAMP(Timestamp_end) - UNIX_TIMESTAMP(Timestamp_start))*0.04)  as charge from new_call_logs;

update charges, numbers
set charges.charge = 0
where charges.UID_To = numbers.UID;

-- Total charges
select sum(charge) from charges;

-- Top 10 users by income calls
select UID_To, count(UID_To) from new_call_logs
group by UID_To order by count(UID_To) desc Limit 10;

-- Top 10 users by outcome calls
select UID_From, count(UID_From) from new_call_logs
group by UID_From order by count(UID_From) desc Limit 10;





