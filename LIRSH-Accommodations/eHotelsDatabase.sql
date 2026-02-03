DROP DATABASE IF EXISTS ehotels;
CREATE DATABASE ehotels;
USE ehotels;

DROP TABLE IF EXISTS HotelChain;
CREATE TABLE HotelChain (
    chain_name VARCHAR(255) PRIMARY KEY,
    number_of_hotels INT,
    address VARCHAR(255),
    phone VARCHAR(255),
    email VARCHAR(255)
);

DROP TABLE IF EXISTS Hotel;
CREATE TABLE Hotel (
    hotel_name VARCHAR(255) PRIMARY KEY,
    location VARCHAR(255),
    number_of_rooms INT,
    number_of_stars INT,
    address VARCHAR(255),
    phone VARCHAR(255),
    email VARCHAR(255),
    chain_name VARCHAR(255),
    FOREIGN KEY (chain_name) REFERENCES HotelChain(chain_name)
);

DROP TABLE IF EXISTS Room; 
CREATE TABLE Room (
    room_number INT,
    capacity INT,
    view_type VARCHAR(255),
    price DECIMAL(10, 2),
    extendable BOOLEAN,
    hotel_name VARCHAR(255),
    room_status VARCHAR(255) DEFAULT 'available',
    INDEX hotel_name_index (hotel_name),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name)
);

DROP TABLE IF EXISTS Amenity;
CREATE TABLE Amenity (
	amenity_id INT AUTO_INCREMENT PRIMARY KEY,
    amenity_name VARCHAR(255)
);

DROP TABLE IF EXISTS Problem;
CREATE TABLE Problem (
	problem_id INT AUTO_INCREMENT PRIMARY KEY,
    problem_description VARCHAR(255)
); 

DROP TABLE IF EXISTS Employee;
CREATE TABLE Employee (
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    address VARCHAR(255),
    SIN VARCHAR(255) PRIMARY KEY,
    hotel_name VARCHAR(255),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name)
);

DROP TABLE IF EXISTS Manager;
CREATE TABLE Manager (
	first_name VARCHAR(255),
    last_name VARCHAR(255),
    address VARCHAR(255),
    SIN VARCHAR(255) PRIMARY KEY,
    hotel_name VARCHAR(255),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name),
    FOREIGN KEY (SIN) REFERENCES Employee(SIN)
);

DROP TABLE IF EXISTS Booking;
CREATE TABLE Booking (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(255),
    start_date DATE,
    end_date DATE,
    room_number INT,
    hotel_name VARCHAR(255),
    INDEX employee_id_index (employee_id),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name),
    FOREIGN KEY (employee_id) REFERENCES Employee(SIN)
);

DROP TABLE IF EXISTS EmployeeBooking;
CREATE TABLE EmployeeBooking (
	booking_id INT,
    employee_id VARCHAR(255),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(SIN)
);

DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer (
	booking_id INT DEFAULT NULL,
    customer_id VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    address VARCHAR(255),
    start_date DATE,
    end_date DATE,
    paid_in_advance BOOLEAN,
    payment_method VARCHAR(255),
    room_number INT,
    hotel_name VARCHAR(255),
    booked_through_employee BOOLEAN,
    INDEX hotel_name_index (hotel_name),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id)
);

DROP TABLE IF EXISTS Archive;
CREATE TABLE Archive (
    booking_id INT,
    employee_id VARCHAR(255),
    start_date DATE,
    end_date DATE,
    room_number INT,
    hotel_name VARCHAR(255),
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(SIN),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name)
);

DROP TABLE IF EXISTS HotelAmenity;
CREATE TABLE HotelAmenity (
    amenity_id INT,
    hotel_name VARCHAR(255),
    FOREIGN KEY (amenity_id) REFERENCES Amenity(amenity_id),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name)
);

DROP TABLE IF EXISTS RoomProblem;
CREATE TABLE RoomProblem (
    room_number INT,
    problem_id INT,
    hotel_name VARCHAR(255),
    FOREIGN KEY (problem_id) REFERENCES Problem(problem_id),
    FOREIGN KEY (hotel_name) REFERENCES Hotel(hotel_name)
);
  
DELIMITER $$

DROP TRIGGER IF EXISTS BookingRoom;
CREATE TRIGGER BookingRoom
AFTER INSERT ON Customer
FOR EACH ROW
BEGIN
	INSERT IGNORE INTO Booking (employee_id, start_date, end_date, room_number, hotel_name) VALUES
		(NULL, NEW.start_date, NEW.end_date, NEW.room_number, NEW.hotel_name);
        
	SET @previous_id = LAST_INSERT_ID ();
        
	IF NEW.booked_through_employee = TRUE THEN
		SET @manager = (SELECT SIN FROM Manager WHERE hotel_name = NEW.hotel_name);
		INSERT IGNORE INTO EmployeeBooking (booking_id, employee_id) VALUES
			(NEW.booking_id, @manager);
            
		SET @employee = (SELECT employee_id FROM EmployeeBooking WHERE booking_id = @previous_id);
        UPDATE Booking
		SET employee_id = @employee
		WHERE booking_id = @previous_id;
	END IF;
    
    UPDATE Customer
    SET booking_id = @previous_id
    WHERE room_number = NEW.room_number AND hotel_name = NEW.hotel_name;
    
    CALL UpdateRoomStatus ();
END $$

DROP TRIGGER IF EXISTS MoveToArchive;
CREATE TRIGGER MoveToArchive
AFTER DELETE ON Customer
FOR EACH ROW
BEGIN
	SET @employee = (SELECT employee_id FROM Booking WHERE booking_id = OLD.booking_id);

	INSERT IGNORE INTO Archive (booking_id, employee_id, start_date, end_date, room_number, hotel_name) VALUES 
		(OLD.booking_id, @employee, OLD.start_date, OLD.end_date, OLD.room_number, OLD.hotel_name);
        
	DELETE FROM Booking WHERE booking_id = OLD.booking_id;
    
    IF @employee IS NOT NULL THEN
		DELETE FROM EmployeeBooking WHERE booking_id = OLD.booking_id;
	END IF;
    
    UPDATE Room
    SET room_status = 'available'
    WHERE room_number = OLD.room_number AND hotel_name = OLD.hotel_name;
END $$

SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS UpdateRoomStatus;
CREATE EVENT UpdateRoomStatus
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
	SET @present = CURDATE ();
    
    UPDATE Room r
    JOIN Booking b ON r.room_number = b.room_number AND r.hotel_name = b.hotel_name
    SET r.room_status = 'unavailable'
    WHERE present BETWEEN b.start_date AND b.end_date;
END $$

DELIMITER ;

INSERT IGNORE INTO HotelChain (chain_name, number_of_hotels, address, phone, email) VALUES
	('Hyatt Hotels', 150, '123 Main Street, Chicago, IL, USA', '+1 (312) 555-1234', 'info@hyatthotels.com'),
    ('Regional Resorts', 75, '456 Resort Avenue, Orlando, FL, USA', '+1 (407) 555-9876', 'contact@regionalresorts.com'),
	('Serenity Spas', 100, '789 Zen Street, Los Angeles, CA, USA', '+1 (213) 555-7890', 'relax@serenityspas.com'),
	('Lakewood Lodges', 50, '101 Forest Road, Vancouver, BC, Canada', '+1 (604) 555-8765', 'info@lakewoodlodges.com'),
    ('Indigo Inns', 80, '246 Ocean View Drive, Miami, FL, USA', '+1 (305) 555-2345', 'stay@indigoinns.com');

