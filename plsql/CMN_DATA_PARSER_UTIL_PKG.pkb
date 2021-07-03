create or replace PACKAGE BODY cmn_data_parser_util_pkg AS

    FUNCTION f_get_raw_header_columns (
        p_app_temp_file IN apex_application_temp_files%rowtype
    ) RETURN apex_t_varchar2 IS
        l_parsecol apex_t_varchar2;
    BEGIN
        l_parsecol := apex_t_varchar2();
        l_parsecol.extend(300);
        SELECT
            col001 , col002 , col003 , col004 , col005 , col006 , col007 , col008 , col009 , col010 
		  , col011 , col012 , col013 , col014 , col015 , col016 , col017 , col018 , col019 , col020 
		  , col021 , col022 , col023 , col024 , col025 , col026 , col027 , col028 , col029 , col030 
		  , col031 , col032 , col033 , col034 , col035 , col036 , col037 , col038 , col039 , col040 
		  , col041 , col042 , col043 , col044 , col045 , col046 , col047 , col048 , col049 , col050 
		  , col051 , col052 , col053 , col054 , col055 , col056 , col057 , col058 , col059 , col060 
		  , col061 , col062 , col063 , col064 , col065 , col066 , col067 , col068 , col069 , col070 
		  , col071 , col072 , col073 , col074 , col075 , col076 , col077 , col078 , col079 , col080 
		  , col081 , col082 , col083 , col084 , col085 , col086 , col087 , col088 , col089 , col090 
		  , col091 , col092 , col093 , col094 , col095 , col096 , col097 , col098 , col099 , col100 
		  , col101 , col102 , col103 , col104 , col105 , col106 , col107 , col108 , col109 , col110 
		  , col111 , col112 , col113 , col114 , col115 , col116 , col117 , col118 , col119 , col120 
		  , col121 , col122 , col123 , col124 , col125 , col126 , col127 , col128 , col129 , col130 
		  , col131 , col132 , col133 , col134 , col135 , col136 , col137 , col138 , col139 , col140 
		  , col141 , col142 , col143 , col144 , col145 , col146 , col147 , col148 , col149 , col150 
		  , col151 , col152 , col153 , col154 , col155 , col156 , col157 , col158 , col159 , col160 
		  , col161 , col162 , col163 , col164 , col165 , col166 , col167 , col168 , col169 , col170 
		  , col171 , col172 , col173 , col174 , col175 , col176 , col177 , col178 , col179 , col180 
		  , col181 , col182 , col183 , col184 , col185 , col186 , col187 , col188 , col189 , col190 
		  , col191 , col192 , col193 , col194 , col195 , col196 , col197 , col198 , col199 , col200 
		  , col201 , col202 , col203 , col204 , col205 , col206 , col207 , col208 , col209 , col210 
		  , col211 , col212 , col213 , col214 , col215 , col216 , col217 , col218 , col219 , col220 
		  , col221 , col222 , col223 , col224 , col225 , col226 , col227 , col228 , col229 , col230 
		  , col231 , col232 , col233 , col234 , col235 , col236 , col237 , col238 , col239 , col240 
		  , col241 , col242 , col243 , col244 , col245 , col246 , col247 , col248 , col249 , col250 
		  , col251 , col252 , col253 , col254 , col255 , col256 , col257 , col258 , col259 , col260 
		  , col261 , col262 , col263 , col264 , col265 , col266 , col267 , col268 , col269 , col270 
		  , col271 , col272 , col273 , col274 , col275 , col276 , col277 , col278 , col279 , col280 
		  , col281 , col282 , col283 , col284 , col285 , col286 , col287 , col288 , col289 , col290 
		  , col291 , col292 , col293 , col294 , col295 , col296 , col297 , col298 , col299 , col300
        INTO
          l_parsecol(1) , l_parsecol(2) , l_parsecol(3) , l_parsecol(4) , l_parsecol(5) , l_parsecol(6) , l_parsecol(7) , l_parsecol(8) , l_parsecol(9) , l_parsecol(10) 
		, l_parsecol(11) , l_parsecol(12) , l_parsecol(13) , l_parsecol(14) , l_parsecol(15) , l_parsecol(16) , l_parsecol(17) , l_parsecol(18) , l_parsecol(19) , l_parsecol(20) 
		, l_parsecol(21) , l_parsecol(22) , l_parsecol(23) , l_parsecol(24) , l_parsecol(25) , l_parsecol(26) , l_parsecol(27) , l_parsecol(28) , l_parsecol(29) , l_parsecol(30) 
		, l_parsecol(31) , l_parsecol(32) , l_parsecol(33) , l_parsecol(34) , l_parsecol(35) , l_parsecol(36) , l_parsecol(37) , l_parsecol(38) , l_parsecol(39) , l_parsecol(40) 
		, l_parsecol(41) , l_parsecol(42) , l_parsecol(43) , l_parsecol(44) , l_parsecol(45) , l_parsecol(46) , l_parsecol(47) , l_parsecol(48) , l_parsecol(49) , l_parsecol(50) 
		, l_parsecol(51) , l_parsecol(52) , l_parsecol(53) , l_parsecol(54) , l_parsecol(55) , l_parsecol(56) , l_parsecol(57) , l_parsecol(58) , l_parsecol(59) , l_parsecol(60) 
		, l_parsecol(61) , l_parsecol(62) , l_parsecol(63) , l_parsecol(64) , l_parsecol(65) , l_parsecol(66) , l_parsecol(67) , l_parsecol(68) , l_parsecol(69) , l_parsecol(70) 
		, l_parsecol(71) , l_parsecol(72) , l_parsecol(73) , l_parsecol(74) , l_parsecol(75) , l_parsecol(76) , l_parsecol(77) , l_parsecol(78) , l_parsecol(79) , l_parsecol(80) 
		, l_parsecol(81) , l_parsecol(82) , l_parsecol(83) , l_parsecol(84) , l_parsecol(85) , l_parsecol(86) , l_parsecol(87) , l_parsecol(88) , l_parsecol(89) , l_parsecol(90) 
		, l_parsecol(91) , l_parsecol(92) , l_parsecol(93) , l_parsecol(94) , l_parsecol(95) , l_parsecol(96) , l_parsecol(97) , l_parsecol(98) , l_parsecol(99) , l_parsecol(100) 
		, l_parsecol(101) , l_parsecol(102) , l_parsecol(103) , l_parsecol(104) , l_parsecol(105) , l_parsecol(106) , l_parsecol(107) , l_parsecol(108) , l_parsecol(109) , l_parsecol(110) 
		, l_parsecol(111) , l_parsecol(112) , l_parsecol(113) , l_parsecol(114) , l_parsecol(115) , l_parsecol(116) , l_parsecol(117) , l_parsecol(118) , l_parsecol(119) , l_parsecol(120) 
		, l_parsecol(121) , l_parsecol(122) , l_parsecol(123) , l_parsecol(124) , l_parsecol(125) , l_parsecol(126) , l_parsecol(127) , l_parsecol(128) , l_parsecol(129) , l_parsecol(130) 
		, l_parsecol(131) , l_parsecol(132) , l_parsecol(133) , l_parsecol(134) , l_parsecol(135) , l_parsecol(136) , l_parsecol(137) , l_parsecol(138) , l_parsecol(139) , l_parsecol(140) 
		, l_parsecol(141) , l_parsecol(142) , l_parsecol(143) , l_parsecol(144) , l_parsecol(145) , l_parsecol(146) , l_parsecol(147) , l_parsecol(148) , l_parsecol(149) , l_parsecol(150) 
		, l_parsecol(151) , l_parsecol(152) , l_parsecol(153) , l_parsecol(154) , l_parsecol(155) , l_parsecol(156) , l_parsecol(157) , l_parsecol(158) , l_parsecol(159) , l_parsecol(160) 
		, l_parsecol(161) , l_parsecol(162) , l_parsecol(163) , l_parsecol(164) , l_parsecol(165) , l_parsecol(166) , l_parsecol(167) , l_parsecol(168) , l_parsecol(169) , l_parsecol(170) 
		, l_parsecol(171) , l_parsecol(172) , l_parsecol(173) , l_parsecol(174) , l_parsecol(175) , l_parsecol(176) , l_parsecol(177) , l_parsecol(178) , l_parsecol(179) , l_parsecol(180) 
		, l_parsecol(181) , l_parsecol(182) , l_parsecol(183) , l_parsecol(184) , l_parsecol(185) , l_parsecol(186) , l_parsecol(187) , l_parsecol(188) , l_parsecol(189) , l_parsecol(190) 
		, l_parsecol(191) , l_parsecol(192) , l_parsecol(193) , l_parsecol(194) , l_parsecol(195) , l_parsecol(196) , l_parsecol(197) , l_parsecol(198) , l_parsecol(199) , l_parsecol(200) 
		, l_parsecol(201) , l_parsecol(202) , l_parsecol(203) , l_parsecol(204) , l_parsecol(205) , l_parsecol(206) , l_parsecol(207) , l_parsecol(208) , l_parsecol(209) , l_parsecol(210) 
		, l_parsecol(211) , l_parsecol(212) , l_parsecol(213) , l_parsecol(214) , l_parsecol(215) , l_parsecol(216) , l_parsecol(217) , l_parsecol(218) , l_parsecol(219) , l_parsecol(220) 
		, l_parsecol(221) , l_parsecol(222) , l_parsecol(223) , l_parsecol(224) , l_parsecol(225) , l_parsecol(226) , l_parsecol(227) , l_parsecol(228) , l_parsecol(229) , l_parsecol(230) 
		, l_parsecol(231) , l_parsecol(232) , l_parsecol(233) , l_parsecol(234) , l_parsecol(235) , l_parsecol(236) , l_parsecol(237) , l_parsecol(238) , l_parsecol(239) , l_parsecol(240) 
		, l_parsecol(241) , l_parsecol(242) , l_parsecol(243) , l_parsecol(244) , l_parsecol(245) , l_parsecol(246) , l_parsecol(247) , l_parsecol(248) , l_parsecol(249) , l_parsecol(250) 
		, l_parsecol(251) , l_parsecol(252) , l_parsecol(253) , l_parsecol(254) , l_parsecol(255) , l_parsecol(256) , l_parsecol(257) , l_parsecol(258) , l_parsecol(259) , l_parsecol(260) 
		, l_parsecol(261) , l_parsecol(262) , l_parsecol(263) , l_parsecol(264) , l_parsecol(265) , l_parsecol(266) , l_parsecol(267) , l_parsecol(268) , l_parsecol(269) , l_parsecol(270) 
		, l_parsecol(271) , l_parsecol(272) , l_parsecol(273) , l_parsecol(274) , l_parsecol(275) , l_parsecol(276) , l_parsecol(277) , l_parsecol(278) , l_parsecol(279) , l_parsecol(280) 
		, l_parsecol(281) , l_parsecol(282) , l_parsecol(283) , l_parsecol(284) , l_parsecol(285) , l_parsecol(286) , l_parsecol(287) , l_parsecol(288) , l_parsecol(289) , l_parsecol(290) 
		, l_parsecol(291) , l_parsecol(292) , l_parsecol(293) , l_parsecol(294) , l_parsecol(295) , l_parsecol(296) , l_parsecol(297) , l_parsecol(298) , l_parsecol(299) , l_parsecol(300)
        FROM
            TABLE ( apex_data_parser.parse(p_content => p_app_temp_file.blob_content, p_file_name => p_app_temp_file.filename, p_max_rows => 2) )
        FETCH FIRST ROW ONLY
        /* APEX_DATA_PARSER bug: p_max_rows => 1 throws no data error when parsing CSV */
        ;

        RETURN l_parsecol;
    END;

    PROCEDURE p_create_column_collection (
        p_app_temp_file IN apex_application_temp_files%rowtype
    ) IS
        l_ret_file    apex_application_temp_files%rowtype;
        l_msg         VARCHAR2(4000);
        l_raw_headers apex_t_varchar2;
    BEGIN
        cc_dta_util_pkg.p_get_file_to_process(p_app_temp_file, l_ret_file, l_msg);
        IF l_msg IS NOT NULL THEN
            return;
        END IF;

        l_raw_headers := f_get_raw_header_columns(l_ret_file);

        apex_collection.create_or_truncate_collection(p_collection_name => 'DATA_LOAD_METADATA');
        FOR r IN (
            SELECT
                column_position
              , column_name
              , data_type
              , format_mask
              , clob_content_column
              FROM
                TABLE ( apex_data_parser.get_columns(apex_data_parser.discover(p_content => l_ret_file.blob_content
                                                                             , p_file_name => l_ret_file.filename)) ) p
        ) LOOP
            apex_collection.add_member(p_collection_name => 'DATA_LOAD_METADATA', p_n001 => r.column_position
                                     --, p_c001 => r.column_name
                                     , p_c001 => SUBSTR(UPPER(REGEXP_REPLACE(l_raw_headers(r.column_position), '\W', '_', 1, 0)), 1, 128)
                                     , p_c002 => r.data_type
                                     , p_c003 => replace(r.format_mask, '"')
                                     , p_c004 => r.clob_content_column);
        END LOOP;

    END;

    FUNCTION f_generate_column_ddl (
        p_collection_name  IN  VARCHAR2
      , p_options          IN  process_options
    ) RETURN CLOB IS
        l_return CLOB;
    BEGIN
        FOR c IN (
            SELECT
                n001  AS column_position
              , c001  AS column_name
              , c002  AS data_type
              , c003  AS format_mask
              , c004  AS clob_content_column
              , c005  AS nullable
              FROM
                apex_collections
             WHERE
                collection_name = p_collection_name
             ORDER BY
                n001
        ) LOOP
            IF c.column_position = 1 THEN
                l_return := '"'
                            || c.column_name
                            || '"'
                            || ' '
                            || CASE
                                WHEN c.data_type = 'CLOB' THEN
                                    c.data_type
                                ELSE nvl(p_options.data_type_override, c.data_type)
                                END
                            || CASE WHEN c.nullable = 'N' THEN ' NOT NULL' END;

            ELSE
                l_return := l_return
                            || ', '
                            || '"'
                            || c.column_name
                            || '"'
                            || ' '
                            || CASE
                                WHEN c.data_type = 'CLOB' THEN
                                    c.data_type
                                ELSE nvl(p_options.data_type_override, c.data_type)
                                END
                            || CASE WHEN c.nullable = 'N' THEN ' NOT NULL' END;
            END IF;
        END LOOP;

        RETURN l_return;
    END;

    PROCEDURE p_create_source_table (
        p_schema_name        IN  VARCHAR2
      , p_table_name         IN  VARCHAR2
      , p_column_collection  IN  VARCHAR2
      , p_options            IN  process_options
    ) IS
        l_sql CLOB;
    BEGIN
        l_sql := 'CREATE TABLE '
                 || p_schema_name
                 || '.'
                 || p_table_name
                 || '('
                 || f_generate_column_ddl(p_column_collection, p_options)
                 || ')';

        apex_debug.message(l_sql);
        EXECUTE IMMEDIATE l_sql;
    END p_create_source_table;

    PROCEDURE p_load_table_from_file (
        p_schema_name    IN   VARCHAR2
      , p_table_name     IN   VARCHAR2
      , p_app_temp_file  IN   apex_application_temp_files%rowtype
      , p_options        IN   process_options
      , p_rows           OUT  NUMBER
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
            apex_debug.message('=== Creating table to be loaded ===');
            p_create_source_table(p_schema_name, p_table_name, 'DATA_LOAD_METADATA'
                                , p_options);
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
                collection_name = 'DATA_LOAD_METADATA'
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
                       AND table_name             = upper(p_table_name)
                       AND upper(REGEXP_REPLACE(column_name, '[^A-Z0-9]+', '', 1, 0, 'i'))
                                                  = upper(REGEXP_REPLACE(i.column_name, '[^A-Z0-9]+', '', 1, 0, 'i')) /* alphanumeric chars match */
                 FETCH FIRST ROW ONLY;

            EXCEPTION
                WHEN no_data_found THEN
                    l_column_exists             := 'N';
                    l_columnname                := NULL;
                    l_existing_column_datatype  := NULL;
            END;

            IF l_column_exists = 'Y' AND p_options.addl_columns IS NOT NULL THEN
                /* Exclude columns in file that is already in p_options.addl_columns */
                IF l_columnname MEMBER OF p_options.addl_columns THEN
                    CONTINUE;
                END IF;
            END IF;

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
                    AND ( l_existing_column_datatype LIKE '%CHAR%' OR l_existing_column_datatype = 'CLOB' )
                    AND p_options.reformat_date IS NOT NULL
                THEN
                    apex_string.push(l_selectcol, 'TO_CHAR(TO_DATE('
                                                  || 'COL'
                                                  || trim(to_char(i.column_position, '009'))
                                                  || ','''
                                                  || i.format_mask
                                                  || '''),'''
                                                  || p_options.reformat_date
                                                  || ''')');
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

        IF p_options.addl_columns IS NOT NULL THEN
            IF MOD(p_options.addl_columns.count, 2) = 0 THEN /* must have even elements */
                FOR addlc IN 1..(p_options.addl_columns.count - 1)
                LOOP
                    IF MOD(addlc, 2) = 1 THEN /* process key elements only */
                        apex_string.push(l_headercol, p_options.addl_columns(addlc));
                        apex_string.push(l_selectcol, p_options.addl_columns(addlc + 1));
                    END IF;
                END LOOP;
            END IF;
        END IF;

        IF l_headercol.count = 0 THEN
            apex_error.add_error(p_message => 'No matching columns found on table. No data loaded.'
                               , p_display_location => apex_error.c_on_error_page);
            return;
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
            TABLE ( apex_data_parser.parse(p_content => :fileblob, p_file_name => :filename, p_skip_rows => 1) )';

        IF p_options.errlog_tbl IS NOT NULL THEN
            l_insert_sql := l_insert_sql || ' LOG ERRORS INTO ' || p_options.errlog_tbl || ' (''' || p_options.load_id || ''') REJECT LIMIT UNLIMITED';
        END IF;

        apex_debug.message('l_insert_sql: [%s]', l_insert_sql);
        apex_debug.message('p_app_temp_file.filename: [%s]', p_app_temp_file.filename);
        EXECUTE IMMEDIATE l_insert_sql
            USING p_app_temp_file.blob_content, p_app_temp_file.filename;
        p_rows        := SQL%rowcount;
    END p_load_table_from_file;

    FUNCTION f_stripbom (
        p_in_blob IN BLOB
    ) RETURN BLOB IS
        l_cached_blob  BLOB;
        l_blob_size    PLS_INTEGER;
    BEGIN
        l_blob_size := dbms_lob.getlength(p_in_blob);
        IF l_blob_size > 3 THEN
            IF rawtohex(dbms_lob.substr(p_in_blob, 3)) = 'EFBBBF' THEN
                dbms_lob.createtemporary(l_cached_blob, true);
                dbms_lob.copy(dest_lob => l_cached_blob, src_lob => p_in_blob, amount => l_blob_size - 3
                            , dest_offset => 1
                            , src_offset => 4);

                RETURN l_cached_blob;
            END IF;

        END IF;

        RETURN p_in_blob;
    END;

    PROCEDURE p_get_file_to_process (
        p_app_temp_file  IN   apex_application_temp_files%rowtype
      , p_return_file    OUT NOCOPY apex_application_temp_files%rowtype
      , p_error_msg      OUT  VARCHAR2
    ) IS
        l_files       apex_zip.t_files;
        l_final_blob  BLOB;
    BEGIN
        IF p_app_temp_file.mime_type = 'application/zip' THEN
            l_files := apex_zip.get_files(p_zipped_blob => p_app_temp_file.blob_content);
            FOR i IN 1..l_files.count LOOP
                IF regexp_like(l_files(i), '\.(csv|xlsx)$', 'i') THEN
                    p_return_file.filename := l_files(i);
                    IF regexp_like(l_files(i), '\.csv$', 'i') THEN
                        p_return_file.blob_content := f_stripbom(apex_zip.get_file_content(p_zipped_blob => p_app_temp_file.blob_content,
                        p_file_name => l_files(i)));

                    ELSE
                        p_return_file.blob_content := apex_zip.get_file_content(p_zipped_blob => p_app_temp_file.blob_content, p_file_name =>
                        l_files(i));
                    END IF;

                    EXIT;
                END IF;
            END LOOP;

            IF p_return_file.blob_content IS NULL THEN
                p_error_msg := 'No CSV or XLSX file found in zip.';
                return;
            END IF;
        ELSIF p_app_temp_file.mime_type IN ( 'text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ) THEN
            p_return_file.filename := p_app_temp_file.filename;
            IF p_app_temp_file.mime_type = 'text/csv' THEN
                p_return_file.blob_content := f_stripbom(p_app_temp_file.blob_content);
            ELSE
                p_return_file.blob_content := p_app_temp_file.blob_content;
            END IF;

        ELSE
            p_error_msg := 'File must be CSV or XLSX, or ZIP containing CSV or XLSX.';
            return;
        END IF;
    END;

    PROCEDURE p_process_file_upload (
        p_schema_name    IN   VARCHAR2
      , p_table_name     IN   VARCHAR2
      , p_app_temp_file  IN   apex_application_temp_files%rowtype
      , p_options        IN   process_options
      , p_rows           OUT  NUMBER
    ) IS
        l_tmp_file   apex_application_temp_files%rowtype;
        l_error_msg  VARCHAR2(4000);
    BEGIN
        p_get_file_to_process(p_app_temp_file => p_app_temp_file, p_return_file => l_tmp_file, p_error_msg => l_error_msg);
        IF l_error_msg IS NOT NULL THEN
            apex_error.add_error(p_message => l_error_msg || ' Data load aborted.'
                               , p_display_location => apex_error.c_on_error_page);

            return;
        END IF;

        apex_debug.message('=== Calling p_load_table_from_file ===');
        p_load_table_from_file(p_schema_name => p_schema_name, p_table_name => p_table_name
                             , p_app_temp_file => l_tmp_file
                             , p_options => p_options
                             , p_rows => p_rows);

    END;

    FUNCTION f_get_file_from_os (
        p_base_url     IN  VARCHAR2
      , p_bucket_name  IN  VARCHAR2
      , p_filename     IN  VARCHAR2
    ) RETURN apex_application_temp_files%rowtype IS
        l_return       apex_application_temp_files%rowtype;
        l_os_response  BLOB;
    BEGIN
        l_os_response := apex_web_service.make_rest_request_b(p_url => p_base_url
                                                                       || 'b/'
                                                                       || p_bucket_name
                                                                       || '/o/'
                                                                       || p_filename
                                                            , p_http_method => 'GET'
                                                            , p_credential_static_id => 'OCI_API_ACCESS');

        IF apex_web_service.g_status_code = 200 THEN
            l_return.blob_content    := l_os_response;
            l_return.filename        := p_filename;
            FOR i IN 1..apex_web_service.g_headers.count LOOP
                IF upper(apex_web_service.g_headers(i).name) = 'CONTENT-TYPE' THEN
                    l_return.mime_type := apex_web_service.g_headers(i).value;
                    EXIT;
                END IF;
            END LOOP;

        ELSE
            apex_error.add_error(p_message => 'Cannot retrieve file from objects storage.'
                               , p_display_location => apex_error.c_on_error_page);
        END IF;

        RETURN l_return;
    END;

END cmn_data_parser_util_pkg;
