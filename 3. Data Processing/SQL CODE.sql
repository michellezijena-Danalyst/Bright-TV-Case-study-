select * from `workspace`.`default`.`user_profiles` limit 100;

--DATA INSPECTION.

--1 CHECKING DATASET FOR NULL VALUES AND REPLACING THEM WITH VALUES.
SELECT
  'user_profiles' AS UP,
  COUNT(*) - COUNT(`UserID`) AS null_UserID,
  COUNT(*) - COUNT(`Name`) AS null_Name,
  COUNT(*) - COUNT(`Surname`) AS null_Surname,
  COUNT(*) - COUNT(`Email`) AS null_Email,
  COUNT(*) - COUNT(`Gender`) AS null_Gender,
  COUNT(*) - COUNT(`Race`) AS null_Race,
  COUNT(*) - COUNT(`Age`) AS null_Age,
  COUNT(*) - COUNT(`Province`) AS null_Province,
  COUNT(*) - COUNT(`Social Media Handle`) AS null_SocialMediaHandle,
  NULL AS null_Channel2,
  NULL AS null_RecordDate2,
  NULL AS null_Duration2
FROM
  `workspace`.`default`.`user_profiles`
UNION ALL
SELECT
  'viewership' AS V,
  COUNT(*) - COUNT(`UserID`) AS null_UserID,
  NULL AS null_Name,
  NULL AS null_Surname,
  NULL AS null_Email,
  NULL AS null_Gender,
  NULL AS null_Race,
  NULL AS null_Age,
  NULL AS null_Province,
  NULL AS null_SocialMediaHandle,
  COUNT(*) - COUNT(`Channel2`) AS null_Channel2,
  COUNT(*) - COUNT(`RecordDate2`) AS null_RecordDate2,
  COUNT(*) - COUNT(`Duration 2`) AS null_Duration2
FROM
  `workspace`.`default`.`viewership`;

--2 Query to summarize overall user and usage metrics, including total users, active users, average age, gender counts, total sessions, channel count, and average session duration.

SELECT
  COUNT(DISTINCT up.UserID) AS total_users,
  COUNT(DISTINCT v.UserID) AS active_users,
  AVG(up.Age) AS avg_age,
  COUNT(DISTINCT
    CASE
      WHEN up.Gender = 'male' THEN up.UserID
    END
    ) AS male_users,
  COUNT(DISTINCT
    CASE
      WHEN up.Gender = 'female' THEN up.UserID
    END
  ) AS female_users,
  COUNT(v.UserID) AS total_sessions,
  COUNT(DISTINCT v.Channel2) AS total_channels
FROM
  `workspace`.`default`.`user_profiles` up
    LEFT JOIN `workspace`.`default`.`viewership` v
      ON up.UserID = v.UserID;

--3 CONVERTING UTC TIMESTAMP TO SA STANDARD TIME
SELECT
  `UserID`,
  `Channel2`,
  `RecordDate2` AS utc_datetime_string,
  TO_TIMESTAMP(`RecordDate2`, 'yyyy/MM/dd HH:mm') AS utc_timestamp,
  TIMESTAMPADD(HOUR, 2, TO_TIMESTAMP(`RecordDate2`, 'yyyy/MM/dd HH:mm')) AS sa_timestamp,
  `Duration 2` AS viewing_duration
FROM
  `workspace`.`default`.`viewership`
WHERE
  `RecordDate2` IS NOT NULL
LIMIT 10;

--4 AVERAGE SESSION DURATION BY GENDER
SELECT
  up.Gender,
  AVG(
    HOUR(v.`Duration 2`) * 60 + MINUTE(v.`Duration 2`) + try_divide(SECOND(v.`Duration 2`), 60.0)
  ) AS avg_session_duration_minutes
FROM
  `workspace`.`default`.`user_profiles` up
    JOIN `workspace`.`default`.`viewership` v
      ON up.UserID = v.UserID
WHERE
  up.Gender IS NOT NULL
  AND up.Gender != ''
  AND up.Gender != ' '
  AND up.Gender != 'None'
  AND v.`Duration 2` IS NOT NULL
GROUP BY
  up.Gender
ORDER BY
  avg_session_duration_minutes DESC;

--5 AVERAGE SESSION DURATION BY AGE
SELECT
  CASE
    WHEN up.Age BETWEEN 0 AND 17 THEN '0-17'
    WHEN up.Age BETWEEN 18 AND 24 THEN '18-24'
    WHEN up.Age BETWEEN 25 AND 34 THEN '25-34'
    WHEN up.Age BETWEEN 35 AND 44 THEN '35-44'
    WHEN up.Age BETWEEN 45 AND 54 THEN '45-54'
    WHEN up.Age BETWEEN 55 AND 64 THEN '55-64'
    WHEN up.Age >= 65 THEN '65+'
    ELSE 'Unknown'
  END AS age_group,
  AVG(
    HOUR(v.`Duration 2`) * 60 + MINUTE(v.`Duration 2`) + try_divide(SECOND(v.`Duration 2`), 60.0)
  ) AS avg_session_duration_minutes
FROM
  `workspace`.`default`.`user_profiles` up
    JOIN `workspace`.`default`.`viewership` v
      ON up.UserID = v.UserID
WHERE
  up.Age IS NOT NULL
  AND up.Age > 0
  AND v.`Duration 2` IS NOT NULL
GROUP BY
  age_group
ORDER BY
  avg_session_duration_minutes DES;

