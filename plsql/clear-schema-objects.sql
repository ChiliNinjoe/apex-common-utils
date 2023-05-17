CLEAR SCREEN
   set serveroutput on
SHOW USER

CREATE PRIVATE TEMPORARY TABLE ora$ptt_ddl_tables ON COMMIT PRESERVE DEFINITION
    AS
        -- Populate with tables with no foreign keys
        SELECT
            table_name
          , 0 AS ddl_level
          FROM
            user_tables ut
         WHERE
            NOT EXISTS (
                SELECT
                    1
                  FROM
                    user_constraints
                 WHERE
                        table_name = ut.table_name
                       AND constraint_type = 'R'
            );

CREATE PRIVATE TEMPORARY TABLE ora$ptt_ddl_views ON COMMIT PRESERVE DEFINITION
    AS
        -- Populate with views with no dependent views
        SELECT
            view_name
          , 0 AS ddl_level
          FROM
            user_views uv
         WHERE
                substr(view_name, 1, 3) != 'XY_' -- exclude application-generated views
               AND NOT EXISTS (
                SELECT
                    1
                  FROM
                    user_dependencies
                 WHERE
                        name = uv.view_name
                       AND type            = 'VIEW'
                       AND referenced_type = 'VIEW'
            );

DECLARE
    l_ddl_level INTEGER := 1;
BEGIN
    /* Add table names to ora$ptt_ddl_tables where referenced table are already included */
    LOOP
        INSERT INTO ora$ptt_ddl_tables (
            table_name
            , ddl_level
        )
            SELECT
                table_name
              , l_ddl_level
              FROM
                user_tables ut
             WHERE
                table_name NOT IN (
                    SELECT
                        table_name
                      FROM
                        ora$ptt_ddl_tables
                )
                   AND NOT EXISTS (
                    SELECT
                        uc2.table_name
                      FROM
                             user_constraints uc1
                         INNER JOIN user_constraints uc2 ON uc1.r_owner = uc2.owner
                           AND uc1.r_constraint_name = uc2.constraint_name
                     WHERE
                            uc1.table_name = ut.table_name
                           AND uc1.constraint_type = 'R'
                    MINUS
                    SELECT
                        table_name
                      FROM
                        ora$ptt_ddl_tables
                );

        IF SQL%rowcount = 0 THEN
            EXIT;
        END IF;
        l_ddl_level := l_ddl_level + 1;
    END LOOP;
END;
/

DECLARE
    l_ddl_level INTEGER := 1;
BEGIN
    /* Add view names to ora$ptt_ddl_views where referenced views are already included */
    LOOP
        INSERT INTO ora$ptt_ddl_views (
            view_name
            , ddl_level
        )
            SELECT
                view_name
              , l_ddl_level
              FROM
                user_views uv
             WHERE
                view_name NOT IN (
                    SELECT
                        view_name
                      FROM
                        ora$ptt_ddl_views
                )
                   AND NOT EXISTS (
                    SELECT
                        referenced_name
                      FROM
                        user_dependencies
                     WHERE
                            name = uv.view_name
                           AND type            = 'VIEW'
                           AND referenced_type = 'VIEW'
                    MINUS
                    SELECT
                        view_name
                      FROM
                        ora$ptt_ddl_views
                );

        IF SQL%rowcount = 0 THEN
            EXIT;
        END IF;
        l_ddl_level := l_ddl_level + 1;
    END LOOP;
END;
/

DECLARE
    l_sql VARCHAR2(4000);
BEGIN
    FOR o IN (
        SELECT
            *
          FROM
            user_objects
         WHERE
            object_type IN ( 'FUNCTION', 'PROCEDURE', 'PACKAGE'
                           , 'TYPE' )
         ORDER BY
            decode(object_type, 'FUNCTION', 1
                 , 'PROCEDURE', 2, 'PACKAGE'
                 , 3, 'TYPE', 4)
    ) LOOP
        l_sql := 'DROP '
                 || o.object_type
                 || ' '
                 || o.object_name;
        dbms_output.put_line(l_sql);
        EXECUTE IMMEDIATE l_sql;
    END LOOP;

    FOR v IN (
        SELECT
            view_name
          FROM
            ora$ptt_ddl_views
         ORDER BY
            ddl_level DESC
    ) LOOP
        l_sql := 'DROP VIEW ' || v.view_name;
        dbms_output.put_line(l_sql);
        EXECUTE IMMEDIATE l_sql;
    END LOOP;

    FOR t IN (
        SELECT
            table_name
          FROM
            ora$ptt_ddl_tables
         ORDER BY
            ddl_level DESC
    ) LOOP
        l_sql := 'DROP TABLE ' || t.table_name;
        dbms_output.put_line(l_sql);
        EXECUTE IMMEDIATE l_sql;
    END LOOP;

    FOR s IN (
        SELECT
            *
          FROM
            user_objects
         WHERE
            object_type IN ( 'SEQUENCE' )
    ) LOOP
        BEGIN
            l_sql := 'DROP '
                     || s.object_type
                     || ' '
                     || s.object_name;
            dbms_output.put_line(l_sql);
            EXECUTE IMMEDIATE l_sql;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line(sqlerrm);
        END;
    END LOOP;
    
    EXECUTE IMMEDIATE 'PURGE RECYCLEBIN';

END;
/