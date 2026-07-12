IF DB_ID(N'WaterBillingDb') IS NULL
BEGIN
    CREATE DATABASE WaterBillingDb;
END
GO

USE WaterBillingDb;
GO

IF OBJECT_ID(N'dbo.bills', N'U') IS NOT NULL DROP TABLE dbo.bills;
IF OBJECT_ID(N'dbo.tariff_tiers', N'U') IS NOT NULL DROP TABLE dbo.tariff_tiers;
IF OBJECT_ID(N'dbo.customers', N'U') IS NOT NULL DROP TABLE dbo.customers;
IF OBJECT_ID(N'dbo.app_users', N'U') IS NOT NULL DROP TABLE dbo.app_users;
GO

CREATE TABLE dbo.customers (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_customers PRIMARY KEY,
    code NVARCHAR(30) NOT NULL CONSTRAINT uq_customers_code UNIQUE,
    name NVARCHAR(150) NOT NULL,
    address NVARCHAR(500) NOT NULL,
    phone NVARCHAR(30) NOT NULL,
    current_reading INT NOT NULL CONSTRAINT df_customers_current_reading DEFAULT 0,
    status VARCHAR(20) NOT NULL CONSTRAINT df_customers_status DEFAULT 'PENDING',
    created_at DATETIME2 NOT NULL CONSTRAINT df_customers_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT ck_customers_current_reading CHECK (current_reading >= 0),
    CONSTRAINT ck_customers_status CHECK (status IN ('PENDING', 'READING', 'COMPLETED'))
);

CREATE TABLE dbo.app_users (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_app_users PRIMARY KEY,
    username NVARCHAR(50) NOT NULL CONSTRAINT uq_app_users_username UNIQUE,
    password_hash NVARCHAR(100) NOT NULL,
    full_name NVARCHAR(150) NOT NULL,
    role VARCHAR(20) NOT NULL,
    email NVARCHAR(150) NULL,
    phone NVARCHAR(30) NULL,
    customer_id BIGINT NULL,
    created_at DATETIME2 NOT NULL CONSTRAINT df_app_users_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT ck_app_users_role CHECK (role IN ('ADMIN', 'STAFF', 'USER')),
    CONSTRAINT fk_app_users_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(id) ON DELETE SET NULL
);



CREATE TABLE dbo.bills (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_bills PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    bill_code NVARCHAR(50) NOT NULL CONSTRAINT uq_bills_bill_code UNIQUE,
    bill_date DATETIME2 NOT NULL,
    old_reading INT NOT NULL,
    new_reading INT NOT NULL,
    consumption DECIMAL(18,2) NOT NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    vat DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    image_path NVARCHAR(1000) NULL,
    is_synced BIT NOT NULL CONSTRAINT df_bills_is_synced DEFAULT 0,
    is_paid BIT NOT NULL CONSTRAINT df_bills_is_paid DEFAULT 0,
    created_at DATETIME2 NOT NULL CONSTRAINT df_bills_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT fk_bills_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(id) ON DELETE CASCADE,
    CONSTRAINT ck_bills_reading CHECK (old_reading >= 0 AND new_reading >= 0),
    CONSTRAINT ck_bills_money CHECK (consumption >= 0 AND unit_price >= 0 AND amount >= 0 AND vat >= 0 AND total_amount >= 0)
);

CREATE TABLE dbo.tariff_tiers (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_tariff_tiers PRIMARY KEY,
    tier_name NVARCHAR(100) NOT NULL,
    from_m3 INT NOT NULL,
    to_m3 INT NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    vat_rate DECIMAL(5,4) NOT NULL CONSTRAINT df_tariff_tiers_vat_rate DEFAULT 0.10,
    is_active BIT NOT NULL CONSTRAINT df_tariff_tiers_is_active DEFAULT 1,
    CONSTRAINT ck_tariff_tiers_range CHECK (from_m3 >= 0 AND (to_m3 IS NULL OR to_m3 >= from_m3))
);
GO

CREATE INDEX ix_customers_name ON dbo.customers(name);
CREATE INDEX ix_bills_customer_date ON dbo.bills(customer_id, bill_date DESC);
CREATE INDEX ix_bills_is_synced ON dbo.bills(is_synced);
GO

