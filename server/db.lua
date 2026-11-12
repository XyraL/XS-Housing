Db = { ready = false }

local TABLES = {
    [[CREATE TABLE IF NOT EXISTS `xs_housing_properties` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `data` LONGTEXT NOT NULL,
        `created_at` INT NOT NULL DEFAULT 0,
        `updated_at` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_owners` (
        `property_id` INT NOT NULL,
        `citizenid` VARCHAR(64) NOT NULL,
        `name` VARCHAR(100) NOT NULL DEFAULT '',
        `kind` VARCHAR(16) NOT NULL DEFAULT 'owned',
        `since` INT NOT NULL DEFAULT 0,
        `next_due` INT NOT NULL DEFAULT 0,
        `amount` INT NOT NULL DEFAULT 0,
        `balance` INT NOT NULL DEFAULT 0,
        `payments_left` INT NOT NULL DEFAULT 0,
        `missed` INT NOT NULL DEFAULT 0,
        `deposit` INT NOT NULL DEFAULT 0,
        `locked` TINYINT NOT NULL DEFAULT 1,
        `style` VARCHAR(48) NOT NULL DEFAULT '',
        `house_name` VARCHAR(64) NOT NULL DEFAULT '',
        `storage_level` INT NOT NULL DEFAULT 0,
        `prefs` LONGTEXT NULL,
        `security` LONGTEXT NULL,
        `paid` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`property_id`),
        KEY `xsh_owner_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_keys` (
        `property_id` INT NOT NULL,
        `citizenid` VARCHAR(64) NOT NULL,
        `name` VARCHAR(100) NOT NULL DEFAULT '',
        `role` VARCHAR(16) NOT NULL DEFAULT 'guest',
        `expires` INT NOT NULL DEFAULT 0,
        `given_by` VARCHAR(64) NOT NULL DEFAULT '',
        PRIMARY KEY (`property_id`, `citizenid`),
        KEY `xsh_key_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_furniture` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `property_id` INT NOT NULL,
        `item` VARCHAR(64) NOT NULL,
        `model` VARCHAR(80) NOT NULL,
        `place` VARCHAR(8) NOT NULL DEFAULT 'inside',
        `x` DOUBLE NOT NULL DEFAULT 0,
        `y` DOUBLE NOT NULL DEFAULT 0,
        `z` DOUBLE NOT NULL DEFAULT 0,
        `rx` DOUBLE NOT NULL DEFAULT 0,
        `ry` DOUBLE NOT NULL DEFAULT 0,
        `rz` DOUBLE NOT NULL DEFAULT 0,
        `price` INT NOT NULL DEFAULT 0,
        `data` LONGTEXT NULL,
        PRIMARY KEY (`id`),
        KEY `xsh_furn_prop` (`property_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_settings` (
        `name` VARCHAR(64) NOT NULL,
        `data` LONGTEXT NOT NULL,
        PRIMARY KEY (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_logs` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `property_id` INT NOT NULL DEFAULT 0,
        `kind` VARCHAR(24) NOT NULL,
        `citizenid` VARCHAR(64) NOT NULL DEFAULT '',
        `name` VARCHAR(100) NOT NULL DEFAULT '',
        `detail` VARCHAR(255) NOT NULL DEFAULT '',
        `amount` INT NOT NULL DEFAULT 0,
        `at` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `xsh_log_prop` (`property_id`),
        KEY `xsh_log_at` (`at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_claims` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(64) NOT NULL,
        `property_id` INT NOT NULL,
        `owner_key` VARCHAR(64) NOT NULL,
        `label` VARCHAR(100) NOT NULL DEFAULT '',
        `until` INT NOT NULL DEFAULT 0,
        `stashes` LONGTEXT NULL,
        PRIMARY KEY (`id`),
        KEY `xsh_claim_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `xs_housing_pictures` (
        `id` VARCHAR(100) NOT NULL,
        `data` MEDIUMTEXT NOT NULL,
        `updated_at` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
}

function Db.Setup()
    for _, statement in ipairs(TABLES) do
        local ok, err = pcall(MySQL.query.await, statement)
        if not ok then
            print(('^1[XS-Housing]^0 could not create a table: %s'):format(tostring(err)))
            return false
        end
    end
    Db.ready = true
    return true
end

function Db.Json(value)
    local ok, out = pcall(json.encode, value)
    return ok and out or '{}'
end

function Db.Decode(value, fallback)
    if type(value) ~= 'string' or value == '' then return fallback end
    local ok, out = pcall(json.decode, value)
    if ok and out ~= nil then return out end
    return fallback
end
