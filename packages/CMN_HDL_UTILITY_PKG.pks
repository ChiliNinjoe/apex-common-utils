CREATE OR REPLACE PACKAGE cmn_hdl_utility_pkg IS
    FUNCTION submit_hdl_job (
        p_fa_domain             IN  VARCHAR2
      , p_credential_static_id  IN  VARCHAR2
      , p_hdl_filename          IN  VARCHAR2
      , p_hdl_author            IN  VARCHAR2
      , p_hdl_blob              IN  BLOB
      , p_timeout_minutes       IN  NUMBER DEFAULT 60
      , p_monitoring            IN  VARCHAR2 DEFAULT 'ON'
      , p_success_callback      IN  VARCHAR2 DEFAULT NULL
      , p_failure_callback      IN  VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_job_status (
        p_job_id IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_job_record (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    FUNCTION upload_to_webcenter (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    FUNCTION import_and_load (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    FUNCTION update_hdl_status (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    PROCEDURE initiate_job (
        p_job_id IN NUMBER
    );

END cmn_hdl_utility_pkg;