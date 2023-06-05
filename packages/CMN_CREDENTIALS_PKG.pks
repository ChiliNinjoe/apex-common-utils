create or replace PACKAGE cmn_credentials_pkg AS
    TYPE acct_creds IS RECORD (
        fa_domain      VARCHAR2(128)
        , username       VARCHAR2(128)
        , password       VARCHAR2(128)
        , session_token  VARCHAR2(128)
    );
END cmn_credentials_pkg;