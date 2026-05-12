/* =========================================================
   ETL CUSTOMER TRANSACTION ANALYTICS
   SQL SCRIPT
   ========================================================= */


/* =========================================================
   1. CLIENTES ACTIVOS
   ========================================================= */

SELECT
    CUSTOMER_ID,
    FULL_NAME,
    CITY,
    STATUS,
    CREATED_DATE
FROM CUSTOMER
WHERE STATUS = 'ACTIVE';



/* =========================================================
   2. CUENTAS ACTIVAS
   ========================================================= */

SELECT
    ACCOUNT_NUMBER,
    CUSTOMER_ID,
    PRODUCT_TYPE,
    ACCOUNT_STATUS,
    OPEN_DATE
FROM ACCOUNT
WHERE ACCOUNT_STATUS = 'ACTIVE';



/* =========================================================
   3. TRANSACCIONES ÚLTIMOS 12 MESES
   ========================================================= */

SELECT
    TRANSACTION_ID,
    ACCOUNT_NUMBER,
    TRANSACTION_DATE,
    TRANSACTION_TYPE,
    AMOUNT_VALUE
FROM TRANSACTION
WHERE TRANSACTION_DATE >= ADD_MONTHS(SYSDATE,-12);



/* =========================================================
   4. VALIDACIÓN DE TRANSACCIONES POSITIVAS
   ========================================================= */

SELECT
    TRANSACTION_ID,
    ACCOUNT_NUMBER,
    TRANSACTION_DATE,
    TRANSACTION_TYPE,
    AMOUNT_VALUE
FROM TRANSACTION
WHERE AMOUNT_VALUE > 0;



/* =========================================================
   5. REMOVE DUPLICATES
   ========================================================= */

SELECT *
FROM
(
    SELECT
        T.*,
        ROW_NUMBER() OVER
        (
            PARTITION BY ACCOUNT_NUMBER, TRANSACTION_ID
            ORDER BY TRANSACTION_DATE DESC
        ) AS RN
    FROM TRANSACTION T
)
WHERE RN = 1;



/* =========================================================
   6. JOIN CLIENTES + CUENTAS
   ========================================================= */

SELECT
    C.CUSTOMER_ID,
    C.FULL_NAME,
    C.CITY,
    A.ACCOUNT_NUMBER,
    A.PRODUCT_TYPE,
    A.OPEN_DATE
FROM CUSTOMER C
INNER JOIN ACCOUNT A
ON C.CUSTOMER_ID = A.CUSTOMER_ID
WHERE C.STATUS = 'ACTIVE'
AND A.ACCOUNT_STATUS = 'ACTIVE';



/* =========================================================
   7. JOIN CLIENTES + CUENTAS + TRANSACCIONES
   ========================================================= */

SELECT
    C.CUSTOMER_ID,
    C.FULL_NAME,
    C.CITY,
    A.ACCOUNT_NUMBER,
    A.PRODUCT_TYPE,
    T.TRANSACTION_ID,
    T.TRANSACTION_DATE,
    T.TRANSACTION_TYPE,
    T.AMOUNT_VALUE
FROM CUSTOMER C
INNER JOIN ACCOUNT A
    ON C.CUSTOMER_ID = A.CUSTOMER_ID
INNER JOIN TRANSACTION T
    ON A.ACCOUNT_NUMBER = T.ACCOUNT_NUMBER
WHERE C.STATUS = 'ACTIVE'
AND A.ACCOUNT_STATUS = 'ACTIVE'
AND T.AMOUNT_VALUE > 0;



/* =========================================================
   8. TRANSFORMACIONES
   ========================================================= */

SELECT
    TRANSACTION_ID,
    ACCOUNT_NUMBER,
    TRANSACTION_DATE,

    CASE
        WHEN TRANSACTION_TYPE = 'PURCHASE'
        THEN 'CONSUMO'
        ELSE 'OTROS'
    END AS TRANSACTION_CATEGORY,

    CASE
        WHEN AMOUNT_VALUE >= 1000
        THEN 'YES'
        ELSE 'NO'
    END AS HIGH_AMOUNT_FLAG,

    AMOUNT_VALUE