INSERT IGNORE INTO Hotel (hotel_name, location, number_of_rooms, number_of_stars, address, phone, email, chain_name) VALUES 
	('Hyatt Tokyo', 'Tokyo', 5, 4, '1-23-5 Shinjuku, Tokyo, Japan', '+81 3 1234 5678', 'tokyo@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt Sydney', 'Sydney', 5, 5, '123 George St, Sydney NSW 2000, Australia', '+61 2 9876 5432', 'sydney@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt Paris', 'Paris', 5, 4, '3 Rue de la Paix, 75002 Paris, France', '+33 1 8765 4321', 'paris@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt New York', 'New York', 5, 5, '109 East 42nd Street at Grand Central Terminal, New York, USA', '+1 212 345 6789', 'newyork@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt London', 'London', 5, 4, '30 Portman Square, Marylebone, London W1H 7BH, UK', '+44 20 7654 3210', 'london@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt Dubai', 'Dubai', 5, 5, 'Sheikh Rashid Road, Dubai Healthcare City, Dubai, UAE', '+971 4 567 8901', 'dubai@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt Shanghai', 'Shanghai', 5, 4, '199 Huang Pu Rd, Hong Kou Qu, Shanghai, China', '+86 21 2345 6789', 'shanghai@hyatthotels.com', 'Hyatt Hotels'),
	('Hyatt Rome', 'Rome', 5, 4, 'Via Vittorio Veneto, 203, 00187 Roma RM, Italy', '+39 06 7890 1234', 'rome@hyatthotels.com', 'Hyatt Hotels'),
    
    ('Regional Tokyo', 'Tokyo', 5, 3, '2-15-3 Shibuya, Tokyo, Japan', '+81 3 9876 5432', 'tokyo@regionalresorts.com', 'Regional Resorts'),
	('Regional Sydney', 'Sydney', 5, 4, '456 Pitt St, Sydney NSW 2000, Australia', '+61 2 3456 7890', 'sydney@regionalresorts.com', 'Regional Resorts'),
	('Regional Paris', 'Paris', 5, 3, '8 Rue des Archives, 75004 Paris, France', '+33 1 2345 6789', 'paris@regionalresorts.com', 'Regional Resorts'),
	('Regional New York', 'New York', 5, 4, '20 West 34th Street, New York, USA', '+1 212 4567 8901', 'newyork@regionalresorts.com', 'Regional Resorts'),
	('Regional London', 'London', 5, 3, '45 Park Lane, Mayfair, London W1K 1PN, UK', '+44 20 1234 5678', 'london@regionalresorts.com', 'Regional Resorts'),
	('Regional Dubai', 'Dubai', 5, 4, 'Sheikh Zayed Rd - Trade CentreDowntown Dubai - Dubai - United Arab Emirates', '+971 4 6789 0123', 'dubai@regionalresorts.com', 'Regional Resorts'),
	('Regional Shanghai', 'Shanghai', 5, 3, '889 South Yanggao Road, Pudong, Shanghai, China', '+86 21 7890 1234', 'shanghai@regionalresorts.com', 'Regional Resorts'),
	('Regional Rome', 'Rome', 5, 3, 'Via Sistina, 67, 00187 Roma RM, Italy', '+39 06 3456 7890', 'rome@regionalresorts.com', 'Regional Resorts'),
    
    ('Serenity Tokyo', 'Tokyo', 5, 4, '4 Chome-2-8 Shibakoen, Minato City, Tokyo 105-0011, Japan', '+81 3 7654 3210', 'tokyo@serenityspas.com', 'Serenity Spas'),
	('Serenity Sydney', 'Sydney', 5, 5, '20 Bondi Rd, Bondi Beach NSW 2026, Australia', '+61 2 2345 6789', 'sydney@serenityspas.com', 'Serenity Spas'),
	('Serenity Paris', 'Paris', 5, 4, '10 Rue Saint-Jacques, 75005 Paris, France', '+33 1 6789 0123', 'paris@serenityspas.com', 'Serenity Spas'),
	('Serenity New York', 'New York', 5, 5, '1535 Broadway, New York, NY 10036, USA', '+1 212 5678 9012', 'newyork@serenityspas.com', 'Serenity Spas'),
	('Serenity London', 'London', 5, 4, '10 Godliman St, London EC4V 5AJ, UK', '+44 20 4567 8901', 'london@serenityspas.com', 'Serenity Spas'),
	('Serenity Dubai', 'Dubai', 5, 5, 'Al Jurf, Ajman, United Arab Emirates', '+971 4 2345 6789', 'dubai@serenityspas.com', 'Serenity Spas'),
	('Serenity Shanghai', 'Shanghai', 5, 4, '210 Century Ave, LuJiaZui, Pudong, Shanghai, China', '+86 21 7890 1234', 'shanghai@serenityspas.com', 'Serenity Spas'),
	('Serenity Rome', 'Rome', 5, 4, 'Via del Gianicolo, 3, 00165 Roma RM, Italy', '+39 06 1234 5678', 'rome@serenityspas.com', 'Serenity Spas'),
    
    ('Lakewood Tokyo', 'Tokyo', 5, 3, '2 Chome-4-1 Asakusa, Taito City, Tokyo 111-0032, Japan', '+81 3 9012 3456', 'tokyo@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood Sydney', 'Sydney', 5, 4, '78 Stanley St, Darlinghurst NSW 2010, Australia', '+61 2 8901 2345', 'sydney@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood Paris', 'Paris', 5, 3, '9 Rue de la Harpe, 75005 Paris, France', '+33 1 3456 7890', 'paris@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood New York', 'New York', 5, 4, '1535 Broadway, New York, NY 10036, USA', '+1 212 6789 0123', 'newyork@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood London', 'London', 5, 3, '61 South Audley St, Mayfair, London W1K 2QU, UK', '+44 20 7890 1234', 'london@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood Dubai', 'Dubai', 5, 4, 'Sheikh Zayed Rd - Trade CentreDowntown Dubai - Dubai - United Arab Emirates', '+971 4 5678 9012', 'dubai@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood Shanghai', 'Shanghai', 5, 3, '301 Nanjing Rd E, WaiTan, Huangpu Qu, Shanghai, China', '+86 21 9012 3456', 'shanghai@lakewoodlodges.com', 'Lakewood Lodges'),
	('Lakewood Rome', 'Rome', 5, 3, 'Via Giovanni Giolitti, 34, 00185 Roma RM, Italy', '+39 06 2345 6789', 'rome@lakewoodlodges.com', 'Lakewood Lodges'),
	
    ('Indigo Tokyo', 'Tokyo', 5, 3, '1 Chome-1-5 Kabukicho, Shinjuku City, Tokyo 160-0021, Japan', '+81 3 5678 9012', 'tokyo@indigoinns.com', 'Indigo Inns'),
	('Indigo Sydney', 'Sydney', 5, 4, '54 Darlinghurst Rd, Potts Point NSW 2011, Australia', '+61 2 3456 7890', 'sydney@indigoinns.com', 'Indigo Inns'),
	('Indigo Paris', 'Paris', 5, 3, '4 Rue des Petits Champs, 75002 Paris, France', '+33 1 6789 0123', 'paris@indigoinns.com', 'Indigo Inns'),
	('Indigo New York', 'New York', 5, 4, '234 West 42nd Street, New York, NY 10036, USA', '+1 212 4567 8901', 'newyork@indigoinns.com', 'Indigo Inns'),
	('Indigo London', 'London', 5, 3, '16-22 Great Russell St, Bloomsbury, London WC1B 3NN, UK', '+44 20 7890 1234', 'london@indigoinns.com', 'Indigo Inns'),
	('Indigo Dubai', 'Dubai', 5, 4, 'Downtown Dubai, Dubai, United Arab Emirates', '+971 4 9012 3456', 'dubai@indigoinns.com', 'Indigo Inns'),
	('Indigo Shanghai', 'Shanghai', 5, 3, '425 Yanan Middle Rd, Huangpu Qu, Shanghai Shi, China', '+86 21 6789 0123', 'shanghai@indigoinns.com', 'Indigo Inns'),
	('Indigo Rome', 'Rome', 5, 3, 'Via del Tritone, 87, 00187 Roma RM, Italy', '+39 06 3456 7890', 'rome@indigoinns.com', 'Indigo Inns');

