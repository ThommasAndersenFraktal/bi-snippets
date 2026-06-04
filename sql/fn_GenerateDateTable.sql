CREATE OR ALTER FUNCTION dbo.fn_GenerateDateTable
(
    @start_date DATE, 
    @end_date   DATE
)
RETURNS @result TABLE
(
    dato DATE,
    første_dato_i_måned DATE,
    siste_dato_i_måned DATE,
    første_dato_i_uke DATE,
    siste_dato_i_uke DATE,
    ukedag INT,
    uke INT,
    kvartal INT,
    måned INT,
    år INT,
    år_måned INT,
    år_uke INT,
    år_kvartal INT,
    dag_i_år INT,
    dag_i_uke INT,
    dag_i_måned INT,
    ukedag_navn NVARCHAR(50),
    ukedag_navn_kort NVARCHAR(50),
    måned_navn NVARCHAR(50),
    måned_navn_kort NVARCHAR(50),
    måned_år_navn NVARCHAR(50),
    måned_år_navn_kort NVARCHAR(50),
    uke_år_navn NVARCHAR(50),
    kvartal_år_navn NVARCHAR(50),
    arbeidsdag_navn NVARCHAR(50),
    er_frem_til_i_dag BIT,
    er_før_i_dag BIT,
    passerte_dager INT,
    passerte_år INT,
    passerte_måneder INT,
    passerte_kvartaler INT,
    passerte_uker INT,
    dag_dynamisk NVARCHAR(50),
    uke_dynamisk NVARCHAR(50),
    måned_dynamisk NVARCHAR(50),
    år_dynamisk NVARCHAR(50),
    perioder_år_tidligere NVARCHAR(50)
)
AS
BEGIN

    DECLARE @i_dag DATE = CONVERT(DATE, SYSDATETIME());

    WITH cte_dato_liste AS (
        -- Generate a contiguous list of dates from @start_date to @end_date
        SELECT CAST(@start_date AS DATE) AS dato_verdi
        UNION ALL
        SELECT DATEADD(DAY, 1, dato_verdi)
        FROM cte_dato_liste
        WHERE dato_verdi < @end_date
    ),

    -- Custom month names
    måned_navn AS (
        select
            *
        from
            (values
                (1, 'Jan', 'Januar'),
                (2, 'Feb', 'Februar'),
                (3, 'Mar', 'Mars'),
                (4, 'Apr', 'April'),
                (5, 'Mai', 'Mai'),
                (6, 'Jun', 'Juni'),
                (7, 'Jul', 'Juli'),
                (8, 'Aug', 'August'),
                (9, 'Sep', 'September'),
                (10, 'Okt', 'Oktober'),
                (11, 'Nov', 'November'),
                (12, 'Des', 'Desember')
        ) as t(måned_nummer, måned_navn_kort, måned_navn_lang)
    ),

    -- Custom weekday names
    ukedag_navn AS (
        select
            *
        from
            (values
                (1, 'Man', 'Mandag'),
                (2, 'Tir', 'Tirsdag'),
                (3, 'Ons', 'Onsdag'),
                (4, 'Tor', 'Torsdag'),
                (5, 'Fre', 'Fredag'),
                (6, 'Lør', 'Lørdag'),
                (7, 'Søn', 'Søndag')
        ) as t(ukedag_nummer, ukedag_navn_kort, ukedag_navn_lang)
    ),

    grunnlag AS (
        SELECT
            dl.dato_verdi                                                      AS dato,
            DATEFROMPARTS(YEAR(dl.dato_verdi), MONTH(dl.dato_verdi), 1)        AS første_dato_i_måned,
            EOMONTH(dl.dato_verdi)                                             AS siste_dato_i_måned,
            DATETRUNC(WEEK, dl.dato_verdi)                                     AS første_dato_i_uke,
            DATEADD(DAY, 6, DATETRUNC(WEEK, dl.dato_verdi))                    AS siste_dato_i_uke,

            ((DATEPART(weekday,dl.dato_verdi)+@@DATEFIRST-2)%7)+1              AS ukedag,
            DATEPART(ISO_WEEK, dl.dato_verdi)                                  AS uke,
            DATEPART(QUARTER,  dl.dato_verdi)                                  AS kvartal,
            DATEPART(MONTH,    dl.dato_verdi)                                  AS måned,
            DATEPART(YEAR,     dl.dato_verdi)                                  AS år,
            (YEAR(dl.dato_verdi) * 100 + MONTH(dl.dato_verdi))                 AS år_måned,
            (CAST(
                DATEPART(YEAR, DATEADD(DAY, 26 - DATEPART(ISO_WEEK, dl.dato_verdi), dl.dato_verdi)) AS INT
             ) * 100 + DATEPART(ISO_WEEK, dl.dato_verdi))                      AS år_uke,
            (YEAR(dl.dato_verdi) * 10 + DATEPART(QUARTER, dl.dato_verdi))      AS år_kvartal,
            DATEPART(DAYOFYEAR, dl.dato_verdi)                                 AS dag_i_år,
            DATEPART(WEEKDAY,   dl.dato_verdi)                                 AS dag_i_uke,
            DATEPART(DAY,       dl.dato_verdi)                                 AS dag_i_måned,
            u.ukedag_navn_lang                                                 AS ukedag_navn,
            u.ukedag_navn_kort                                                 AS ukedag_navn_kort,
            m.måned_navn_lang                                                  AS måned_navn,
            m.måned_navn_kort                                                  AS måned_navn_kort,
            CONCAT(m.måned_navn_lang,' ',DATEPART(YEAR,dl.dato_verdi) )        AS måned_år_navn,
            CONCAT(m.måned_navn_kort,' ',DATEPART(YEAR,dl.dato_verdi) )        AS måned_år_navn_kort,
            CONCAT('U', RIGHT('0' + CAST(DATEPART(ISO_WEEK, dl.dato_verdi) AS VARCHAR(2)), 2),
                   ' ', CAST(DATEPART(YEAR, DATEADD(DAY, 26 - DATEPART(ISO_WEEK, dl.dato_verdi), dl.dato_verdi)) AS CHAR(4))) AS uke_år_navn,
            CONCAT('K', DATEPART(QUARTER, dl.dato_verdi), ' ', DATEPART(YEAR, dl.dato_verdi)) 
                                                                               AS kvartal_år_navn,

            IIF(dl.dato_verdi <= @i_dag, 1, 0)                                 AS er_frem_til_i_dag,
            IIF(dl.dato_verdi  <  @i_dag, 1, 0)                                AS er_før_i_dag,

            DATEDIFF(DAY, dl.dato_verdi, @i_dag)                               AS passerte_dager,
            DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi)             AS passerte_år,
            (DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi)) * 12
              + (DATEPART(MONTH, @i_dag) - DATEPART(MONTH, dl.dato_verdi))     AS passerte_måneder,
            ((DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi)) * 4
              + (DATEPART(QUARTER, @i_dag) - DATEPART(QUARTER, dl.dato_verdi))
            )                                                                  AS passerte_kvartaler,
            DATEDIFF(
                WEEK,
                DATEADD(DAY, -CASE WHEN DATEPART(DW, dl.dato_verdi) = 1 THEN 6 ELSE DATEPART(DW, dl.dato_verdi) - 2 END, dl.dato_verdi),
                DATEADD(DAY, -CASE WHEN DATEPART(DW, @i_dag)     = 1 THEN 6 ELSE DATEPART(DW, @i_dag)     - 2 END, @i_dag)
            )                                                                  AS passerte_uker,

            CASE
                WHEN DATEDIFF(DAY, dl.dato_verdi, @i_dag) =  0 THEN N'I dag'
                WHEN DATEDIFF(DAY, dl.dato_verdi, @i_dag) =  1 THEN N'I går'
                WHEN DATEDIFF(DAY, dl.dato_verdi, @i_dag) = -1 THEN N'I morgen'
                ELSE CONVERT(VARCHAR(10), dl.dato_verdi, 120)
            END                                                                AS dag_dynamisk,
            CASE
                WHEN DATEPART(ISO_WEEK, dl.dato_verdi) = DATEPART(ISO_WEEK, @i_dag)
                     AND DATEPART(YEAR, DATEADD(DAY, 26 - DATEPART(ISO_WEEK, dl.dato_verdi), dl.dato_verdi)) = YEAR(@i_dag)
                    THEN N'Denne uken'
                WHEN DATEPART(ISO_WEEK, dl.dato_verdi) = DATEPART(ISO_WEEK, @i_dag) - 1
                     AND DATEPART(YEAR, DATEADD(DAY, 26 - DATEPART(ISO_WEEK, dl.dato_verdi), dl.dato_verdi)) = YEAR(@i_dag)
                    THEN N'Forrige uke'
                WHEN DATEPART(ISO_WEEK, dl.dato_verdi) = DATEPART(ISO_WEEK, @i_dag) + 1
                     AND DATEPART(YEAR, DATEADD(DAY, 26 - DATEPART(ISO_WEEK, dl.dato_verdi), dl.dato_verdi)) = YEAR(@i_dag)
                    THEN N'Neste uke'
                ELSE N'U' + RIGHT('00' + CAST(DATEPART(ISO_WEEK, dl.dato_verdi) AS VARCHAR(2)), 2) + N' '
                     + CAST(DATEPART(YEAR, DATEADD(DAY, 26 
                     - DATEPART(ISO_WEEK, dl.dato_verdi), dl.dato_verdi)) AS VARCHAR(4))
            END                                                                AS uke_dynamisk,
            CASE
                WHEN DATEDIFF(MONTH, dl.dato_verdi, @i_dag) =  0 THEN N'Denne måneden'
                WHEN DATEDIFF(MONTH, dl.dato_verdi, @i_dag) =  1 THEN N'Forrige måned'
                WHEN DATEDIFF(MONTH, dl.dato_verdi, @i_dag) = -1 THEN N'Neste måned'
                ELSE LEFT(DATENAME(MONTH, dl.dato_verdi), 3) + N' ' + 
                CAST(DATEPART(YEAR, dl.dato_verdi) AS VARCHAR(4))
            END                                                                AS måned_dynamisk,
            CASE
                WHEN DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi) =  0 THEN N'I år'
                WHEN DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi) =  1 THEN N'I fjor'
                WHEN DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi) = -1 THEN N'Neste år'
                ELSE CAST(DATEPART(YEAR, dl.dato_verdi) AS VARCHAR(4))
            END                                                                AS år_dynamisk,
            CASE
                WHEN DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi) =  0 THEN N'I år'
                WHEN DATEPART(YEAR, @i_dag) - DATEPART(YEAR, dl.dato_verdi) >  0 THEN N'Tidligere'
                ELSE CAST(DATEPART(YEAR, dl.dato_verdi) AS VARCHAR(4))
            END                                                                AS perioder_år_tidligere
        FROM cte_dato_liste dl
        left join måned_navn  as m on MONTH(dl.dato_verdi)  = m.måned_nummer
        left join ukedag_navn  as u on ((DATEPART(weekday,dl.dato_verdi)+@@DATEFIRST-2)%7)+1 = u.ukedag_nummer

    ),

    årstall_helligdager AS (
        SELECT DISTINCT
            YEAR(dato) AS år
        FROM grunnlag
    ),
      
    påske_trinn1 AS (
        SELECT
            år,
            år % 19                  AS a,
            FLOOR(år/100.0)          AS b,
            år % 100                 AS c,
            FLOOR(FLOOR(år/100.0)/4) AS d,
            FLOOR(år/100.0) % 4      AS e,
            FLOOR((FLOOR(år/100.0)+8)/25) AS f,
            FLOOR((FLOOR(år/100.0)
             - FLOOR((FLOOR(år/100.0)+8)/25)
             + 1
           )/3.0)                      AS g
        FROM årstall_helligdager
    ),

    påske_trinn2 AS (
        SELECT
            år,
            a,
            e,
            FLOOR(c/4.0)                 AS i,
            c % 4                        AS k,
            (19*a + b - d - g + 15) % 30 AS h
        FROM påske_trinn1
    ),

    påske_trinn3 AS (
        SELECT
            år,
            h,
            e,
            i,
            k,
            (32 + 2*e + 2*i - h - k) % 7        AS l,
            FLOOR((a + 11*h + 22 * ((32+2*e+2*i-h-k)%7)) / 451.0) AS m
        FROM påske_trinn2
    ),

    påske_datoer AS (
        SELECT
            år,
            DATEFROMPARTS(
            år,
            FLOOR((h + l - 7*m + 114)/31.0),
            ((h + l - 7*m + 114) % 31) + 1
            ) AS påske_søndag
        FROM påske_trinn3
    ),

    definerte_helligdager AS (
        
        SELECT
            helligdag_navn,
            måned,
            dag,
            forskyvning_dager
        FROM (VALUES
                ('1. nyttårsdag', 1, 1, NULL),
                ('Skjærtorsdag', NULL, NULL, -3),
                ('Langfredag', NULL, NULL, -2),
                ('Påskeaften', NULL, NULL, -1),
                ('1. påskedag', NULL, NULL, 0),
                ('2. påskedag', NULL, NULL, 1),
                ('Arbeidernes dag', 5, 1, NULL),
                ('Grunnlovsdagen', 5, 17, NULL),
                ('Kristi himmelfartsdag', NULL, NULL, 39),
                ('Pinseaften', NULL, NULL, 48),
                ('1. pinsedag', NULL, NULL, 49),
                ('2. pinsedag', NULL, NULL, 50),
                ('Julaften', 12, 24, NULL),
                ('1. juledag', 12, 25, NULL),
                ('2. juledag', 12, 26, NULL),
                ('Nyttårsaften', 12, 31, NULL)
        ) AS t(helligdag_navn, måned, dag, forskyvning_dager)
    ),

    helligdager AS (
        SELECT
            CASE
                WHEN måned IS NOT NULL THEN DATEFROMPARTS(hy.år, måned, dag)
                ELSE DATEADD(DAY, forskyvning_dager, ed.påske_søndag)
            END AS helligdag_dato,
            helligdag_navn
        FROM årstall_helligdager AS hy
        CROSS JOIN definerte_helligdager
        LEFT JOIN påske_datoer AS ed
            ON ed.år = hy.år
    ),

    korrigert AS (
        SELECT
            dato,
            første_dato_i_måned,
            siste_dato_i_måned,
            første_dato_i_uke,
            siste_dato_i_uke,
            ukedag,
            uke,
            kvartal,
            måned,
            år,
            år_måned,
            år_uke,
            år_kvartal,
            dag_i_år,
            dag_i_uke,
            dag_i_måned,
            ukedag_navn,
            ukedag_navn_kort,
            måned_navn,
            måned_navn_kort,
            måned_år_navn,
            måned_år_navn_kort,
            ISNULL(helligdager.helligdag_navn, IIF(ukedag > 5, 'Helg', 'Arbeidsdag')) AS arbeidsdag_navn,
            helligdager.helligdag_navn,
            uke_år_navn,
            kvartal_år_navn,
            er_frem_til_i_dag,
            er_før_i_dag,
            passerte_dager,
            passerte_år,
            passerte_måneder,
            passerte_kvartaler,
            passerte_uker,
            dag_dynamisk,
            uke_dynamisk,
            måned_dynamisk,
            år_dynamisk,
            perioder_år_tidligere
        FROM grunnlag AS d
        LEFT JOIN (
            SELECT
                IIF(min(helligdag_navn) <> max(helligdag_navn), CONCAT_WS(' - ',min(helligdag_navn),max(helligdag_navn)), min(helligdag_navn)) 
                AS helligdag_navn, --avoid duplicates for occasions appearing on the same date
                helligdag_dato
            FROM helligdager GROUP BY helligdag_dato
        ) AS helligdager
        ON d.dato = helligdager.helligdag_dato
    )
    INSERT INTO @result
    SELECT
        dato,
        første_dato_i_måned,
        siste_dato_i_måned,
        første_dato_i_uke,
        siste_dato_i_uke,
        ukedag,
        uke,
        kvartal,
        måned,
        år,
        år_måned,
        år_uke,
        år_kvartal,
        dag_i_år,
        dag_i_uke,
        dag_i_måned,
        ukedag_navn,
        ukedag_navn_kort,
        måned_navn,
        måned_navn_kort,
        måned_år_navn,
        måned_år_navn_kort,
        uke_år_navn,
        kvartal_år_navn,
        arbeidsdag_navn,
        er_frem_til_i_dag,
        er_før_i_dag,
        passerte_dager,
        passerte_år,
        passerte_måneder,
        passerte_kvartaler,
        passerte_uker,
        dag_dynamisk,
        uke_dynamisk,
        måned_dynamisk,
        år_dynamisk,
        perioder_år_tidligere
    FROM korrigert
    OPTION (MAXRECURSION 0);

    RETURN;
END

GO

