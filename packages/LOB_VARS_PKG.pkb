CREATE OR REPLACE PACKAGE BODY lob_vars_pkg AS

    clob_val CLOB;
    blob_val BLOB;

    FUNCTION clob_to_blob (
        p_data IN CLOB
    ) RETURN BLOB
    -- -----------------------------------------------------------------------------------
    -- Author       : Tim Hall
    -- Description  : Converts a CLOB to a BLOB.
    -- Last Modified: 26/12/2016
    -- -----------------------------------------------------------------------------------
     AS

        l_blob         BLOB;
        l_dest_offset  PLS_INTEGER := 1;
        l_src_offset   PLS_INTEGER := 1;
        l_lang_context PLS_INTEGER := dbms_lob.default_lang_ctx;
        l_warning      PLS_INTEGER := dbms_lob.warn_inconvertible_char;
    BEGIN
        dbms_lob.createtemporary(lob_loc => l_blob, cache => TRUE);
        dbms_lob.converttoblob(dest_lob => l_blob
                             , src_clob => p_data
                             , amount => dbms_lob.lobmaxsize
                             , dest_offset => l_dest_offset
                             , src_offset => l_src_offset
                             , blob_csid => dbms_lob.default_csid
                             , lang_context => l_lang_context
                             , warning => l_warning);

        RETURN l_blob;
    END clob_to_blob;

    PROCEDURE set_clob (
        p_data IN CLOB
    ) AS
    BEGIN
        clob_val := p_data;
        blob_val := clob_to_blob(p_data);
    END set_clob;

    FUNCTION get_blob RETURN BLOB IS
    BEGIN
        RETURN blob_val;
    END get_blob;

    FUNCTION get_clob RETURN CLOB IS
    BEGIN
        RETURN clob_val;
    END get_clob;

END lob_vars_pkg;