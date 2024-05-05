CREATE OR REPLACE PACKAGE lob_vars_pkg AS
    -- -----------------------------------------------------------------------------------
    -- Author       : Joe Ngo
    -- Description  : Helper package for prototyping/debugging in SQL Developer.
    --                Creates a package for storing LOB objects that can be referenced 
    --                by another SQL statement within a session.
    -- Last Modified: Apr 30, 2024
    -- -----------------------------------------------------------------------------------
    PROCEDURE set_clob (
        p_data IN CLOB
    );

    FUNCTION get_blob RETURN BLOB;

    FUNCTION get_clob RETURN CLOB;

END lob_vars_pkg;