INSERT IGNORE INTO Room (room_number, capacity, view_type, price, extendable, hotel_name) VALUES
    (1, 1, 'Sea', 100, true, 'Hyatt Tokyo'),
    (2, 2, 'Sea', 120, true, 'Hyatt Tokyo'),
    (3, 3, 'Mountain', 140, false, 'Hyatt Tokyo'),
    (4, 4, 'Mountain', 160, false, 'Hyatt Tokyo'),
    (5, 5, 'Mountain', 180, false, 'Hyatt Tokyo'),
    
    (1, 1, 'Sea', 200, true, 'Hyatt Sydney'),
    (2, 2, 'Sea', 220, true, 'Hyatt Sydney'),
    (3, 3, 'Mountain', 240, false, 'Hyatt Sydney'),
    (4, 4, 'Mountain', 260, false, 'Hyatt Sydney'),
    (5, 5, 'Mountain', 280, false, 'Hyatt Sydney'),

    (1, 1, 'Sea', 100, true, 'Hyatt Paris'),
    (2, 2, 'Sea', 120, true, 'Hyatt Paris'),
    (3, 3, 'Mountain', 140, false, 'Hyatt Paris'),
    (4, 4, 'Mountain', 160, false, 'Hyatt Paris'),
    (5, 5, 'Mountain', 180, false, 'Hyatt Paris'),
    
	(1, 1, 'Sea', 200, true, 'Hyatt New York'),
    (2, 2, 'Sea', 220, true, 'Hyatt New York'),
    (3, 3, 'Mountain', 240, false, 'Hyatt New York'),
    (4, 4, 'Mountain', 260, false, 'Hyatt New York'),
    (5, 5, 'Mountain', 280, false, 'Hyatt New York'),
    
	(1, 1, 'Sea', 100, true, 'Hyatt London'),
    (2, 2, 'Sea', 120, true, 'Hyatt London'),
    (3, 3, 'Mountain', 140, false, 'Hyatt London'),
    (4, 4, 'Mountain', 160, false, 'Hyatt London'),
    (5, 5, 'Mountain', 180, false, 'Hyatt London'),
    
	(1, 1, 'Sea', 200, true, 'Hyatt Dubai'),
    (2, 2, 'Sea', 220, true, 'Hyatt Dubai'),
    (3, 3, 'Mountain', 240, false, 'Hyatt Dubai'),
    (4, 4, 'Mountain', 260, false, 'Hyatt Dubai'),
    (5, 5, 'Mountain', 280, false, 'Hyatt Dubai'),    
    
	(1, 1, 'Sea', 100, true, 'Hyatt Shanghai'),
    (2, 2, 'Sea', 120, true, 'Hyatt Shanghai'),
    (3, 3, 'Mountain', 140, false, 'Hyatt Shanghai'),
    (4, 4, 'Mountain', 160, false, 'Hyatt Shanghai'),
    (5, 5, 'Mountain', 180, false, 'Hyatt Shanghai'),
    
	(1, 1, 'Sea', 100, true, 'Hyatt Rome'),
    (2, 2, 'Sea', 120, true, 'Hyatt Rome'),
    (3, 3, 'Mountain', 140, false, 'Hyatt Rome'),
    (4, 4, 'Mountain', 160, false, 'Hyatt Rome'),
    (5, 5, 'Mountain', 180, false, 'Hyatt Rome'),
    
    (1, 1, 'Sea', 50, true, 'Regional Tokyo'),
    (2, 2, 'Sea', 70, true, 'Regional Tokyo'),
    (3, 3, 'Mountain', 90, false, 'Regional Tokyo'),
    (4, 4, 'Mountain', 110, false, 'Regional Tokyo'),
    (5, 5, 'Mountain', 120, false, 'Regional Tokyo'),
    
    (1, 1, 'Sea', 100, true, 'Regional Sydney'),
    (2, 2, 'Sea', 120, true, 'Regional Sydney'),
    (3, 3, 'Mountain', 140, false, 'Regional Sydney'),
    (4, 4, 'Mountain', 160, false, 'Regional Sydney'),
    (5, 5, 'Mountain', 180, false, 'Regional Sydney'),
    
    (1, 1, 'Sea', 50, true, 'Regional Paris'),
    (2, 2, 'Sea', 70, true, 'Regional Paris'),
    (3, 3, 'Mountain', 90, false, 'Regional Paris'),
    (4, 4, 'Mountain', 110, false, 'Regional Paris'),
    (5, 5, 'Mountain', 120, false, 'Regional Paris'),
    
    (1, 1, 'Sea', 100, true, 'Regional New York'),
    (2, 2, 'Sea', 120, true, 'Regional New York'),
    (3, 3, 'Mountain', 140, false, 'Regional New York'),
    (4, 4, 'Mountain', 160, false, 'Regional New York'),
    (5, 5, 'Mountain', 180, false, 'Regional New York'),    
    
    (1, 1, 'Sea', 50, true, 'Regional London'),
    (2, 2, 'Sea', 70, true, 'Regional London'),
    (3, 3, 'Mountain', 90, false, 'Regional London'),
    (4, 4, 'Mountain', 110, false, 'Regional London'),
    (5, 5, 'Mountain', 120, false, 'Regional London'),
    
    (1, 1, 'Sea', 100, true, 'Regional Dubai'),
    (2, 2, 'Sea', 120, true, 'Regional Dubai'),
    (3, 3, 'Mountain', 140, false, 'Regional Dubai'),
    (4, 4, 'Mountain', 160, false, 'Regional Dubai'),
    (5, 5, 'Mountain', 180, false, 'Regional Dubai'),     
    
    (1, 1, 'Sea', 50, true, 'Regional Shanghai'),
    (2, 2, 'Sea', 70, true, 'Regional Shanghai'),
    (3, 3, 'Mountain', 90, false, 'Regional Shanghai'),
    (4, 4, 'Mountain', 110, false, 'Regional Shanghai'),
    (5, 5, 'Mountain', 120, false, 'Regional Shanghai'),
  
    (1, 1, 'Sea', 50, true, 'Regional Rome'),
    (2, 2, 'Sea', 70, true, 'Regional Rome'),
    (3, 3, 'Mountain', 90, false, 'Regional Rome'),
    (4, 4, 'Mountain', 110, false, 'Regional Rome'),
    (5, 5, 'Mountain', 120, false, 'Regional Rome'),
    
    (1, 1, 'Sea', 100, true, 'Serenity Tokyo'),
    (2, 2, 'Sea', 120, true, 'Serenity Tokyo'),
    (3, 3, 'Mountain', 140, false, 'Serenity Tokyo'),
    (4, 4, 'Mountain', 160, false, 'Serenity Tokyo'),
    (5, 5, 'Mountain', 180, false, 'Serenity Tokyo'),  
    
    (1, 1, 'Sea', 200, true, 'Serenity Sydney'),
    (2, 2, 'Sea', 220, true, 'Serenity Sydney'),
    (3, 3, 'Mountain', 240, false, 'Serenity Sydney'),
    (4, 4, 'Mountain', 260, false, 'Serenity Sydney'),
    (5, 5, 'Mountain', 280, false, 'Serenity Sydney'),      
    
    (1, 1, 'Sea', 100, true, 'Serenity Paris'),
    (2, 2, 'Sea', 120, true, 'Serenity Paris'),
    (3, 3, 'Mountain', 140, false, 'Serenity Paris'),
    (4, 4, 'Mountain', 160, false, 'Serenity Paris'),
    (5, 5, 'Mountain', 180, false, 'Serenity Paris'),      
    
    (1, 1, 'Sea', 200, true, 'Serenity New York'),
    (2, 2, 'Sea', 220, true, 'Serenity New York'),
    (3, 3, 'Mountain', 240, false, 'Serenity New York'),
    (4, 4, 'Mountain', 260, false, 'Serenity New York'),
    (5, 5, 'Mountain', 280, false, 'Serenity New York'),   
    
    (1, 1, 'Sea', 100, true, 'Serenity London'),
    (2, 2, 'Sea', 120, true, 'Serenity London'),
    (3, 3, 'Mountain', 140, false, 'Serenity London'),
    (4, 4, 'Mountain', 160, false, 'Serenity London'),
    (5, 5, 'Mountain', 180, false, 'Serenity London'),   
    
    (1, 1, 'Sea', 200, true, 'Serenity Dubai'),
    (2, 2, 'Sea', 220, true, 'Serenity Dubai'),
    (3, 3, 'Mountain', 240, false, 'Serenity Dubai'),
    (4, 4, 'Mountain', 260, false, 'Serenity Dubai'),
    (5, 5, 'Mountain', 280, false, 'Serenity Dubai'),   
    
    (1, 1, 'Sea', 100, true, 'Serenity Shanghai'),
    (2, 2, 'Sea', 120, true, 'Serenity Shanghai'),
    (3, 3, 'Mountain', 140, false, 'Serenity Shanghai'),
    (4, 4, 'Mountain', 160, false, 'Serenity Shanghai'),
    (5, 5, 'Mountain', 180, false, 'Serenity Shanghai'),       
    
    (1, 1, 'Sea', 100, true, 'Serenity Rome'),
    (2, 2, 'Sea', 120, true, 'Serenity Rome'),
    (3, 3, 'Mountain', 140, false, 'Serenity Rome'),
    (4, 4, 'Mountain', 160, false, 'Serenity Rome'),
    (5, 5, 'Mountain', 180, false, 'Serenity Rome'),
    
    (1, 1, 'Sea', 50, true, 'Lakewood Tokyo'),
    (2, 2, 'Sea', 70, true, 'Lakewood Tokyo'),
    (3, 3, 'Mountain', 90, false, 'Lakewood Tokyo'),
    (4, 4, 'Mountain', 110, false, 'Lakewood Tokyo'),
    (5, 5, 'Mountain', 120, false, 'Lakewood Tokyo'),

    (1, 1, 'Sea', 100, true, 'Lakewood Sydney'),
    (2, 2, 'Sea', 120, true, 'Lakewood Sydney'),
    (3, 3, 'Mountain', 140, false, 'Lakewood Sydney'),
    (4, 4, 'Mountain', 160, false, 'Lakewood Sydney'),
    (5, 5, 'Mountain', 180, false, 'Lakewood Sydney'),
  
    (1, 1, 'Sea', 50, true, 'Lakewood Paris'),
    (2, 2, 'Sea', 70, true, 'Lakewood Paris'),
    (3, 3, 'Mountain', 90, false, 'Lakewood Paris'),
    (4, 4, 'Mountain', 110, false, 'Lakewood Paris'),
    (5, 5, 'Mountain', 120, false, 'Lakewood Paris'),
    
    (1, 1, 'Sea', 100, true, 'Lakewood New York'),
    (2, 2, 'Sea', 120, true, 'Lakewood New York'),
    (3, 3, 'Mountain', 140, false, 'Lakewood New York'),
    (4, 4, 'Mountain', 160, false, 'Lakewood New York'),
    (5, 5, 'Mountain', 180, false, 'Lakewood New York'),
  
    (1, 1, 'Sea', 50, true, 'Lakewood London'),
    (2, 2, 'Sea', 70, true, 'Lakewood London'),
    (3, 3, 'Mountain', 90, false, 'Lakewood London'),
    (4, 4, 'Mountain', 110, false, 'Lakewood London'),
    (5, 5, 'Mountain', 120, false, 'Lakewood London'),
    
    (1, 1, 'Sea', 100, true, 'Lakewood Dubai'),
    (2, 2, 'Sea', 120, true, 'Lakewood Dubai'),
    (3, 3, 'Mountain', 140, false, 'Lakewood Dubai'),
    (4, 4, 'Mountain', 160, false, 'Lakewood Dubai'),
    (5, 5, 'Mountain', 180, false, 'Lakewood Dubai'),
      
    (1, 1, 'Sea', 50, true, 'Lakewood Shanghai'),
    (2, 2, 'Sea', 70, true, 'Lakewood Shanghai'),
    (3, 3, 'Mountain', 90, false, 'Lakewood Shanghai'),
    (4, 4, 'Mountain', 110, false, 'Lakewood Shanghai'),
    (5, 5, 'Mountain', 120, false, 'Lakewood Shanghai'),
    
	(1, 1, 'Sea', 50, true, 'Lakewood Rome'),
    (2, 2, 'Sea', 70, true, 'Lakewood Rome'),
    (3, 3, 'Mountain', 90, false, 'Lakewood Rome'),
    (4, 4, 'Mountain', 110, false, 'Lakewood Rome'),
    (5, 5, 'Mountain', 120, false, 'Lakewood Rome'),
    
	(1, 1, 'Sea', 50, true, 'Indigo Tokyo'),
    (2, 2, 'Sea', 70, true, 'Indigo Tokyo'),
    (3, 3, 'Mountain', 90, false, 'Indigo Tokyo'),
    (4, 4, 'Mountain', 110, false, 'Indigo Tokyo'),
    (5, 5, 'Mountain', 120, false, 'Indigo Tokyo'),

    (1, 1, 'Sea', 100, true, 'Indigo Sydney'),
    (2, 2, 'Sea', 120, true, 'Indigo Sydney'),
    (3, 3, 'Mountain', 140, false, 'Indigo Sydney'),
    (4, 4, 'Mountain', 160, false, 'Indigo Sydney'),
    (5, 5, 'Mountain', 180, false, 'Indigo Sydney'),
  
    (1, 1, 'Sea', 50, true, 'Indigo Paris'),
    (2, 2, 'Sea', 70, true, 'Indigo Paris'),
    (3, 3, 'Mountain', 90, false, 'Indigo Paris'),
    (4, 4, 'Mountain', 110, false, 'Indigo Paris'),
    (5, 5, 'Mountain', 120, false, 'Indigo Paris'),
    
    (1, 1, 'Sea', 100, true, 'Indigo New York'),
    (2, 2, 'Sea', 120, true, 'Indigo New York'),
    (3, 3, 'Mountain', 140, false, 'Indigo New York'),
    (4, 4, 'Mountain', 160, false, 'Indigo New York'),
    (5, 5, 'Mountain', 180, false, 'Indigo New York'),
  
    (1, 1, 'Sea', 50, true, 'Indigo London'),
    (2, 2, 'Sea', 70, true, 'Indigo London'),
    (3, 3, 'Mountain', 90, false, 'Indigo London'),
    (4, 4, 'Mountain', 110, false, 'Indigo London'),
    (5, 5, 'Mountain', 120, false, 'Indigo London'),
    
    (1, 1, 'Sea', 100, true, 'Indigo Dubai'),
    (2, 2, 'Sea', 120, true, 'Indigo Dubai'),
    (3, 3, 'Mountain', 140, false, 'Indigo Dubai'),
    (4, 4, 'Mountain', 160, false, 'Indigo Dubai'),
    (5, 5, 'Mountain', 180, false, 'Indigo Dubai'),
      
    (1, 1, 'Sea', 50, true, 'Indigo Shanghai'),
    (2, 2, 'Sea', 70, true, 'Indigo Shanghai'),
    (3, 3, 'Mountain', 90, false, 'Indigo Shanghai'),
    (4, 4, 'Mountain', 110, false, 'Indigo Shanghai'),
    (5, 5, 'Mountain', 120, false, 'Indigo Shanghai'),
    
	(1, 1, 'Sea', 50, true, 'Indigo Rome'),
    (2, 2, 'Sea', 70, true, 'Indigo Rome'),
    (3, 3, 'Mountain', 90, false, 'Indigo Rome'),
    (4, 4, 'Mountain', 110, false, 'Indigo Rome'),
    (5, 5, 'Mountain', 120, false, 'Indigo Rome');
    
