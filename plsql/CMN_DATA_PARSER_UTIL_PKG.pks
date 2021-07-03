create or replace PACKAGE cmn_data_parser_util_pkg AS
    TYPE process_options IS RECORD (
        data_type_override  VARCHAR2(128)
        , reformat_date       VARCHAR2(60)
        , addl_columns        apex_t_varchar2 /* plist for additional columns to be added on insert SQL */
        , errlog_tbl          VARCHAR2(128)
        , load_id             VARCHAR2(2000)
    );
    PROCEDURE p_create_column_collection (
        p_app_temp_file IN apex_application_temp_files%rowtype
    );

    FUNCTION f_generate_column_ddl (
        p_collection_name  IN  VARCHAR2
      , p_options          IN  process_options
    ) RETURN CLOB;

    PROCEDURE p_get_file_to_process (
        p_app_temp_file  IN   apex_application_temp_files%rowtype
      , p_return_file    OUT NOCOPY apex_application_temp_files%rowtype
      , p_error_msg      OUT  VARCHAR2
    );

    PROCEDURE p_process_file_upload (
        p_schema_name    IN   VARCHAR2
      , p_table_name     IN   VARCHAR2
      , p_app_temp_file  IN   apex_application_temp_files%rowtype
      , p_options        IN   process_options
      , p_rows           OUT  NUMBER
    );

    FUNCTION f_get_file_from_os (
        p_base_url     IN  VARCHAR2
      , p_bucket_name  IN  VARCHAR2
      , p_filename     IN  VARCHAR2
    ) RETURN apex_application_temp_files%rowtype;

END cmn_data_parser_util_pkg;