FROM TRANSACTION;



/* =========================================================
   9. AGGREGATIONS POR CLIENTE
   ========================================================= */

SELECT
    C.CUSTOMER_ID,
    C.FULL_NAME,
    C.CITY,

    COUNT(T.TRANSACTION_ID) AS TOTAL_TRANSACTIONS,

    SUM(T.AMOUNT_VALUE) AS TOTAL_AMOUNT,

    AVG(T.AMOUNT_VALUE) AS AVG_AMOUNT,

    MAX(T.AMOUNT_VALUE) AS MAX_AMOUNT,

    MIN(T.AMOUNT_VALUE) AS MIN_AMOUNT

FROM CUSTOMER C

INNER JOIN ACCOUNT A
    ON C.CUSTOMER_ID = A.CUSTOMER_ID

INNER JOIN TRANSACTION T
    ON A.ACCOUNT_NUMBER = T.ACCOUNT_NUMBER

WHERE C.STATUS = 'ACTIVE'
AND A.ACCOUNT_STATUS = 'ACTIVE'
AND T.AMOUNT_VALUE > 0

GROUP BY
    C.CUSTOMER_ID,
    C.FULL_NAME,
    C.CITY;



/* =========================================================
   10. SEGMENTACIÓN DE CLIENTES
   ========================================================= */

SELECT
    CUSTOMER_ID,
    FULL_NAME,
    CITY,
    TOTAL_AMOUNT,

    CASE
        WHEN TOTAL_AMOUNT >= 10000
        THEN 'PREMIUM'
        ELSE 'STANDARD'
    END AS CUSTOMER_SEGMENT

FROM CUSTOMER_TRANSACTION_SUMMARY;



/* =========================================================
   11. VALIDACIÓN DE DUPLICADOS
   ========================================================= */

SELECT
    ACCOUNT_NUMBER,
    COUNT(*) AS TOTAL_DUPLICATES
FROM TRANSACTION
GROUP BY ACCOUNT_NUMBER
HAVING COUNT(*) > 1;



/* =========================================================
   12. VALIDACIÓN DE NULOS
   ========================================================= */

SELECT *
FROM CUSTOMER
WHERE CUSTOMER_ID IS NULL;



/* =========================================================
   13. CARGA FINAL
   ========================================================= */

INSERT INTO CUSTOMER_TRANSACTION_SUMMARY
(
    CUSTOMER_ID,
    FULL_NAME,
    CITY,
    TOTAL_TRANSACTIONS,
    TOTAL_AMOUNT,
    AVG_AMOUNT,
    MAX_AMOUNT,
    MIN_AMOUNT,
    CUSTOMER_SEGMENT,
    PROCESS_DATE
)

SELECT
    C.CUSTOMER_ID,
    C.FULL_NAME,
    C.CITY,

    COUNT(T.TRANSACTION_ID) AS TOTAL_TRANSACTIONS,

    SUM(T.AMOUNT_VALUE) AS TOTAL_AMOUNT,

    AVG(T.AMOUNT_VALUE) AS AVG_AMOUNT,

    MAX(T.AMOUNT_VALUE) AS MAX_AMOUNT,

    MIN(T.AMOUNT_VALUE) AS MIN_AMOUNT,

    CASE
        WHEN SUM(T.AMOUNT_VALUE) >= 10000
        THEN 'PREMIUM'
        ELSE 'STANDARD'
    END AS CUSTOMER_SEGMENT,

    SYSDATE

FROM CUSTOMER C

INNER JOIN ACCOUNT A
    ON C.CUSTOMER_ID = A.CUSTOMER_ID

INNER JOIN TRANSACTION T
    ON A.ACCOUNT_NUMBER = T.ACCOUNT_NUMBER

WHERE C.STATUS = 'ACTIVE'
AND A.ACCOUNT_STATUS = 'ACTIVE'
AND T.AMOUNT_VALUE > 0

GROUP BY
    C.CUSTOMER_ID,
    C.FULL_NAME,
    C.CITY;