INSERT IGNORE INTO Amenity (amenity_name) VALUES
	('Internet'),
    ('Gym'),
    ('Spa');
    
INSERT IGNORE INTO HotelAmenity (amenity_id, hotel_name) VALUES
    (1, 'Hyatt Tokyo'),
    (2, 'Hyatt Tokyo'),
    
    (1, 'Hyatt Sydney'),
    (2, 'Hyatt Sydney'),
    (3, 'Hyatt Sydney'),
    
    (1, 'Hyatt Paris'),
    (2, 'Hyatt Paris'),
    
    (1, 'Hyatt New York'),
    (2, 'Hyatt New York'),
    (3, 'Hyatt New York'),
    
    (1, 'Hyatt London'),
    (2, 'Hyatt London'),
    
    (1, 'Hyatt Dubai'),
    (2, 'Hyatt Dubai'),
    (3, 'Hyatt Dubai'),
    
    (1, 'Hyatt Shanghai'),
    (2, 'Hyatt Shanghai'),
    
    (1, 'Hyatt Rome'),
    (2, 'Hyatt Rome'),
    
    (1, 'Regional Tokyo'),
    
    (1, 'Regional Sydney'),
    (2, 'Regional Sydney'),
    
    (1, 'Regional Paris'),
    
    (1, 'Regional New York'),
    (2, 'Regional New York'),
    
    (1, 'Regional London'),
    
    (1, 'Regional Dubai'),
    (2, 'Regional Dubai'),
    
    (1, 'Regional Shanghai'),
    
    (1, 'Regional Rome'),
    
    (1, 'Serenity Tokyo'),
    (2, 'Serenity Tokyo'),
    
    (1, 'Serenity Sydney'),
    (2, 'Serenity Sydney'),
    (3, 'Serenity Sydney'),
    
    (1, 'Serenity Paris'),
    (2, 'Serenity Paris'),
    
    (1, 'Serenity New York'),
    (2, 'Serenity New York'),
    (3, 'Serenity New York'),
    
    (1, 'Serenity London'),
    (2, 'Serenity London'),
    
    (1, 'Serenity Dubai'),
    (2, 'Serenity Dubai'),
    (3, 'Serenity Dubai'),
    
    (1, 'Serenity Shanghai'),
    (2, 'Serenity Shanghai'),
    
    (1, 'Serenity Rome'),
    (2, 'Serenity Rome'),
    
    (1, 'Lakewood Tokyo'),
    
    (1, 'Lakewood Sydney'),
    (2, 'Lakewood Sydney'),
    
    (1, 'Lakewood Paris'),
    
    (1, 'Lakewood New York'),
    (2, 'Lakewood New York'),
    
    (1, 'Lakewood London'),
    
    (1, 'Lakewood Dubai'),
    (2, 'Lakewood Dubai'),
    
    (1, 'Lakewood Shanghai'),
    
    (1, 'Lakewood Rome'),
    
    (1, 'Indigo Tokyo'),
    
    (1, 'Indigo Sydney'),
    (2, 'Indigo Sydney'),
    
    (1, 'Indigo Paris'),
    
    (1, 'Indigo New York'),
    (2, 'Indigo New York'),
    
    (1, 'Indigo London'),
    
    (1, 'Indigo Dubai'),
    (2, 'Indigo Dubai'),
    
    (1, 'Indigo Shanghai'),
    
    (1, 'Indigo Rome');
    
