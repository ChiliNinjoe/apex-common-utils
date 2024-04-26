create or replace PACKAGE BODY cmn_hdl_utility_pkg IS

    c_monitoring_interval_seconds NUMBER := 10;
    FUNCTION clob_to_blob (
        p_data IN CLOB
    ) RETURN BLOB;

    FUNCTION get_webcenter_url (
        p_domain IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_hdl_url (
        p_domain IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE update_job_record (
        p_job IN cmn_hdl_load_job_tbl%rowtype
    );

    PROCEDURE monitor_job (
        p_job_id IN NUMBER
    );

    /**
    * Submits a HCM Data Loader (HDL) job with the specified parameters and returns the job ID.
    * 
    * @param p_fa_domain The Fusion Applications domain.
    * @param p_credential_static_id The credential static ID for accessing services.
    * @param p_hdl_filename The filename for the HDL file to be processed.
    * @param p_hdl_author The author of the HDL file.
    * @param p_hdl_blob The binary content of the HDL file as a BLOB.
    * @param p_timeout_minutes The timeout period in minutes for the job before it is forcibly terminated. Defaults to 60 minutes.
    * @param p_monitoring Indicates whether monitoring is enabled ('ON' or 'OFF'). Defaults to 'ON'.
    * @param p_success_callback The name of the callback procedure to execute upon successful completion.
    * @param p_failure_callback The name of the callback procedure to execute if the job fails.
    * @return The job ID as a NUMBER.
    */
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
    ) RETURN NUMBER IS
        l_job_id              cmn_hdl_load_job_tbl.id%TYPE;
        l_scheduler_job_name  VARCHAR2(128);
    BEGIN
        l_scheduler_job_name := dbms_scheduler.generate_job_name('CMN_HDL_LOAD');
        INSERT INTO cmn_hdl_load_job_tbl (
            scheduler_job_name
            , fa_domain
            , credential_static_id
            , hdl_filename
            , hdl_author
            , hdl_blob
            , timeout_minutes
            , load_monitoring
            , success_callback
            , failure_callback
        ) VALUES (
            l_scheduler_job_name
          , p_fa_domain
          , p_credential_static_id
          , p_hdl_filename
          , p_hdl_author
          , p_hdl_blob
          , p_timeout_minutes
          , p_monitoring
          , p_success_callback
          , p_failure_callback
        ) RETURNING id INTO l_job_id;

        COMMIT;
        
        -- Invoke scheduler job
        dbms_scheduler.create_job(job_name => l_scheduler_job_name, program_name => 'CMN_HDL_LOAD', comments =>('HDL Load Job #'
                                                                                                                || l_job_id)
                                , enabled => false);

        dbms_scheduler.set_job_argument_value(job_name => l_scheduler_job_name, argument_name => 'p_job_id'
                                            , argument_value => l_job_id);

        dbms_scheduler.enable(l_scheduler_job_name); 
                
        -- Return job ID
        RETURN l_job_id;
    END submit_hdl_job;

    /**
    * Retrieves the status of a given HDL job by its ID.
    * 
    * @param p_job_id The job ID.
    * @return The status of the job as VARCHAR2.
    */
    FUNCTION get_job_status (
        p_job_id IN NUMBER
    ) RETURN VARCHAR2 IS
        l_status cmn_hdl_load_job_tbl.job_status%TYPE;
    BEGIN
        SELECT
            job_status
          INTO l_status
          FROM
            cmn_hdl_load_job_tbl
         WHERE
            id = p_job_id;

        RETURN l_status;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_job_status;

    /**
    * Fetches a record from the HDL job table corresponding to the given job ID.
    * 
    * @param p_job_id The job ID.
    * @return A record from the HDL job table (based on the defined %rowtype).
    */
    FUNCTION get_job_record (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype IS
        l_job cmn_hdl_load_job_tbl%rowtype;
    BEGIN
        SELECT
            *
          INTO l_job
          FROM
            cmn_hdl_load_job_tbl
         WHERE
            id = p_job_id;

        RETURN l_job;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_job_record;

    /**
    * Uploads the specified HDL job to WebCenter and updates its record with the upload status.
    * 
    * @param p_job_id The job ID.
    * @return The updated job record after attempting the upload.
    */
    FUNCTION upload_to_webcenter (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype IS
        l_job           cmn_hdl_load_job_tbl%rowtype;
        l_payload       CLOB;
        l_fileblob_b64  CLOB;
        l_http_code     NUMBER;
        l_response      CLOB;
        l_resp_xml      CLOB;
    BEGIN
        l_job                   := get_job_record(p_job_id);
        l_job.job_start_ts      := systimestamp;
        l_fileblob_b64          := apex_web_service.blob2clobbase64(l_job.hdl_blob);
        l_payload               := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ucm="http://www.oracle.com/UCM" xmlns:wsse="http://schemas.xmlsoap.org/ws/2003/06/secext">
    <soapenv:Header />
    <soapenv:Body>
        <ucm:GenericRequest webKey="cs">
            <ucm:Service IdcService="CHECKIN_UNIVERSAL">
                <ucm:User />
                <ucm:Document>
                    <ucm:Field name="dDocTitle">Load %1</ucm:Field>
                    <ucm:Field name="dDocType">Document</ucm:Field>
                    <ucm:Field name="dDocAuthor">%0</ucm:Field>
                    <ucm:Field name="dSecurityGroup">FAFusionImportExport</ucm:Field>
                    <ucm:Field name="dDocAccount">hcm$/dataloader$/import$</ucm:Field>
                    <ucm:Field name="primaryFile">%1</ucm:Field>
                    <ucm:File href="%1" name="primaryFile">
                        <ucm:Contents>'
                                      , l_job.hdl_author
                                      , l_job.hdl_filename)
                     || l_fileblob_b64
                     || '</ucm:Contents>
                    </ucm:File>
                </ucm:Document>
            </ucm:Service>
        </ucm:GenericRequest>
    </soapenv:Body>
</soapenv:Envelope>';

        l_job.job_status        := 'UPLOAD_PENDING';
        update_job_record(l_job);
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => 'urn:GenericSoap/GenericSoapOperation'
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response              := apex_web_service.make_rest_request(p_url => get_webcenter_url(l_job.fa_domain)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload
                                                       , p_credential_static_id => l_job.credential_static_id);

        l_http_code             := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_job.job_status         := 'ERROR';
            l_job.error_http_code    := l_http_code;
            l_job.error_msg          := l_response;
            update_job_record(l_job);
            RETURN l_job;
        END IF;

        /* Expect response has MIME wrapper, so need to extract document text */
        l_resp_xml              := regexp_substr(l_response, '<\?xml.*</env:Envelope>', 1
                                  , 1, 'mn');
        l_job.ucm_content_id    := apex_web_service.parse_xml(p_xml => xmltype.createxml(l_resp_xml), p_xpath => '//Document/Field[@name="dDocName"]/text()'
                                                         , p_ns => 'xmlns="http://www.oracle.com/UCM"');

        IF l_job.ucm_content_id IS NOT NULL THEN
            l_job.job_status := 'UPLOADED';
        ELSE
            l_job.job_status         := 'ERROR';
            l_job.error_http_code    := l_http_code;
            l_job.error_msg          := l_response;
        END IF;

        update_job_record(l_job);
        RETURN l_job;
    EXCEPTION
        WHEN OTHERS THEN
            l_job.job_status    := 'ERROR';
            l_job.error_msg     := sqlerrm;
            update_job_record(l_job);
            RETURN l_job;
    END upload_to_webcenter;

    /**
    * Performs the import and load operation for the specified HDL job and updates its status accordingly.
    * 
    * @param p_job_id The job ID.
    * @return The updated job record post import and load operation.
    */
    FUNCTION import_and_load (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype IS
        l_job        cmn_hdl_load_job_tbl%rowtype;
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_err        CLOB;
    BEGIN
        l_job                   := get_job_record(p_job_id);
        l_payload               := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/hcm/common/dataLoader/core/dataLoaderIntegrationService/types/">
   <soapenv:Header/>
   <soapenv:Body>
      <typ:importAndLoadData>
         <typ:ContentId>%0</typ:ContentId>
         <typ:Parameters>%1</typ:Parameters>
      </typ:importAndLoadData>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , l_job.ucm_content_id
                                      , l_job.load_parameters);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => 'http://xmlns.oracle.com/apps/hcm/common/dataLoader/core/dataLoaderIntegrationService/importAndLoadData'
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response              := apex_web_service.make_rest_request(p_url => get_hdl_url(l_job.fa_domain)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload
                                                       , p_credential_static_id => l_job.credential_static_id);

        l_http_code             := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_job.job_status         := 'ERROR';
            l_job.error_http_code    := l_http_code;
            l_job.error_msg          := l_response;
            update_job_record(l_job);
            RETURN l_job;
        END IF;

        l_job.hdl_process_id    := apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//result/text()'
                                                         , p_ns => 'xmlns="http://xmlns.oracle.com/apps/hcm/common/dataLoader/core/dataLoaderIntegrationService/types/"');

        IF l_job.hdl_process_id IS NOT NULL THEN
            l_job.job_status := 'IMPORT_PENDING';
        ELSE
            l_job.job_status         := 'ERROR';
            l_job.error_http_code    := l_http_code;
            l_job.error_msg          := l_response;
        END IF;

        update_job_record(l_job);
        RETURN l_job;
    EXCEPTION
        WHEN OTHERS THEN
            l_job.job_status    := 'ERROR';
            l_job.error_msg     := sqlerrm;
            update_job_record(l_job);
            RETURN l_job;
    END import_and_load;

    /**
    * Updates the status of the given HDL job based on the current processing state.
    * 
    * @param p_job_id The job ID.
    * @return The updated job record with the latest status.
    */
    FUNCTION update_hdl_status (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype IS
        l_job        cmn_hdl_load_job_tbl%rowtype;
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_ds_xmltxt  CLOB;
        l_ds_xml     XMLTYPE;
    BEGIN
        l_job                                  := get_job_record(p_job_id);
        l_payload                              := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/hcm/common/dataLoader/core/dataLoaderIntegrationService/types/">
   <soapenv:Header/>
   <soapenv:Body>
      <typ:getDataSetStatus>
         <typ:Parameters>ProcessId=%0</typ:Parameters>
      </typ:getDataSetStatus>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , l_job.hdl_process_id);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type', p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => 'http://xmlns.oracle.com/apps/hcm/common/dataLoader/core/dataLoaderIntegrationService/getDataSetStatus'
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response                             := apex_web_service.make_rest_request(p_url => get_hdl_url(l_job.fa_domain)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload
                                                       , p_credential_static_id => l_job.credential_static_id);

        l_http_code                            := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_job.job_status         := 'ERROR';
            l_job.error_http_code    := l_http_code;
            l_job.error_msg          := l_response;
            update_job_record(l_job);
            RETURN l_job;
        END IF;

        l_ds_xmltxt                            := apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//result/text()'
                                                , p_ns => 'xmlns="http://xmlns.oracle.com/apps/hcm/common/dataLoader/core/dataLoaderIntegrationService/types/"');

        l_ds_xml                               := xmltype.createxml(l_ds_xmltxt);
                                
        /*** Update job record ***/
        l_job.hdl_result_count                 := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/RESULT_COUNT/text()');

        l_job.overall_status                   := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/STATUS/text()');

        l_job.import_status                    := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/IMPORT/STATUS/text()');

        l_job.import_percentage_complete       := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/IMPORT/PERCENTAGE_COMPLETE/text()');

        l_job.import_line_count_total          := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/IMPORT/DATA_LINE_COUNTS/TOTAL/text()');

        l_job.import_line_count_success        := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/IMPORT/DATA_LINE_COUNTS/SUCCESS/text()');

        l_job.import_line_count_failed         := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/IMPORT/DATA_LINE_COUNTS/FAILED/text()');

        l_job.import_line_count_unprocessed    := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/IMPORT/DATA_LINE_COUNTS/UNPROCESSED/text()');

        l_job.load_status                      := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/LOAD/STATUS/text()');

        l_job.load_percentage_complete         := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/LOAD/PERCENTAGE_COMPLETE/text()');

        l_job.load_line_count_total            := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/LOAD/OBJECT_COUNT/TOTAL/text()');

        l_job.load_line_count_success          := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/LOAD/OBJECT_COUNT/SUCCESS/text()');

        l_job.load_line_count_failed           := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/LOAD/OBJECT_COUNT/FAILED/text()');

        l_job.load_line_count_unprocessed      := apex_web_service.parse_xml(p_xml => l_ds_xml, p_xpath => '/DATA_SET_STATUS/DATA_SET/LOAD/OBJECT_COUNT/UNPROCESSED/text()');

        IF l_job.overall_status = 'COMPLETED' THEN
            l_job.job_status    := 'COMPLETE';
            l_job.job_end_ts    := systimestamp;
        ELSIF nvl(l_job.load_status, 'NOT_READY') <> 'NOT_READY' THEN
            l_job.job_status := 'LOAD_PENDING';
        END IF;

        update_job_record(l_job);
        RETURN l_job;
    EXCEPTION
        WHEN OTHERS THEN
            l_job.job_status    := 'ERROR';
            l_job.error_msg     := sqlerrm;
            update_job_record(l_job);
            RETURN l_job;
    END update_hdl_status;

    /**
    * Initiates the processing of an HDL job, including upload, import, load, and monitoring, based on the job's current state and configuration.
    * 
    * @param p_job_id The job ID to initiate processing for.
    */
    PROCEDURE initiate_job (
        p_job_id IN NUMBER
    ) IS
        l_job cmn_hdl_load_job_tbl%rowtype;
    BEGIN
        -- create APEX session to get access to web credentials
        apex_session.create_session(p_app_id => 1000, p_page_id => 1, p_username => 'CC_CONVERSION');

        l_job := upload_to_webcenter(p_job_id);
        IF l_job.job_status <> 'ERROR' THEN
            l_job := import_and_load(p_job_id);
            IF
                l_job.job_status <> 'ERROR'
                AND l_job.load_monitoring = 'ON'
            THEN
                monitor_job(p_job_id);
            END IF;

        END IF;

        IF l_job.job_status = 'ERROR' THEN
            l_job.job_end_ts := systimestamp;
            IF l_job.failure_callback IS NOT NULL THEN
                l_job.callback_status := 'FAILURE_CB_EXECUTING';
                update_job_record(l_job);
                BEGIN
                    EXECUTE IMMEDIATE 'begin '
                                      || l_job.failure_callback
                                      || '(:1); end;'
                        USING p_job_id;
                    l_job.callback_status := 'FAILURE_CB_COMPLETED';
                EXCEPTION
                    WHEN OTHERS THEN
                        l_job.callback_status       := 'FAILURE_CB_FAILED';
                        l_job.callback_error_msg    := sqlerrm;
                END;

            END IF;

            update_job_record(l_job);
        END IF;

    END;


    /**************************************************************************/
    /***************************** Private area *******************************/
    /**************************************************************************/

    /**
    * Constructs the WebCenter service URL based on the provided domain.
    * 
    * @param p_domain The domain to include in the service URL.
    * @return The constructed WebCenter service URL as VARCHAR2.
    */
    FUNCTION get_webcenter_url (
        p_domain IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'https://'
               || regexp_substr(p_domain, '(https://)?([^/]+)', 1
                              , 1, 'i', 2) -- extract domain only in case full URL is specfied
               || '/idcws/GenericSoapPort';
    END get_webcenter_url;

    /**
    * Constructs the HCM Data Loader (HDL) service URL based on the provided domain.
    * 
    * @param p_domain The domain to include in the service URL.
    * @return The constructed HDL service URL as VARCHAR2.
    */
    FUNCTION get_hdl_url (
        p_domain IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'https://'
               || regexp_substr(p_domain, '(https://)?([^/]+)', 1
                              , 1, 'i', 2) -- extract domain only in case full URL is specfied
               || '/hcmService/HCMDataLoader';
    END get_hdl_url;

    /**
    * Updates the HDL job record in the database with the provided job details.
    * 
    * @param p_job The HDL job record containing updated data.
    */
    PROCEDURE update_job_record (
        p_job IN cmn_hdl_load_job_tbl%rowtype
    ) IS
    BEGIN
        UPDATE cmn_hdl_load_job_tbl
           SET
            job_status = p_job.job_status
        , job_start_ts = p_job.job_start_ts
        , job_end_ts = p_job.job_end_ts
        , ucm_content_id = p_job.ucm_content_id
        , hdl_process_id = p_job.hdl_process_id
        , hdl_result_count = p_job.hdl_result_count
        , overall_status = p_job.overall_status
        , import_status = p_job.import_status
        , import_percentage_complete = p_job.import_percentage_complete
        , import_line_count_total = p_job.import_line_count_total
        , import_line_count_success = p_job.import_line_count_success
        , import_line_count_failed = p_job.import_line_count_failed
        , import_line_count_unprocessed = p_job.import_line_count_unprocessed
        , load_status = p_job.load_status
        , load_percentage_complete = p_job.load_percentage_complete
        , load_line_count_total = p_job.load_line_count_total
        , load_line_count_success = p_job.load_line_count_success
        , load_line_count_failed = p_job.load_line_count_failed
        , load_line_count_unprocessed = p_job.load_line_count_unprocessed
        , error_http_code = p_job.error_http_code
        , error_msg = p_job.error_msg
        , callback_status = p_job.callback_status
        , callback_error_msg = p_job.callback_error_msg
         WHERE
            id = p_job.id;

        COMMIT;
    END update_job_record;
    
    /********************** Scheduler job processing **************************/
    /**
    * Monitors the specified HDL job, updating its status based on elapsed time and current processing state.
    * 
    * @param p_job_id The job ID to monitor.
    */
    PROCEDURE monitor_job (
        p_job_id IN NUMBER
    ) IS
        l_job           cmn_hdl_load_job_tbl%rowtype;
        l_elapsed       INTERVAL DAY TO SECOND;
        l_elapsed_mins  NUMBER;
    BEGIN
        l_job           := update_hdl_status(p_job_id);
        IF l_job.job_status = 'COMPLETE' THEN
            IF l_job.success_callback IS NOT NULL THEN
                l_job.callback_status := 'SUCCESS_CB_EXECUTING';
                update_job_record(l_job);
                BEGIN
                    EXECUTE IMMEDIATE 'begin '
                                      || l_job.success_callback
                                      || '(:1); end;'
                        USING p_job_id;
                    l_job.callback_status := 'SUCCESS_CB_COMPLETED';
                EXCEPTION
                    WHEN OTHERS THEN
                        l_job.callback_status       := 'SUCCESS_CB_FAILED';
                        l_job.callback_error_msg    := sqlerrm;
                END;

            END IF;

            update_job_record(l_job);
            RETURN;
        END IF;
        
        -- Get elapsed time
        l_elapsed       := systimestamp - l_job.job_start_ts;
        l_elapsed_mins  := ( extract(DAY FROM l_elapsed) * 60 * 24 ) + ( extract(HOUR FROM l_elapsed) * 60 ) + extract(MINUTE FROM l_elapsed);

        IF l_elapsed_mins >= l_job.timeout_minutes THEN
            l_job.job_status := 'TIMEOUT';
            update_job_record(l_job);
            RETURN;
        END IF;
        
        -- Wait and check
        dbms_session.sleep(c_monitoring_interval_seconds);
        monitor_job(p_job_id);
    END;
    
    /************************* 3rd-party Util *********************************/
    FUNCTION clob_to_blob (
        p_data IN CLOB
    ) RETURN BLOB
    -- -----------------------------------------------------------------------------------
    -- File Name    : https://oracle-base.com/dba/miscellaneous/clob_to_blob.sql
    -- Author       : Tim Hall
    -- Description  : Converts a CLOB to a BLOB.
    -- Last Modified: 26/12/2016
    -- -----------------------------------------------------------------------------------
     AS

        l_blob          BLOB;
        l_dest_offset   PLS_INTEGER := 1;
        l_src_offset    PLS_INTEGER := 1;
        l_lang_context  PLS_INTEGER := dbms_lob.default_lang_ctx;
        l_warning       PLS_INTEGER := dbms_lob.warn_inconvertible_char;
    BEGIN
        dbms_lob.createtemporary(lob_loc => l_blob, cache => true);
        dbms_lob.converttoblob(dest_lob => l_blob, src_clob => p_data, amount => dbms_lob.lobmaxsize
                             , dest_offset => l_dest_offset
                             , src_offset => l_src_offset
                             , blob_csid => dbms_lob.default_csid
                             , lang_context => l_lang_context
                             , warning => l_warning);

        RETURN l_blob;
    END clob_to_blob;

END cmn_hdl_utility_pkg;