create or replace PACKAGE cmn_bip_utility_pkg AS
/* Dependencies:
 *    cmn_credentials_pkg
 */
    PROCEDURE create_data_model (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_sql          IN  CLOB DEFAULT NULL -- SELECT ONE: Provide sql
      , p_xdm_xml      IN  CLOB DEFAULT NULL --          or xdm XML
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
        p_path             IN   VARCHAR2
      , p_name             IN   VARCHAR2
      , p_credentials      IN   cmn_credentials_pkg.acct_creds
      , p_parameters       IN   apex_t_varchar2 DEFAULT NULL
      , p_collection_name  IN   VARCHAR2
      , p_rows             OUT  NUMBER
    );

END cmn_bip_utility_pkg;