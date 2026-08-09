-- VeeBiiz Physical Items — MariaDB schema
-- Import once, or let the resource auto-create on start via oxmysql.

CREATE TABLE IF NOT EXISTS `physical_objects` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `zone_id` VARCHAR(64) NOT NULL,
    `slot_id` VARCHAR(64) NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `model` VARCHAR(128) NOT NULL,
    `x` DOUBLE NOT NULL,
    `y` DOUBLE NOT NULL,
    `z` DOUBLE NOT NULL,
    `rot_x` DOUBLE NOT NULL DEFAULT 0,
    `rot_y` DOUBLE NOT NULL DEFAULT 0,
    `rot_z` DOUBLE NOT NULL DEFAULT 0,
    `metadata` LONGTEXT NULL,
    `owner` VARCHAR(64) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_zone_slot` (`zone_id`, `slot_id`),
    KEY `idx_item` (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
