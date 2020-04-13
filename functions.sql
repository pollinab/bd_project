CREATE TYPE low_calory_dish_result AS (dish_category text, dish_name text);

CREATE FUNCTION low_calory_dish(dish_category text) RETURNS low_calory_dish_result
AS
$$
SELECT $1, Dish.name
FROM Dish
       INNER JOIN Category ON Dish.cat_id = Category.cat_id
WHERE Category.name = dish_category
ORDER BY cal_val
LIMIT 1
$$
  LANGUAGE SQL;

SELECT *
FROM low_calory_dish('Первые блюда');

CREATE FUNCTION low_calory_menu() RETURNS table
                                          (
                                            category_name text,
                                            dish_name     text
                                          )
AS
$$
SELECT low_calory_dish(name)
FROM Category
$$
  LANGUAGE SQL;

SELECT *
FROM low_calory_menu();

CREATE TABLE if not exists menu
AS
SELECT name AS dish_name
FROM (SELECT name,
             row_number() OVER (PARTITION BY cat_id ORDER BY random()) AS rn
      FROM Dish) AS add_table
WHERE rn = 1;

SELECT *
FROM menu;

CREATE FUNCTION get_random_menu() RETURNS table
                                          (
                                            dish_name text
                                          )
AS
$$
SELECT name
FROM (SELECT name,
             row_number() OVER (PARTITION BY cat_id ORDER BY random()) AS rn
      FROM Dish) AS add_table
WHERE rn = 1
$$
  LANGUAGE SQL;

SELECT *
FROM get_random_menu();

CREATE FUNCTION menu_calory() RETURNS real
AS
$$
SELECT sum(cal_val)
FROM Dish
       INNER JOIN menu ON name = dish_name;
$$
  LANGUAGE SQL;

SELECT *
FROM menu_calory();


CREATE FUNCTION get_products(dish_name text, people integer) RETURNS table
                                                                     (
                                                                       pr_name   text,
                                                                       pr_weight float,
                                                                       pr_unit   text
                                                                     )
AS
$$
SELECT P.name, (gr_wt / 100) * people, P.unit
FROM Product P
       INNER JOIN ProductInDish PID on P.product_id = PID.product_id
       INNER JOIN Dish D on PID.dish_id = D.dish_id
WHERE D.name = dish_name
$$
  LANGUAGE SQL;

SELECT *
FROM get_products(' Винегрет овощной с зеленым горошком', 5);

CREATE FUNCTION get_products_for_menu(people integer) RETURNS table
                                                              (
                                                                pr_name   text,
                                                                pr_weight float,
                                                                pr_unit   text
                                                              )
AS
$$
SELECT P.name, sum((gr_wt / 100) * people), unit
FROM Product P
       INNER JOIN ProductInDish PID on P.product_id = PID.product_id
       INNER JOIN Dish D on PID.dish_id = D.dish_id
WHERE D.name IN (SELECT dish_name FROM menu)
GROUP BY P.name, P.unit
$$
  LANGUAGE SQL;

SELECT pr_name, round(cast(pr_weight as numeric), 5), pr_unit
FROM get_products_for_menu(15)
ORDER BY pr_weight DESC;

CREATE FUNCTION get_utensils_for_menu() RETURNS table
                                                (
                                                  ut_name text
                                                )
AS
$$
SELECT DISTINCT U.name
FROM Utensil U
       INNER JOIN UtensilForDish UFD on U.utensil_id = UFD.utensil_id
       INNER JOIN Dish D on UFD.dish_id = D.dish_id
WHERE D.name IN (SELECT dish_name FROM menu)
$$
  LANGUAGE SQL;

SELECT *
FROM get_utensils_for_menu();

DROP FUNCTION if exists show_analogs;

CREATE FUNCTION show_analogs(dish_name text) RETURNS table
                                                     (
                                                       pr_name     text,
                                                       analog_name text,
                                                       pr_amount   real,
                                                       pr_unit     text,
                                                       a_amount    real,
                                                       a_unit      text
                                                     )
AS
$$
WITH All_products(name, id, weight, un) AS (
  SELECT P.name, P.product_id, gr_wt, unit
  FROM Product P
         INNER JOIN ProductInDish PID on P.product_id = PID.product_id
         INNER JOIN Dish D on PID.dish_id = D.dish_id
  WHERE D.name = dish_name
)
SELECT All_products.name, Pr.name, weight, un, weight * coefficient, Pr.unit
FROM All_products
       LEFT JOIN Analog A ON id = A.product_id
       LEFT JOIN Product Pr on A.analog_id = Pr.product_id
$$
  LANGUAGE SQL;


SELECT *
FROM show_analogs(' Суп-пюре из разных овощей с ржан.гренками');
