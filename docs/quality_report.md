# Reporte de Calidad de Datos — Olist RAW Layer

## Resumen

Profiling realizado sobre las 9 tablas de la capa RAW en Snowflake (`DATA_ACADEMY.RAW`).
Dataset: e-commerce brasileño Olist, 2016–2018.

---

## 0. Conteo de filas por tabla

| Tabla | Filas |
|---|---|
| GEOLOCATION | 1.000.163 |
| ORDER_ITEMS | 112.650 |
| ORDER_PAYMENTS | 103.886 |
| ORDERS | 99.441 |
| CUSTOMERS | 99.441 |
| ORDER_REVIEWS | 99.224 |
| PRODUCTS | 32.951 |
| SELLERS | 3.095 |
| PRODUCT_CATEGORY_NAME_TRANSLATION | 71 |

---

## 1. Completeness — Nulls y campos vacíos

### Orders — fechas
```sql
SELECT
  COUNT(*) AS total,
  COUNT(*) - COUNT(order_approved_at) AS missing_approved,
  COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivered,
  COUNT(*) - COUNT(order_delivered_carrier_date) AS missing_shipped
FROM ORDERS;
```

| total | missing_approved | missing_delivered | missing_shipped |
|---|---|---|---|
| 99.441 | 0 | 0 | 0 |

**Hallazgo:** Los campos de fecha no son NULL sino strings vacíos `''` — consecuencia de cómo el script Python cargó los CSVs. Al desglosar por status se confirma que los vacíos corresponden a órdenes no entregadas o canceladas, no a errores aleatorios.

| order_status | filas |
|---|---|
| delivered | 96.478 |
| shipped | 1.107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

**Resolución en staging:** `NULLIF(campo, '')` en `stg_orders` convierte los strings vacíos en NULL real.

### Products — categoría y peso
| total | missing_category | missing_weight |
|---|---|---|
| 32.951 | 0 | 0 |

**Hallazgo:** Mismo patrón — strings vacíos en lugar de NULL.

### Reviews — comentarios
| total | missing_title | missing_message |
|---|---|---|
| 99.224 | 0 | 0 |

**Hallazgo:** Los comentarios vacíos llegan como `''`. Es esperable que muchos clientes no escriban comentario — no es un error, pero hay que normalizar a NULL.

**Resolución en staging:** `NULLIF(TRIM(review_comment_title), '')` y `NULLIF(TRIM(review_comment_message), '')` en `stg_order_reviews`.

---

## 2. Uniqueness — Duplicados

### Geolocation
```sql
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zips,
  COUNT(*) / COUNT(DISTINCT geolocation_zip_code_prefix) AS avg_rows_per_zip
FROM GEOLOCATION;
```

| total_rows | unique_zips | avg_rows_per_zip |
|---|---|---|
| 1.000.163 | 19.015 | 52,6 |

Top 5 zip codes con más duplicados:

| zip_code_prefix | repeticiones |
|---|---|
| 24220 | 1.146 |
| 24230 | 1.102 |
| 38400 | 965 |
| 35500 | 907 |
| 11680 | 879 |

**Hallazgo:** Cada zip code tiene de media 52 filas con coordenadas ligeramente distintas. No es posible usar esta tabla directamente para joins — necesita agregación.

**Resolución en staging:** `stg_geolocation` filtra coordenadas fuera de Brasil y agrega con `AVG(lat)` / `AVG(lng)` agrupando por `zip_code_prefix`, resultando en una fila por zip.

### Reviews — review_id duplicado
```sql
SELECT review_id, COUNT(*) AS times
FROM ORDER_REVIEWS GROUP BY review_id
HAVING COUNT(*) > 1 ORDER BY times DESC LIMIT 5;
```

| review_id | veces |
|---|---|
| 2172867fd5b1a55f98fe4608e1547b4b | 3 |
| 4d0e6dd087008d1f992d25ef6e1f619f | 3 |
| 44e9f871226d8a130de3fc39dfbdf0c5 | 3 |

**Hallazgo:** `review_id` no es único en el source — hay IDs que aparecen hasta 3 veces.

**Resolución:** Se documenta aquí. Se deduplicará en CORE al construir la dimensión de reviews.

---

## 3. Granularity — ¿Qué es una fila?

### Customers — customer_id vs customer_unique_id
```sql
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT customer_id) AS customer_id_distinct,
  COUNT(DISTINCT customer_unique_id) AS real_customers
FROM CUSTOMERS;
```

| total_rows | customer_id_distinct | real_customers |
|---|---|---|
| 99.441 | 99.441 | 96.096 |

