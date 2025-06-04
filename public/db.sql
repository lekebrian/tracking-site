-- MySQL Database Schema for Enhanced TNT Tracking System
-- This schema supports all the comprehensive tracking features from v6

-- Create database
CREATE DATABASE IF NOT EXISTS tnt_tracking;
USE tnt_tracking;

-- Users table for admin authentication
-- CREATE TABLE users (
--     id INT PRIMARY KEY AUTO_INCREMENT,
--     username VARCHAR(50) UNIQUE NOT NULL,
--     password_hash VARCHAR(255) NOT NULL,
--     role ENUM('admin', 'user') DEFAULT 'admin',
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- );

-- Main shipments table with all comprehensive fields
CREATE TABLE shipments (
    id VARCHAR(15) PRIMARY KEY,  -- 15-character tracking ID
    description TEXT,
    
    -- Origin and Destination
    origin VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    
    -- Sender Information
    sender_name VARCHAR(255),
    sender_location VARCHAR(255),
    sender_email VARCHAR(255),
    sender_phone VARCHAR(50),
    
    -- Receiver Information
    receiver_name VARCHAR(255),
    receiver_address TEXT,
    receiver_email VARCHAR(255),
    receiver_phone VARCHAR(50),
    
    -- Shipment Information
    status ENUM('Pending', 'In Transit', 'On Hold', 'Delivered') DEFAULT 'Pending',
    carrier ENUM('FedEx', 'DHL', 'USPS', 'UPS', 'TNT') DEFAULT 'TNT',
    shipment_type ENUM('Air Freight', 'Sea Freight', 'Road Freight', 'Rail Freight') DEFAULT 'Air Freight',
    shipment_mode ENUM('Air Freight', 'Express', 'Standard', 'Economy') DEFAULT 'Standard',
    weight DECIMAL(10, 2),  -- in kg
    number_of_boxes INT DEFAULT 1,
    carrier_ref_number VARCHAR(100),
    product_name VARCHAR(255),
    quantity INT DEFAULT 1,
    total_freight DECIMAL(10, 2),  -- in USD
    
    -- Dates and Times
    expected_delivery_date DATE,
    departure_time TIME,
    pick_up_date DATE,
    pick_up_time TIME,
    
    -- Total Information
    total_weight DECIMAL(10, 2),  -- in kg
    total_volumetric_weight DECIMAL(10, 2),  -- in kg
    total_volume DECIMAL(10, 3),  -- in m³
    total_actual_weight DECIMAL(10, 2),  -- in kg
    
    -- Comments
    comments TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Packages table for detailed package information
CREATE TABLE packages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    shipment_id VARCHAR(15) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    piece_type ENUM('Loose', 'Pallet', 'Box', 'Crate') DEFAULT 'Box',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE
);

-- Shipment history table for tracking status changes and updates
CREATE TABLE shipment_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    shipment_id VARCHAR(15) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    location VARCHAR(255) NOT NULL,
    status ENUM('Pending', 'In Transit', 'On Hold', 'Delivered') NOT NULL,
    updated_by VARCHAR(100) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE
);

-- QR codes table for mobile tracking
CREATE TABLE qr_codes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    shipment_id VARCHAR(15) NOT NULL UNIQUE,
    qr_code_data TEXT NOT NULL,  -- Base64 encoded QR code or URL
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE
);

-- Insert default admin user (password: admin123)
-- Note: In production, use proper password hashing with bcrypt
INSERT INTO users (username, password_hash, role) VALUES 
('admin', '$2b$10$rQZ8kHWKQYXyQqGqGqGqGOeKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK', 'admin');