INSERT IGNORE INTO Problem (problem_description) VALUES
	('Leaking shower'),
    ('Faulty air conditioning'),
    ('Broken TV');
    
INSERT IGNORE INTO RoomProblem (room_number, problem_id, hotel_name) VALUES
	(1, 1, 'Regional Tokyo'),
    (2, 2, 'Regional Paris'),
    (3, 3, 'Lakewood London'),
    (1, 1, 'Lakewood Shanghai'),
    (2, 2, 'Indigo Rome');
    
INSERT IGNORE INTO Employee (first_name, last_name, address, SIN, hotel_name) VALUES
    ('Emily', 'Smith', '123 Sakura Street, Tokyo, Japan', '023-456-789', 'Hyatt Tokyo'),
    ('Daniel', 'Johnson', '456 Fuji Avenue, Tokyo, Japan', '987-654-321', 'Hyatt Tokyo'),
    ('Sophia', 'Kim', '789 Cherry Blossom Lane, Tokyo, Japan', '356-789-012', 'Hyatt Tokyo'),
    
    ('John', 'Doe', '456 Oceanview Drive, Sydney, Australia', '234-567-890', 'Hyatt Sydney'),
    ('Jane', 'Doe', '789 Forest Road, Sydney, Australia', '890-123-456', 'Hyatt Sydney'),
    ('Michael', 'Brown', '321 Mountain Avenue, Sydney, Australia', '467-890-123', 'Hyatt Sydney'),
    
    ('Alice', 'Martin', '123 Eiffel Tower Road, Paris, France', '432-109-876', 'Hyatt Paris'),
    ('James', 'Wilson', '456 Louvre Street, Paris, France', '109-876-543', 'Hyatt Paris'),
    ('Emma', 'Lee', '789 Seine River Lane, Paris, France', '776-543-210', 'Hyatt Paris'),
    
    ('William', 'Taylor', '123 Broadway, New York, USA', '887-654-321', 'Hyatt New York'),
    ('Olivia', 'Anderson', '456 Fifth Avenue, New York, USA', '654-321-098', 'Hyatt New York'),
    ('Noah', 'Martinez', '789 Central Park West, New York, USA', '321-098-765', 'Hyatt New York'),
    
    ('Sophia', 'White', '123 Buckingham Palace Road, London, UK', '876-543-210', 'Hyatt London'),
    ('Liam', 'Jackson', '456 Tower Bridge Lane, London, UK', '543-210-987', 'Hyatt London'),
    ('Ava', 'Harris', '789 Abbey Road, London, UK', '210-987-654', 'Hyatt London'),
    
    ('Mia', 'Thompson', '123 Burj Khalifa Street, Dubai, UAE', '678-945-321', 'Hyatt Dubai'),
    ('Ethan', 'Garcia', '456 Palm Jumeirah Avenue, Dubai, UAE', '945-321-678', 'Hyatt Dubai'),
    ('Isabella', 'Rodriguez', '789 Sheikh Zayed Road, Dubai, UAE', '321-678-945', 'Hyatt Dubai'),
    
    ('Charlotte', 'Lopez', '123 Oriental Pearl Tower Road, Shanghai, China', '567-890-123', 'Hyatt Shanghai'),
    ('Alexander', 'Perez', '456 The Bund Lane, Shanghai, China', '790-123-456', 'Hyatt Shanghai'),
    ('Amelia', 'Gonzalez', '789 Yu Garden Lane, Shanghai, China', '123-456-789', 'Hyatt Shanghai'),
    
    ('Benjamin', 'Hernandez', '123 Colosseum Street, Rome, Italy', '456-789-012', 'Hyatt Rome'),
    ('Harper', 'Sullivan', '456 Vatican Avenue, Rome, Italy', '789-012-345', 'Hyatt Rome'),
    ('Evelyn', 'Fisher', '789 Trevi Fountain Lane, Rome, Italy', '012-345-678', 'Hyatt Rome'),
    
    ('Liam', 'Clark', '123 Mount Fuji Street, Tokyo, Japan', '111-222-333', 'Regional Tokyo'),
    ('Olivia', 'Lewis', '456 Shibuya Crossing Lane, Tokyo, Japan', '222-333-444', 'Regional Tokyo'),
    ('William', 'Walker', '789 Sumida River Road, Tokyo, Japan', '333-444-555', 'Regional Tokyo'),
    
    ('Emma', 'Brown', '123 Circular Quay, Sydney, Australia', '555-666-777', 'Regional Sydney'),
    ('Alexander', 'Taylor', '456 Bondi Beach Road, Sydney, Australia', '666-777-888', 'Regional Sydney'),
    ('Madison', 'Miller', '789 Darling Harbour Lane, Sydney, Australia', '777-888-999', 'Regional Sydney'),
    
    ('Sophia', 'Wilson', '123 Champs-Élysées Avenue, Paris, France', '888-999-000', 'Regional Paris'),
    ('Liam', 'Garcia', '456 Montmartre Street, Paris, France', '999-000-111', 'Regional Paris'),
    ('Olivia', 'Hernandez', '789 Seine River Lane, Paris, France', '000-111-222', 'Regional Paris'),

    ('William', 'Anderson', '123 Times Square, New York, USA', '111-222-331', 'Regional New York'),
    ('Ava', 'Martinez', '456 Statue of Liberty Avenue, New York, USA', '222-333-442', 'Regional New York'),
    ('Noah', 'Gonzalez', '789 Central Park West, New York, USA', '333-444-553', 'Regional New York'),
    
    ('Oliver', 'Perez', '123 Westminster Abbey Road, London, UK', '444-555-664', 'Regional London'),
    ('Sophia', 'Gonzalez', '456 Trafalgar Square, London, UK', '555-666-775', 'Regional London'),
    ('James', 'Rodriguez', '789 Abbey Road, London, UK', '666-777-886', 'Regional London'),
    
    ('Elijah', 'Hernandez', '123 Burj Khalifa Street, Dubai, UAE', '777-888-997', 'Regional Dubai'),
    ('Charlotte', 'Thompson', '456 Palm Jumeirah Avenue, Dubai, UAE', '888-999-008', 'Regional Dubai'),
    ('Mia', 'Lopez', '789 Sheikh Zayed Road, Dubai, UAE', '999-000-119', 'Regional Dubai'),
    
    ('Michael', 'Wilson', '123 Nanjing Road, Shanghai, China', '000-111-210', 'Regional Shanghai'),
    ('Harper', 'Harris', '456 The Bund Lane, Shanghai, China', '111-222-311', 'Regional Shanghai'),
    ('Ethan', 'Clark', '789 Yu Garden Lane, Shanghai, China', '222-333-412', 'Regional Shanghai'),
    
    ('Avery', 'Lewis', '123 Colosseum Street, Rome, Italy', '333-444-513', 'Regional Rome'),
    ('Emily', 'Young', '456 Vatican Avenue, Rome, Italy', '444-555-614', 'Regional Rome'),
    ('Matthew', 'Hall', '789 Trevi Fountain Lane, Rome, Italy', '555-666-715', 'Regional Rome'),
    
    ('Isabella', 'Thompson', '123 Asakusa Street, Tokyo, Japan', '666-777-816', 'Serenity Tokyo'),
    ('Liam', 'Harris', '456 Roppongi Lane, Tokyo, Japan', '777-888-917', 'Serenity Tokyo'),
    ('Olivia', 'Jackson', '789 Akihabara Road, Tokyo, Japan', '888-999-018', 'Serenity Tokyo'),
    
    ('Aiden', 'Roberts', '123 Bondi Beach Road, Sydney, Australia', '111-222-319', 'Serenity Sydney'),
    ('Ella', 'Gray', '456 Circular Quay, Sydney, Australia', '222-333-420', 'Serenity Sydney'),
    ('Logan', 'Bailey', '789 Darling Harbour Lane, Sydney, Australia', '333-444-521', 'Serenity Sydney'),
    
    ('Mason', 'Adams', '123 Champs-Élysées Avenue, Paris, France', '444-555-622', 'Serenity Paris'),
    ('Scarlett', 'Evans', '456 Montmartre Street, Paris, France', '555-666-723', 'Serenity Paris'),
    ('Lucas', 'Gordon', '789 Seine River Lane, Paris, France', '666-777-824', 'Serenity Paris'),
    
    ('Evelyn', 'Foster', '123 Times Square, New York, USA', '777-888-925', 'Serenity New York'),
    ('Jack', 'Butler', '456 Statue of Liberty Avenue, New York, USA', '888-999-026', 'Serenity New York'),
    ('Grace', 'Murphy', '789 Central Park West, New York, USA', '999-000-127', 'Serenity New York'),
    
    ('Landon', 'Perry', '123 Westminster Abbey Road, London, UK', '000-111-228', 'Serenity London'),
    ('Brooklyn', 'Cox', '456 Trafalgar Square, London, UK', '111-222-329', 'Serenity London'),
    ('Nora', 'Hayes', '789 Abbey Road, London, UK', '222-333-430', 'Serenity London'),
    
    ('Grayson', 'Russell', '123 Burj Khalifa Street, Dubai, UAE', '333-444-531', 'Serenity Dubai'),
    ('Zoey', 'Simmons', '456 Palm Jumeirah Avenue, Dubai, UAE', '444-555-632', 'Serenity Dubai'),
    ('Hudson', 'Ortiz', '789 Sheikh Zayed Road, Dubai, UAE', '555-666-733', 'Serenity Dubai'),
    
    ('Eleanor', 'Ferguson', '123 Nanjing Road, Shanghai, China', '666-777-834', 'Serenity Shanghai'),
    ('Nathan', 'Burns', '456 The Bund Lane, Shanghai, China', '777-888-935', 'Serenity Shanghai'),
    ('Eliana', 'Barnes', '789 Yu Garden Lane, Shanghai, China', '888-999-036', 'Serenity Shanghai'),
    
    ('Levi', 'Bryant', '123 Colosseum Street, Rome, Italy', '999-000-137', 'Serenity Rome'),
    ('Hannah', 'Dunn', '456 Vatican Avenue, Rome, Italy', '000-111-238', 'Serenity Rome'),
    ('David', 'Parker', '789 Trevi Fountain Lane, Rome, Italy', '111-222-339', 'Serenity Rome'),
    
    ('Elijah', 'Young', '123 Shibuya Crossing Lane, Tokyo, Japan', '222-333-440', 'Lakewood Tokyo'),
    ('Charlotte', 'Hernandez', '456 Asakusa Street, Tokyo, Japan', '333-444-541', 'Lakewood Tokyo'),
    ('Mia', 'Lopez', '789 Roppongi Lane, Tokyo, Japan', '444-555-642', 'Lakewood Tokyo'),
    
    ('Ethan', 'Taylor', '123 Bondi Beach Road, Sydney, Australia', '555-666-743', 'Lakewood Sydney'),
    ('Amelia', 'Harris', '456 Circular Quay, Sydney, Australia', '666-777-844', 'Lakewood Sydney'),
    ('Oliver', 'King', '789 Darling Harbour Lane, Sydney, Australia', '777-888-945', 'Lakewood Sydney'),
    
    ('Ava', 'Morris', '123 Champs-Élysées Avenue, Paris, France', '888-999-046', 'Lakewood Paris'),
    ('Noah', 'Baker', '456 Montmartre Street, Paris, France', '999-000-147', 'Lakewood Paris'),
    ('Isabella', 'Fisher', '789 Seine River Lane, Paris, France', '000-111-248', 'Lakewood Paris'),
    
    ('Emma', 'Martinez', '123 Times Square, New York, USA', '111-222-349', 'Lakewood New York'),
    ('Liam', 'Gonzalez', '456 Statue of Liberty Avenue, New York, USA', '222-333-450', 'Lakewood New York'),
    ('Olivia', 'Roberts', '789 Central Park West, New York, USA', '333-444-551', 'Lakewood New York'),

    ('William', 'Stewart', '123 Westminster Abbey Road, London, UK', '444-555-652', 'Lakewood London'),
    ('Sophia', 'Mitchell', '456 Trafalgar Square, London, UK', '555-666-753', 'Lakewood London'),
    ('James', 'Perez', '789 Abbey Road, London, UK', '666-777-854', 'Lakewood London'),
    
    ('Oliver', 'Morris', '123 Burj Khalifa Street, Dubai, UAE', '777-888-955', 'Lakewood Dubai'),
    ('Harper', 'Ward', '456 Palm Jumeirah Avenue, Dubai, UAE', '888-999-056', 'Lakewood Dubai'),
    ('Evelyn', 'Watson', '789 Sheikh Zayed Road, Dubai, UAE', '999-000-157', 'Lakewood Dubai'),
    
    ('Logan', 'Brooks', '123 Nanjing Road, Shanghai, China', '000-111-258', 'Lakewood Shanghai'),
    ('Avery', 'Sanders', '456 The Bund Lane, Shanghai, China', '111-222-359', 'Lakewood Shanghai'),
    ('Ella', 'Price', '789 Yu Garden Lane, Shanghai, China', '222-333-460', 'Lakewood Shanghai'),
    
    ('Mason', 'Wood', '123 Colosseum Street, Rome, Italy', '333-444-561', 'Lakewood Rome'),
    ('Layla', 'Ward', '456 Vatican Avenue, Rome, Italy', '444-555-662', 'Lakewood Rome'),
    ('Jackson', 'Foster', '789 Trevi Fountain Lane, Rome, Italy', '555-666-763', 'Lakewood Rome'),
    
	('Aiden', 'Morris', '123 Shibuya Crossing Lane, Tokyo, Japan', '111-222-364', 'Indigo Tokyo'),
    ('Ella', 'Hernandez', '456 Asakusa Street, Tokyo, Japan', '222-333-465', 'Indigo Tokyo'),
    ('Logan', 'Lopez', '789 Roppongi Lane, Tokyo, Japan', '333-444-566', 'Indigo Tokyo'),
    
    ('Mason', 'Taylor', '123 Bondi Beach Road, Sydney, Australia', '444-555-667', 'Indigo Sydney'),
    ('Scarlett', 'Harris', '456 Circular Quay, Sydney, Australia', '555-666-768', 'Indigo Sydney'),
    ('Lucas', 'King', '789 Darling Harbour Lane, Sydney, Australia', '666-777-869', 'Indigo Sydney'),
    
    ('Evelyn', 'Morris', '123 Champs-Élysées Avenue, Paris, France', '777-888-970', 'Indigo Paris'),
    ('Jack', 'Baker', '456 Montmartre Street, Paris, France', '888-999-071', 'Indigo Paris'),
    ('Grace', 'Fisher', '789 Seine River Lane, Paris, France', '999-000-172', 'Indigo Paris'),
    
    ('William', 'Martinez', '123 Times Square, New York, USA', '000-111-273', 'Indigo New York'),
    ('Sophia', 'Gonzalez', '456 Statue of Liberty Avenue, New York, USA', '111-222-374', 'Indigo New York'),
    ('James', 'Roberts', '789 Central Park West, New York, USA', '222-333-475', 'Indigo New York'),
    
    ('Oliver', 'Stewart', '123 Westminster Abbey Road, London, UK', '333-444-576', 'Indigo London'),
    ('Amelia', 'Mitchell', '456 Trafalgar Square, London, UK', '444-555-677', 'Indigo London'),
    ('Benjamin', 'Perez', '789 Abbey Road, London, UK', '555-666-778', 'Indigo London'),
    
    ('Ethan', 'Morris', '123 Burj Khalifa Street, Dubai, UAE', '666-777-879', 'Indigo Dubai'),
    ('Isabella', 'Ward', '456 Palm Jumeirah Avenue, Dubai, UAE', '777-888-980', 'Indigo Dubai'),
    ('Olivia', 'Watson', '789 Sheikh Zayed Road, Dubai, UAE', '888-999-081', 'Indigo Dubai'),
    
    ('Liam', 'Brooks', '123 Nanjing Road, Shanghai, China', '999-000-182', 'Indigo Shanghai'),
    ('Ava', 'Sanders', '456 The Bund Lane, Shanghai, China', '000-111-283', 'Indigo Shanghai'),
    ('Harper', 'Price', '789 Yu Garden Lane, Shanghai, China', '111-222-384', 'Indigo Shanghai'),
    
    ('Noah', 'Wood', '123 Colosseum Street, Rome, Italy', '222-333-485', 'Indigo Rome'),
    ('Mia', 'Ward', '456 Vatican Avenue, Rome, Italy', '333-444-586', 'Indigo Rome'),
    ('Elijah', 'Foster', '789 Trevi Fountain Lane, Rome, Italy', '444-555-687', 'Indigo Rome');
    
