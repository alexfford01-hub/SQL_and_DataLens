--Автор: КИРИЛЛ ФАЛЕТОРОВ
 -- Дата: 14.06.2025

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL))
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


/** Задача 1: Время активности объявлений
 Результат запроса должен ответить на такие вопросы:
 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
    имеют наиболее короткие или длинные сроки активности объявлений?
 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
    Как эти зависимости варьируют между регионами?
 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?
*/


WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id 	
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL))
SELECT 
case when c.city='Санкт-Петербург' then 'Санкт-Петербург' else 'Лен.Обл' end AS Region,
case when a.days_exposition between 1 and 30 then 'месяц'
 when a.days_exposition between 31 and 90 then 'до_квартала'
 when a.days_exposition between 91 and 180 then 'до_полугода'
 when a.days_exposition>='181' then 'больше_полугода' end AS Segment_activnosti,
	AVG (last_price/total_area) AS AVG_total_cost,
	AVG(total_area) AS  AVG_total_area,
	COUNT(a.id) AS Kol_vo_obevleniy,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS Mediana_komnat,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS Mediana_balconov,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS  Mediana_etashey
FROM real_estate.flats AS f
JOIN real_estate.city AS c ON  c.city_id = f.city_id 
JOIN real_estate.advertisement AS a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and days_exposition IS NOT NULL and type_id ='F8EM'
GROUP BY Region, Segment_activnosti
ORDER by Region DESC, Segment_activnosti ASC;



/** Задача 2: Сезонность объявлений
 Результат запроса должен ответить на такие вопросы:
 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
    А в какие — по снятию? Это показывает динамику активности покупателей.
 2. Совпадают ли периоды активной публикации объявлений и периоды, 
    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
   Что можно сказать о зависимости этих параметров от месяца?
*/

--Анализ по публикациям

WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
)
SELECT 
    COUNT(f.id) AS Kol_vo_obevleniy,
    EXTRACT(month FROM first_day_exposition) AS Month_publica,
    AVG(last_price/total_area) AS AVG_total_cost,
    AVG(total_area) AS AVG_total_area
FROM real_estate.flats AS f 
JOIN real_estate.advertisement AS a ON f.id = a.id
WHERE f.id IN (SELECT * FROM filtered_id) 
AND type_id = 'F8EM'
GROUP BY Month_publica
ORDER BY Kol_vo_obevleniy DESC;

 --Анализ по снятиям

WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL))
SELECT COUNT(f.id) AS  Kol_vo_obevleniy,
EXTRACT  (month from (first_day_exposition::date + days_exposition::INT)) AS Month_vivoda,
AVG (last_price/total_area) AS   AVG_total_cost,
AVG(total_area) AS  AVG_total_area
	FROM real_estate.flats AS f 
	JOIN real_estate.advertisement AS a ON f.id = a.id 
	WHERE f.id IN (SELECT * FROM filtered_id) and days_exposition IS  NOT  NULL  and type_id ='F8EM'
GROUP  BY  Month_vivoda
ORDER  BY  Kol_vo_obevleniy DESC;




/** Задача 3: Анализ рынка недвижимости Ленобласти
 Результат запроса должен ответить на такие вопросы:
 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
*/
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL))
 SELECT c.city, COUNT(f.id) AS  Kol_vo_obevleniy
FROM real_estate.flats AS f
JOIN  real_estate.city AS c on c.city_id = f.city_id 
JOIN real_estate.advertisement AS a ON  a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург'
GROUP  BY  c.city 
ORDER  by Kol_vo_obevleniy DESC 
LIMIT  10;

-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL))
SELECT city, 
COUNT(f.id) FILTER(WHERE days_exposition IS NOT NULL) / COUNT(f.id)::real AS Dolya_vivoda_obevleniy,
COUNT(f.id) FILTER(WHERE days_exposition IS NOT NULL) AS Kol_vo_vivod_obevleniy
FROM real_estate.flats AS f
JOIN  real_estate.city AS c ON  c.city_id = f.city_id 
JOIN real_estate.advertisement AS  a ON  a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург' 
GROUP  BY  city
ORDER  BY  Kol_vo_vivod_obevleniy DESC;


-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир
--	   в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL))
SELECT c.city, COUNT(f.id) AS  Kol_vo_obevleniy,
AVG(total_area) AS  AVG_total_area,
AVG (last_price/total_area) AS  AVG_cost_kvm
FROM real_estate.flats AS f
JOIN  real_estate.city AS  c on c.city_id = f.city_id 
JOIN real_estate.advertisement AS a ON  a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург'and days_exposition IS  NOT  NULL 
GROUP  BY  c.city 
ORDER  BY   AVG_total_area  DESC;


-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)) 
SELECT  c.city, COUNT(f.id) AS  Kol_vo_obevleniy,
AVG  (days_exposition )/30 AS  AVG_total_cost
FROM real_estate.flats AS f
JOIN  real_estate.city AS c on c.city_id = f.city_id 
JOIN real_estate.advertisement AS a ON  a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург' and days_exposition IS  NOT  NULL 
GROUP  BY  c.city
ORDER  BY Kol_vo_obevleniy DESC;




