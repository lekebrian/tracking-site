-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 04, 2025 at 02:00 PM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tnt_tracking`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=CURRENT_USER PROCEDURE `CreateShipment` (IN `p_id` VARCHAR(15), IN `p_description` TEXT, IN `p_origin` VARCHAR(255), IN `p_destination` VARCHAR(255), IN `p_sender_name` VARCHAR(255), IN `p_sender_location` VARCHAR(255), IN `p_sender_email` VARCHAR(255), IN `p_sender_phone` VARCHAR(50), IN `p_receiver_name` VARCHAR(255), IN `p_receiver_address` TEXT, IN `p_receiver_email` VARCHAR(255), IN `p_receiver_phone` VARCHAR(50), IN `p_carrier` ENUM('FedEx','DHL','USPS','UPS','TNT'), IN `p_shipment_type` ENUM('Air Freight','Sea Freight','Road Freight','Rail Freight'), IN `p_weight` DECIMAL(10,2), IN `p_created_by` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insert shipment
    INSERT INTO shipments (
        id, description, origin, destination,
        sender_name, sender_location, sender_email, sender_phone,
        receiver_name, receiver_address, receiver_email, receiver_phone,
        carrier, shipment_type, weight, created_by
    ) VALUES (
        p_id, p_description, p_origin, p_destination,
        p_sender_name, p_sender_location, p_sender_email, p_sender_phone,
        p_receiver_name, p_receiver_address, p_receiver_email, p_receiver_phone,
        p_carrier, p_shipment_type, p_weight, p_created_by
    );
    
    -- Add initial history entry
    INSERT INTO shipment_history (shipment_id, date, time, location, status, updated_by, remarks)
    VALUES (p_id, CURDATE(), CURTIME(), p_origin, 'Pending', 'System', 'Shipment created');
    
    -- Generate QR code entry
    INSERT INTO qr_codes (shipment_id, qr_code_data)
    VALUES (p_id, CONCAT('https://tnt-tracking.com/track?id=', p_id));
    
    COMMIT;
END$$

CREATE DEFINER=CURRENT_USER PROCEDURE `GetShipmentDetails` (IN `tracking_id` VARCHAR(15))   BEGIN
    -- Get main shipment info
    SELECT * FROM shipments WHERE id = tracking_id;
    
    -- Get packages
    SELECT * FROM packages WHERE shipment_id = tracking_id ORDER BY id;
    
    -- Get history
    SELECT * FROM shipment_history 
    WHERE shipment_id = tracking_id 
    ORDER BY date DESC, time DESC;
    
    -- Get QR code
    SELECT qr_code_data FROM qr_codes WHERE shipment_id = tracking_id;
END$$

CREATE DEFINER=CURRENT_USER PROCEDURE `UpdateShipmentStatus` (IN `tracking_id` VARCHAR(15), IN `new_status` ENUM('Pending','In Transit','On Hold','Delivered'), IN `location` VARCHAR(255), IN `updated_by` VARCHAR(100), IN `remarks` TEXT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Update shipment status
    UPDATE shipments 
    SET status = new_status, updated_at = CURRENT_TIMESTAMP 
    WHERE id = tracking_id;
    
    -- Add history entry
    INSERT INTO shipment_history (shipment_id, date, time, location, status, updated_by, remarks)
    VALUES (tracking_id, CURDATE(), CURTIME(), location, new_status, updated_by, remarks);
    
    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `latest_shipment_status`
-- (See below for the actual view)
--
CREATE TABLE `latest_shipment_status` (
`shipment_id` varchar(15)
,`last_update_date` date
,`last_update_time` time
,`current_location` varchar(255)
,`current_status` enum('Pending','In Transit','On Hold','Delivered')
,`updated_by` varchar(100)
,`remarks` text
);

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` int(11) NOT NULL,
  `shipment_id` varchar(15) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `piece_type` enum('Loose','Pallet','Box','Crate') DEFAULT 'Box',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`id`, `shipment_id`, `quantity`, `piece_type`, `description`, `created_at`) VALUES