INSERT IGNORE INTO Manager (first_name, last_name, address, SIN, hotel_name) VALUES
    ('Sophia', 'Kim', '789 Cherry Blossom Lane, Tokyo, Japan', '356-789-012', 'Hyatt Tokyo'),
    ('Michael', 'Brown', '321 Mountain Avenue, Sydney, Australia', '467-890-123', 'Hyatt Sydney'),
    ('Emma', 'Lee', '789 Seine River Lane, Paris, France', '776-543-210', 'Hyatt Paris'),
    ('Noah', 'Martinez', '789 Central Park West, New York, USA', '321-098-765', 'Hyatt New York'),
    ('Ava', 'Harris', '789 Abbey Road, London, UK', '210-987-654', 'Hyatt London'),
    ('Isabella', 'Rodriguez', '789 Sheikh Zayed Road, Dubai, UAE', '321-678-945', 'Hyatt Dubai'),
    ('Amelia', 'Gonzalez', '789 Yu Garden Lane, Shanghai, China', '123-456-789', 'Hyatt Shanghai'),
    ('Evelyn', 'Fisher', '789 Trevi Fountain Lane, Rome, Italy', '012-345-678', 'Hyatt Rome'),

    ('William', 'Walker', '789 Sumida River Road, Tokyo, Japan', '333-444-555', 'Regional Tokyo'),
    ('Madison', 'Miller', '789 Darling Harbour Lane, Sydney, Australia', '777-888-999', 'Regional Sydney'),
    ('Olivia', 'Hernandez', '789 Seine River Lane, Paris, France', '000-111-222', 'Regional Paris'),
    ('Noah', 'Gonzalez', '789 Central Park West, New York, USA', '333-444-553', 'Regional New York'),
    ('James', 'Rodriguez', '789 Abbey Road, London, UK', '666-777-886', 'Regional London'),
    ('Mia', 'Lopez', '789 Sheikh Zayed Road, Dubai, UAE', '999-000-119', 'Regional Dubai'),
    ('Ethan', 'Clark', '789 Yu Garden Lane, Shanghai, China', '222-333-412', 'Regional Shanghai'),
    ('Matthew', 'Hall', '789 Trevi Fountain Lane, Rome, Italy', '555-666-715', 'Regional Rome'),
    
    ('Olivia', 'Jackson', '789 Akihabara Road, Tokyo, Japan', '888-999-018', 'Serenity Tokyo'),
    ('Logan', 'Bailey', '789 Darling Harbour Lane, Sydney, Australia', '333-444-521', 'Serenity Sydney'),
    ('Lucas', 'Gordon', '789 Seine River Lane, Paris, France', '666-777-824', 'Serenity Paris'),
    ('Grace', 'Murphy', '789 Central Park West, New York, USA', '999-000-127', 'Serenity New York'),
    ('Nora', 'Hayes', '789 Abbey Road, London, UK', '222-333-430', 'Serenity London'),
    ('Hudson', 'Ortiz', '789 Sheikh Zayed Road, Dubai, UAE', '555-666-733', 'Serenity Dubai'),
    ('Eliana', 'Barnes', '789 Yu Garden Lane, Shanghai, China', '888-999-036', 'Serenity Shanghai'),
    ('David', 'Parker', '789 Trevi Fountain Lane, Rome, Italy', '111-222-339', 'Serenity Rome'),
    
    ('Mia', 'Lopez', '789 Roppongi Lane, Tokyo, Japan', '444-555-642', 'Lakewood Tokyo'),
    ('Oliver', 'King', '789 Darling Harbour Lane, Sydney, Australia', '777-888-945', 'Lakewood Sydney'),
    ('Isabella', 'Fisher', '789 Seine River Lane, Paris, France', '000-111-248', 'Lakewood Paris'),
    ('Olivia', 'Roberts', '789 Central Park West, New York, USA', '333-444-551', 'Lakewood New York'),
    ('James', 'Perez', '789 Abbey Road, London, UK', '666-777-854', 'Lakewood London'),
    ('Evelyn', 'Watson', '789 Sheikh Zayed Road, Dubai, UAE', '999-000-157', 'Lakewood Dubai'),
    ('Ella', 'Price', '789 Yu Garden Lane, Shanghai, China', '222-333-460', 'Lakewood Shanghai'),
    ('Jackson', 'Foster', '789 Trevi Fountain Lane, Rome, Italy', '555-666-763', 'Lakewood Rome'),
    
    ('Logan', 'Lopez', '789 Roppongi Lane, Tokyo, Japan', '333-444-566', 'Indigo Tokyo'),
    ('Lucas', 'King', '789 Darling Harbour Lane, Sydney, Australia', '666-777-869', 'Indigo Sydney'),
    ('Grace', 'Fisher', '789 Seine River Lane, Paris, France', '999-000-172', 'Indigo Paris'),
    ('James', 'Roberts', '789 Central Park West, New York, USA', '222-333-475', 'Indigo New York'),
    ('Benjamin', 'Perez', '789 Abbey Road, London, UK', '555-666-778', 'Indigo London'),
    ('Olivia', 'Watson', '789 Sheikh Zayed Road, Dubai, UAE', '888-999-081', 'Indigo Dubai'),
    ('Harper', 'Price', '789 Yu Garden Lane, Shanghai, China', '111-222-384', 'Indigo Shanghai'),
    ('Elijah', 'Foster', '789 Trevi Fountain Lane, Rome, Italy', '444-555-687', 'Indigo Rome');
    
