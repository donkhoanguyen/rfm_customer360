use rfm_proj;

create table Customer_RFM_Statistics (
with cte as (
	SELECT Contract,
		SUM(GMV) / ( YEAR('2022-09-01') - YEAR(max(created_date)) )
			as monetary,
		count(ct.ID) * 1.0 / ( YEAR('2022-09-01') - YEAR(max(created_date)) ) 
			as frequency,
		( YEAR('2022-09-01') - YEAR(max(created_date)) )
			as recency,
		row_number() OVER(ORDER BY ( SUM(GMV) / ( YEAR('2022-09-01') - YEAR(max(created_date)) ) ) desc
			) as rn_monetary,
		row_number() OVER( ORDER BY (count(ct.ID) * 1.0 / ( YEAR('2022-09-01') - YEAR(max(created_date)) ) ) desc
			) as rn_frequency,
		ROW_NUMBER() OVER( ORDER BY ( YEAR('2022-09-01') - YEAR(max(created_date)) ) 
			) as rn_recency
	FROM Customer_Registered cr
	JOIN Customer_Transaction ct on cr.ID = ct.CustomerID 
	WHERE cr.stopdate is null
	GROUP BY Contract, ct.Purchase_Date 
),

rfm_mapping as (
SELECT 
    Contract,
    monetary,
    frequency,
    recency,
    CASE 
        WHEN rn_monetary >= (SELECT MIN(rn_monetary) FROM cte) AND rn_monetary < (SELECT COUNT(rn_monetary)*0.25 FROM cte) THEN 1
        WHEN rn_monetary >= (SELECT COUNT(rn_monetary)*0.25 FROM cte) AND rn_monetary < (SELECT COUNT(rn_monetary)*0.5 FROM cte) THEN 2
        WHEN rn_monetary >= (SELECT COUNT(rn_monetary)*0.5 FROM cte) AND rn_monetary < (SELECT COUNT(rn_monetary)*0.75 FROM cte) THEN 3
        ELSE 4
    END AS M,
    CASE 
        WHEN rn_frequency >= (SELECT MIN(rn_frequency) FROM cte) AND rn_frequency < (SELECT COUNT(rn_frequency)*0.25 FROM cte) THEN 1
        WHEN rn_frequency >= (SELECT COUNT(rn_frequency)*0.25 FROM cte) AND rn_frequency < (SELECT COUNT(rn_frequency)*0.5 FROM cte) THEN 2
        WHEN rn_frequency >= (SELECT COUNT(rn_frequency)*0.5 FROM cte) AND rn_frequency < (SELECT COUNT(rn_frequency)*0.75 FROM cte) THEN 3
        ELSE 4
    END AS F,
    CASE 
        WHEN rn_recency >= (SELECT MIN(rn_recency) FROM cte) AND rn_recency < (SELECT COUNT(rn_recency)*0.25 FROM cte) THEN 1
        WHEN rn_recency >= (SELECT COUNT(rn_recency)*0.25 FROM cte) AND rn_recency < (SELECT COUNT(rn_recency)*0.5 FROM cte) THEN 2
        WHEN rn_recency >= (SELECT COUNT(rn_recency)*0.5 FROM cte) AND rn_recency < (SELECT COUNT(rn_recency)*0.75 FROM cte) THEN 3
        ELSE 4
    END AS R
FROM cte
)

select *, concat(r,f,m) as rfm
from rfm_mapping
)

;

select * from Customer_RFM_Statistics;





