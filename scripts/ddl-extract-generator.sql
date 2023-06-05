clear screen
set feedback off
set serveroutput on SIZE UNLIMITED
set define off
whenever sqlerror exit

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
                substr(
                    view_name
                  , 1
                  , 3
                ) != 'XY_' -- exclude application-generated views
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    user_dependencies
                WHERE
                        name = uv.view_name
                    AND type = 'VIEW'
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
                                                           AND uc1.r_constraint_name =
                                                           uc2.constraint_name
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
                AND substr(
                    view_name
                  , 1
                  , 3
                ) != 'XY_' -- exclude application-generated views
                AND NOT EXISTS (
                    SELECT
                        referenced_name
                    FROM
                        user_dependencies
                    WHERE
                            name = uv.view_name
                        AND type = 'VIEW'
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
    l_index_count   INTEGER;
    l_trigger_count INTEGER;
BEGIN
    dbms_output.put_line(q'[CLEAR SCREEN
SET FEEDBACK off
SET LONG 2000000
SET PAGESIZE 0
SET LINESIZE 32000
SET WRAP OFF
WHENEVER SQLERROR EXIT

EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'COLLATION_CLAUSE','NEVER');
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'CONSTRAINTS',true);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'REF_CONSTRAINTS',true);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',false);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'TABLESPACE',false);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'TABLE_COMPRESSION_CLAUSE','NONE');
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'LOB_STORAGE','NO_CHANGE');
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'FORCE',false);

ACCEPT base_folder_name PROMPT 'Full path to output (ddl) folder: '
CD "&base_folder_name"
set encoding UTF-8

-- Reset all-DDLs.sql
SPOOL all-DDLs.sql
PROMPT /******************************/
PROMPT /* Consolidated master script */
PROMPT /******************************/
PROMPT
SPOOL off

]');

    -- Add Sequences
    dbms_output.put_line('SPOOL all-DDLs.sql APPEND');
    dbms_output.put_line('PROMPT @"sequences.sql"');
    dbms_output.put_line('SPOOL off');
    dbms_output.put_line('SPOOL "sequences.sql"');
    FOR s IN (
        SELECT
            sequence_name
        FROM
            user_sequences
        WHERE
            sequence_name NOT LIKE 'ISEQ$$%'
        ORDER BY
            sequence_name
    ) LOOP
        dbms_output.put_line('EXEC dbms_output.put_line( REGEXP_REPLACE(REPLACE(dbms_metadata.get_ddl(''SEQUENCE'', '''
                             || s.sequence_name
                             || '''), ''"'
                             || user
                             || '".''), ''START WITH \d+'', ''START WITH 1'') );');
    END LOOP;

    dbms_output.put_line('SPOOL off');
    -- Add Types
    dbms_output.put_line('SPOOL all-DDLs.sql APPEND');
    dbms_output.put_line('PROMPT @"types.sql"');
    dbms_output.put_line('SPOOL off');
    dbms_output.put_line('SPOOL "types.sql"');
    FOR typ IN (
        SELECT
            type_name
        FROM
            user_types
        ORDER BY
            type_name
    ) LOOP
        dbms_output.put_line('EXEC dbms_output.put_line( REPLACE(dbms_metadata.get_ddl(''TYPE'', '''
                             || typ.type_name
                             || '''), ''"'
                             || user
                             || '".'') );');
    END LOOP;

    dbms_output.put_line('SPOOL off');

    -- Add Tables
    FOR t IN (
        SELECT
            table_name
        FROM
            ora$ptt_ddl_tables
        ORDER BY
            ddl_level ASC
          , table_name ASC
    ) LOOP
        dbms_output.put_line('SPOOL all-DDLs.sql APPEND');
        dbms_output.put_line('PROMPT @"tables\'
                             || t.table_name
                             || '.sql"');
        dbms_output.put_line('SPOOL off');
        SELECT
            COUNT(*)
        INTO l_index_count
        FROM
            user_indexes
        WHERE
            table_name = t.table_name;

        SELECT
            COUNT(*)
        INTO l_trigger_count
        FROM
            user_triggers
        WHERE
                table_name = t.table_name
            AND base_object_type = 'TABLE';

        dbms_output.put_line('SPOOL "tables\'
                             || t.table_name
                             || '.sql"');
        dbms_output.put_line('EXEC dbms_output.put_line( REGEXP_REPLACE(REPLACE(dbms_metadata.get_ddl(''TABLE'', '''
                             || t.table_name
                             || '''), ''"'
                             || user
                             || '".''), '' SEGMENT CREATION IMMEDIATE(  LOGGING)?'') );');

        IF l_index_count > 0 THEN
            dbms_output.put_line('EXEC dbms_output.put_line( REGEXP_REPLACE(REPLACE(dbms_metadata.get_dependent_ddl(''INDEX'', '''
                                 || t.table_name
                                 || '''), ''"'
                                 || user
                                 || '".''), ''CREATE UNIQUE INDEX "SYS_IL.*?;(\s+)?'', '''', 1, 0, ''mn'') );'); -- exclude empty system-generated SYS_IL% indexes
        END IF;

        IF l_trigger_count > 0 THEN
            dbms_output.put_line('EXEC dbms_output.put_line( REPLACE(dbms_metadata.get_dependent_ddl(''TRIGGER'', '''
                                 || t.table_name
                                 || '''), ''"'
                                 || user
                                 || '".'') );');
        END IF;

        dbms_output.put_line('SPOOL off');
    END LOOP;

    -- Add Views
    FOR v IN (
        SELECT
            view_name
        FROM
            ora$ptt_ddl_views
        ORDER BY
            ddl_level ASC
          , view_name ASC
    ) LOOP
        dbms_output.put_line('SPOOL all-DDLs.sql APPEND');
        dbms_output.put_line('PROMPT @"views\'
                             || v.view_name
                             || '.sql"');
        dbms_output.put_line('SPOOL off');
        dbms_output.put_line('SPOOL "views\'
                             || v.view_name
                             || '.sql"');
        dbms_output.put_line('EXEC dbms_output.put_line( REPLACE(dbms_metadata.get_ddl(''VIEW'', '''
                             || v.view_name
                             || '''), ''"'
                             || user
                             || '".'') );');

        dbms_output.put_line('SPOOL off');
    END LOOP;

END;
/

DROP TABLE ora$ptt_ddl_tables;

DROP TABLE ora$ptt_ddl_views;

PROMPT "EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT');"