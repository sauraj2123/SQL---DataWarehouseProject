/*
===============================================================================
Quality Checks: Gold Layer (PostgreSQL)
===============================================================================
What this script does:
    Checks that the star schema is sound:
      - Surrogate keys in each dimension are unique.
      - Every sale links to a customer and a product.

How to use:
    Run after creating the gold views. Every check should return NO rows.
===============================================================================
*/

-- ============================================================================
-- gold.dim_customers
-- ============================================================================

-- Duplicate customer keys. Expect: no rows
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ============================================================================
-- gold.dim_products
-- ============================================================================

-- Duplicate product keys. Expect: no rows
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ============================================================================
-- gold.fact_sales
-- ============================================================================

-- Sales with no matching customer or product. Expect: no rows
SELECT
    *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;
