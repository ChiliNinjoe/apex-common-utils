CREATE OR REPLACE PACKAGE BODY cmn_bip_utility_pkg AS

    /*
        TODOS
        - encapsulate repetitive SOAP code to procedure
        - apply chunking for report download
        - eliminate apex_collection for table output option (to make it more dbms_scheduler friendly)
        
        KNOWN ISSUES
        - parsing error on CLOB columns for adhoc sql
    */

    /**************************************************************************/
    /***************************** PRIVATE AREA *******************************/
    /**************************************************************************/

    c_bip_output_metadata  CONSTANT VARCHAR2(60) := 'CMN_BIP_OUTPUT_METADATA';
    c_dummy_xml_filename   CONSTANT VARCHAR2(60) := 'bipoutput.xml';
    --
    TYPE bip_output IS RECORD (
        output_content_xml  BLOB
        , dp_profile          CLOB
    );

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

    FUNCTION get_securityservice_url (
        p_credentials IN cmn_credentials_pkg.acct_creds
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'https://'
               || regexp_substr(p_credentials.fa_domain, '(https://)?([^/]+)', 1
                              , 1, 'i', 2) -- extract domain only in case full URL is specfied
               || '/xmlpserver/services/v2/SecurityService';
    END get_securityservice_url;

    FUNCTION get_catalogservice_url (
        p_credentials IN cmn_credentials_pkg.acct_creds
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'https://'
               || regexp_substr(p_credentials.fa_domain, '(https://)?([^/]+)', 1
                              , 1, 'i', 2) -- extract domain only in case full URL is specfied
               || '/xmlpserver/services/v2/CatalogService';
    END get_catalogservice_url;

    FUNCTION get_reportservice_url (
        p_credentials IN cmn_credentials_pkg.acct_creds
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'https://'
               || regexp_substr(p_credentials.fa_domain, '(https://)?([^/]+)', 1
                              , 1, 'i', 2) -- extract domain only in case full URL is specfied
               || '/xmlpserver/services/v2/ReportService';
    END get_reportservice_url;

    PROCEDURE create_output_column_collection (
        p_dp_profile IN CLOB
    ) IS
        l_clob_counter  INTEGER := 0;
        l_clob_column   VARCHAR2(30);
    BEGIN
        apex_collection.create_or_truncate_collection(p_collection_name => c_bip_output_metadata);
        FOR r IN (
            SELECT
                column_position
              , column_name
              , data_type
              , format_mask
              , clob_content_column
              FROM
                TABLE ( apex_data_parser.get_columns(p_dp_profile) ) p
             ORDER BY
                column_position ASC
        ) LOOP
            IF r.data_type = 'CLOB' THEN
                -- remediate bug in APEX_DATA_PARSER discover for clob
                l_clob_counter := l_clob_counter + 1;
                IF r.clob_content_column = 'CLOB' THEN
                    l_clob_column := 'CLOB'
                                     || trim(to_char(l_clob_counter, '09'));
                ELSE
                    l_clob_column := r.clob_content_column;
                END IF;

            ELSE
                l_clob_column := NULL;
            END IF;

            apex_collection.add_member(p_collection_name => c_bip_output_metadata, p_n001 => r.column_position
                                     , p_c001 => r.column_name
                                     , p_c002 => r.data_type
                                     , p_c003 => replace(r.format_mask, '"')
                                     , p_c004 => l_clob_column);

        END LOOP;

    END create_output_column_collection;

    PROCEDURE generate_select_columns_for_collection (
        p_dp_profile     IN   CLOB
      , p_select_sql     OUT  CLOB
      , p_column_labels  OUT  CLOB
    ) IS
        l_clob_counter  INTEGER := 0;
        l_clob_column   VARCHAR2(30);
        l_selectcol     apex_t_varchar2;
        l_colnames      apex_t_varchar2;
    BEGIN
        l_selectcol      := apex_t_varchar2();
        l_colnames       := apex_t_varchar2();
        FOR r IN (
            SELECT
                column_position
              , column_name
              , data_type
              , format_mask
              , clob_content_column
              FROM
                TABLE ( apex_data_parser.get_columns(p_dp_profile) ) p
             ORDER BY
                column_position ASC
        ) LOOP
            IF r.data_type = 'CLOB' THEN
                l_clob_counter := l_clob_counter + 1;
                IF r.clob_content_column = 'CLOB' THEN
                    -- remediate bug in APEX_DATA_PARSER discover for clob
                    apex_string.push(l_selectcol, 'CLOB'
                                                  || trim(to_char(l_clob_counter, '09'))
                                                  || ' AS "'
                                                  || r.column_name
                                                  || '"');

                ELSE
                    apex_string.push(l_selectcol, r.clob_content_column
                                                  || ' AS "'
                                                  || r.column_name
                                                  || '"');
                END IF;

            ELSE
                apex_string.push(l_selectcol, 'COL'
                                              || trim(to_char(r.column_position, '009'))
                                              || ' AS "'
                                              || r.column_name
                                              || '"');
            END IF;

            apex_string.push(l_colnames, r.column_name);
        END LOOP;

        p_select_sql     := 'SELECT '
                        || apex_string.join_clob(l_selectcol, ',');
        p_column_labels  := apex_string.join_clob(l_colnames, ':');
    END generate_select_columns_for_collection;

    PROCEDURE retrieve_session_token (
        p_credentials IN OUT NOCOPY cmn_credentials_pkg.acct_creds
    ) IS
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_error      CLOB;
    BEGIN
        l_payload                      := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:login>
         <v2:userID>%0</v2:userID>
         <v2:password>%1</v2:password>
      </v2:login>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , p_credentials.username
                                      , p_credentials.password);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response                     := apex_web_service.make_rest_request(p_url => get_securityservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code                    := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[retrieve_session_token] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

        p_credentials.session_token    := apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//loginResponse/loginReturn/text()'
                                                                , p_ns => 'xmlns="http://xmlns.oracle.com/oxp/service/v2"');

    END retrieve_session_token;

    PROCEDURE invalidate_session_token (
        p_credentials IN OUT NOCOPY cmn_credentials_pkg.acct_creds
    ) IS
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_error      CLOB;
    BEGIN
        l_payload                      := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:logout>
         <v2:bipSessionToken>%0</v2:bipSessionToken>
      </v2:logout>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , p_credentials.session_token);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response                     := apex_web_service.make_rest_request(p_url => get_securityservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code                    := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[retrieve_session_token] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

        p_credentials.session_token    := NULL;
    END invalidate_session_token;

    FUNCTION get_dm_for_sql (
        p_sql IN CLOB
    ) RETURN CLOB IS
    BEGIN
        RETURN '<?xml version = ''1.0'' encoding = ''utf-8''?>
<dataModel xmlns="http://xmlns.oracle.com/oxp/xmlp" version="2.0" xmlns:xdm="http://xmlns.oracle.com/oxp/xmlp" xmlns:xsd="http://wwww.w3.org/2001/XMLSchema" defaultDataSourceRef="demo">
<description> 
<![CDATA[Generic Data Model]]>
</description>
<dataProperties>
<property name="include_parameters" value="true" />
<property name="include_null_Element" value="false" />
<property name="include_rowsettag" value="false" />
<property name="xml_tag_case" value="upper" />
</dataProperties>
<dataSets>
<dataSet name="GENERIC_DATASET" type="simple">
<sql dataSourceRef="ApplicationDB_HCM" nsQuery="true" xmlRowTagName="" bindMultiValueAsCommaSepStr="false"> 
<![CDATA['
               || p_sql
               || ']]>
</sql>
</dataSet>
</dataSets>
<output rootName="DATA_DS" uniqueRowName="false">
<nodeList name="GENERIC_DATASET" />
</output>
<eventTriggers />
<lexicals />
<valueSets />
<parameters />
<bursting />
<display>
<layouts>
<layout name="GENERIC_DATASET" left="281px" top="0px" />
<layout name="DATA_DS" left="1px" top="289px" />
</layouts>
<groupLinks />
</display>
</dataModel>';
    END get_dm_for_sql;

    FUNCTION data_model_exists (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
    ) RETURN BOOLEAN IS
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_result     VARCHAR2(30);
        l_error      CLOB;
    BEGIN
        IF p_credentials.session_token IS NULL THEN
            retrieve_session_token(p_credentials);
        END IF;
        --

        l_payload    := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:objectExistInSession>
         <v2:reportObjectAbsolutePath>%0</v2:reportObjectAbsolutePath>
         <v2:bipSessionToken>%1</v2:bipSessionToken>
      </v2:objectExistInSession>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , trim(TRAILING '/' FROM p_path)
                                          || '/'
                                          || regexp_replace(p_name, '\.xdm$', ''
                                                          , 1, 1, 'i')
                                          || '.xdm'
                                      , p_credentials.session_token);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response   := apex_web_service.make_rest_request(p_url => get_catalogservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code  := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[data_model_exists] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

        l_result     := apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//objectExistInSessionResponse/objectExistInSessionReturn/text()'
                                             , p_ns => 'xmlns="http://xmlns.oracle.com/oxp/service/v2"');

        IF upper(l_result) = 'TRUE' THEN
            RETURN true;
        ELSE
            RETURN false;
        END IF;
    END data_model_exists;

    PROCEDURE delete_data_model (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
    ) IS
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_result     VARCHAR2(30);
        l_error      CLOB;
    BEGIN
        IF p_credentials.session_token IS NULL THEN
            retrieve_session_token(p_credentials);
        END IF;
        --

        l_payload    := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:deleteObjectInSession>
         <v2:objectAbsolutePath>%0</v2:objectAbsolutePath>
         <v2:bipSessionToken>%1</v2:bipSessionToken>
      </v2:deleteObjectInSession>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , trim(TRAILING '/' FROM p_path)
                                          || '/'
                                          || regexp_replace(p_name, '\.xdm$', ''
                                                          , 1, 1, 'i')
                                          || '.xdm'
                                      , p_credentials.session_token);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response   := apex_web_service.make_rest_request(p_url => get_catalogservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code  := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[delete_data_model] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

    END delete_data_model;

    PROCEDURE post_data_model (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_xdm_xml      IN  CLOB
    ) IS
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_error      CLOB;
    BEGIN
        IF p_credentials.session_token IS NULL THEN
            retrieve_session_token(p_credentials);
        END IF;
        --

        l_payload    := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:createObjectInSession>
         <v2:folderAbsolutePathURL>%0</v2:folderAbsolutePathURL>
         <v2:objectName>%1</v2:objectName>
         <v2:objectType>xdm</v2:objectType>
         <v2:objectDescription>Generic Data Model from web service</v2:objectDescription>
         <v2:objectData>'
                                      , trim(TRAILING '/' FROM p_path)
                                          || '/'
                                      , regexp_replace(p_name, '\.xdm$', ''
                                                       , 1, 1, 'i'))
                     || apex_web_service.blob2clobbase64(clob_to_blob(p_xdm_xml))
                     || apex_string.format('</v2:objectData>
         <v2:bipSessionToken>%0</v2:bipSessionToken>
      </v2:createObjectInSession>
   </soapenv:Body>
</soapenv:Envelope>'
                                         , p_credentials.session_token);

        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response   := apex_web_service.make_rest_request(p_url => get_catalogservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code  := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[post_data_model] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

    END post_data_model;

    PROCEDURE retrieve_dm_data (
        p_path         IN   VARCHAR2
      , p_name         IN   VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_parameters   IN   apex_t_varchar2 DEFAULT NULL
      , p_bip_output   OUT  bip_output
    ) IS

        l_param_node   CLOB;
        l_param_items  CLOB;
        l_payload      CLOB;
        l_http_code    NUMBER;
        l_response     CLOB;
        l_output_clob  CLOB;
        l_error        CLOB;
    BEGIN
        IF p_credentials.session_token IS NULL THEN
            retrieve_session_token(p_credentials);
        END IF;
        --
        IF p_parameters IS NOT NULL THEN
            IF MOD(p_parameters.count, 2) = 0 THEN /* must have even elements */
                FOR p IN 1..( p_parameters.count - 1 ) LOOP
                    IF MOD(p, 2) = 1 THEN /* process key elements only */
                        l_param_items  := l_param_items
                                         || apex_string.format('<v2:item><v2:name>%0</v2:name><v2:values><v2:item>%1</v2:item></v2:values></v2:item>'
                                                             , p_parameters(p)
                                                             , p_parameters(p + 1));

                        l_param_node   := '<v2:parameterNameValues><v2:listOfParamNameValues>'
                                        || l_param_items
                                        || '</v2:listOfParamNameValues></v2:parameterNameValues>';
                    END IF;
                END LOOP;

            END IF;

        END IF;

        l_payload                          := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:runDataModelInSession>
         <v2:reportRequest>
            %0
            <v2:reportAbsolutePath>%1</v2:reportAbsolutePath>
            <v2:sizeOfDataChunkDownload>-1</v2:sizeOfDataChunkDownload>
         </v2:reportRequest>
         <v2:bipSessionToken>%2</v2:bipSessionToken>
      </v2:runDataModelInSession>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , l_param_node
                                      , trim(TRAILING '/' FROM p_path)
                                          || '/'
                                          || regexp_replace(p_name, '\.xdm$', ''
                                                          , 1, 1, 'i')
                                          || '.xdm'
                                      , p_credentials.session_token);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response                         := apex_web_service.make_rest_request(p_url => get_reportservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code                        := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[retrieve_dm_data] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

        l_output_clob                      := apex_web_service.parse_xml_clob(p_xml => xmltype.createxml(l_response), p_xpath => '//runDataModelInSessionResponse/runDataModelInSessionReturn/reportBytes/text()'
                                                       , p_ns => 'xmlns="http://xmlns.oracle.com/oxp/service/v2"');

        p_bip_output.output_content_xml    := apex_web_service.clobbase642blob(l_output_clob);
        p_bip_output.dp_profile            := apex_data_parser.discover(p_content => p_bip_output.output_content_xml
                                                           , p_file_name => c_dummy_xml_filename
                                                           , p_row_selector => '/ROWSET/ROW');

        create_output_column_collection(p_bip_output.dp_profile);
    END retrieve_dm_data;

    FUNCTION get_column_ddl RETURN CLOB IS
        l_return CLOB;
    BEGIN
        FOR c IN (
            SELECT
                n001  AS column_position
              , c001  AS column_name
              , c002  AS data_type
              , c003  AS format_mask
              , c004  AS clob_content_column
              FROM
                apex_collections
             WHERE
                collection_name = c_bip_output_metadata
             ORDER BY
                n001
        ) LOOP
            IF c.column_position = 1 THEN
                l_return := '"'
                            || c.column_name
                            || '"'
                            || ' '
                            || c.data_type;

            ELSE
                l_return := l_return
                            || ', '
                            || '"'
                            || c.column_name
                            || '"'
                            || ' '
                            || c.data_type;
            END IF;
        END LOOP;

        RETURN l_return;
    END get_column_ddl;

    PROCEDURE create_output_table (
        p_schema_name  IN  VARCHAR2
      , p_table_name   IN  VARCHAR2
    ) IS
        l_sql CLOB;
    BEGIN
        l_sql := 'CREATE TABLE '
                 || p_schema_name
                 || '.'
                 || p_table_name
                 || '('
                 || get_column_ddl
                 || ')';

        apex_debug.message('Create SQL: ' || l_sql);
        EXECUTE IMMEDIATE l_sql;
    END create_output_table;

    PROCEDURE load_table_from_xml (
        p_schema_name  IN   VARCHAR2
      , p_table_name   IN   VARCHAR2
      , p_bip_output   IN   bip_output
      , p_errlog_tbl   IN   VARCHAR2 DEFAULT NULL
      , p_rows         OUT  NUMBER
    ) IS

        l_table_exists              VARCHAR2(1);
        l_existing_column_datatype  VARCHAR2(128);
        l_columnname                VARCHAR2(128);
        l_column_exists             VARCHAR2(1);
        l_headercol                 apex_t_varchar2;
        l_selectcol                 apex_t_varchar2;
        l_insert_sql                CLOB;
    BEGIN
        BEGIN
            SELECT
                'Y'
              INTO l_table_exists
              FROM
                all_tables
             WHERE
                    owner = upper(p_schema_name)
                   AND table_name = upper(p_table_name);

        EXCEPTION
            WHEN no_data_found THEN
                l_table_exists := 'N';
        END;

        IF l_table_exists = 'N' THEN
            apex_debug.trace('=== Creating table to be loaded ===');
            create_output_table(p_schema_name, p_table_name);
        END IF;

        l_headercol   := apex_t_varchar2();
        l_selectcol   := apex_t_varchar2();
        FOR i IN (
            SELECT
                n001  AS column_position
              , c001  AS column_name
              , c002  AS data_type
              , c003  AS format_mask
              , c004  AS clob_content_column
              FROM
                apex_collections
             WHERE
                collection_name = c_bip_output_metadata
             ORDER BY
                n001
        ) LOOP
            BEGIN
                SELECT
                    'Y'
                  , column_name
                  , data_type
                  INTO
                    l_column_exists
                , l_columnname
                , l_existing_column_datatype
                  FROM
                    all_tab_cols
                 WHERE
                        owner = upper(p_schema_name)
                       AND table_name   = upper(p_table_name)
                       AND column_name  = i.column_name /* Find exact match first */
                UNION ALL
                SELECT
                    'Y'
                  , column_name
                  , data_type
                  FROM
                    all_tab_cols
                 WHERE
                        owner = upper(p_schema_name)
                       AND table_name             = upper(p_table_name)
                       AND upper(column_name)     = upper(i.column_name) /* then perform case insensitive match */
                UNION ALL
                SELECT
                    'Y'
                  , column_name
                  , data_type
                  FROM
                    all_tab_cols
                 WHERE
                        owner = upper(p_schema_name)
                       AND table_name             = upper(p_table_name)
                       AND upper(column_name)     = upper(replace(i.column_name, '_', ' ')) /* find space for _ */
                UNION ALL
                SELECT
                    'Y'
                  , column_name
                  , data_type
                  FROM
                    all_tab_cols
                 WHERE
                        owner = upper(p_schema_name)
                       AND table_name                                                                  = upper(p_table_name)
                       AND upper(regexp_replace(column_name, '[^A-Z0-9]+', ''
                                              , 1, 0, 'i')) = upper(regexp_replace(i.column_name
                                                                                   , '[^A-Z0-9]+'
                                                                                   , ''
                                                                                   , 1
                                                                                   , 0
                                                                                   , 'i')) /* alphanumeric chars match */
                 FETCH FIRST ROW ONLY;

            EXCEPTION
                WHEN no_data_found THEN
                    l_column_exists             := 'N';
                    l_columnname                := NULL;
                    l_existing_column_datatype  := NULL;
            END;

            IF l_column_exists = 'Y' THEN
                /* Capture table column name with matching column from APEX_DATA_PARSER */
                apex_string.push(l_headercol, '"'
                                              || l_columnname
                                              || '"');
                IF
                    i.data_type = 'CLOB'
                    AND i.clob_content_column IS NOT NULL
                THEN
                    apex_string.push(l_selectcol, 'NVL('
                                                  || i.clob_content_column
                                                  || ','
                                                  || 'COL'
                                                  || trim(to_char(i.column_position, '009'))
                                                  || ')');

                ELSIF
                    i.format_mask IS NOT NULL
                    AND l_existing_column_datatype = 'DATE'
                THEN
                    apex_string.push(l_selectcol, 'TO_DATE('
                                                  || 'COL'
                                                  || trim(to_char(i.column_position, '009'))
                                                  || ','''
                                                  || i.format_mask
                                                  || ''')');
                ELSIF
                    i.format_mask IS NOT NULL
                    AND l_existing_column_datatype LIKE 'TIMESTAMP%'
                THEN
                    apex_string.push(l_selectcol, 'TO_TIMESTAMP('
                                                  || 'COL'
                                                  || trim(to_char(i.column_position, '009'))
                                                  || ','''
                                                  || i.format_mask
                                                  || ''')');
                ELSE
                    apex_string.push(l_selectcol
                                   , 'COL'
                                       || trim(to_char(i.column_position, '009')));
                END IF;

            END IF;

        END LOOP;

        IF l_headercol.count = 0 THEN
            apex_error.add_error(p_message => 'No matching columns found on table. No data loaded.'
                               , p_display_location => apex_error.c_on_error_page);
            RETURN;
        END IF;

        l_insert_sql  := 'INSERT INTO '
                        || p_schema_name
                        || '.'
                        || p_table_name
                        || '('
                        || apex_string.join(l_headercol, ',')
                        || ') '
                        || 'SELECT '
                        || apex_string.join(l_selectcol, ',')
                        || '
        FROM
            TABLE ( apex_data_parser.parse(p_content => :fileblob, p_file_name => :filename, p_file_profile => :fileprofile, p_row_selector => ''/ROWSET/ROW'') )';

        IF p_errlog_tbl IS NOT NULL THEN
            l_insert_sql := l_insert_sql
                            || ' LOG ERRORS INTO '
                            || p_schema_name
                            || '.'
                            || p_errlog_tbl
                            || ' ('''
                            || to_char(systimestamp)
                            || ''') REJECT LIMIT UNLIMITED';
        END IF;

        apex_debug.message('l_insert_sql: [%s]', l_insert_sql);
        EXECUTE IMMEDIATE l_insert_sql
            USING p_bip_output.output_content_xml, c_dummy_xml_filename, p_bip_output.dp_profile;
        --
        p_rows        := SQL%rowcount;
        --
    END load_table_from_xml;

    /**************************************************************************/
    /*************************** PUBLIC INTERFACE *****************************/
    /**************************************************************************/

    FUNCTION is_credential_valid (
        p_credentials IN cmn_credentials_pkg.acct_creds
    ) RETURN BOOLEAN IS
        l_payload    CLOB;
        l_http_code  NUMBER;
        l_response   CLOB;
        l_error      CLOB;
        l_result     VARCHAR2(30);
    BEGIN
        l_payload    := apex_string.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2">
   <soapenv:Header/>
   <soapenv:Body>
      <v2:validateLogin>
         <v2:userID>%0</v2:userID>
         <v2:password>%1</v2:password>
      </v2:validateLogin>
   </soapenv:Body>
</soapenv:Envelope>'
                                      , p_credentials.username
                                      , p_credentials.password);
        --
        apex_web_service.set_request_headers(p_name_01 => 'Content-Type'
                                           , p_value_01 => 'text/xml;charset=UTF-8'
                                           , p_name_02 => 'SOAPAction'
                                           , p_value_02 => ''
                                           , p_reset => true
                                           , p_skip_if_exists => true);

        l_response   := apex_web_service.make_rest_request(p_url => get_securityservice_url(p_credentials)
                                                       , p_http_method => 'POST'
                                                       , p_body => l_payload);

        l_http_code  := apex_web_service.g_status_code;
        IF l_http_code <> 200 THEN
            l_error := nvl(apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//faultstring[1]/text()')
                         , l_response);

            raise_application_error(-20100, '[is_credential_valid] HTTP '
                                            || l_http_code
                                            || ': '
                                            || l_error);
        END IF;

        l_result     := apex_web_service.parse_xml(p_xml => xmltype.createxml(l_response), p_xpath => '//validateLoginResponse/validateLoginReturn/text()'
                                             , p_ns => 'xmlns="http://xmlns.oracle.com/oxp/service/v2"');

        IF upper(l_result) = 'TRUE' THEN
            RETURN true;
        ELSE
            RETURN false;
        END IF;
    END is_credential_valid;

    PROCEDURE create_data_model (
        p_path         IN  VARCHAR2
      , p_name         IN  VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_sql          IN  CLOB DEFAULT NULL
      , p_xdm_xml      IN  CLOB DEFAULT NULL
      , p_replace      IN  VARCHAR2 DEFAULT 'N'
    ) IS
        l_xdm_xml CLOB;
    BEGIN
        IF
            p_sql IS NULL
            AND p_xdm_xml IS NULL
        THEN
            raise_application_error(-20001, 'Incomplete parameters. Either p_sql or p_xdm_xml must be provided.');
        END IF;

        IF
            p_sql IS NOT NULL
            AND p_xdm_xml IS NOT NULL
        THEN
            raise_application_error(-20001, 'Cannot provide p_sql and p_xdm_xml parameters at the same time.');
        END IF;

        IF data_model_exists(p_path => p_path, p_name => p_name, p_credentials => p_credentials) = true THEN
            apex_debug.trace('DM Exists');
            IF upper(p_replace) = 'Y' THEN
                apex_debug.trace('Deleting DM ...');
                delete_data_model(p_path => p_path, p_name => p_name, p_credentials => p_credentials);
            ELSE
                apex_debug.trace('Skipped DM creation');
                RETURN;
            END IF;

        END IF;

        l_xdm_xml := nvl(p_xdm_xml, get_dm_for_sql(p_sql));
        post_data_model(p_path => p_path, p_name => p_name, p_credentials => p_credentials
                      , p_xdm_xml => l_xdm_xml);

    END create_data_model;

    PROCEDURE load_data_model_to_table (
        p_path         IN   VARCHAR2
      , p_name         IN   VARCHAR2
      , p_credentials  IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_parameters   IN   apex_t_varchar2 DEFAULT NULL
      , p_schema_name  IN   VARCHAR2
      , p_table_name   IN   VARCHAR2
      , p_errlog_tbl   IN   VARCHAR2 DEFAULT NULL
      , p_rows         OUT  NUMBER
    ) IS
        l_bip_output bip_output;
    BEGIN
        retrieve_dm_data(p_path => p_path, p_name => p_name, p_credentials => p_credentials
                       , p_parameters => p_parameters
                       , p_bip_output => l_bip_output);

        invalidate_session_token(p_credentials);
        --
        load_table_from_xml(p_schema_name => p_schema_name, p_table_name => p_table_name, p_bip_output => l_bip_output
                          , p_rows => p_rows);

    END load_data_model_to_table;

    PROCEDURE load_data_model_to_collection (
        p_path             IN  VARCHAR2
      , p_name             IN  VARCHAR2
      , p_credentials      IN OUT NOCOPY cmn_credentials_pkg.acct_creds
      , p_parameters       IN  apex_t_varchar2 DEFAULT NULL
      , p_collection_name  IN  VARCHAR2
    ) IS
        l_bip_output     bip_output;
        l_select_sql     CLOB;
        l_column_labels  CLOB;
        l_sql_query      CLOB;
    BEGIN
        retrieve_dm_data(p_path => p_path, p_name => p_name, p_credentials => p_credentials
                       , p_parameters => p_parameters
                       , p_bip_output => l_bip_output);

        invalidate_session_token(p_credentials);
        --
        apex_collection.create_or_truncate_collection(p_collection_name => p_collection_name);
        generate_select_columns_for_collection(p_dp_profile => l_bip_output.dp_profile
                                             , p_select_sql => l_select_sql
                                             , p_column_labels => l_column_labels);

        -- Add BIP output LOBs to collection
        apex_collection.add_member(p_collection_name => p_collection_name, p_c001 => 'BIP_OUTPUT_LOB'
                                 , p_clob001 => l_bip_output.dp_profile
                                 , p_blob001 => l_bip_output.output_content_xml);

        -- Add SQL Query to collection
        l_sql_query := l_select_sql
                       || ' FROM apex_collections ac, TABLE ( apex_data_parser.parse(p_content => ac.blob001, p_file_name => ''dummy.xml'', p_file_profile => ac.clob001, p_row_selector => ''/ROWSET/ROW'') ) '
                       || ' WHERE ac.collection_name = '''
                       || p_collection_name
                       || ''' AND c001 = ''BIP_OUTPUT_LOB''';
        apex_collection.add_member(p_collection_name => p_collection_name, p_c001 => 'SELECT_QUERY'
                                 , p_clob001 => l_sql_query);

        -- Add column list to collection
        apex_collection.add_member(p_collection_name => p_collection_name, p_c001 => 'COLUMN_LIST'
                                 , p_clob001 => l_column_labels);

    END load_data_model_to_collection;

    FUNCTION get_query_for_collection (
        p_collection_name IN VARCHAR2
    ) RETURN CLOB IS
        l_result CLOB;
    BEGIN
        SELECT
            clob001
          INTO l_result
          FROM
            apex_collections
         WHERE
                collection_name = p_collection_name
               AND c001 = 'SELECT_QUERY';

        RETURN l_result;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 'SELECT DUMMY FROM DUAL';
    END get_query_for_collection;

    FUNCTION get_columns_for_collection (
        p_collection_name IN VARCHAR2
    ) RETURN CLOB IS
        l_result CLOB;
    BEGIN
        SELECT
            clob001
          INTO l_result
          FROM
            apex_collections
         WHERE
                collection_name = p_collection_name
               AND c001 = 'COLUMN_LIST';

        RETURN l_result;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 'DUMMY';
    END get_columns_for_collection;

END cmn_bip_utility_pkg;