INSERT INTO dbo.tariff_tiers (tier_name, from_m3, to_m3, unit_price, vat_rate) VALUES
(N'Giá demo cố định', 0, NULL, 12000, 0.10),
(N'Bậc 1: 0-10 m3', 0, 10, 5973, 0.05),
(N'Bậc 2: 11-20 m3', 11, 20, 7052, 0.05),
(N'Bậc 3: 21-30 m3', 21, 30, 8669, 0.05),
(N'Bậc 4: trên 30 m3', 31, NULL, 15929, 0.05);

SET IDENTITY_INSERT dbo.customers ON;
INSERT INTO dbo.customers (id, code, name, address, phone, current_reading, status) VALUES
(1, N'KH001', N'Lưu Bị', N'12-A Phố Huế, Hai Bà Trưng, Hà Nội', N'0912345001', 125, 'PENDING'),
(2, N'KH002', N'Quan Vũ', N'88 Đường Láng, Đống Đa, Hà Nội', N'0987654002', 80, 'PENDING'),
(3, N'KH003', N'Trương Phi', N'15/2 Trần Duy Hưng, Cầu Giấy, Hà Nội', N'0904444003', 210, 'COMPLETED'),
(4, N'KH004', N'Gia Cát Lượng', N'Lạch Tray, Ngô Quyền, Hải Phòng', N'0911222004', 45, 'READING'),
(5, N'KH005', N'Tào Tháo', N'Trần Hưng Đạo, TP. Bắc Ninh', N'0933555005', 320, 'PENDING'),
(6, N'KH006', N'Tôn Quyền', N'Khu đô thị Mon Bay, Hạ Long, Quảng Ninh', N'0944006006', 150, 'PENDING'),
(7, N'KH007', N'Triệu Vân', N'Quang Trung, TP. Thái Bình', N'0944007007', 95, 'PENDING'),
(8, N'KH008', N'Chu Du', N'15 Nguyễn Trãi, Thanh Xuân, Hà Nội', N'0944008008', 180, 'PENDING'),
(9, N'KH009', N'Lữ Bố', N'89 Cầu Giấy, Cầu Giấy, Hà Nội', N'0944009009', 60, 'PENDING'),
(10, N'KH010', N'Điêu Thuyền', N'Lê Lợi, TP. Bắc Giang', N'0944010010', 275, 'PENDING'),
(11, N'KH011', N'Tư Mã Ý', N'Hùng Vương, TP. Việt Trì, Phú Thọ', N'0944011011', 110, 'PENDING'),
(12, N'KH012', N'Hạ Hầu Đôn', N'Phố Hiến, TP. Hưng Yên', N'0944012012', 400, 'PENDING'),
(13, N'KH013', N'Hứa Chử', N'Trần Đăng Ninh, TP. Nam Định', N'0944013013', 135, 'PENDING'),
(14, N'KH014', N'Trương Liêu', N'Vinhomes Ocean Park, Gia Lâm, Hà Nội', N'0944014014', 20, 'PENDING'),
(15, N'KH015', N'Hoàng Trung', N'Tòa nhà Lotte, Liễu Giai, Ba Đình, Hà Nội', N'0944015015', 245, 'PENDING');
SET IDENTITY_INSERT dbo.customers OFF;

