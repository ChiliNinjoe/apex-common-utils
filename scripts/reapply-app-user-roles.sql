-- Create backup of app user roles
CREATE TABLE app_user_roles_bkup
    AS
        SELECT
            workspace
          , application_id
          , user_name
          , role_static_id
          FROM
            apex_appl_acl_user_roles
         WHERE
            application_id = &app_id;

-- Reapply app user roles
BEGIN
    FOR ur IN (
        SELECT
            application_id
          , user_name
          , role_static_id
          FROM
            app_user_roles_bkup
    ) LOOP
        apex_acl.add_user_role(p_application_id => ur.application_id, p_user_name => ur.user_name, p_role_static_id => ur.role_static_id);
    END LOOP;
END;
/