INSERT IGNORE INTO Customer (customer_id, first_name, last_name, address, start_date, end_date, paid_in_advance, payment_method, room_number, hotel_name, booked_through_employee) VALUES
    ('Health card', 'Alice', 'Smith', '123 Main St, Springfield, USA', '2024-04-05', '2024-04-10', true, 'Cash', 1, 'Hyatt Tokyo', false),
    ('Passport', 'Bob', 'Johnson', '456 Elm St, London, UK', '2024-04-08', '2024-04-15', false, 'Credit card', 2, 'Hyatt Sydney', false),
    ("Driver's License", 'Eve', 'Williams', '789 Oak St, Paris, France', '2024-04-12', '2024-04-20', true, 'Debit card', 3, 'Hyatt Paris', false),
    ('Health card', 'Charlie', 'Brown', '321 Maple St, New York, USA', '2024-04-15', '2024-04-25', false, 'Cash', 4, 'Hyatt New York', false),
    ('Passport', 'Diana', 'Davis', '654 Pine St, Sydney, Australia', '2024-04-18', '2024-04-28', true, 'Credit card', 5, 'Hyatt London', false),
    ("Driver's License", 'Frank', 'Miller', '987 Birch St, Dubai, UAE', '2024-04-22', '2024-05-01', false, 'Debit card', 1, 'Hyatt Dubai', false),
    ('Health card', 'Grace', 'Wilson', '741 Cedar St, Shanghai, China', '2024-04-25', '2024-05-05', true, 'Cash', 2, 'Hyatt Shanghai', false),
    ('Passport', 'Harry', 'Thompson', '852 Walnut St, Rome, Italy', '2024-04-28', '2024-05-08', false, 'Credit card', 3, 'Hyatt Rome', false),

    ('Health card', 'Isabella', 'Martinez', '159 Elm St, Tokyo, Japan', '2024-04-03', '2024-04-09', true, 'Cash', 1, 'Regional Tokyo', true),
    ('Passport', 'Jack', 'Garcia', '753 Cherry St, Sydney, Australia', '2024-04-06', '2024-04-13', false, 'Credit card', 2, 'Regional Sydney', false),
    ("Driver's License", 'Liam', 'Rodriguez', '258 Olive St, Paris, France', '2024-04-10', '2024-04-19', true, 'Debit card', 3, 'Regional Paris', false),
    ('Health card', 'Olivia', 'Hernandez', '369 Sycamore St, New York, USA', '2024-04-13', '2024-04-24', false, 'Cash', 4, 'Regional New York', false),
    ('Passport', 'Mia', 'Lopez', '951 Laurel St, London, UK', '2024-04-16', '2024-04-27', true, 'Credit card', 5, 'Regional London', false),
    ("Driver's License", 'Noah', 'Perez', '147 Aspen St, Dubai, UAE', '2024-04-19', '2024-04-30', false, 'Debit card', 1, 'Regional Dubai', false),
    ('Health card', 'Sophia', 'Gonzalez', '753 Cedar St, Shanghai, China', '2024-04-22', '2024-05-03', true, 'Cash', 2, 'Regional Shanghai', false),
    ('Passport', 'William', 'Sanchez', '258 Oak St, Rome, Italy', '2024-04-25', '2024-05-06', false, 'Credit card', 3, 'Regional Rome', false),

    ('Health card', 'Ava', 'Ramirez', '123 Main St, Tokyo, Japan', '2024-04-02', '2024-04-08', true, 'Cash', 1, 'Serenity Tokyo', true),
    ('Passport', 'Logan', 'Campbell', '456 Elm St, Sydney, Australia', '2024-04-01', '2024-04-11', false, 'Credit card', 2, 'Serenity Sydney', true),
    ("Driver's License", 'Emma', 'Mitchell', '789 Oak St, Paris, France', '2024-04-09', '2024-04-18', true, 'Debit card', 3, 'Serenity Paris', false),
    ('Health card', 'Liam', 'Roberts', '321 Maple St, New York, USA', '2024-04-12', '2024-04-23', false, 'Cash', 4, 'Serenity New York', false),
    ('Passport', 'Oliver', 'Phillips', '654 Pine St, London, UK', '2024-04-15', '2024-04-26', true, 'Credit card', 5, 'Serenity London', false),
    ("Driver's License", 'Aria', 'Evans', '987 Birch St, Dubai, UAE', '2024-04-18', '2024-04-29', false, 'Debit card', 1, 'Serenity Dubai', false),
    ('Health card', 'Ethan', 'Collins', '741 Cedar St, Shanghai, China', '2024-04-21', '2024-04-30', true, 'Cash', 2, 'Serenity Shanghai', false),
    ('Passport', 'Amelia', 'Stewart', '852 Walnut St, Rome, Italy', '2024-04-24', '2024-05-05', false, 'Credit card', 3, 'Serenity Rome', false),

    ('Health card', 'Charlotte', 'Turner', '159 Elm St, Tokyo, Japan', '2024-04-04', '2024-04-10', true, 'Cash', 1, 'Lakewood Tokyo', true),
    ('Passport', 'Lucas', 'Mitchell', '753 Cherry St, Sydney, Australia', '2024-04-02', '2024-04-13', false, 'Credit card', 2, 'Lakewood Sydney', true),
    ("Driver's License", 'Harper', 'Parker', '258 Olive St, Paris, France', '2024-04-11', '2024-04-19', true, 'Debit card', 3, 'Lakewood Paris', false),
    ('Health card', 'Avery', 'Jones', '369 Sycamore St, New York, USA', '2024-04-14', '2024-04-24', false, 'Cash', 4, 'Lakewood New York', false),
    ('Passport', 'Evelyn', 'Taylor', '951 Laurel St, London, UK', '2024-04-17', '2024-04-27', true, 'Credit card', 5, 'Lakewood London', false),
    ("Driver's License", 'Landon', 'White', '147 Aspen St, Dubai, UAE', '2024-04-20', '2024-04-30', false, 'Debit card', 1, 'Lakewood Dubai', false),
    ('Health card', 'Scarlett', 'Harris', '753 Cedar St, Shanghai, China', '2024-04-23', '2024-05-01', true, 'Cash', 2, 'Lakewood Shanghai', false),
    ('Passport', 'Chloe', 'Lee', '258 Oak St, Rome, Italy', '2024-04-26', '2024-05-06', false, 'Credit card', 3, 'Lakewood Rome', false),

    ('Health card', 'Zoey', 'Martin', '123 Main St, Tokyo, Japan', '2024-04-01', '2024-04-09', true, 'Cash', 1, 'Indigo Tokyo', true),
    ('Passport', 'Xavier', 'Jackson', '456 Elm St, Sydney, Australia', '2024-04-04', '2024-04-11', false, 'Credit card', 2, 'Indigo Sydney', true),
    ("Driver's License", 'Mila', 'Adams', '789 Oak St, Paris, France', '2024-04-03', '2024-04-17', true, 'Debit card', 3, 'Indigo Paris', true),
    ('Health card', 'Liam', 'Wilson', '321 Maple St, New York, USA', '2024-04-11', '2024-04-20', false, 'Cash', 4, 'Indigo New York', false),
    ('Passport', 'Olivia', 'Brown', '654 Pine St, London, UK', '2024-04-14', '2024-04-23', true, 'Credit card', 5, 'Indigo London', false),
    ("Driver's License", 'Noah', 'Taylor', '987 Birch St, Dubai, UAE', '2024-04-17', '2024-04-26', false, 'Debit card', 1, 'Indigo Dubai', false),
    ('Health card', 'Sophia', 'Thomas', '741 Cedar St, Shanghai, China', '2024-04-20', '2024-04-29', true, 'Cash', 2, 'Indigo Shanghai', false),
    ('Passport', 'William', 'Jones', '852 Walnut St, Rome, Italy', '2024-04-23', '2024-05-02', false, 'Credit card', 3, 'Indigo Rome', false);