SET IDENTITY_INSERT dbo.bills ON;
INSERT INTO dbo.bills (id, customer_id, bill_code, bill_date, old_reading, new_reading, consumption, unit_price, amount, vat, total_amount, image_path, is_synced) VALUES
(1, 1, N'HD0324001', '2024-03-15T09:00:00', 82, 95, 13, 12000, 156000, 15600, 171600, NULL, 1),
(2, 1, N'HD0424001', '2024-04-15T09:00:00', 95, 110, 15, 12000, 180000, 18000, 198000, NULL, 1),
(3, 1, N'HD0524001', '2024-05-15T09:00:00', 110, 125, 15, 12000, 180000, 18000, 198000, NULL, 1),
(4, 2, N'HD0424002', '2024-04-16T09:00:00', 55, 70, 15, 12000, 180000, 18000, 198000, NULL, 1),
(5, 2, N'HD0524002', '2024-05-16T09:00:00', 70, 80, 10, 12000, 120000, 12000, 132000, NULL, 1),
(6, 3, N'HD0424003', '2024-04-17T09:00:00', 172, 190, 18, 12000, 216000, 21600, 237600, NULL, 1),
(7, 3, N'HD0524003', '2024-05-17T09:00:00', 190, 210, 20, 12000, 240000, 24000, 264000, NULL, 1),
(8, 4, N'HD0524004', '2024-05-18T09:00:00', 30, 45, 15, 12000, 180000, 18000, 198000, NULL, 1),
(9, 5, N'HD0424005', '2024-04-19T09:00:00', 265, 290, 25, 12000, 300000, 30000, 330000, NULL, 1),
(10, 5, N'HD0524005', '2024-05-19T09:00:00', 290, 320, 30, 12000, 360000, 36000, 396000, NULL, 1),
(11, 1, N'PENDING-KH001-20240605', '2024-06-05T14:31:00', 125, 141, 16, 12000, 192000, 19200, 211200, NULL, 0),
(12, 2, N'PENDING-KH002-20240605', '2024-06-05T14:32:00', 80, 127, 47, 12000, 564000, 56400, 620400, NULL, 0),
(13, 5, N'PENDING-KH005-20240605', '2024-06-05T14:33:00', 320, 345, 25, 12000, 300000, 30000, 330000, NULL, 0);
SET IDENTITY_INSERT dbo.bills OFF;
GO

-- Insert AppUsers directly so all data is in one place
-- Mật khẩu mặc định cho tất cả các tài khoản dưới đây là: 123456
SET IDENTITY_INSERT dbo.app_users ON;
INSERT INTO dbo.app_users (id, username, password_hash, full_name, role, email, phone, customer_id) VALUES
(1, N'admin', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Quản Trị Viên', 'ADMIN', N'admin@water.com', N'0987654321', NULL),
(2, N'nhanvien01', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Nguyễn Văn A', 'STAFF', N'nguyenvana@gmail.com', N'0912345678', NULL),
(3, N'khachhang01', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Lưu Bị', 'USER', N'kh01@gmail.com', N'0912345001', 1),
(4, N'khachhang02', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Quan Vũ', 'USER', N'kh02@gmail.com', N'0987654002', 2),
(5, N'khachhang03', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Trương Phi', 'USER', N'kh03@gmail.com', N'0904444003', 3),
(6, N'khachhang04', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Gia Cát Lượng', 'USER', N'kh04@gmail.com', N'0911222004', 4),
(7, N'khachhang05', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Tào Tháo', 'USER', N'kh05@gmail.com', N'0933555005', 5),
(8, N'khachhang06', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Tôn Quyền', 'USER', N'kh06@gmail.com', N'0944006006', 6),
(9, N'khachhang07', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Triệu Vân', 'USER', N'kh07@gmail.com', N'0944007007', 7),
(10, N'khachhang08', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Chu Du', 'USER', N'kh08@gmail.com', N'0944008008', 8),
(11, N'khachhang09', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Lữ Bố', 'USER', N'kh09@gmail.com', N'0944009009', 9),
(12, N'khachhang10', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Điêu Thuyền', 'USER', N'kh10@gmail.com', N'0944010010', 10),
(13, N'khachhang11', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Tư Mã Ý', 'USER', N'kh11@gmail.com', N'0944011011', 11),
(14, N'khachhang12', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Hạ Hầu Đôn', 'USER', N'kh12@gmail.com', N'0944012012', 12),
(15, N'khachhang13', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Hứa Chử', 'USER', N'kh13@gmail.com', N'0944013013', 13),
(16, N'khachhang14', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Trương Liêu', 'USER', N'kh14@gmail.com', N'0944014014', 14),
(17, N'khachhang15', N'$2a$10$exR8o08Ra0/4vrl7ey2w3ezL0SxflYWmmrQ6DM9jWL572yLdQwhM6', N'Hoàng Trung', 'USER', N'kh15@gmail.com', N'0944015015', 15);
SET IDENTITY_INSERT dbo.app_users OFF;
GO