**Hallazgo:** `customer_id` es único por orden (99.441 = total de filas), no por cliente real. `customer_unique_id` tiene 96.096 valores únicos — esos son los clientes reales. Confundir ambos campos rompe cualquier análisis de retención o repurchase rate.

**Resolución en staging:** Ambos campos se mantienen con sus nombres originales y se documentan claramente. En CORE se usará `customer_unique_id` como clave de la dimensión de clientes.

### Order Items — líneas por pedido
Un pedido puede tener hasta 21 líneas. No se agrega en staging — la suma de importes se calcula en CORE.

### Order Payments — pagos por pedido
Un pedido puede tener hasta 29 pagos distintos (por ejemplo, combinando tarjeta de crédito y voucher). No se agrega en staging.

---

## 4. Validity — Valores imposibles o anómalos

### Payment type
| payment_type | filas |
|---|---|
| credit_card | 76.795 |
| boleto | 19.784 |
| voucher | 5.775 |
| debit_card | 1.529 |
| not_defined | 3 |

**Hallazgo:** 3 filas con `not_defined` como tipo de pago. Se pasan a staging y se filtrarán en CORE.

### Payment installments
**Hallazgo:** 2 filas con `payment_installments = 0` — valor imposible (mínimo debería ser 1). Se gestionará en CORE.

### Coordenadas fuera de Brasil
```sql
SELECT COUNT(*) AS coords_outside_brazil
FROM GEOLOCATION
WHERE TRY_TO_DOUBLE(geolocation_lat) NOT BETWEEN -34 AND 5
   OR TRY_TO_DOUBLE(geolocation_lng) NOT BETWEEN -74 AND -34;
```

| coords_outside_brazil |
|---|
| 42 |

**Hallazgo:** 42 coordenadas fuera de los límites de Brasil (lat [-34, 5], lng [-74, -34]). Pueden ser typos o valores por defecto erróneos.

**Resolución en staging:** `stg_geolocation` las elimina con un `WHERE BETWEEN` antes de agregar.

---

## 5. Referential Integrity — ¿Los keys joinean?

### Categorías sin traducción
```sql
SELECT COUNT(DISTINCT p.product_category_name) AS categories_without_translation
FROM PRODUCTS p
LEFT JOIN PRODUCT_CATEGORY_NAME_TRANSLATION t
  ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;
```

| categories_without_translation |
|---|
| 3 |

**Hallazgo:** 3 categorías en `products` no tienen traducción al inglés. El join en CORE devolverá NULL para esas categorías.

**Resolución:** `LEFT JOIN` en CORE. No se resuelve en staging porque staging no hace joins.

### Items sin orden (foreign key huérfano)
| items_without_order |
|---|
| 0 |

**Hallazgo:** Integridad referencial perfecta — todos los `order_id` en `order_items` existen en `orders`.

---

## 6. Types — Tipos disfrazados como texto

En RAW todas las columnas son VARCHAR. Se verifica que los casteos no van a generar NULLs inesperados.

### Fechas en ORDERS
| total | dates_parseable |
|---|---|
| 99.441 | 99.441 |

**Hallazgo:** El 100% de los timestamps parsean correctamente con `TRY_TO_TIMESTAMP`.

### Precios en ORDER_ITEMS
| total | price_ok | freight_ok |
|---|---|---|
| 112.650 | 112.650 | 112.650 |

**Hallazgo:** El 100% de los valores numéricos parsean correctamente con `TRY_TO_DOUBLE`.

### Typos en PRODUCTS
Dos columnas llegan con nombre incorrecto desde el source:
- `product_name_lenght` → debería ser `product_name_length`
- `product_description_lenght` → debería ser `product_description_length`

**Resolución en staging:** Se heredan los nombres incorrectos del source y se corrigen con alias en `stg_products`.

---

## Resumen de decisiones

| Dimensión | Hallazgo | Dónde se resuelve |
|---|---|---|
| Completeness | Strings vacíos `''` en lugar de NULL | STAGING — `NULLIF` |
| Uniqueness | ~52 filas por zip en geolocation | STAGING — `AVG + GROUP BY` |
| Uniqueness | `review_id` duplicado | CORE |
| Granularity | `customer_id` ≠ `customer_unique_id` | Documentado en STAGING, resuelto en CORE |
| Validity | 42 coordenadas fuera de Brasil | STAGING — filtro `WHERE BETWEEN` |
| Validity | 3 pagos `not_defined`, 2 con 0 cuotas | CORE |
| Integrity | 3 categorías sin traducción | CORE — `LEFT JOIN` |
| Types | Fechas y números como VARCHAR | STAGING — `TRY_TO_TIMESTAMP`, `TRY_TO_DOUBLE` |
| Types | Typos en columnas de `products` | STAGING — alias en `stg_products` |
