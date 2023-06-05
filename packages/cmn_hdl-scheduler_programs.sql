--------------------------------------------------------
--  Define scheduler programs
--------------------------------------------------------
BEGIN
    dbms_scheduler.create_program(program_name => 'CMN_HDL_LOAD', program_action => 'cmn_hdl_utility_pkg.initiate_job'
                                , program_type => 'STORED_PROCEDURE'
                                , number_of_arguments => 1
                                , comments => 'Invoke HDL Import and Load job process'
                                , enabled => false);
END;
/

BEGIN
    dbms_scheduler.define_program_argument(program_name => 'CMN_HDL_LOAD', argument_position => 1, argument_name => 'p_job_id'
                                         , argument_type => 'NUMBER');
END;
/

BEGIN
    dbms_scheduler.enable('CMN_HDL_LOAD');
END;
/