(1, 'ABC123XYZ456789', 1, 'Box', 'MacBook Pro 16-inch in original packaging', '2025-06-03 04:32:38'),
(2, 'ABC123XYZ456789', 1, 'Box', 'Laptop accessories and charger', '2025-06-03 04:32:38'),
(3, 'DEF456UVW789012', 1, 'Loose', 'Sealed envelope with legal documents', '2025-06-03 04:32:38'),
(4, 'GHI789RST012345', 2, 'Box', 'Evening dresses - size M', '2025-06-03 04:32:38'),
(5, 'GHI789RST012345', 1, 'Box', 'Casual wear collection', '2025-06-03 04:32:38'),
(6, 'GHI789RST012345', 2, 'Box', 'Accessories and shoes', '2025-06-03 04:32:38'),
(7, '111222333444555', 3245, 'Box', 'dfsdfsafas', '2025-06-03 04:59:02'),
(8, 'DAJ620065198187', 34, 'Pallet', 'thios fkjsdf  fsdofhsdiof', '2025-06-03 06:36:05');

--
-- Triggers `packages`
--
DELIMITER $$
CREATE TRIGGER `update_shipment_on_package_change` AFTER INSERT ON `packages` FOR EACH ROW BEGIN
    UPDATE shipments 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.shipment_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_shipment_on_package_delete` AFTER DELETE ON `packages` FOR EACH ROW BEGIN
    UPDATE shipments 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = OLD.shipment_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_shipment_on_package_update` AFTER UPDATE ON `packages` FOR EACH ROW BEGIN
    UPDATE shipments 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.shipment_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `qr_codes`
--