-- query: list the hotel names from the hotel chain 'Hyatt Hotels' with 4 stars
SELECT hotel_name
From Hotel
Where chain_name = 'Hyatt Hotels' and number_of_stars = 4;

-- query: list the first and last names of the customers who presented their passport as id and paid in advance
SELECT first_name, last_name
From Customer
Where customer_id = 'Passport' and paid_in_advance = true;

-- aggregation query: list the total number of rooms in each hotel chain
SELECT chain_name, SUM(number_of_rooms)
From Hotel
GROUP BY chain_name;
    
-- nested query: list the first and last names of the customers who have booked a room at a hotel that has a spa
SELECT c.first_name, c.last_name
FROM Customer c
JOIN Hotel h ON c.hotel_name = h.hotel_name
JOIN HotelAmenity ha ON h.hotel_name = ha.hotel_name
JOIN Amenity a ON ha.amenity_id = a.amenity_id
WHERE a.amenity_name = 'Spa';
 
-- view: the number of available rooms per area    
DROP VIEW IF EXISTS RoomsPerArea;
CREATE VIEW RoomsPerArea AS     
SELECT h.location AS location, COUNT(*) AS total_rooms
FROM Room r
JOIN Hotel h ON r.hotel_name = h.hotel_name
WHERE r.room_status = 'available'
GROUP BY h.location;
    
-- view: the aggregated capacity of all the rooms of a specific hotel    
DROP VIEW IF EXISTS RoomCapacity;
CREATE VIEW RoomCapacity AS
SELECT hotel_name, SUM(capacity) as total_capacity
FROM Room
GROUP BY hotel_name;
    
    
    
    
    