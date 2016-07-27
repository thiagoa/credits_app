\x off

EXPLAIN ANALYZE SELECT user_id FROM "credits" WHERE (expires_at <= '2014-01-01') 
AND "credits"."processed" = 'f' AND ("credits"."user_id" IS NOT NULL); 

EXPLAIN ANALYZE SELECT sum(amount), user_id FROM "credits" WHERE (expires_at <= 
  '2014-01-01') AND "credits"."user_id" IN (SELECT DISTINCT "credits"."user_id" 
  FROM "credits" WHERE (expires_at <= '2014-01-01') AND "credits"."processed" = 
  'f' AND ("credits"."user_id" IS NOT NULL)) GROUP BY "credits"."user_id"; 

EXPLAIN ANALYZE SELECT SUM(amount), user_id FROM credits AS c
WHERE (c.user_id IN
  (SELECT DISTINCT "credits"."user_id" FROM "credits" WHERE (expires_at <=
  '2014-03-01') AND "credits"."processed" = 'f' AND ("credits"."user_id" IS
  NOT NULL))
) AND (c.created_at >=
  (SELECT MIN(created_at) FROM "credits" WHERE credits.user_id = c.user_id AND
    "credits"."expires_at" IS NOT NULL)
) AND (c.amount < 0) GROUP BY c.user_id;
