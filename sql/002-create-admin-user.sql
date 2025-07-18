--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
-- OF ANY KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--

-- Create default user "guacadmin" with password "guacadmin"
INSERT INTO guacamole_entity (name, type) 
SELECT 'guacadmin', 'USER'
WHERE NOT EXISTS (SELECT 1 FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER');

-- Only insert the user's password if the user exists
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
SELECT
    entity_id,
    x'CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960',  -- 'guacadmin'
    x'FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264',
    NOW()
FROM guacamole_entity 
WHERE name = 'guacadmin' AND NOT EXISTS (SELECT 1 FROM guacamole_user WHERE entity_id = guacamole_entity.entity_id);

-- Grant this user all system permissions if they don't already exist
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission
FROM (
          SELECT 'guacadmin'  AS username, 'CREATE_CONNECTION'       AS permission
    UNION SELECT 'guacadmin'  AS username, 'CREATE_CONNECTION_GROUP' AS permission
    UNION SELECT 'guacadmin'  AS username, 'CREATE_SHARING_PROFILE'  AS permission
    UNION SELECT 'guacadmin'  AS username, 'CREATE_USER'             AS permission
    UNION SELECT 'guacadmin'  AS username, 'CREATE_USER_GROUP'       AS permission
    UNION SELECT 'guacadmin'  AS username, 'ADMINISTER'              AS permission
) permissions
JOIN guacamole_entity ON permissions.username = guacamole_entity.name AND guacamole_entity.type = 'USER'
WHERE NOT EXISTS (SELECT 1 FROM guacamole_system_permission 
                  WHERE entity_id = guacamole_entity.entity_id AND permission = permissions.permission);

-- Grant admin permission to read/update/administer self if they don't already exist
INSERT INTO guacamole_user_permission (entity_id, affected_user_id, permission)
SELECT guacamole_entity.entity_id, guacamole_user.user_id, permission
FROM (
          SELECT 'guacadmin' AS username, 'guacadmin' AS affected_username, 'READ'       AS permission
    UNION SELECT 'guacadmin' AS username, 'guacadmin' AS affected_username, 'UPDATE'     AS permission
    UNION SELECT 'guacadmin' AS username, 'guacadmin' AS affected_username, 'ADMINISTER' AS permission
) permissions
JOIN guacamole_entity          ON permissions.username = guacamole_entity.name AND guacamole_entity.type = 'USER'
JOIN guacamole_entity affected ON permissions.affected_username = affected.name AND guacamole_entity.type = 'USER'
JOIN guacamole_user            ON guacamole_user.entity_id = affected.entity_id
WHERE NOT EXISTS (SELECT 1 FROM guacamole_user_permission WHERE entity_id = guacamole_entity.entity_id AND affected_user_id = guacamole_user.user_id AND permission = permissions.permission);
