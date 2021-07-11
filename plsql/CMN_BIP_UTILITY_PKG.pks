CREATE OR REPLACE PACKAGE cmn_bip_utility_pkg AS
/* Dependencies:
 *    cmn_credentials_pkg
 */
    FUNCTION is_credential_valid (
        p_credentials IN cmn_credentials_pkg.acct_creds
    ) RETURN BOOLEAN;

    PROCEDURE create_folder (
        p_path         IN VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
    );

    PROCEDURE create_data_model (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_sql          IN  CLOB DEFAULT NULL -- SELECT ONE: Provide sql
      , p_xdm_xml      IN  CLOB DEFAULT NULL --          or xdm XML
      , p_data_source  IN  VARCHAR DEFAULT 'ApplicationDB_HCM'
      , p_replace      IN  VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE load_data_model_to_table (
        p_path         IN   VARCHAR2
      , p_name         IN   VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_parameters   IN   apex_t_varchar2 DEFAULT NULL
      , p_schema_name  IN   VARCHAR2
      , p_table_name   IN   VARCHAR2
      , p_errlog_tbl   IN   VARCHAR2 DEFAULT NULL
      , p_rows         OUT  NUMBER
    );

    PROCEDURE load_data_model_to_collection (
        p_path             IN  VARCHAR2
      , p_name             IN  VARCHAR2
      , p_credentials      IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_parameters       IN  apex_t_varchar2 DEFAULT NULL
      , p_collection_name  IN  VARCHAR2
    );

    PROCEDURE load_folder_contents_to_collection (
        p_path             IN  VARCHAR2
      , p_credentials      IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_collection_name  IN  VARCHAR2
    );

    FUNCTION get_data_model_sql (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
    ) RETURN CLOB;

    FUNCTION get_query_for_collection (
        p_collection_name     IN  VARCHAR2
      , p_designtime_columns  IN  VARCHAR2 DEFAULT 'DUMMY'
    ) RETURN CLOB;

    FUNCTION get_columns_for_collection (
        p_collection_name IN VARCHAR2
    ) RETURN CLOB;

END cmn_bip_utility_pkg;