-- Insert comprehensive sample shipments with all fields
INSERT INTO shipments (
    id, description, origin, destination, 
    sender_name, sender_location, sender_email, sender_phone,
    receiver_name, receiver_address, receiver_email, receiver_phone,
    status, carrier, shipment_type, shipment_mode, weight, number_of_boxes,
    carrier_ref_number, product_name, quantity, total_freight,
    expected_delivery_date, departure_time, pick_up_date, pick_up_time,
    total_weight, total_volumetric_weight, total_volume, total_actual_weight,
    comments, created_at, updated_at
) VALUES
(
    'ABC123XYZ456789', 
    'Electronics Package - High-end Laptop Computer with Accessories',
    'New York, USA', 
    'London, UK',
    'John Smith', 
    'Manhattan, New York', 
    'john.smith@email.com', 
    '+1-555-0123',
    'Sarah Johnson', 
    '123 Baker Street, London, UK', 
    'sarah.johnson@email.com', 
    '+44-20-7946-0958',
    'In Transit', 
    'FedEx', 
    'Air Freight', 
    'Express', 
    2.5, 
    1,
    'FX123456789', 
    'MacBook Pro 16-inch', 
    1, 
    299.99,
    '2025-01-15', 
    '14:30:00', 
    '2025-01-10', 
    '09:00:00',
    2.5, 
    2.8, 
    0.015, 
    2.5,
    'Handle with care - fragile electronics. Signature required upon delivery.',
    '2025-01-01 10:00:00', 
    '2025-01-02 14:30:00'
),
(
    'DEF456UVW789012', 
    'Legal Documents Package - Important Contract Papers',
    'Los Angeles, USA', 
    'Tokyo, Japan',
    'Michael Brown', 
    'Downtown LA', 
    'michael.brown@lawfirm.com', 
    '+1-555-0456',
    'Hiroshi Tanaka', 
    '456 Shibuya District, Tokyo, Japan', 
    'hiroshi.tanaka@company.jp', 
    '+81-3-1234-5678',
    'Delivered', 
    'DHL', 
    'Air Freight', 
    'Express', 
    0.5, 
    1,
    'DHL987654321', 
    'Legal Documents', 
    1, 
    149.99,
    '2025-01-05', 
    '22:15:00', 
    '2024-12-28', 
    '08:00:00',
    0.5, 
    0.6, 
    0.002, 
    0.5,
    'Confidential documents - secure handling required.',
    '2024-12-28 08:00:00', 
    '2025-01-01 16:45:00'
),
(
    'GHI789RST012345', 
    'Fashion Items - Designer Clothing Collection',
    'Paris, France', 
    'Sydney, Australia',
    'Marie Dubois', 
    'Champs-Élysées, Paris', 
    'marie.dubois@fashion.fr', 
    '+33-1-42-96-12-34',
    'Emma Wilson', 
    '789 George Street, Sydney, Australia', 
    'emma.wilson@email.com', 
    '+61-2-9876-5432',
    'Pending', 
    'TNT', 
    'Air Freight', 
    'Standard', 
    5.2, 
    3,
    'TNT555666777', 
    'Designer Dresses', 
    5, 
    599.99,
    '2025-01-20', 
    '11:45:00', 
    '2025-01-03', 
    '12:00:00',
    5.2, 
    6.1, 
    0.045, 
    5.2,
    'Fashion items - avoid folding. Temperature controlled environment preferred.',
    '2025-01-03 12:00:00', 
    '2025-01-03 12:00:00'
);

-- Insert sample packages for each shipment
INSERT INTO packages (shipment_id, quantity, piece_type, description) VALUES
('ABC123XYZ456789', 1, 'Box', 'MacBook Pro 16-inch in original packaging'),
('ABC123XYZ456789', 1, 'Box', 'Laptop accessories and charger'),

('DEF456UVW789012', 1, 'Loose', 'Sealed envelope with legal documents'),

('GHI789RST012345', 2, 'Box', 'Evening dresses - size M'),
('GHI789RST012345', 1, 'Box', 'Casual wear collection'),
('GHI789RST012345', 2, 'Box', 'Accessories and shoes');

-- Insert sample shipment history
INSERT INTO shipment_history (shipment_id, date, time, location, status, updated_by, remarks) VALUES
-- History for ABC123XYZ456789
('ABC123XYZ456789', '2025-01-01', '10:00:00', 'New York Warehouse', 'Pending', 'System', 'Shipment created and awaiting pickup'),
('ABC123XYZ456789', '2025-01-01', '15:30:00', 'FedEx Facility NYC', 'In Transit', 'John Doe', 'Package picked up and processed'),
('ABC123XYZ456789', '2025-01-02', '08:15:00', 'JFK Airport', 'In Transit', 'Airport Handler', 'Loaded onto flight FX1234'),
('ABC123XYZ456789', '2025-01-02', '14:30:00', 'Heathrow Airport', 'In Transit', 'UK Customs', 'Cleared customs, proceeding to local facility'),

-- History for DEF456UVW789012
('DEF456UVW789012', '2024-12-28', '08:00:00', 'Los Angeles Office', 'Pending', 'System', 'Document package prepared'),
('DEF456UVW789012', '2024-12-28', '12:30:00', 'DHL Hub LA', 'In Transit', 'DHL Agent', 'Express shipment processed'),
('DEF456UVW789012', '2024-12-30', '18:45:00', 'Tokyo Distribution Center', 'In Transit', 'Local Agent', 'Arrived in Tokyo, out for delivery'),
('DEF456UVW789012', '2025-01-01', '16:45:00', 'Tokyo Office Building', 'Delivered', 'Delivery Driver', 'Successfully delivered to recipient'),

-- History for GHI789RST012345
('GHI789RST012345', '2025-01-03', '12:00:00', 'Paris Fashion District', 'Pending', 'System', 'Fashion items packaged and labeled');

