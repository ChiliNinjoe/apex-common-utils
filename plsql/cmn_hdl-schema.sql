DROP TABLE cmn_hdl_load_job_tbl;

CREATE TABLE cmn_hdl_load_job_tbl (
    id                             NUMBER
        GENERATED ALWAYS AS IDENTITY
    NOT NULL
    , job_status                     VARCHAR2(30 CHAR) DEFAULT ON NULL 'NEW'
    , timeout_minutes                NUMBER DEFAULT ON NULL 60
    , job_start_ts                   TIMESTAMP
    , job_end_ts                     TIMESTAMP
    , fa_domain                      VARCHAR2(255 CHAR) NOT NULL
    , credential_static_id           VARCHAR2(255 CHAR) NOT NULL
    , hdl_filename                   VARCHAR2(400 CHAR) NOT NULL
    , hdl_author                     VARCHAR2(400 CHAR) NOT NULL
    , hdl_blob                       BLOB NOT NULL
    , load_monitoring                VARCHAR2(3 CHAR) DEFAULT ON NULL 'ON'
    , load_parameters                VARCHAR2(4000 CHAR)
    , success_callback               VARCHAR2(400 CHAR)
    , failure_callback               VARCHAR2(400 CHAR)
    , callback_error_msg             CLOB
    , ucm_content_id                 VARCHAR2(255 CHAR)
    , hdl_process_id                 VARCHAR2(255 CHAR)
    , hdl_result_count               NUMBER
    , overall_status                 VARCHAR2(30 CHAR)
    , import_status                  VARCHAR2(30 CHAR)
    , import_percentage_complete     NUMBER(5, 2)
    , import_line_count_total        NUMBER
    , import_line_count_success      NUMBER
    , import_line_count_failed       NUMBER
    , import_line_count_unprocessed  NUMBER
    , load_status                    VARCHAR2(30 CHAR)
    , load_percentage_complete       NUMBER(5, 2)
    , load_line_count_total          NUMBER
    , load_line_count_success        NUMBER
    , load_line_count_failed         NUMBER
    , load_line_count_unprocessed    NUMBER
    , error_http_code                NUMBER
    , error_msg                      CLOB
    , CONSTRAINT cmn_hdl_load_job_tbl_pk PRIMARY KEY ( id )
    , CONSTRAINT cmn_hdl_load_job_tbl_status_chk CHECK ( job_status IN ( 'NEW', 'UPLOAD_PENDING', 'UPLOADED'
                                                                       , 'IMPORT_PENDING'
                                                                       , 'LOAD_PENDING'
                                                                       , 'COMPLETE'
                                                                       , 'TIMEOUT'
                                                                       , 'ERROR' ) )
    , CONSTRAINT cmn_hdl_load_job_tbl_monitoring_chk CHECK ( load_monitoring IN ( 'ON', 'OFF' ) )
);

DROP TABLE cmn_hdl_load_job_audit;

CREATE TABLE cmn_hdl_load_job_audit (
    audit_ts                       TIMESTAMP DEFAULT ON NULL systimestamp
    , job_id                         NUMBER
    , job_status                     VARCHAR2(30 CHAR)
    , job_start_ts                   TIMESTAMP
    , job_end_ts                     TIMESTAMP
    , ucm_content_id                 VARCHAR2(255 CHAR)
    , hdl_process_id                 VARCHAR2(255 CHAR)
    , hdl_result_count               NUMBER
    , overall_status                 VARCHAR2(30 CHAR)
    , import_status                  VARCHAR2(30 CHAR)
    , import_percentage_complete     NUMBER(5, 2)
    , import_line_count_total        NUMBER
    , import_line_count_success      NUMBER
    , import_line_count_failed       NUMBER
    , import_line_count_unprocessed  NUMBER
    , load_status                    VARCHAR2(30 CHAR)
    , load_percentage_complete       NUMBER(5, 2)
    , load_line_count_total          NUMBER
    , load_line_count_success        NUMBER
    , load_line_count_failed         NUMBER
    , load_line_count_unprocessed    NUMBER
    , error_http_code                NUMBER
    , error_msg                      CLOB
);

CREATE INDEX cmn_hdl_load_job_audit_id_ix ON
    cmn_hdl_load_job_audit (
        job_id
    )
        COMPRESS;

CREATE OR REPLACE TRIGGER cmn_hdl_load_job_tbl_hist_trg AFTER
    UPDATE ON cmn_hdl_load_job_tbl
    FOR EACH ROW
BEGIN
    INSERT INTO cmn_hdl_load_job_audit (
        job_id
        , job_status
        , job_start_ts
        , job_end_ts
        , ucm_content_id
        , hdl_process_id
        , hdl_result_count
        , overall_status
        , import_status
        , import_percentage_complete
        , import_line_count_total
        , import_line_count_success
        , import_line_count_failed
        , import_line_count_unprocessed
        , load_status
        , load_percentage_complete
        , load_line_count_total
        , load_line_count_success
        , load_line_count_failed
        , load_line_count_unprocessed
        , error_http_code
        , error_msg
    ) VALUES (
        :old.id
      , :old.job_status
      , :old.job_start_ts
      , :old.job_end_ts
      , :old.ucm_content_id
      , :old.hdl_process_id
      , :old.hdl_result_count
      , :old.overall_status
      , :old.import_status
      , :old.import_percentage_complete
      , :old.import_line_count_total
      , :old.import_line_count_success
      , :old.import_line_count_failed
      , :old.import_line_count_unprocessed
      , :old.load_status
      , :old.load_percentage_complete
      , :old.load_line_count_total
      , :old.load_line_count_success
      , :old.load_line_count_failed
      , :old.load_line_count_unprocessed
      , :old.error_http_code
      , :old.error_msg
    );

END cmn_hdl_load_job_tbl_hist_trg;
/