--6 PEAK VEIWING TIMES AND UNIQUE VIEWERS.
SELECT
  HOUR(TO_TIMESTAMP(`RecordDate2`, 'yyyy/MM/dd HH:mm')) AS hour_of_day,
  SUM(
    HOUR(`Duration 2`) + MINUTE(`Duration 2`) / 60.0 + SECOND(`Duration 2`) / 3600.0
  ) AS total_viewing_hours,
  COUNT(DISTINCT `UserID`) AS unique_viewers
FROM
  `workspace`.`default`.`viewership`
WHERE
  `RecordDate2` IS NOT NULL
  AND `Duration 2` IS NOT NULL
  AND `UserID` IS NOT NULL
GROUP BY
  hour_of_day
ORDER BY
  total_viewing_hours DESC;

--7 USAGE DEMAND BY PROVINCE
SELECT
  up.Province,
  SUM(
    (HOUR(`Duration 2`) * 3600 + MINUTE(`Duration 2`) * 60 + SECOND(`Duration 2`)) / 3600.0
  ) AS total_viewing_hours,
  COUNT(DISTINCT v.UserID) AS unique_viewers
FROM
  `workspace`.`default`.`user_profiles` up
    JOIN `workspace`.`default`.`viewership` v
      ON up.UserID = v.UserID
WHERE
  up.Province IS NOT NULL
  AND up.Province != 'None'
  AND up.Province != ' '
  AND v.`Duration 2` IS NOT NULL
GROUP BY
  up.Province
ORDER BY
  total_viewing_hours DESC;

--8 CONTENT PREFERENCES BY GENDER
SELECT
  up.Gender,
  v.Channel2,
  COUNT(*) AS session_count
FROM
  `workspace`.`default`.`user_profiles` up
    JOIN `workspace`.`default`.`viewership` v
      ON up.UserID = v.UserID
WHERE
  up.Gender IS NOT NULL
  AND up.Gender != ''
  AND up.Gender != ' '
  AND up.Gender != 'None'
  AND v.Channel2 IS NOT NULL
GROUP BY
  up.Gender,
  v.Channel2
ORDER BY
  up.Gender,
  session_count DESC

--9 COMPARING USAGE CONSUMPTION BY WEEKDAY VS WEEKEND
  SELECT
  EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP(`RecordDate2`, 'yyyy/MM/dd HH:mm')) AS day_of_week_number,
  DAYNAME(TO_TIMESTAMP(`RecordDate2`, 'yyyy/MM/dd HH:mm')) AS day_of_week,
  CASE
    WHEN
      EXTRACT(DAYOFWEEK FROM TO_TIMESTAMP(`RecordDate2`, 'yyyy/MM/dd HH:mm')) IN (1, 7)
    THEN
      'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  COUNT(*) AS session_count
FROM
  `workspace`.`default`.`viewership`
WHERE
  `RecordDate2` IS NOT NULL
GROUP BY
  day_of_week_number,
  day_of_week,
  day_type
ORDER BY
  day_of_week_number;

--10 EXCTRACTING DATA TO SEE HIGHEST CONCETRATION OF USERS BY GENDER AND PROVINCE AS WELL AS THE AVERAGE AGE
SELECT
  Gender,
  Province,
  AVG(Age) AS avg_age,
  COUNT(UserID) AS user_count
FROM
  `workspace`.`default`.`user_profiles`
WHERE
  Gender IS NOT NULL
  AND Gender != 'None'
  AND Gender != ' '
  AND Province IS NOT NULL
  AND Province != 'None'
  AND Province != ' '
  AND Age IS NOT NULL
  AND Age > 0
GROUP BY
  Gender,
  Province
ORDER BY
  user_count DESC;


--BIG DATA 
SELECT
  up.UserID,
  up.Age,
  up.Gender,
  up.Race,
  up.Province,
  v.Channel2,
  to_date(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) AS record_date,
  date_format(
    TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS,
    'HH:mm:ss'
  ) AS record_time,
  HOUR(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) AS Hour_SA,
  date_format(
    TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS,
    'EEEE'
  ) AS Day_Name,
  CASE
    WHEN
      hour(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) BETWEEN 6 AND 9
    THEN
      'Early Morning'
    WHEN
      hour(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) BETWEEN 10 AND 12
    THEN
      'Late Morning'
    WHEN
      hour(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) BETWEEN 13 AND 15
    THEN
      'Early Afternoon'
    WHEN
      hour(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) BETWEEN 16 AND 18
    THEN
      'Late Afternoon'
    WHEN
      hour(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm') + INTERVAL 2 HOURS) BETWEEN 19 AND 22
    THEN
      'Evening'
    ELSE 'Late Night'
  END AS Time_bucket,
  date_format(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm'), 'MMMM') AS Month_name,
  (
    (HOUR(v.`Duration 2`) * 3600) + (MINUTE(v.`Duration 2`) * 60) + SECOND(v.`Duration 2`)
  ) AS Duration_Seconds,
  CASE
    WHEN up.Age < 18 THEN 'Under 18'
    WHEN up.Age BETWEEN 18 AND 25 THEN '18-25'
    WHEN up.Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN up.Age BETWEEN 36 AND 50 THEN '36-50'
    ELSE '50+'
  END AS Age_group
FROM
  `workspace`.`default`.`user_profiles` up
    JOIN `workspace`.`default`.`viewership` v
      ON up.UserID = v.UserID
      LIMIT 1000;
