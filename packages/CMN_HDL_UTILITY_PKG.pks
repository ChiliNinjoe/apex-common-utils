CREATE OR REPLACE PACKAGE cmn_hdl_utility_pkg IS
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
    ) RETURN NUMBER;

    /**
    * Retrieves the status of a given HDL job by its ID.
    * 
    * @param p_job_id The job ID.
    * @return The status of the job as VARCHAR2.
    */
    FUNCTION get_job_status (
        p_job_id IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Fetches a record from the HDL job table corresponding to the given job ID.
    * 
    * @param p_job_id The job ID.
    * @return A record from the HDL job table (based on the defined %rowtype).
    */
    FUNCTION get_job_record (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    /**
    * Uploads the specified HDL job to WebCenter and updates its record with the upload status.
    * 
    * @param p_job_id The job ID.
    * @return The updated job record after attempting the upload.
    */
    FUNCTION upload_to_webcenter (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    /**
    * Performs the import and load operation for the specified HDL job and updates its status accordingly.
    * 
    * @param p_job_id The job ID.
    * @return The updated job record post import and load operation.
    */
    FUNCTION import_and_load (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    /**
    * Updates the status of the given HDL job based on the current processing state.
    * 
    * @param p_job_id The job ID.
    * @return The updated job record with the latest status.
    */
    FUNCTION update_hdl_status (
        p_job_id IN NUMBER
    ) RETURN cmn_hdl_load_job_tbl%rowtype;

    /**
    * Initiates the processing of an HDL job, including upload, import, load, and monitoring, based on the job's current state and configuration.
    * 
    * @param p_job_id The job ID to initiate processing for.
    */
    PROCEDURE initiate_job (
        p_job_id IN NUMBER
    );

END cmn_hdl_utility_pkg;