-- Insert QR code data for shipments
INSERT INTO qr_codes (shipment_id, qr_code_data) VALUES
('ABC123XYZ456789', 'https://tnt-tracking.com/track?id=ABC123XYZ456789'),
('DEF456UVW789012', 'https://tnt-tracking.com/track?id=DEF456UVW789012'),
('GHI789RST012345', 'https://tnt-tracking.com/track?id=GHI789RST012345');

-- Create indexes for better performance
CREATE INDEX idx_shipments_status ON shipments(status);
CREATE INDEX idx_shipments_created_at ON shipments(created_at);
CREATE INDEX idx_shipments_updated_at ON shipments(updated_at);
CREATE INDEX idx_shipments_sender_email ON shipments(sender_email);
CREATE INDEX idx_shipments_receiver_email ON shipments(receiver_email);
CREATE INDEX idx_shipments_carrier ON shipments(carrier);
CREATE INDEX idx_shipments_expected_delivery ON shipments(expected_delivery_date);

CREATE INDEX idx_packages_shipment_id ON packages(shipment_id);
CREATE INDEX idx_history_shipment_id ON shipment_history(shipment_id);
CREATE INDEX idx_history_date ON shipment_history(date);
CREATE INDEX idx_history_status ON shipment_history(status);

CREATE INDEX idx_qr_codes_shipment_id ON qr_codes(shipment_id);

-- Create views for easier data retrieval
CREATE VIEW shipment_summary AS
SELECT 
    s.id,
    s.description,
    s.origin,
    s.destination,
    s.status,
    s.carrier,
    s.expected_delivery_date,
    s.sender_name,
    s.receiver_name,
    COUNT(p.id) as package_count,
    s.total_weight,
    s.total_freight,
    s.created_at,
    s.updated_at
FROM shipments s
LEFT JOIN packages p ON s.id = p.shipment_id
GROUP BY s.id;

CREATE VIEW latest_shipment_status AS
SELECT 
    sh.shipment_id,
    sh.date as last_update_date,
    sh.time as last_update_time,
    sh.location as current_location,
    sh.status as current_status,
    sh.updated_by,
    sh.remarks
FROM shipment_history sh
INNER JOIN (
    SELECT shipment_id, MAX(CONCAT(date, ' ', time)) as latest_update
    FROM shipment_history
    GROUP BY shipment_id
) latest ON sh.shipment_id = latest.shipment_id 
AND CONCAT(sh.date, ' ', sh.time) = latest.latest_update;

-- Create stored procedures for common operations

-- Procedure to get complete shipment details
DELIMITER //
CREATE PROCEDURE GetShipmentDetails(IN tracking_id VARCHAR(15))
BEGIN
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
END //

-- Procedure to update shipment status and add history entry
CREATE PROCEDURE UpdateShipmentStatus(
    IN tracking_id VARCHAR(15),
    IN new_status ENUM('Pending', 'In Transit', 'On Hold', 'Delivered'),
    IN location VARCHAR(255),
    IN updated_by VARCHAR(100),
    IN remarks TEXT
)
BEGIN
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
END //

-- Procedure to create a new shipment with packages
CREATE PROCEDURE CreateShipment(
    IN p_id VARCHAR(15),
    IN p_description TEXT,
    IN p_origin VARCHAR(255),
    IN p_destination VARCHAR(255),
    IN p_sender_name VARCHAR(255),
    IN p_sender_location VARCHAR(255),
    IN p_sender_email VARCHAR(255),
    IN p_sender_phone VARCHAR(50),
    IN p_receiver_name VARCHAR(255),
    IN p_receiver_address TEXT,
    IN p_receiver_email VARCHAR(255),
    IN p_receiver_phone VARCHAR(50),
    IN p_carrier ENUM('FedEx', 'DHL', 'USPS', 'UPS', 'TNT'),
    IN p_shipment_type ENUM('Air Freight', 'Sea Freight', 'Road Freight', 'Rail Freight'),
    IN p_weight DECIMAL(10, 2),
    IN p_created_by INT
)
BEGIN
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
END //

DELIMITER ;

-- Create triggers for automatic updates

-- Trigger to update shipment timestamp when packages are modified
DELIMITER //
CREATE TRIGGER update_shipment_on_package_change
AFTER INSERT ON packages
FOR EACH ROW
BEGIN
    UPDATE shipments 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.shipment_id;
END //

CREATE TRIGGER update_shipment_on_package_update
AFTER UPDATE ON packages
FOR EACH ROW
BEGIN
    UPDATE shipments 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.shipment_id;
END //

CREATE TRIGGER update_shipment_on_package_delete
AFTER DELETE ON packages
FOR EACH ROW
BEGIN
    UPDATE shipments 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = OLD.shipment_id;
END //

DELIMITER ;

-- Grant appropriate permissions (adjust as needed for your setup)
-- CREATE USER 'tnt_app'@'localhost' IDENTIFIED BY 'secure_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON tnt_tracking.* TO 'tnt_app'@'localhost';
-- FLUSH PRIVILEGES;