CREATE TABLE `qr_codes` (
  `id` int(11) NOT NULL,
  `shipment_id` varchar(15) NOT NULL,
  `qr_code_data` text NOT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `qr_codes`
--

INSERT INTO `qr_codes` (`id`, `shipment_id`, `qr_code_data`, `generated_at`) VALUES
(1, 'ABC123XYZ456789', 'https://tnt-tracking.com/track?id=ABC123XYZ456789', '2025-06-03 04:32:38'),
(2, 'DEF456UVW789012', 'https://tnt-tracking.com/track?id=DEF456UVW789012', '2025-06-03 04:32:38'),
(3, 'GHI789RST012345', 'https://tnt-tracking.com/track?id=GHI789RST012345', '2025-06-03 04:32:38');

-- --------------------------------------------------------

--
-- Table structure for table `shipments`
--

CREATE TABLE `shipments` (
  `id` varchar(15) NOT NULL,
  `description` text DEFAULT NULL,
  `origin` varchar(255) NOT NULL,
  `destination` varchar(255) NOT NULL,
  `sender_name` varchar(255) DEFAULT NULL,
  `sender_location` varchar(255) DEFAULT NULL,
  `sender_email` varchar(255) DEFAULT NULL,
  `sender_phone` varchar(50) DEFAULT NULL,
  `receiver_name` varchar(255) DEFAULT NULL,
  `receiver_address` text DEFAULT NULL,
  `receiver_email` varchar(255) DEFAULT NULL,
  `receiver_phone` varchar(50) DEFAULT NULL,
  `status` enum('Pending','In Transit','On Hold','Delivered') DEFAULT 'Pending',
  `carrier` enum('FedEx','DHL','USPS','UPS','TNT') DEFAULT 'TNT',
  `shipment_type` enum('Air Freight','Sea Freight','Road Freight','Rail Freight') DEFAULT 'Air Freight',
  `shipment_mode` enum('Air Freight','Express','Standard','Economy') DEFAULT 'Standard',
  `weight` decimal(10,2) DEFAULT NULL,
  `number_of_boxes` int(11) DEFAULT 1,
  `carrier_ref_number` varchar(100) DEFAULT NULL,
  `product_name` varchar(255) DEFAULT NULL,
  `quantity` int(11) DEFAULT 1,
  `total_freight` decimal(10,2) DEFAULT NULL,
  `expected_delivery_date` date DEFAULT NULL,
  `departure_time` time DEFAULT NULL,
  `pick_up_date` date DEFAULT NULL,
  `pick_up_time` time DEFAULT NULL,
  `total_weight` decimal(10,2) DEFAULT NULL,
  `total_volumetric_weight` decimal(10,2) DEFAULT NULL,
  `total_volume` decimal(10,3) DEFAULT NULL,
  `total_actual_weight` decimal(10,2) DEFAULT NULL,
  `comments` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `shipments`
--

INSERT INTO `shipments` (`id`, `description`, `origin`, `destination`, `sender_name`, `sender_location`, `sender_email`, `sender_phone`, `receiver_name`, `receiver_address`, `receiver_email`, `receiver_phone`, `status`, `carrier`, `shipment_type`, `shipment_mode`, `weight`, `number_of_boxes`, `carrier_ref_number`, `product_name`, `quantity`, `total_freight`, `expected_delivery_date`, `departure_time`, `pick_up_date`, `pick_up_time`, `total_weight`, `total_volumetric_weight`, `total_volume`, `total_actual_weight`, `comments`, `created_at`, `updated_at`, `created_by`) VALUES
('111222333444555', 'dfsdf', 'afa', 'dfadf', 'adfas', 'afd', 'lekebryan64@gmail.com', 'dfaf', 'LEKE', 'adsfa', 'adsfa@gmail.com', '3452345', 'In Transit', 'USPS', 'Sea Freight', 'Standard', '445.00', 34, '1234324134', '1234123412', 121, '123.00', '2025-06-26', '05:00:00', '2025-06-27', '08:58:00', '234.00', '234234.00', '234.000', '234.00', 'dfasdfa', '2025-06-03 04:59:02', '2025-06-03 04:59:02', NULL),
('ABC123XYZ456789', 'Electronics Package - High-end Laptop Computer with Accessories', 'New York, USA', 'London, UK', 'John Smith', 'Manhattan, New York', 'john.smith@email.com', '+1-555-0123', 'Sarah Johnson', '123 Baker Street, London, UK', 'sarah.johnson@email.com', '+44-20-7946-0958', 'In Transit', 'FedEx', 'Air Freight', 'Express', '2.50', 1, 'FX123456789', 'MacBook Pro 16-inch', 1, '299.99', '2025-01-15', '14:30:00', '2025-01-10', '09:00:00', '2.50', '2.80', '0.015', '2.50', 'Handle with care - fragile electronics. Signature required upon delivery.', '2025-01-01 09:00:00', '2025-01-02 13:30:00', NULL),
('DAJ620065198187', NULL, '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Delivered', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-06-03 06:36:05', '2025-06-03 07:16:33', NULL),
('DEF456UVW789012', 'Legal Documents Package - Important Contract Papers', 'Los Angeles, USA', 'Tokyo, Japan', 'Michael Brown', 'Downtown LA', 'michael.brown@lawfirm.com', '+1-555-0456', 'Hiroshi Tanaka', '456 Shibuya District, Tokyo, Japan', 'hiroshi.tanaka@company.jp', '+81-3-1234-5678', 'Delivered', 'DHL', 'Air Freight', 'Express', '0.50', 1, 'DHL987654321', 'Legal Documents', 1, '149.99', '2025-01-05', '22:15:00', '2024-12-28', '08:00:00', '0.50', '0.60', '0.002', '0.50', 'Confidential documents - secure handling required.', '2024-12-28 07:00:00', '2025-01-01 15:45:00', NULL),
('GHI789RST012345', 'Fashion Items - Designer Clothing Collection', 'Paris, France', 'Sydney, Australia', 'Marie Dubois', 'Champs-Élysées, Paris', 'marie.dubois@fashion.fr', '+33-1-42-96-12-34', 'Emma Wilson', '789 George Street, Sydney, Australia', 'emma.wilson@email.com', '+61-2-9876-5432', 'Pending', 'TNT', 'Air Freight', 'Standard', '5.20', 3, 'TNT555666777', 'Designer Dresses', 5, '599.99', '2025-01-20', '11:45:00', '2025-01-03', '12:00:00', '5.20', '6.10', '0.045', '5.20', 'Fashion items - avoid folding. Temperature controlled environment preferred.', '2025-01-03 11:00:00', '2025-01-03 11:00:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `shipment_history`
--

CREATE TABLE `shipment_history` (
  `id` int(11) NOT NULL,
  `shipment_id` varchar(15) NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `location` varchar(255) NOT NULL,
  `status` enum('Pending','In Transit','On Hold','Delivered') NOT NULL,
  `updated_by` varchar(100) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `shipment_history`
--

INSERT INTO `shipment_history` (`id`, `shipment_id`, `date`, `time`, `location`, `status`, `updated_by`, `remarks`, `created_at`) VALUES
(1, 'ABC123XYZ456789', '2025-01-01', '10:00:00', 'New York Warehouse', 'Pending', 'System', 'Shipment created and awaiting pickup', '2025-06-03 04:32:38'),
(2, 'ABC123XYZ456789', '2025-01-01', '15:30:00', 'FedEx Facility NYC', 'In Transit', 'John Doe', 'Package picked up and processed', '2025-06-03 04:32:38'),
(3, 'ABC123XYZ456789', '2025-01-02', '08:15:00', 'JFK Airport', 'In Transit', 'Airport Handler', 'Loaded onto flight FX1234', '2025-06-03 04:32:38'),
(4, 'ABC123XYZ456789', '2025-01-02', '14:30:00', 'Heathrow Airport', 'In Transit', 'UK Customs', 'Cleared customs, proceeding to local facility', '2025-06-03 04:32:38'),
(5, 'DEF456UVW789012', '2024-12-28', '08:00:00', 'Los Angeles Office', 'Pending', 'System', 'Document package prepared', '2025-06-03 04:32:38'),
(6, 'DEF456UVW789012', '2024-12-28', '12:30:00', 'DHL Hub LA', 'In Transit', 'DHL Agent', 'Express shipment processed', '2025-06-03 04:32:38'),
(7, 'DEF456UVW789012', '2024-12-30', '18:45:00', 'Tokyo Distribution Center', 'In Transit', 'Local Agent', 'Arrived in Tokyo, out for delivery', '2025-06-03 04:32:38'),
(8, 'DEF456UVW789012', '2025-01-01', '16:45:00', 'Tokyo Office Building', 'Delivered', 'Delivery Driver', 'Successfully delivered to recipient', '2025-06-03 04:32:38'),
(9, 'GHI789RST012345', '2025-01-03', '12:00:00', 'Paris Fashion District', 'Pending', 'System', 'Fashion items packaged and labeled', '2025-06-03 04:32:38'),
(10, '111222333444555', '2025-06-03', '05:59:02', 'afa', 'In Transit', 'admin', 'Shipment created', '2025-06-03 04:59:02'),
(11, 'DAJ620065198187', '2025-06-03', '07:36:05', 'asdfadsfasd', 'On Hold', 'admin', 'Shipment created', '2025-06-03 06:36:05');

-- --------------------------------------------------------

--
-- Stand-in structure for view `shipment_summary`
-- (See below for the actual view)
--
CREATE TABLE `shipment_summary` (
`id` varchar(15)
,`description` text
,`origin` varchar(255)
,`destination` varchar(255)
,`status` enum('Pending','In Transit','On Hold','Delivered')
,`carrier` enum('FedEx','DHL','USPS','UPS','TNT')
,`expected_delivery_date` date
,`sender_name` varchar(255)
,`receiver_name` varchar(255)
,`package_count` bigint(21)
,`total_weight` decimal(10,2)
,`total_freight` decimal(10,2)
,`created_at` timestamp
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','user') DEFAULT 'admin',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `role`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$2b$10$rQZ8kHWKQYXyQqGqGqGqGOeKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK', 'admin', '2025-06-03 04:32:38', '2025-06-03 04:32:38');

-- --------------------------------------------------------

--
-- Structure for view `latest_shipment_status`
--
DROP TABLE IF EXISTS `latest_shipment_status`;

CREATE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW `latest_shipment_status`  AS SELECT `sh`.`shipment_id` AS `shipment_id`, `sh`.`date` AS `last_update_date`, `sh`.`time` AS `last_update_time`, `sh`.`location` AS `current_location`, `sh`.`status` AS `current_status`, `sh`.`updated_by` AS `updated_by`, `sh`.`remarks` AS `remarks` FROM (`shipment_history` `sh` join (select `shipment_history`.`shipment_id` AS `shipment_id`,max(concat(`shipment_history`.`date`,' ',`shipment_history`.`time`)) AS `latest_update` from `shipment_history` group by `shipment_history`.`shipment_id`) `latest` on(`sh`.`shipment_id` = `latest`.`shipment_id` and concat(`sh`.`date`,' ',`sh`.`time`) = `latest`.`latest_update`))  ;

-- --------------------------------------------------------

--
-- Structure for view `shipment_summary`
--
DROP TABLE IF EXISTS `shipment_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=CURRENT_USER SQL SECURITY DEFINER VIEW `shipment_summary`  AS SELECT `s`.`id` AS `id`, `s`.`description` AS `description`, `s`.`origin` AS `origin`, `s`.`destination` AS `destination`, `s`.`status` AS `status`, `s`.`carrier` AS `carrier`, `s`.`expected_delivery_date` AS `expected_delivery_date`, `s`.`sender_name` AS `sender_name`, `s`.`receiver_name` AS `receiver_name`, count(`p`.`id`) AS `package_count`, `s`.`total_weight` AS `total_weight`, `s`.`total_freight` AS `total_freight`, `s`.`created_at` AS `created_at`, `s`.`updated_at` AS `updated_at` FROM (`shipments` `s` left join `packages` `p` on(`s`.`id` = `p`.`shipment_id`)) GROUP BY `s`.`id`  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_packages_shipment_id` (`shipment_id`);

--
-- Indexes for table `qr_codes`
--
ALTER TABLE `qr_codes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `shipment_id` (`shipment_id`),
  ADD KEY `idx_qr_codes_shipment_id` (`shipment_id`);

--
-- Indexes for table `shipments`
--
ALTER TABLE `shipments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_shipments_status` (`status`),
  ADD KEY `idx_shipments_created_at` (`created_at`),
  ADD KEY `idx_shipments_updated_at` (`updated_at`),
  ADD KEY `idx_shipments_sender_email` (`sender_email`),
  ADD KEY `idx_shipments_receiver_email` (`receiver_email`),
  ADD KEY `idx_shipments_carrier` (`carrier`),
  ADD KEY `idx_shipments_expected_delivery` (`expected_delivery_date`);

--
-- Indexes for table `shipment_history`
--
ALTER TABLE `shipment_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_history_shipment_id` (`shipment_id`),
  ADD KEY `idx_history_date` (`date`),
  ADD KEY `idx_history_status` (`status`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `qr_codes`
--
ALTER TABLE `qr_codes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `shipment_history`
--
ALTER TABLE `shipment_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `packages`
--
ALTER TABLE `packages`
  ADD CONSTRAINT `packages_ibfk_1` FOREIGN KEY (`shipment_id`) REFERENCES `shipments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `qr_codes`
--
ALTER TABLE `qr_codes`
  ADD CONSTRAINT `qr_codes_ibfk_1` FOREIGN KEY (`shipment_id`) REFERENCES `shipments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `shipments`
--
ALTER TABLE `shipments`
  ADD CONSTRAINT `shipments_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `shipment_history`
--
ALTER TABLE `shipment_history`
  ADD CONSTRAINT `shipment_history_ibfk_1` FOREIGN KEY (`shipment_id`) REFERENCES `shipments` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@@COLLATION_CONNECTION */;